import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../canvas_object.dart';
import '../../core/constants.dart';
import '../../core/extensions.dart';
import '../../utils/transform_utils.dart';

/// A straight line between two points.
class CanvasLine extends CanvasObject {
  Offset start;
  Offset end;
  Color strokeColor;
  double strokeWidth;
  StrokeCap lineCap;

  @override
  String get type => 'line';

  CanvasLine({
    String? id, String? name,
    this.start = Offset.zero, this.end = const Offset(100, 0),
    this.strokeColor = CanvasConstants.defaultStrokeColor,
    this.strokeWidth = CanvasConstants.defaultStrokeWidth,
    this.lineCap = StrokeCap.round,
    double? rotation, Offset? scale, double? opacity,
    bool? visible, bool? locked, int? zIndex,
    Map<String, dynamic>? metadata, String? layerId, String? parentId,
  }) : super(
    id: id, name: name ?? 'Line', position: Offset.zero,
    rotation: rotation, scale: scale, opacity: opacity,
    visible: visible, locked: locked, zIndex: zIndex,
    metadata: metadata, layerId: layerId, parentId: parentId,
  );

  @override
  Rect get bounds => Rect.fromPoints(start, end);

  @override
  bool hitTest(Offset worldPoint) {
    if (!visible) return false;
    final inverse = TransformUtils.safeInvert(
      TransformUtils.buildMatrix(position: position, rotation: rotation, scale: objectScale),
    );
    final local = TransformUtils.transformPoint(inverse, worldPoint);
    return _distToSegment(local, start, end) <= (strokeWidth / 2 + 4);
  }

  double _distToSegment(Offset p, Offset a, Offset b) {
    final dx = b.dx - a.dx, dy = b.dy - a.dy;
    final lenSq = dx * dx + dy * dy;
    if (lenSq == 0) return (p - a).distance;
    var t = ((p.dx - a.dx) * dx + (p.dy - a.dy) * dy) / lenSq;
    t = t.clamp(0.0, 1.0);
    final proj = Offset(a.dx + t * dx, a.dy + t * dy);
    return (p - proj).distance;
  }

  @override
  void render(PaintContext ctx) {
    if (!visible) return;
    final c = ctx.canvas;
    final matrix = TransformUtils.buildMatrix(position: position, rotation: rotation, scale: objectScale);
    c.save();
    c.transform(matrix.storage);
    final alpha = (255 * opacity).round();
    c.drawLine(start, end, Paint()
      ..color = strokeColor.withAlpha(alpha)
      ..strokeWidth = strokeWidth
      ..strokeCap = lineCap);
    c.restore();
  }

  @override
  CanvasLine clone({String? newId}) => CanvasLine(
    id: newId, name: name, start: start, end: end,
    strokeColor: strokeColor, strokeWidth: strokeWidth, lineCap: lineCap,
    rotation: rotation, scale: objectScale, opacity: opacity,
    visible: visible, locked: locked, zIndex: zIndex,
    metadata: Map.from(metadata), layerId: layerId, parentId: parentId,
  );

  @override
  Map<String, dynamic> toJsonProperties() => {
    'startX': start.dx, 'startY': start.dy,
    'endX': end.dx, 'endY': end.dy,
    'strokeColor': strokeColor.toHex(),
    'strokeWidth': strokeWidth,
    'lineCap': lineCap.name,
  };

  factory CanvasLine.fromJson(Map<String, dynamic> json) {
    final b = CanvasObject.baseFromJson(json);
    return CanvasLine(
      id: b['id'] as String, name: b['name'] as String,
      start: Offset((json['startX'] as num?)?.toDouble() ?? 0, (json['startY'] as num?)?.toDouble() ?? 0),
      end: Offset((json['endX'] as num?)?.toDouble() ?? 100, (json['endY'] as num?)?.toDouble() ?? 0),
      strokeColor: _pc(json['strokeColor']),
      strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? CanvasConstants.defaultStrokeWidth,
      lineCap: _parseCap(json['lineCap']),
      rotation: b['rotation'] as double, scale: b['scale'] as Offset,
      opacity: b['opacity'] as double, visible: b['visible'] as bool,
      locked: b['locked'] as bool, zIndex: b['zIndex'] as int,
      metadata: b['metadata'] as Map<String, dynamic>,
      layerId: b['layerId'] as String?, parentId: b['parentId'] as String?,
    );
  }

  static Color _pc(dynamic v) => v == null ? CanvasConstants.defaultStrokeColor
      : Color(int.parse(v.toString().replaceFirst('#', '0x')));

  static StrokeCap _parseCap(dynamic v) {
    switch (v?.toString()) {
      case 'butt': return StrokeCap.butt;
      case 'square': return StrokeCap.square;
      default: return StrokeCap.round;
    }
  }
}