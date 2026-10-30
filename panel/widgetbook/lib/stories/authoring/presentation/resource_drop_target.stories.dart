import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/stories/authoring/presentation/realm_story.dart";
import "package:widgetbook_workspace/support/story.dart";

@widgetbook.UseCase(name: "Drag entries onto a page", type: ResourceDropTarget)
Widget resourceDropTargetStory(BuildContext context) {
  final nodes = context.knobs.object.segmented(
    label: "Nodes",
    options: const ["Wide", "Narrow"],
    initialOption: "Wide",
  );
  return Story([
    signedIn(ada, organization: acme),
    realmServing(
      compiledEntryGraphDocument(
        narrow: nodes == "Narrow",
        operations: entryOperations,
      ),
    ),
    operations(entryOperations),
    ...context.knobs.traits("Village evening", {
      "Accepts the entries": [
        dropsOnto([compiledEntryDestinationId]),
      ],
      "Accepts them slowly": [
        dropsOnto([
          compiledEntryDestinationId,
        ], delay: const Duration(milliseconds: 750)),
      ],
      "Refuses the entries": [dropsOnto(const [])],
    }),
    ...context.knobs.traits("Realm", {
      "Online": const [],
      "Offline": const [realmHostStopped],
    }),
  ], at: realmSurface(compiledEntryPageId));
}

/// The operations the entry Realm offers on its entries.
const entryOperations = [moveToEvening, RealmOperation.delete()];

/// The Move to operation of the story: it moves the dragged entries onto
/// the Village evening page.
const moveToEvening = RealmOperation(
  "MoveToOwner",
  label: "Move to",
  group: skir.OperationGroup.organize,
  inspector: RealmOperationInspector.hidden,
  effect: _moveToEvening,
);

void _moveToEvening(AuthoringEdit edit, List<skir.ResourceId> targets) {
  for (final id in targets) {
    final path = editorRootPath.field("page");
    final endpoint = edit.catalog!
        .endpointBindingsAt(edit.resources[id]!.configuration, path)
        .single
        .template
        .endpoint;
    edit.connect(
      skir.LinkOccurrence(
        id: skir.LinkOccurrenceId(
          endpoint: endpoint,
          location: skir.ValueLocation(resource: id, path: path),
        ),
        source: id,
        target: skir.LinkTarget(
          resource: compiledEntryDestinationId,
          opposite: null,
        ),
      ),
      compiledEntryDestinationId,
    );
  }
}

@widgetbook.UseCase(name: "Hover states", type: ResourceDropHighlight)
Widget resourceDropHighlightStory(BuildContext context) {
  final state = context.knobs.object.dropdown(
    label: "State",
    options: const ["Idle", "Accepted", "Rejected"],
    initialOption: "Accepted",
  );
  final hint = context.knobs.string(label: "Hint", initialValue: "Move here");
  return Story(
    const [],
    at: PanelLocation.component(
      SizedBox(
        width: 280,
        child: ResourceDropHighlight(
          hover: switch (state) {
            "Accepted" => ResourceDropHover(accepted: true, hint: hint),
            "Rejected" => const ResourceDropHover(rejected: true),
            _ => ResourceDropHover.idle,
          },
          child: const ListTile(
            leading: Icon(Icons.article_outlined),
            title: Text("Village evening"),
          ),
        ),
      ),
    ),
  );
}

@widgetbook.UseCase(name: "Several offers", type: DropChooser)
Widget dropChooserStory(BuildContext context) {
  final count = context.knobs.int.slider(
    label: "Offers",
    initialValue: 2,
    min: 2,
    max: 3,
  );
  return Story(
    const [],
    at: PanelLocation.component(
      DropChooser(
        offers: [
          DropOffer.operation(
            operation: _definition(
              "MoveToOwner",
              label: "Move to",
              icon: "mdi:folder-move-outline",
              order: 10,
              hint: "Move here",
            ),
            destination: compiledEntryDestinationId,
          ),
          DropOffer.operation(
            operation: _definition(
              "LinkWith",
              label: "Link with",
              icon: "mdi:link-variant",
              order: 20,
              hint: "Link",
            ),
            destination: compiledEntryDestinationId,
          ),
          if (count > 2)
            DropOffer.operation(
              operation: _definition(
                "LinkWithDuplicate",
                label: "Link with duplicate",
                icon: "mdi:link-variant-plus",
                order: 30,
                hint: "Link a copy",
              ),
              destination: compiledEntryDestinationId,
            ),
        ],
        onChoose: (_) {},
      ),
    ),
  );
}

@widgetbook.UseCase(name: "Dragged resources", type: ResourceDragFeedback)
Widget resourceDragFeedbackStory(BuildContext context) => Story(
  const [],
  at: PanelLocation.component(
    ResourceDragFeedback(
      label: context.knobs.string(label: "Label", initialValue: "Greeting"),
      icon: skir.Icon.wrapIconify("mdi:message-text-outline"),
      accent: Colors.teal,
      count: context.knobs.int.slider(
        label: "Resources",
        initialValue: 1,
        min: 1,
        max: 5,
      ),
    ),
  ),
);

skir.ResourceOperationDefinition _definition(
  String name, {
  required String label,
  required String icon,
  required int order,
  required String hint,
}) => skir.ResourceOperationDefinition(
  id: skir.ResourceOperationId(
    artifact: "typewriter",
    sourcePart: "main",
    declaration: "com.typewritermc.operations.$name",
  ),
  targets: skir.OperationTargets(
    subject: skir.ResourceTarget.anyResource,
    cardinality: skir.OperationCardinality.selection,
  ),
  capability: skir.CapabilityId(value: "operations:$name"),
  drop: skir.OperationDrop(
    input: editorRootPath.field("destination"),
    hint: hint,
  ),
  presentation: skir.OperationPresentation(
    label: label,
    description: "Apply to the dragged resources",
    icon: icon,
    group: skir.OperationGroup.organize,
    order: order,
    tone: skir.HeaderActionTone.neutral,
    confirmation: null,
    inspector: skir.OperationInspector.hidden,
    shortcut: null,
  ),
);
