/// Collaboration system interfaces for real-time multi-user editing.
///
/// This module defines the contracts for real-time collaboration features
/// including Operational Transform (OT), CRDT-based conflict resolution,
/// presence tracking, and cursor sharing.
///
/// Implementations can plug in different backends (WebSocket, WebRTC, etc.).
library;

import 'dart:async';
import '../models/canvas_object.dart';
import 'models/collaboration_event.dart';
import '../core/typedefs.dart';

/// Represents a remote user's presence on the canvas.
class RemoteUser {
  final String userId;
  String displayName;
  int colorValue;
  Offset? cursorPosition;
  Set<String> selectedObjectIds;
  DateTime lastSeen;

  RemoteUser({
    required this.userId,
    required this.displayName,
    required this.colorValue,
    this.cursorPosition,
    Set<String>? selectedObjectIds,
    DateTime? lastSeen,
  })  : selectedObjectIds = selectedObjectIds ?? {},
        lastSeen = lastSeen ?? DateTime.now();
}

/// Interface for sending and receiving collaboration messages.
///
/// Implement this to connect the canvas to a real-time backend.
abstract class CollaborationTransport {
  /// Connects to the collaboration server.
  Future<void> connect(String sessionId, String userId);

  /// Disconnects from the server.
  Future<void> disconnect();

  /// Sends a local change to other users.
  Future<void> sendChange(Map<String, dynamic> change);

  /// Sends a cursor position update.
  Future<void> sendCursorMove(Offset position);

  /// Sends a selection change.
  Future<void> sendSelectionChange(Set<String> objectIds);

  /// Stream of incoming events from remote users.
  Stream<CollaborationEvent> get events;

  /// Connection state.
  Stream<bool> get connectionState;

  /// Whether currently connected.
  bool get isConnected;
}

/// Interface for Operational Transform (OT) based conflict resolution.
///
/// OT transforms concurrent edits so they converge to the same state.
abstract class OperationalTransformEngine {
  /// Transforms a local operation against a remote operation.
  Map<String, dynamic> transformLocal(
    Map<String, dynamic> localOp,
    Map<String, dynamic> remoteOp,
  );

  /// Transforms a remote operation against a local operation.
  Map<String, dynamic> transformRemote(
    Map<String, dynamic> remoteOp,
    Map<String, dynamic> localOp,
  );

  /// The current revision number.
  int get revision;
}

/// Interface for CRDT-based conflict resolution.
///
/// CRDTs guarantee eventual consistency without a central server.
abstract class CrdtEngine {
  /// Merges a remote state update into the local state.
  void merge(Map<String, dynamic> remoteUpdate);

  /// Generates a local state update to send to remote peers.
  Map<String, dynamic> generateUpdate();

  /// Returns the current CRDT state for persistence.
  Map<String, dynamic> get state;
}

/// Manages collaboration state: presence, cursors, conflict resolution.
class CollaborationManager with ChangeNotifier {
  final CollaborationTransport transport;
  final OperationalTransformEngine? otEngine;
  final CrdtEngine? crdtEngine;

  final Map<String, RemoteUser> _remoteUsers = {};
  final List<CanvasCollaborationCallback> _eventCallbacks = [];

  String? _sessionId;
  String? _localUserId;
  bool _isConnected = false;

  CollaborationManager({
    required this.transport,
    this.otEngine,
    this.crdtEngine,
  }) {
    transport.events.listen(_handleRemoteEvent);
    transport.connectionState.listen((connected) {
      _isConnected = connected;
      notifyListeners();
    });
  }

  bool get isConnected => _isConnected;
  String? get sessionId => _sessionId;
  String? get localUserId => _localUserId;
  Map<String, RemoteUser> get remoteUsers => Map.unmodifiable(_remoteUsers);

  /// Joins a collaborative session.
  Future<void> join(String sessionId, String userId, {String displayName = 'User'}) async {
    _sessionId = sessionId;
    _localUserId = userId;
    await transport.connect(sessionId, userId);
  }

  /// Leaves the collaborative session.
  Future<void> leave() async {
    await transport.disconnect();
    _remoteUsers.clear();
    _sessionId = null;
    _localUserId = null;
    notifyListeners();
  }

  /// Broadcasts an object change to all collaborators.
  Future<void> broadcastChange(Map<String, dynamic> change) async {
    if (!_isConnected) return;
    await transport.sendChange(change);
  }

  /// Broadcasts cursor position.
  Future<void> broadcastCursor(Offset position) async {
    if (!_isConnected) return;
    await transport.sendCursorMove(position);
  }

  /// Broadcasts selection change.
  Future<void> broadcastSelection(Set<String> objectIds) async {
    if (!_isConnected) return;
    await transport.sendSelectionChange(objectIds);
  }

  void addEventCallback(CanvasCollaborationCallback callback) => _eventCallbacks.add(callback);
  void removeEventCallback(CanvasCollaborationCallback callback) => _eventCallbacks.remove(callback);

  void _handleRemoteEvent(CollaborationEvent event) {
    // Update presence
    if (event is PresenceUpdateEvent) {
      final user = RemoteUser(
        userId: event.userId, displayName: event.displayName,
        colorValue: event.colorValue,
      );
      _remoteUsers[event.userId] = user;
      if (event.state == 'offline') {
        _remoteUsers.remove(event.userId);
      }
    }
    // Update cursor
    if (event is CursorMoveEvent) {
      _remoteUsers[event.userId]?.cursorPosition = event.position;
    }
    // Update selection
    if (event is SelectionChangeEvent) {
      _remoteUsers[event.userId]?.selectedObjectIds = event.selectedObjectIds.toSet();
    }
    notifyListeners();
    for (final cb in _eventCallbacks) cb(event);
  }
}

/// Mock transport for testing and offline mode.
class MockCollaborationTransport implements CollaborationTransport {
  final StreamController<CollaborationEvent> _eventController = StreamController.broadcast();
  final StreamController<bool> _stateController = StreamController.broadcast();
  bool _connected = false;

  @override
  bool get isConnected => _connected;

  @override
  Stream<CollaborationEvent> get events => _eventController.stream;

  @override
  Stream<bool> get connectionState => _stateController.stream;

  @override
  Future<void> connect(String sessionId, String userId) async {
    _connected = true;
    _stateController.add(true);
  }

  @override
  Future<void> disconnect() async {
    _connected = false;
    _stateController.add(false);
  }

  @override
  Future<void> sendChange(Map<String, dynamic> change) async {}

  @override
  Future<void> sendCursorMove(Offset position) async {}

  @override
  Future<void> sendSelectionChange(Set<String> objectIds) async {}

  /// Simulates receiving a remote event (for testing).
  void simulateEvent(CollaborationEvent event) {
    _eventController.add(event);
  }
}

/// Mock OT engine for testing.
class MockOperationalTransformEngine implements OperationalTransformEngine {
  int _revision = 0;

  @override
  int get revision => _revision;

  @override
  Map<String, dynamic> transformLocal(Map<String, dynamic> localOp, Map<String, dynamic> remoteOp) {
    _revision++;
    return localOp;
  }

  @override
  Map<String, dynamic> transformRemote(Map<String, dynamic> remoteOp, Map<String, dynamic> localOp) {
    _revision++;
    return remoteOp;
  }
}