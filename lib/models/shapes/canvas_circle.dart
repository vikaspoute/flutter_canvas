import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../canvas_object.dart';
import '../../core/constants.dart';
import '../../core/extensions.dart';
import '../../utils/transform_utils.dart';

/// A circular shape on the canvas.
class CanvasCircle extends CanvasObject {
  double radius;
  Color fillColor;
  Color strokeColor;
  double strokeWidth;

  @override
  String get type => 'circle';

  CanvasCircle({
    String? id,
    String? name,
    double x = 0,
    double y = 0,
    required this.radius,
    this.fillColor = CanvasConstants.defaultFillColor,
    this.strokeColor = CanvasConstants.defaultStrokeColor,
    this.strokeWidth = CanvasConstants.defaultStrokeWidth,
    double? rotation,
    Offset? scale,
    double? opacity,
    bool? visible,
    bool? locked,
    int? zIndex,
    Map<String, dynamic>? metadata,
    String? layerId,
    String? parentId,
  }) : super(
          id: id,
          name: name ?? 'Circle',
          position: Offset(x, y),
          rotation: rotation,
          scale: scale,
          opacity: opacity,
          visible: visible,
          locked: locked,
          zIndex: zIndex,
          metadata: metadata,
          layerId: layerId,
          parentId: parentId,
        );

  @override
  Rect get bounds => Rect.fromLTRB(-radius, -radius, radius, radius);

  @override
  bool hitTest(Offset worldPoint) {
    if (!visible) return false;
    final dist = (worldPoint - position).distance;
    final effectiveRadius = radius * math.max(objectScale.dx.abs(), objectScale.dy.abs());
    return dist <= effectiveRadius + strokeWidth / 2;
  }

  @override
  void render(PaintContext ctx) {
    if (!visible) return;
    final c = ctx.canvas;
    final matrix = TransformUtils.buildMatrix(position: position, rotation: rotation, scale: objectScale);
    c.save();
    c.transform(matrix.storage);
    final alpha = (255 * opacity).round();
    if (fillColor != Colors.transparent) {
      c.drawCircle(Offset.zero, radius, Paint()..color = fillColor.withAlpha(alpha));
    }
    if (strokeColor != Colors.transparent && strokeWidth > 0) {
      c.drawCircle(Offset.zero, radius, Paint()..color = strokeColor.withAlpha(alpha)..style = PaintingStyle.stroke..strokeWidth = strokeWidth);
    }
    c.restore();
  }

  @override
  CanvasCircle clone({String? newId}) => CanvasCircle(
        id: newId, name: name, x: position.dx, y: position.dy,
        radius: radius, fillColor: fillColor, strokeColor: strokeColor,
        strokeWidth: strokeWidth, rotation: rotation, scale: objectScale,
        opacity: opacity, visible: visible, locked: locked, zIndex: zIndex,
        metadata: Map.from(metadata), layerId: layerId, parentId: parentId,
      );

  @override
  Map<String, dynamic> toJsonProperties() => {
        'radius': radius, 'fillColor': fillColor.toHex(),
        'strokeColor': strokeColor.toHex(), 'strokeWidth': strokeWidth,
      };

  factory CanvasCircle.fromJson(Map<String, dynamic> json) {
    final b = CanvasObject.baseFromJson(json);
    return CanvasCircle(
      id: b['id'] as String, name: b['name'] as String,
      x: (b['position'] as Offset).dx, y: (b['position'] as Offset).dy,
      radius: (json['radius'] as num).toDouble(),
      fillColor: _pc(json['fillColor']), strokeColor: _pc(json['strokeColor']),
      strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? CanvasConstants.defaultStrokeWidth,
      rotation: b['rotation'] as double, scale: b['scale'] as Offset,
      opacity: b['opacity'] as double, visible: b['visible'] as bool,
      locked: b['locked'] as bool, zIndex: b['zIndex'] as int,
      metadata: b['metadata'] as Map<String, dynamic>,
      layerId: b['layerId'] as String?, parentId: b['parentId'] as String?,
    );
  }

  static Color _pc(dynamic v) => v == null ? CanvasConstants.defaultFillColor
      : Color(int.parse(v.toString().replaceFirst('#', '0x')));
}