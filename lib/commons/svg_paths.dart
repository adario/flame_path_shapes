import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/cache.dart';
import 'package:flame/extensions.dart';
import 'package:flame/flame.dart';
import 'package:flame_path_shapes/commons/vector_paint.dart';
import 'package:flame_path_shapes/commons/vector_graphics_extensions.dart';
import 'package:flame_path_shapes/commons/vector_path.dart';
import 'package:flutter/foundation.dart';
import 'package:vector_graphics_compiler/vector_graphics_compiler.dart';

typedef VectorPaintList = List<VectorPaint>;
typedef VectorPaintMap = Map<int, VectorPaint>;
typedef VectorPathMap = Map<int, VectorPath>;

class SvgPaths {
  SvgPaths(String svg) {
    _importSvg(svg);
  }

  static Future<SvgPaths> fromFile(
    String fileName, {
    AssetsCache? cache,
  }) async {
    final assets = cache ?? Flame.assets;
    final svg = await assets.readFile(fileName);
    assert(svg.isNotEmpty, 'SVG file not found: $fileName');
    debugPrint('SVG file = $fileName');
    return SvgPaths(svg);
  }

  VectorPath? pathAt(int index) {
    final validIndex = index >= 0 && index < _paths.length;
    assert(validIndex, 'Invalid vector path index $index');
    return validIndex ? _paths[index] : null;
  }

  VectorPaint? paintsAt(int index) {
    final validIndex = index >= 0 && index < _paints.length;
    assert(validIndex, 'Invalid paints index $index');
    return validIndex ? _paints[index] : null;
  }

  double get width => _instructions.width;
  double get height => _instructions.height;

  /// The original bounds for all paths.
  ui.Rect get bounds => _bounds;

  late ui.Rect _bounds;

  /// Renders the svg on the [canvas] using the dimensions provided by [size].
  void render(ui.Canvas canvas, Vector2 size, {ui.Paint? overridePaint}) {
    final localSize = Size(size.x, size.y);

    canvas.save();

    final scale = math.min(localSize.width / width, localSize.height / height);
    canvas.translate(
      (localSize.width - width * scale) * 0.5,
      (localSize.height - height * scale) * 0.5,
    );
    canvas.scale(scale);

    _render(canvas, overridePaint);

    canvas.restore();
  }

  /// Renders the svg on the [canvas] on the given [position] using the
  /// dimensions provided by [size].
  void renderPosition(ui.Canvas canvas, Vector2 position, Vector2 size) {
    canvas.renderAt(position, (c) => render(c, size));
  }

  void _render(ui.Canvas canvas, ui.Paint? overridePaint) {
    final paints = _paints;
    assert(paints.length == _paths.length, 'Paints length mismatch');
    for (var i = 0; i < _paths.length; i++) {
      _paths[i].render(canvas, paints[i]);
    }
  }

  // MARK: - Private methods

  void _importSvg(String svg) {
    try {
      _instructions = parseWithoutOptimizers(svg);
      debugPrint(
        // ignore: lines_longer_than_80_chars
        'SVG vector = $_instructions, paints #${_instructions.paints.length} paths #${_instructions.paths.length} commands #${_instructions.commands.length} vertices # ${_instructions.vertices}',
      );
    } on Exception catch (err) {
      debugPrint('!!! SVG error: $err');
      return;
    }

    _bounds = _computeBounds();
    debugPrint('SVG bounds @ ${_bounds.center} -> $_bounds');

    _importObjects();
  }

  void _importObjects() {
    final paints = VectorPaintMap();
    final paths = VectorPathMap();

    for (final c in _instructions.commands) {
      if (c.type != .path) {
        debugPrint('SVG skipping draw command = $c');
        continue;
      }

      final paintId = c.paintId;
      VectorPaint? paint;
      if (paintId != null) {
        paint = paints[paintId] ?? _instructions.paints[paintId].toVectorPaint();
        paints[paintId] = paint;
        _paints.add(paint);
      }

      final pathId = c.objectId;
      if (pathId != null) {
        final path =
            paths[pathId] ??
            _instructions.paths[pathId].toVectorPath(
              paint!,
              pathId: pathId,
              description: StringBuffer(),
            );
        paths[pathId] = path;
        _paths.add(path);
      }
    }
    assert(_paints.length == _paths.length, 'Paints/Paths length mismatch');
    _merge(paths, paints);
  }

  static const Offset _zero = .zero;
  void _merge(VectorPathMap paths, VectorPaintMap paints) {
    if (paths.length <= 1 || paints.length != 1) {
      return;
    }
    _paths.clear();
    _paints.clear();

    final paint = paints.values.first;
    final merged = ui.Path();
    for (final path in paths.values) {
      merged.addPath(path.path, SvgPaths._zero);
    }
    _paths.add(
      VectorPath(
        merged,
        paint,
        pathId: paths.length,
        description: StringBuffer(),
      ),
    );
    _paints.add(paint);
    debugPrint('SVG unified paths = ${paths.length}');
  }

  ui.Rect _computeBounds() {
    var bounds = ui.Rect.zero;
    for (final path in _instructions.paths) {
      final x = path.bounds();
      final t = ui.Rect.fromLTRB(x.left, x.top, x.right, x.bottom);
      bounds = bounds.expandToInclude(t);
    }
    return bounds;
  }

  late final VectorInstructions _instructions;
  late final VectorPathList _paths = [];
  late final VectorPaintList _paints = [];
}
