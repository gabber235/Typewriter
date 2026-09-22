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
      ownerPath: value.ownerPath,
      rootType: value.subject.content.rootType,
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
    required List<skir.ResourceId> ownerPath,
    required ResolvedTypeRef rootType,
  }) = _OpenAuthoringResourceEffect;
}
