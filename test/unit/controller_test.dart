import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_canvas/flutter_canvas.dart';

void main() {
  group('CanvasController', () {
    late CanvasController controller;

    setUp(() {
      controller = CanvasController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('initial state is empty', () {
      expect(controller.objects, isEmpty);
      expect(controller.selectedObjects, isEmpty);
    });

    test('add object', () {
      final rect = CanvasRect(x: 10, y: 20, width: 100, height: 50);
      controller.add(rect);
      expect(controller.objects.length, 1);
      expect(controller.getObject(rect.id), rect);
    });

    test('remove object', () {
      final rect = CanvasRect(x: 10, y: 20, width: 100, height: 50);
      controller.add(rect);
      controller.remove(rect.id);
      expect(controller.objects, isEmpty);
    });

    test('clear removes all', () {
      controller.add(CanvasRect(x: 0, y: 0, width: 100, height: 100));
      controller.add(CanvasCircle(x: 50, y: 50, radius: 25));
      controller.clear();
      expect(controller.objects, isEmpty);
    });

    test('addWithUndo can be undone', () {
      final rect = CanvasRect(x: 10, y: 20, width: 100, height: 50);
      controller.addWithUndo(rect);
      expect(controller.objects.length, 1);
      controller.history.undo();
      expect(controller.objects, isEmpty);
    });

    test('deleteSelected removes from canvas', () {
      final rect = CanvasRect(x: 10, y: 20, width: 100, height: 50);
      controller.add(rect);
      controller.select(rect);
      controller.deleteSelected();
      expect(controller.objects, isEmpty);
    });

    test('deleteSelected can be undone', () {
      final rect = CanvasRect(x: 10, y: 20, width: 100, height: 50);
      controller.add(rect);
      controller.select(rect);
      controller.deleteSelected();
      controller.history.undo();
      expect(controller.objects.length, 1);
    });

    test('selectAll selects all objects', () {
      controller.add(CanvasRect(x: 0, y: 0, width: 50, height: 50));
      controller.add(CanvasRect(x: 100, y: 100, width: 50, height: 50));
      controller.selectAll();
      expect(controller.selectedObjects.length, 2);
    });

    test('deselectAll clears selection', () {
      final rect = CanvasRect(x: 0, y: 0, width: 50, height: 50);
      controller.add(rect);
      controller.select(rect);
      controller.deselectAll();
      expect(controller.selectedObjects, isEmpty);
    });

    test('exportJson returns valid JSON', () {
      controller.add(CanvasRect(x: 10, y: 20, width: 100, height: 50));
      final jsonStr = controller.exportJson();
      expect(jsonStr, isNotEmpty);
      expect(jsonStr.contains('"type":"rect"'), isTrue);
    });

    test('importJson restores state', () {
      controller.add(CanvasRect(x: 10, y: 20, width: 100, height: 50));
      controller.add(CanvasCircle(x: 50, y: 50, radius: 25));
      final jsonStr = controller.exportJson();

      final newController = CanvasController();
      newController.importJson(jsonStr);
      expect(newController.objects.length, 2);
      newController.dispose();
    });

    test('groupSelected creates a group', () {
      final r1 = CanvasRect(x: 0, y: 0, width: 50, height: 50);
      final r2 = CanvasRect(x: 60, y: 60, width: 50, height: 50);
      controller.add(r1);
      controller.add(r2);
      controller.select(r1);
      controller.selection.addToSelection(r2);
      controller.groupSelected();
      expect(controller.objects.whereType<CanvasGroup>().length, 1);
    });

    test('z-ordering works', () {
      final r1 = CanvasRect(x: 0, y: 0, width: 50, height: 50);
      final r2 = CanvasRect(x: 0, y: 0, width: 50, height: 50);
      controller.add(r1);
      controller.add(r2);
      expect(r2.zIndex > r1.zIndex, isTrue);
      controller.bringToFront(r1);
      expect(r1.zIndex > r2.zIndex, isTrue);
    });
  });

  group('GridConfig', () {
    test('defaults', () {
      final config = GridConfig();
      expect(config.type, GridType.square);
      expect(config.size, 20.0);
      expect(config.visible, isTrue);
      expect(config.snapEnabled, isTrue);
    });

    test('copyWith', () {
      final config = GridConfig().copyWith(size: 40, type: GridType.dot);
      expect(config.size, 40);
      expect(config.type, GridType.dot);
      expect(config.visible, isTrue); // Unchanged
    });

    test('serialization round-trip', () {
      final config = GridConfig(type: GridType.dot, size: 30);
      final json = config.toJson();
      final restored = GridConfig.fromJson(json);
      expect(restored.type, GridType.dot);
      expect(restored.size, 30);
    });
  });

  group('ObjectRegistry', () {
    test('all types registered by default', () {
      CanvasObjectRegistry.instance.registerDefaults();
      expect(CanvasObjectRegistry.instance.isRegistered('rect'), isTrue);
      expect(CanvasObjectRegistry.instance.isRegistered('circle'), isTrue);
      expect(CanvasObjectRegistry.instance.isRegistered('line'), isTrue);
      expect(CanvasObjectRegistry.instance.isRegistered('arrow'), isTrue);
      expect(CanvasObjectRegistry.instance.isRegistered('text'), isTrue);
      expect(CanvasObjectRegistry.instance.isRegistered('image'), isTrue);
      expect(CanvasObjectRegistry.instance.isRegistered('path'), isTrue);
      expect(CanvasObjectRegistry.instance.isRegistered('polygon'), isTrue);
      expect(CanvasObjectRegistry.instance.isRegistered('sticky_note'), isTrue);
      expect(CanvasObjectRegistry.instance.isRegistered('frame'), isTrue);
      expect(CanvasObjectRegistry.instance.isRegistered('svg'), isTrue);
      expect(CanvasObjectRegistry.instance.isRegistered('group'), isTrue);
    });

    test('fromJson polymorphic deserialization', () {
      CanvasObjectRegistry.instance.registerDefaults();
      final json = CanvasRect(x: 10, y: 20, width: 100, height: 50).toJson();
      final obj = CanvasObjectRegistry.instance.fromJson(json);
      expect(obj, isA<CanvasRect>());
      expect(obj.position.dx, 10);
    });

    test('custom type registration', () {
      CanvasObjectRegistry.instance.register('custom', (json) {
        return CanvasRect.fromJson(json); // Use rect as proxy
      });
      expect(CanvasObjectRegistry.instance.isRegistered('custom'), isTrue);
      CanvasObjectRegistry.instance.unregister('custom');
    });
  });
}