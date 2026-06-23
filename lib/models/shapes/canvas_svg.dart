import 'dart:ui';
import 'package:flutter/material.dart';
import '../canvas_object.dart';
import '../../core/constants.dart';
import '../../core/extensions.dart';
import '../../utils/transform_utils.dart';

/// An SVG graphic rendered on the canvas.
class CanvasSvg extends CanvasObject {
  final String svgString;
  double width;
  double height;
  final BoxFit fit;

  @override
  String get type => 'svg';

  CanvasSvg({
    String? id, String? name,
    double x = 0, double y = 0,
    required this.svgString,
    this.width = 200, this.height = 200,
    this.fit = BoxFit.contain,
    double? rotation, Offset? scale, double? opacity,
    bool? visible, bool? locked, int? zIndex,
    Map<String, dynamic>? metadata, String? layerId, String? parentId,
  }) : super(
    id: id, name: name ?? 'SVG', position: Offset(x, y),
    rotation: rotation, scale: scale, opacity: opacity,
    visible: visible, locked: locked, zIndex: zIndex,
    metadata: metadata, layerId: layerId, parentId: parentId,
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
    final alpha = (255 * opacity).round();
    // Draw SVG placeholder with indicator
    c.drawRRect(
      RRect.fromRectAndRadius(bounds, Radius.circular(4)),
      Paint()..color = Colors.purple.shade50.withAlpha(alpha),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(bounds, Radius.circular(4)),
      Paint()
        ..color = Colors.purple.shade200.withAlpha(alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    // Draw "SVG" label
    final tp = TextPainter(
      text: TextSpan(text: 'SVG', style: TextStyle(
        color: Colors.purple.shade400.withAlpha(alpha), fontSize: 14, fontWeight: FontWeight.w600,
      )),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, Offset((width - tp.width) / 2, (height - tp.height) / 2));
    c.restore();
  }

  @override
  CanvasSvg clone({String? newId}) => CanvasSvg(
    id: newId, name: name, x: position.dx, y: position.dy,
    svgString: svgString, width: width, height: height, fit: fit,
    rotation: rotation, scale: objectScale, opacity: opacity,
    visible: visible, locked: locked, zIndex: zIndex,
    metadata: Map.from(metadata), layerId: layerId, parentId: parentId,
  );

  @override
  Map<String, dynamic> toJsonProperties() => {
    'svgString': svgString, 'width': width, 'height': height, 'fit': fit.name,
  };

  factory CanvasSvg.fromJson(Map<String, dynamic> json) {
    final b = CanvasObject.baseFromJson(json);
    return CanvasSvg(
      id: b['id'] as String, name: b['name'] as String,
      x: (b['position'] as Offset).dx, y: (b['position'] as Offset).dy,
      svgString: json['svgString'] as String? ?? '',
      width: (json['width'] as num?)?.toDouble() ?? 200,
      height: (json['height'] as num?)?.toDouble() ?? 200,
      fit: _parseFit(json['fit']),
      rotation: b['rotation'] as double, scale: b['scale'] as Offset,
      opacity: b['opacity'] as double, visible: b['visible'] as bool,
      locked: b['locked'] as bool, zIndex: b['zIndex'] as int,
      metadata: b['metadata'] as Map<String, dynamic>,
      layerId: b['layerId'] as String?, parentId: b['parentId'] as String?,
    );
  }

  static BoxFit _parseFit(dynamic v) {
    switch (v?.toString()) {
      case 'fill': return BoxFit.fill;
      case 'cover': return BoxFit.cover;
      case 'fitWidth': return BoxFit.fitWidth;
      case 'fitHeight': return BoxFit.fitHeight;
      case 'none': return BoxFit.none;
      case 'scaleDown': return BoxFit.scaleDown;
      default: return BoxFit.contain;
    }
  }
}