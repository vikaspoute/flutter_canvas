import 'dart:ui';
import 'package:flutter/material.dart';
import '../canvas_object.dart';
import '../../core/constants.dart';
import '../../core/extensions.dart';
import '../../utils/transform_utils.dart';

/// A frame that groups and labels a region of the canvas (Figma-style).
class CanvasFrame extends CanvasObject {
  String title;
  double width;
  double height;
  Color fillColor;
  Color strokeColor;
  double strokeWidth;
  double cornerRadius;
  bool showTitle;
  double titleBarHeight;

  @override
  String get type => 'frame';

  CanvasFrame({
    String? id, String? name,
    double x = 0, double y = 0,
    this.title = 'Frame', required this.width, required this.height,
    this.fillColor = const Color(0xFFF8F9FA),
    this.strokeColor = const Color(0xFFDEE2E6),
    this.strokeWidth = 1.0, this.cornerRadius = 8.0,
    this.showTitle = true, this.titleBarHeight = 32.0,
    double? rotation, Offset? scale, double? opacity,
    bool? visible, bool? locked, int? zIndex,
    Map<String, dynamic>? metadata, String? layerId, String? parentId,
  }) : super(
    id: id, name: name ?? 'Frame', position: Offset(x, y),
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
    final rrect = RRect.fromRectAndRadius(bounds, Radius.circular(cornerRadius));
    // Background
    c.drawRRect(rrect, Paint()..color = fillColor.withAlpha(alpha));
    // Border
    if (strokeColor != Colors.transparent && strokeWidth > 0) {
      c.drawRRect(rrect, Paint()
        ..color = strokeColor.withAlpha(alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth);
    }
    // Title bar
    if (showTitle && title.isNotEmpty) {
      final titleRect = Rect.fromLTWH(0, 0, width, titleBarHeight);
      final titleRrect = RRect.fromRectAndCorners(titleRect,
        topLeft: Radius.circular(cornerRadius), topRight: Radius.circular(cornerRadius));
      c.drawRRect(titleRrect, Paint()..color = strokeColor.withAlpha((alpha * 0.2).round()));
      final tp = TextPainter(
        text: TextSpan(text: title, style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600,
          color: strokeColor.withAlpha(alpha),
        )),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(c, Offset(12, (titleBarHeight - tp.height) / 2));
    }
    c.restore();
  }

  @override
  CanvasFrame clone({String? newId}) => CanvasFrame(
    id: newId, name: name, x: position.dx, y: position.dy,
    title: title, width: width, height: height,
    fillColor: fillColor, strokeColor: strokeColor, strokeWidth: strokeWidth,
    cornerRadius: cornerRadius, showTitle: showTitle, titleBarHeight: titleBarHeight,
    rotation: rotation, scale: objectScale, opacity: opacity,
    visible: visible, locked: locked, zIndex: zIndex,
    metadata: Map.from(metadata), layerId: layerId, parentId: parentId,
  );

  @override
  Map<String, dynamic> toJsonProperties() => {
    'title': title, 'width': width, 'height': height,
    'fillColor': fillColor.toHex(), 'strokeColor': strokeColor.toHex(),
    'strokeWidth': strokeWidth, 'cornerRadius': cornerRadius,
    'showTitle': showTitle, 'titleBarHeight': titleBarHeight,
  };

  factory CanvasFrame.fromJson(Map<String, dynamic> json) {
    final b = CanvasObject.baseFromJson(json);
    return CanvasFrame(
      id: b['id'] as String, name: b['name'] as String,
      x: (b['position'] as Offset).dx, y: (b['position'] as Offset).dy,
      title: json['title'] as String? ?? 'Frame',
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      fillColor: _pc(json['fillColor']),
      strokeColor: _pc(json['strokeColor']),
      strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 1.0,
      cornerRadius: (json['cornerRadius'] as num?)?.toDouble() ?? 8.0,
      showTitle: json['showTitle'] as bool? ?? true,
      titleBarHeight: (json['titleBarHeight'] as num?)?.toDouble() ?? 32.0,
      rotation: b['rotation'] as double, scale: b['scale'] as Offset,
      opacity: b['opacity'] as double, visible: b['visible'] as bool,
      locked: b['locked'] as bool, zIndex: b['zIndex'] as int,
      metadata: b['metadata'] as Map<String, dynamic>,
      layerId: b['layerId'] as String?, parentId: b['parentId'] as String?,
    );
  }

  static Color _pc(dynamic v) => v == null ? const Color(0xFFF8F9FA)
      : Color(int.parse(v.toString().replaceFirst('#', '0x')));
}