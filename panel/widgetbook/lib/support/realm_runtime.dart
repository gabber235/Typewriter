import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

/// Local realm capabilities for stories that exercise reference authoring.
EditorRealmRuntime storyRealmRuntime(Iterable<Tag> tags) {
  final values = tags.toList(growable: false);
  final byId = {for (final tag in values) tag.tagId: tag};
  return EditorRealmRuntime(
    actions: RealmActionCapabilities(
      execute: (_, _) async => const RealmCommandResult.success([]),
    ),
    presentationSearch: RealmPresentationSearchCapabilities(
      source: ({
        required provider,
        required queryBindingId,
        required expressions,
        required registry,
        required budget,
        required providerKey,
      }) => MockSearchSource(),
    ),
    references: ReferenceAuthoringCapabilities(
      search: ({required target, required origins, required registry}) =>
          MockSearchSource(
            nodes: [
              for (final tag in values)
                SearchNode.result(
                  result: SearchResult(
                    id: tag.tagId.value,
                    type: presentationSearchResultType,
                    title: tag.name,
                    payload: PresentationSearchResultPayload(
                      selectedValue: ReferenceValue(tag.tagId),
                      presentation: PresentationNode(
                        id: "widgetbook.reference.${tag.tagId.value}",
                        element: TextElement(tag.name.asStringLiteral),
                      ),
                      expressions: const ExpressionContext(
                        bindings: BindingEnvironment({}),
                      ),
                      providerKey: "widgetbook.references",
                    ),
                  ),
                ),
            ],
          ),
      resolve: ({required target, required ids, required registry}) async => [
        for (final id in ids)
          ReferenceResourceSummary(
            id: id,
            exists: byId.containsKey(id),
            title: byId[id]?.name,
          ),
      ],
    ),
  );
}
