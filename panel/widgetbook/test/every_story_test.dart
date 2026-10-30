import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_workspace/main.directories.g.dart";

import "support/stories.dart";

/// Every story of the catalog, by its path such as
/// `features/members/join_codes/presentation/JoinCodesPage/Default`.
final Map<String, WidgetbookUseCase> stories = {
  for (final useCase in WidgetbookRoot(
    children: directories,
  ).leaves.whereType<WidgetbookUseCase>())
    useCase.path: useCase,
};

/// Renders every story in every combination of its choice knobs (dropdowns,
/// segments and switches), and its initial knobs once in the dark theme.
///
/// A story fails when it throws or overflows in any variant. Each variant is
/// captured as an image below [storyImages] for the pull request evidence;
/// images are never compared.
void main() {
  setUpAll(loadStoryFonts);

  for (final MapEntry(key: path, value: story) in stories.entries) {
    testWidgets("$path renders every variant", (tester) async {
      await tester.pumpStory(story.builder, path: path);
      expect(tester.takeException(), isNull, reason: "$path (initial)");
      final variants = storyVariants(tester.storyKnobs.values);
      await tester.captureStory("$path/initial");

      for (final variant in variants) {
        final name = variant.entries
            .map((knob) => "${knob.key}=${knob.value}")
            .join(",");
        await tester.pumpStory(story.builder, path: path, knobs: variant);
        expect(tester.takeException(), isNull, reason: "$path ($name)");
        await tester.captureStory("$path/$name");
      }

      await tester.pumpStory(story.builder, path: path, dark: true);
      expect(tester.takeException(), isNull, reason: "$path (dark)");
      await tester.captureStory("$path/dark");
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
