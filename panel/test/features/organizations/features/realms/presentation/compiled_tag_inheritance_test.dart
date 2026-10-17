import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../../../../support/test_utils.dart";

const _pink = Color(0xffff527d);
const _blue = Color(0xff69a9ff);
const _green = Color(0xff67d9ae);

void main() {
  for (final book in [true, false]) {
    final subject = book ? "Book" : "Tag";
    testWidgets("compiled $subject hides an empty inheritance section", (
      tester,
    ) async {
      await _pump(tester, book: book, tags: const [], roots: const []);
      expect(_section(book), findsNothing);
      expect(
        find.text(book ? "Direct Tags" : "Direct Parents"),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets("compiled $subject leaf fills the inspector without an arrow", (
      tester,
    ) async {
      await _pump(tester, book: book, tags: [_tag("Quest")], roots: ["Quest"]);
      final section = _section(book);
      final card = _card(section, "Quest");
      expect(card, findsOneWidget);
      expect(tester.getSize(card).width, greaterThan(340));
      expect(_hierarchies(section), findsNothing);
      expect(_disclosures(section), findsNothing);
      expect(
        find.descendant(of: section, matching: find.byType(Chip)),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets("compiled unary chain keeps equal card widths and child colors", (
    tester,
  ) async {
    await _pump(
      tester,
      tags: [
        _tag("Quest", parents: ["Story"]),
        _tag("Story", color: _blue, parents: ["Content"]),
        _tag("Content", color: _green),
      ],
      roots: ["Quest"],
    );
    final section = _section(true);
    final widths = [
      for (final name in ["Quest", "Story", "Content"])
        tester.getSize(_card(section, name)).width,
    ];
    expect(widths[0], greaterThan(340));
    expect(widths[1], closeTo(widths[0], 0.01));
    expect(widths[2], closeTo(widths[0], 0.01));
    expect(_disclosures(section), findsNothing);
    final colors = _strokeColors(tester, section);
    expect(colors, containsAll([_blue, _green]));
    expect(colors, isNot(contains(_pink)));
    expect(tester.takeException(), isNull);
  });

  for (final direction in [TextDirection.ltr, TextDirection.rtl]) {
    testWidgets(
      "compiled branch has a collapsed rail and keyboard disclosure in $direction",
      (tester) async {
        await _pump(
          tester,
          direction: direction,
          tags: [
            _tag("Quest", parents: ["Story", "Region"]),
            _tag("Story", color: _blue),
            _tag("Region", color: _green),
          ],
          roots: ["Quest"],
        );
        final section = _section(true);
        expect(_label(section, "Story"), findsNothing);
        final rail = find.descendant(
          of: section,
          matching: find.byWidgetPredicate((widget) {
            if (widget is! DecoratedBox ||
                widget.decoration is! BoxDecoration) {
              return false;
            }
            final border = (widget.decoration as BoxDecoration).border;
            return border is BorderDirectional &&
                border.start.width == 4 &&
                border.start.color == _pink;
          }),
        );
        expect(rail, findsOneWidget);
        expect(
          tester
              .getRect(rail)
              .contains(tester.getCenter(_label(section, "Quest"))),
          isTrue,
        );
        final toggle = _disclosures(section);
        expect(toggle, findsOneWidget);
        await tester.ensureVisible(toggle);
        await tester.pumpAndSettle();
        for (var count = 0; count < 80; count++) {
          if (_hasFocus(tester, toggle)) break;
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pumpAndSettle();
        }
        expect(_hasFocus(tester, toggle), isTrue);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(_label(section, "Story"), findsOneWidget);
        expect(_label(section, "Region"), findsOneWidget);
        expect(
          _strokeColors(tester, section),
          containsAll([_pink, _blue, _green]),
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();
        expect(_label(section, "Story"), findsNothing);
        expect(_hasFocus(tester, _disclosures(section)), isTrue);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets("compiled shared ancestor expands independently on each path", (
    tester,
  ) async {
    await _pump(
      tester,
      tags: [
        _tag("Quest", parents: ["Shared"]),
        _tag("Region", color: _green, parents: ["Shared"]),
        _tag("Shared", color: _blue, parents: ["Story", "Content"]),
        _tag("Story"),
        _tag("Content", color: _green),
      ],
      roots: ["Quest", "Region"],
    );
    final section = _section(true);
    expect(_label(section, "Shared"), findsNWidgets(2));
    expect(_disclosures(section), findsNWidgets(2));

    final first = _disclosures(section).first;
    await tester.ensureVisible(first);
    await tester.tap(first);
    await tester.pumpAndSettle();
    expect(_label(section, "Story"), findsOneWidget);
    expect(_label(section, "Content"), findsOneWidget);

    final second = _disclosures(section).last;
    await tester.ensureVisible(second);
    await tester.tap(second);
    await tester.pumpAndSettle();
    expect(_label(section, "Story"), findsNWidgets(2));
    expect(_label(section, "Content"), findsNWidgets(2));

    await tester.ensureVisible(first);
    await tester.tap(first);
    await tester.pumpAndSettle();
    expect(_label(section, "Story"), findsOneWidget);
    expect(_label(section, "Content"), findsOneWidget);
    expect(tester.widget<IconButton>(second).tooltip, "Collapse");
    expect(tester.takeException(), isNull);
  });

  testWidgets("compiled long tag label wraps inside a narrow card", (
    tester,
  ) async {
    const name =
        "A long inherited quest tag whose complete name remains readable";
    await _pump(tester, width: 280, tags: [_tag(name)], roots: [name]);
    final card = _card(_section(true), name);
    final label = _label(_section(true), name);
    expect(tester.getSize(card).width, lessThanOrEqualTo(280));
    expect(tester.getSize(label).height, greaterThan(30));
    expect(tester.takeException(), isNull);
  });
}

bool _hasFocus(WidgetTester tester, Finder button) {
  final focused = FocusManager.instance.primaryFocus?.context;
  if (focused is! Element) return false;
  final targets = button.evaluate().toSet();
  var containsFocus = targets.contains(focused);
  focused.visitAncestorElements((ancestor) {
    containsFocus = containsFocus || targets.contains(ancestor);
    return !containsFocus;
  });
  return containsFocus;
}

Finder _section(bool book) =>
    find.byKey(ValueKey(book ? "effective-tags" : "inheritance"));

Finder _label(Finder section, String name) =>
    find.descendant(of: section, matching: find.text(name));

Finder _card(Finder section, String name) => find
    .ancestor(
      of: _label(section, name),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is PortablePresentationNodeRenderer &&
            widget.node.element is skir.PresentationElement_containerWrapper,
      ),
    )
    .first;

Finder _disclosures(Finder section) => find.descendant(
  of: section,
  matching: find.byWidgetPredicate(
    (widget) =>
        widget is IconButton &&
        (widget.tooltip == "Expand" || widget.tooltip == "Collapse"),
  ),
);

Finder _hierarchies(Finder section) => find.descendant(
  of: section,
  matching: find.byWidgetPredicate(
    (widget) => widget.runtimeType.toString() == "_HierarchyRenderSurface",
  ),
);

List<Color> _strokeColors(WidgetTester tester, Finder section) => [
  for (final element in _hierarchies(section).evaluate())
    for (final dynamic stroke
        in (element.findRenderObject() as dynamic).debugStrokes)
      stroke.style.color as Color,
];

Tag _tag(String name, {Color color = _pink, List<String> parents = const []}) =>
    Tag(
      tagId: _id(name),
      name: name,
      color: color,
      parentIds: parents.map(_id).toList(),
      placement: const GraphPlacement(x: 0, y: 0, width: 4, height: 1),
    );

skir.ResourceId _id(String name) => skir.ResourceId(value: "tag:$name");

Future<void> _pump(
  WidgetTester tester, {
  required List<Tag> tags,
  required List<String> roots,
  bool book = true,
  double width = 400,
  TextDirection direction = TextDirection.ltr,
}) async {
  await tester.pumpTestApp(
    child: Directionality(
      textDirection: direction,
      child: Center(
        child: SizedBox(
          width: width,
          child: CompiledTagInheritanceInspector(
            document: compiledTagInheritanceDocument(
              tags: tags,
              roots: roots.map(_id).toList(),
            ),
            resource: book
                ? compiledInheritanceBookId
                : compiledInheritanceTagId,
          ),
        ),
      ),
    ),
  );
}
