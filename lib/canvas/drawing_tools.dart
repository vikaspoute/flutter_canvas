/// Drawing tool types and base class.
///
/// Provides a framework for implementing drawing tools (pen, brush,
/// shape, arrow, text, etc.) that can be plugged into the canvas.
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/canvas_object.dart';
import '../models/shapes/canvas_path.dart';
import '../models/shapes/canvas_rect.dart';
import '../models/shapes/canvas_circle.dart';
import '../models/shapes/canvas_line.dart';
import '../models/shapes/canvas_arrow.dart';
import '../models/shapes/canvas_text.dart';
import '../models/shapes/canvas_sticky_note.dart';
import '../models/shapes/canvas_frame.dart';
import '../viewport/canvas_viewport.dart';
import '../controllers/canvas_controller.dart';

/// The type of drawing tool.
enum DrawingToolType {
  select, pen, brush, marker, highlighter, eraser,
  laserPointer, rectangle, circle, line, arrow,
  text, stickyNote, frame, hand,
}

/// Configuration for a drawing tool.
class DrawingToolConfig {
  final Color strokeColor;
  final Color fillColor;
  final double strokeWidth;
  final double fontSize;
  final String fontFamily;
  bool fill;

  DrawingToolConfig({
    this.strokeColor = const Color(0xFF000000),
    this.fillColor = const Color(0xFFFFFFFF),
    this.strokeWidth = 2.0,
    this.fontSize = 16.0,
    this.fontFamily = 'Roboto',
    this.fill = false,
  });

  DrawingToolConfig copyWith({
    Color? strokeColor, Color? fillColor, double? strokeWidth,
    double? fontSize, String? fontFamily, bool? fill,
  }) => DrawingToolConfig(
    strokeColor: strokeColor ?? this.strokeColor,
    fillColor: fillColor ?? this.fillColor,
    strokeWidth: strokeWidth ?? this.strokeWidth,
    fontSize: fontSize ?? this.fontSize,
    fontFamily: fontFamily ?? this.fontFamily,
    fill: fill ?? this.fill,
  );
}

/// Base class for all drawing tools.
///
/// Subclasses implement the specific behavior for each tool type:
/// - [PenTool]: Freehand drawing with smoothing
/// - [ShapeTool]: Rectangle, circle, and other shapes
/// - [TextTool]: Text placement
///
/// Tools receive pointer events and create/modify canvas objects.
abstract class DrawingTool {
  final DrawingToolType type;
  DrawingToolConfig config;

  DrawingTool({required this.type, DrawingToolConfig? config})
      : config = config ?? DrawingToolConfig();

  /// Called when the tool is activated.
  void activate(CanvasController controller) {}

  /// Called when the tool is deactivated.
  void deactivate(CanvasController controller) {}

  /// Called when a pointer goes down in world coordinates.
  void onPointerDown(Offset worldPoint, CanvasController controller) {}

  /// Called when a pointer moves in world coordinates.
  void onPointerMove(Offset worldPoint, CanvasController controller) {}

  /// Called when a pointer goes up in world coordinates.
  void onPointerUp(Offset worldPoint, CanvasController controller) {}

  /// Returns the cursor for this tool.
  MouseCursor get cursor => MouseCursor.uncontrolled;
}

/// Pen/brush freehand drawing tool.
class PenTool extends DrawingTool {
  CanvasPath? _currentPath;
  List<Offset> _points = [];
  bool _smoothingEnabled;

  PenTool({DrawingToolConfig? config, bool smoothing = true})
      : _smoothingEnabled = smoothing,
        super(type: DrawingToolType.pen, config: config);

  @override
  void onPointerDown(Offset worldPoint, CanvasController controller) {
    _points = [worldPoint];
    _currentPath = CanvasPath(
      points: _points,
      strokeColor: config.strokeColor,
      strokeWidth: config.strokeWidth,
      smoothingEnabled: _smoothingEnabled,
    );
    controller.add(_currentPath!);
  }

  @override
  void onPointerMove(Offset worldPoint, CanvasController controller) {
    if (_currentPath == null) return;
    _points.add(worldPoint);
    _currentPath!.points = List.from(_points);
    controller.notifyListeners();
  }

  @override
  void onPointerUp(Offset worldPoint, CanvasController controller) {
    _currentPath = null;
    _points = [];
  }

  @override
  MouseCursor get cursor => SystemMouseCursors.crosshair;
}

/// Shape drawing tool (rectangle, circle).
class ShapeTool extends DrawingTool {
  final ShapeType shapeType;
  Offset? _startPoint;
  CanvasObject? _currentShape;

  ShapeTool({required this.shapeType, DrawingToolConfig? config})
      : super(type: DrawingToolType.rectangle, config: config);

  @override
  void onPointerDown(Offset worldPoint, CanvasController controller) {
    _startPoint = worldPoint;
  }

  @override
  void onPointerMove(Offset worldPoint, CanvasController controller) {
    if (_startPoint == null) return;
    final rect = Rect.fromPoints(_startPoint!, worldPoint);

    if (_currentShape != null) {
      controller.remove(_currentShape!.id);
    }

    switch (shapeType) {
      case ShapeType.rectangle:
        _currentShape = CanvasRect(
          x: rect.left, y: rect.top,
          width: rect.width.abs(), height: rect.height.abs(),
          fillColor: config.fill ? config.fillColor : Colors.transparent,
          strokeColor: config.strokeColor, strokeWidth: config.strokeWidth,
        );
        break;
      case ShapeType.circle:
        final radius = (rect.width.abs() + rect.height.abs()) / 4;
        _currentShape = CanvasCircle(
          x: rect.center.dx, y: rect.center.dy, radius: radius,
          fillColor: config.fill ? config.fillColor : Colors.transparent,
          strokeColor: config.strokeColor, strokeWidth: config.strokeWidth,
        );
        break;
      case ShapeType.line:
        _currentShape = CanvasLine(
          start: _startPoint!, end: worldPoint,
          strokeColor: config.strokeColor, strokeWidth: config.strokeWidth,
        );
        break;
      case ShapeType.arrow:
        _currentShape = CanvasArrow(
          start: _startPoint!, end: worldPoint,
          strokeColor: config.strokeColor, strokeWidth: config.strokeWidth,
        );
        break;
    }

    if (_currentShape != null) {
      controller.add(_currentShape!);
    }
  }

  @override
  void onPointerUp(Offset worldPoint, CanvasController controller) {
    _startPoint = null;
    _currentShape = null;
  }

  @override
  MouseCursor get cursor => SystemMouseCursors.crosshair;
}

/// Text placement tool.
class TextTool extends DrawingTool {
  @override
  void onPointerUp(Offset worldPoint, CanvasController controller) {
    controller.add(CanvasText(
      x: worldPoint.dx, y: worldPoint.dy,
      text: 'Text', fontSize: config.fontSize, fontFamily: config.fontFamily,
      textColor: config.strokeColor,
    ));
  }

  @override
  MouseCursor get cursor => SystemMouseCursors.text;
}

/// Sticky note placement tool.
class StickyNoteTool extends DrawingTool {
  @override
  void onPointerUp(Offset worldPoint, CanvasController controller) {
    controller.add(CanvasStickyNote(
      x: worldPoint.dx, y: worldPoint.dy,
      backgroundColor: config.fillColor, text: 'Note',
    ));
  }

  @override
  MouseCursor get cursor => SystemMouseCursors.cell;
}

enum ShapeType { rectangle, circle, line, arrow }