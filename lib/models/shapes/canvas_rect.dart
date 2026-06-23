/// Canvas rectangle shape.
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import '../canvas_object.dart';
import '../../core/constants.dart';
import '../../core/extensions.dart';
import '../../utils/transform_utils.dart';

/// A rectangular shape on the canvas.
///
/// Supports rounded corners, fill, stroke, and all standard transforms.
class CanvasRect extends CanvasObject {
  double width;
  double height;
  double cornerRadius;
  Color fillColor;
  Color strokeColor;
  double strokeWidth;

  @override
  String get type => 'rect';

  CanvasRect({
    String? id,
    String? name,
    double x = 0,
    double y = 0,
    required this.width,
    required this.height,
    this.cornerRadius = CanvasConstants.defaultCornerRadius,
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
          name: name ?? 'Rectangle',
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
  Rect get bounds => Rect.fromLTWH(0, 0, width, height);

  @override
  bool hitTest(Offset worldPoint) {
    if (!visible) return false;
    final inverse = TransformUtils.safeInvert(
      TransformUtils.buildMatrix(position: position, rotation: rotation, scale: objectScale),
    );
    final local = TransformUtils.transformPoint(inverse, worldPoint);
    return bounds.contains(local);
  }

  @override
  void render(PaintContext ctx) {
    if (!visible) return;
    final c = ctx.canvas;
    final matrix = TransformUtils.buildMatrix(position: position, rotation: rotation, scale: objectScale);
    c.save();
    c.transform(matrix.storage);
    final rrect = RRect.fromRectAndRadius(bounds, Radius.circular(cornerRadius));
    final fillPaint = Paint()..color = fillColor.withAlpha((fillColor.alpha * opacity).round());
    if (fillColor != Colors.transparent) c.drawRRect(rrect, fillPaint);
    if (strokeColor != Colors.transparent && strokeWidth > 0) {
      c.drawRRect(rrect, Paint()..color = strokeColor.withAlpha((strokeColor.alpha * opacity).round())..style = PaintingStyle.stroke..strokeWidth = strokeWidth);
    }
    c.restore();
  }

  @override
  CanvasRect clone({String? newId}) => CanvasRect(
        id: newId,
        name: name,
        x: position.dx,
        y: position.dy,
        width: width,
        height: height,
        cornerRadius: cornerRadius,
        fillColor: fillColor,
        strokeColor: strokeColor,
        strokeWidth: strokeWidth,
        rotation: rotation,
        scale: objectScale,
        opacity: opacity,
        visible: visible,
        locked: locked,
        zIndex: zIndex,
        metadata: Map.from(metadata),
        layerId: layerId,
        parentId: parentId,
      );

  @override
  Map<String, dynamic> toJsonProperties() => {
        'width': width,
        'height': height,
        'cornerRadius': cornerRadius,
        'fillColor': fillColor.toHex(),
        'strokeColor': strokeColor.toHex(),
        'strokeWidth': strokeWidth,
      };

  factory CanvasRect.fromJson(Map<String, dynamic> json) {
    final b = CanvasObject.baseFromJson(json);
    return CanvasRect(
      id: b['id'] as String,
      name: b['name'] as String,
      x: (b['position'] as Offset).dx,
      y: (b['position'] as Offset).dy,
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      cornerRadius: (json['cornerRadius'] as num?)?.toDouble() ?? 0.0,
      fillColor: _parseColor(json['fillColor']),
      strokeColor: _parseColor(json['strokeColor']),
      strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? CanvasConstants.defaultStrokeWidth,
      rotation: b['rotation'] as double,
      scale: b['scale'] as Offset,
      opacity: b['opacity'] as double,
      visible: b['visible'] as bool,
      locked: b['locked'] as bool,
      zIndex: b['zIndex'] as int,
      metadata: b['metadata'] as Map<String, dynamic>,
      layerId: b['layerId'] as String?,
      parentId: b['parentId'] as String?,
    );
  }

  static Color _parseColor(dynamic v) {
    if (v == null) return CanvasConstants.defaultFillColor;
    return Color(int.parse(v.toString().replaceFirst('#', '0x')));
  }
}