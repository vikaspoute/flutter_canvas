/// Utility functions for geometric transformations.
library;

import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;

/// Provides static methods for building and manipulating transformation matrices.
///
/// This utility class centralizes all matrix operations used by the canvas
/// engine, ensuring consistency between the viewport, renderer, and object
/// transforms.
class TransformUtils {
  TransformUtils._();

  /// Builds a [Matrix4] from position, rotation, and scale.
  ///
  /// The matrix represents the transformation:
  /// 1. Scale by [scale]
  /// 2. Rotate by [rotation] radians
  /// 3. Translate by [position]
  static Matrix4 buildMatrix({
    required Offset position,
    required double rotation,
    required Offset scale,
    Offset? pivot,
  }) {
    final matrix = Matrix4.identity();
    if (pivot != null) {
      matrix.translate(pivot.dx, pivot.dy);
    }
    matrix.translate(position.dx, position.dy);
    matrix.rotateZ(rotation);
    matrix.scale(scale.dx, scale.dy);
    if (pivot != null) {
      matrix.translate(-pivot.dx, -pivot.dy);
    }
    return matrix;
  }

  /// Builds a [Matrix4] suitable for a viewport camera.
  ///
  /// This composes:
  /// 1. Translate by [-offset] (pan)
  /// 2. Scale by [zoom] (zoom)
  /// 3. Translate by [-canvasSize / 2] to center the origin
  static Matrix4 buildViewportMatrix({
    required Offset offset,
    required double zoom,
    required Size canvasSize,
  }) {
    final matrix = Matrix4.identity();
    matrix.translate(canvasSize.width / 2, canvasSize.height / 2);
    matrix.scale(zoom, zoom);
    matrix.translate(-offset.dx, -offset.dy);
    return matrix;
  }

  /// Transforms a [Rect] by a [Matrix4] and returns the axis-aligned
  /// bounding box of the transformed rectangle.
  static Rect transformRect(Matrix4 matrix, Rect rect) {
    final corners = <Offset>[
      Offset(rect.left, rect.top),
      Offset(rect.right, rect.top),
      Offset(rect.right, rect.bottom),
      Offset(rect.left, rect.bottom),
    ];
    final transformed = corners.map((c) => transformPoint(matrix, c)).toList();
    return Rect.fromLTRB(
      transformed.map((c) => c.dx).reduce(math.min),
      transformed.map((c) => c.dy).reduce(math.min),
      transformed.map((c) => c.dx).reduce(math.max),
      transformed.map((c) => c.dy).reduce(math.max),
    );
  }

  /// Transforms a single [Offset] point by a [Matrix4].
  static Offset transformPoint(Matrix4 matrix, Offset point) {
    final v = matrix.transform3(Vector3(point.dx, point.dy, 0));
    return Offset(v.x, v.y);
  }

  /// Returns the inverse of [matrix], or the identity matrix if the
  /// matrix is not invertible.
  static Matrix4 safeInvert(Matrix4 matrix) {
    final inverse = Matrix4.copy(matrix);
    final success = inverse.invert();
    if (!success) {
      return Matrix4.identity();
    }
    return inverse;
  }

  /// Converts a point from screen coordinates to world coordinates.
  static Offset screenToWorld(Matrix4 viewportMatrix, Offset screenPoint, Size canvasSize) {
    final inverse = safeInvert(viewportMatrix);
    // Adjust for the canvas widget's position offset
    return transformPoint(inverse, screenPoint);
  }

  /// Converts a point from world coordinates to screen coordinates.
  static Offset worldToScreen(Matrix4 viewportMatrix, Offset worldPoint) {
    return transformPoint(viewportMatrix, worldPoint);
  }

  /// Decomposes a [Matrix4] into translation, rotation, and scale.
  ///
  /// Returns a record with the decomposed values.
  static ({
    Offset translation,
    double rotation,
    Offset scale,
  }) decompose(Matrix4 matrix) {
    final sx = math.sqrt(
      matrix.storage[0] * matrix.storage[0] +
          matrix.storage[1] * matrix.storage[1],
    );
    final sy = math.sqrt(
      matrix.storage[4] * matrix.storage[4] +
          matrix.storage[5] * matrix.storage[5],
    );
    final rotation = math.atan2(matrix.storage[1], matrix.storage[0]);
    return (
      translation: Offset(matrix.storage[12], matrix.storage[13]),
      rotation: rotation,
      scale: Offset(sx, sy),
    );
  }

  /// Applies a flip horizontally around a vertical axis at [centerX].
  static Matrix4 flipHorizontal(double centerX) {
    final matrix = Matrix4.identity();
    matrix.translate(centerX, 0);
    matrix.scale(-1, 1);
    matrix.translate(-centerX, 0);
    return matrix;
  }

  /// Applies a flip vertically around a horizontal axis at [centerY].
  static Matrix4 flipVertical(double centerY) {
    final matrix = Matrix4.identity();
    matrix.translate(0, centerY);
    matrix.scale(1, -1);
    matrix.translate(0, -centerY);
    return matrix;
  }

  /// Creates a rotation matrix around a given [center] point.
  static Matrix4 rotateAround(Offset center, double angle) {
    final matrix = Matrix4.identity();
    matrix.translate(center.dx, center.dy);
    matrix.rotateZ(angle);
    matrix.translate(-center.dx, -center.dy);
    return matrix;
  }
}