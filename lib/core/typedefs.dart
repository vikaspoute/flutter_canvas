/// Type definitions used throughout the flutter_canvas package.
///
/// These typedefs provide ergonomic aliases for common callback and
/// function signatures used across the canvas engine.
library;

import '../models/canvas_object.dart';
import '../collaboration/models/collaboration_event.dart';

/// Factory function that creates a [CanvasObject] from a JSON map.
///
/// Used by the serialization system to deserialize objects polymorphically.
typedef CanvasObjectFactory = CanvasObject Function(Map<String, dynamic> json);

/// Predicate function for filtering or testing [CanvasObject] instances.
///
/// Returns `true` if the object matches the condition.
typedef CanvasObjectPredicate = bool Function(CanvasObject object);

/// Callback invoked for each object during iteration or batch operations.
typedef CanvasTransformCallback = void Function(CanvasObject object);

/// Callback for rendering a single object in a custom render pipeline.
typedef CanvasRenderCallback = void Function(
  CanvasObject object,
  dynamic context,
);

/// Callback reporting export progress as a value from 0.0 to 1.0.
typedef CanvasExportProgressCallback = void Function(double progress);

/// Listener notified when the undo/redo history changes.
typedef CanvasHistoryListener = void Function();

/// Callback invoked when a collaboration event is received.
typedef CanvasCollaborationCallback = void Function(
  CollaborationEvent event,
);

/// Callback invoked when the selection set changes.
///
/// Receives the complete set of currently selected objects.
typedef CanvasSelectionCallback = void Function(Set<CanvasObject> selected);

/// Callback invoked when a single canvas object is modified.
typedef CanvasObjectChangeListener = void Function(
  CanvasObject object, {
  required String property,
  required Object? oldValue,
  required Object? newValue,
});

/// Function that maps a canvas object to a display name.
typedef CanvasObjectNamer = String Function(CanvasObject object);

/// Comparator for ordering canvas objects (e.g., by z-index or name).
typedef CanvasObjectComparator = int Function(
  CanvasObject a,
  CanvasObject b,
);

/// Predicate that determines whether an object should be included in
/// hit-testing or selection operations.
typedef CanvasHitTestPredicate = bool Function(
  CanvasObject object,
  Offset worldPoint,
);

/// Builder function that creates a widget for a canvas object's overlay.
typedef CanvasOverlayBuilder = dynamic Function(
  CanvasObject object,
  Set<CanvasObject> selection,
);

/// Signature for a function that converts a world-space [Offset] to
/// a screen-space [Offset] using the current viewport transform.
typedef WorldToScreenTransformer = Offset Function(Offset worldPoint);

/// Signature for a function that converts a screen-space [Offset] to
/// a world-space [Offset] using the inverse viewport transform.
typedef ScreenToWorldTransformer = Offset Function(Offset screenPoint);