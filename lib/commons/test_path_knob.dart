import 'package:flame/game.dart';
import 'package:flame_test/test_paths.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

const _testPathKnob = 'Shape';

/// A knob to pick one of the [TestPaths], which returns its index.
int testPathKnob(BuildContext context) {
  return context.knobs.object.dropdown(
    label: _testPathKnob,
    initialOption: 0,
    options: List.generate(TestPaths.count, (index) => index),
    labelBuilder: (index) => TestPaths.names[index],
  );
}

/// A knob to rotate the shape, which is off by default.
bool rotateKnob(BuildContext context) {
  return context.knobs.boolean(label: 'Rotate');
}

/// A game that shows one of the [TestPaths], which can be changed later.
mixin TestPathSelectable on FlameGame {
  /// Shows the shape with the given index in [TestPaths.names].
  void setShape(int shape);

  /// Rotates the shape or stops it, for the games that support the
  /// [rotateKnob]; the others ignore it.
  void setRotate(bool rotate) {}

  /// Called with the index of the shape once the game has loaded, as it can
  /// be chosen by the game itself.
  void Function(int shape)? onShapeLoaded;
}

/// Hosts a single [TestPathSelectable] game and applies the [testPathKnob] to
/// it, so that changing the knob doesn't restart the game.
///
/// The game is created with the knob value only if the knob has one already,
/// so that it can choose its shape otherwise, which is then written back to
/// the knob once the game has loaded.
class TestPathStory extends StatefulWidget {
  const TestPathStory({
    required this.shape,
    required this.create,
    this.rotate = false,
    super.key,
  });

  /// The value of the [testPathKnob].
  final int shape;

  /// The value of the [rotateKnob], if the game supports it.
  final bool rotate;

  /// Creates the game with the given shape, or one of its own choice.
  final TestPathSelectable Function(int? shape) create;

  @override
  State<TestPathStory> createState() => _TestPathStoryState();
}

class _TestPathStoryState extends State<TestPathStory> {
  late final _game = widget.create(_hasKnobValue ? widget.shape : null)
    ..onShapeLoaded = _updateKnob
    ..setRotate(widget.rotate);

  bool get _hasKnobValue {
    final state = WidgetbookState.of(context);
    final knobs = FieldCodec.decodeQueryGroup(state.queryParams['knobs']);
    return knobs.containsKey(_testPathKnob);
  }

  @override
  void didUpdateWidget(TestPathStory oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shape != oldWidget.shape) {
      _game.setShape(widget.shape);
    }
    if (widget.rotate != oldWidget.rotate) {
      _game.setRotate(widget.rotate);
    }
  }

  void _updateKnob(int shape) {
    if (!mounted) {
      return;
    }
    WidgetbookState.of(context).updateQueryField(
      group: 'knobs',
      field: _testPathKnob,
      value: TestPaths.names[shape],
    );
  }

  @override
  Widget build(BuildContext context) => GameWidget(game: _game);
}
