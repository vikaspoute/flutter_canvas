/// Gesture handling system for the canvas.
///
/// Processes touch, mouse, stylus, and trackpad input events and translates
/// them into canvas operations: pan, zoom, select, draw, etc.
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../viewport/canvas_viewport.dart';
import '../core/constants.dart';
import 'gesture_state.dart';

/// The type of interaction currently being performed.
enum InteractionMode {
  /// Default: select, move, resize objects.
  select,
  /// Freehand drawing with the current tool.
  draw,
  /// Panning the canvas.
  pan,
  /// Creating a new shape.
  createShape,
  /// Box/lasso selection.
  boxSelect,
  /// No interaction allowed (e.g., during an animation).
  none,
}

/// Processes raw pointer and gesture events into canvas actions.
///
/// The gesture handler works with the viewport and a delegate that
/// receives the interpreted actions.
///
/// Architecture:
/// - Raw pointer events are received via [handlePointerEvent]
/// - Gestures are recognized (tap, drag, pinch, scale)
/// - Interpreted actions are forwarded to the [GestureDelegate]
class CanvasGestureHandler {
  final CanvasViewport viewport;
  final GestureDelegate delegate;

  InteractionMode _mode = InteractionMode.select;
  InteractionMode get mode => _mode;

  /// Pointer state tracking for multi-touch and gesture recognition.
  final GestureState _state = GestureState();

  /// Trackpad gesture recognizer for zoom/pan.
  ScaleGestureRecognizer? _scaleRecognizer;
  PointerDeviceKind? _lastDeviceKind;

  CanvasGestureHandler({
    required this.viewport,
    required this.delegate,
  });

  /// Sets the current interaction mode.
  void setMode(InteractionMode newMode) {
    _mode = newMode;
    _state.reset();
  }

  /// Handles a raw pointer event from the canvas widget.
  void handlePointerEvent(PointerEvent event) {
    _lastDeviceKind = event.kind;

    if (event is PointerDownEvent) {
      _state.onPointerDown(event);
      delegate.onPointerDown(event, viewport.screenToWorld(event.position));
    } else if (event is PointerMoveEvent) {
      _state.onPointerMove(event);
      delegate.onPointerMove(event, viewport.screenToWorld(event.position));
    } else if (event is PointerUpEvent) {
      _state.onPointerUp(event);
      delegate.onPointerUp(event, viewport.screenToWorld(event.position));
    } else if (event is PointerScrollEvent) {
      _handleScroll(event);
    } else if (event is PointerSignalEvent) {
      if (event is PointerScrollEvent) _handleScroll(event);
    }
  }

  void _handleScroll(PointerScrollEvent event) {
    if (_mode == InteractionMode.none) return;
    // Zoom with Ctrl/Cmd + scroll, or trackpad pinch
    if (HardwareKeyboard.instance.isMetaPressed || HardwareKeyboard.instance.isControlPressed) {
      final factor = event.scrollDelta.dy > 0
          ? 1 / CanvasConstants.zoomStep
          : CanvasConstants.zoomStep;
      viewport.zoomBy(factor, focalPoint: event.position);
      delegate.onZoomChanged(viewport.zoom);
    } else {
      viewport.panBy(event.scrollDelta);
      delegate.onPanChanged(viewport.offset);
    }
  }

  /// Handles a scale gesture (pinch-to-zoom on touch, trackpad pinch).
  void handleScaleStart(ScaleStartDetails details) {
    if (_mode == InteractionMode.none) return;
    if (details.pointerCount >= 2) {
      _state.initialFocalPoint = details.focalPoint;
      _state.initialZoom = viewport.zoom;
      _state.initialOffset = viewport.offset;
      _state.isPinching = true;
    }
  }

  void handleScaleUpdate(ScaleUpdateDetails details) {
    if (_mode == InteractionMode.none || !_state.isPinching) return;

    // Pinch zoom
    if (details.scale != 1.0) {
      final newZoom = (_state.initialZoom * details.scale)
          .clamp(CanvasConstants.minZoom, CanvasConstants.maxZoom);
      final worldBefore = viewport.screenToWorld(details.focalPoint);
      viewport.setZoom(newZoom);
      final worldAfter = viewport.screenToWorld(details.focalPoint);
      viewport.setOffset(viewport.offset + worldBefore - worldAfter);
      delegate.onZoomChanged(viewport.zoom);
    }

    // Two-finger pan
    if (details.focalPointDelta != Offset.zero && details.pointerCount >= 2) {
      viewport.panBy(-details.focalPointDelta);
      delegate.onPanChanged(viewport.offset);
    }
  }

  void handleScaleEnd(ScaleEndDetails details) {
    _state.isPinching = false;
  }

  /// Handles a tap gesture.
  void handleTap(TapUpDetails details) {
    if (_mode == InteractionMode.none) return;
    delegate.onTap(viewport.screenToWorld(details.localPosition));
  }

  /// Handles a double-tap gesture.
  void handleDoubleTap(TapUpDetails details) {
    if (_mode == InteractionMode.none) return;
    delegate.onDoubleTap(viewport.screenToWorld(details.localPosition));
  }

  /// Handles a long-press gesture.
  void handleLongPress(LongPressStartDetails details) {
    if (_mode == InteractionMode.none) return;
    delegate.onLongPress(viewport.screenToWorld(details.localPosition));
  }

  /// Resets all gesture state.
  void reset() {
    _state.reset();
  }
}

/// Receives interpreted gesture actions from [CanvasGestureHandler].
///
/// Implement this to respond to user interactions. The [CanvasController]
/// provides a default implementation that connects gestures to canvas
/// operations (select, move, pan, etc.).
abstract class GestureDelegate {
  /// A pointer touched down at [worldPoint].
  void onPointerDown(PointerDownEvent event, Offset worldPoint);

  /// A pointer moved to [worldPoint].
  void onPointerMove(PointerMoveEvent event, Offset worldPoint);

  /// A pointer was released at [worldPoint].
  void onPointerUp(PointerUpEvent event, Offset worldPoint);

  /// A tap occurred at [worldPoint].
  void onTap(Offset worldPoint);

  /// A double-tap occurred at [worldPoint].
  void onDoubleTap(Offset worldPoint);

  /// A long-press started at [worldPoint].
  void onLongPress(Offset worldPoint);

  /// The zoom level changed to [newZoom].
  void onZoomChanged(double newZoom);

  /// The pan offset changed to [newOffset].
  void onPanChanged(Offset newOffset);
}