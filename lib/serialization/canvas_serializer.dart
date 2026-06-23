/// JSON serialization for the entire canvas state.
library;

import 'dart:convert';

import '../models/canvas_object.dart';
import '../viewport/canvas_viewport.dart';
import '../layers/layer_manager.dart';
import '../utils/grid_and_guides.dart';
import 'object_registry.dart';
import '../core/constants.dart';
import '../core/exceptions.dart';

/// Serializes and deserializes the complete canvas state to/from JSON.
///
/// The JSON format includes:
/// - Schema version for forward/backward compatibility
/// - Viewport state (offset, zoom, rotation)
/// - All objects (including nested groups)
/// - Layer configuration
/// - Grid configuration
class CanvasSerializer {
  /// The current serialization schema version.
  static const int currentSchemaVersion = CanvasConstants.schemaVersion;

  /// Serializes the entire canvas state to a JSON map.
  static Map<String, dynamic> serialize({
    required List<CanvasObject> objects,
    required CanvasViewport viewport,
    required LayerManager layerManager,
    required GridConfig gridConfig,
  }) {
    return {
      'schemaVersion': currentSchemaVersion,
      'version': CanvasConstants.version,
      'viewport': {
        'offsetX': viewport.offset.dx,
        'offsetY': viewport.offset.dy,
        'zoom': viewport.zoom,
        'rotation': viewport.rotation,
      },
      'grid': gridConfig.toJson(),
      'layers': layerManager.toJson(),
      'objects': objects.map((o) => o.toJson()).toList(),
    };
  }

  /// Serializes the canvas state to a JSON string.
  static String exportJson({
    required List<CanvasObject> objects,
    required CanvasViewport viewport,
    required LayerManager layerManager,
    required GridConfig gridConfig,
  }) {
    return const JsonEncoder.withIndent('  ').convert(serialize(
      objects: objects, viewport: viewport,
      layerManager: layerManager, gridConfig: gridConfig,
    ));
  }

  /// Deserializes a JSON map into canvas components.
  ///
  /// Returns a [SerializedCanvas] containing all the components needed
  /// to restore the canvas state.
  static SerializedCanvas deserialize(Map<String, dynamic> json) {
    final schemaVersion = json['schemaVersion'] as int? ?? 1;

    // Viewport
    final vp = json['viewport'] as Map<String, dynamic>? ?? {};
    final viewportData = ViewportData(
      offset: Offset(
        (vp['offsetX'] as num?)?.toDouble() ?? 0,
        (vp['offsetY'] as num?)?.toDouble() ?? 0,
      ),
      zoom: (vp['zoom'] as num?)?.toDouble() ?? 1.0,
      rotation: (vp['rotation'] as num?)?.toDouble() ?? 0.0,
    );

    // Grid
    final gridJson = json['grid'] as Map<String, dynamic>? ?? {};
    final gridConfig = GridConfig.fromJson(gridJson);

    // Layers
    final layersJson = json['layers'] as List<dynamic>? ?? [];

    // Objects
    final objectsJson = json['objects'] as List<dynamic>? ?? [];
    final objects = <CanvasObject>[];
    for (final objJson in objectsJson) {
      try {
        final obj = CanvasObjectRegistry.instance.fromJson(objJson as Map<String, dynamic>);
        objects.add(obj);
      } catch (e) {
        // Skip unrecognizable objects for forward compatibility
      }
    }

    return SerializedCanvas(
      schemaVersion: schemaVersion,
      viewportData: viewportData,
      gridConfig: gridConfig,
      layersJson: layersJson.cast<Map<String, dynamic>>(),
      objects: objects,
    );
  }

  /// Deserializes from a JSON string.
  static SerializedCanvas importJson(String jsonString) {
    try {
      final json = _parseJson(jsonString);
      return deserialize(json);
    } catch (e) {
      throw CanvasSerializationException('Failed to parse JSON: $e');
    }
  }
}

/// Holds deserialized canvas data.
class SerializedCanvas {
  final int schemaVersion;
  final ViewportData viewportData;
  final GridConfig gridConfig;
  final List<Map<String, dynamic>> layersJson;
  final List<CanvasObject> objects;

  SerializedCanvas({
    required this.schemaVersion,
    required this.viewportData,
    required this.gridConfig,
    required this.layersJson,
    required this.objects,
  });
}

/// Deserialized viewport data.
class ViewportData {
  final Offset offset;
  final double zoom;
  final double rotation;
  ViewportData({required this.offset, required this.zoom, required this.rotation});
}

Map<String, dynamic> _parseJson(String source) {
  return json.decode(source) as Map<String, dynamic>;
}