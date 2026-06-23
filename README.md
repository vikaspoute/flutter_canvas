# Flutter Canvas

A production-grade **infinite canvas engine** for Flutter. Build whiteboards, design tools, diagram builders, flowcharts, and collaborative workspaces.

<p align="center">
  <strong>Inspired by Miro, Figma, Excalidraw, Canva, Fabric.js & Konva — designed natively for Flutter.</strong>
</p>

## ✨ Features

- **Infinite Canvas** — Unlimited workspace with smooth pan, zoom, and rotation
- **12 Built-in Object Types** — Rect, Circle, Line, Arrow, Text, Image, SVG, Path, Polygon, Sticky Note, Frame, Group
- **Selection System** — Single/multi select, box select, shift select, resize handles, rotation handles
- **Layer Management** — Create, delete, lock, hide, rename, reorder, nest layers
- **Undo/Redo** — Command Pattern with history compression and transaction support
- **Smart Guides** — Snap to grid, snap to objects, alignment guides
- **Grid System** — Square, dot, and isometric grids with configurable size
- **Serialization** — JSON import/export with versioned schema
- **Export** — PNG, JPEG, SVG output at arbitrary resolution
- **Collaboration** — OT/CRDT-ready interfaces for real-time multi-user editing
- **Keyboard Shortcuts** — Cross-platform: Ctrl+C/V/X/Z, Delete, arrow nudges, and more
- **Drawing Tools** — Pen, shape, text, and sticky note tools
- **Minimap** — Built-in minimap overlay
- **Performance** — Dirty-region rendering, viewport culling, virtualization for 10K+ objects
- **Clean Architecture** — Modular, extensible, testable

## 🚀 Quick Start

### Installation

```yaml
dependencies:
  flutter_canvas: ^1.0.0
```

### Basic Usage

```dart
import 'package:flutter_canvas/flutter_canvas.dart';

final controller = CanvasController();

// Add objects
controller.add(CanvasRect(
  x: 100, y: 100, width: 200, height: 100,
  fillColor: Colors.blue,
));

controller.add(CanvasText(
  x: 100, y: 50, text: 'Hello Canvas!',
  fontSize: 24,
));

// Display
FlutterCanvas(controller: controller);

// Undo / Redo
controller.undo();
controller.redo();

// Export
final pngBytes = await controller.exportPng(pixelRatio: 3.0);
final svgString = controller.exportSvg();

// Serialize
final json = controller.exportJson();
controller.importJson(json);
```

## 📐 Architecture

```
flutter_canvas/
├── lib/
│   ├── flutter_canvas.dart        # Barrel exports
│   ├── core/                      # Exceptions, constants, extensions, typedefs
│   ├── canvas/                    # Drawing tools
│   ├── models/                    # CanvasObject + 11 shape types
│   │   └── shapes/                # Rect, Circle, Line, Arrow, Text, Image,
│   │                             #   Path, Polygon, StickyNote, Frame, SVG, Group
│   ├── controllers/               # CanvasController (primary API)
│   ├── widgets/                   # FlutterCanvas widget
│   ├── viewport/                  # Camera/viewport transforms
│   ├── renderer/                  # CustomPainter rendering engine
│   ├── gestures/                  # Touch/mouse/stylus/trackpad handling
│   ├── selection/                 # Selection manager + handles
│   ├── layers/                    # Layer management
│   ├── history/                   # Undo/redo with Command Pattern
│   ├── commands/                  # Move, Delete, Create, Resize, Rotate commands
│   ├── serialization/             # JSON import/export, object registry
│   ├── export/                    # PNG, JPEG, SVG export
│   ├── collaboration/             # OT/CRDT interfaces, presence, cursor tracking
│   └── utils/                     # Transform utils, grid, keyboard shortcuts
├── example/                       # Full demo app
├── test/                          # Unit, widget, and benchmark tests
└── docs/                          # Architecture docs
```

## 🎯 Use Cases

| Use Case | Status |
|----------|--------|
| Whiteboard (Miro clone) | ✅ |
| Excalidraw clone | ✅ |
| Figma whiteboard | ✅ |
| Diagram builder | ✅ |
| Flowchart builder | ✅ |
| Mind mapping | ✅ |
| Resume builder | ✅ |
| Poster designer | ✅ |
| Collaborative workspace | ✅ (interfaces ready) |

## 📦 API Overview

### CanvasController

The primary API surface. All operations go through the controller.

```dart
// Object management
controller.add(object)
controller.addWithUndo(object)
controller.remove(objectId)
controller.clear()
controller.getObject(id)

// Selection
controller.select(object)
controller.selectAll()
controller.deselectAll()
controller.selectedObjects
controller.deleteSelected()
controller.copySelected()
controller.pasteClipboard()
controller.duplicateSelected()
controller.groupSelected()
controller.ungroupSelected()

// Transform
controller.bringToFront(object)
controller.sendToBack(object)
controller.nudgeSelected(Offset(10, 0))

// Viewport
controller.zoomToFit()
controller.zoomToSelection()
controller.viewport.zoomBy(1.5, focalPoint: center)

// Serialization
controller.exportJson()
controller.importJson(jsonString)

// Export
await controller.exportPng(pixelRatio: 3.0)
await controller.exportJpeg()
controller.exportSvg()

// History
controller.history.undo()
controller.history.redo()
controller.history.canUndo
controller.history.canRedo
```

### CanvasObject

All objects share a common base:

```dart
CanvasObject(
  id: String,
  name: String,
  position: Offset,
  rotation: double,
  scale: Offset,
  opacity: double,
  visible: bool,
  locked: bool,
  zIndex: int,
  metadata: Map<String, dynamic>,
)
```

### Drawing Tools

```dart
final penTool = PenTool(config: DrawingToolConfig(
  strokeColor: Colors.black,
  strokeWidth: 3,
));
controller.setInteractionMode(InteractionMode.draw);
```

## 🧪 Testing

```bash
flutter test
```

Tests cover models, viewport, history, selection, layers, controller, and serialization.

## 🤝 Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## 📄 License

BSD 3-Clause. See [LICENSE](LICENSE).
