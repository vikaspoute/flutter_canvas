import 'package:flutter/material.dart';
import 'package:flutter_canvas/flutter_canvas.dart';
import 'benchmark_harness.dart';

void main() {
  // Benchmark: Object creation
  Benchmark('Object Creation (10000 rects)').run(() {
    for (var i = 0; i < 10000; i++) {
      CanvasRect(x: i.toDouble(), y: i.toDouble(), width: 50, height: 50);
    }
  });

  // Benchmark: JSON serialization
  final objects = List.generate(1000, (i) => CanvasRect(
    x: i % 100 * 20.0, y: (i ~/ 100) * 20.0,
    width: 18, height: 18, fillColor: Colors.blue,
  ));

  Benchmark('JSON Serialization (1000 objects)').run(() {
    for (final obj in objects) {
      obj.toJson();
    }
  });

  // Benchmark: JSON deserialization
  final jsons = objects.map((o) => o.toJson()).toList();

  Benchmark('JSON Deserialization (1000 objects)').run(() {
    for (final json in jsons) {
      CanvasRect.fromJson(json);
    }
  });

  // Benchmark: Hit testing
  final controller = CanvasController();
  for (final obj in objects) {
    controller.add(obj);
  }
  final testPoint = const Offset(500, 500);

  Benchmark('Hit Test (1000 objects)').run(() {
    for (final obj in controller.objects) {
      obj.hitTest(testPoint);
    }
  });

  // Benchmark: Viewport transforms
  final viewport = CanvasViewport(canvasSize: const Size(1920, 1080));
  final worldPoint = const Offset(5000, 3000);

  Benchmark('Viewport Transform (10000 conversions)').run(() {
    for (var i = 0; i < 10000; i++) {
      viewport.worldToScreen(worldPoint);
      viewport.screenToWorld(Offset(960, 540));
    }
  });

  controller.dispose();
}
ENDOFFILE