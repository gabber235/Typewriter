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
  /// Widgetbook theme.
  ///
  /// Like `pumpPanel`, the story renders in a desktop window and never
  /// reaches the network. Returns a driver over the story's world once its
  /// first frames ran; stories without a panel stage return null.
  Future<PanelDriver?> pumpStory(
    WidgetBuilder story, {
    Map<String, String> knobs = const {},
    String path = "story",
    bool dark = false,
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
    await runStory();
    final stage = find.byType(PanelStage);
    if (stage.evaluate().isEmpty) return null;
    return PanelDriver(this, widget<PanelStage>(stage.first).world);
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
