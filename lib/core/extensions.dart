/// Extension methods on common Dart/Flutter types used throughout
/// the canvas engine.
library;

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';

// ─── Offset Extensions ────────────────────────────────────────────────────────

/// Extension methods on [Offset] for geometric operations.
extension OffsetExtension on Offset {
  /// Converts this offset to a [Point].
  Point<double> toPoint() => Point<double>(dx, dy);

  /// Returns the Euclidean distance to [other].
  double distanceTo(Offset other) {
    final dx = this.dx - other.dx;
    final dy = this.dy - other.dy;
    return math.sqrt(dx * dx + dy * dy);
  }

  /// Returns the angle in radians from this offset to [other],
  /// measured counter-clockwise from the positive x-axis.
  double angleTo(Offset other) {
    return math.atan2(other.dy - dy, other.dx - dx);
  }

  /// Linearly interpolates between this offset and [other] by [t].
  ///
  /// [t] is clamped to the range [0.0, 1.0].
  Offset lerpTo(Offset other, double t) {
    return Offset.lerp(this, other, t.clamp(0.0, 1.0))!;
  }

  /// Rotates this offset around the origin by [angle] radians.
  Offset rotate(double angle) {
    final cosA = math.cos(angle);
    final sinA = math.sin(angle);
    return Offset(dx * cosA - dy * sinA, dx * sinA + dy * cosA);
  }

  /// Scales this offset by [sx] horizontally and optionally [sy] vertically.
  /// If [sy] is null, [sx] is used for both axes.
  Offset scale(double sx, [double? sy]) {
    return Offset(dx * sx, dy * (sy ?? sx));
  }

  /// Converts this offset to a [Vector2].
  Vector2 toVector2() => Vector2(dx, dy);

  /// Returns the Manhattan (L1) distance to [other].
  int manhattanDistanceTo(Offset other) {
    return (dx - other.dx).abs().round() + (dy - other.dy).abs().round();
  }
}

// ─── Rect Extensions ──────────────────────────────────────────────────────────

/// Extension methods on [Rect] for advanced geometric operations.
extension RectExtension on Rect {
  /// Returns the smallest [Rect] that contains both this rect and [point].
  Rect expandToInclude(Offset point) {
    if (isEmpty) {
      return Rect.fromPoints(point, point);
    }
    return Rect.fromLTRB(
      math.min(left, point.dx),
      math.min(top, point.dy),
      math.max(right, point.dx),
      math.max(bottom, point.dy),
    );
  }

  /// Scales this rect around [center] by [scale] factor.
  ///
  /// Returns a new rect that has been uniformly scaled, maintaining the
  /// same center point.
  Rect scaleAround(Offset center, double scale) {
    final newLeft = center.dx + (left - center.dx) * scale;
    final newTop = center.dy + (top - center.dy) * scale;
    final newRight = center.dx + (right - center.dx) * scale;
    final newBottom = center.dy + (bottom - center.dy) * scale;
    return Rect.fromLTRB(newLeft, newTop, newRight, newBottom);
  }

  /// Rotates the four corners of this rect around [center] by [angle]
  /// radians and returns the axis-aligned bounding box of the result.
  Rect rotateAround(Offset center, double angle) {
    final corners = <Offset>[
      Offset(left, top).rotateAround(center, angle),
      Offset(right, top).rotateAround(center, angle),
      Offset(right, bottom).rotateAround(center, angle),
      Offset(left, bottom).rotateAround(center, angle),
    ];
    return Rect.fromLTRB(
      corners.map((c) => c.dx).reduce(math.min),
      corners.map((c) => c.dy).reduce(math.min),
      corners.map((c) => c.dx).reduce(math.max),
      corners.map((c) => c.dy).reduce(math.max),
    );
  }

  /// Converts this rect to a serializable map.
  Map<String, double> toMap() => {
        'left': left,
        'top': top,
        'right': right,
        'bottom': bottom,
      };

  /// Creates a [Rect] from a map produced by [toMap].
  static Rect fromMap(Map<String, double> map) => Rect.fromLTRB(
        map['left']!,
        map['top']!,
        map['right']!,
        map['bottom']!,
      );

  /// Returns `true` if this rect fully contains [other].
  ///
  /// Unlike [contains], which checks a point, this checks containment
  /// of an entire rectangle.
  bool containsRect(Rect other) {
    return left <= other.left &&
        top <= other.top &&
        right >= other.right &&
        bottom >= other.bottom;
  }

  /// Returns `true` if this rect overlaps with [other] by any amount.
  ///
  /// This uses strict overlap (touching edges do not count).
  bool overlapsRect(Rect other) {
    return left < other.right &&
        right > other.left &&
        top < other.bottom &&
        bottom > other.top;
  }
}

// ─── Matrix4 Extensions ───────────────────────────────────────────────────────

/// Extension methods on [Matrix4] for decomposition and inspection.
extension Matrix4Extension on Matrix4 {
  /// Returns `true` if this matrix is approximately the identity matrix.
  bool get isIdentity {
    const epsilon = 1e-10;
    for (var i = 0; i < 16; i++) {
      final expected = i % 5 == 0 ? 1.0 : 0.0;
      if ((storage[i] - expected).abs() > epsilon) return false;
    }
    return true;
  }

  /// Decomposes this transform matrix into its constituent parts.
  ///
  /// Returns a record with translation, rotation (in radians),
  /// scale, and skew values.
  ({
    Offset translation,
    double rotation,
    Offset scale,
    double skewX,
    double skewY,
  }) decompose() {
    final sx = math.sqrt(storage[0] * storage[0] + storage[1] * storage[1]);
    final sy = math.sqrt(storage[4] * storage[4] + storage[5] * storage[5]);

    double rotation = 0;
    double skewX = 0;
    double skewY = 0;

    if (sx.abs() > 1e-10 && sy.abs() > 1e-10) {
      rotation = math.atan2(storage[1], storage[0]);
      skewX = math.atan2(-storage[2] * sx, sy);
      skewY = math.atan2(-storage[4] * sy, sx);
    }

    return (
      translation: Offset(storage[12], storage[13]),
      rotation: rotation,
      scale: Offset(sx, sy),
      skewX: skewX,
      skewY: skewY,
    );
  }
}

// ─── Color Extensions ─────────────────────────────────────────────────────────

/// Extension methods on [Color] for serialization and interpolation.
extension ColorExtension on Color {
  /// Converts this color to a hex string (e.g., `#FF5722`).
  ///
  /// Always returns a 7-character string including the leading `#`.
  String toHex() {
    return '#${alpha.toRadixString(16).padLeft(2, '0')}'
        '${red.toRadixString(16).padLeft(2, '0')}'
        '${green.toRadixString(16).padLeft(2, '0')}'
        '${blue.toRadixString(16).padLeft(2, '0')}';
  }

  /// Converts this color to an `rgba(r, g, b, a)` CSS-style string.
  String toRgbaString() {
    return 'rgba($red, $green, $blue, ${opacity.toStringAsFixed(2)})';
  }

  /// Linearly interpolates between this color and [other] by [t].
  ///
  /// [t] is clamped to the range [0.0, 1.0].
  Color lerpTo(Color other, double t) {
    return Color.lerp(this, other, t.clamp(0.0, 1.0))!;
  }
}

// ─── Private helper: rotate an Offset around a center point ───────────────────

/// Rotates [point] around [center] by [angle] radians.
extension _OffsetRotationExtension on Offset {
  Offset rotateAround(Offset center, double angle) {
    final translated = this - center;
    return translated.rotate(angle) + center;
  }
}