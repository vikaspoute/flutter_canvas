import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_canvas/flutter_canvas.dart';

void main() {
  group('SelectionManager', () {
    late SelectionManager selection;
    late CanvasRect rect1, rect2, rect3;

    setUp(() {
      selection = SelectionManager();
      rect1 = CanvasRect(x: 0, y: 0, width: 100, height: 100);
      rect2 = CanvasRect(x: 200, y: 200, width: 100, height: 100);
      rect3 = CanvasRect(x: 50, y: 50, width: 100, height: 100);
    });

    test('initial state has no selection', () {
      expect(selection.hasSelection, isFalse);
      expect(selection.selected, isEmpty);
    });

    test('select single', () {
      selection.select(rect1);
      expect(selection.hasSelection, isTrue);
      expect(selection.isSingleSelection, isTrue);
      expect(selection.singleSelection, rect1);
    });

    test('addToSelection', () {
      selection.select(rect1);
      selection.addToSelection(rect2);
      expect(selection.selected.length, 2);
      expect(selection.isSingleSelection, isFalse);
    });

    test('removeFromSelection', () {
      selection.select(rect1);
      selection.addToSelection(rect2);
      selection.removeFromSelection(rect1);
      expect(selection.selected.length, 1);
      expect(selection.singleSelection, rect2);
    });

    test('toggleSelection', () {
      selection.select(rect1);
      selection.toggleSelection(rect1);
      expect(selection.hasSelection, isFalse);
    });

    test('selectAll', () {
      selection.selectAll([rect1, rect2, rect3]);
      expect(selection.selected.length, 3);
    });

    test('clear', () {
      selection.select(rect1);
      selection.clear();
      expect(selection.hasSelection, isFalse);
    });

    test('locked objects are skipped', () {
      rect1.locked = true;
      selection.select(rect1);
      expect(selection.hasSelection, isFalse);
    });

    test('selectInRect', () {
      selection.selectInRect(
        const Rect.fromLTWH(0, 0, 300, 300),
        [rect1, rect2, rect3],
      );
      expect(selection.selected.length, 3);
    });

    test('selectInRect partial', () {
      selection.selectInRect(
        const Rect.fromLTWH(250, 250, 100, 100),
        [rect1, rect2, rect3],
      );
      expect(selection.selected.length, 1);
      expect(selection.singleSelection, rect2);
    });

    test('box select workflow', () {
      selection.startBoxSelect(const Offset(0, 0));
      expect(selection.isBoxSelecting, isTrue);
      selection.updateBoxSelect(const Offset(300, 300));
      selection.endBoxSelect([rect1, rect2, rect3]);
      expect(selection.isBoxSelecting, isFalse);
      expect(selection.selected.length, 3);
    });

    test('resize handles count', () {
      selection.select(rect1);
      final handles = selection.getResizeHandles();
      expect(handles.length, 8);
    });

    test('rotation handle exists', () {
      selection.select(rect1);
      final rh = selection.getRotationHandle();
      expect(rh, isNotNull);
    });
  });

  group('LayerManager', () {
    late LayerManager layers;

    setUp(() {
      layers = LayerManager();
    });

    test('creates with default layer', () {
      expect(layers.layers.length, 1);
      expect(layers.activeLayerId, isNotNull);
    });

    test('createLayer adds a layer', () {
      layers.createLayer(name: 'Layer 2');
      expect(layers.layers.length, 2);
    });

    test('deleteLayer removes a layer', () {
      final layer = layers.createLayer(name: 'Temp');
      layers.deleteLayer(layer.id);
      expect(layers.layers.length, 1);
    });

    test('renameLayer', () {
      final layer = layers.createLayer(name: 'Old');
      layers.renameLayer(layer.id, 'New');
      expect(layers.getLayer(layer.id)?.name, 'New');
    });

    test('toggleVisibility', () {
      final layer = layers.getLayer(layers.activeLayerId!);
      expect(layer?.visible, isTrue);
      layers.toggleVisibility(layer!.id);
      expect(layer.visible, isFalse);
    });

    test('setActiveLayer', () {
      final layer2 = layers.createLayer(name: 'L2');
      layers.setActiveLayer(layer2.id);
      expect(layers.activeLayerId, layer2.id);
    });

    test('bringForward/sendBackward', () {
      final l2 = layers.createLayer(name: 'L2');
      final l3 = layers.createLayer(name: 'L3');
      final sorted = layers.layers;
      expect(sorted.first.id, layers.layers.first.id);
      layers.bringToFront(l2.id);
      expect(layers.layers.last.id, l2.id);
    });

    test('toJson/fromJson round-trip', () {
      layers.createLayer(name: 'L2');
      layers.createLayer(name: 'L3');
      final json = layers.toJson();
      final newLayers = LayerManager();
      newLayers.fromJson(json);
      expect(newLayers.layers.length, 3);
    });
  });
}