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

final _quest = Tag(
  tagId: skir.ResourceId(value: "tag:quest"),
  name: "Quest",
  color: Colors.teal,
);

/// The inspector beside a Realm's resources, showing what the user selected.
@widgetbook.UseCase(name: "Default", type: InspectorScaffold)
Widget inspectorUseCase(BuildContext context) {
  final color = context.knobs.object.segmented(
    label: "Tag color",
    options: const ["Shared with the Book", "Its own"],
    initialOption: "Its own",
  );
  final tag = color == "Its own"
      ? _quest.copyWith(color: Colors.orange)
      : _quest;
  return Story([
    signedIn(ada, organization: acme),
    realm(books: [_lostVillage], tags: [tag]),
    ...context.knobs.traits("Selection", {
      "Nothing": const [],
      "One Book": [
        selected([_resource(_lostVillage.bookId)]),
      ],
      "A Book and a Tag": [
        selected([_resource(_lostVillage.bookId), _resource(tag.tagId)]),
      ],
    }, initial: "A Book and a Tag"),
    ...context.knobs.traits("Window", {
      "Desktop": const [],
      "Compact": const [compact],
    }),
  ]);
}

/// [resource] of the Realm the story seeds.
AuthoringResourceIdentifier _resource(skir.ResourceId resource) =>
    AuthoringResourceIdentifier(
      organizationId: acme.organizationId,
      realmId: skir.recordId("realm_instance:main"),
      resourceId: resource,
    );
