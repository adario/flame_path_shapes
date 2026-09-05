import 'package:dashbook/dashbook.dart';
import 'package:flame_path_shapes/stories/collision_detection/collision_detection.dart';
import 'package:flame_path_shapes/stories/experimental/experimental.dart';
import 'package:flame_path_shapes/stories/input/input.dart';
import 'package:flutter/material.dart';

void main() {
  runAsDashbook();
}

void runAsDashbook() {
  final dashbook = Dashbook(title: 'Flame Examples', theme: ThemeData.dark());

  // Some small sample games
  // addGameStories(dashbook);

  // Show some different ways of structuring games
  // addStructureStories(dashbook);

  // Feature examples
  // addAudioStories(dashbook);
  // addAnimationStories(dashbook);
  // addCameraAndViewportStories(dashbook);
  addCollisionDetectionStories(dashbook);
  // addComponentsStories(dashbook);
  // addDecoratorStories(dashbook);
  // addEffectsStories(dashbook);
  addExperimentalStories(dashbook);
  addInputStories(dashbook);
  // addLayoutStories(dashbook);
  // addParallaxStories(dashbook);
  // addRenderingStories(dashbook);
  // addRouterStories(dashbook);
  // addTiledStories(dashbook);
  // addSpritesStories(dashbook);
  // addSvgStories(dashbook);
  // addSystemStories(dashbook);
  // addUtilsStories(dashbook);
  // addWidgetsStories(dashbook);
  // addImageStories(dashbook);

  // Bridge package examples
  // addForge2DStories(dashbook);
  // addFlameIsolateExample(dashbook);
  // addFlameJennyExample(dashbook);
  // addFlameLottieExample(dashbook);
  // addFlameSpineExamples(dashbook);

  runApp(dashbook);
}
