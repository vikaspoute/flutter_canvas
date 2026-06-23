/// The main FlutterCanvas widget.
///
/// This is the primary widget that developers place in their widget tree
/// to display an interactive infinite canvas.
///
/// Example:
/// ```dart
/// final controller = CanvasController();
/// FlutterCanvas(controller: controller);
/// controller.add(CanvasRect(x: 100, y: 100, width: 200, height: 100));
/// ```
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controllers/canvas_controller.dart';
import '../renderer/canvas_renderer.dart';
import '../gestures/canvas_gesture_handler.dart';
import '../gestures/gesture_state.dart';
import '../selection/selection_manager.dart';
import '../viewport/canvas_viewport.dart';
import '../utils/grid_and_guides.dart';
import '../models/canvas_object.dart';

/// The main canvas widget.
///
/// Provides an infinite, zoomable, pannable canvas with object rendering,
/// selection overlays, grid, and smart guides.
class FlutterCanvas extends StatefulWidget {
  /// The controller that manages all canvas state and operations.
  final CanvasController controller;

  /// Background color of the canvas area.
  final Color backgroundColor;

  /// Whether to show the minimap overlay.
  final bool showMinimap;

  /// Custom builder for the selection overlay.
  final Widget Function(BuildContext, SelectionManager)? selectionOverlayBuilder;

  /// Custom builder for the minimap.
  final Widget Function(BuildContext, CanvasController)? minimapBuilder;

  const FlutterCanvas({
    super.key,
    required this.controller,
    this.backgroundColor = const Color(0xFFFFFFFF),
    this.showMinimap = false,
    this.selectionOverlayBuilder,
    this.minimapBuilder,
  });

  @override
  State<FlutterCanvas> createState() => _FlutterCanvasState();
}

class _FlutterCanvasState extends State<FlutterCanvas> {
  late CanvasRenderer _renderer;
  late CanvasGestureHandler _gestureHandler;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _renderer = CanvasRenderer(
      viewport: widget.controller.viewport,
      getObjects: () => widget.controller.objects,
    );
    _gestureHandler = _CanvasGestureDelegate(
      viewport: widget.controller.viewport,
      controller: widget.controller,
      renderer: _renderer,
    );
    widget.controller.gestureHandler = _gestureHandler;
    widget.controller.addListener(_onControllerChange);
  }

  @override
  void didUpdateWidget(FlutterCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChange);
      widget.controller.gestureHandler = _gestureHandler;
      widget.controller.addListener(_onControllerChange);
      _renderer = CanvasRenderer(
        viewport: widget.controller.viewport,
        getObjects: () => widget.controller.objects,
      );
      _gestureHandler = _CanvasGestureDelegate(
        viewport: widget.controller.viewport,
        controller: widget.controller,
        renderer: _renderer,
      );
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onControllerChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        if (widget.controller.shortcuts.handleKeyEvent(event)) {
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onScaleStart: _gestureHandler.handleScaleStart,
        onScaleUpdate: _gestureHandler.handleScaleUpdate,
        onScaleEnd: _gestureHandler.handleScaleEnd,
        onTapUp: _gestureHandler.handleTap,
        onDoubleTapDown: (d) => _gestureHandler.handleDoubleTap(d.details),
        onLongPressStart: _gestureHandler.handleLongPress,
        child: MouseRegion(
          cursor: _cursorForMode(),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, constraints.maxHeight);
              if (widget.controller.viewport.canvasSize != size) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  widget.controller.viewport.updateCanvasSize(size);
                });
              }
              return Stack(
                children: [
                  // Main canvas
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _CanvasPainter(
                        renderer: _renderer,
                        controller: widget.controller,
                        backgroundColor: widget.backgroundColor,
                      ),
                      size: size,
                    ),
                  ),
                  // Selection overlay
                  if (widget.controller.selection.hasSelection)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _SelectionOverlayPainter(
                          selection: widget.controller.selection,
                          viewport: widget.controller.viewport,
                        ),
                        size: size,
                      ),
                    ),
                  // Minimap
                  if (widget.showMinimap)
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: _MinimapWidget(
                        controller: widget.controller,
                        renderer: _renderer,
                        size: const Size(180, 120),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  SystemMouseCursor _cursorForMode() {
    switch (widget.controller.mode) {
      case InteractionMode.draw: return SystemMouseCursors.crosshair;
      case InteractionMode.pan: return SystemMouseCursors.grab;
      case InteractionMode.boxSelect: return SystemMouseCursors.crosshair;
      default: return SystemMouseCursors.basic;
    }
  }
}

/// CustomPainter that renders all canvas objects plus the grid.
class _CanvasPainter extends CustomPainter {
  final CanvasRenderer renderer;
  final CanvasController controller;
  final Color backgroundColor;

  _CanvasPainter({
    required this.renderer,
    required this.controller,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    canvas.drawRect(Offset.zero & size, Paint()..color = backgroundColor);

    // Grid
    final gridRenderer = GridRenderer(controller.gridConfig);
    gridRenderer.paint(canvas, controller.viewport);

    // Smart guides
    controller.smartGuides.paintGuides(canvas, controller.viewport);

    // Objects
    renderer.paint(canvas, size);
  }

  @override
  bool shouldRepaint(covariant _CanvasPainter oldDelegate) => true;
}

/// Paints selection handles and box-select rectangle.
class _SelectionOverlayPainter extends CustomPainter {
  final SelectionManager selection;
  final CanvasViewport viewport;

  _SelectionOverlayPainter({required this.selection, required this.viewport});

  @override
  void paint(Canvas canvas, Size size) {
    final transform = viewport.transform;

    // Box-select rectangle
    if (selection.isBoxSelecting && selection.boxSelectRect != null) {
      final rect = selection.boxSelectRect!;
      final tl = viewport.worldToScreen(rect.topLeft);
      final br = viewport.worldToScreen(rect.bottomRight);
      canvas.drawRect(
        Rect.fromPoints(tl, br),
        Paint()..color = const Color(0x2266BBFF),
      );
      canvas.drawRect(
        Rect.fromPoints(tl, br),
        Paint()
          ..color = const Color(0xFF4488FF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }

    // Selection handles
    final bounds = selection.selectionBounds;
    if (bounds == null) return;
    final screenBounds = viewport.worldRectToScreen(bounds);
    final handleSize = 8.0;

    // Selection border
    canvas.drawRect(
      screenBounds,
      Paint()
        ..color = const Color(0xFF2196F3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Resize handles
    final handles = [
      screenBounds.topLeft, screenBounds.topCenter, screenBounds.topRight,
      screenBounds.centerRight, screenBounds.bottomRight, screenBounds.bottomCenter,
      screenBounds.bottomLeft, screenBounds.centerLeft,
    ];
    for (final h in handles) {
      canvas.drawRect(
        Rect.fromCenter(center: h, width: handleSize, height: handleSize),
        Paint()..color = Colors.white..style = PaintingStyle.fill,
      );
      canvas.drawRect(
        Rect.fromCenter(center: h, width: handleSize, height: handleSize),
        Paint()..color = const Color(0xFF2196F3)..style = PaintingStyle.stroke..strokeWidth = 1.5,
      );
    }

    // Rotation handle
    final rotHandle = Offset(screenBounds.center.dx, screenBounds.top - 30);
    canvas.drawLine(
      screenBounds.topCenter, rotHandle,
      Paint()..color = const Color(0xFF2196F3)..strokeWidth = 1.0,
    );
    canvas.drawCircle(rotHandle, 5, Paint()..color = const Color(0xFF2196F3));
    canvas.drawCircle(rotHandle, 5, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.5);
  }

  @override
  bool shouldRepaint(covariant _SelectionOverlayPainter oldDelegate) => true;
}

/// A simple minimap widget.
class _MinimapWidget extends StatelessWidget {
  final CanvasController controller;
  final CanvasRenderer renderer;
  final Size size;

  const _MinimapWidget({
    required this.controller,
    required this.renderer,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: CustomPaint(
          painter: _MinimapPainter(controller: controller, renderer: renderer),
          size: size,
        ),
      ),
    );
  }
}

class _MinimapPainter extends CustomPainter {
  final CanvasController controller;
  final CanvasRenderer renderer;

  _MinimapPainter({required this.controller, required this.renderer});

  @override
  void paint(Canvas canvas, Size size) {
    final contentBounds = renderer.contentBounds();
    if (contentBounds == null) return;

    final padding = 10.0;
    final availableSize = Size(size.width - padding * 2, size.height - padding * 2);
    final scaleX = availableSize.width / contentBounds.width;
    final scaleY = availableSize.height / contentBounds.height;
    final scale = scaleX < scaleY ? scaleX : scaleY;

    canvas.save();
    canvas.translate(padding, padding);
    canvas.scale(scale, scale);
    canvas.translate(-contentBounds.left, -contentBounds.top);

    // Draw objects
    for (final obj in controller.objects.where((o) => o.visible)) {
      final wb = obj.worldBounds;
      canvas.drawRect(wb, Paint()
        ..color = const Color(0xFFE0E0E0)..style = PaintingStyle.fill);
      canvas.drawRect(wb, Paint()
        ..color = const Color(0xFF999999)..style = PaintingStyle.stroke..strokeWidth = 2 / scale);
    }

    // Draw viewport rectangle
    final visibleRect = controller.viewport.visibleWorldRect;
    canvas.drawRect(visibleRect, Paint()
      ..color = const Color(0x332196F3)..style = PaintingStyle.fill);
    canvas.drawRect(visibleRect, Paint()
      ..color = const Color(0xFF2196F3)..style = PaintingStyle.stroke..strokeWidth = 3 / scale);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MinimapPainter oldDelegate) => true;
}

/// Default gesture delegate that connects gestures to canvas operations.
class _CanvasGestureDelegate extends GestureDelegate {
  final CanvasController controller;
  final CanvasRenderer renderer;
  final CanvasViewport viewport;
  final GestureState state = GestureState();

  Offset? _dragStartWorld;
  Offset? _dragStartOffset;
  bool _isPanning = false;
  bool _isMovingObjects = false;
  List<Offset>? _originalPositions;

  _CanvasGestureDelegate({
    required this.viewport,
    required this.controller,
    required this.renderer,
  });

  @override
  void onPointerDown(PointerDownEvent event, Offset worldPoint) {
    state.onPointerDown(event);
    state.dragStartWorldPoint = worldPoint;
    state.dragStartScreenPoint = event.position;

    if (controller.mode == InteractionMode.pan || event.buttons == kMiddleMouseButton) {
      _isPanning = true;
      state.isDragging = true;
      return;
    }

    if (controller.mode == InteractionMode.select) {
      // Check if we hit a selected handle
      final handle = controller.selection.hitTestHandles(worldPoint, 10 / viewport.zoom);
      if (handle != null) {
        // Handle resize/rotate - simplified for now
        state.isDragging = true;
        return;
      }

      // Hit test objects
      final hit = renderer.hitTest(event.position);
      if (hit != null && !hit.locked) {
        if (event.modifiers.contains(kShiftModifier)) {
          controller.selection.toggleSelection(hit);
        } else if (!controller.selection.selected.contains(hit)) {
          controller.selection.select(hit);
        }
        // Start move
        _isMovingObjects = true;
        state.isDragging = true;
        _originalPositions = controller.selection.selected.map((o) => o.position).toList();
      } else {
        controller.selection.clear();
      }
    }
  }

  @override
  void onPointerMove(PointerMoveEvent event, Offset worldPoint) {
    if (!state.isDragging) return;

    if (_isPanning) {
      final screenDelta = event.position - (state.dragStartScreenPoint ?? event.position);
      viewport.panBy(screenDelta);
      state.dragStartScreenPoint = event.position;
      return;
    }

    if (_isMovingObjects && _originalPositions != null) {
      final selected = controller.selection.selected.toList();
      final dragDelta = worldPoint - (state.dragStartWorldPoint ?? worldPoint);
      // Apply snapping
      for (var i = 0; i < selected.length && i < _originalPositions!.length; i++) {
        var newPos = _originalPositions![i] + dragDelta;
        newPos = controller.smartGuides.snapToObjects(
          newPos, controller.objects, excludeIds: selected.map((o) => o.id).toSet());
        newPos = controller.smartGuides.snapToGrid(newPos);
        selected[i].position = newPos;
      }
      controller.notifyListeners();
    }
  }

  @override
  void onPointerUp(PointerUpEvent event, Offset worldPoint) {
    if (_isMovingObjects && _originalPositions != null) {
      final selected = controller.selection.selected.toList();
      final newPositions = selected.map((o) => o.position).toList();
      if (_originalPositions!.asMap().entries.any((e) => e.value != newPositions[e.key])) {
        controller.history.execute(
          MoveCommand(selected, List.from(_originalPositions!), newPositions),
        );
      }
      controller.smartGuides.clearGuides();
    }

    state.onPointerUp(event);
    _isPanning = false;
    _isMovingObjects = false;
    _originalPositions = null;
  }

  @override
  void onTap(Offset worldPoint) {}

  @override
  void onDoubleTap(Offset worldPoint) {}

  @override
  void onLongPress(Offset worldPoint) {}

  @override
  void onZoomChanged(double newZoom) {}

  @override
  void onPanChanged(Offset newOffset) {}
}