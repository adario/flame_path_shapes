import 'dart:math';
import 'dart:ui';

import 'package:flame_path_shapes/commons/convex_pieces.dart';
import 'package:flame_path_shapes/stories/bridge_libraries/flame_forge2d/utils/style.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/extensions.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flame_test/test_paths.dart';

class DominoExample({bool showPieces = false}) extends Forge2DExampleGame {
  static const description = '''
    The classic domino tower: vertical dominoes carry horizontal ones as
    planks, level by level, with braces at the edges.

    The tower stands on its own until you tap the screen, which drops a random
    shape, different from the last one, that topples it. The shape collides as the convex pieces of its outline,
    which the Show pieces knob draws.
  ''';

  this
    : super(
        gravity: Vector2(0, 10.0),
        world: DominoExampleWorld(showPieces: showPieces),
        metersToPixels: 24,
      );

  /// Draws the convex pieces of the shapes, or stops drawing them.
  set showPieces(bool value) =>
      (world as DominoExampleWorld).showPieces = value;
}

class DominoExampleWorld({bool showPieces = false})
    extends Forge2DWorld
    with TapCallbacks, HasGameRef<Forge2DGame> {
  static const dominoWidth = 0.2;
  static const dominoHeight = 1.0;
  static const baseCount = 12;

  /// The size of the dropped shapes, in meters.
  static final shapeSize = Vector2(2, 3);

  int _tint = 0;

  final _random = Random();

  /// The indices in [TestPaths.names] of the shapes still to be dropped in
  /// this round, in which each test path is dropped once, in random order.
  final _shapes = <int>[];

  /// The index in [TestPaths.names] of the last dropped shape.
  int? _lastShape;

  /// The index in [TestPaths.names] of the next shape to drop, which is never
  /// the same as the last one.
  int _nextShape() {
    if (_shapes.isEmpty) {
      _shapes.addAll(
        List.generate(TestPaths.count, (i) => i)..shuffle(_random),
      );
      // The shapes are taken from the end, and the first one of a round must
      // not repeat the last one of the previous round.
      if (_shapes.last == _lastShape) {
        _shapes
          ..[_shapes.length - 1] = _shapes.first
          ..[0] = _lastShape!;
      }
    }
    return _lastShape = _shapes.removeLast();
  }

  bool _showPieces = showPieces;

  /// Whether the convex pieces of the shapes are drawn, which applies to the
  /// shapes already dropped too.
  bool get showPieces => _showPieces;
  set showPieces(bool value) {
    _showPieces = value;
    for (final shape in children.whereType<PathShape>()) {
      shape.renderBody = value;
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(Ground());
    _buildTower();

    // Frame the tower, which is built upwards from the ground at y = 0.
    gameRef.camera.viewfinder.position = Vector2(0, -towerHeight / 2);
  }

  /// How tall the finished tower is, in world units.
  static double get towerHeight =>
      dominoHeight * 0.5 + (dominoHeight + 2 * dominoWidth) * (baseCount - 1);

  /// Adds a domino [height] above the ground, standing up or lying down.
  void _addDomino(
    double x,
    double height, {
    required bool horizontal,
    required double density,
  }) {
    add(
      Domino(
        // The tower is built upwards, which is the negative y direction.
        initialPosition: Vector2(x, -height),
        horizontal: horizontal,
        density: density,
        color: ExampleColors.dynamicColor(_tint++),
      ),
    );
  }

  void _buildTower() {
    var density = 10.0;

    for (var i = 0; i < baseCount; i++) {
      final x = i * 1.5 * dominoHeight - 1.5 * dominoHeight * baseCount / 2;
      _addDomino(x, dominoHeight / 2, horizontal: false, density: density);
      _addDomino(
        x,
        dominoHeight + dominoWidth / 2,
        horizontal: true,
        density: density,
      );
    }

    for (var level = 1; level < baseCount; level++) {
      if (level > 3) {
        density *= 0.8;
      }
      final height =
          dominoHeight * 0.5 + (dominoHeight + 2 * dominoWidth) * 0.99 * level;
      final count = baseCount - level;
      for (var i = 0; i < count; i++) {
        final x = i * 1.5 * dominoHeight - 1.5 * dominoHeight * count / 2;
        // The braces at both ends of a level are heavier, which is what
        // keeps the tower standing.
        density *= 2.5;
        if (i == 0) {
          _addDomino(
            x - 1.25 * dominoHeight + 0.5 * dominoWidth,
            height - dominoWidth,
            horizontal: false,
            density: density,
          );
        }
        if (i == count - 1) {
          _addDomino(
            x + 1.25 * dominoHeight - 0.5 * dominoWidth,
            height - dominoWidth,
            horizontal: false,
            density: density,
          );
        }
        density /= 2.5;

        _addDomino(x, height, horizontal: false, density: density);
        _addDomino(
          x,
          height + 0.5 * (dominoWidth + dominoHeight),
          horizontal: true,
          density: density,
        );
        _addDomino(
          x,
          height - 0.5 * (dominoWidth + dominoHeight),
          horizontal: true,
          density: density,
        );
      }
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    final position = event.localPosition;
    final shapeIndex = _nextShape();
    print(
      'Dropping shape $shapeIndex = "${TestPaths.names[shapeIndex]}" at $position',
    );
    add(
      PathShape(position, TestPaths.byIndex(shapeIndex, shapeSize.toSize()))
        ..paint = (Paint()..color = ExampleColors.dynamicColor(_tint++))
        ..renderBody = _showPieces,
    );
  }
}

class Domino({
  /// Where the domino starts out; [position] tracks the live body position.
  required final Vector2 initialPosition,
  required final bool horizontal,
  required final double density,
  required Color color,
}) extends BodyComponent with GlowingBody {
  this {
    paint = Paint()..color = color;
  }

  @override
  double get outlineWidth => 0.04;

  @override
  Body createBody() {
    final bodyDef = BodyDef(
      type: BodyType.dynamic,
      position: initialPosition,
      rotation: horizontal ? Rot.fromAngle(pi / 2) : const Rot.identity(),
    );
    return world.createBody(bodyDef)..createShape(
      Polygon.box(
        DominoExampleWorld.dominoWidth / 2,
        DominoExampleWorld.dominoHeight / 2,
      ),
      // The default material is what a domino wants: plenty of grip and no
      // bounce. With less friction the tower shakes itself apart as soon as
      // the frame rate dips.
      ShapeDef(density: density),
    );
  }
}

/// A body with the shape of the first contour of a [Path], fitted within
/// [size] meters, which is drawn by a [PathComponent] and collides as the
/// convex pieces of the polygon of that component.
///
/// The pieces are drawn on top of it when [renderBody] is true.
class PathShape(final Vector2 initialPosition, final Path path, {Vector2? size})
    extends BodyComponent
    with GlowingBody {
  this : super(renderBody: false);

  final Vector2 size = size ?? Vector2(2, 3);

  /// The linear slop of Box2D in meters, which Forge2D doesn't expose: the
  /// points of a polygon closer than 4 times it are welded, and the ones
  /// closer than twice it to an edge are dropped, see `b2ComputeHull`.
  static const linearSlop = 0.005;

  late final List<List<Vector2>> _pieces;

  @override
  double get outlineWidth => 0.04;

  /// The component that draws the first contour of the [path], fitted within
  /// [size] meters, with [pixels] per meter.
  ///
  /// The contour is laid out in pixels rather than in meters, so that the
  /// default sampling of the component follows it closely, and then the
  /// component is scaled down to meters.
  static PathComponent contourComponent(
    Path path,
    Vector2 size,
    double pixels,
  ) {
    final metric = path.computeMetrics().first;
    final contour = metric.extractPath(0, metric.length)..close();
    return PathComponent(
      path: contour.resizeTo((size * pixels).toSize(), keepRatio: true),
      anchor: Anchor.center,
      scale: Vector2.all(1 / pixels),
    );
  }

  /// The convex pieces of the polygons of the [component], in the coordinates
  /// of its parent, which Box2D accepts as polygons.
  static List<List<Vector2>> piecesOf(PathComponent component) {
    return [
      for (final polygon in component.polygons)
        ...convexPieces(
          [for (final vertex in polygon) component.positionOf(vertex)],
          maxVertices: Polygon.maxVertices,
          minDistance: 4 * linearSlop,
          minWidth: 2 * linearSlop,
        ),
    ];
  }

  @override
  Future<void> onLoad() async {
    final pixels = gameRef.metersToPixels;
    final color = paint.color;
    final component = contourComponent(path, size, pixels)
      ..paintLayers = [
        Paint()..color = color.withValues(alpha: 0.28),
        Paint()
          ..color = color.withValues(alpha: 0.95)
          ..style = PaintingStyle.stroke
          ..strokeWidth = outlineWidth * pixels,
      ];
    // The body is created from the pieces by super.onLoad, and again whenever
    // it is mounted after being removed, so they are worked out only once.
    _pieces = piecesOf(component);
    await super.onLoad();
    add(component);
  }

  @override
  Body createBody() {
    final shapeDef = ShapeDef(
      userData: this, // To be able to determine object in collision
      material: SurfaceMaterial(restitution: 0.4, friction: 0.5),
    );

    final bodyDef = BodyDef(
      position: initialPosition,
      rotation: Rot.fromAngle((initialPosition.x + initialPosition.y) / 2 * pi),
      type: BodyType.dynamic,
    );
    final body = world.createBody(bodyDef);
    for (final piece in _pieces) {
      body.createShape(Polygon(piece), shapeDef);
    }
    return body;
  }
}

class Ground() extends BodyComponent with GlowingBody {
  this {
    paint = Paint()..color = ExampleColors.slate;
  }

  @override
  Body createBody() {
    // The top of the ground is at y = 0, which the tower is built up from.
    final bodyDef = BodyDef(position: Vector2(0, 1));
    return world.createBody(bodyDef)..createShape(Polygon.box(24, 1));
  }
}
