/// Command pattern implementation for undo/redo.
///
/// Every mutation on the canvas should be wrapped in a [CanvasCommand]
/// so that it can be undone and redone.
library;

import '../models/canvas_object.dart';

/// Interface for all canvas commands.
///
/// Commands encapsulate a single logical action (or transaction of actions)
/// that can be executed, undone, and redone.
///
/// Example:
/// ```dart
/// controller.executeCommand(MoveCommand(objects, oldPositions, newPositions));
/// ```
abstract class CanvasCommand {
  /// Executes the command (performs the action).
  void execute();

  /// Undoes the command (reverts the action).
  void undo();

  /// Redoes the command (re-executes after undo).
  ///
  /// Default implementation calls [execute]. Override if redo differs.
  void redo() => execute();

  /// A human-readable description of this command.
  String get description;

  /// Optional: merge with another command of the same type for history
  /// compression (e.g., consecutive small moves become one big move).
  bool canMergeWith(CanvasCommand other) => false;

  /// Merges [other] into this command.
  void mergeWith(CanvasCommand other) {}
}

/// Moves one or more objects from their old positions to new positions.
class MoveCommand implements CanvasCommand {
  final List<CanvasObject> objects;
  final List<Offset> oldPositions;
  final List<Offset> newPositions;
  final String _description;

  MoveCommand(this.objects, this.oldPositions, this.newPositions)
      : _description = 'Move ${objects.length} object(s)';

  @override
  String get description => _description;

  @override
  bool canMergeWith(CanvasCommand other) {
    return other is MoveCommand &&
        _sameObjects(other) &&
        (newPositions[0] - oldPositions[0]).distance < 100;
  }

  bool _sameObjects(MoveCommand other) {
    if (objects.length != other.objects.length) return false;
    for (var i = 0; i < objects.length; i++) {
      if (objects[i].id != other.objects[i].id) return false;
    }
    return true;
  }

  @override
  void mergeWith(CanvasCommand other) {
    if (other is MoveCommand) {
      for (var i = 0; i < objects.length && i < other.newPositions.length; i++) {
        objects[i].position = other.newPositions[i];
      }
    }
  }

  @override
  void execute() {
    for (var i = 0; i < objects.length; i++) {
      objects[i].position = newPositions[i];
    }
  }

  @override
  void undo() {
    for (var i = 0; i < objects.length; i++) {
      objects[i].position = oldPositions[i];
    }
  }
}

/// Creates (adds) objects to the canvas.
class CreateCommand implements CanvasCommand {
  final List<CanvasObject> objects;
  final void Function(CanvasObject) _adder;
  final void Function(CanvasObject) _remover;

  CreateCommand(this.objects, this._adder, this._remover);

  @override
  String get description => 'Create ${objects.length} object(s)';

  @override
  void execute() {
    for (final obj in objects) _adder(obj);
  }

  @override
  void undo() {
    for (final obj in objects) _remover(obj);
  }
}

/// Deletes objects from the canvas.
class DeleteCommand implements CanvasCommand {
  final List<CanvasObject> objects;
  final List<int> _oldZIndices;
  final void Function(CanvasObject) _remover;
  final void Function(CanvasObject, int) _restorer;

  DeleteCommand(this.objects, this._oldZIndices, this._remover, this._restorer);

  @override
  String get description => 'Delete ${objects.length} object(s)';

  @override
  void execute() {
    for (final obj in objects) _remover(obj);
  }

  @override
  void undo() {
    for (var i = 0; i < objects.length; i++) {
      _restorer(objects[i], _oldZIndices[i]);
    }
  }
}

/// Resizes one or more objects.
class ResizeCommand implements CanvasCommand {
  final List<CanvasObject> objects;
  final List<Map<String, double>> oldProperties;
  final List<Map<String, double>> newProperties;

  ResizeCommand(this.objects, this.oldProperties, this.newProperties);

  @override
  String get description => 'Resize ${objects.length} object(s)';

  void _apply(List<Map<String, double>> props) {
    for (var i = 0; i < objects.length && i < props.length; i++) {
      final p = props[i];
      final obj = objects[i];
      if (p.containsKey('width')) (obj as dynamic).width = p['width']!;
      if (p.containsKey('height')) (obj as dynamic).height = p['height']!;
      if (p.containsKey('radius')) (obj as dynamic).radius = p['radius']!;
      obj.objectScale = Offset(p['scaleX'] ?? obj.objectScale.dx, p['scaleY'] ?? obj.objectScale.dy);
      obj.position = Offset(p['x'] ?? obj.position.dx, p['y'] ?? obj.position.dy);
    }
  }

  @override
  void execute() => _apply(newProperties);

  @override
  void undo() => _apply(oldProperties);
}

/// Rotates one or more objects.
class RotateCommand implements CanvasCommand {
  final List<CanvasObject> objects;
  final List<double> oldRotations;
  final List<double> newRotations;

  RotateCommand(this.objects, this.oldRotations, this.newRotations);

  @override
  String get description => 'Rotate ${objects.length} object(s)';

  @override
  void execute() {
    for (var i = 0; i < objects.length; i++) {
      objects[i].rotation = newRotations[i];
    }
  }

  @override
  void undo() {
    for (var i = 0; i < objects.length; i++) {
      objects[i].rotation = oldRotations[i];
    }
  }
}

/// Changes visual properties (color, opacity, etc.) of objects.
class PropertyChangeCommand implements CanvasCommand {
  final String _propertyName;
  final List<CanvasObject> objects;
  final List<dynamic> oldValues;
  final List<dynamic> newValues;

  PropertyChangeCommand(this._propertyName, this.objects, this.oldValues, this.newValues);

  @override
  String get description => 'Change $_propertyName on ${objects.length} object(s)';

  void _apply(List<dynamic> values) {
    for (var i = 0; i < objects.length && i < values.length; i++) {
      switch (_propertyName) {
        case 'opacity': objects[i].opacity = values[i] as double;
        case 'visible': objects[i].visible = values[i] as bool;
        case 'locked': objects[i].locked = values[i] as bool;
        case 'zIndex': objects[i].zIndex = values[i] as int;
        case 'name': objects[i].name = values[i] as String;
      }
    }
  }

  @override
  void execute() => _apply(newValues);

  @override
  void undo() => _apply(oldValues);
}

/// Groups objects into a CanvasGroup.
class GroupCommand implements CanvasCommand {
  final List<CanvasObject> _children;
  final dynamic _group; // CanvasGroup
  final void Function(CanvasObject) _removeChild;
  final void Function(CanvasObject) _addChild;
  final void Function(dynamic) _addGroup;
  final void Function(dynamic) _removeGroup;

  GroupCommand(this._children, this._group, this._removeChild, this._addChild,
      this._addGroup, this._removeGroup);

  @override
  String get description => 'Group ${_children.length} object(s)';

  @override
  void execute() {
    for (final c in _children) _removeChild(c);
    _addGroup(_group);
  }

  @override
  void undo() {
    _removeGroup(_group);
    for (final c in _children) _addChild(c);
  }
}

/// A transaction that groups multiple commands into one undo step.
class TransactionCommand implements CanvasCommand {
  final String _description;
  final List<CanvasCommand> _commands;

  TransactionCommand(this._commands, {String description = 'Transaction'})
      : _description = description;

  @override
  String get description => _description;

  @override
  void execute() {
    for (final cmd in _commands) cmd.execute();
  }

  @override
  void undo() {
    for (final cmd in _commands.reversed) cmd.undo();
  }

  @override
  void redo() => execute();
}