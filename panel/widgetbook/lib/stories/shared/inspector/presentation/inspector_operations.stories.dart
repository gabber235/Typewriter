import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

final _lostVillage = Book(
  bookId: skir.ResourceId(value: "book:the_lost_village"),
  title: "The Lost Village",
  icon: "material-symbols:book",
  color: Colors.teal,
);

/// Organizing operations a Realm declares beside the core ones, in its own
/// order.
const _pin = RealmOperation(
  "Pin",
  group: skir.OperationGroup.organize,
  order: 10,
  emphasis: skir.OperationEmphasis.outline,
);
const _tag = RealmOperation(
  "Tag",
  group: skir.OperationGroup.organize,
  order: 20,
);

/// The inspector's operations of a selected Book: a section per group with
/// a divider between, in the order of its context menu. Right click the
/// Book for the same list as a menu.
@widgetbook.UseCase(name: "Operations in sections", type: InspectorOperations)
Widget inspectorOperationsUseCase(BuildContext context) {
  return Story([
    signedIn(ada, organization: acme),
    realm(books: [_lostVillage]),
    ...context.knobs.traits("Filled buttons declared", {
      "One": [
        operations(const [
          RealmOperation.duplicate(),
          _pin,
          _tag,
          RealmOperation.moveTo(),
          RealmOperation.delete(),
        ]),
      ],
      // Duplicate asks to be filled too; only the first filled one is.
      "Two": [
        operations(const [
          RealmOperation(
            "Duplicate",
            group: skir.OperationGroup.edit,
            emphasis: skir.OperationEmphasis.filled,
          ),
          _pin,
          _tag,
          RealmOperation.moveTo(),
          RealmOperation.delete(),
        ]),
      ],
    }),
    selected([
      AuthoringResourceIdentifier(
        organizationId: acme.organizationId,
        realmId: skir.recordId("realm_instance:main"),
        resourceId: _lostVillage.bookId,
      ),
    ]),
  ]);
}
