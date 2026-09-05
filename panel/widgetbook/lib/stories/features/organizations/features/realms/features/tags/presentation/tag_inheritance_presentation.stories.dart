import "package:flutter/material.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "Inheritance leaf", type: TagGraph)
Widget tagInheritanceLeafUseCase(BuildContext context) =>
    _story(tags: [_tag("leaf")], roots: const ["leaf"]);

@widgetbook.UseCase(name: "Inheritance unary chain", type: TagGraph)
Widget tagInheritanceUnaryUseCase(BuildContext context) => _story(
  tags: [
    _tag("direct", parents: const ["middle"]),
    _tag("middle", parents: const ["leaf"]),
    _tag("leaf"),
  ],
  roots: const ["direct"],
);

@widgetbook.UseCase(name: "Inheritance branching", type: TagGraph)
Widget tagInheritanceBranchingUseCase(BuildContext context) => _story(
  tags: [
    _tag("direct", parents: const ["first", "second"]),
    _tag("first"),
    _tag("second"),
  ],
  roots: const ["direct"],
);

@widgetbook.UseCase(name: "Inheritance shared ancestor", type: TagGraph)
Widget tagInheritanceSharedUseCase(BuildContext context) => _story(
  tags: [
    _tag("first_root", parents: const ["shared"]),
    _tag("second_root", parents: const ["shared"]),
    _tag("shared", parents: const ["first_leaf", "second_leaf"]),
    _tag("first_leaf"),
    _tag("second_leaf"),
  ],
  roots: const ["first_root", "second_root"],
);

@widgetbook.UseCase(name: "Inheritance keyboard interaction", type: TagGraph)
Widget tagInheritanceKeyboardUseCase(BuildContext context) => _story(
  tags: [
    _tag("focusable_branch", parents: const ["first", "second"]),
    _tag("first"),
    _tag("second"),
  ],
  roots: const ["focusable_branch"],
);

@widgetbook.UseCase(name: "Inheritance narrow layout", type: TagGraph)
Widget tagInheritanceNarrowUseCase(BuildContext context) => _story(
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

@widgetbook.UseCase(name: "Inheritance right to left", type: TagGraph)
Widget tagInheritanceRightToLeftUseCase(BuildContext context) => _story(
  textDirection: TextDirection.rtl,
  tags: [
    _tag("direct", parents: const ["first", "second"]),
    _tag("first"),
    _tag("second"),
  ],
  roots: const ["direct"],
);

Widget _story({
  required List<Tag> tags,
  required List<String> roots,
  double width = 520,
  TextDirection textDirection = TextDirection.ltr,
}) {
  const rootBinding = BindingReference(bindingId: BindingId(0));
  const rootType = ResolvedTypeRef(
    id: QualifiedTypeId(namespace: "widgetbook", name: "TagInheritance"),
    revision: 1,
  );
  return FakeApp(
    child: Directionality(
      textDirection: textDirection,
      child: Center(
        child: SizedBox(
          width: width,
          child: EditorProtocolRenderer(
            envelope: TypedValueEnvelope(
              rootType: rootType,
              rootValue: ListValue(
                roots.map((id) => StringValue(_tagRecordId(id).id)).toList(),
              ),
            ),
            typeCatalog: TypeCatalog([
              TypeDefinition(
                id: rootType,
                kind: NominalTypeKind.concrete,
                representation: ListType(element: tagReferenceType),
              ),
            ]),
            collections: [tagPresentationCollection(tags)],
            presentation: effectiveTagGraph(
              id: "widgetbook.tagInheritance",
              title: "Inheritance",
              roots: rootBinding,
            ),
          ),
        ),
      ),
    ),
  );
}

Tag _tag(String id, {List<String> parents = const []}) => Tag(
  tagId: _tagRecordId(id),
  authoringSequence: 1,
  name: id,
  color: Colors.blue,
  parentIds: parents.map(_tagRecordId).toList(),
  placement: const Placement(x: 0, y: 0, width: 4, height: 1),
);

skir.RecordId _tagRecordId(String id) => recordId("tag:$id");
