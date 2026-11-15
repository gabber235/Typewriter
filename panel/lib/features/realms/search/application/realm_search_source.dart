import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

const realmSearchResultType = SearchResultType(
  id: "realm",
  rowRendererId: "realm",
  label: "Realm",
);

/// Searches the topology's Realms by their record id without probing runtime
/// readiness. An empty search lists them all, and the known Realms stay listed
/// while the topology loads again or reports an error. Commands separately
/// gate opening a Realm on availability.
ListSearchSource<skir.RealmInstance> realmsSearchSource(
  ValueListenable<AsyncValue<List<skir.RealmInstance>>> realms,
) => ListSearchSource<skir.RealmInstance>(
  items: realms,
  type: realmSearchResultType,
  sectionId: "realms",
  title: "Realms",
  listsWithoutQuery: true,
  retainsStale: true,
  idOf: (realm) => realm.realmId.toSurrealQl(),
  titleOf: (realm) => realm.realmId.toSurrealQl(),
  termsOf: (realm) => [realm.realmId.toSurrealQl()],
);
