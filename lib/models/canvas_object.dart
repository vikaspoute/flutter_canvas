/// The abstract base class for all objects on the canvas.
///
/// Every element that appears on the canvas — shapes, text, images, paths,
/// groups, sticky notes, frames — must extend [CanvasObject]. This class
/// provides the common interface for identity, transformation, rendering,
/// hit-testing, and serialization.
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../core/constants.dart';
import '../core/exceptions.dart';
import '../core/extensions.dart';
import '../utils/transform_utils.dart';

/// Abstract base for every canvas element.
///
/// Subclasses must implement:
/// - [type] — a unique string identifier for the object kind.
/// - [bounds] — the axis-aligned bounding box in local coordinates.
/// - [clone] — a deep copy of this object with a new ID.
/// - [render] — drawing logic called by the rendering engine.
/// - [hitTest] — point-in-object test for selection.
///
/// Common properties like [id], [position], [rotation], [scale], [opacity],
/// [visible], [locked], [name], and [metadata] are provided by this base.
///
/// Usage:
/// ```dart
/// final rect = CanvasRect(
///   x: 100, y: 100,
///   width: 200, height: 100,
/// );
/// controller.add(rect);
/// ```
abstract class CanvasObject with ChangeNotifier {
  // ─── Identity ─────────────────────────────────────────────────────────────

  /// Globally unique identifier for this object.
  final String id;

  /// Human-readable name (auto-generated if not provided).
  String name;

  /// A unique string identifying the concrete type of this object.
  ///
  /// Used by the serialization system for polymorphic deserialization.
  String get type;

  // ─── Transform ────────────────────────────────────────────────────────────

  /// Position of the object's origin in world (parent) coordinates.
  Offset _position;

  /// Gets the object's position.
  Offset get position => _position;

  /// Sets the object's position and notifies listeners.
  set position(Offset value) {
    if (_position == value) return;
    _position = value;
    _markDirty();
  }

  /// Rotation in radians, counter-clockwise from the positive x-axis.
  double _rotation;

  /// Gets the object's rotation.
  double get rotation => _rotation;

  /// Sets the object's rotation and notifies listeners.
  set rotation(double value) {
    if (_rotation == value) return;
    _rotation = value;
    _markDirty();
  }

  /// Scale factor. [Offset.dx] is horizontal scale, [Offset.dy] is vertical.
  Offset _objectScale;

  /// Gets the object's scale.
  Offset get objectScale => _objectScale;

  /// Sets the object's scale and notifies listeners.
  set objectScale(Offset value) {
    if (_objectScale == value) return;
    _objectScale = value;
    _markDirty();
  }

  // ─── Appearance ───────────────────────────────────────────────────────────

  /// Opacity of this object (0.0 = fully transparent, 1.0 = fully opaque).
  double _opacity;

  /// Gets the opacity.
  double get opacity => _opacity;

  /// Sets the opacity and notifies listeners.
  set opacity(double value) {
    final clamped = value.clamp(0.0, 1.0);
    if (_opacity == clamped) return;
    _opacity = clamped;
    _markDirty();
  }

  // ─── State ────────────────────────────────────────────────────────────────

  /// Whether this object is visible on the canvas.
  bool _visible;

  /// Gets visibility state.
  bool get visible => _visible;

  /// Sets visibility and notifies listeners.
  set visible(bool value) {
    if (_visible == value) return;
    _visible = value;
    _markDirty();
  }

  /// Whether this object is locked (cannot be moved, resized, or deleted).
  bool _locked;

  /// Gets the locked state.
  bool get locked => _locked;

  /// Sets the locked state and notifies listeners.
  set locked(bool value) {
    if (_locked == value) return;
    _locked = value;
    notifyListeners();
  }

  // ─── Z-ordering ───────────────────────────────────────────────────────────

  /// Z-index for draw ordering within a layer. Higher values are drawn on top.
  int _zIndex;

  /// Gets the z-index.
  int get zIndex => _zIndex;

  /// Sets the z-index and notifies listeners.
  set zIndex(int value) {
    if (_zIndex == value) return;
    _zIndex = value;
    notifyListeners();
  }

  // ─── Metadata ─────────────────────────────────────────────────────────────

  /// Arbitrary key-value metadata attached to this object.
  ///
  /// Useful for storing application-specific data without subclassing.
  Map<String, dynamic> metadata;

  // ─── Parent / Layer ───────────────────────────────────────────────────────

  /// ID of the layer this object belongs to, or `null` for the default layer.
  String? layerId;

  /// ID of the parent group, or `null` if this object is not grouped.
  String? parentId;

  // ─── Dirty Tracking ───────────────────────────────────────────────────────

  /// Whether this object's visual representation needs to be repainted.
  bool _isDirty = true;

  /// Returns `true` if this object needs repainting.
  bool get isDirty => _isDirty;

  /// Marks the object as dirty and notifies listeners.
  void _markDirty() {
    _isDirty = true;
    notifyListeners();
  }

  /// Clears the dirty flag. Called by the renderer after painting.
  void clearDirty() {
    _isDirty = false;
  }

  // ─── Constructor ──────────────────────────────────────────────────────────

  static const _uuid = Uuid();

  /// Creates a new [CanvasObject] with the given properties.
  ///
  /// If [id] is not provided, a new UUID is generated.
  CanvasObject({
    String? id,
    String? name,
    Offset? position,
    double? rotation,
    Offset? scale,
    double? opacity,
    bool? visible,
    bool? locked,
    int? zIndex,
    Map<String, dynamic>? metadata,
    this.layerId,
    this.parentId,
  })  : id = id ?? _uuid.v4(),
        name = name ?? 'Object',
        _position = position ?? Offset.zero,
        _rotation = rotation ?? CanvasConstants.defaultRotation,
        _objectScale = scale ?? const Offset(1.0, 1.0),
        _opacity = opacity ?? CanvasConstants.defaultOpacity,
        _visible = visible ?? true,
        _locked = locked ?? false,
        _zIndex = zIndex ?? 0,
        metadata = metadata ?? const {};

  // ─── Bounds ───────────────────────────────────────────────────────────────

  /// The axis-aligned bounding box of this object in **local** coordinates
  /// (before transform is applied).
  Rect get bounds;

  /// The bounding box of this object in **world** coordinates, taking into
  /// account position, rotation, and scale.
  Rect get worldBounds {
    if (rotation == 0.0 && objectScale == const Offset(1.0, 1.0)) {
      return bounds.shift(position);
    }
    final matrix = TransformUtils.buildMatrix(
      position: position,
      rotation: rotation,
      scale: objectScale,
    );
    return TransformUtils.transformRect(matrix, bounds);
  }

  // ─── Hit Testing ──────────────────────────────────────────────────────────

  /// Tests whether [worldPoint] (in world coordinates) intersects this object.
  ///
  /// Returns `true` if the point is inside the object's visible area.
  /// Implementations should account for stroke width and other visual
  /// properties that extend beyond the geometric bounds.
  bool hitTest(Offset worldPoint);

  /// Tests whether this object's world bounds fully contain [rect].
  bool containsRect(Rect rect) => worldBounds.containsRect(rect);

  /// Tests whether this object's world bounds overlap [rect].
  bool overlapsRect(Rect rect) => worldBounds.overlapsRect(rect);

  // ─── Rendering ────────────────────────────────────────────────────────────

  /// Draws this object onto [canvas] using the given [paintContext].
  ///
  /// The [paintContext] provides the combined transform that maps local
  /// coordinates to screen coordinates. Implementations should apply
  /// any additional local transforms before drawing.
  ///
  /// [paintContext] is a [PaintContext] containing the Canvas, the
  /// screen-to-world transform, and other rendering state.
  void render(PaintContext paintContext);

  // ─── Cloning ──────────────────────────────────────────────────────────────

  /// Creates a deep copy of this object with a new [id].
  ///
  /// All mutable properties are copied. The returned object is fully
  /// independent from the original.
  CanvasObject clone({String? newId});

  // ─── Serialization ────────────────────────────────────────────────────────

  /// Serializes this object to a JSON-compatible map.
  ///
  /// Subclasses should override [toJsonProperties] to add their own
  /// properties. The base [toJson] method handles common properties.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'name': name,
      'x': position.dx,
      'y': position.dy,
      'rotation': rotation,
      'scaleX': objectScale.dx,
      'scaleY': objectScale.dy,
      'opacity': opacity,
      'visible': visible,
      'locked': locked,
      'zIndex': zIndex,
      'layerId': layerId,
      'parentId': parentId,
      'metadata': metadata.isEmpty ? null : metadata,
      ...toJsonProperties(),
    };
  }

  /// Serializes subclass-specific properties.
  ///
  /// Override this in subclasses to add type-specific fields.
  Map<String, dynamic> toJsonProperties();

  /// Deserializes common properties from a JSON map.
  ///
  /// Subclasses should override [fromJsonProperties] to read their own fields.
  /// Call `super.fromJsonFactory(json)` from subclass factory constructors.
  static Map<String, Object> baseFromJson(Map<String, dynamic> json) {
    return {
      'id': json['id'] as String? ?? _uuid.v4(),
      'name': json['name'] as String? ?? 'Object',
      'position': Offset(
        (json['x'] as num?)?.toDouble() ?? 0.0,
        (json['y'] as num?)?.toDouble() ?? 0.0,
      ),
      'rotation': (json['rotation'] as num?)?.toDouble() ?? 0.0,
      'scale': Offset(
        (json['scaleX'] as num?)?.toDouble() ?? 1.0,
        (json['scaleY'] as num?)?.toDouble() ?? 1.0,
      ),
      'opacity': (json['opacity'] as num?)?.toDouble() ?? 1.0,
      'visible': json['visible'] as bool? ?? true,
      'locked': json['locked'] as bool? ?? false,
      'zIndex': json['zIndex'] as int? ?? 0,
      'layerId': json['layerId'] as String?,
      'parentId': json['parentId'] as String?,
      'metadata': json['metadata'] as Map<String, dynamic>? ?? const {},
    };
  }

  // ─── Object-level equality (by ID) ───────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CanvasObject && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => '$type(id: $id, name: $name)';
}

/// Rendering context passed to [CanvasObject.render].
///
/// Provides the underlying [Canvas] and the current viewport transform
/// so that objects can draw themselves in the correct coordinate space.
class PaintContext {
  /// The Flutter [Canvas] to draw on.
  final Canvas canvas;

  /// The current viewport transform (world → screen).
  final Matrix4 viewportTransform;

  /// The effective pixel ratio of the display.
  final double pixelRatio;

  /// The current zoom level of the viewport.
  final double zoom;

  /// Creates a new [PaintContext].
  const PaintContext({
    required this.canvas,
    required this.viewportTransform,
    required this.pixelRatio,
    required this.zoom,
  });
}