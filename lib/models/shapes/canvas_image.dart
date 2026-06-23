import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../canvas_object.dart';
import '../../core/constants.dart';
import '../../core/extensions.dart';
import '../../utils/transform_utils.dart';

/// An image object on the canvas.
class CanvasImage extends CanvasObject {
  final String? assetPath;
  final String? networkUrl;
  final double displayWidth;
  final double displayHeight;
  final BoxFit fit;
  ui.Image? _resolvedImage;

  @override
  String get type => 'image';

  ui.Image? get resolvedImage => _resolvedImage;

  @override
  Rect get bounds => Rect.fromLTWH(0, 0, displayWidth, displayHeight);

  CanvasImage({
    String? id, String? name,
    double x = 0, double y = 0,
    this.assetPath, this.networkUrl,
    this.displayWidth = 200, this.displayHeight = 200,
    this.fit = BoxFit.contain,
    double? rotation, Offset? scale, double? opacity,
    bool? visible, bool? locked, int? zIndex,
    Map<String, dynamic>? metadata, String? layerId, String? parentId,
  }) : super(
    id: id, name: name ?? 'Image', position: Offset(x, y),
    rotation: rotation, scale: scale, opacity: opacity,
    visible: visible, locked: locked, zIndex: zIndex,
    metadata: metadata, layerId: layerId, parentId: parentId,
  ) {
    if (assetPath != null || networkUrl != null) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    try {
      if (networkUrl != null) {
        final provider = NetworkImage(networkUrl!);
        final completer = Completer<ui.Image>();
        provider.resolve(ImageConfiguration()).addListener(
          ImageStreamListener((info, _) => completer.complete(info.image)),
        );
        _resolvedImage = await completer.future;
      }
    } catch (_) {
      _resolvedImage = null;
    }
    _markDirty();
  }

  /// Load image from an asset path. Call this after construction if needed.
  Future<void> loadFromAsset(String path) async {
    // The caller should handle asset loading via the asset bundle.
    // This is a placeholder for the full implementation.
    _markDirty();
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
    if (_resolvedImage != null) {
      final src = Rect.fromLTWH(0, 0, _resolvedImage!.width.toDouble(), _resolvedImage!.height.toDouble());
      final dstSize = _applyBoxFit(fit, Size(src.width, src.height), Size(displayWidth, displayHeight));
      final dst = Alignment.center.inscribe(dstSize, bounds);
      c.saveLayer(bounds, Paint()..alpha = (255 * opacity).round());
      c.drawImageRect(_resolvedImage!, src, dst, Paint()..filterQuality = FilterQuality.high);
      c.restore();
    } else {
      // Draw placeholder
      c.drawRect(bounds, Paint()..color = Colors.grey.shade200.withAlpha((255 * opacity).round()));
      c.drawRect(bounds, Paint()..color = Colors.grey.shade400.withAlpha((255 * opacity).round())..style = PaintingStyle.stroke..strokeWidth = 1);
      final tp = TextPainter(text: TextSpan(text: 'Image', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)), textDirection: TextDirection.ltr)
        ..layout();
      tp.paint(c, Offset((displayWidth - tp.width) / 2, (displayHeight - tp.height) / 2));
    }
    c.restore();
  }

  Size _applyBoxFit(BoxFit fit, Size source, Size destination) {
    if (source.isEmpty || destination.isEmpty) return Size.zero;
    switch (fit) {
      case BoxFit.fill: return destination;
      case BoxFit.contain:
        final sr = source.width / source.height;
        final dr = destination.width / destination.height;
        return sr > dr
            ? Size(destination.width, destination.width / sr)
            : Size(destination.height * sr, destination.height);
      case BoxFit.cover:
        final sr = source.width / source.height;
        final dr = destination.width / destination.height;
        return sr > dr
            ? Size(destination.height * sr, destination.height)
            : Size(destination.width, destination.width / sr);
      case BoxFit.fitWidth: return Size(destination.width, destination.width / source.width * source.height);
      case BoxFit.fitHeight: return Size(destination.height / source.height * source.width, destination.height);
      case BoxFit.none: return source;
      case BoxFit.scaleDown:
        final contain = _applyBoxFit(BoxFit.contain, source, destination);
        if (contain.width > source.width || contain.height > source.height) return source;
        return contain;
    }
  }

  @override
  CanvasImage clone({String? newId}) => CanvasImage(
    id: newId, name: name, x: position.dx, y: position.dy,
    assetPath: assetPath, networkUrl: networkUrl,
    displayWidth: displayWidth, displayHeight: displayHeight, fit: fit,
    rotation: rotation, scale: objectScale, opacity: opacity,
    visible: visible, locked: locked, zIndex: zIndex,
    metadata: Map.from(metadata), layerId: layerId, parentId: parentId,
  );

  @override
  Map<String, dynamic> toJsonProperties() => {
    'assetPath': assetPath, 'networkUrl': networkUrl,
    'displayWidth': displayWidth, 'displayHeight': displayHeight, 'fit': fit.name,
  };

  factory CanvasImage.fromJson(Map<String, dynamic> json) {
    final b = CanvasObject.baseFromJson(json);
    return CanvasImage(
      id: b['id'] as String, name: b['name'] as String,
      x: (b['position'] as Offset).dx, y: (b['position'] as Offset).dy,
      assetPath: json['assetPath'] as String?, networkUrl: json['networkUrl'] as String?,
      displayWidth: (json['displayWidth'] as num?)?.toDouble() ?? 200,
      displayHeight: (json['displayHeight'] as num?)?.toDouble() ?? 200,
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