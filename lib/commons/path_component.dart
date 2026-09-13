import 'dart:ui';

import 'package:flame/geometry.dart';

class PathComponent extends ShapeComponent {
  PathComponent({
    required this.path,
    super.position,
    super.size,
    super.scale,
    super.angle,
    super.anchor,
    super.children,
    super.priority,
    super.key,
    super.paint,
    super.paintLayers,
  });

  final Path path;

  @override
  void render(Canvas canvas) {
    if (renderShape) {
      if (hasPaintLayers) {
        for (final paint in paintLayers) {
          canvas.drawPath(path, paint);
        }
      } else {
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  void renderDebugMode(Canvas canvas) {
    super.renderDebugMode(canvas);
    canvas.drawPath(path, debugPaint);
  }
}
