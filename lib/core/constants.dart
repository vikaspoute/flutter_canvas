/// Constants used throughout the flutter_canvas package.
///
/// These values define default behaviors, limits, and configuration
/// for the canvas engine. Override them via [CanvasController] configuration.
library;

import 'dart:ui';

/// Centralized constants for the canvas engine.
///
/// All default values, limits, and configuration parameters are defined here.
/// These provide sensible defaults that work well across mobile, web, and desktop.
class CanvasConstants {
  // Private constructor to prevent instantiation.
  CanvasConstants._();

  // ─── Grid ───────────────────────────────────────────────────────────

  /// Default spacing between grid lines or dots.
  static const double defaultGridSize = 20.0;

  // ─── Zoom & Viewport ───────────────────────────────────────────────

  /// Minimum allowed zoom level (1% of actual size).
  static const double minZoom = 0.01;

  /// Maximum allowed zoom level (100x actual size).
  static const double maxZoom = 100.0;

  /// Multiplicative step applied per zoom tick (scroll or pinch).
  static const double zoomStep = 1.2;

  /// Friction coefficient for inertial scrolling after a fling gesture.
  /// Value between 0.0 (instant stop) and 1.0 (no friction).
  static const double scrollInertiaFriction = 0.9;

  // ─── Stroke & Fill ─────────────────────────────────────────────────

  /// Default stroke width for new objects.
  static const double defaultStrokeWidth = 2.0;

  /// Default fill color.
  static const Color defaultFillColor = Color(0xFFFFFFFF);

  /// Default stroke color.
  static const Color defaultStrokeColor = Color(0xFF000000);

  // ─── Text ──────────────────────────────────────────────────────────

  /// Default font size in logical pixels.
  static const double defaultFontSize = 16.0;

  /// Default font family name.
  static const String defaultFontFamily = 'Roboto';

  /// Default line height multiplier.
  static const double defaultLineHeight = 1.4;

  /// Default letter spacing in logical pixels.
  static const double defaultLetterSpacing = 0.0;

  // ─── Object Properties ─────────────────────────────────────────────

  /// Default opacity for new objects (fully opaque).
  static const double defaultOpacity = 1.0;

  /// Default rotation in radians (no rotation).
  static const double defaultRotation = 0.0;

  /// Default corner radius for rectangles.
  static const double defaultCornerRadius = 0.0;

  /// Minimum allowed size for any canvas object in logical pixels.
  static const double minObjectSize = 1.0;

  // ─── Selection ─────────────────────────────────────────────────────

  /// Size of the square resize handles on selected objects.
  static const double selectionHandleSize = 8.0;

  /// Distance of the rotation handle from the selection bounding box.
  static const double rotationHandleDistance = 30.0;

  /// Minimum distance the cursor must move to initiate a selection drag.
  static const double selectionDragThreshold = 4.0;

  // ─── Snapping ──────────────────────────────────────────────────────

  /// Maximum distance (in screen pixels) for snap-to-guide activation.
  static const double snapTolerance = 5.0;

  // ─── History ───────────────────────────────────────────────────────

  /// Maximum number of history entries to retain.
  static const int maxHistorySize = 10000;

  // ─── Interaction Timing ────────────────────────────────────────────

  /// Maximum duration between two taps to register a double-tap.
  static const int doubleTapTimeout = 300;

  /// Duration a pointer must remain stationary to register a long press.
  static const int longPressTimeout = 500;

  // ─── Sticky Notes ──────────────────────────────────────────────────

  /// Maximum width for a sticky note before it wraps.
  static const double maxStickyNoteWidth = 300.0;

  /// Default sticky note background color.
  static const Color stickyNoteColor = Color(0xFFFFEB3B);

  // ─── Arrows & Connectors ───────────────────────────────────────────

  /// Default size of arrow head markers.
  static const double defaultArrowHeadSize = 10.0;

  /// Default radius for connector endpoint circles.
  static const double defaultConnectorRadius = 6.0;

  // ─── Drawing Tools ─────────────────────────────────────────────────

  /// Default width for the eraser tool.
  static const double eraserWidth = 20.0;

  /// Smoothing factor for freehand drawing (0 = no smoothing, 1 = max).
  static const double smoothingFactor = 0.3;

  /// Minimum number of points to simplify a path.
  static const int pathSimplificationThreshold = 3;

  // ─── Versioning ────────────────────────────────────────────────────

  /// Current semantic version of the package.
  static const String version = '1.0.0';

  /// Current serialization schema version.
  /// Increment when breaking changes are made to the JSON format.
  static const int schemaVersion = 1;

  // ─── Performance ───────────────────────────────────────────────────

  /// Target frames per second for the canvas.
  static const int targetFps = 60;

  /// Maximum number of objects before virtualization kicks in.
  static const int virtualizationThreshold = 1000;

  /// Maximum dirty regions tracked per frame before a full repaint.
  static const int maxDirtyRegionsPerFrame = 20;

  // ─── Export ────────────────────────────────────────────────────────

  /// Default pixel ratio for PNG/JPEG exports.
  static const double exportPixelRatio = 2.0;

  /// Default JPEG compression quality (0.0 to 1.0).
  static const double defaultJpegQuality = 0.92;
}