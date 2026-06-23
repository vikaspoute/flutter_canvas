/// Flutter Canvas — A production-grade infinite canvas engine for Flutter.
///
/// Build whiteboards, design tools, diagram builders, flowcharts,
/// collaborative workspaces, and more.
library;

// Core
export 'core/exceptions.dart';
export 'core/constants.dart';
export 'core/extensions.dart';
export 'core/typedefs.dart';

// Models
export 'models/canvas_object.dart';
export 'models/shapes/canvas_rect.dart';
export 'models/shapes/canvas_circle.dart';
export 'models/shapes/canvas_line.dart';
export 'models/shapes/canvas_arrow.dart';
export 'models/shapes/canvas_text.dart';
export 'models/shapes/canvas_image.dart';
export 'models/shapes/canvas_path.dart';
export 'models/shapes/canvas_polygon.dart';
export 'models/shapes/canvas_sticky_note.dart';
export 'models/shapes/canvas_frame.dart';
export 'models/shapes/canvas_svg.dart';
export 'models/shapes/canvas_group.dart';

// Controller
export 'controllers/canvas_controller.dart';

// Widget
export 'widgets/flutter_canvas_widget.dart';

// Viewport
export 'viewport/canvas_viewport.dart';

// Selection
export 'selection/selection_manager.dart';

// Layers
export 'layers/layer_manager.dart';

// History
export 'history/history_manager.dart';
export 'commands/canvas_commands.dart';

// Serialization
export 'serialization/object_registry.dart';
export 'serialization/canvas_serializer.dart';

// Export
export 'export/canvas_exporter.dart';

// Grid & Guides
export 'utils/grid_and_guides.dart';

// Keyboard
export 'utils/keyboard_shortcuts.dart';

// Drawing Tools
export 'canvas/drawing_tools.dart';

// Gestures
export 'gestures/canvas_gesture_handler.dart';

// Collaboration
export 'collaboration/collaboration_manager.dart';
export 'collaboration/models/collaboration_event.dart';
