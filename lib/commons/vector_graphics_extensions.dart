import 'dart:ui' as ui;

import 'package:flame_path_shapes/commons/vector_paint.dart';
import 'package:flame_path_shapes/commons/vector_path.dart';
import 'package:vector_graphics_compiler/vector_graphics_compiler.dart';

extension BlendModeConverter on BlendMode {
  ui.BlendMode toUiBlendMode() {
    switch (this) {
      case .clear:
        return .clear;
      case .color:
        return .color;
      case .colorBurn:
        return .colorBurn;
      case .colorDodge:
        return .colorDodge;
      case .darken:
        return .darken;
      case .difference:
        return .difference;
      case .dst:
        return .dst;
      case .dstATop:
        return .dstATop;
      case .dstIn:
        return .dstIn;
      case .dstOut:
        return .dstOut;
      case .dstOver:
        return .dstOver;
      case .exclusion:
        return .exclusion;
      case .hardLight:
        return .hardLight;
      case .hue:
        return .hue;
      case .lighten:
        return .lighten;
      case .luminosity:
        return .luminosity;
      case .modulate:
        return .modulate;
      case .multiply:
        return .multiply;
      case .overlay:
        return .overlay;
      case .plus:
        return .plus;
      case .saturation:
        return .saturation;
      case .screen:
        return .screen;
      case .softLight:
        return .softLight;
      case .src:
        return .src;
      case .srcATop:
        return .srcATop;
      case .srcIn:
        return .srcIn;
      case .srcOut:
        return .srcOut;
      case .srcOver:
        return .srcOver;
      case .xor:
        return .xor;
    }
  }
}

extension StrokeCapConverter on StrokeCap {
  ui.StrokeCap toUiStrokeCap() {
    switch (this) {
      case .butt:
        return .butt;
      case .round:
        return .round;
      case .square:
        return .square;
    }
  }
}

extension StrokeJoinConverter on StrokeJoin {
  ui.StrokeJoin toUiStrokeJoin() {
    switch (this) {
      case .miter:
        return .miter;
      case .round:
        return .round;
      case .bevel:
        return .bevel;
    }
  }
}

extension PaintConverter on Paint {
  VectorPaint toVectorPaint() {
    return VectorPaint(stroke: toStrokedUiPaint(), fill: toFilledUiPaint());
  }

  ui.Paint? toStrokedUiPaint() {
    final s = stroke;
    if (s == null || s.width == null || s.width! <= 0) {
      return null;
    }
    final p = ui.Paint();
    p.style = .stroke;
    p.blendMode = blendMode.toUiBlendMode();
    p.strokeWidth = s.width ?? p.strokeWidth;
    p.strokeMiterLimit = s.miterLimit ?? p.strokeMiterLimit;
    p.color = ui.Color(s.color.value);
    final c = s.cap;
    if (c != null) {
      p.strokeCap = c.toUiStrokeCap();
    }
    final j = s.join;
    if (j != null) {
      p.strokeJoin = j.toUiStrokeJoin();
    }
    return p;
  }

  ui.Paint? toFilledUiPaint() {
    final f = fill;
    if (f == null) {
      return null;
    }
    final p = ui.Paint();
    p.style = .fill;
    p.blendMode = blendMode.toUiBlendMode();
    p.color = ui.Color(f.color.value);
    return p;
  }
}

extension PathConverter on Path {
  VectorPath toVectorPath(
    VectorPaint paints, {
    bool clip = false,
    int? pathId,
    StringBuffer? description,
  }) {
    return VectorPath(
      toUiPath(description),
      paints,
      clip: clip,
      pathId: pathId,
      description: description,
    );
  }

  ui.Path toUiPath([StringBuffer? description]) {
    description?.writeln('  path');
    final p = ui.Path();
    switch (fillType) {
      case .nonZero:
        p.fillType = .nonZero;
      case .evenOdd:
        p.fillType = .evenOdd;
    }
    for (final c in commands) {
      if (c is MoveToCommand) {
        p.moveTo(c.x, c.y);
        description?.writeln('    ..moveTo(${c.x}, ${c.y})');
      } else if (c is LineToCommand) {
        p.lineTo(c.x, c.y);
        description?.writeln('    ..lineTo(${c.x}, ${c.y})');
      } else if (c is CubicToCommand) {
        p.cubicTo(c.x1, c.y1, c.x2, c.y2, c.x3, c.y3);
        description?.writeln(
          '    ..cubicTo(${c.x1}, ${c.y1}, ${c.x2}, ${c.y2}, ${c.x3}, ${c.y3})',
        );
      } else if (c is CloseCommand) {
        p.close();
        description?.writeln('    ..close()');
      }
    }
    return p;
  }
}
