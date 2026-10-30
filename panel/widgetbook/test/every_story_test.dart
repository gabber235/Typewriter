import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_workspace/main.directories.g.dart";

import "support/stories.dart";

/// Every story of the catalog, by its path such as
/// `features/members/join_codes/presentation/JoinCodesPage/Default`.
final Map<String, WidgetbookUseCase> stories = {
  for (final useCase
      in WidgetbookRoot(
        children: directories,
      ).leaves.whereType<WidgetbookUseCase>())
    useCase.path: useCase,
};

/// More combinations than this vary one knob at a time instead.
const _combinationLimit = 12;

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
      _expectClean(tester, path, "initial");
      final variants = _variants(tester.storyKnobs.values);
      await tester.captureStory("$path/initial");

      for (final variant in variants) {
        final name = variant.entries
            .map((knob) => "${knob.key}=${knob.value}")
            .join(",");
        await tester.pumpStory(story.builder, path: path, knobs: variant);
        _expectClean(tester, path, name);
        await tester.captureStory("$path/$name");
      }

      await tester.pumpStory(story.builder, path: path, dark: true);
      _expectClean(tester, path, "dark");
      await tester.captureStory("$path/dark");
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}

/// Fails with the story and variant when a frame threw or overflowed.
void _expectClean(WidgetTester tester, String path, String variant) {
  final error = tester.takeException();
  if (error != null) fail("$path ($variant) threw: $error");
}

/// The knob values to render besides the initial ones: every combination of
/// the choice knobs, or each choice alone when there are too many.
List<Map<String, String>> _variants(Iterable<Knob> knobs) {
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
