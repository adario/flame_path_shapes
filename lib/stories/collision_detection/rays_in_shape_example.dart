import 'dart:async';
import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/extensions.dart';
import 'package:flame/game.dart';
import 'package:flame/geometry.dart';
import 'package:flame/palette.dart';
import 'package:flame/text.dart';
import 'package:flame_path_shapes/commons/cancellable_button_component.dart';
import 'package:flame_path_shapes/commons/paths.dart';
import 'package:flame_path_shapes/commons/rounded_rect_component.dart';
import 'package:flutter/material.dart';

const playArea = Rect.fromLTRB(-100, -100, 100, 100);

extension ElapsedString on Stopwatch {
  String get elapsedString {
    final elapsed = elapsedMicroseconds;
    if (elapsed > 1000) {
      return '${(elapsed / 1000).toStringAsFixed(1)}ms';
    } else {
      return '$elapsedµs';
    }
  }
}

class RaysInShapeExample extends FlameGame<RaysInShapeWorld> {
  static const description = '''
In this example we showcase the raytrace functionality where you can see whether
the rays are inside the shapes or not. Double-click to change the shape that the rays
are casted against. The rays originates from small circles, and if the circle is
inside the shape it will be red, otherwise green. And if the ray doesn't hit any
shape it will be gray. Click once in all shapes but the circle to toggle
the ray casting/intersection behaviour between the (current) crossings approach
and the point-containment proposal, which should be used for concave polygons.
''';

  TextRenderer get textRenderer =>
      TextPaint(style: TextStyle(fontSize: 8, color: Colors.white));

  TextRenderer get textOffRenderer =>
      TextPaint(style: TextStyle(fontSize: 8, color: Colors.white54));

  Vector2 get buttonSize => Vector2(32, 12);

  late AdvancedButtonComponent _rotateButton;
  late AdvancedButtonComponent _modeButton;
  late AdvancedButtonComponent _shapeButton;

  RaysInShapeExample()
    : super(
        world: RaysInShapeWorld(),
        camera: CameraComponent.withFixedResolution(
          width: playArea.width,
          height: playArea.height,
        ),
      );

  @override
  FutureOr<void> onLoad() async {
    await super.onLoad();

    _rotateButton = _createRotateButton();
    _rotateButton.isDisabled = true;
    _shapeButton = _createShapeButton();
    _modeButton = _createModeButton();
    _modeButton.isDisabled = true;
    camera.viewport.addAll([_rotateButton, _shapeButton, _modeButton]);
  }

  Vector2 get halfSize => size * 0.5;

  AdvancedButtonComponent _createButton(
    String title,
    double x,
    Anchor anchor,
    Color color,
    void Function()? action,
  ) {
    final disabledColor = color.withValues(alpha: 0.5);
    Color downColor;
    if (color == BasicPalette.orange.color) {
      downColor = BasicPalette.lightOrange.color;
    } else if (color == BasicPalette.blue.color) {
      downColor = BasicPalette.lightBlue.color;
    } else if (color == BasicPalette.pink.color) {
      downColor = BasicPalette.lightPink.color;
    } else {
      downColor = color;
    }
    return CancellableButtonComponent(
      position: Vector2(x, 2),
      size: buttonSize,
      anchor: anchor,
      defaultLabel: TextComponent(text: title, textRenderer: textRenderer),
      disabledLabel: TextComponent(text: title, textRenderer: textOffRenderer),
      defaultSkin: RoundedRectComponent()..setColor(color),
      disabledSkin: RoundedRectComponent()..setColor(disabledColor),
      downSkin: RoundedRectComponent()..setColor(downColor),
      onReleased: action,
    );
  }

  AdvancedButtonComponent _createRotateButton() {
    return _createButton(
      'Rotate',
      2,
      .topLeft,
      BasicPalette.orange.color,
      () => world.toggleRotate(),
    );
  }

  AdvancedButtonComponent _createModeButton() {
    return _createButton(
      'Mode',
      size.x - 2,
      .topRight,
      BasicPalette.pink.color,
      () => world.toggleContainment(),
    );
  }

  AdvancedButtonComponent _createShapeButton() {
    return _createButton(
      'Shape',
      size.x * 0.5,
      .topCenter,
      BasicPalette.blue.color,
      () {
        world.changeShape();
        final isCircle = world.current is CircleComponent;
        _rotateButton.isDisabled = isCircle;
        _modeButton.isDisabled = isCircle;
        if (isCircle && world.isRotating) {
          world.toggleRotate();
        }
      },
    );
  }
}

final whiteStroke = Paint()
  ..color = const Color(0xffffffff)
  ..style = PaintingStyle.stroke;

final lightStroke = Paint()
  ..color = const Color(0x80ffffff)
  ..style = PaintingStyle.stroke;

final hoveredLightStroke = Paint()
  ..color = const Color(0xd0ffffff)
  ..style = PaintingStyle.stroke;

final greenStroke = Paint()
  ..color = const Color(0xd000ff00)
  ..style = PaintingStyle.stroke;

final hoveredGreenStroke = Paint()
  ..color = const Color(0xff00ff00)
  ..style = PaintingStyle.stroke;

final redStroke = Paint()
  ..color = const Color(0xd0ff0000)
  ..style = PaintingStyle.stroke;

final hoveredRedStroke = Paint()
  ..color = const Color(0xffff0000)
  ..style = PaintingStyle.stroke;

class RayCircleComponent extends CircleComponent
    with
        DragCallbacks,
        HoverCallbacks,
        TapCallbacks,
        HasWorldRef<RaysInShapeWorld> {
  RayCircleComponent(
    this.ray, {
    super.radius,
    super.position,
    super.scale,
    super.angle,
    super.anchor,
    super.children,
    super.priority,
    super.paint,
    super.paintLayers,
    super.key,
  });

  RaycastResult<ShapeHitbox>? _raycastResult;

  @override
  void update(double dt) {
    super.update(dt);
    _raycastResult = worldRef.intersections(ray);
    if (_raycastResult == null) {
      paint = lightPaint;
    } else {
      paint = _raycastResult!.isInsideHitbox ? greenPaint : redPaint;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.save();
    canvas.translate(radius, radius);
    final origin = ray.origin.toOffset();
    if (_raycastResult == null) {
      canvas.drawLine(.zero, ray.direction.scaled(10).toOffset(), lightPaint);
    } else {
      final target = _raycastResult!.intersectionPoint!.toOffset() - origin;
      canvas.drawLine(.zero, target, lightPaint);
    }
    canvas.restore();
  }

  @override
  void onHoverEnter() {
    // Only apply hover feedback when not dragging.
    if (!_isDragging) {
      _isHovering = true;
    }
  }

  @override
  void onHoverExit() {
    if (!_isDragging) {
      _isHovering = false;
    }
  }

  @override
  void onHoverCancel() {
    onHoverExit();
  }

  @override
  void onTapDown(TapDownEvent event) {
    _isDragging = true;

    // Guard against invalid local event positions.
    var local = event.localPosition;
    if (local.x.isNaN || local.y.isNaN) {
      local = absoluteToLocal(event.canvasPosition);
    }
  }

  @override
  void onTapUp(TapUpEvent event) {
    _isDragging = false;
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    _isDragging = false;
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    _isDragging = true;
    _updateFromDrag(event.localPosition);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    // Guard against invalid local event positions.
    var local = event.localEndPosition;
    if (local.x.isNaN || local.y.isNaN) {
      local = absoluteToLocal(event.canvasEndPosition);
    }
    _updateFromDrag(local);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _isDragging = false;
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    _isDragging = false;
  }

  @override
  bool containsLocalPoint(Vector2 point) {
    var inside = super.containsLocalPoint(point);
    if (!inside) {
      inside = point.taxicabDistanceTo(.zero()) <= radius * 2;
    }
    return inside;
  }

  void _updateFromDrag(Vector2 drag) {
    position += drag;
    ray.origin += drag;
  }

  final Ray2 ray;
  bool _isDragging = false;
  bool _isHovering = false;

  bool get _isActive => _isHovering || _isDragging;

  Paint get lightPaint => _isActive ? hoveredLightStroke : lightStroke;
  Paint get redPaint => _isActive ? hoveredRedStroke : redStroke;
  Paint get greenPaint => _isActive ? hoveredGreenStroke : greenStroke;
}

class RaysInShapeWorld extends World
    with HasGameRef<RaysInShapeExample>, HasCollisionDetection {
  final _rng = Random();
  List<Ray2> _rays = [];
  final Map<Ray2, RayCircleComponent> _circles = {};
  Iterable<RayCircleComponent> get circleComponents => _circles.values;

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

  void _createCircles() {
    removeAll(circleComponents);
    _circles.clear();
    for (final ray in _rays) {
      final circle = RayCircleComponent(
        ray,
        position: ray.origin.clone(),
        radius: 1,
        anchor: .center,
        paint: lightStroke,
      );
      _circles[ray] = circle;
    }
    addAll(circleComponents);
  }

  int _componentIndex = 0;
  static final _componentSize = Vector2(
    playArea.width * 0.5,
    playArea.height * 0.5,
  );
  static final _pathSize = Size(playArea.width * 0.5, playArea.height * 0.5);

  static Effect createRotate() {
    return RotateEffect.by(
      rotateAmplitude,
      EffectController(duration: rotateDuration, infinite: true),
    );
  }

  static double get rotateAmplitude => pi * 2.0;
  static double get rotateDuration => 10.0;

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

  var useContainment = false;
  int? hoveredRay;
  Effect? rotate;
  var isRotating = false;

  void _forceUpdate() {
    _updates = _updatesInterval;
  }

  void toggleRotate() {
    if (_componentIndex == 0) {
      // Not available on the circle.
      return;
    }
    isRotating = !isRotating;
    if (isRotating) {
      _addRotate(current);
    } else {
      _removeRotate();
    }
    _forceUpdate();
  }

  void toggleContainment() {
    if (_componentIndex == 0) {
      // Not available on the circle.
      return;
    }
    useContainment = !useContainment;
    _forceUpdate();
  }

  void changeShape() {
    remove(current);
    _componentIndex = (_componentIndex + 1) % _components.length;
    _addCurrent(current);
    _recording.clear();
    _rays = randomRays(_numRays);
    _createCircles();
    _forceUpdate();
  }

  bool _addRotate(Component component) {
    _removeRotate();
    if (_componentIndex != 0 && current.children.length < 2) {
      rotate = createRotate();
      component.add(rotate!);
      return true;
    }
    return false;
  }

  void _removeRotate() {
    rotate?.removeFromParent();
    rotate = null;
  }

  void _addCurrent(PositionComponent component) {
    _removeRotate();
    if (isRotating) {
      _addRotate(component);
    }
    add(component);
  }

  @override
  FutureOr<void> onLoad() {
    super.onLoad();
    _addCurrent(current);
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
        decimalPlaces: 1,
        windowSize: _updatesInterval,
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
    _createCircles();
  }

  Ray2? rayAtPoint(Vector2 point) {
    for (final ray in _rays) {
      if (point.taxicabDistanceTo(ray.origin) < 2) {
        return ray;
      }
    }
    return null;
  }

  final Map<Ray2, RaycastResult<ShapeHitbox>?> _recording = {};
  final int _updatesInterval = 30;
  var _updates = 0;

  RaycastResult<ShapeHitbox>? intersections(Ray2 ray) => _recording[ray];

  @override
  void update(double dt) {
    super.update(dt);

    final timer = Stopwatch()..start();
    for (final ray in _rays) {
      final result = collisionDetection.raycast(
        ray,
        useContainment: useContainment,
      );
      _recording[ray] = result;
    }
    timer.stop();
    if (++_updates >= _updatesInterval) {
      _updates = 0;
      _updateTimerText(timer);
    }
  }

  void _updateTimerText(Stopwatch timer) {
    var message = '#${_rays.length} ';
    if (polygon != null) {
      message += useContainment ? 'contain ' : 'crossing ';
    } else {
      message += 'circle ';
    }
    message += timer.elapsedString.padLeft(7);
    _textComponent.text = message;
  }
}
