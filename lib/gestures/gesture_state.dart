/// Internal state tracking for the gesture handler.
library;

import 'package:flutter/material.dart';

/// Tracks the state of pointers and gesture recognition.
class GestureState {
  /// Whether a two-finger pinch is in progress.
  bool isPinching = false;

  /// Whether a drag operation is active.
  bool isDragging = false;

  /// The focal point at the start of a gesture.
  Offset? initialFocalPoint;

  /// The viewport zoom at the start of a pinch.
  double initialZoom = 1.0;

  /// The viewport offset at the start of a pan.
  Offset initialOffset = Offset.zero;

  /// The world position where the last drag started.
  Offset? dragStartWorldPoint;

  /// The screen position where the last drag started.
  Offset? dragStartScreenPoint;

  /// All currently active pointer IDs and their positions.
  final Map<int, Offset> activePointers = {};

  /// The primary pointer ID (first touch).
  int? primaryPointerId;

  /// Timestamp of the last pointer down event (for double-tap detection).
  int? lastTapTime;

  /// Position of the last tap (for double-tap detection).
  Offset? lastTapPosition;

  void onPointerDown(PointerDownEvent event) {
    activePointers[event.pointer] = event.position;
    primaryPointerId ??= event.pointer;

    // Double-tap detection
    final now = DateTime.now().millisecondsSinceEpoch;
    if (lastTapTime != null &&
        lastTapPosition != null &&
        now - lastTapTime! < 300 &&
        (event.position - lastTapPosition!).distance < 30) {
      // Double tap detected - handled by gesture handler
    }
    lastTapTime = now;
    lastTapPosition = event.position;
  }

  void onPointerMove(PointerMoveEvent event) {
    activePointers[event.pointer] = event.position;
  }

  void onPointerUp(PointerUpEvent event) {
    activePointers.remove(event.pointer);
    if (event.pointer == primaryPointerId) {
      primaryPointerId = activePointers.keys.isNotEmpty ? activePointers.keys.first : null;
    }
    if (activePointers.isEmpty) {
      isDragging = false;
      isPinching = false;
    }
  }

  /// Resets all state.
  void reset() {
    isPinching = false;
    isDragging = false;
    initialFocalPoint = null;
    initialZoom = 1.0;
    initialOffset = Offset.zero;
    dragStartWorldPoint = null;
    dragStartScreenPoint = null;
    activePointers.clear();
    primaryPointerId = null;
  }

  /// Whether exactly one pointer is active.
  bool get isSinglePointer => activePointers.length == 1;

  /// Whether two or more pointers are active.
  bool get isMultiTouch => activePointers.length >= 2;

  /// The current position of the primary pointer, if any.
  Offset? get primaryPointerPosition => primaryPointerId != null
      ? activePointers[primaryPointerId]
      : null;
}