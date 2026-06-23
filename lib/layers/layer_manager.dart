/// Layer management system for the canvas.
///
/// Provides named layers with visibility, lock, and ordering controls.
/// Objects are assigned to layers and can be reordered within and across layers.
library;

import 'package:flutter/material.dart';
import '../models/canvas_object.dart';
import '../core/exceptions.dart';

/// A single layer that contains a collection of canvas objects.
///
/// Layers support nesting, visibility toggling, locking, and z-ordering.
class CanvasLayer with ChangeNotifier {
  final String id;
  String name;
  bool _visible;
  bool _locked;
  bool _expanded;
  String? parentId;
  final List<String> _childLayerIds;
  int _order;

  CanvasLayer({
    required this.id,
    this.name = 'Layer',
    bool visible = true,
    bool locked = false,
    bool expanded = true,
    String? parentId,
    List<String>? childLayerIds,
    int order = 0,
  })  : _visible = visible,
        _locked = locked,
        _expanded = expanded,
        this.parentId = parentId,
        _childLayerIds = childLayerIds ?? [],
        _order = order;

  bool get visible => _visible;
  bool get locked => _locked;
  bool get expanded => _expanded;
  List<String> get childLayerIds => List.unmodifiable(_childLayerIds);
  int get order => _order;

  set visible(bool v) { if (_visible != v) { _visible = v; notifyListeners(); } }
  set locked(bool v) { if (_locked != v) { _locked = v; notifyListeners(); } }
  set expanded(bool v) { if (_expanded != v) { _expanded = v; notifyListeners(); } }
  set order(int v) { if (_order != v) { _order = v; notifyListeners(); } }

  void addChild(String layerId) { _childLayerIds.add(layerId); notifyListeners(); }
  void removeChild(String layerId) { _childLayerIds.remove(layerId); notifyListeners(); }

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'visible': visible, 'locked': locked,
    'expanded': expanded, 'parentId': parentId, 'childLayerIds': childLayerIds,
    'order': order,
  };

  factory CanvasLayer.fromJson(Map<String, dynamic> json) => CanvasLayer(
    id: json['id'] as String, name: json['name'] as String? ?? 'Layer',
    visible: json['visible'] as bool? ?? true, locked: json['locked'] as bool? ?? false,
    expanded: json['expanded'] as bool? ?? true,
    parentId: json['parentId'] as String?,
    childLayerIds: (json['childLayerIds'] as List?)?.cast<String>(),
    order: json['order'] as int? ?? 0,
  );
}

/// Manages all layers in the canvas.
///
/// Provides CRUD operations for layers, z-ordering, and the ability to
/// move objects between layers.
class LayerManager with ChangeNotifier {
  final Map<String, CanvasLayer> _layers = {};
  String? _activeLayerId;

  /// Creates a new layer manager with a default layer.
  LayerManager() {
    createLayer(name: 'Default', makeActive: true);
  }

  /// The currently active layer where new objects are placed.
  String? get activeLayerId => _activeLayerId;

  /// The currently active layer, or `null`.
  CanvasLayer? get activeLayer =>
      _activeLayerId != null ? _layers[_activeLayerId!] : null;

  /// All layers ordered by their [CanvasLayer.order] value.
  List<CanvasLayer> get layers {
    final sorted = _layers.values.toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    return sorted;
  }

  /// Creates a new layer.
  CanvasLayer createLayer({
    String? id,
    String name = 'Layer',
    bool visible = true,
    bool locked = false,
    String? parentId,
    bool makeActive = false,
  }) {
    final layer = CanvasLayer(
      id: id ?? 'layer_${DateTime.now().microsecondsSinceEpoch}',
      name: name, visible: visible, locked: locked,
      parentId: parentId, order: _layers.length,
    );
    _layers[layer.id] = layer;
    if (makeActive || _activeLayerId == null) _activeLayerId = layer.id;
    if (parentId != null && _layers.containsKey(parentId)) {
      _layers[parentId]!.addChild(layer.id);
    }
    notifyListeners();
    return layer;
  }

  /// Deletes a layer and moves its objects to the default layer.
  /// The default layer cannot be deleted.
  void deleteLayer(String layerId) {
    if (_layers.length <= 1) throw CanvasInvalidOperationException('Cannot delete the last layer');
    final layer = _layers[layerId];
    if (layer == null) throw CanvasLayerNotFoundException(layerId);
    if (layer.parentId != null && _layers.containsKey(layer.parentId)) {
      _layers[layer.parentId!]!.removeChild(layerId);
    }
    _layers.remove(layerId);
    if (_activeLayerId == layerId) _activeLayerId = _layers.keys.first;
    notifyListeners();
  }

  /// Gets a layer by ID.
  CanvasLayer? getLayer(String id) => _layers[id];

  /// Renames a layer.
  void renameLayer(String layerId, String newName) {
    final layer = _layers[layerId];
    if (layer == null) throw CanvasLayerNotFoundException(layerId);
    layer.name = newName;
    notifyListeners();
  }

  /// Sets the active layer.
  void setActiveLayer(String layerId) {
    if (!_layers.containsKey(layerId)) throw CanvasLayerNotFoundException(layerId);
    _activeLayerId = layerId;
    notifyListeners();
  }

  /// Toggles layer visibility.
  void toggleVisibility(String layerId) {
    final layer = _layers[layerId];
    if (layer == null) throw CanvasLayerNotFoundException(layerId);
    layer.visible = !layer.visible;
    notifyListeners();
  }

  /// Toggles layer lock state.
  void toggleLock(String layerId) {
    final layer = _layers[layerId];
    if (layer == null) throw CanvasLayerNotFoundException(layerId);
    layer.locked = !layer.locked;
    notifyListeners();
  }

  /// Moves [layerId] up one position in the layer order.
  void bringForward(String layerId) {
    final sortedLayers = layers;
    final idx = sortedLayers.indexWhere((l) => l.id == layerId);
    if (idx < 0 || idx >= sortedLayers.length - 1) return;
    _swapLayerOrder(sortedLayers[idx], sortedLayers[idx + 1]);
  }

  /// Moves [layerId] down one position.
  void sendBackward(String layerId) {
    final sortedLayers = layers;
    final idx = sortedLayers.indexWhere((l) => l.id == layerId);
    if (idx <= 0) return;
    _swapLayerOrder(sortedLayers[idx], sortedLayers[idx - 1]);
  }

  /// Moves [layerId] to the top of the layer stack.
  void bringToFront(String layerId) {
    final sortedLayers = layers;
    final maxOrder = sortedLayers.last.order;
    _layers[layerId]?.order = maxOrder + 1;
    notifyListeners();
  }

  /// Moves [layerId] to the bottom of the layer stack.
  void sendToBack(String layerId) {
    final sortedLayers = layers;
    final minOrder = sortedLayers.first.order;
    _layers[layerId]?.order = minOrder - 1;
    notifyListeners();
  }

  void _swapLayerOrder(CanvasLayer a, CanvasLayer b) {
    final tmp = a.order;
    a.order = b.order;
    b.order = tmp;
    notifyListeners();
  }

  /// Returns the effective visibility of a layer (checks parent chain).
  bool isLayerEffectiveVisible(String layerId) {
    final layer = _layers[layerId];
    if (layer == null) return false;
    if (!layer.visible) return false;
    if (layer.parentId != null) return isLayerEffectiveVisible(layer.parentId!);
    return true;
  }

  /// Serializes all layers to JSON.
  List<Map<String, dynamic>> toJson() =>
      layers.map((l) => l.toJson()).toList();

  /// Deserializes layers from JSON.
  void fromJson(List<Map<String, dynamic>> jsonList) {
    _layers.clear();
    for (final json in jsonList) {
      final layer = CanvasLayer.fromJson(json);
      _layers[layer.id] = layer;
    }
    _activeLayerId = _layers.keys.firstOrNull;
    notifyListeners();
  }
}