/// Registry for polymorphic canvas object serialization.
///
/// Maps type strings to factory constructors so that [CanvasObject.fromJson]
/// can deserialize any registered object type.
library;

import '../models/canvas_object.dart';
import '../models/shapes/canvas_rect.dart';
import '../models/shapes/canvas_circle.dart';
import '../models/shapes/canvas_line.dart';
import '../models/shapes/canvas_arrow.dart';
import '../models/shapes/canvas_text.dart';
import '../models/shapes/canvas_image.dart';
import '../models/shapes/canvas_path.dart';
import '../models/shapes/canvas_polygon.dart';
import '../models/shapes/canvas_sticky_note.dart';
import '../models/shapes/canvas_frame.dart';
import '../models/shapes/canvas_svg.dart';
import '../models/shapes/canvas_group.dart';
import '../core/typedefs.dart';

/// Singleton registry that maps type strings to factory functions.
///
/// Use this to register custom canvas object types for serialization.
/// All built-in types are registered by default.
///
/// Example:
/// ```dart
/// CanvasObjectRegistry.instance.register('my_custom_shape', (json) => MyCustomShape.fromJson(json));
/// ```
class CanvasObjectRegistry {
  CanvasObjectRegistry._();

  static final CanvasObjectRegistry instance = CanvasObjectRegistry._();

  final Map<String, CanvasObjectFactory> _factories = {};

  /// Registers a factory for the given [type] string.
  ///
  /// If a factory already exists for [type], it is replaced.
  void register(String type, CanvasObjectFactory factory) {
    _factories[type] = factory;
  }

  /// Unregisters the factory for the given [type] string.
  ///
  /// Returns `true` if a factory was found and removed.
  bool unregister(String type) => _factories.remove(type) != null;

  /// Returns the factory registered for [type], or `null` if not found.
  CanvasObjectFactory? getFactory(String type) => _factories[type];

  /// Returns `true` if a factory is registered for [type].
  bool isRegistered(String type) => _factories.containsKey(type);

  /// Returns all registered type strings.
  Iterable<String> get registeredTypes => _factories.keys;

  /// Deserializes a JSON map into a [CanvasObject] using the registered factory.
  ///
  /// Throws [CanvasSerializationException] if the type is not registered
  /// or if deserialization fails.
  CanvasObject fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    if (type == null) {
      throw ArgumentError('JSON object missing "type" field: $json');
    }
    final factory = _factories[type];
    if (factory == null) {
      throw ArgumentError('No factory registered for type "$type". '
          'Register your type with CanvasObjectRegistry.instance.register("$type", factory).');
    }
    return factory(json);
  }

  /// Registers all built-in canvas object types.
  void registerDefaults() {
    register('rect', (json) => CanvasRect.fromJson(json));
    register('circle', (json) => CanvasCircle.fromJson(json));
    register('line', (json) => CanvasLine.fromJson(json));
    register('arrow', (json) => CanvasArrow.fromJson(json));
    register('text', (json) => CanvasText.fromJson(json));
    register('image', (json) => CanvasImage.fromJson(json));
    register('path', (json) => CanvasPath.fromJson(json));
    register('polygon', (json) => CanvasPolygon.fromJson(json));
    register('sticky_note', (json) => CanvasStickyNote.fromJson(json));
    register('frame', (json) => CanvasFrame.fromJson(json));
    register('svg', (json) => CanvasSvg.fromJson(json));
    register('group', (json) => CanvasGroup.fromJson(json));
  }
}