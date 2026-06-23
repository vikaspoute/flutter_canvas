import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../canvas_object.dart';
import '../../core/constants.dart';
import '../../core/extensions.dart';
import '../../utils/transform_utils.dart';

/// A freehand path drawn with pen/brush tools.
class CanvasPath extends CanvasObject {
  List<Offset> points;
  Color strokeColor;
  double strokeWidth;
  Color fillColor;
  bool fill;
  bool smoothingEnabled;
  bool closed;

  @override
  String get type => 'path';

  CanvasPath({
    String? id, String? name,
    double x = 0, double y = 0,
    List<Offset>? points,
    this.strokeColor = CanvasConstants.defaultStrokeColor,
    this.strokeWidth = CanvasConstants.defaultStrokeWidth,
    this.fillColor = Colors.transparent,
    this.fill = false,
    this.smoothingEnabled = true,
    this.closed = false,
    double? rotation, Offset? scale, double? opacity,
    bool? visible, bool? locked, int? zIndex,
    Map<String, dynamic>? metadata, String? layerId, String? parentId,
  }) : points = points ?? [],
       super(
    id: id, name: name ?? 'Path', position: Offset(x, y),
    rotation: rotation, scale: scale, opacity: opacity,
    visible: visible, locked: locked, zIndex: zIndex,
    metadata: metadata, layerId: layerId, parentId: parentId,
  );

  @override
  Rect get bounds {
    if (points.isEmpty) return Rect.zero;
    double minX = points[0].dx, minY = points[0].dy;
    double maxX = points[0].dx, maxY = points[0].dy;
    for (final p in points) {
      if (p.dx < minX) minX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy > maxY) maxY = p.dy;
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY).inflate(strokeWidth / 2);
  }

  Path _buildSmoothPath() {
    final path = Path();
    if (points.isEmpty) return path;
    if (!smoothingEnabled || points.length < 3) {
      path.moveTo(points[0].dx, points[0].dy);
      for (var i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
    } else {
      path.moveTo(points[0].dx, points[0].dy);
      for (var i = 0; i < points.length - 1; i++) {
        final p0 = points[i];
        final p1 = points[i + 1];
        final mx = (p0.dx + p1.dx) / 2;
        final my = (p0.dy + p1.dy) / 2;
        if (i == 0) {
          path.lineTo(mx, my);
        } else {
          path.quadraticBezierTo(p0.dx, p0.dy, mx, my);
        }
      }
      path.lineTo(points.last.dx, points.last.dy);
    }
    if (closed) path.close();
    return path;
  }

  @override
  bool hitTest(Offset worldPoint) {
    if (!visible || points.isEmpty) return false;
    final inverse = TransformUtils.safeInvert(
      TransformUtils.buildMatrix(position: position, rotation: rotation, scale: objectScale),
    );
    final local = TransformUtils.transformPoint(inverse, worldPoint);
    if (fill) return _buildSmoothPath().contains(local);
    for (var i = 0; i < points.length - 1; i++) {
      final a = points[i], b = points[i + 1];
      final dx = b.dx - a.dx, dy = b.dy - a.dy;
      final lenSq = dx * dx + dy * dy;
      if (lenSq == 0) continue;
      var t = ((local.dx - a.dx) * dx + (local.dy - a.dy) * dy) / lenSq;
      t = t.clamp(0.0, 1.0);
      final proj = Offset(a.dx + t * dx, a.dy + t * dy);
      if ((local - proj).distance <= strokeWidth / 2 + 4) return true;
    }
    return false;
  }

  @override
  void render(PaintContext ctx) {
    if (!visible || points.isEmpty) return;
    final c = ctx.canvas;
    final matrix = TransformUtils.buildMatrix(position: position, rotation: rotation, scale: objectScale);
    c.save();
    c.transform(matrix.storage);
    final path = _buildSmoothPath();
    final alpha = (255 * opacity).round();
    if (fill && fillColor != Colors.transparent) {
      c.drawPath(path, Paint()..color = fillColor.withAlpha(alpha));
    }
    c.drawPath(path, Paint()
      ..color = strokeColor.withAlpha(alpha)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round);
    c.restore();
  }

  @override
  CanvasPath clone({String? newId}) => CanvasPath(
    id: newId, name: name, x: position.dx, y: position.dy,
    points: List.from(points), strokeColor: strokeColor, strokeWidth: strokeWidth,
    fillColor: fillColor, fill: fill, smoothingEnabled: smoothingEnabled,
    closed: closed, rotation: rotation, scale: objectScale, opacity: opacity,
    visible: visible, locked: locked, zIndex: zIndex,
    metadata: Map.from(metadata), layerId: layerId, parentId: parentId,
  );

  @override
  Map<String, dynamic> toJsonProperties() => {
    'points': points.map((p) => [p.dx, p.dy]).toList(),
    'strokeColor': strokeColor.toHex(), 'strokeWidth': strokeWidth,
    'fillColor': fillColor.toHex(), 'fill': fill,
    'smoothingEnabled': smoothingEnabled, 'closed': closed,
  };

  factory CanvasPath.fromJson(Map<String, dynamic> json) {
    final b = CanvasObject.baseFromJson(json);
    final pts = (json['points'] as List?)?.map((e) => Offset((e[0] as num).toDouble(), (e[1] as num).toDouble())).toList();
    return CanvasPath(
      id: b['id'] as String, name: b['name'] as String,
      x: (b['position'] as Offset).dx, y: (b['position'] as Offset).dy,
      points: pts, strokeColor: _pc(json['strokeColor']),
      strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? CanvasConstants.defaultStrokeWidth,
      fillColor: _pc(json['fillColor']),
      fill: json['fill'] as bool? ?? false,
      smoothingEnabled: json['smoothingEnabled'] as bool? ?? true,
      closed: json['closed'] as bool? ?? false,
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