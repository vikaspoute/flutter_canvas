/// Models for the collaboration system.
library;

import 'dart:ui';

/// Represents a single event in a collaborative session.
///
/// This is the base class for all collaboration events. Concrete subclasses
/// represent specific actions like cursor movement, object changes, and
/// presence updates.
sealed class CollaborationEvent {
  /// Unique identifier for this event.
  final String eventId;

  /// ID of the user who initiated this event.
  final String userId;

  /// Timestamp when the event was created (milliseconds since epoch).
  final int timestamp;

  /// Creates a new [CollaborationEvent].
  const CollaborationEvent({
    required this.eventId,
    required this.userId,
    required this.timestamp,
  });

  /// Serializes this event to a JSON map.
  Map<String, dynamic> toJson();

  /// Creates an event from a JSON map.
  static CollaborationEvent fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    switch (type) {
      case 'cursor_move':
        return CursorMoveEvent.fromJson(json);
      case 'selection_change':
        return SelectionChangeEvent.fromJson(json);
      case 'object_change':
        return ObjectChangeEvent.fromJson(json);
      case 'presence_update':
        return PresenceUpdateEvent.fromJson(json);
      default:
        return GenericCollaborationEvent.fromJson(json);
    }
  }
}

/// Event emitted when a remote user moves their cursor.
class CursorMoveEvent extends CollaborationEvent {
  /// Current cursor position in world coordinates.
  final Offset position;

  /// Creates a new [CursorMoveEvent].
  const CursorMoveEvent({
    required super.eventId,
    required super.userId,
    required super.timestamp,
    required this.position,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'cursor_move',
        'eventId': eventId,
        'userId': userId,
        'timestamp': timestamp,
        'x': position.dx,
        'y': position.dy,
      };

  /// Creates a [CursorMoveEvent] from JSON.
  static CursorMoveEvent fromJson(Map<String, dynamic> json) {
    return CursorMoveEvent(
      eventId: json['eventId'] as String,
      userId: json['userId'] as String,
      timestamp: json['timestamp'] as int,
      position: Offset(
        (json['x'] as num).toDouble(),
        (json['y'] as num).toDouble(),
      ),
    );
  }
}

/// Event emitted when a remote user changes their selection.
class SelectionChangeEvent extends CollaborationEvent {
  /// IDs of the objects now selected by the remote user.
  final List<String> selectedObjectIds;

  /// Creates a new [SelectionChangeEvent].
  const SelectionChangeEvent({
    required super.eventId,
    required super.userId,
    required super.timestamp,
    required this.selectedObjectIds,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'selection_change',
        'eventId': eventId,
        'userId': userId,
        'timestamp': timestamp,
        'selectedObjectIds': selectedObjectIds,
      };

  /// Creates a [SelectionChangeEvent] from JSON.
  static SelectionChangeEvent fromJson(Map<String, dynamic> json) {
    return SelectionChangeEvent(
      eventId: json['eventId'] as String,
      userId: json['userId'] as String,
      timestamp: json['timestamp'] as int,
      selectedObjectIds: List<String>.from(json['selectedObjectIds'] as List),
    );
  }
}

/// Event emitted when a remote user modifies a canvas object.
class ObjectChangeEvent extends CollaborationEvent {
  /// ID of the modified object.
  final String objectId;

  /// The type of modification.
  final String changeType;

  /// JSON-serialized delta describing the change.
  final Map<String, dynamic> delta;

  /// Creates a new [ObjectChangeEvent].
  const ObjectChangeEvent({
    required super.eventId,
    required super.userId,
    required super.timestamp,
    required this.objectId,
    required this.changeType,
    required this.delta,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'object_change',
        'eventId': eventId,
        'userId': userId,
        'timestamp': timestamp,
        'objectId': objectId,
        'changeType': changeType,
        'delta': delta,
      };

  /// Creates an [ObjectChangeEvent] from JSON.
  static ObjectChangeEvent fromJson(Map<String, dynamic> json) {
    return ObjectChangeEvent(
      eventId: json['eventId'] as String,
      userId: json['userId'] as String,
      timestamp: json['timestamp'] as int,
      objectId: json['objectId'] as String,
      changeType: json['changeType'] as String,
      delta: Map<String, dynamic>.from(json['delta'] as Map),
    );
  }
}

/// Event emitted when a user's presence state changes (join, leave, idle).
class PresenceUpdateEvent extends CollaborationEvent {
  /// The user's display name.
  final String displayName;

  /// The user's chosen color for their cursor and selection.
  final int colorValue;

  /// The user's current state (active, idle, offline).
  final String state;

  /// Creates a new [PresenceUpdateEvent].
  const PresenceUpdateEvent({
    required super.eventId,
    required super.userId,
    required super.timestamp,
    required this.displayName,
    required this.colorValue,
    required this.state,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'presence_update',
        'eventId': eventId,
        'userId': userId,
        'timestamp': timestamp,
        'displayName': displayName,
        'colorValue': colorValue,
        'state': state,
      };

  /// Creates a [PresenceUpdateEvent] from JSON.
  static PresenceUpdateEvent fromJson(Map<String, dynamic> json) {
    return PresenceUpdateEvent(
      eventId: json['eventId'] as String,
      userId: json['userId'] as String,
      timestamp: json['timestamp'] as int,
      displayName: json['displayName'] as String,
      colorValue: json['colorValue'] as int,
      state: json['state'] as String,
    );
  }
}

/// A generic collaboration event for unknown or extension event types.
class GenericCollaborationEvent extends CollaborationEvent {
  /// The raw event type string.
  final String eventType;

  /// Additional payload data.
  final Map<String, dynamic> payload;

  /// Creates a new [GenericCollaborationEvent].
  const GenericCollaborationEvent({
    required super.eventId,
    required super.userId,
    required super.timestamp,
    required this.eventType,
    this.payload = const {},
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': eventType,
        'eventId': eventId,
        'userId': userId,
        'timestamp': timestamp,
        ...payload,
      };

  /// Creates a [GenericCollaborationEvent] from JSON.
  static GenericCollaborationEvent fromJson(Map<String, dynamic> json) {
    final payload = Map<String, dynamic>.from(json);
    payload.remove('type');
    payload.remove('eventId');
    payload.remove('userId');
    payload.remove('timestamp');
    return GenericCollaborationEvent(
      eventId: json['eventId'] as String,
      userId: json['userId'] as String,
      timestamp: json['timestamp'] as int,
      eventType: json['type'] as String? ?? 'unknown',
      payload: payload,
    );
  }
}