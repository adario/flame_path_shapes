import 'dart:async';
import 'dart:ui';

import 'package:flame/extensions.dart';
import 'package:flame/geometry.dart';
import 'package:flame/collisions.dart';
import 'package:flame/palette.dart';

class PathComponent extends ShapeComponent {
  PathComponent({
    required this.path,
    this.hasHitboxes = true,
    this.renderHitboxes = false,
    this.hitboxesPaint,
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
  final bool hasHitboxes;
  final bool renderHitboxes;
  final Paint? hitboxesPaint;

  late final whiteStroke = BasicPalette.white.paint()..style = .stroke;

  @override
  FutureOr<void> onLoad() async {
    await super.onLoad();
    final hitboxes = _hitboxesFor(path);
    addAll(_filterHitboxes(hitboxes));
  }

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

  List<PolygonHitbox> _filterHitboxes(List<PolygonHitbox> hitboxes) {
    if (hitboxes.length < 2) {
      return hitboxes;
    }
    // Sort the hitboxes by size in ascending order: we will use the largest
    // area in order to approximate full inclusion.
    hitboxes.sort((a, b) => (b.size.length2 - a.size.length2).toInt());
    final first = hitboxes.first;
    final area = Rect.fromCenter(
      center: first.position.toOffset(),
      width: first.width,
      height: first.height,
    );

    // We always keep the first hitbox (the largest one): the others
    // are discarded if they fit entirely within it.
    hitboxes.removeWhere((element) {
      if (element == first) {
        return false;
      }
      final bounds = Rect.fromCenter(
        center: element.position.toOffset(),
        width: element.width,
        height: element.height,
      );
      return area.expandToInclude(bounds) == area;
    });
    return hitboxes;
  }

  List<PolygonHitbox> _hitboxesFor(Path path) {
    final hitboxes = <PolygonHitbox>[];
    final contours = path.walkContours();
    for (final contour in contours) {
      final rectangle = contour.rectangle;
      hitboxes.add(
        PolygonHitbox(
            contour.vertices,
            anchor: .center,
            position: rectangle.center.toVector2(),
          )
          ..priority = priority + 1
          ..paint = hitboxesPaint ?? whiteStroke
          ..renderShape = renderHitboxes,
      );
    }
    return hitboxes;
  }
}
