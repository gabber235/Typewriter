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
  _openAuthoringCommand<skir.AuthoringSearchBook>(
    id: openAuthoringBookCommandId,
    type: authoringBookSearchResultType,
    effect: (value) => OpenAuthoringBookEffect(
      organizationId: organizationId,
      realmId: realmId,
      bookId: value.id,
    ),
  ),
  _openAuthoringCommand<skir.AuthoringSearchTag>(
    id: openAuthoringTagCommandId,
    type: authoringTagSearchResultType,
    effect: (value) => OpenAuthoringTagEffect(
      organizationId: organizationId,
      realmId: realmId,
      tagId: value.id,
    ),
  ),
  _openAuthoringCommand<skir.AuthoringSearchPage>(
    id: openAuthoringPageCommandId,
    type: authoringPageSearchResultType,
    effect: (value) => OpenAuthoringPageEffect(
      organizationId: organizationId,
      realmId: realmId,
      bookId: value.book.id,
      pageId: value.id,
    ),
  ),
  _openAuthoringCommand<skir.AuthoringSearchElement>(
    id: openAuthoringElementCommandId,
    type: authoringElementSearchResultType,
    effect: (value) => OpenAuthoringElementEffect(
      organizationId: organizationId,
      realmId: realmId,
      bookId: value.page.book.id,
      pageId: value.page.id,
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
    required skir.RecordId bookId,
  }) = _OpenAuthoringBookEffect;
}

@freezed
abstract class OpenAuthoringTagEffect
    with _$OpenAuthoringTagEffect
    implements SearchHostEffect {
  const factory OpenAuthoringTagEffect({
    required skir.RecordId organizationId,
    required skir.RecordId realmId,
    required skir.RecordId tagId,
  }) = _OpenAuthoringTagEffect;
}

@freezed
abstract class OpenAuthoringPageEffect
    with _$OpenAuthoringPageEffect
    implements SearchHostEffect {
  const factory OpenAuthoringPageEffect({
    required skir.RecordId organizationId,
    required skir.RecordId realmId,
    required skir.RecordId bookId,
    required skir.RecordId pageId,
  }) = _OpenAuthoringPageEffect;
}

@freezed
abstract class OpenAuthoringElementEffect
    with _$OpenAuthoringElementEffect
    implements SearchHostEffect {
  const factory OpenAuthoringElementEffect({
    required skir.RecordId organizationId,
    required skir.RecordId realmId,
    required skir.RecordId bookId,
    required skir.RecordId pageId,
    required SelectableIdentifier? elementIdentifier,
  }) = _OpenAuthoringElementEffect;
}

extension on skir.AuthoringSearchElement {
  SelectableIdentifier? get elementIdentifier => switch (placement) {
    skir.ElementPlacement_graphWrapper() ||
    skir.ElementPlacement_timelineEntryWrapper() => EntryIdentifier(
      id.id,
      pageId: page.id.id,
    ),
    skir.ElementPlacement_timelineSegmentWrapper() ||
    skir.ElementPlacement_timelineKeyframeWrapper() => CueIdentifier(
      pageId: page.id.id,
      id: id.id,
    ),
    skir.ElementPlacement_unknown() => null,
  };
}
