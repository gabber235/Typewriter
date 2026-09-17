import "package:flutter/foundation.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/material_symbols.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "realm_search_commands.freezed.dart";

const openRealmCommandId = SearchCommandId("realm.open");

SearchCommand openRealmCommand({
  required skir.RecordId organizationId,
  required ValueListenable<AsyncValue<Map<skir.RecordId, bool>>> availability,
}) => SearchCommand.single<TopologyRealm>(
  id: openRealmCommandId,
  presentation: const SearchCommandPresentation(
    label: "Open Realm",
    icon: MaterialSymbols.open_in_new_rounded,
  ),
  matcher: const SearchResultMatcher(realmSearchResultType),
  dependencies: [availability],
  evaluate: (realm, target) => switch (availability.value) {
    AsyncData(:final value) when value[realm.realmId] == true =>
      const SearchCommandState.enabled(),
    AsyncLoading() => const SearchCommandState.disabled(
      "Checking realm availability",
    ),
    _ => const SearchCommandState.hidden(),
  },
  execute: (context, realm, target) async => SearchCommandResult.completed(
    hostEffects: [OpenRealmEffect(organizationId, realm.realmId)],
  ),
);

@freezed
abstract class OpenRealmEffect
    with _$OpenRealmEffect
    implements SearchHostEffect {
  const factory OpenRealmEffect(
    skir.RecordId organizationId,
    skir.RecordId realmId,
  ) = _OpenRealmEffect;
}
