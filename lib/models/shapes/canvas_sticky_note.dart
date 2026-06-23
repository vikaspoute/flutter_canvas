import 'dart:ui';
import 'package:flutter/material.dart';
import '../canvas_object.dart';
import '../../core/constants.dart';
import '../../core/extensions.dart';
import '../../utils/transform_utils.dart';

/// A sticky note widget on the canvas (Miro-style).
class CanvasStickyNote extends CanvasObject {
  String text;
  Color backgroundColor;
  Color textColor;
  double width;
  double fontSize;
  String fontFamily;
  double padding;

  @override
  String get type => 'sticky_note';

  CanvasStickyNote({
    String? id, String? name,
    double x = 0, double y = 0,
    this.text = '', this.backgroundColor = CanvasConstants.stickyNoteColor,
    this.textColor = const Color(0xFF333333),
    this.width = CanvasConstants.maxStickyNoteWidth,
    this.fontSize = CanvasConstants.defaultFontSize,
    this.fontFamily = CanvasConstants.defaultFontFamily,
    this.padding = 16.0,
    double? rotation, Offset? scale, double? opacity,
    bool? visible, bool? locked, int? zIndex,
    Map<String, dynamic>? metadata, String? layerId, String? parentId,
  }) : super(
    id: id, name: name ?? 'Sticky Note', position: Offset(x, y),
    rotation: rotation, scale: scale, opacity: opacity,
    visible: visible, locked: locked, zIndex: zIndex,
    metadata: metadata, layerId: layerId, parentId: parentId,
  );

  TextPainter get _textPainter {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(fontSize: fontSize, fontFamily: fontFamily, color: textColor, height: 1.4)),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: width - padding * 2);
    return tp;
  }

  @override
  Rect get bounds {
    final tp = _textPainter;
    return Rect.fromLTWH(0, 0, width, tp.height + padding * 2);
  }

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
    final rrect = RRect.fromRectAndRadius(bounds, Radius.circular(4));
    // Shadow
    c.drawRRect(rrect.shift(const Offset(2, 4)), Paint()..color = Colors.black.withAlpha(40));
    // Background
    c.drawRRect(rrect, Paint()..color = backgroundColor.withAlpha(alpha));
    // Text
    final tp = _textPainter;
    tp.paint(c, Offset(padding, padding));
    c.restore();
  }

  @override
  CanvasStickyNote clone({String? newId}) => CanvasStickyNote(
    id: newId, name: name, x: position.dx, y: position.dy,
    text: text, backgroundColor: backgroundColor, textColor: textColor,
    width: width, fontSize: fontSize, fontFamily: fontFamily, padding: padding,
    rotation: rotation, scale: objectScale, opacity: opacity,
    visible: visible, locked: locked, zIndex: zIndex,
    metadata: Map.from(metadata), layerId: layerId, parentId: parentId,
  );

  @override
  Map<String, dynamic> toJsonProperties() => {
    'text': text, 'backgroundColor': backgroundColor.toHex(),
    'textColor': textColor.toHex(), 'width': width,
    'fontSize': fontSize, 'fontFamily': fontFamily, 'padding': padding,
  };

  factory CanvasStickyNote.fromJson(Map<String, dynamic> json) {
    final b = CanvasObject.baseFromJson(json);
    return CanvasStickyNote(
      id: b['id'] as String, name: b['name'] as String,
      x: (b['position'] as Offset).dx, y: (b['position'] as Offset).dy,
      text: json['text'] as String? ?? '',
      backgroundColor: _pc(json['backgroundColor']) ?? CanvasConstants.stickyNoteColor,
      textColor: _pc(json['textColor']) ?? const Color(0xFF333333),
      width: (json['width'] as num?)?.toDouble() ?? CanvasConstants.maxStickyNoteWidth,
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? CanvasConstants.defaultFontSize,
      fontFamily: json['fontFamily'] as String? ?? CanvasConstants.defaultFontFamily,
      padding: (json['padding'] as num?)?.toDouble() ?? 16.0,
      rotation: b['rotation'] as double, scale: b['scale'] as Offset,
      opacity: b['opacity'] as double, visible: b['visible'] as bool,
      locked: b['locked'] as bool, zIndex: b['zIndex'] as int,
      metadata: b['metadata'] as Map<String, dynamic>,
      layerId: b['layerId'] as String?, parentId: b['parentId'] as String?,
    );
  }

  static Color? _pc(dynamic v) => v == null ? null
      : Color(int.parse(v.toString().replaceFirst('#', '0x')));
}