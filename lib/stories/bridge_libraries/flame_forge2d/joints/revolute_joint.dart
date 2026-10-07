import 'dart:math';
import 'dart:ui';

import 'package:flame_path_shapes/stories/bridge_libraries/flame_forge2d/utils/balls.dart';
import 'package:flame_path_shapes/stories/bridge_libraries/flame_forge2d/utils/boundaries.dart';
import 'package:flame_path_shapes/stories/bridge_libraries/flame_forge2d/utils/joint_renderer.dart';
import 'package:flame_path_shapes/stories/bridge_libraries/flame_forge2d/utils/path_shape.dart';
import 'package:flame_path_shapes/stories/bridge_libraries/flame_forge2d/utils/style.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flame_test/test_paths.dart';

class RevoluteJointExample() extends Forge2DExampleGame {
  static const description = '''
    In this example we use a joint to keep a body with several fixtures stuck
    to another body.

    Tap the screen to add more of these combined bodies.
  ''';

  this : super(gravity: Vector2(0, 10.0), world: RevoluteJointWorld());
}

class RevoluteJointWorld()
    extends Forge2DWorld
    with TapCallbacks, HasGameRef<Forge2DGame> {
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    addAll(createBoundaries(gameRef));
  }

  /// The shapes that the taps cycle through, where null stands for circles.
  static const _shapes = [
    null,
    'flame',
    'alien1',
    'clover',
    'abstract',
    'invader3',
  ];

  /// The number of taps so far.
  var _taps = 0;

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    final ball = Ball(event.localPosition);
    add(ball);
    const size = CircleShuffler.pathSize;
    final name = _shapes[_taps++ % _shapes.length];
    final path = name == null
        ? null
        : TestPaths.byName(name, const Size(size, size));
    add(CircleShuffler(ball, path: path));
  }
}

/// A ring of pieces around the [ball], which are circles, or the convex pieces
/// of the first contour of the [path] fitted within [pathSize], if any.
class CircleShuffler(final Ball ball, {final Path? path})
    extends BodyComponent {
  static const pieceRadius = 1.2;

  /// The size of the square that the [path] is fitted within, in meters,
  /// slightly larger than the circles.
  static const pathSize = pieceRadius * 2 + 1;

  @override
  Body createBody() {
    final bodyDef = BodyDef(
      type: BodyType.dynamic,
      position: ball.body.position.clone(),
    );
    const numPieces = 5;
    const radius = 6.0;
    final body = world.createBody(bodyDef);
    final shapeDef = ShapeDef(
      density: 50.0,
      material: SurfaceMaterial(friction: 0.5, restitution: 0.4),
    );
    // Centered on the origin, and shifted to each piece.
    final pathPieces = path == null
        ? null
        : PathShape.piecesOf(
            PathShape.contourComponent(
              path!,
              Vector2.all(pathSize),
              gameRef.metersToPixels,
            ),
          );

    for (var i = 0; i < numPieces; i++) {
      final xPos = radius * cos(2 * pi * (i / numPieces));
      final yPos = radius * sin(2 * pi * (i / numPieces));
      final center = Vector2(xPos, yPos);

      if (pathPieces == null) {
        body.createShape(Circle(radius: pieceRadius, center: center), shapeDef);
      } else {
        for (final piece in pathPieces) {
          body.createShape(
            Polygon([for (final vertex in piece) vertex + center]),
            shapeDef,
          );
        }
      }
    }

    final joint = world.physicsWorld.createRevoluteJoint(
      RevoluteJointDef(bodyA: body, bodyB: ball.body),
    );
    world.add(JointRenderer(joint: joint));

    return body;
  }
}
