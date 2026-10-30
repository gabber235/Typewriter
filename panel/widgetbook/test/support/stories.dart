import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";
import "package:widgetbook/widgetbook.dart";

/// Where story images land: build output of the repository, never checked
/// in and never compared, published as pull request evidence.
const storyImages = "../../.xtask/results/stories";

/// Marks the boundary a story renders in; a symbol, so no story key matches.
const _storyKey = ValueKey(#widgetbookStory);

/// Starting stories in a widget test, the way Widgetbook shows them.
extension StoryTester on WidgetTester {
  /// Shows [story] with its knobs set to [knobs] (label to option label);
  /// knobs left out keep their initial value. [dark] picks the dark
  /// Widgetbook theme. The story runs for [run] before this returns, longer
  /// for stories whose doubles answer late.
  ///
  /// Like `pumpPanel`, the story renders in a desktop window and never
  /// reaches the network. Returns a driver over the story's world once its
  /// first frames ran; every story renders a panel stage.
  Future<PanelDriver> pumpStory(
    WidgetBuilder story, {
    Map<String, String> knobs = const {},
    String path = "story",
    bool dark = false,
    Duration run = const Duration(seconds: 1),
  }) async {
    keepOffline();
    view
      ..physicalSize = desktopWindow
      ..devicePixelRatio = 1;
    addTearDown(view.reset);
    final state = WidgetbookState(
      path: path,
      root: WidgetbookRoot(children: const []),
      queryParams: {"knobs": FieldCodec.encodeQueryGroup(knobs)},
    );
    addTearDown(state.dispose);
    await pumpWidget(
      WidgetbookScope(
        state: state,
        child: RepaintBoundary(
          key: _storyKey,
          child: Theme(
            data: buildTheme(dark ? Brightness.dark : Brightness.light),
            child: Builder(builder: story),
          ),
        ),
      ),
    );
    await runStory(duration: run);
    return PanelDriver(
      this,
      widget<PanelStage>(find.byType(PanelStage).first).world,
    );
  }

  /// Lets a story run for [duration] of test time, frame by frame.
  ///
  /// Stories hold endless animations (loading indicators, shimmers), so this
  /// never waits for them to settle.
  Future<void> runStory({
    Duration duration = const Duration(seconds: 1),
  }) async {
    const frame = Duration(milliseconds: 100);
    for (var waited = Duration.zero; waited < duration; waited += frame) {
      await pump(frame);
    }
  }

  /// Scrolls [target] into view, taps it and lets the story run.
  Future<void> tapInStory(Finder target) async {
    await ensureVisible(target);
    await tap(target);
    await runStory();
  }

  /// Replaces the text of the field read as [label] with [text] and lets the
  /// story run.
  Future<void> typeInStory(String label, String text) async {
    await enterText(find.bySemanticsLabel(label), text);
    await runStory();
  }

  /// Presses [key], with Shift or the platform's primary modifier (Command on
  /// Apple platforms, Control elsewhere) held when asked, and lets the story
  /// run. Stories hold endless animations, so this never waits for them to
  /// settle the way the panel driver's presses do.
  Future<void> pressInStory(
    LogicalKeyboardKey key, {
    bool shift = false,
    bool primary = false,
  }) async {
    final modifiers = [
      if (shift) LogicalKeyboardKey.shiftLeft,
      if (primary)
        switch (defaultTargetPlatform) {
          TargetPlatform.macOS ||
          TargetPlatform.iOS => LogicalKeyboardKey.metaLeft,
          _ => LogicalKeyboardKey.controlLeft,
        },
    ];
    for (final modifier in modifiers) {
      await sendKeyDownEvent(modifier);
    }
    await sendKeyEvent(key);
    for (final modifier in modifiers.reversed) {
      await sendKeyUpEvent(modifier);
    }
    await runStory();
  }

  /// Picks up the item [item] of [panel], moves it past the drag threshold
  /// onto the item [onto] and lets the story run; the drag stays held, so
  /// the test drops or cancels it.
  Future<TestGesture> holdDrag(
    PanelDriver panel,
    String item, {
    required String onto,
  }) async {
    final gesture = await startGesture(panel.item(item).rect.center);
    await gesture.moveBy(const Offset(25, 0));
    await pump();
    await gesture.moveTo(panel.item(onto).rect.center);
    await runStory();
    return gesture;
  }

  /// The knobs the shown story registered, by label.
  Map<String, Knob> get storyKnobs =>
      WidgetbookState.of(element(find.byKey(_storyKey))).knobs;

  /// Writes what the story shows to [name] below [storyImages].
  Future<void> captureStory(String name) async {
    final boundary = renderObject<RenderRepaintBoundary>(find.byKey(_storyKey));
    await runAsync(() async {
      final image = await boundary.toImage();
      final bytes = await image.toByteData(format: ImageByteFormat.png);
      image.dispose();
      final file = File("$storyImages/$name.png");
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
    });
  }
}

/// Loads the fonts the catalog bundles, so story images show real text
/// instead of the test font's boxes.
Future<void> loadStoryFonts() async {
  final manifest = jsonDecode(
    await rootBundle.loadString("FontManifest.json"),
  ) as List<Object?>;
  for (final family in manifest.cast<Map<String, Object?>>()) {
    final loader = FontLoader(family["family"]! as String);
    for (final font in (family["fonts"]! as List<Object?>).cast<Map>()) {
      loader.addFont(rootBundle.load(font["asset"]! as String));
    }
    await loader.load();
  }
}

/// More combinations than this vary one knob at a time instead.
const _combinationLimit = 12;

/// The knob values to render besides the initial ones: every combination of
/// the choice knobs, or each choice alone when there are too many.
List<Map<String, String>> storyVariants(Iterable<Knob> knobs) {
  final choices = <String, List<String>>{
    for (final knob in knobs)
      for (final field in knob.fields)
        if (_options(field) case final options? when options.length > 1)
          field.name: options,
  };
  var combinations = 1;
  for (final options in choices.values) {
    combinations *= options.length;
  }
  if (combinations <= _combinationLimit) {
    var product = [<String, String>{}];
    for (final MapEntry(key: label, value: options) in choices.entries) {
      product = [
        for (final partial in product)
          for (final option in options) {...partial, label: option},
      ];
    }
    return product;
  }
  return [
    for (final MapEntry(key: label, value: options) in choices.entries)
      for (final option in options.skip(1)) {label: option},
  ];
}

/// The option labels of a choice field, or null for free input.
List<String>? _options(Field<dynamic> field) {
  // The fields are generic over the knob's value type; reading them as
  // dynamic avoids a label builder typed for one value type.
  final dynamic choice = field;
  return switch (field) {
    ObjectDropdownField() || ObjectSegmentedField() => [
      for (final Object? value in choice.values as List)
        choice.labelBuilder(value) as String,
    ],
    BooleanField() => const ["true", "false"],
    _ => null,
  };
}
