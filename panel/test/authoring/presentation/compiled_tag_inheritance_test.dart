import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

const _pink = Color(0xffff527d);
const _blue = Color(0xff69a9ff);
const _green = Color(0xff67d9ae);

void main() {
  for (final book in [true, false]) {
    final subject = book ? "Book" : "Tag";
    testWidgets("compiled $subject hides an empty inheritance section", (
      tester,
    ) async {
      await tester.showComponent(
        SizedBox(
          width: 400,
          child: CompiledTagInheritanceInspector(
            document: compiledTagInheritanceDocument(
              tags: const [],
              roots: const [],
            ),
            resource: book
                ? compiledInheritanceBookId
                : compiledInheritanceTagId,
          ),
        ),
      );
      expect(CompiledInheritanceSection(book: book).finder, findsNothing);
      expect(
        find.text(book ? "Direct Tags" : "Direct Parents"),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets("compiled $subject leaf fills the inspector without an arrow", (
      tester,
    ) async {
      await tester.showComponent(
        SizedBox(
          width: 400,
          child: CompiledTagInheritanceInspector(
            document: compiledTagInheritanceDocument(
              tags: [tag("Quest", color: _pink)],
              roots: [tag("Quest").tagId],
            ),
            resource: book
                ? compiledInheritanceBookId
                : compiledInheritanceTagId,
          ),
        ),
      );
      final section = CompiledInheritanceSection(book: book);
      final card = section.card("Quest");
      expect(card, findsOneWidget);
      expect(tester.getSize(card).width, greaterThan(340));
      expect(section.hierarchies, findsNothing);
      expect(section.disclosures, findsNothing);
      expect(
        find.descendant(of: section.finder, matching: find.byType(Chip)),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets("compiled unary chain keeps equal card widths and child colors", (
    tester,
  ) async {
    await tester.showComponent(
      SizedBox(
        width: 400,
        child: CompiledTagInheritanceInspector(
          document: compiledTagInheritanceDocument(
            tags: [
              tag("Quest", color: _pink, parents: [tag("Story").tagId]),
              tag("Story", color: _blue, parents: [tag("Content").tagId]),
              tag("Content", color: _green),
            ],
            roots: [tag("Quest").tagId],
          ),
          resource: compiledInheritanceBookId,
        ),
      ),
    );
    final section = CompiledInheritanceSection();
    final widths = [
      for (final name in ["Quest", "Story", "Content"])
        tester.getSize(section.card(name)).width,
    ];
    expect(widths[0], greaterThan(340));
    expect(widths[1], closeTo(widths[0], 0.01));
    expect(widths[2], closeTo(widths[0], 0.01));
    expect(section.disclosures, findsNothing);
    final colors = section.strokeColors;
    expect(colors, containsAll([_blue, _green]));
    expect(colors, isNot(contains(_pink)));
    expect(tester.takeException(), isNull);
  });

  for (final direction in [TextDirection.ltr, TextDirection.rtl]) {
    testWidgets(
      "a collapsed branch opens and closes from the keyboard in $direction",
      (tester) async {
        final panel = await tester.showComponent(
          Directionality(
            textDirection: direction,
            child: SizedBox(
              width: 400,
              child: CompiledTagInheritanceInspector(
                document: compiledTagInheritanceDocument(
                  tags: [
                    tag(
                      "Quest",
                      color: _pink,
                      parents: [tag("Story").tagId, tag("Region").tagId],
                    ),
                    tag("Story", color: _blue),
                    tag("Region", color: _green),
                  ],
                  roots: [tag("Quest").tagId],
                ),
                resource: compiledInheritanceBookId,
              ),
            ),
          ),
        );
        final section = CompiledInheritanceSection();
        expect(section.label("Story"), findsNothing);
        final toggle = section.disclosures;
        expect(toggle, findsOneWidget);
        await tester.ensureVisible(toggle);
        Focus.of(
          tester.element(
            find.descendant(of: toggle, matching: find.byType(Icon)),
          ),
        ).requestFocus();
        await tester.pumpAndSettle();
        expect(panel.hasFocusOn("Expand"), isTrue);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(section.label("Story"), findsOneWidget);
        expect(section.label("Region"), findsOneWidget);
        expect(section.strokeColors, containsAll([_pink, _blue, _green]));
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();
        expect(section.label("Story"), findsNothing);
        expect(panel.hasFocusOn("Expand"), isTrue);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets("compiled shared ancestor expands independently on each path", (
    tester,
  ) async {
    await tester.showComponent(
      SizedBox(
        width: 400,
        child: CompiledTagInheritanceInspector(
          document: compiledTagInheritanceDocument(
            tags: [
              tag("Quest", color: _pink, parents: [tag("Shared").tagId]),
              tag("Region", color: _green, parents: [tag("Shared").tagId]),
              tag(
                "Shared",
                color: _blue,
                parents: [tag("Story").tagId, tag("Content").tagId],
              ),
              tag("Story", color: _pink),
              tag("Content", color: _green),
            ],
            roots: [tag("Quest").tagId, tag("Region").tagId],
          ),
          resource: compiledInheritanceBookId,
        ),
      ),
    );
    final section = CompiledInheritanceSection();
    expect(section.label("Shared"), findsNWidgets(2));
    expect(section.disclosures, findsNWidgets(2));

    final first = section.disclosures.first;
    await tester.ensureVisible(first);
    await tester.tap(first);
    await tester.pumpAndSettle();
    expect(section.label("Story"), findsOneWidget);
    expect(section.label("Content"), findsOneWidget);

    final second = section.disclosures.last;
    await tester.ensureVisible(second);
    await tester.tap(second);
    await tester.pumpAndSettle();
    expect(section.label("Story"), findsNWidgets(2));
    expect(section.label("Content"), findsNWidgets(2));

    await tester.ensureVisible(first);
    await tester.tap(first);
    await tester.pumpAndSettle();
    expect(section.label("Story"), findsOneWidget);
    expect(section.label("Content"), findsOneWidget);
    expect(tester.widget<Button>(second).tooltip, "Collapse");
    expect(tester.takeException(), isNull);
  });

  testWidgets("compiled long tag label wraps inside a narrow card", (
    tester,
  ) async {
    const name =
        "A long inherited quest tag whose complete name remains readable";
    await tester.showComponent(
      SizedBox(
        width: 280,
        child: CompiledTagInheritanceInspector(
          document: compiledTagInheritanceDocument(
            tags: [tag(name, color: _pink)],
            roots: [tag(name).tagId],
          ),
          resource: compiledInheritanceBookId,
        ),
      ),
    );
    final card = CompiledInheritanceSection().card(name);
    final label = CompiledInheritanceSection().label(name);
    expect(tester.getSize(card).width, lessThanOrEqualTo(280));
    expect(tester.getSize(label).height, greaterThan(30));
    expect(tester.takeException(), isNull);
  });
}
