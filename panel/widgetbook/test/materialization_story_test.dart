import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook_workspace/stories/features/organizations/features/realms/features/search/application/element_value_materialization.stories.dart";

void main() {
  for (final size in [
    const Size(390, 844),
    const Size(844, 390),
    const Size(1024, 768),
    const Size(1440, 1200),
  ]) {
    testWidgets("opens reference search at ${size.width} by ${size.height}", (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(Builder(builder: materializationPromptUseCase));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text("Create quest objective"), findsOneWidget);
      expect(find.text("Target"), findsOneWidget);
      expect(find.text("Identifier"), findsOneWidget);
      expect(find.text("Priority"), findsOneWidget);
      expect(find.text("Audience"), findsOneWidget);
      expect(find.text("Objectives"), findsOneWidget);
      expect(find.text("Variables"), findsOneWidget);
      expect(find.textContaining("number of"), findsNothing);
      expect(find.text(mixedValueReplacementMessage), findsNothing);
      expect(find.text("Multiple values"), findsNothing);
      expect(find.text("Create"), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, "Create"))
            .onPressed,
        isNull,
      );

      final targetControl = find.ancestor(
        of: find.text("Target"),
        matching: find.byType(LabeledControl),
      );
      final identifierControl = find.ancestor(
        of: find.text("Identifier"),
        matching: find.byType(LabeledControl),
      );
      expect(
        find.descendant(
          of: targetControl,
          matching: find.text("A value is required"),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: identifierControl,
          matching: find.text("A value is required"),
        ),
        findsOneWidget,
      );
      expect(find.text("Player Audience"), findsOneWidget);
      expect(find.text("Permission Audience"), findsOneWidget);
      expect(
        find.text("Abstract values require a polymorphic control"),
        findsNothing,
      );

      await tester.ensureVisible(targetControl);
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: targetControl,
          matching: find.byType(InputDecorator),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("Mayor greeting"), findsOneWidget);
      expect(find.text("Start main quest"), findsOneWidget);
      expect(find.text("Reward player"), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets("places a concrete polymorphic diagnostic on its field", (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(Builder(builder: materializationPromptUseCase));
    await tester.pumpAndSettle();

    await tester.tap(find.text("Player Audience"));
    await tester.pumpAndSettle();

    final playerControl = find.ancestor(
      of: find.text("Player", skipOffstage: false),
      matching: find.byType(LabeledControl, skipOffstage: false),
    );
    expect(
      find.descendant(
        of: playerControl,
        matching: find.text("A value is required", skipOffstage: false),
      ),
      findsOneWidget,
    );
    expect(
      find.text("A value is required", skipOffstage: false),
      findsNWidgets(4),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets("builds a constrained reference list incrementally", (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1024, 768));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(Builder(builder: materializationPromptUseCase));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text("Objectives"));
    await tester.tap(find.text("Objectives"));
    await tester.pumpAndSettle();
    final objectivesSearch = find.byType(PresentationSearchInput).last;
    await tester.tap(
      find.descendant(
        of: objectivesSearch,
        matching: find.byType(InputDecorator),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("Length must be at least 2"), findsOneWidget);

    await tester.tap(_resultRow("Mayor greeting"));
    await tester.pumpAndSettle();

    expect(find.text("Length must be at least 2"), findsOneWidget);
    expect(find.text("Mayor greeting"), findsWidgets);

    await tester.ensureVisible(_resultRow("Start main quest"));
    await tester.pumpAndSettle();
    await tester.tap(_resultRow("Start main quest"));
    await tester.pumpAndSettle();

    expect(find.text("Length must be at least 2"), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets("places an incomplete map diagnostic on the missing value", (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(Builder(builder: materializationPromptUseCase));
    await tester.pumpAndSettle();

    final variablesHeader = find.ancestor(
      of: find.text("Variables"),
      matching: find.byType(PresentationHeaderChrome),
    );
    await tester.ensureVisible(variablesHeader);
    await tester.tap(find.text("Variables"));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip("Add entry"));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: variablesHeader,
        matching: find.byIcon(Icons.error_outline),
      ),
      findsNWidgets(2),
    );
    expect(find.text("A value is required"), findsNWidgets(4));
    final valueControl = find.ancestor(
      of: find.text("Value"),
      matching: find.byType(LabeledControl),
    );
    expect(
      find.descendant(
        of: valueControl,
        matching: find.text("A value is required"),
      ),
      findsOneWidget,
    );
    expect(find.text("Length must be at least 1"), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets("map entry and collection diagnostics keep distinct owners", (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(Builder(builder: materializationPromptUseCase));
    await tester.pumpAndSettle();

    final variablesHeader = find.ancestor(
      of: find.text("Variables"),
      matching: find.byType(PresentationHeaderChrome),
    );
    await tester.tap(find.text("Variables"));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip("Add entry"));
    await tester.pumpAndSettle();

    var firstEntry = _entryHeader("Map entry 1");
    await _selectEntryValue(tester, firstEntry, "Mayor greeting");
    await tester.tap(find.byTooltip("Add entry"));
    await tester.pumpAndSettle();

    firstEntry = _entryHeader("Map entry 1");
    final secondEntry = _entryHeader("Map entry 2");
    expect(
      find.descendant(
        of: firstEntry,
        matching: find.byIcon(Icons.error_outline),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: secondEntry,
        matching: find.byIcon(Icons.error_outline),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: variablesHeader,
        matching: find.byIcon(Icons.error_outline),
      ),
      findsNWidgets(2),
    );

    await _selectEntryValue(tester, secondEntry, "Start main quest");

    expect(find.text("Map keys must be unique"), findsOneWidget);
    expect(
      find.descendant(
        of: _entryHeader("Map entry 1"),
        matching: find.byIcon(Icons.error_outline),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: _entryHeader("Map entry 2"),
        matching: find.byIcon(Icons.error_outline),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: variablesHeader,
        matching: find.byIcon(Icons.error_outline),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

Finder _resultRow(String label) => find
    .ancestor(of: find.text(label).first, matching: find.byType(InkWell))
    .first;

Finder _entryHeader(String label) => find.ancestor(
  of: find.text(label),
  matching: find.byType(PresentationHeaderChrome),
).first;

Future<void> _selectEntryValue(
  WidgetTester tester,
  Finder entry,
  String result,
) async {
  final search = find.descendant(
    of: entry,
    matching: find.byType(PresentationSearchInput),
  );
  final input = find.descendant(
    of: search,
    matching: find.byType(InputDecorator),
  );
  await tester.ensureVisible(input);
  await tester.pumpAndSettle();
  await tester.tap(input);
  await tester.pumpAndSettle();
  await tester.tap(_resultRow(result));
  await tester.pumpAndSettle();
}
