import "package:collection/collection.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "realm_authoring_search_commands.freezed.dart";

const openAuthoringResourceCommandId = SearchCommandId(
  "authoring.resource.open",
);

List<SearchCommand> openAuthoringCommands(
  skir.RecordId organizationId,
  skir.RecordId realmId,
) => [
  _openAuthoringCommand<AuthoringSearchResultPayload>(
    id: openAuthoringResourceCommandId,
    type: authoringResourceSearchResultType,
    effect: (value) => OpenAuthoringResourceEffect(
      organizationId: organizationId,
      realmId: realmId,
      resourceId: value.id,
      definition: value.definition,
      bookId: value.coreBookId,
      ownerId: value.owner,
      nestedIdentifier: value.nestedIdentifier,
    ),
  ),
];

SearchCommand _openAuthoringCommand<T extends Object>({
  required SearchCommandId id,
  required SearchResultType type,
  required SearchHostEffect Function(T value) effect,
}) => SearchCommand.single<T>(
  id: id,
  presentation: const SearchCommandPresentation(label: "Open"),
  matcher: SearchResultMatcher(type),
  execute: (context, value, target) async =>
      SearchCommandResult.completed(hostEffects: [effect(value)]),
);

@freezed
abstract class OpenAuthoringResourceEffect
    with _$OpenAuthoringResourceEffect
    implements SearchHostEffect {
  const factory OpenAuthoringResourceEffect({
    required skir.RecordId organizationId,
    required skir.RecordId realmId,
    required skir.ResourceId resourceId,
    required ResourceDefinitionId definition,
    required skir.ResourceId? bookId,
    required skir.ResourceId? ownerId,
    required SelectableIdentifier? nestedIdentifier,
  }) = _OpenAuthoringResourceEffect;
}

extension on AuthoringSearchResultPayload {
  skir.ResourceId? get coreBookId => switch (definition) {
    CoreResourceDefinitionIds.book => id,
    CoreResourceDefinitionIds.page => ownerPath.firstOrNull,
    CoreResourceDefinitionIds.element => ownerPath.lastOrNull,
    _ => null,
  };

  SelectableIdentifier? get nestedIdentifier {
    final pageId = owner?.id;
    if (pageId == null) return null;
    final registry = TypeRegistry(presentation.model.catalog);
    final resolved = registry
        .resolveExact(subject.content.rootType)
        .valueOrNull;
    final names = {
      subject.content.rootType.id,
      ...?resolved?.ancestors.map((type) => type.id),
    }.whereType<QualifiedTypeId>().map((id) => id.name).toSet();
    if (names.contains("Entry")) {
      return EntryIdentifier(id.id, pageId: pageId);
    }
    if (names.contains("Cue")) {
      return CueIdentifier(pageId: pageId, id: id.id);
    }
    return null;
  }
}
