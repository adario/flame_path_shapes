import 'package:flame_path_shapes/commons/commons.dart';
import 'package:flame_path_shapes/commons/example_use_case.dart';
import 'package:flame_path_shapes/stories/svg/collidable_svg_paths_example.dart';
// import 'package:flame_path_shapes/stories/svg/svg_component.dart';
import 'package:flame/game.dart';
import 'package:widgetbook/widgetbook.dart';

WidgetbookComponent svgStories() {
  return WidgetbookComponent(
    name: 'Svg',
    useCases: [
      // ExampleUseCase(
      //   name: 'Svg Component',
      //   builder: (_) => GameWidget(game: SvgComponentExample()),
      //   codeLink: baseLink('svg/svg_component.dart'),
      //   info: SvgComponentExample.description,
      // ),
      ExampleUseCase(
        name: 'Collidable Svg Paths',
        builder: (_) => GameWidget(game: CollidableSvgPathsExample()),
        codeLink: baseLink('svg/collidable_svg_paths_example.dart'),
        info: CollidableSvgPathsExample.description,
      ),
    ],
  );
}
