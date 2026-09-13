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
import 'package:flame_path_shapes/commons/path_component.dart';
import 'package:flame_path_shapes/commons/paths.dart';
import 'package:flame_path_shapes/commons/rounded_rect_component.dart';
import 'package:flutter/material.dart';

const side = 200.0;
const playArea = Rect.fromLTRB(-side, -side, side, side);
const fontFamily = 'LEDBoard-7';
const fontSize = 9.0;

typedef ButtonColors = (Color, Color);

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

  TextRenderer get textRenderer => TextPaint(
    style: TextStyle(
      fontSize: fontSize - 1,
      fontFamily: fontFamily,
      color: Colors.white,
    ),
  );

  TextRenderer get textOffRenderer => TextPaint(
    style: TextStyle(
      fontSize: fontSize - 1,
      fontFamily: fontFamily,
      color: Colors.white54,
    ),
  );

  Vector2 get buttonSize => Vector2(40, 16);

  late AdvancedButtonComponent _rotateButton;
  late AdvancedButtonComponent _modeButton;
  late AdvancedButtonComponent _shapeButton;
  late AdvancedButtonComponent _raysButton;

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
    _shapeButton = _createShapeButton();
    _modeButton = _createModeButton();
    _raysButton = _createRaysButton();
    _rotateButton.isDisabled = isCircle;
    _modeButton.isDisabled = isCircle;
    camera.viewport.addAll([
      _rotateButton,
      _raysButton,
      _shapeButton,
      _modeButton,
    ]);
  }

  Vector2 get halfSize => size * 0.5;
  bool get isCircle => world.isCircle;

  ButtonColors _getColorsFor(Color color) {
    final disabledColor = color.withValues(alpha: 0.5);
    Color downColor;
    if (color == BasicPalette.orange.color) {
      downColor = BasicPalette.lightOrange.color;
    } else if (color == BasicPalette.blue.color) {
      downColor = BasicPalette.lightBlue.color;
    } else if (color == BasicPalette.pink.color) {
      downColor = BasicPalette.lightPink.color;
    } else if (color == BasicPalette.purple.color) {
      downColor = BasicPalette.magenta.color;
    } else {
      downColor = color;
    }
    return (downColor, disabledColor);
  }

  AdvancedButtonComponent _createButton(
    String title,
    double x,
    Anchor anchor,
    Color color,
    void Function()? action, {
    double y = 2,
  }) {
    final colors = _getColorsFor(color);
    final disabledColor = colors.$2;
    final downColor = colors.$1;
    return CancellableButtonComponent(
      position: Vector2(x, y),
      size: buttonSize,
      anchor: anchor,
      priority: RaysInShapeWorld.hudPriority,
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
      () => _changeShape(),
    );
  }

  AdvancedButtonComponent _createRaysButton() {
    return _createButton(
      'Rays',
      size.x * 0.5,
      .topCenter,
      BasicPalette.purple.color,
      () => world.changeRays(),
      y: _shapeButton.position.y + buttonSize.y + 2,
    );
  }

  void _changeShape() {
    world.changeShape();
    _rotateButton.isDisabled = isCircle;
    _modeButton.isDisabled = isCircle;
  }
}

final whiteStroke = Paint()
  ..color = const Color(0xffffffff)
  ..style = PaintingStyle.stroke;

final pathStroke = Paint()
  ..color = BasicPalette.blue.color
  ..style = PaintingStyle.stroke
  ..strokeWidth = 3
  ..strokeCap = .round
  ..strokeJoin = .bevel;

final lightStroke = Paint()
  ..color = const Color(0x90ffffff)
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
  bool get _hitScreen {
    final hitbox = _raycastResult?.hitbox;
    if (hitbox != null) {
      return hitbox is ScreenHitbox ||
          (hitbox is RectangleHitbox && hitbox.parent is ScreenHitbox);
    }
    return false;
  }

  late final _rayLength = playArea.width * 0.1;
  late Offset _lineTarget;

  Offset get _lineOffset => Offset(radius, radius);

  @override
  void update(double dt) {
    super.update(dt);
    _raycastResult = worldRef.intersections(ray);
    if (_raycastResult == null) {
      paint = _lightPaint;
      _lineTarget = ray.direction.scaled(_rayLength).toOffset();
    } else {
      if (_hitScreen) {
        paint = _lightPaint;
      } else {
        paint = _raycastResult!.isInsideHitbox ? _greenPaint : _redPaint;
      }
      final origin = ray.origin.toOffset();
      _lineTarget = _raycastResult!.intersectionPoint!.toOffset() - origin;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final offset = _lineOffset;
    canvas.drawLine(offset, _lineTarget + offset, paint);
  }

  @override
  void onHoverEnter() {
    // Only apply hover feedback when not dragging.
    if (!isDragging) {
      _isHovering = true;
    }
  }

  @override
  void onHoverExit() {
    if (!isDragging) {
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
    final taxicabDistance = point.x.abs() + point.y.abs();
    return taxicabDistance <= radius * 2 || super.containsLocalPoint(point);
  }

  void _updateFromDrag(Vector2 drag) {
    drag -= Vector2(radius, radius);
    position += drag;
    ray.origin += drag;
  }

  final Ray2 ray;

  bool get isDragging => _isDragging || isDragged;
  bool get isHovering => _isHovering || isHovered;
  bool get isActive => isHovering || isDragging;

  bool _isDragging = false;
  bool _isHovering = false;

  Paint get _lightPaint => isActive ? hoveredLightStroke : lightStroke;
  Paint get _redPaint => isActive ? hoveredRedStroke : redStroke;
  Paint get _greenPaint => isActive ? hoveredGreenStroke : greenStroke;
}

class RaysInShapeWorld extends World
    with HasGameRef<RaysInShapeExample>, HasCollisionDetection {
  final _rng = Random();
  List<Ray2> _rays = [];
  final Map<Ray2, RayCircleComponent> _circles = {};
  Iterable<RayCircleComponent> get circleComponents => _circles.values;

  int get _numRays => 300;

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
        radius: 3,
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
  static double get rotateDuration => 20.0;

  static int get hudPriority => 1000;
  static int get shapePriority => 1;

  final _components = [
    CircleComponent(
      priority: shapePriority,
      radius: _componentSize.x * 0.6,
      anchor: Anchor.center,
      position: Vector2.zero(),
      paint: whiteStroke,
      children: [CircleHitbox()],
    ),
    RectangleComponent(
      priority: shapePriority,
      size: _componentSize,
      anchor: Anchor.center,
      position: Vector2.zero(),
      paint: whiteStroke,
      children: [RectangleHitbox()],
    ),
    PositionComponent(
      priority: shapePriority,
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
    for (var index = 0; index < numPaths; ++index) _pathComponent(index),
  ];

  final _ignoredHitboxes = <PolygonHitbox>[];

  static PathComponent _pathComponent(int index) {
    // Create a standard test path with our chosen size but the original
    // aspect ratio; this is centered by default.
    final path = _indexedPath(index);

    // Create a hitbox per each path contour.
    final hitboxes = _hitboxesFor(path);

    // Create a component that displays the whole path: we filter all hitboxes
    // that are (approximately) fully enclosed in the largest one.
    return PathComponent(
        path: path,
        priority: shapePriority,
        position: Vector2.zero(),
        children: _filter(hitboxes),
      )
      ..paint = pathStroke
      ..renderShape = true;
  }

  static Path _indexedPath(int index) {
    return indexedPath(index % numPaths, _pathSize);
  }

  static List<PolygonHitbox> _filter(List<PolygonHitbox> hitboxes) {
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
      final i = area.expandToInclude(bounds);
      return i == area;
    });
    return hitboxes;
  }

  static List<PolygonHitbox> _hitboxesFor(Path path) {
    final hitboxes = <PolygonHitbox>[];
    final contours = path.walkContours();
    for (final contour in contours) {
      hitboxes.add(
        PolygonHitbox(
            contour.vertices,
            anchor: .center,
            position: contour.rectangle.center.toVector2(),
          )
          ..priority = shapePriority + 1
          ..paint = whiteStroke
          ..renderShape = true,
      );
    }
    return hitboxes;
  }

  late TextComponent _textComponent;
  TextPaint get _textRenderer => TextPaint(
    style: TextStyle(
      color: Colors.white,
      fontSize: fontSize,
      fontFamily: fontFamily,
    ),
  );

  PositionComponent get current => _components[_componentIndex];
  PolygonRayIntersection? get polygon {
    if (current is PathComponent) {
      final f = current.children.firstWhere(
        (element) => element is PolygonHitbox,
        orElse: () => Component(),
      );
      return f is PolygonHitbox ? f : null;
    }
    return null;
  }

  var useContainment = false;
  int? hoveredRay;
  Effect? rotate;
  var isRotating = false;

  bool get isCircle => current is CircleComponent;

  void _forceUpdate() {
    _resetTimer();
    _resetTotalTimer();
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
    final angle = isRotating && !isCircle ? current.angle : null;
    remove(current);
    _componentIndex = (_componentIndex + 1) % _components.length;
    _addCurrent(current);
    if (isRotating && angle != null) {
      current.angle = angle;
    }
    _recording.clear();
  }

  void changeRays() {
    _recording.clear();
    _rays = randomRays(_numRays);
    _createCircles();
    _forceUpdate();
  }

  void _addRotate(Component component) {
    _removeRotate();
    final Effect? effect = current.firstChild();
    if (_componentIndex != 0 && effect == null) {
      rotate = createRotate();
      component.add(rotate!);
    }
  }

  void _removeRotate() {
    rotate?.removeFromParent();
    rotate = null;
  }

  void _addCurrent(PositionComponent component) {
    _removeRotate();
    if (isRotating && !isCircle) {
      _addRotate(component);
    }
    add(component);
  }

  @override
  FutureOr<void> onLoad() {
    super.onLoad();
    _addCurrent(current);
    add(ScreenHitbox());
    _textComponent = TextComponent(
      text: 'Rays #${_rays.length}',
      priority: hudPriority,
      position: Vector2(
        (playArea.width * 0.5) - 2,
        (playArea.height * 0.5) - 6,
      ),
      anchor: .centerRight,
      textRenderer: _textRenderer,
    );
    addAll([
      FpsTextComponent(
        decimalPlaces: 1,
        windowSize: _updatesInterval,
        priority: hudPriority,
        position: Vector2(
          (-playArea.width * 0.5) + 2,
          (playArea.height * 0.5) - 6,
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
  var _totalUpdates = 0;

  RaycastResult<ShapeHitbox>? intersections(Ray2 ray) => _recording[ray];

  late DateTime _start;
  int _elapsed = 0;
  double _totalElapsed = 0;

  void _startTimer() {
    _start = DateTime.now();
  }

  void _advanceTimer() {
    final delta = DateTime.now().difference(_start);
    _elapsed += delta.inMicroseconds;
  }

  void _updateTotalTimer(double elapsed) {
    _totalElapsed += elapsed;
    _totalUpdates++;
  }

  void _resetTimer() {
    _elapsed = 0;
    _updates = 0;
  }

  void _resetTotalTimer() {
    _totalUpdates = 0;
    _totalElapsed = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);

    _startTimer();
    for (final ray in _rays) {
      final result = collisionDetection.raycast(
        ray,
        ignoreHitboxes: _ignoredHitboxes,
        useContainment: useContainment,
      );
      _recording[ray] = result;
    }
    _advanceTimer();
    if (++_updates >= _updatesInterval) {
      _updateTimer();
      _resetTimer();
    }
  }

  void _updateTimer() {
    final elapsed = _elapsed / _updates;
    _updateTotalTimer(elapsed);
    final total = _totalElapsed / _totalUpdates;
    _updateTimerText(elapsed, total);
  }

  void _updateTimerText(double elapsed, double total) {
    var message = '#${_rays.length} ';
    if (polygon != null) {
      message += useContainment ? 'contain ' : 'odd-cross ';
    } else {
      message += 'circle ';
    }

    message += elapsedString(elapsed).padLeft(7);
    message += '/${elapsedString(total).padLeft(7)}';
    _textComponent.text = message;
  }

  String elapsedString(double elapsed) {
    if (elapsed >= 1000) {
      return '${(elapsed / 1000).toStringAsFixed(1)}ms';
    } else {
      return '${elapsed.toStringAsFixed(1)}us';
    }
  }
}
