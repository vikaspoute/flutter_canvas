/// Grid system and smart guides for the canvas.
library;

import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../models/canvas_object.dart';
import '../viewport/canvas_viewport.dart';

/// The type of grid to display.
enum GridType { square, dot, isometric, none }

/// Configuration for the canvas grid.
class GridConfig {
  GridType type;
  double size;
  Color color;
  double opacity;
  bool snapEnabled;
  bool visible;

  GridConfig({
    this.type = GridType.square,
    this.size = CanvasConstants.defaultGridSize,
    this.color = const Color(0xFFD0D0D0),
    this.opacity = 0.3,
    this.snapEnabled = true,
    this.visible = true,
  });

  GridConfig copyWith({
    GridType? type, double? size, Color? color,
    double? opacity, bool? snapEnabled, bool? visible,
  }) => GridConfig(
    type: type ?? this.type, size: size ?? this.size,
    color: color ?? this.color, opacity: opacity ?? this.opacity,
    snapEnabled: snapEnabled ?? this.snapEnabled, visible: visible ?? this.visible,
  );

  Map<String, dynamic> toJson() => {
    'type': type.name, 'size': size, 'color': color.toHex(),
    'opacity': opacity, 'snapEnabled': snapEnabled, 'visible': visible,
  };

  factory GridConfig.fromJson(Map<String, dynamic> json) => GridConfig(
    type: GridType.values.firstWhere(
      (e) => e.name == json['type'], orElse: () => GridType.square),
    size: (json['size'] as num?)?.toDouble() ?? CanvasConstants.defaultGridSize,
    color: Color(int.parse((json['color'] ?? '#FFD0D0D0').toString().replaceFirst('#', '0x'))),
    opacity: (json['opacity'] as num?)?.toDouble() ?? 0.3,
    snapEnabled: json['snapEnabled'] as bool? ?? true,
    visible: json['visible'] as bool? ?? true,
  );
}

/// Renders the grid on the canvas.
class GridRenderer {
  final GridConfig config;

  GridRenderer(this.config);

  /// Paints the grid within the visible viewport.
  void paint(Canvas canvas, CanvasViewport viewport) {
    if (!config.visible || config.type == GridType.none) return;
    final visibleRect = viewport.visibleWorldRect;
    final inv = viewport.inverseTransform;
    canvas.save();

    switch (config.type) {
      case GridType.square:
        _paintSquareGrid(canvas, visibleRect, inv);
        break;
      case GridType.dot:
        _paintDotGrid(canvas, visibleRect, inv);
        break;
      case GridType.isometric:
        _paintIsometricGrid(canvas, visibleRect, inv);
        break;
      case GridType.none:
        break;
    }
    canvas.restore();
  }

  void _paintSquareGrid(Canvas canvas, Rect visible, Matrix4 inv) {
    final paint = Paint()..color = config.color.withAlpha((255 * config.opacity).round())
      ..strokeWidth = 0.5;
    final left = (visible.left / config.size).floor() * config.size;
    final top = (visible.top / config.size).floor() * config.size;
    final right = (visible.right / config.size).ceil() * config.size;
    final bottom = (visible.bottom / config.size).ceil() * config.size;
    for (var x = left; x <= right; x += config.size) {
      canvas.drawLine(Offset(x, top), Offset(x, bottom), paint);
    }
    for (var y = top; y <= bottom; y += config.size) {
      canvas.drawLine(Offset(left, y), Offset(right, y), paint);
    }
  }

  void _paintDotGrid(Canvas canvas, Rect visible, Matrix4 inv) {
    final paint = Paint()..color = config.color.withAlpha((255 * config.opacity).round());
    final left = (visible.left / config.size).floor() * config.size;
    final top = (visible.top / config.size).floor() * config.size;
    final right = (visible.right / config.size).ceil() * config.size;
    final bottom = (visible.bottom / config.size).ceil() * config.size;
    for (var x = left; x <= right; x += config.size) {
      for (var y = top; y <= bottom; y += config.size) {
        canvas.drawCircle(Offset(x, y), 1.5, paint);
      }
    }
  }

  void _paintIsometricGrid(Canvas canvas, Rect visible, Matrix4 inv) {
    final paint = Paint()..color = config.color.withAlpha((255 * config.opacity).round())
      ..strokeWidth = 0.5;
    final size = config.size;
    final extent = math.max(visible.width, visible.height) * 2;
    final cx = visible.center.dx, cy = visible.center.dy;
    for (var i = -extent.toInt(); i < extent.toInt(); i += size.toInt()) {
      // Lines at 30 and -30 degrees
      final angle1 = math.pi / 3;
      final angle2 = -math.pi / 3;
      final dx1 = math.cos(angle1) * i, dy1 = math.sin(angle1) * i;
      final dx2 = math.cos(angle2) * i, dy2 = math.sin(angle2) * i;
      canvas.drawLine(
        Offset(cx + dx1 - extent, cy + dy1 - extent),
        Offset(cx + dx1 + extent, cy + dy1 + extent), paint);
      canvas.drawLine(
        Offset(cx + dx2 - extent, cy + dy2 - extent),
        Offset(cx + dx2 + extent, cy + dy2 + extent), paint);
    }
  }
}

/// Smart guide system that provides snap-to-object and snap-to-grid assistance.
class SmartGuideSystem {
  final GridConfig gridConfig;
  final CanvasViewport viewport;
  final double snapTolerance;

  /// Currently active alignment/edge guides to draw.
  final List<SmartGuide> activeGuides = [];

  SmartGuideSystem({
    required this.gridConfig,
    required this.viewport,
    this.snapTolerance = CanvasConstants.snapTolerance,
  });

  /// Snaps [point] to the grid if grid snapping is enabled.
  Offset snapToGrid(Offset point) {
    if (!gridConfig.snapEnabled || gridConfig.type == GridType.none) return point;
    final gridSize = gridConfig.size;
    return Offset(
      (point.dx / gridSize).round() * gridSize,
      (point.dy / gridSize).round() * gridSize,
    );
  }

  /// Snaps [point] to the edges and centers of [otherObjects].
  ///
  /// Returns the snapped point and populates [activeGuides] with visual
  /// indicators for any active snaps.
  Offset snapToObjects(Offset point, Iterable<CanvasObject> otherObjects, {Set<String>? excludeIds}) {
    activeGuides.clear();
    var result = point;
    double? bestDx, bestDy;
    final tol = snapTolerance / viewport.zoom;

    for (final obj in otherObjects) {
      if (excludeIds != null && excludeIds.contains(obj.id)) continue;
      if (!obj.visible) continue;
      final b = obj.worldBounds;

      // Snap to left/right/centerX edges
      for (final xEdge in [b.left, b.right, b.center.dx]) {
        final dx = xEdge - point.dx;
        if (dx.abs() < tol) {
          if (bestDx == null || dx.abs() < bestDx.abs()) {
            bestDx = dx;
            activeGuides.clear();
            activeGuides.add(SmartGuide(
              type: SmartGuideType.alignment,
              axis: Axis.vertical,
              position: xEdge,
            ));
          }
        }
      }

      // Snap to top/bottom/centerY edges
      for (final yEdge in [b.top, b.bottom, b.center.dy]) {
        final dy = yEdge - point.dy;
        if (dy.abs() < tol) {
          if (bestDy == null || dy.abs() < bestDy.abs()) {
            bestDy = dy;
            activeGuides.add(SmartGuide(
              type: SmartGuideType.alignment,
              axis: Axis.horizontal,
              position: yEdge,
            ));
          }
        }
      }
    }

    if (bestDx != null) result = Offset(point.dx + bestDx, result.dy);
    if (bestDy != null) result = Offset(result.dx, point.dy + bestDy);
    return result;
  }

  /// Paints the active smart guide lines.
  void paintGuides(Canvas canvas, CanvasViewport viewport) {
    if (activeGuides.isEmpty) return;
    final paint = Paint()
      ..color = const Color(0xFF2196F3)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    final vr = viewport.visibleWorldRect.inflate(1000);
    for (final guide in activeGuides) {
      if (guide.axis == Axis.vertical) {
        canvas.drawLine(Offset(guide.position, vr.top), Offset(guide.position, vr.bottom), paint);
      } else {
        canvas.drawLine(Offset(vr.left, guide.position), Offset(vr.right, guide.position), paint);
      }
    }
  }

  void clearGuides() => activeGuides.clear();
}

/// A visual smart guide indicator.
class SmartGuide {
  final SmartGuideType type;
  final Axis axis;
  final double position;
  final double? distance;

  SmartGuide({required this.type, required this.axis, required this.position, this.distance});
}

enum SmartGuideType { alignment, distance, center }