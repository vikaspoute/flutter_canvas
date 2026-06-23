import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'canvas_line.dart';
import '../canvas_object.dart';
import '../../core/constants.dart';
import '../../core/extensions.dart';
import '../../utils/transform_utils.dart';

/// A line with an arrowhead at the end point.
class CanvasArrow extends CanvasLine {
  double arrowHeadSize;
  String arrowHeadStyle; // 'filled' or 'open'

  @override
  String get type => 'arrow';

  CanvasArrow({
    String? id, String? name,
    Offset? start, Offset? end,
    Color? strokeColor,
    double strokeWidth = CanvasConstants.defaultStrokeWidth,
    StrokeCap lineCap = StrokeCap.round,
    this.arrowHeadSize = CanvasConstants.defaultArrowHeadSize,
    this.arrowHeadStyle = 'filled',
    double? rotation, Offset? scale, double? opacity,
    bool? visible, bool? locked, int? zIndex,
    Map<String, dynamic>? metadata, String? layerId, String? parentId,
  }) : super(
    id: id, name: name ?? 'Arrow',
    start: start ?? Offset.zero, end: end ?? const Offset(100, 0),
    strokeColor: strokeColor ?? CanvasConstants.defaultStrokeColor,
    strokeWidth: strokeWidth, lineCap: lineCap,
    rotation: rotation, scale: scale, opacity: opacity,
    visible: visible, locked: locked, zIndex: zIndex,
    metadata: metadata, layerId: layerId, parentId: parentId,
  );

  @override
  void render(PaintContext ctx) {
    if (!visible) return;
    super.render(ctx);
    final c = ctx.canvas;
    final matrix = TransformUtils.buildMatrix(position: position, rotation: rotation, scale: objectScale);
    c.save();
    c.transform(matrix.storage);
    final alpha = (255 * opacity).round();
    final dir = (end - start);
    final len = dir.distance;
    if (len < 1) { c.restore(); return; }
    final angle = math.atan2(dir.dy, dir.dx);
    final headAngle = math.pi / 6;
    final tip = end;
    final left = tip - Offset.fromDirection(angle + math.pi - headAngle, arrowHeadSize);
    final right = tip - Offset.fromDirection(angle + math.pi + headAngle, arrowHeadSize);
    final paint = Paint()..color = strokeColor.withAlpha(alpha)..style = PaintingStyle.fill;
    if (arrowHeadStyle == 'filled') {
      c.drawPath(Path()..moveTo(tip.dx, tip.dy)..lineTo(left.dx, left.dy)..lineTo(right.dx, right.dy)..close(), paint);
    } else {
      c.drawPath(Path()..moveTo(tip.dx, tip.dy)..lineTo(left.dx, left.dy)..moveTo(tip.dx, tip.dy)..lineTo(right.dx, right.dy),
        Paint()..color = strokeColor.withAlpha(alpha)..style = PaintingStyle.stroke..strokeWidth = strokeWidth..strokeCap = StrokeCap.round);
    }
    c.restore();
  }

  @override
  CanvasArrow clone({String? newId}) => CanvasArrow(
    id: newId, name: name, start: start, end: end,
    strokeColor: strokeColor, strokeWidth: strokeWidth, lineCap: lineCap,
    arrowHeadSize: arrowHeadSize, arrowHeadStyle: arrowHeadStyle,
    rotation: rotation, scale: objectScale, opacity: opacity,
    visible: visible, locked: locked, zIndex: zIndex,
    metadata: Map.from(metadata), layerId: layerId, parentId: parentId,
  );

  @override
  Map<String, dynamic> toJsonProperties() => {
    ...super.toJsonProperties(),
    'arrowHeadSize': arrowHeadSize, 'arrowHeadStyle': arrowHeadStyle,
  };

  factory CanvasArrow.fromJson(Map<String, dynamic> json) {
    final b = CanvasObject.baseFromJson(json);
    return CanvasArrow(
      id: b['id'] as String, name: b['name'] as String,
      start: Offset((json['startX'] as num?)?.toDouble() ?? 0, (json['startY'] as num?)?.toDouble() ?? 0),
      end: Offset((json['endX'] as num?)?.toDouble() ?? 100, (json['endY'] as num?)?.toDouble() ?? 0),
      strokeColor: Color(int.parse((json['strokeColor'] ?? '#FF000000').toString().replaceFirst('#', '0x'))),
      strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? CanvasConstants.defaultStrokeWidth,
      arrowHeadSize: (json['arrowHeadSize'] as num?)?.toDouble() ?? CanvasConstants.defaultArrowHeadSize,
      arrowHeadStyle: json['arrowHeadStyle'] as String? ?? 'filled',
      rotation: b['rotation'] as double, scale: b['scale'] as Offset,
      opacity: b['opacity'] as double, visible: b['visible'] as bool,
      locked: b['locked'] as bool, zIndex: b['zIndex'] as int,
      metadata: b['metadata'] as Map<String, dynamic>,
      layerId: b['layerId'] as String?, parentId: b['parentId'] as String?,
    );
  }
}