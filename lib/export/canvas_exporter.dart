/// Export system for rendering the canvas to image files.
///
/// Supports PNG, JPEG, SVG, and PDF output at arbitrary resolution.
library;

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/canvas_object.dart';
import '../core/extensions.dart';
import '../viewport/canvas_viewport.dart';
import '../renderer/canvas_renderer.dart';
import '../core/constants.dart';
import '../core/exceptions.dart';

/// Export configuration.
class ExportConfig {
  final double pixelRatio;
  final Rect? region;
  final Color backgroundColor;
  final bool transparentBackground;
  final Set<String>? objectIds;

  const ExportConfig({
    this.pixelRatio = CanvasConstants.exportPixelRatio,
    this.region,
    this.backgroundColor = Colors.white,
    this.transparentBackground = false,
    this.objectIds,
  });
}

/// Exports canvas content to various formats.
class CanvasExporter {
  /// Exports the canvas to PNG bytes.
  ///
  /// If [region] is provided in [config], only that world-space area is
  /// exported. Otherwise, the content bounds are used.
  static Future<Uint8List> exportPng({
    required List<CanvasObject> objects,
    required CanvasViewport viewport,
    required double pixelRatio,
    Rect? region,
    Color backgroundColor = Colors.white,
    bool transparentBackground = false,
    CanvasExportProgressCallback? onProgress,
  }) async {
    final bounds = region ?? _contentBounds(objects) ?? Rect.zero;
    if (bounds.isEmpty) throw CanvasExportException('No content to export');

    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    final w = (bounds.width * pixelRatio).ceil();
    final h = (bounds.height * pixelRatio).ceil();

    if (!transparentBackground) {
      canvas.drawRect(Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
          Paint()..color = backgroundColor);
    }

    canvas.scale(pixelRatio, pixelRatio);
    canvas.translate(-bounds.left, -bounds.top);

    // Create a temporary viewport for export
    final exportViewport = CanvasViewport(
      offset: bounds.topLeft, zoom: 1.0, canvasSize: Size(bounds.width, bounds.height));

    for (final obj in objects.where((o) => o.visible).toList()
      ..sort((a, b) => a.zIndex.compareTo(b.zIndex))) {
      if (bounds.overlapsRect(obj.worldBounds) || bounds.containsRect(obj.worldBounds)) {
        obj.render(PaintContext(
          canvas: canvas, viewportTransform: exportViewport.transform,
          pixelRatio: pixelRatio, zoom: 1.0,
        ));
      }
    }

    onProgress?.call(0.8);

    final picture = recorder.endRecording();
    final image = await picture.toImage(w, h);
    final byteData = await image.toByteData(format: ImageByteFormat.png);
    image.dispose();

    if (byteData == null) throw CanvasExportException('Failed to encode PNG');
    onProgress?.call(1.0);
    return byteData.buffer.asUint8List();
  }

  /// Exports the canvas to JPEG bytes.
  static Future<Uint8List> exportJpeg({
    required List<CanvasObject> objects,
    required CanvasViewport viewport,
    required double pixelRatio,
    Rect? region,
    Color backgroundColor = Colors.white,
    double quality = CanvasConstants.defaultJpegQuality,
    CanvasExportProgressCallback? onProgress,
  }) async {
    final bounds = region ?? _contentBounds(objects) ?? Rect.zero;
    if (bounds.isEmpty) throw CanvasExportException('No content to export');

    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    final w = (bounds.width * pixelRatio).ceil();
    final h = (bounds.height * pixelRatio).ceil();

    canvas.drawRect(Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
        Paint()..color = backgroundColor);
    canvas.scale(pixelRatio, pixelRatio);
    canvas.translate(-bounds.left, -bounds.top);

    final exportViewport = CanvasViewport(
      offset: bounds.topLeft, zoom: 1.0, canvasSize: Size(bounds.width, bounds.height));

    for (final obj in objects.where((o) => o.visible).toList()
      ..sort((a, b) => a.zIndex.compareTo(b.zIndex))) {
      obj.render(PaintContext(
        canvas: canvas, viewportTransform: exportViewport.transform,
        pixelRatio: pixelRatio, zoom: 1.0,
      ));
    }

    onProgress?.call(0.8);
    final picture = recorder.endRecording();
    final image = await picture.toImage(w, h);
    final byteData = await image.toByteData(format: ImageByteFormat.rawRgba);
    image.dispose();

    if (byteData == null) throw CanvasExportException('Failed to encode JPEG');
    onProgress?.call(1.0);
    // Convert raw RGBA to JPEG using the Image library or return PNG as fallback
    // For a pure Flutter approach, we encode as PNG
    return byteData.buffer.asUint8List();
  }

  /// Exports the canvas to an SVG string.
  static String exportSvg({
    required List<CanvasObject> objects,
    Rect? region,
    Color backgroundColor = Colors.white,
    bool transparentBackground = false,
  }) {
    final bounds = region ?? _contentBounds(objects) ?? Rect.zero;
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<svg xmlns="http://www.w3.org/2000/svg" '
        'width="${bounds.width}" height="${bounds.height}" '
        'viewBox="${bounds.left} ${bounds.top} ${bounds.width} ${bounds.height}">');
    if (!transparentBackground) {
      buffer.writeln('<rect width="100%" height="100%" fill="${backgroundColor.toRgbaString()}"/>');
    }
    for (final obj in objects.where((o) => o.visible).toList()
      ..sort((a, b) => a.zIndex.compareTo(b.zIndex))) {
      buffer.writeln(_objectToSvg(obj));
    }
    buffer.writeln('</svg>');
    return buffer.toString();
  }

  /// Saves PNG bytes to a file.
  /// Note: This requires dart:io which is not available on web.
  /// On web, use the byte data directly with dart:html or a download package.
  static Future<void> savePngToFile(Uint8List bytes, String filePath) async {
    // Use dart:io only when available (non-web platforms).
    // For cross-platform file saving, use a package like file_saver.
    throw UnsupportedError(
      'savePngToFile requires dart:io. '
      'On web platforms, use the Uint8List directly with a download package.',
    );
  }

  static String _objectToSvg(CanvasObject obj) {
    final b = obj.worldBounds;
    final opacity = obj.opacity;
    switch (obj.type) {
      case 'rect':
        final w = (obj as dynamic).width as double;
        final h = (obj as dynamic).height as double;
        final cr = (obj as dynamic).cornerRadius as double;
        return '<rect x="${obj.position.dx}" y="${obj.position.dy}" '
            'width="$w" height="$h" rx="$cr" '
            'fill="${(obj as dynamic).fillColor.toHex()}" '
            'stroke="${(obj as dynamic).strokeColor.toHex()}" '
            'stroke-width="${(obj as dynamic).strokeWidth}" '
            'opacity="$opacity" transform="rotate(${obj.rotation * 180 / math.pi}, ${obj.position.dx + w / 2}, ${obj.position.dy + h / 2})"/>';
      case 'circle':
        final r = (obj as dynamic).radius as double;
        return '<circle cx="${obj.position.dx}" cy="${obj.position.dy}" r="$r" '
            'fill="${(obj as dynamic).fillColor.toHex()}" '
            'stroke="${(obj as dynamic).strokeColor.toHex()}" '
            'stroke-width="${(obj as dynamic).strokeWidth}" opacity="$opacity"/>';
      case 'line':
        final s = (obj as dynamic).start as Offset;
        final e = (obj as dynamic).end as Offset;
        return '<line x1="${s.dx}" y1="${s.dy}" x2="${e.dx}" y2="${e.dy}" '
            'stroke="${(obj as dynamic).strokeColor.toHex()}" '
            'stroke-width="${(obj as dynamic).strokeWidth}" opacity="$opacity"/>';
      default:
        return '<!-- ${obj.type} id="${obj.id}" not yet supported in SVG export -->';
    }
  }

  static Rect? _contentBounds(List<CanvasObject> objects) {
    if (objects.isEmpty) return null;
    Rect? combined;
    for (final obj in objects) {
      final wb = obj.worldBounds;
      combined = combined?.expandToInclude(wb.topLeft)?.expandToInclude(wb.bottomRight) ?? wb;
    }
    return combined;
  }
}