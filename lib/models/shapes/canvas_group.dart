import 'dart:ui';
import 'package:flutter/material.dart';
import '../canvas_object.dart';
import '../../core/constants.dart';
import '../../core/extensions.dart';
import '../../serialization/object_registry.dart';
import '../../utils/transform_utils.dart';

/// A group of canvas objects treated as a single entity.
///
/// Groups support nesting, transformation of children, and serialization.
/// When a group is moved, rotated, or scaled, all children transform together.
class CanvasGroup extends CanvasObject {
  final List<CanvasObject> children;
  Color fillColor;
  Color strokeColor;
  double strokeWidth;
  bool autoBounds;

  @override
  String get type => 'group';

  CanvasGroup({
    String? id, String? name,
    double x = 0, double y = 0,
    List<CanvasObject>? children,
    this.fillColor = Colors.transparent,
    this.strokeColor = Colors.transparent,
    this.strokeWidth = 0,
    this.autoBounds = true,
    double? rotation, Offset? scale, double? opacity,
    bool? visible, bool? locked, int? zIndex,
    Map<String, dynamic>? metadata, String? layerId, String? parentId,
  }) : children = children ?? [],
       super(
    id: id, name: name ?? 'Group', position: Offset(x, y),
    rotation: rotation, scale: scale, opacity: opacity,
    visible: visible, locked: locked, zIndex: zIndex,
    metadata: metadata, layerId: layerId, parentId: parentId,
  ) {
    for (final child in this.children) {
      child.parentId = this.id;
    }
  }

  /// Adds a child object to this group.
  void addChild(CanvasObject child) {
    child.parentId = id;
    children.add(child);
    _markDirty();
  }

  /// Removes a child object from this group.
  void removeChild(String childId) {
    children.removeWhere((c) => c.id == childId);
    _markDirty();
  }

  /// Finds a descendant by ID, searching recursively through nested groups.
  CanvasObject? findDescendant(String objectId) {
    for (final child in children) {
      if (child.id == objectId) return child;
      if (child is CanvasGroup) {
        final found = child.findDescendant(objectId);
        if (found != null) return found;
      }
    }
    return null;
  }

  /// Returns all descendant objects (flattened), including nested groups.
  List<CanvasObject> get allDescendants {
    final result = <CanvasObject>[];
    for (final child in children) {
      result.add(child);
      if (child is CanvasGroup) {
        result.addAll(child.allDescendants);
      }
    }
    return result;
  }

  @override
  Rect get bounds {
    if (children.isEmpty || !autoBounds) return Rect.zero;
    Rect? combined;
    for (final child in children) {
      final childBounds = child.bounds.shift(child.position);
      combined = combined?.expandToInclude(childBounds.topLeft)
          ?.expandToInclude(childBounds.bottomRight) ?? childBounds;
    }
    return combined ?? Rect.zero;
  }

  @override
  bool hitTest(Offset worldPoint) {
    if (!visible) return false;
    for (final child in children.reversed) {
      if (child.hitTest(worldPoint)) return true;
    }
    if (autoBounds) {
      final inverse = TransformUtils.safeInvert(
        TransformUtils.buildMatrix(position: position, rotation: rotation, scale: objectScale),
      );
      final local = TransformUtils.transformPoint(inverse, worldPoint);
      return bounds.contains(local);
    }
    return false;
  }

  @override
  void render(PaintContext ctx) {
    if (!visible) return;
    for (final child in children) {
      if (child.visible) child.render(ctx);
    }
    // Optional group border
    if (strokeColor != Colors.transparent && strokeWidth > 0) {
      final c = ctx.canvas;
      final matrix = TransformUtils.buildMatrix(position: position, rotation: rotation, scale: objectScale);
      c.save();
      c.transform(matrix.storage);
      c.drawRect(bounds, Paint()
        ..color = strokeColor.withAlpha((255 * opacity).round())
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth / objectScale.dx);
      c.restore();
    }
  }

  @override
  CanvasGroup clone({String? newId}) {
    final clonedChildren = children.map((c) {
      final cloned = c.clone();
      cloned.parentId = newId ?? id;
      return cloned;
    }).toList();
    return CanvasGroup(
      id: newId, name: name, x: position.dx, y: position.dy,
      children: clonedChildren, fillColor: fillColor,
      strokeColor: strokeColor, strokeWidth: strokeWidth, autoBounds: autoBounds,
      rotation: rotation, scale: objectScale, opacity: opacity,
      visible: visible, locked: locked, zIndex: zIndex,
      metadata: Map.from(metadata), layerId: layerId, parentId: parentId,
    );
  }

  @override
  Map<String, dynamic> toJsonProperties() => {
    'children': children.map((c) => c.toJson()).toList(),
    'fillColor': fillColor.toHex(), 'strokeColor': strokeColor.toHex(),
    'strokeWidth': strokeWidth, 'autoBounds': autoBounds,
  };

  factory CanvasGroup.fromJson(Map<String, dynamic> json) {
    final b = CanvasObject.baseFromJson(json);
    final childrenJson = (json['children'] as List?) ?? [];
    final children = childrenJson
        .map((c) => CanvasObjectRegistry.instance.fromJson(c as Map<String, dynamic>))
        .toList();
    return CanvasGroup(
      id: b['id'] as String, name: b['name'] as String,
      x: (b['position'] as Offset).dx, y: (b['position'] as Offset).dy,
      children: children,
      fillColor: _pc(json['fillColor']),
      strokeColor: _pc(json['strokeColor']),
      strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 0,
      autoBounds: json['autoBounds'] as bool? ?? true,
      rotation: b['rotation'] as double, scale: b['scale'] as Offset,
      opacity: b['opacity'] as double, visible: b['visible'] as bool,
      locked: b['locked'] as bool, zIndex: b['zIndex'] as int,
      metadata: b['metadata'] as Map<String, dynamic>,
      layerId: b['layerId'] as String?, parentId: b['parentId'] as String?,
    );
  }

  static Color _pc(dynamic v) => v == null ? Colors.transparent
      : Color(int.parse(v.toString().replaceFirst('#', '0x')));
}