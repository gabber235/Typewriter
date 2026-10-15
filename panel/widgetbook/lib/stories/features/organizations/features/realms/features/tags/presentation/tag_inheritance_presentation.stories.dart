import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "Inheritance leaf", type: AuthoredResourceInspection)
Widget tagInheritanceLeafUseCase(BuildContext context) =>
    _story(context, tags: [_tag("leaf")], roots: const ["leaf"]);

@widgetbook.UseCase(
  name: "Inheritance unary chain",
  type: AuthoredResourceInspection,
)
Widget tagInheritanceUnaryUseCase(BuildContext context) => _story(
  context,
  tags: [
    _tag("direct", parents: const ["middle"]),
    _tag("middle", parents: const ["leaf"]),
    _tag("leaf"),
  ],
  roots: const ["direct"],
);

@widgetbook.UseCase(
  name: "Inheritance branching",
  type: AuthoredResourceInspection,
)
Widget tagInheritanceBranchingUseCase(BuildContext context) => _story(
  context,
  tags: [
    _tag("direct", parents: const ["first", "second"]),
    _tag("first"),
    _tag("second"),
  ],
  roots: const ["direct"],
);

@widgetbook.UseCase(
  name: "Inheritance shared ancestor",
  type: AuthoredResourceInspection,
)
Widget tagInheritanceSharedUseCase(BuildContext context) => _story(
  context,
  tags: [
    _tag("first_root", parents: const ["shared"]),
    _tag("second_root", parents: const ["shared"]),
    _tag("shared", parents: const ["first_leaf", "second_leaf"]),
    _tag("first_leaf"),
    _tag("second_leaf"),
  ],
  roots: const ["first_root", "second_root"],
);

@widgetbook.UseCase(
  name: "Inheritance keyboard interaction",
  type: AuthoredResourceInspection,
)
Widget tagInheritanceKeyboardUseCase(BuildContext context) => _story(
  context,
  tags: [
    _tag("focusable_branch", parents: const ["first", "second"]),
    _tag("first"),
    _tag("second"),
  ],
  roots: const ["focusable_branch"],
);

@widgetbook.UseCase(
  name: "Inheritance narrow layout",
  type: AuthoredResourceInspection,
)
Widget tagInheritanceNarrowUseCase(BuildContext context) => _story(
  context,
  width: 400,
  tags: [
    _tag(
      "a_moderately_long_direct_tag",
      parents: const [
        "a_moderately_long_first_parent",
        "a_moderately_long_second_parent",
      ],
    ),
    _tag("a_moderately_long_first_parent"),
    _tag("a_moderately_long_second_parent"),
  ],
  roots: const ["a_moderately_long_direct_tag"],
);

@widgetbook.UseCase(
  name: "Inheritance right to left",
  type: AuthoredResourceInspection,
)
Widget tagInheritanceRightToLeftUseCase(BuildContext context) => _story(
  context,
  textDirection: TextDirection.rtl,
  tags: [
    _tag("direct", parents: const ["first", "second"]),
    _tag("first"),
    _tag("second"),
  ],
  roots: const ["direct"],
);

Widget _story(
  BuildContext context, {
  required List<Tag> tags,
  required List<String> roots,
  double width = 520,
  TextDirection textDirection = TextDirection.ltr,
}) {
  final book = context.knobs.boolean(label: "Inspect Book", initialValue: true);
  final inspectorWidth = context.knobs.double.slider(
    label: "Inspector width",
    initialValue: width,
    min: 280,
    max: 700,
  );
  return tagInheritanceStory(
    tags: tags,
    roots: roots.map(_tagRecordId).toList(),
    book: book,
    width: inspectorWidth,
    textDirection: textDirection,
  );
}

Widget tagInheritanceStory({
  required List<Tag> tags,
  required List<skir.ResourceId> roots,
  bool book = true,
  double width = 400,
  TextDirection textDirection = TextDirection.ltr,
}) => FakeApp(
  child: Directionality(
    textDirection: textDirection,
    child: Center(
      child: SizedBox(
        width: width,
        height: 760,
        child: CompiledTagInheritanceInspector(
          key: ValueKey(
            Object.hash(book, Object.hashAll(tags), Object.hashAll(roots)),
          ),
          document: compiledTagInheritanceDocument(tags: tags, roots: roots),
          resource: book ? compiledInheritanceBookId : compiledInheritanceTagId,
        ),
      ),
    ),
  ),
);

Tag _tag(String id, {List<String> parents = const []}) => Tag(
  tagId: _tagRecordId(id),
  name: id,
  color: switch (id) {
    "direct" || "first_root" => const Color(0xffff527d),
    "second" || "second_leaf" => const Color(0xff67d9ae),
    _ => const Color(0xff69a9ff),
  },
  parentIds: parents.map(_tagRecordId).toList(),
  placement: const GraphPlacement(x: 0, y: 0, width: 4, height: 1),
);

skir.ResourceId _tagRecordId(String id) => skir.ResourceId(value: "tag:$id");
