import 'dart:ui' as ui;

class VectorPaint {
  late final ui.Paint? fill;
  late final ui.Paint? stroke;

  VectorPaint({this.fill, this.stroke});
  VectorPaint.layers(List<ui.Paint> paints) {
    fill = paints.isNotEmpty ? paints.first : null;
    stroke = paints.length > 1 ? paints[1] : null;
  }

  ui.Paint? get paint => fill ?? stroke;
  List<ui.Paint>? get paintLayers {
    final paints = <ui.Paint>[];
    if (fill != null) {
      paints.add(fill!);
    }
    if (stroke != null) {
      paints.add(stroke!);
    }
    return paints.isNotEmpty ? paints : null;
  }

  bool get isStroked => stroke != null;
  bool get isFilled => fill != null;
  bool get isFull => isStroked && isFilled;

  @override
  String toString() {
    var result = 'VectorPaint(';
    if (fill != null) {
      result += 'fill: $fill';
    }
    if (stroke != null) {
      if (fill != null) {
        result += ', ';
      }
      result += 'stroke: $stroke';
    }
    return '$result)';
  }

  @override
  int get hashCode => Object.hash(fill, stroke);

  @override
  bool operator ==(Object other) {
    if (other is VectorPaint) {
      return fill == other.fill && stroke == other.stroke;
    }
    return false;
  }
}
