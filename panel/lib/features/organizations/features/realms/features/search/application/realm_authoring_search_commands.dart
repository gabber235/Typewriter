import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "realm_authoring_search_commands.freezed.dart";

const openAuthoringBookCommandId = SearchCommandId("authoring.book.open");
const openAuthoringTagCommandId = SearchCommandId("authoring.tag.open");
const openAuthoringPageCommandId = SearchCommandId("authoring.page.open");
const openAuthoringElementCommandId = SearchCommandId("authoring.element.open");

List<SearchCommand> openAuthoringCommands(
  skir.RecordId organizationId,
  skir.RecordId realmId,
) => [
  _openAuthoringCommand<AuthoringSearchResultPayload>(
    id: openAuthoringBookCommandId,
    type: authoringBookSearchResultType,
    effect: (value) => OpenAuthoringBookEffect(
      organizationId: organizationId,
      realmId: realmId,
      bookId: value.id,
    ),
  ),
  _openAuthoringCommand<AuthoringSearchResultPayload>(
    id: openAuthoringTagCommandId,
    type: authoringTagSearchResultType,
    effect: (value) => OpenAuthoringTagEffect(
      organizationId: organizationId,
      realmId: realmId,
      tagId: value.id,
    ),
  ),
  _openAuthoringCommand<AuthoringSearchResultPayload>(
    id: openAuthoringPageCommandId,
    type: authoringPageSearchResultType,
    effect: (value) => OpenAuthoringPageEffect(
      organizationId: organizationId,
      realmId: realmId,
      bookId: value.owner!,
      pageId: value.id,
    ),
  ),
  _openAuthoringCommand<AuthoringSearchResultPayload>(
    id: openAuthoringElementCommandId,
    type: authoringElementSearchResultType,
    effect: (value) => OpenAuthoringElementEffect(
      organizationId: organizationId,
      realmId: realmId,
      bookId: value.contextReference("book")!,
      pageId: value.owner!,
      elementIdentifier: value.elementIdentifier,
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
abstract class OpenAuthoringBookEffect
    with _$OpenAuthoringBookEffect
    implements SearchHostEffect {
  const factory OpenAuthoringBookEffect({
    required skir.RecordId organizationId,
    required skir.RecordId realmId,
    required skir.ResourceId bookId,
  }) = _OpenAuthoringBookEffect;
}

@freezed
abstract class OpenAuthoringTagEffect
    with _$OpenAuthoringTagEffect
    implements SearchHostEffect {
  const factory OpenAuthoringTagEffect({
    required skir.RecordId organizationId,
    required skir.RecordId realmId,
    required skir.ResourceId tagId,
  }) = _OpenAuthoringTagEffect;
}

@freezed
abstract class OpenAuthoringPageEffect
    with _$OpenAuthoringPageEffect
    implements SearchHostEffect {
  const factory OpenAuthoringPageEffect({
    required skir.RecordId organizationId,
    required skir.RecordId realmId,
    required skir.ResourceId bookId,
    required skir.ResourceId pageId,
  }) = _OpenAuthoringPageEffect;
}

@freezed
abstract class OpenAuthoringElementEffect
    with _$OpenAuthoringElementEffect
    implements SearchHostEffect {
  const factory OpenAuthoringElementEffect({
    required skir.RecordId organizationId,
    required skir.RecordId realmId,
    required skir.ResourceId bookId,
    required skir.ResourceId pageId,
    required SelectableIdentifier? elementIdentifier,
  }) = _OpenAuthoringElementEffect;
}

extension on AuthoringSearchResultPayload {
  SelectableIdentifier? get elementIdentifier {
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
    return names.contains("Entry")
        ? EntryIdentifier(id.id, pageId: pageId)
        : CueIdentifier(pageId: pageId, id: id.id);
  }
}
