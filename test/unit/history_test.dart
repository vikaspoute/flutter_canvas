import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_canvas/flutter_canvas.dart';

void main() {
  group('HistoryManager', () {
    late HistoryManager history;

    setUp(() {
      history = HistoryManager();
    });

    test('initial state', () {
      expect(history.canUndo, isFalse);
      expect(history.canRedo, isFalse);
    });

    test('execute adds to undo stack', () {
      var value = 0;
      history.execute(_TestCommand(() => value = 1, () => value = 0, 'Set to 1'));
      expect(value, 1);
      expect(history.canUndo, isTrue);
    });

    test('undo reverts', () {
      var value = 0;
      history.execute(_TestCommand(() => value = 1, () => value = 0, 'Set'));
      history.undo();
      expect(value, 0);
      expect(history.canRedo, isTrue);
    });

    test('redo re-executes', () {
      var value = 0;
      history.execute(_TestCommand(() => value = 1, () => value = 0, 'Set'));
      history.undo();
      history.redo();
      expect(value, 1);
    });

    test('new command clears redo stack', () {
      var value = 0;
      history.execute(_TestCommand(() => value = 1, () => value = 0, 'Set 1'));
      history.execute(_TestCommand(() => value = 2, () => value = 1, 'Set 2'));
      history.undo();
      expect(history.canRedo, isTrue);
      history.execute(_TestCommand(() => value = 3, () => value = 1, 'Set 3'));
      expect(history.canRedo, isFalse);
    });

    test('clear empties stacks', () {
      var value = 0;
      history.execute(_TestCommand(() => value = 1, () => value = 0, 'Set'));
      history.clear();
      expect(history.canUndo, isFalse);
    });

    test('transaction groups commands', () {
      var a = 0, b = 0;
      final txn = history.beginTransaction(description: 'Set both');
      txn.add(_TestCommand(() => a = 1, () => a = 0, 'Set a'));
      txn.add(_TestCommand(() => b = 2, () => b = 0, 'Set b'));
      txn.commit();
      expect(a, 1);
      expect(b, 2);
      history.undo();
      expect(a, 0);
      expect(b, 0);
    });

    test('transaction cancel undoes', () {
      var a = 0;
      final txn = history.beginTransaction(description: 'Set a');
      txn.add(_TestCommand(() => a = 1, () => a = 0, 'Set a'));
      txn.cancel();
      expect(a, 0);
    });

    test('max size limits undo stack', () {
      final smallHistory = HistoryManager(maxSize: 5);
      for (var i = 0; i < 10; i++) {
        smallHistory.execute(_TestCommand(() {}, () {}, 'Op $i'));
      }
      expect(smallHistory.undoCount, 5);
    });
  });

  group('MoveCommand', () {
    test('moves and undoes', () {
      final rect = CanvasRect(x: 0, y: 0, width: 100, height: 100);
      final cmd = MoveCommand(
        [rect],
        [const Offset(0, 0)],
        [const Offset(50, 50)],
      );
      cmd.execute();
      expect(rect.position, const Offset(50, 50));
      cmd.undo();
      expect(rect.position, Offset.zero);
    });
  });

  group('DeleteCommand', () {
    test('deletes and restores', () {
      final rect = CanvasRect(x: 0, y: 0, width: 100, height: 100);
      var list = <CanvasObject>[rect];
      final cmd = DeleteCommand(
        list, [0],
        (obj) => list.remove(obj),
        (obj, zIndex) { obj.zIndex = zIndex; list.add(obj); },
      );
      cmd.execute();
      expect(list, isEmpty);
      cmd.undo();
      expect(list.length, 1);
    });
  });

  group('PropertyChangeCommand', () {
    test('changes and undoes opacity', () {
      final rect = CanvasRect(x: 0, y: 0, width: 100, height: 100);
      final cmd = PropertyChangeCommand(
        'opacity', [rect], [1.0], [0.5],
      );
      cmd.execute();
      expect(rect.opacity, 0.5);
      cmd.undo();
      expect(rect.opacity, 1.0);
    });
  });
}

class _TestCommand implements CanvasCommand {
  final void Function() _doAction;
  final void Function() _undoAction;
  @override
  final String description;

  _TestCommand(this._doAction, this._undoAction, this.description);

  @override
  void execute() => _doAction();
  @override
  void undo() => _undoAction();
}

}