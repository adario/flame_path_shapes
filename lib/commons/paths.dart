import 'dart:math';
import 'dart:ui';

import 'package:flame/extensions.dart';
import 'package:flame/game.dart';

Path resizePath(Path path, Size size) {
  final box = path.getBounds();
  final t = Transform2D();
  t.scale = Vector2(size.width / box.width, size.height / box.height);
  return path.transform32(t.transformMatrix.storage);
}

Path roundRectPath(Size size) {
  return Path()..addRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(min(size.width, size.height) * 0.25),
    ),
  );
}

Path flamePath() {
  return Path()
    ..moveTo(62.0, 42.8)
    ..cubicTo(62.0, 58.9, 49.0, 65.0, 33.0, 65.0)
    ..cubicTo(17.0, 65.0, 4.0, 58.9, 4.0, 42.8)
    ..cubicTo(4.0, 38.6, 4.9, 35.9, 6.5, 32.2)
    ..cubicTo(7.6, 29.8, 10.1, 40.7, 11.9, 38.8)
    ..cubicTo(16.2, 34.1, 7.2, 23.3, 23.8, 15.2)
    ..cubicTo(20.8, 23.5, 23.2, 26.8, 26.4, 26.8)
    ..cubicTo(33.4, 26.8, 33.5, 16.3, 32.7, 3.0)
    ..cubicTo(54.1, 19.6, 42.3, 26.0, 44.7, 28.1)
    ..cubicTo(56.6, 29.4, 48.7, 3.1, 59.3, 28.3)
    ..cubicTo(61.3, 32.8, 62.0, 37.5, 62.0, 42.8)
    ..close();
}
