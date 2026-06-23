import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_canvas/flutter_canvas.dart';

void main() {
  group('CanvasRect', () {
    test('creates with defaults', () {
      final rect = CanvasRect(x: 10, y: 20, width: 100, height: 50);
      expect(rect.type, 'rect');
      expect(rect.position, const Offset(10, 20));
      expect(rect.width, 100);
      expect(rect.height, 50);
      expect(rect.visible, isTrue);
      expect(rect.locked, isFalse);
      expect(rect.opacity, 1.0);
      expect(rect.rotation, 0.0);
    });

    test('bounds are correct', () {
      final rect = CanvasRect(x: 0, y: 0, width: 200, height: 100);
      expect(rect.bounds, const Rect.fromLTWH(0, 0, 200, 100));
    });

    test('worldBounds includes position', () {
      final rect = CanvasRect(x: 50, y: 30, width: 100, height: 80);
      final wb = rect.worldBounds;
      expect(wb.left, 50);
      expect(wb.top, 30);
      expect(wb.width, 100);
      expect(wb.height, 80);
    });

    test('hitTest works for point inside', () {
      final rect = CanvasRect(x: 100, y: 100, width: 200, height: 100);
      expect(rect.hitTest(const Offset(200, 150)), isTrue);
    });

    test('hitTest fails for point outside', () {
      final rect = CanvasRect(x: 100, y: 100, width: 200, height: 100);
      expect(rect.hitTest(const Offset(50, 50)), isFalse);
    });

    test('clone creates independent copy', () {
      final rect = CanvasRect(x: 10, y: 20, width: 100, height: 50,
        fillColor: Colors.blue, strokeWidth: 3);
      final cloned = rect.clone();
      expect(cloned.id, isNot(equals(rect.id)));
      expect(cloned.position, rect.position);
      expect(cloned.width, rect.width);
      expect(cloned.fillColor, rect.fillColor);
      cloned.width = 999;
      expect(rect.width, 100); // Original unchanged
    });

    test('serialization round-trip', () {
      final rect = CanvasRect(x: 10, y: 20, width: 100, height: 50,
        fillColor: Colors.blue, strokeColor: Colors.red, strokeWidth: 3,
        cornerRadius: 8);
      final json = rect.toJson();
      final restored = CanvasRect.fromJson(json);
      expect(restored.position.dx, 10);
      expect(restored.position.dy, 20);
      expect(restored.width, 100);
      expect(restored.height, 50);
      expect(restored.cornerRadius, 8);
      expect(restored.strokeWidth, 3);
    });
  });

  group('CanvasCircle', () {
    test('creates with defaults', () {
      final circle = CanvasCircle(x: 50, y: 50, radius: 30);
      expect(circle.type, 'circle');
      expect(circle.radius, 30);
    });

    test('hitTest works for point inside', () {
      final circle = CanvasCircle(x: 100, y: 100, radius: 50);
      expect(circle.hitTest(const Offset(120, 110)), isTrue);
    });

    test('hitTest fails for point outside', () {
      final circle = CanvasCircle(x: 100, y: 100, radius: 50);
      expect(circle.hitTest(const Offset(200, 200)), isFalse);
    });

    test('serialization round-trip', () {
      final circle = CanvasCircle(x: 10, y: 20, radius: 45);
      final json = circle.toJson();
      final restored = CanvasCircle.fromJson(json);
      expect(restored.radius, 45);
      expect(restored.position.dx, 10);
    });
  });

  group('CanvasLine', () {
    test('creates with defaults', () {
      final line = CanvasLine(start: const Offset(0, 0), end: const Offset(100, 100));
      expect(line.type, 'line');
    });

    test('serialization round-trip', () {
      final line = CanvasLine(
        start: const Offset(10, 20), end: const Offset(100, 200),
        strokeColor: Colors.red, strokeWidth: 5,
      );
      final json = line.toJson();
      final restored = CanvasLine.fromJson(json);
      expect(restored.start.dx, 10);
      expect(restored.end.dy, 200);
      expect(restored.strokeWidth, 5);
    });
  });

  group('CanvasArrow', () {
    test('creates and serializes', () {
      final arrow = CanvasArrow(
        start: const Offset(0, 0), end: const Offset(100, 0),
        arrowHeadStyle: 'open', arrowHeadSize: 15,
      );
      expect(arrow.type, 'arrow');
      final json = arrow.toJson();
      final restored = CanvasArrow.fromJson(json);
      expect(restored.arrowHeadStyle, 'open');
      expect(restored.arrowHeadSize, 15);
    });
  });

  group('CanvasText', () {
    test('creates with defaults', () {
      final text = CanvasText(x: 10, y: 20, text: 'Hello');
      expect(text.type, 'text');
      expect(text.text, 'Hello');
    });

    test('serialization round-trip', () {
      final text = CanvasText(x: 10, y: 20, text: 'Hello World',
        fontSize: 24, fontWeight: FontWeight.bold);
      final json = text.toJson();
      final restored = CanvasText.fromJson(json);
      expect(restored.text, 'Hello World');
      expect(restored.fontSize, 24);
    });
  });

  group('CanvasPath', () {
    test('creates with points', () {
      final path = CanvasPath(points: [
        const Offset(0, 0), const Offset(50, 50), const Offset(100, 0),
      ]);
      expect(path.type, 'path');
      expect(path.points.length, 3);
    });

    test('serialization round-trip', () {
      final path = CanvasPath(points: [
        const Offset(10, 20), const Offset(30, 40),
      ], strokeColor: Colors.blue, closed: true);
      final json = path.toJson();
      final restored = CanvasPath.fromJson(json);
      expect(restored.points.length, 2);
      expect(restored.closed, isTrue);
    });
  });

  group('CanvasStickyNote', () {
    test('creates and serializes', () {
      final note = CanvasStickyNote(x: 10, y: 20, text: 'Buy milk',
        backgroundColor: const Color(0xFFFFEB3B));
      expect(note.type, 'sticky_note');
      final json = note.toJson();
      final restored = CanvasStickyNote.fromJson(json);
      expect(restored.text, 'Buy milk');
    });
  });

  group('CanvasFrame', () {
    test('creates and serializes', () {
      final frame = CanvasFrame(x: 0, y: 0, width: 800, height: 600, title: 'My Frame');
      expect(frame.type, 'frame');
      final json = frame.toJson();
      final restored = CanvasFrame.fromJson(json);
      expect(restored.title, 'My Frame');
      expect(restored.width, 800);
    });
  });

  group('CanvasSvg', () {
    test('creates and serializes', () {
      final svg = CanvasSvg(svgString: '<svg></svg>', width: 100, height: 100);
      expect(svg.type, 'svg');
      final json = svg.toJson();
      final restored = CanvasSvg.fromJson(json);
      expect(restored.svgString, '<svg></svg>');
    });
  });
}