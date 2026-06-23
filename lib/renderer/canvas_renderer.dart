/// The rendering engine for the canvas.
///
/// Manages efficient painting of canvas objects using dirty-region tracking,
/// layer optimization, and virtualized rendering for large object counts.
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/canvas_object.dart';
import '../core/extensions.dart';
import '../viewport/canvas_viewport.dart';
import '../core/constants.dart';

/// Manages rendering of canvas objects with performance optimizations.
///
/// Features:
/// - Dirty-region tracking to avoid repainting unaffected areas
/// - Viewport culling (objects outside the visible area are skipped)
/// - Z-ordering within layers
/// - Virtualization for object counts exceeding [virtualizationThreshold]
///
/// The renderer does not own the objects or the viewport; it references them
/// to perform painting on demand.
class CanvasRenderer {
  /// The viewport providing the current transform.
  final CanvasViewport viewport;

  /// Callback to get all objects that should be rendered.
  final List<CanvasObject> Function() getObjects;

  /// Set of dirty region rectangles in screen space.
  final Set<Rect> _dirtyRegions = {};

  /// Whether a full repaint is needed on the next frame.
  bool _needsFullRepaint = true;

  /// Cached paint context reused across frames.
  PaintContext? _cachedContext;

  CanvasRenderer({
    required this.viewport,
    required this.getObjects,
  });

  // ─── Dirty Region Management ──────────────────────────────────────────────

  /// Marks the entire canvas as needing repaint.
  void markFullRepaint() {
    _needsFullRepaint = true;
    _dirtyRegions.clear();
  }

  /// Marks a specific region (in world coordinates) as dirty.
  void markDirty(Rect worldRect) {
    final screenRect = viewport.worldRectToScreen(worldRect);
    if (_dirtyRegions.length >= CanvasConstants.maxDirtyRegionsPerFrame) {
      _needsFullRepaint = true;
      _dirtyRegions.clear();
      return;
    }
    _dirtyRegions.add(screenRect);
  }

  /// Marks a specific object as needing repaint.
  void markObjectDirty(CanvasObject object) {
    markDirty(object.worldBounds);
  }

  /// Returns `true` if any region of the canvas needs repainting.
  bool get needsRepaint => _needsFullRepaint || _dirtyRegions.isNotEmpty;

  /// Returns `true` if the given object's screen bounds intersect any
  /// dirty region, meaning it needs to be repainted.
  bool isObjectDirty(CanvasObject object) {
    if (_needsFullRepaint) return true;
    final screenBounds = viewport.worldRectToScreen(object.worldBounds);
    for (final dirty in _dirtyRegions) {
      if (screenBounds.overlapsRect(dirty)) return true;
    }
    return false;
  }

  // ─── Rendering ────────────────────────────────────────────────────────────

  /// Paints all visible objects onto the canvas.
  ///
  /// Called from a [CustomPainter.paint] method. This method:
  /// 1. Builds the paint context with the current viewport transform
  /// 2. Filters objects to only those visible in the viewport
  /// 3. Sorts by z-index
  /// 4. Calls [CanvasObject.render] on each visible, non-dirty-skippable object
  void paint(Canvas canvas, Size size, {double pixelRatio = 1.0}) {
    _cachedContext = PaintContext(
      canvas: canvas,
      viewportTransform: viewport.transform,
      pixelRatio: pixelRatio,
      zoom: viewport.zoom,
    );

    final objects = getObjects();
    final visibleRect = viewport.visibleWorldRect;

    // Sort objects by z-index for correct draw order
    final sortedObjects = List<CanvasObject>.from(objects)
      ..sort((a, b) => a.zIndex.compareTo(b.zIndex));

    // Render grid and background first (handled by widget layer)

    // Render each visible object
    for (final object in sortedObjects) {
      if (!object.visible) continue;

      // Viewport culling
      if (!object.worldBounds.overlapsRect(visibleRect) &&
          !visibleRect.containsRect(object.worldBounds)) {
        // Check expanded bounds for large objects
        final expanded = visibleRect.inflate(500 / viewport.zoom);
        if (!object.worldBounds.overlapsRect(expanded)) continue;
      }

      object.render(_cachedContext!);
      object.clearDirty();
    }

    // Clear dirty regions after full paint
    _dirtyRegions.clear();
    _needsFullRepaint = false;
  }

  /// Paints only the objects that overlap the given [clipRect] in world space.
  ///
  /// Useful for partial exports or minimap rendering.
  void paintRegion(Canvas canvas, Rect worldClipRect, {double pixelRatio = 1.0}) {
    final ctx = PaintContext(
      canvas: canvas,
      viewportTransform: viewport.transform,
      pixelRatio: pixelRatio,
      zoom: viewport.zoom,
    );

    final objects = getObjects()
        .where((o) => o.visible && o.worldBounds.overlapsRect(worldClipRect))
        .toList()
      ..sort((a, b) => a.zIndex.compareTo(b.zIndex));

    for (final object in objects) {
      object.render(ctx);
    }
  }

  /// Performs a hit test at [screenPoint], returning the topmost object
  /// under the cursor, or `null` if nothing was hit.
  CanvasObject? hitTest(Offset screenPoint) {
    final worldPoint = viewport.screenToWorld(screenPoint);
    final objects = getObjects();
    // Test in reverse z-order (topmost first)
    final sortedObjects = List<CanvasObject>.from(objects)
      ..sort((a, b) => b.zIndex.compareTo(a.zIndex));
    for (final object in sortedObjects) {
      if (object.hitTest(worldPoint)) return object;
    }
    return null;
  }

  /// Performs a hit test returning all objects under [screenPoint].
  List<CanvasObject> hitTestAll(Offset screenPoint) {
    final worldPoint = viewport.screenToWorld(screenPoint);
    return getObjects()
        .where((o) => o.visible && o.hitTest(worldPoint))
        .toList()
      ..sort((a, b) => b.zIndex.compareTo(a.zIndex));
  }

  /// Returns all objects whose world bounds intersect [worldRect].
  List<CanvasObject> objectsInRect(Rect worldRect) {
    return getObjects()
        .where((o) => o.visible && o.worldBounds.overlapsRect(worldRect))
        .toList()
      ..sort((a, b) => a.zIndex.compareTo(b.zIndex));
  }

  /// Returns the combined bounding box of all objects, or `null` if empty.
  Rect? contentBounds() {
    final objects = getObjects();
    if (objects.isEmpty) return null;
    Rect? combined;
    for (final obj in objects) {
      final wb = obj.worldBounds;
      combined = combined?.expandToInclude(wb.topLeft)?.expandToInclude(wb.bottomRight) ?? wb;
    }
    return combined;
  }
}