import 'package:flutter/material.dart';
import 'package:flutter_canvas/flutter_canvas.dart';

void main() {
  runApp(const CanvasExampleApp());
}

class CanvasExampleApp extends StatelessWidget {
  const CanvasExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Canvas Example',
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      home: const CanvasExamplePage(),
    );
  }
}

class CanvasExamplePage extends StatefulWidget {
  const CanvasExamplePage({super.key});

  @override
  State<CanvasExamplePage> createState() => _CanvasExamplePageState();
}

class _CanvasExamplePageState extends State<CanvasExamplePage> {
  final CanvasController controller = CanvasController();

  @override
  void initState() {
    super.initState();
    _addDemoContent();
  }

  void _addDemoContent() {
    // Rectangle
    controller.add(CanvasRect(
      x: 100, y: 100, width: 200, height: 120,
      fillColor: const Color(0xFFE3F2FD),
      strokeColor: const Color(0xFF2196F3),
      strokeWidth: 2,
      cornerRadius: 8,
    ));

    // Circle
    controller.add(CanvasCircle(
      x: 450, y: 160, radius: 60,
      fillColor: const Color(0xFFE8F5E9),
      strokeColor: const Color(0xFF4CAF50),
      strokeWidth: 2,
    ));

    // Arrow
    controller.add(CanvasArrow(
      start: const Offset(300, 160), end: const Offset(390, 160),
      strokeColor: const Color(0xFF333333),
      strokeWidth: 2,
      arrowHeadStyle: 'filled',
    ));

    // Text
    controller.add(CanvasText(
      x: 140, y: 140, text: 'Hello Canvas!',
      fontSize: 20, fontWeight: FontWeight.bold,
      textColor: const Color(0xFF1565C0),
    ));

    // Sticky Note
    controller.add(CanvasStickyNote(
      x: 100, y: 300, text: 'This is a sticky note.\nYou can edit me!',
      backgroundColor: const Color(0xFFFFF9C4),
      textColor: const Color(0xFF5D4037),
      fontSize: 14,
    ));

    // Line
    controller.add(CanvasLine(
      start: const Offset(100, y: 480), end: const Offset(500, 480),
      strokeColor: const Color(0xFF9E9E9E),
      strokeWidth: 1,
      lineCap: StrokeCap.round,
    ));

    // Frame
    controller.add(CanvasFrame(
      x: 550, y: 50, width: 300, height: 200,
      title: 'Design System', showTitle: true,
      fillColor: const Color(0xFFFAFAFA),
    ));

    // Path (hand-drawn)
    controller.add(CanvasPath(
      x: 0, y: 0,
      points: [
        const Offset(550, 350),
        const Offset(600, 320),
        const Offset(650, 340),
        const Offset(700, 300),
        const Offset(750, 330),
        const Offset(800, 310),
      ],
      strokeColor: const Color(0xFFFF5722),
      strokeWidth: 3,
      smoothingEnabled: true,
    ));

    // Polygon
    controller.add(CanvasPolygon(
      x: 450, y: 400, sides: 6, radius: 50,
      strokeColor: const Color(0xFF9C27B0),
      fillColor: const Color(0xFFF3E5F5),
      strokeWidth: 2,
    ));
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Canvas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box),
            tooltip: 'Add Rectangle',
            onPressed: _addRect,
          ),
          IconButton(
            icon: const Icon(Icons.circle_outlined),
            tooltip: 'Add Circle',
            onPressed: _addCircle,
          ),
          IconButton(
            icon: const Icon(Icons.text_fields),
            tooltip: 'Add Text',
            onPressed: _addText,
          ),
          IconButton(
            icon: const Icon(Icons.note),
            tooltip: 'Add Sticky Note',
            onPressed: _addStickyNote,
          ),
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'Undo',
            onPressed: () => controller.history.undo(),
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            tooltip: 'Redo',
            onPressed: () => controller.history.redo(),
          ),
          IconButton(
            icon: const Icon(Icons.zoom_in),
            tooltip: 'Zoom In',
            onPressed: () => controller.viewport.zoomBy(
              CanvasConstants.zoomStep,
              focalPoint: Offset(
                controller.viewport.canvasSize.width / 2,
                controller.viewport.canvasSize.height / 2,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out),
            tooltip: 'Zoom Out',
            onPressed: () => controller.viewport.zoomBy(
              1 / CanvasConstants.zoomStep,
              focalPoint: Offset(
                controller.viewport.canvasSize.width / 2,
                controller.viewport.canvasSize.height / 2,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.fit_screen),
            tooltip: 'Zoom to Fit',
            onPressed: () => controller.zoomToFit(),
          ),
          IconButton(
            icon: const Icon(Icons.grid_on),
            tooltip: 'Toggle Grid',
            onPressed: _toggleGrid,
          ),
        ],
      ),
      body: Column(
        children: [
          // Zoom indicator
          Container(
            height: 32,
            color: Colors.grey.shade100,
            child: Row(
              children: [
                const SizedBox(width: 16),
                Text(
                  'Zoom: ${(controller.viewport.zoom * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 16),
                Text(
                  'Objects: ${controller.objects.length}',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 16),
                if (controller.selection.hasSelection)
                  Text(
                    'Selected: ${controller.selectedObjects.length}',
                    style: const TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                const Spacer(),
                if (controller.history.canUndo)
                  Text('Undo: ${controller.history.undoDescription}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(width: 16),
              ],
            ),
          ),
          // Canvas
          Expanded(
            child: ListenableBuilder(
              listenable: controller,
              builder: (context, _) {
                return FlutterCanvas(
                  controller: controller,
                  showMinimap: true,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _addRect() {
    final center = controller.viewport.screenToWorld(Offset(
      controller.viewport.canvasSize.width / 2,
      controller.viewport.canvasSize.height / 2,
    ));
    controller.addWithUndo(CanvasRect(
      x: center.dx - 50, y: center.dy - 50,
      width: 100, height: 100,
      fillColor: Colors.blue.withOpacity(0.2),
      strokeColor: Colors.blue,
      strokeWidth: 2,
      cornerRadius: 4,
    ));
  }

  void _addCircle() {
    final center = controller.viewport.screenToWorld(Offset(
      controller.viewport.canvasSize.width / 2,
      controller.viewport.canvasSize.height / 2,
    ));
    controller.addWithUndo(CanvasCircle(
      x: center.dx, y: center.dy, radius: 50,
      fillColor: Colors.green.withOpacity(0.2),
      strokeColor: Colors.green, strokeWidth: 2,
    ));
  }

  void _addText() {
    final center = controller.viewport.screenToWorld(Offset(
      controller.viewport.canvasSize.width / 2,
      controller.viewport.canvasSize.height / 2,
    ));
    controller.addWithUndo(CanvasText(
      x: center.dx, y: center.dy,
      text: 'New Text',
      fontSize: 18,
      textColor: const Color(0xFF333333),
    ));
  }

  void _addStickyNote() {
    final center = controller.viewport.screenToWorld(Offset(
      controller.viewport.canvasSize.width / 2,
      controller.viewport.canvasSize.height / 2,
    ));
    controller.addWithUndo(CanvasStickyNote(
      x: center.dx - 150, y: center.dy - 40,
      text: 'New Note',
      backgroundColor: const Color(0xFFFFF9C4),
    ));
  }

  void _toggleGrid() {
    final current = controller.gridConfig;
    controller.setGridConfig(current.copyWith(
      visible: !current.visible,
      type: current.type == GridType.square ? GridType.dot : GridType.square,
    ));
  }
}