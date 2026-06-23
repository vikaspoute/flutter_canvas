/// Core exceptions for the flutter_canvas package.
///
/// All exceptions thrown by the canvas engine inherit from [CanvasException].
library;

/// Base exception for all canvas-related errors.
///
/// Provides a consistent interface for error handling across the canvas system.
/// All specific canvas exceptions extend this class.
class CanvasException implements Exception {
  /// A human-readable description of the error.
  final String message;

  /// Optional stack trace at the point where the exception was thrown.
  final StackTrace? stackTrace;

  /// Optional identifier of the object that caused the exception.
  final String? objectId;

  /// Creates a new [CanvasException] with the given [message].
  const CanvasException(
    this.message, {
    this.stackTrace,
    this.objectId,
  });

  @override
  String toString() {
    final buffer = StringBuffer('CanvasException: $message');
    if (objectId != null) {
      buffer.write(' (objectId: $objectId)');
    }
    return buffer.toString();
  }
}

/// Thrown when a requested [CanvasObject] cannot be found by its ID.
///
/// This typically occurs when an operation references an object that has been
/// deleted or was never added to the canvas.
class CanvasObjectNotFoundException extends CanvasException {
  /// Creates a new [CanvasObjectNotFoundException] for the given [objectId].
  const CanvasObjectNotFoundException(
    super.objectId, {
    super.stackTrace,
  }) : super('Object not found');

  @override
  String toString() =>
      'CanvasObjectNotFoundException: Object with id "$objectId" not found';
}

/// Thrown when a requested layer cannot be found by its ID or name.
///
/// Layers may be deleted or renamed, causing operations that reference them
/// by their previous identifier to fail.
class CanvasLayerNotFoundException extends CanvasException {
  /// Creates a new [CanvasLayerNotFoundException] for the given [layerId].
  const CanvasLayerNotFoundException(
    String layerId, {
    super.stackTrace,
  }) : super('Layer not found', objectId: layerId);

  @override
  String toString() =>
      'CanvasLayerNotFoundException: Layer with id "$objectId" not found';
}

/// Thrown when serialization (to or from JSON) fails.
///
/// This can occur due to malformed JSON, unsupported object types,
/// version incompatibilities, or missing required fields.
class CanvasSerializationException extends CanvasException {
  /// Optional field name that caused the serialization error.
  final String? field;

  /// Creates a new [CanvasSerializationException].
  const CanvasSerializationException(
    super.message, {
    this.field,
    super.stackTrace,
    super.objectId,
  });

  @override
  String toString() {
    final buffer = StringBuffer('CanvasSerializationException: $message');
    if (field != null) buffer.write(' (field: $field)');
    if (objectId != null) buffer.write(' (objectId: $objectId)');
    return buffer.toString();
  }
}

/// Thrown when exporting the canvas to an image, SVG, or PDF fails.
///
/// Export failures can result from render issues, unsupported formats,
/// permission errors, or resource constraints.
class CanvasExportException extends CanvasException {
  /// The export format that was being used when the error occurred.
  final String? format;

  /// Creates a new [CanvasExportException].
  const CanvasExportException(
    super.message, {
    this.format,
    super.stackTrace,
  });

  @override
  String toString() {
    final buffer = StringBuffer('CanvasExportException: $message');
    if (format != null) buffer.write(' (format: $format)');
    return buffer.toString();
  }
}

/// Thrown when the rendering engine encounters an error.
///
/// This can include issues with paint objects, transform matrices,
/// clipping regions, or canvas operations.
class CanvasRenderException extends CanvasException {
  /// Creates a new [CanvasRenderException].
  const CanvasRenderException(
    super.message, {
    super.stackTrace,
    super.objectId,
  });

  @override
  String toString() => 'CanvasRenderException: $message';
}

/// Thrown when a geometric transformation operation fails.
///
/// This can happen with degenerate matrices, singular transforms,
/// or invalid transform parameters.
class CanvasTransformException extends CanvasException {
  /// Creates a new [CanvasTransformException].
  const CanvasTransformException(
    super.message, {
    super.stackTrace,
    super.objectId,
  });

  @override
  String toString() => 'CanvasTransformException: $message';
}

/// Thrown when an undo/redo or history operation fails.
///
/// This can occur when trying to redo past the end of history,
/// undo before the beginning, or when history state is corrupted.
class CanvasHistoryException extends CanvasException {
  /// Creates a new [CanvasHistoryException].
  const CanvasHistoryException(
    super.message, {
    super.stackTrace,
  });

  @override
  String toString() => 'CanvasHistoryException: $message';
}

/// Thrown when a real-time collaboration operation fails.
///
/// Collaboration errors may result from connection issues,
/// conflict resolution failures, or invalid operational transform operations.
class CanvasCollaborationException extends CanvasException {
  /// Optional ID of the remote client or session involved.
  final String? sessionId;

  /// Creates a new [CanvasCollaborationException].
  const CanvasCollaborationException(
    super.message, {
    this.sessionId,
    super.stackTrace,
  });

  @override
  String toString() {
    final buffer = StringBuffer('CanvasCollaborationException: $message');
    if (sessionId != null) buffer.write(' (sessionId: $sessionId)');
    return buffer.toString();
  }
}

/// Thrown when an operation is performed on a canvas object that is
/// in an invalid state for that operation.
///
/// For example: trying to move a locked object, resize a grouped child
/// independently, or delete a protected layer.
class CanvasInvalidOperationException extends CanvasException {
  /// Creates a new [CanvasInvalidOperationException].
  const CanvasInvalidOperationException(
    super.message, {
    super.stackTrace,
    super.objectId,
  });

  @override
  String toString() => 'CanvasInvalidOperationException: $message';
}