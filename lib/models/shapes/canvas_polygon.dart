import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'canvas_path.dart';

/// A regular polygon with a configurable number of sides.
class CanvasPolygon extends CanvasPath {
  int sides;
  double radius;

  @override
  String get type => 'polygon';

  CanvasPolygon({
    String? id, String? name,
    double x = 0, double y = 0,
    this.sides = 6, this.radius = 50,
    Color? strokeColor, double strokeWidth = 2.0,
    Color? fillColor, bool closed = true,
    double? rotation, Offset? scale, double? opacity,
    bool? visible, bool? locked, int? zIndex,
    Map<String, dynamic>? metadata, String? layerId, String? parentId,
  }) : super(
    id: id, name: name ?? 'Polygon', x: x, y: y,
    points: _generatePoints(sides, radius),
    strokeColor: strokeColor ?? const Color(0xFF000000),
    strokeWidth: strokeWidth,
    fillColor: fillColor ?? const Color(0xFFFFFFFF),
    fill: fillColor != null && fillColor != Colors.transparent,
    closed: closed,
    rotation: rotation, scale: scale, opacity: opacity,
    visible: visible, locked: locked, zIndex: zIndex,
    metadata: metadata, layerId: layerId, parentId: parentId,
  );

  static List<Offset> _generatePoints(int sides, double radius) {
    final pts = <Offset>[];
    for (var i = 0; i < sides; i++) {
      final angle = (2 * math.pi * i / sides) - math.pi / 2;
      pts.add(Offset(math.cos(angle) * radius, math.sin(angle) * radius));
    }
    return pts;
  }

  @override
  CanvasPolygon clone({String? newId}) => CanvasPolygon(
    id: newId, name: name, x: position.dx, y: position.dy,
    sides: sides, radius: radius,
    strokeColor: strokeColor, strokeWidth: strokeWidth,
    fillColor: fill ? fillColor : null, closed: closed,
    rotation: rotation, scale: objectScale, opacity: opacity,
    visible: visible, locked: locked, zIndex: zIndex,
    metadata: Map.from(metadata), layerId: layerId, parentId: parentId,
  );

  @override
  Map<String, dynamic> toJsonProperties() => {
    ...super.toJsonProperties(), 'sides': sides, 'radius': radius,
  };

  factory CanvasPolygon.fromJson(Map<String, dynamic> json) {
    final b = CanvasObject.baseFromJson(json);
    final pts = (json['points'] as List?)?.map((e) => Offset((e[0] as num).toDouble(), (e[1] as num).toDouble())).toList();
    return CanvasPolygon(
      id: b['id'] as String, name: b['name'] as String,
      x: (b['position'] as Offset).dx, y: (b['position'] as Offset).dy,
      sides: json['sides'] as int? ?? 6,
      radius: json['radius'] as num? ?? 50,
      strokeColor: Color(int.parse((json['strokeColor'] ?? '#FF000000').toString().replaceFirst('#', '0x'))),
      strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 2.0,
      fillColor: Color(int.parse((json['fillColor'] ?? '#FFFFFFFF').toString().replaceFirst('#', '0x'))),
      closed: json['closed'] as bool? ?? true,
      rotation: b['rotation'] as double, scale: b['scale'] as Offset,
      opacity: b['opacity'] as double, visible: b['visible'] as bool,
      locked: b['locked'] as bool, zIndex: b['zIndex'] as int,
      metadata: b['metadata'] as Map<String, dynamic>,
      layerId: b['layerId'] as String?, parentId: b['parentId'] as String?,
    )..points = pts ?? _generatePoints(json['sides'] as int? ?? 6, (json['radius'] as num?)?.toDouble() ?? 50);
  }
}