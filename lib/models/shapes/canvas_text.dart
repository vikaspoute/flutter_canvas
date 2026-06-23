import 'dart:ui';
import 'package:flutter/material.dart';
import '../canvas_object.dart';
import '../../core/constants.dart';
import '../../core/extensions.dart';
import '../../utils/transform_utils.dart';

/// Text object rendered directly on the canvas.
class CanvasText extends CanvasObject {
  String text;
  double fontSize;
  String fontFamily;
  FontWeight fontWeight;
  FontStyle fontStyle;
  Color textColor;
  TextAlign textAlign;
  double lineHeight;
  double letterSpacing;
  double maxWidth;

  TextPainter? _cachedPainter;
  String? _cachedTextKey;

  @override
  String get type => 'text';

  CanvasText({
    String? id, String? name,
    double x = 0, double y = 0,
    this.text = '', this.fontSize = CanvasConstants.defaultFontSize,
    this.fontFamily = CanvasConstants.defaultFontFamily,
    this.fontWeight = FontWeight.normal, this.fontStyle = FontStyle.normal,
    this.textColor = CanvasConstants.defaultStrokeColor,
    this.textAlign = TextAlign.left,
    this.lineHeight = CanvasConstants.defaultLineHeight,
    this.letterSpacing = CanvasConstants.defaultLetterSpacing,
    this.maxWidth = double.infinity,
    double? rotation, Offset? scale, double? opacity,
    bool? visible, bool? locked, int? zIndex,
    Map<String, dynamic>? metadata, String? layerId, String? parentId,
  }) : super(
    id: id, name: name ?? 'Text', position: Offset(x, y),
    rotation: rotation, scale: scale, opacity: opacity,
    visible: visible, locked: locked, zIndex: zIndex,
    metadata: metadata, layerId: layerId, parentId: parentId,
  );

  TextPainter get _textPainter {
    final key = '$text|$fontSize|$fontFamily|$fontWeight|$fontStyle|$textAlign|$maxWidth|$lineHeight|$letterSpacing';
    if (_cachedPainter != null && _cachedTextKey == key) return _cachedPainter!;
    final style = TextStyle(
      fontSize: fontSize, fontFamily: fontFamily,
      fontWeight: fontWeight, fontStyle: fontStyle,
      color: textColor, height: lineHeight, letterSpacing: letterSpacing,
    );
    _cachedPainter?.dispose();
    _cachedPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: textAlign,
      maxLines: maxWidth == double.infinity ? null : null,
    )..layout(maxWidth: maxWidth == double.infinity ? double.infinity : maxWidth);
    _cachedTextKey = key;
    return _cachedPainter!;
  }

  @override
  Rect get bounds => Rect.fromLTWH(0, 0, _textPainter.width, _textPainter.height);

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
    if (!visible || text.isEmpty) return;
    final c = ctx.canvas;
    final matrix = TransformUtils.buildMatrix(position: position, rotation: rotation, scale: objectScale);
    c.save();
    c.transform(matrix.storage);
    final effectiveColor = textColor.withAlpha((textColor.alpha * opacity).round());
    final style = TextStyle(
      fontSize: fontSize, fontFamily: fontFamily, fontWeight: fontWeight,
      fontStyle: fontStyle, color: effectiveColor,
      height: lineHeight, letterSpacing: letterSpacing,
    );
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr, textAlign: textAlign,
    )..layout(maxWidth: maxWidth == double.infinity ? double.infinity : maxWidth);
    tp.paint(c, Offset.zero);
    c.restore();
  }

  @override
  CanvasText clone({String? newId}) => CanvasText(
    id: newId, name: name, x: position.dx, y: position.dy,
    text: text, fontSize: fontSize, fontFamily: fontFamily,
    fontWeight: fontWeight, fontStyle: fontStyle, textColor: textColor,
    textAlign: textAlign, lineHeight: lineHeight, letterSpacing: letterSpacing,
    maxWidth: maxWidth, rotation: rotation, scale: objectScale,
    opacity: opacity, visible: visible, locked: locked, zIndex: zIndex,
    metadata: Map.from(metadata), layerId: layerId, parentId: parentId,
  );

  @override
  Map<String, dynamic> toJsonProperties() => {
    'text': text, 'fontSize': fontSize, 'fontFamily': fontFamily,
    'fontWeight': fontWeight.index, 'fontStyle': fontStyle.index,
    'textColor': textColor.toHex(), 'textAlign': textAlign.name,
    'lineHeight': lineHeight, 'letterSpacing': letterSpacing, 'maxWidth': maxWidth,
  };

  factory CanvasText.fromJson(Map<String, dynamic> json) {
    final b = CanvasObject.baseFromJson(json);
    return CanvasText(
      id: b['id'] as String, name: b['name'] as String,
      x: (b['position'] as Offset).dx, y: (b['position'] as Offset).dy,
      text: json['text'] as String? ?? '',
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? CanvasConstants.defaultFontSize,
      fontFamily: json['fontFamily'] as String? ?? CanvasConstants.defaultFontFamily,
      fontWeight: FontWeight.values[json['fontWeight'] as int? ?? 0],
      fontStyle: FontStyle.values[json['fontStyle'] as int? ?? 0],
      textColor: _pc(json['textColor']),
      textAlign: _ta(json['textAlign']),
      lineHeight: (json['lineHeight'] as num?)?.toDouble() ?? CanvasConstants.defaultLineHeight,
      letterSpacing: (json['letterSpacing'] as num?)?.toDouble() ?? 0.0,
      maxWidth: (json['maxWidth'] as num?)?.toDouble() ?? double.infinity,
      rotation: b['rotation'] as double, scale: b['scale'] as Offset,
      opacity: b['opacity'] as double, visible: b['visible'] as bool,
      locked: b['locked'] as bool, zIndex: b['zIndex'] as int,
      metadata: b['metadata'] as Map<String, dynamic>,
      layerId: b['layerId'] as String?, parentId: b['parentId'] as String?,
    );
  }

  static Color _pc(dynamic v) => v == null ? Colors.black
      : Color(int.parse(v.toString().replaceFirst('#', '0x')));

  static TextAlign _ta(dynamic v) {
    switch (v?.toString()) {
      case 'center': return TextAlign.center;
      case 'right': return TextAlign.right;
      case 'justify': return TextAlign.justify;
      case 'end': return TextAlign.end;
      default: return TextAlign.left;
    }
  }
}