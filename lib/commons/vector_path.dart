// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes
import 'dart:ui' as ui;

import 'package:flame/extensions.dart';
import 'package:flame_path_shapes/commons/vector_paint.dart';
import 'package:flutter/foundation.dart';

typedef VectorPathList = List<VectorPath>;

class VectorPath {
  VectorPath(
    this.path,
    this.paints, {
    this.clip = false,
    this.pathId,
    this.description,
  }) {
    _prepare();
  }

  void _prepare() {
    if (paints.isFull || paints.isFilled) {
      _analyze();
    } else if (paints.isStroked) {
      _strokePath = path;
    } else {
      assert(
        paints.isFilled || paints.isStroked,
        'VectorPath must have at least a stroke or a fill.',
      );
    }
  }

  static const ui.Offset _zero = .zero;
  void _analyze() {
    // Analyze the path to determine which open/closed contours it contains.
    final contours = path.contours;
    final totalLength = contours.contoursLength;
    debugPrint(
      'VectorPath $pathId: #${contours.length} contours, length: $totalLength',
    );
    for (final metric in contours) {
      final p = metric.extractPath(0, metric.length);
      if (metric.isClosed) {
        closed.add(p);
      } else {
        open.add(p);
      }
    }

    if (open.isNotEmpty) {
      // Create a path for the open contours.
      _strokePath = _addOpen();
    }

    if (closed.isNotEmpty) {
      // Create a path for the closed contours.
      _fillPath = _addClosed();

      // If we have both open and closed contours with corresponding
      // single countours, merge them accordingly.
      if (_strokePath != null) {
        if (open.length == 1) {
          _fillPath!.addPath(_strokePath!, VectorPath._zero);
        } else if (closed.length == 1) {
          _strokePath!.addPath(_fillPath!, VectorPath._zero);
        }
      }
    } else {
      // No closed contours, but we have open contours. If the paints
      // are not stroked, we keep only the fill path.
      if (!paints.isStroked && open.isNotEmpty) {
        _fillPath = _strokePath;
        _strokePath = null;
      }
    }
    assert(
      _fillPath != null || _strokePath != null,
      'VectorPath must have at least a stroke or a fill.',
    );
  }

  ui.Path _addOpen() {
    final result = ui.Path();
    result.fillType = path.fillType;
    for (final p in open) {
      result.addPath(p, ui.Offset.zero);
    }
    return result;
  }

  ui.Path _addClosed() {
    final result = ui.Path();
    result.fillType = path.fillType;
    for (final p in closed) {
      result.addPath(p, ui.Offset.zero);
    }
    return result;
  }

  void render(ui.Canvas canvas, VectorPaint? p) {
    final paints = p ?? this.paints;
    final fill = _fillPath;
    if (fill != null && paints.fill != null) {
      if (clip) {
        canvas.save();
        canvas.clipPath(fill);
        canvas.drawPaint(paints.fill!);
        canvas.restore();
      } else {
        canvas.drawPath(fill, paints.fill!);
      }
    }
    if (_strokePath != null && paints.stroke != null) {
      canvas.drawPath(_strokePath!, paints.stroke!);
    }
  }

  /// The default paints.
  VectorPaint paints;

  /// The original path.
  final ui.Path path;

  /// The stroked path (if any).
  ui.Path? get strokePath => _strokePath;

  /// The filled path (if any).
  ui.Path? get fillPath => _fillPath;

  /// The original path ID.
  final int? pathId;

  /// Whether we use clipping for rendering filled paths.
  bool clip = false;

  ui.Path? _strokePath;
  ui.Path? _fillPath;

  @internal
  List<ui.Path> open = [];
  @internal
  List<ui.Path> closed = [];

  StringBuffer? description;

  @override
  String toString() {
    var desc =
        'paints: $paints, open: ${open.length}, closed: ${closed.length}';
    desc = 'VectorPath($desc)';
    if (description != null) {
      desc += '\n${description!}';
    }
    return desc;
  }

  @override
  int get hashCode => Object.hash(paints, open.length, closed.length);

  @override
  bool operator ==(Object other) {
    if (other is VectorPath) {
      return paints == other.paints &&
          open.length == other.open.length &&
          closed.length == other.closed.length;
    }
    return false;
  }
}

extension VectorPathLength on VectorPathList {
  double get pathLength {
    return fold(0.0, (sum, path) => sum + path.path.contours.contoursLength);
  }
}
