/// The central controller for the canvas.
///
/// Orchestrates all subsystems: viewport, renderer, selection, layers,
/// history, gestures, grid, and keyboard shortcuts. This is the primary
/// API surface that developers interact with.
///
/// Example:
/// ```dart
/// final controller = CanvasController();
/// controller.add(CanvasRect(x: 100, y: 100, width: 200, height: 100));
/// controller.undo();
/// ```
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/canvas_object.dart';
import '../models/shapes/canvas_group.dart';
import '../viewport/canvas_viewport.dart';
import '../renderer/canvas_renderer.dart';
import '../gestures/canvas_gesture_handler.dart';
import '../selection/selection_manager.dart';
import '../layers/layer_manager.dart';
import '../history/history_manager.dart';
import '../commands/canvas_commands.dart';
import '../utils/grid_and_guides.dart';
import '../utils/keyboard_shortcuts.dart';
import '../serialization/object_registry.dart';
import '../serialization/canvas_serializer.dart';
import '../export/canvas_exporter.dart';
import '../collaboration/collaboration_manager.dart';
import '../core/constants.dart';
import '../core/exceptions.dart';

/// The main controller that owns and coordinates all canvas subsystems.
class CanvasController with ChangeNotifier {
  // ─── Subsystems ──────────────────────────────────────────────────────────

  /// All objects on the canvas.
  final List<CanvasObject> _objects = [];

  /// The viewport / camera.
  late final CanvasViewport viewport;

  /// The selection manager.
  late final SelectionManager selection;

  /// The layer manager.
  late final LayerManager layers;

  /// The undo/redo history.
  late final HistoryManager history;

  /// The grid configuration.
  GridConfig gridConfig;

  /// The smart guide system.
  late final SmartGuideSystem smartGuides;

  /// The keyboard shortcut manager.
  late final KeyboardShortcutManager shortcuts;

  /// The gesture handler.
  CanvasGestureHandler? _gestureHandler;

  /// The collaboration manager (optional).
  CollaborationManager? collaboration;

  /// Clipboard for copy/paste.
  final List<CanvasObject> _clipboard = [];

  // ─── State ───────────────────────────────────────────────────────────────

  InteractionMode _mode = InteractionMode.select;
  InteractionMode get mode => _mode;

  int _nextZIndex = 0;

  // ─── Constructor ─────────────────────────────────────────────────────────

  CanvasController({
    Size canvasSize = const Size(800, 600),
    GridConfig? gridConfig,
  }) : gridConfig = gridConfig ?? GridConfig() {
    viewport = CanvasViewport(canvasSize: canvasSize);
    selection = SelectionManager();
    layers = LayerManager();
    history = HistoryManager();
    smartGuides = SmartGuideSystem(gridConfig: this.gridConfig, viewport: viewport);
    shortcuts = KeyboardShortcutManager();

    // Ensure default object types are registered
    CanvasObjectRegistry.instance.registerDefaults();

    // Connect keyboard shortcuts
    _setupKeyboardShortcuts();

    // Listen for object changes to trigger repaints
    for (final obj in _objects) {
      obj.addListener(notifyListeners);
    }
  }

  void _setupKeyboardShortcuts() {
    shortcuts.onCopy = copySelected;
    shortcuts.onPaste = pasteClipboard;
    shortcuts.onCut = cutSelected;
    shortcuts.onDelete = deleteSelected;
    shortcuts.onUndo = () => history.undo();
    shortcuts.onRedo = () => history.redo();
    shortcuts.onSelectAll = selectAll;
    shortcuts.onGroup = groupSelected;
    shortcuts.onUngroup = ungroupSelected;
    shortcuts.onDuplicate = duplicateSelected;
    shortcuts.onZoomIn = () => viewport.zoomBy(CanvasConstants.zoomStep, focalPoint: _screenCenter);
    shortcuts.onZoomOut = () => viewport.zoomBy(1 / CanvasConstants.zoomStep, focalPoint: _screenCenter);
    shortcuts.onZoomFit = zoomToFit;
    shortcuts.onNudge = (delta) => nudgeSelected(delta);
  }

  Offset get _screenCenter => Offset(viewport.canvasSize.width / 2, viewport.canvasSize.height / 2);

  // ─── Object Management ───────────────────────────────────────────────────

  /// Returns all objects on the canvas.
  List<CanvasObject> get objects => List.unmodifiable(_objects);

  /// Finds an object by ID.
  CanvasObject? getObject(String id) {
    for (final obj in _objects) {
      if (obj.id == id) return obj;
      if (obj is CanvasGroup) {
        final found = obj.findDescendant(id);
        if (found != null) return found;
      }
    }
    return null;
  }

  /// Adds an object to the canvas.
  void add(CanvasObject object) {
    object.zIndex = _nextZIndex++;
    object.layerId ??= layers.activeLayerId;
    _objects.add(object);
    object.addListener(notifyListeners);
    notifyListeners();
  }

  /// Adds an object via a command (undoable).
  void addWithUndo(CanvasObject object) {
    object.zIndex = _nextZIndex++;
    object.layerId ??= layers.activeLayerId;
    history.execute(CreateCommand([object], _directAdd, _directRemove));
  }

  void _directAdd(CanvasObject obj) {
    if (!_objects.contains(obj)) {
      _objects.add(obj);
      obj.addListener(notifyListeners);
    }
    notifyListeners();
  }

  void _directRemove(CanvasObject obj) {
    _objects.remove(obj);
    obj.removeListener(notifyListeners);
    notifyListeners();
  }

  void _directRestore(CanvasObject obj, int zIndex) {
    obj.zIndex = zIndex;
    _directAdd(obj);
  }

  /// Removes an object by ID.
  void remove(String objectId) {
    final obj = getObject(objectId);
    if (obj == null) throw CanvasObjectNotFoundException(objectId);
    _directRemove(obj);
    selection.removeFromSelection(obj);
  }

  /// Removes all objects.
  void clear() {
    for (final obj in _objects) obj.removeListener(notifyListeners);
    _objects.clear();
    selection.clear();
    history.clear();
    _nextZIndex = 0;
    notifyListeners();
  }

  // ─── Selection Operations ────────────────────────────────────────────────

  void select(CanvasObject object) => selection.select(object);

  void selectAll() => selection.selectAll(_objects);

  void deselectAll() => selection.clear();

  Set<CanvasObject> get selectedObjects => selection.selected;

  // ─── Clipboard ───────────────────────────────────────────────────────────

  void copySelected() {
    _clipboard.clear();
    for (final obj in selection.selected) {
      _clipboard.add(obj.clone());
    }
  }

  void cutSelected() {
    copySelected();
    deleteSelected();
  }

  void pasteClipboard() {
    final txn = history.beginTransaction(description: 'Paste');
    for (final obj in _clipboard) {
      final cloned = obj.clone();
      cloned.position += const Offset(20, 20);
      txn.add(CreateCommand([cloned], _directAdd, _directRemove));
    }
    txn.commit();
  }

  void duplicateSelected() {
    copySelected();
    pasteClipboard();
  }

  void deleteSelected() {
    final toDelete = selection.selected.toList();
    if (toDelete.isEmpty) return;
    final zIndices = toDelete.map((o) => o.zIndex).toList();
    history.execute(DeleteCommand(toDelete, zIndices, _directRemove, _directRestore));
    selection.clear();
  }

  // ─── Grouping ────────────────────────────────────────────────────────────

  void groupSelected() {
    final objs = selection.selected.toList();
    if (objs.length < 2) return;
    final group = CanvasGroup(children: List.from(objs));
    group.zIndex = _nextZIndex++;
    history.execute(GroupCommand(
      objs, group, _directRemove, _directAdd, _directAdd, _directRemove,
    ));
    selection.select(group);
  }

  void ungroupSelected() {
    final group = selection.singleSelection;
    if (group == null || group is! CanvasGroup) return;
    final children = List<CanvasObject>.from(group.children);
    final zIndices = children.map((c) => c.zIndex).toList();
    for (final child in children) child.parentId = null;
    history.execute(GroupCommand(
      children, group, _directRemove, _directAdd, _directRemove, _directAdd,
    ));
    selection.selectAll(children);
  }

  // ─── Z-Ordering ──────────────────────────────────────────────────────────

  void bringToFront(CanvasObject obj) { obj.zIndex = _nextZIndex++; notifyListeners(); }
  void sendToBack(CanvasObject obj) {
    final minZ = _objects.map((o) => o.zIndex).reduce((a, b) => a < b ? a : b);
    obj.zIndex = minZ - 1;
    notifyListeners();
  }
  void bringForward(CanvasObject obj) { obj.zIndex += 1; notifyListeners(); }
  void sendBackward(CanvasObject obj) { obj.zIndex = (obj.zIndex - 1).clamp(0, _nextZIndex); notifyListeners(); }

  // ─── Transform Selected ──────────────────────────────────────────────────

  void nudgeSelected(Offset delta) {
    final objs = selection.selected.toList();
    if (objs.isEmpty) return;
    final oldPositions = objs.map((o) => o.position).toList();
    final newPositions = objs.map((o) => o.position + delta).toList();
    history.execute(MoveCommand(objs, oldPositions, newPositions));
    notifyListeners();
  }

  // ─── Viewport Shortcuts ──────────────────────────────────────────────────

  void zoomToFit() {
    viewport.zoomToFitContent(_objects.map((o) => o.worldBounds));
  }

  void zoomToSelection() {
    if (selection.selectionBounds != null) {
      viewport.zoomToFit(selection.selectionBounds!);
    }
  }

  void setInteractionMode(InteractionMode newMode) {
    _mode = newMode;
    _gestureHandler?.setMode(newMode);
    notifyListeners();
  }

  // ─── Serialization ───────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => CanvasSerializer.serialize(
    objects: _objects, viewport: viewport, layerManager: layers, gridConfig: gridConfig,
  );

  String exportJson() => CanvasSerializer.exportJson(
    objects: _objects, viewport: viewport, layerManager: layers, gridConfig: gridConfig,
  );

  void importJson(String jsonString) {
    final data = CanvasSerializer.importJson(jsonString);
    clear();
    _objects.addAll(data.objects);
    for (final obj in _objects) obj.addListener(notifyListeners);
    layers.fromJson(data.layersJson);
    gridConfig = data.gridConfig;
    viewport.setOffset(data.viewportData.offset);
    viewport.setZoom(data.viewportData.zoom);
    notifyListeners();
  }

  void fromJsonMap(Map<String, dynamic> json) {
    final data = CanvasSerializer.deserialize(json);
    clear();
    _objects.addAll(data.objects);
    for (final obj in _objects) obj.addListener(notifyListeners);
    layers.fromJson(data.layersJson);
    notifyListeners();
  }

  // ─── Export ───────────────────────────────────────────────────────────────

  Future<Uint8List> exportPng({double pixelRatio = 2.0, Rect? region}) {
    return CanvasExporter.exportPng(
      objects: _objects, viewport: viewport, pixelRatio: pixelRatio, region: region,
    );
  }

  Future<Uint8List> exportJpeg({double pixelRatio = 2.0, Rect? region, double quality = 0.92}) {
    return CanvasExporter.exportJpeg(
      objects: _objects, viewport: viewport, pixelRatio: pixelRatio, region: region, quality: quality,
    );
  }

  String exportSvg({Rect? region}) {
    return CanvasExporter.exportSvg(objects: _objects, region: region);
  }

  // ─── Grid ────────────────────────────────────────────────────────────────

  void setGridConfig(GridConfig config) {
    gridConfig = config;
    smartGuides = SmartGuideSystem(gridConfig: gridConfig, viewport: viewport);
    notifyListeners();
  }

  // ─── Internal: Gesture Connection ────────────────────────────────────────

  /// Sets the gesture handler (called by the canvas widget).
  set gestureHandler(CanvasGestureHandler? handler) {
    _gestureHandler = handler;
    if (handler != null) handler.setMode(_mode);
  }

  // ─── Dispose ─────────────────────────────────────────────────────────────

  void dispose() {
    for (final obj in _objects) obj.removeListener(notifyListeners);
    viewport.dispose();
    history.clear();
    _objects.clear();
    super.dispose();
  }
}