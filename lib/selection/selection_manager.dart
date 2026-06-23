/// Selection system for the canvas.
///
/// Manages which objects are currently selected, provides selection handles
/// for resize/rotate, and supports multi-selection, lasso/box selection,
/// and shift-select.
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/canvas_object.dart';
import '../core/constants.dart';
import '../core/extensions.dart';

/// Manages the selection state of the canvas.
///
/// The selection system is independent from the rendering layer. It tracks
/// which objects are selected and provides the visual overlay (handles)
/// for the current selection.
///
/// Example:
/// ```dart
/// selection.select(rect);
/// selection.selectAll(objects);
/// selection.clear();
/// ```
class SelectionManager with ChangeNotifier {
  /// Currently selected objects, ordered by selection time.
  final Set<CanvasObject> _selected = {};

  /// Whether the selection is currently being dragged.
  bool _isDragging = false;

  /// Start position of a box-select drag in world coordinates.
  Offset? _boxSelectStart;

  /// Current position of a box-select drag in world coordinates.
  Offset? _boxSelectEnd;

  /// Whether box-select is active.
  bool _isBoxSelecting = false;

  /// The combined bounding box of all selected objects.
  Rect? _selectionBounds;

  // ─── Accessors ────────────────────────────────────────────────────────────

  /// The set of currently selected objects.
  Set<CanvasObject> get selected => Set.unmodifiable(_selected);

  /// Whether any objects are selected.
  bool get hasSelection => _selected.isNotEmpty;

  /// Whether exactly one object is selected.
  bool get isSingleSelection => _selected.length == 1;

  /// The single selected object, or `null` if 0 or multiple are selected.
  CanvasObject? get singleSelection =>
      _selected.length == 1 ? _selected.first : null;

  /// The combined bounding box of all selected objects in world coordinates,
  /// or `null` if nothing is selected.
  Rect? get selectionBounds {
    if (_selected.isEmpty) return null;
    Rect? combined;
    for (final obj in _selected) {
      final wb = obj.worldBounds;
      combined = combined?.expandToInclude(wb.topLeft)
          ?.expandToInclude(wb.bottomRight) ?? wb;
    }
    return combined;
  }

  /// Whether a box-select drag is in progress.
  bool get isBoxSelecting => _isBoxSelecting;

  /// The rectangle defined by the box-select drag, in world coordinates.
  Rect? get boxSelectRect {
    if (_boxSelectStart == null || _boxSelectEnd == null) return null;
    return Rect.fromPoints(_boxSelectStart!, _boxSelectEnd!);
  }

  /// Whether the selection is being dragged.
  bool get isDragging => _isDragging;

  // ─── Selection Operations ─────────────────────────────────────────────────

  /// Selects a single object, clearing any previous selection.
  void select(CanvasObject object) {
    if (object.locked) return;
    _selected.clear();
    _selected.add(object);
    _invalidate();
  }

  /// Adds an object to the current selection (shift-select behavior).
  void addToSelection(CanvasObject object) {
    if (object.locked) return;
    _selected.add(object);
    _invalidate();
  }

  /// Removes an object from the current selection.
  void removeFromSelection(CanvasObject object) {
    _selected.remove(object);
    _invalidate();
  }

  /// Toggles an object's selection state.
  void toggleSelection(CanvasObject object) {
    if (_selected.contains(object)) {
      removeFromSelection(object);
    } else {
      addToSelection(object);
    }
  }

  /// Selects all objects in the list that are not locked.
  void selectAll(Iterable<CanvasObject> objects) {
    _selected.clear();
    _selected.addAll(objects.where((o) => !o.locked));
    _invalidate();
  }

  /// Clears the selection.
  void clear() {
    if (_selected.isEmpty) return;
    _selected.clear();
    _invalidate();
  }

  /// Selects all objects whose world bounds intersect [worldRect].
  void selectInRect(Rect worldRect, Iterable<CanvasObject> allObjects) {
    _selected.clear();
    for (final obj in allObjects) {
      if (!obj.locked && obj.worldBounds.overlapsRect(worldRect)) {
        _selected.add(obj);
      }
    }
    _invalidate();
  }

  /// Selects objects that contain [worldPoint], with shift-select support.
  void selectAtPoint(Offset worldPoint, Iterable<CanvasObject> allObjects, {bool shift = false}) {
    if (!shift) _selected.clear();
    // Iterate in reverse z-order for topmost-first selection
    final sorted = allObjects.where((o) => o.visible).toList()
      ..sort((a, b) => b.zIndex.compareTo(a.zIndex));
    for (final obj in sorted) {
      if (!obj.locked && obj.hitTest(worldPoint)) {
        _selected.add(obj);
        break; // Only select the topmost object
      }
    }
    _invalidate();
  }

  // ─── Box Select ───────────────────────────────────────────────────────────

  /// Starts a box-select drag at [worldPoint].
  void startBoxSelect(Offset worldPoint) {
    _isBoxSelecting = true;
    _boxSelectStart = worldPoint;
    _boxSelectEnd = worldPoint;
    notifyListeners();
  }

  /// Updates the box-select drag to [worldPoint].
  void updateBoxSelect(Offset worldPoint) {
    if (!_isBoxSelecting) return;
    _boxSelectEnd = worldPoint;
    notifyListeners();
  }

  /// Ends the box-select drag and selects objects within the box.
  void endBoxSelect(Iterable<CanvasObject> allObjects) {
    if (_isBoxSelecting && boxSelectRect != null) {
      selectInRect(boxSelectRect!, allObjects);
    }
    _isBoxSelecting = false;
    _boxSelectStart = null;
    _boxSelectEnd = null;
  }

  // ─── Selection Handles ────────────────────────────────────────────────────

  /// Returns the 8 resize handle positions (corners + edge midpoints) for
  /// the current selection bounding box, in world coordinates.
  List<Offset> getResizeHandles() {
    final bounds = selectionBounds;
    if (bounds == null) return [];
    return [
      bounds.topLeft,       // 0: top-left
      bounds.topCenter,     // 1: top-center
      bounds.topRight,      // 2: top-right
      bounds.centerRight,   // 3: right-center
      bounds.bottomRight,   // 4: bottom-right
      bounds.bottomCenter,  // 5: bottom-center
      bounds.bottomLeft,    // 6: bottom-left
      bounds.centerLeft,    // 7: left-center
    ];
  }

  /// Returns the rotation handle position (above the top-center).
  Offset? getRotationHandle() {
    final bounds = selectionBounds;
    if (bounds == null) return null;
    return Offset(bounds.center.dx, bounds.top - CanvasConstants.rotationHandleDistance);
  }

  /// Determines which handle (if any) is at [worldPoint].
  /// Returns the handle index (0-7) or -1 for rotation handle, or null.
  int? hitTestHandles(Offset worldPoint, double tolerance) {
    final handles = getResizeHandles();
    for (var i = 0; i < handles.length; i++) {
      if ((worldPoint - handles[i]).distance <= tolerance) return i;
    }
    final rotHandle = getRotationHandle();
    if (rotHandle != null && (worldPoint - rotHandle).distance <= tolerance) {
      return -1;
    }
    return null;
  }

  // ─── Drag State ───────────────────────────────────────────────────────────

  void startDrag() {
    _isDragging = true;
    notifyListeners();
  }

  void endDrag() {
    _isDragging = false;
    notifyListeners();
  }

  // ─── Internal ─────────────────────────────────────────────────────────────

  void _invalidate() {
    _selectionBounds = null;
    notifyListeners();
  }
}

/// Identifies which handle is being manipulated.
enum HandlePosition {
  topLeft, topCenter, topRight,
  centerRight, bottomRight, bottomCenter, bottomLeft, centerLeft,
  rotation,
}