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

/// The traits of a Realm with [_lostVillage] and [_quest], selecting what
/// the Selection knob names.
List<Trait> _selection(BuildContext context, {String initial = "One Book"}) => [
  signedIn(ada, organization: acme),
  realm(books: [_lostVillage], tags: [_quest]),
  ...context.knobs.traits("Selection", {
    "Nothing": const [],
    "One Book": [
      selected([_resource(_lostVillage.bookId)]),
    ],
    "One Tag": [
      selected([_resource(_quest.tagId)]),
    ],
    "A Book and a Tag": [
      selected([_resource(_lostVillage.bookId), _resource(_quest.tagId)]),
    ],
  }, initial: initial),
];

/// The [DesktopInspector] pane beside the content of a wide window: it
/// arrives when something is selected and leaves when nothing is. Drag its
/// edge to resize it; it never grows past three eighths of the window.
@widgetbook.UseCase(name: "Default", type: DesktopInspector)
Widget desktopInspectorUseCase(BuildContext context) {
  return Story([
    ..._selection(context),
    ...context.knobs.traits("Window", {
      "Desktop": const [],
      "Wide": [window(const Size(1920, 1080))],
      "Narrow": [window(const Size(1000, 720))],
    }),
  ]);
}

/// The [MobileInspector] bottom sheet of a narrow window: it peeks when
/// something is selected, drags up to fill the window, and clears the
/// selection when dragged shut.
@widgetbook.UseCase(name: "Default", type: MobileInspector)
Widget mobileInspectorUseCase(BuildContext context) {
  return Story([
    ..._selection(context),
    ...context.knobs.traits("Window", {
      "Compact": const [compact],
      "Phone": [window(const Size(360, 720))],
    }),
  ]);
}

/// [InspectorOperations] for what is selected: only the operations that
/// accept the whole selection appear, so a Book, a Tag and both together
/// each list their own.
@widgetbook.UseCase(name: "Default", type: InspectorOperations)
Widget inspectorOperationsUseCase(BuildContext context) {
  return Story(_selection(context));
}
