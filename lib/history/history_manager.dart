/// History manager for undo/redo operations.
///
/// Maintains a stack of executed commands with support for command merging,
/// transaction grouping, and configurable capacity limits.
library;

import 'package:flutter/material.dart';
import 'canvas_commands.dart';
import '../core/constants.dart';
import '../core/exceptions.dart';

/// Manages the undo/redo history stack.
///
/// Commands are pushed onto the undo stack when executed. Undoing pops from
/// the undo stack and pushes onto the redo stack. Executing a new command
/// clears the redo stack.
///
/// Example:
/// ```dart
/// history.execute(command);
/// history.undo();
/// history.redo();
/// ```
class HistoryManager with ChangeNotifier {
  final List<CanvasCommand> _undoStack = [];
  final List<CanvasCommand> _redoStack = [];
  final int _maxSize;
  final List<CanvasHistoryListener> _listeners = [];

  /// Whether there are commands that can be undone.
  bool get canUndo => _undoStack.isNotEmpty;

  /// Whether there are commands that can be redone.
  bool get canRedo => _redoStack.isNotEmpty;

  /// Number of commands in the undo stack.
  int get undoCount => _undoStack.length;

  /// Number of commands in the redo stack.
  int get redoCount => _redoStack.length;

  /// The description of the next undoable command, or `null`.
  String? get undoDescription => _undoStack.isNotEmpty ? _undoStack.last.description : null;

  /// The description of the next redoable command, or `null`.
  String? get redoDescription => _redoStack.isNotEmpty ? _redoStack.last.description : null;

  /// Creates a new history manager.
  HistoryManager({int maxSize = CanvasConstants.maxHistorySize})
      : _maxSize = maxSize;

  /// Executes a command and adds it to the undo stack.
  ///
  /// If the new command can be merged with the last undo command,
  /// they are merged instead of pushing a new entry (history compression).
  void execute(CanvasCommand command) {
    command.execute();
    pushToUndo(command);
  }

  /// Pushes a pre-executed command onto the undo stack.
  void pushToUndo(CanvasCommand command) {
    // Try to merge with the last command for history compression
    if (_undoStack.isNotEmpty && _undoStack.last.canMergeWith(command)) {
      _undoStack.last.mergeWith(command);
    } else {
      _undoStack.add(command);
    }
    // Clear redo stack on new action
    _redoStack.clear();
    // Trim if over capacity
    while (_undoStack.length > _maxSize) {
      _undoStack.removeAt(0);
    }
    _notifyListeners();
  }

  /// Undoes the last command.
  ///
  /// Throws [CanvasHistoryException] if there is nothing to undo.
  void undo() {
    if (_undoStack.isEmpty) throw CanvasHistoryException('Nothing to undo');
    final command = _undoStack.removeLast();
    command.undo();
    _redoStack.add(command);
    _notifyListeners();
  }

  /// Redoes the last undone command.
  ///
  /// Throws [CanvasHistoryException] if there is nothing to redo.
  void redo() {
    if (_redoStack.isEmpty) throw CanvasHistoryException('Nothing to redo');
    final command = _redoStack.removeLast();
    command.redo();
    _undoStack.add(command);
    _notifyListeners();
  }

  /// Clears all history.
  void clear() {
    _undoStack.clear();
    _redoStack.clear();
    _notifyListeners();
  }

  /// Begins a transaction. All commands executed before [endTransaction]
  /// are grouped into a single undoable step.
  ///
  /// Returns the transaction collector.
  TransactionCollector beginTransaction({String description = 'Transaction'}) {
    return TransactionCollector(this, description: description);
  }

  /// Commits a transaction of commands as a single undo step.
  void commitTransaction(List<CanvasCommand> commands, String description) {
    if (commands.isEmpty) return;
    if (commands.length == 1) {
      pushToUndo(commands.first);
    } else {
      final txn = TransactionCommand(commands, description: description);
      pushToUndo(txn);
    }
  }

  /// Adds a listener that is called after any undo/redo/execute.
  void addListener(CanvasHistoryListener listener) => _listeners.add(listener);

  /// Removes a history listener.
  void removeListener(CanvasHistoryListener listener) => _listeners.remove(listener);

  void _notifyListeners() {
    notifyListeners();
    for (final l in _listeners) l();
  }
}

/// Collects commands during a transaction and commits them atomically.
class TransactionCollector {
  final HistoryManager _history;
  final String _description;
  final List<CanvasCommand> _commands = [];
  bool _committed = false;

  TransactionCollector(this._history, {required String description})
      : _description = description;

  /// Adds a command to this transaction (does NOT execute it).
  void add(CanvasCommand command) {
    if (_committed) throw StateError('Transaction already committed');
    command.execute();
    _commands.add(command);
  }

  /// Commits all collected commands as a single undo step.
  void commit() {
    if (_committed) throw StateError('Transaction already committed');
    _committed = true;
    _history.commitTransaction(_commands, _description);
  }

  /// Cancels the transaction and undoes all executed commands.
  void cancel() {
    if (_committed) throw StateError('Transaction already committed');
    _committed = true;
    for (final cmd in _commands.reversed) cmd.undo();
  }
}