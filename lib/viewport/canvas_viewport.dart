/// Viewport and camera system for the infinite canvas.
///
/// Manages the transformation between world coordinates and screen coordinates,
/// including pan (offset), zoom (scale), and rotation. Supports smooth animated
/// transitions, zoom-to-cursor, and infinite scrolling.
library;

import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../core/constants.dart';
import '../core/extensions.dart';
import '../utils/transform_utils.dart';

/// Manages the camera/viewport transform for the canvas.
///
/// The viewport converts between world coordinates (the infinite canvas space
/// where objects live) and screen coordinates (pixel positions on the display).
///
/// The transform is: screen = (world - offset) * zoom + screenCenter
///
/// Example:
/// ```dart
/// final viewport = CanvasViewport(canvasSize: Size(800, 600));
/// viewport.zoomBy(1.2, focalPoint: Offset(400, 300));
/// final worldPos = viewport.screenToWorld(Offset(100, 100));
/// ```
class CanvasViewport with ChangeNotifier {
  /// Current pan offset in world coordinates.
  Offset _offset;

  /// Current zoom level (1.0 = 100%, 2.0 = 200%).
  double _zoom;

  /// Current rotation of the viewport in radians.
  double _rotation;

  /// Size of the canvas widget in logical pixels.
  Size _canvasSize;

  /// Target values for animated transitions.
  Offset? _targetOffset;
  double? _targetZoom;
  double? _targetRotation;

  /// Animation controller tick for smooth transitions.
  Ticker? _ticker;
  double _animationProgress = 1.0;
  Offset _animationStartOffset = Offset.zero;
  double _animationStartZoom = 1.0;

  /// Minimum and maximum zoom constraints.
  final double minZoom;
  final double maxZoom;

  /// Creates a new viewport.
  CanvasViewport({
    Offset offset = Offset.zero,
    double zoom = 1.0,
    double rotation = 0.0,
    required Size canvasSize,
    this.minZoom = CanvasConstants.minZoom,
    this.maxZoom = CanvasConstants.maxZoom,
  })  : _offset = offset,
        _zoom = zoom.clamp(CanvasConstants.minZoom, CanvasConstants.maxZoom),
        _rotation = rotation,
        _canvasSize = canvasSize;

  // ─── Getters ──────────────────────────────────────────────────────────────

  /// Current pan offset in world coordinates.
  Offset get offset => _offset;

  /// Current zoom level.
  double get zoom => _zoom;

  /// Current rotation in radians.
  double get rotation => _rotation;

  /// Current canvas size.
  Size get canvasSize => _canvasSize;

  /// Whether an animation is currently in progress.
  bool get isAnimating => _animationProgress < 1.0;

  /// The computed viewport transform matrix (world → screen).
  Matrix4 get transform => TransformUtils.buildViewportMatrix(
        offset: _offset,
        zoom: _zoom,
        canvasSize: _canvasSize,
      );

  /// The inverse transform (screen → world).
  Matrix4 get inverseTransform => TransformUtils.safeInvert(transform);

  // ─── Coordinate Conversion ────────────────────────────────────────────────

  /// Converts a screen-space point to world-space coordinates.
  Offset screenToWorld(Offset screenPoint) {
    return TransformUtils.screenToWorld(transform, screenPoint, _canvasSize);
  }

  /// Converts a world-space point to screen-space coordinates.
  Offset worldToScreen(Offset worldPoint) {
    return TransformUtils.worldToScreen(transform, worldPoint);
  }

  /// Converts a screen-space rect to world-space.
  Rect screenRectToWorld(Rect screenRect) {
    final topLeft = screenToWorld(screenRect.topLeft);
    final bottomRight = screenToWorld(screenRect.bottomRight);
    return Rect.fromPoints(topLeft, bottomRight);
  }

  /// Converts a world-space rect to screen-space.
  Rect worldRectToScreen(Rect worldRect) {
    final topLeft = worldToScreen(worldRect.topLeft);
    final bottomRight = worldToScreen(worldRect.bottomRight);
    return Rect.fromPoints(topLeft, bottomRight);
  }

  /// Returns the visible region of the world in world coordinates.
  Rect get visibleWorldRect {
    final tl = screenToWorld(Offset.zero);
    final br = screenToWorld(_canvasSize);
    return Rect.fromPoints(tl, br);
  }

  // ─── Pan Operations ───────────────────────────────────────────────────────

  /// Sets the offset directly.
  void setOffset(Offset newOffset) {
    _offset = newOffset;
    notifyListeners();
  }

  /// Pans by the given delta in screen-space pixels.
  void panBy(Offset screenDelta) {
    _offset += screenDelta / _zoom;
    notifyListeners();
  }

  /// Pans to center a specific world-space point on screen.
  void panTo(Offset worldPoint, {Offset? screenTarget}) {
    final target = screenTarget ?? Offset(_canvasSize.width / 2, _canvasSize.height / 2);
    _offset = worldPoint - target / _zoom;
    notifyListeners();
  }

  // ─── Zoom Operations ──────────────────────────────────────────────────────

  /// Sets the zoom level directly, clamped to [minZoom] and [maxZoom].
  void setZoom(double newZoom) {
    _zoom = newZoom.clamp(minZoom, maxZoom);
    notifyListeners();
  }

  /// Zooms by a multiplicative [factor] centered on [focalPoint] in screen space.
  ///
  /// This keeps the point under the cursor stationary during zoom, providing
  /// a natural "zoom to cursor" experience.
  void zoomBy(double factor, {required Offset focalPoint}) {
    final worldBefore = screenToWorld(focalPoint);
    _zoom = (_zoom * factor).clamp(minZoom, maxZoom);
    final worldAfter = screenToWorld(focalPoint);
    _offset += worldBefore - worldAfter;
    notifyListeners();
  }

  /// Zooms to fit the given [worldRect] within the viewport with padding.
  void zoomToFit(Rect worldRect, {double padding = 40}) {
    if (worldRect.isEmpty) return;
    final effectiveSize = _canvasSize - Offset(padding * 2, padding * 2);
    final scaleX = effectiveSize.width / worldRect.width;
    final scaleY = effectiveSize.height / worldRect.height;
    _zoom = (math.min(scaleX, scaleY)).clamp(minZoom, maxZoom);
    _offset = worldRect.center - _canvasSize / (2 * _zoom);
    notifyListeners();
  }

  /// Zooms to fit the entire canvas content.
  void zoomToFitContent(Iterable<Rect> objectBounds, {double padding = 60}) {
    if (objectBounds.isEmpty) return;
    Rect? combined;
    for (final b in objectBounds) {
      combined = combined?.expandToInclude(b.topLeft)?.expandToInclude(b.bottomRight) ?? b;
    }
    if (combined != null) zoomToFit(combined, padding: padding);
  }

  // ─── Rotation ─────────────────────────────────────────────────────────────

  /// Sets the viewport rotation in radians.
  void setRotation(double radians) {
    _rotation = radians;
    notifyListeners();
  }

  // ─── Animated Transitions ─────────────────────────────────────────────────

  /// Animates to the specified offset and zoom over [duration].
  void animateTo({
    Offset? offset,
    double? zoom,
    double? rotation,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeOutCubic,
  }) {
    _targetOffset = offset;
    _targetZoom = zoom?.clamp(minZoom, maxZoom);
    _targetRotation = rotation;
    _animationStartOffset = _offset;
    _animationStartZoom = _zoom;
    _animationProgress = 0.0;

    _ticker?.stop();
    final start = DateTime.now().microsecondsSinceEpoch;
    final dur = duration.inMicroseconds;

    _ticker = Ticker((elapsed) {
      final now = DateTime.now().microsecondsSinceEpoch;
      _animationProgress = ((now - start) / dur).clamp(0.0, 1.0);
      final t = curve.transform(_animationProgress);

      if (_targetOffset != null) {
        _offset = Offset.lerp(_animationStartOffset, _targetOffset!, t)!;
      }
      if (_targetZoom != null) {
        _zoom = _animationStartZoom + (_targetZoom! - _animationStartZoom) * t;
        _zoom = _zoom.clamp(minZoom, maxZoom);
      }
      if (_targetRotation != null) {
        _rotation = _rotation + (_targetRotation! - _rotation) * t;
      }

      notifyListeners();

      if (_animationProgress >= 1.0) {
        _ticker?.stop();
        _ticker = null;
      }
    });
    _ticker!.start();
  }

  // ─── Reset ────────────────────────────────────────────────────────────────

  /// Resets the viewport to its default state (offset zero, zoom 1.0).
  void reset({bool animate = false}) {
    if (animate) {
      animateTo(offset: Offset.zero, zoom: 1.0, rotation: 0.0);
    } else {
      _offset = Offset.zero;
      _zoom = 1.0;
      _rotation = 0.0;
      notifyListeners();
    }
  }

  // ─── Resize ───────────────────────────────────────────────────────────────

  /// Updates the canvas size (called on layout changes).
  void updateCanvasSize(Size newSize) {
    if (_canvasSize == newSize) return;
    final oldCenter = _canvasSize / 2;
    final newCenter = newSize / 2;
    _offset += (oldCenter - newCenter) / _zoom;
    _canvasSize = newSize;
    notifyListeners();
  }

  // ─── Dispose ──────────────────────────────────────────────────────────────

  /// Disposes the viewport and stops any running animations.
  void dispose() {
    _ticker?.stop();
    _ticker = null;
  }
}