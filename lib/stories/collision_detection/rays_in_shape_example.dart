import 'dart:async';
import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/extensions.dart';
import 'package:flame/game.dart';
import 'package:flame/geometry.dart';
import 'package:flame_path_shapes/commons/paths.dart';
import 'package:flutter/material.dart';

const playArea = Rect.fromLTRB(-100, -100, 100, 100);

class RaysInShapeExample extends FlameGame {
  static const description = '''
In this example we showcase the raytrace functionality where you can see whether
the rays are inside the shapes or not. Click to change the shape that the rays
are casted against. The rays originates from small circles, and if the circle is
inside the shape it will be red, otherwise green. And if the ray doesn't hit any
shape it will be gray.
''';

  RaysInShapeExample()
    : super(
        world: RaysInShapeWorld(),
        camera: CameraComponent.withFixedResolution(
          width: playArea.width,
          height: playArea.height,
        ),
      );
}

final whiteStroke = Paint()
  ..color = const Color(0xffffffff)
  ..style = PaintingStyle.stroke;

final lightStroke = Paint()
  ..color = const Color(0x50ffffff)
  ..style = PaintingStyle.stroke;

final greenStroke = Paint()
  ..color = const Color(0xff00ff00)
  ..style = PaintingStyle.stroke;

final redStroke = Paint()
  ..color = const Color(0xffff0000)
  ..style = PaintingStyle.stroke;

class RaysInShapeWorld extends World
    with
        HasGameRef<RaysInShapeExample>,
        HasCollisionDetection,
        TapCallbacks,
        DoubleTapCallbacks {
  final _rng = Random();
  List<Ray2> _rays = [];

  int get _numRays => 400;

  List<Ray2> randomRays(int count) => List<Ray2>.generate(
    count,
    (index) => Ray2(
      origin:
          (Vector2.random(_rng)) * playArea.size.width -
          playArea.size.toVector2() / 2,
      direction: (Vector2.random(_rng) - Vector2(0.5, 0.5)).normalized(),
    ),
  );

  int _componentIndex = 0;
  static final _componentSize = Vector2(
    playArea.width * 0.5,
    playArea.height * 0.5,
  );
  static final _pathSize = Size(playArea.width * 0.5, playArea.height * 0.5);

  final _components = [
    CircleComponent(
      radius: _componentSize.x * 0.6,
      anchor: Anchor.center,
      position: Vector2.zero(),
      paint: whiteStroke,
      children: [CircleHitbox()],
    ),
    RectangleComponent(
      size: _componentSize,
      anchor: Anchor.center,
      position: Vector2.zero(),
      paint: whiteStroke,
      children: [RectangleHitbox()],
    ),
    PositionComponent(
      position: Vector2.zero(),
      children: [
        PolygonHitbox.relative(
            [
              Vector2(-0.7, -1),
              Vector2(1, -0.4),
              Vector2(0.3, 1),
              Vector2(-1, 0.6),
            ],
            parentSize: _componentSize,
            anchor: Anchor.center,
            position: Vector2.zero(),
          )
          ..paint = whiteStroke
          ..renderShape = true,
      ],
    ),
    for (var index = 0; index < 5; ++index)
      PositionComponent(
        position: Vector2.zero(),
        children: [
          PolygonHitbox.contour(
              indexedPath(index, _pathSize).centered,
              granularity: 1.0,
              anchor: .center,
              position: Vector2.zero(),
            )
            ..paint = whiteStroke
            ..renderShape = true,
        ],
      ),
  ];

  late TextComponent _textComponent;
  TextPaint get _textRenderer =>
      TextPaint(style: TextStyle(color: Colors.white, fontSize: 10));

  PositionComponent get current => _components[_componentIndex];
  PolygonRayIntersection? get polygon {
    final first = current.children.first;
    if (first is PolygonRayIntersection) {
      return first;
    }
    return null;
  }

  @override
  FutureOr<void> onLoad() {
    super.onLoad();
    add(current);
    _textComponent = TextComponent(
      text: 'Rays #${_rays.length}',
      priority: 1,
      position: Vector2(
        (playArea.width * 0.5) - 5,
        (playArea.height * 0.5) - 10,
      ),
      anchor: .centerRight,
      textRenderer: _textRenderer,
    );
    addAll([
      FpsTextComponent(
        priority: 1,
        position: Vector2(
          (-playArea.width * 0.5) + 5,
          (playArea.height * 0.5) - 10,
        ),
        anchor: .centerLeft,
        textRenderer: _textRenderer,
      ),
      _textComponent,
    ]);
    _rays = randomRays(_numRays);
  }

  @override
  void onTapUp(TapUpEvent event) {
    super.onTapUp(event);
    final polygon = this.polygon;
    if (polygon != null) {
      polygon.useContainment = !polygon.useContainment;
    }
    _updates = _updatesInterval;
  }

  @override
  void onDoubleTapUp(DoubleTapEvent event) {
    super.onDoubleTapUp(event);
    remove(current);
    _componentIndex = (_componentIndex + 1) % _components.length;
    add(current);
    _recording.clear();
    _rays = randomRays(_numRays);
    _updates = _updatesInterval;
  }

  final Map<Ray2, RaycastResult<ShapeHitbox>?> _recording = {};
  final int _updatesInterval = 30;
  var _updates = 0;

  @override
  void update(double dt) {
    super.update(dt);

    final timer = Stopwatch()..start();
    for (final ray in _rays) {
      final result = collisionDetection.raycast(ray);
      _recording.addAll({ray: result});
    }
    timer.stop();
    if (++_updates >= _updatesInterval) {
      _updates = 0;
      var message = '#${_rays.length} ';
      final polygon = this.polygon;
      if (polygon != null) {
        message += polygon.useContainment ? 'contain ' : 'crossing ';
      } else {
        message += 'circle ';
      }
      final t = '${timer.elapsedMicroseconds}µs';
      message += t.padLeft(7);
      _textComponent.text = message;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    for (final ray in _recording.keys) {
      final result = _recording[ray];
      if (result == null) {
        canvas.drawLine(
          ray.origin.toOffset(),
          (ray.origin + ray.direction.scaled(10)).toOffset(),
          lightStroke,
        );
        canvas.drawCircle(ray.origin.toOffset(), 1, lightStroke);
      } else {
        canvas.drawLine(
          ray.origin.toOffset(),
          result.intersectionPoint!.toOffset(),
          lightStroke,
        );
        canvas.drawCircle(
          ray.origin.toOffset(),
          1,
          result.isInsideHitbox ? redStroke : greenStroke,
        );
      }
    }
  }
}
