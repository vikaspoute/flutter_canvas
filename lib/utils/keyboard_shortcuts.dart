/// Keyboard shortcut system for the canvas.
///
/// Provides cross-platform keyboard shortcut handling for common operations
/// like copy, paste, delete, undo, redo, zoom, and object manipulation.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/canvas_object.dart';
import '../core/typedefs.dart';

/// Defines a keyboard shortcut.
class KeyboardShortcut {
  final KeyCombination keys;
  final String description;
  final VoidCallback action;

  const KeyboardShortcut({
    required this.keys,
    required this.description,
    required this.action,
  });
}

/// Represents a combination of modifier keys and a trigger key.
class KeyCombination {
  final bool ctrl;
  final bool shift;
  final bool alt;
  final bool meta;
  final LogicalKeyboardKey key;

  const KeyCombination({
    this.ctrl = false, this.shift = false,
    this.alt = false, this.meta = false,
    required this.key,
  });

  /// Returns a standard shortcut label (e.g., "Ctrl+C", "⌘+Z").
  String get label {
    final parts = <String>[];
    if (ctrl) parts.add(Platform.isMacOS ? '⌘' : 'Ctrl');
    if (shift) parts.add('Shift');
    if (alt) parts.add(Platform.isMacOS ? '⌥' : 'Alt');
    if (meta) parts.add('Meta');
    parts.add(_keyLabel);
    return parts.join('+');
  }

  String get _keyLabel {
    if (key == LogicalKeyboardKey.keyC) return 'C';
    if (key == LogicalKeyboardKey.keyV) return 'V';
    if (key == LogicalKeyboardKey.keyX) return 'X';
    if (key == LogicalKeyboardKey.keyZ) return 'Z';
    if (key == LogicalKeyboardKey.keyA) return 'A';
    if (key == LogicalKeyboardKey.keyD) return 'D';
    if (key == LogicalKeyboardKey.keyG) return 'G';
    if (key == LogicalKeyboardKey.keyS) return 'S';
    if (key == LogicalKeyboardKey.keyF) return 'F';
    if (key == LogicalKeyboardKey.delete) return 'Del';
    if (key == LogicalKeyboardKey.backspace) return '⌫';
    if (key == LogicalKeyboardKey.equal || key == LogicalKeyboardKey.numpadAdd) return '+';
    if (key == LogicalKeyboardKey.minus || key == LogicalKeyboardKey.numpadSubtract) return '-';
    if (key == LogicalKeyboardKey.digit0) return '0';
    if (key == LogicalKeyboardKey.arrowUp) return '↑';
    if (key == LogicalKeyboardKey.arrowDown) return '↓';
    if (key == LogicalKeyboardKey.arrowLeft) return '←';
    if (key == LogicalKeyboardKey.arrowRight) return '→';
    return key.keyLabel;
  }

  bool matches(RawKeyEvent event, bool isMac) {
    final ctrlMatch = isMac ? (event.isMetaPressed && ctrl) : (event.isControlPressed && ctrl);
    final shiftMatch = event.isShiftPressed == shift || (!shift && !event.isShiftPressed);
    final altMatch = event.isAltPressed == alt || (!alt && !event.isAltPressed);
    final metaMatch = event.isMetaPressed == meta || (!meta && !event.isMetaPressed);
    return ctrlMatch && shiftMatch && altMatch && metaMatch && event.logicalKey == key;
  }
}

/// Manages keyboard shortcuts for the canvas.
class KeyboardShortcutManager with ChangeNotifier {
  final List<KeyboardShortcut> _shortcuts = [];
  final Map<KeyCombination, KeyboardShortcut> _shortcutMap = {};

  /// Callbacks for clipboard operations.
  VoidCallback? onCopy;
  VoidCallback? onPaste;
  VoidCallback? onCut;
  VoidCallback? onDelete;
  VoidCallback? onUndo;
  VoidCallback? onRedo;
  VoidCallback? onSelectAll;
  VoidCallback? onGroup;
  VoidCallback? onUngroup;
  VoidCallback? onDuplicate;
  VoidCallback? onZoomIn;
  VoidCallback? onZoomOut;
  VoidCallback? onZoomFit;
  VoidCallback? onSave;
  void Function(Offset delta)? onNudge;

  KeyboardShortcutManager() {
    _registerDefaults();
  }

  void _registerDefaults() {
    register(KeyboardShortcut(
      keys: const KeyCombination(ctrl: true, key: LogicalKeyboardKey.keyC),
      description: 'Copy', action: onCopy ?? () {},
    ));
    register(KeyboardShortcut(
      keys: const KeyCombination(ctrl: true, key: LogicalKeyboardKey.keyV),
      description: 'Paste', action: onPaste ?? () {},
    ));
    register(KeyboardShortcut(
      keys: const KeyCombination(ctrl: true, key: LogicalKeyboardKey.keyX),
      description: 'Cut', action: onCut ?? () {},
    ));
    register(KeyboardShortcut(
      keys: const KeyCombination(ctrl: true, shift: true, key: LogicalKeyboardKey.keyZ),
      description: 'Redo', action: onRedo ?? () {},
    ));
    register(KeyboardShortcut(
      keys: const KeyCombination(ctrl: true, key: LogicalKeyboardKey.keyZ),
      description: 'Undo', action: onUndo ?? () {},
    ));
    register(KeyboardShortcut(
      keys: const KeyCombination(ctrl: true, key: LogicalKeyboardKey.keyA),
      description: 'Select All', action: onSelectAll ?? () {},
    ));
    register(KeyboardShortcut(
      keys: const KeyCombination(ctrl: true, key: LogicalKeyboardKey.keyD),
      description: 'Duplicate', action: onDuplicate ?? () {},
    ));
    register(KeyboardShortcut(
      keys: const KeyCombination(ctrl: true, key: LogicalKeyboardKey.keyG),
      description: 'Group', action: onGroup ?? () {},
    ));
    register(KeyboardShortcut(
      keys: const KeyCombination(ctrl: true, shift: true, key: LogicalKeyboardKey.keyG),
      description: 'Ungroup', action: onUngroup ?? () {},
    ));
    register(KeyboardShortcut(
      keys: const KeyCombination(ctrl: true, key: LogicalKeyboardKey.keyS),
      description: 'Save', action: onSave ?? () {},
    ));
    register(KeyboardShortcut(
      keys: const KeyCombination(ctrl: true, key: LogicalKeyboardKey.keyF),
      description: 'Zoom to Fit', action: onZoomFit ?? () {},
    ));
    register(KeyboardShortcut(
      keys: const KeyCombination(ctrl: true, key: LogicalKeyboardKey.equal),
      description: 'Zoom In', action: onZoomIn ?? () {},
    ));
    register(KeyboardShortcut(
      keys: const KeyCombination(ctrl: true, key: LogicalKeyboardKey.minus),
      description: 'Zoom Out', action: onZoomOut ?? () {},
    ));
    register(KeyboardShortcut(
      keys: const KeyCombination(key: LogicalKeyboardKey.delete),
      description: 'Delete', action: onDelete ?? () {},
    ));
    register(KeyboardShortcut(
      keys: const KeyCombination(key: LogicalKeyboardKey.backspace),
      description: 'Backspace Delete', action: onDelete ?? () {},
    ));
    register(KeyboardShortcut(
      keys: const KeyCombination(key: LogicalKeyboardKey.arrowUp),
      description: 'Nudge Up', action: () => onNudge?.call(const Offset(0, -1)),
    ));
    register(KeyboardShortcut(
      keys: const KeyCombination(shift: true, key: LogicalKeyboardKey.arrowUp),
      description: 'Nudge Up (10x)', action: () => onNudge?.call(const Offset(0, -10)),
    ));
    register(KeyboardShortcut(
      keys: const KeyCombination(key: LogicalKeyboardKey.arrowDown),
      description: 'Nudge Down', action: () => onNudge?.call(const Offset(0, 1)),
    ));
    register(KeyboardShortcut(
      keys: const KeyCombination(shift: true, key: LogicalKeyboardKey.arrowDown),
      description: 'Nudge Down (10x)', action: () => onNudge?.call(const Offset(0, 10)),
    ));
    register(KeyboardShortcut(
      keys: const KeyCombination(key: LogicalKeyboardKey.arrowLeft),
      description: 'Nudge Left', action: () => onNudge?.call(const Offset(-1, 0)),
    ));
    register(KeyboardShortcut(
      keys: const KeyCombination(shift: true, key: LogicalKeyboardKey.arrowLeft),
      description: 'Nudge Left (10x)', action: () => onNudge?.call(const Offset(-10, 0)),
    ));
    register(KeyboardShortcut(
      keys: const KeyCombination(key: LogicalKeyboardKey.arrowRight),
      description: 'Nudge Right', action: () => onNudge?.call(const Offset(1, 0)),
    ));
    register(KeyboardShortcut(
      keys: const KeyCombination(shift: true, key: LogicalKeyboardKey.arrowRight),
      description: 'Nudge Right (10x)', action: () => onNudge?.call(const Offset(10, 0)),
    ));
  }

  void register(KeyboardShortcut shortcut) {
    _shortcuts.add(shortcut);
    _shortcutMap[shortcut.keys] = shortcut;
    notifyListeners();
  }

  void unregister(KeyCombination keys) {
    _shortcuts.removeWhere((s) => s.keys == keys);
    _shortcutMap.remove(keys);
    notifyListeners();
  }

  /// Handles a raw key event. Returns `true` if the event was consumed.
  bool handleKeyEvent(RawKeyEvent event) {
    if (event is! RawKeyDownEvent) return false;
    final isMac = Platform.isMacOS;
    for (final shortcut in _shortcuts) {
      if (shortcut.keys.matches(event, isMac)) {
        // Update the action reference before calling
        shortcut.action();
        return true;
      }
    }
    return false;
  }

  List<KeyboardShortcut> get shortcuts => List.unmodifiable(_shortcuts);
}