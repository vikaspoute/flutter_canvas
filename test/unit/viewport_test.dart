import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_canvas/flutter_canvas.dart';

void main() {
  group('CanvasViewport', () {
    late CanvasViewport viewport;

    setUp(() {
      viewport = CanvasViewport(canvasSize: const Size(800, 600));
    });

    test('initial state', () {
      expect(viewport.zoom, 1.0);
      expect(viewport.offset, Offset.zero);
      expect(viewport.rotation, 0.0);
    });

    test('screenToWorld and worldToScreen are inverses', () {
      final screenPoint = const Offset(400, 300);
      final world = viewport.screenToWorld(screenPoint);
      final screenBack = viewport.worldToScreen(world);
      expect(screenBack.dx, closeTo(screenPoint.dx, 0.01));
      expect(screenBack.dy, closeTo(screenPoint.dy, 0.01));
    });

    test('zoom clamping', () {
      viewport.setZoom(0.001);
      expect(viewport.zoom, CanvasConstants.minZoom);
      viewport.setZoom(10000);
      expect(viewport.zoom, CanvasConstants.maxZoom);
    });

    test('panBy moves offset', () {
      final initialOffset = viewport.offset;
      viewport.panBy(const Offset(100, 50));
      expect(viewport.offset.dx, closeTo(initialOffset.dx + 100, 0.01));
      expect(viewport.offset.dy, closeTo(initialOffset.dy + 50, 0.01));
    });

    test('zoomToCursor keeps point stationary', () {
      final focal = const Offset(400, 300);
      final worldBefore = viewport.screenToWorld(focal);
      viewport.zoomBy(2.0, focalPoint: focal);
      final worldAfter = viewport.screenToWorld(focal);
      expect(worldAfter.dx, closeTo(worldBefore.dx, 0.1));
      expect(worldAfter.dy, closeTo(worldBefore.dy, 0.1));
      expect(viewport.zoom, 2.0);
    });

    test('zoomToFit scales to fit rect', () {
      viewport.zoomToFit(const Rect.fromLTWH(0, 0, 1600, 1200));
      expect(viewport.zoom, closeTo(0.5, 0.01));
    });

    test('visibleWorldRect is correct', () {
      final rect = viewport.visibleWorldRect;
      expect(rect.width, closeTo(800, 0.01));
      expect(rect.height, closeTo(600, 0.01));
    });

    test('updateCanvasSize adjusts offset', () {
      viewport.updateCanvasSize(const Size(1000, 800));
      expect(viewport.canvasSize.width, 1000);
    });

    test('reset returns to default', () {
      viewport.setZoom(5.0);
      viewport.setOffset(const Offset(100, 200));
      viewport.reset();
      expect(viewport.zoom, 1.0);
      expect(viewport.offset, Offset.zero);
    });
  });

  group('TransformUtils', () {
    test('transformPoint round-trip', () {
      final matrix = Matrix4.identity()
        ..translate(100, 50)
        ..scale(2.0);
      final point = const Offset(10, 20);
      final transformed = TransformUtils.transformPoint(matrix, point);
      expect(transformed.dx, 120); // (10 * 2) + 100
      expect(transformed.dy, 90);  // (20 * 2) + 50
    });

    test('safeInvert returns identity for singular matrix', () {
      final singular = Matrix4.zero();
      final inverted = TransformUtils.safeInvert(singular);
      expect(inverted.isIdentity, isTrue);
    });

    test('flipHorizontal', () {
      final matrix = TransformUtils.flipHorizontal(100);
      final p1 = TransformUtils.transformPoint(matrix, const Offset(90, 0));
      final p2 = TransformUtils.transformPoint(matrix, const Offset(110, 0));
      expect(p1.dx, closeTo(110, 0.01));
      expect(p2.dx, closeTo(90, 0.01));
    });
  });
}