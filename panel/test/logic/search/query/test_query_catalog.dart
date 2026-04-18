import "package:typewriter_panel/logic/search/query/query.dart";

List<QuerySelectorDefinition> buildDefaultQuerySelectorsForTest() {
  return const <QuerySelectorDefinition>[
    SymbolSelectorDefinition(id: "tag", symbol: "#"),
    SymbolSelectorDefinition(id: "user", symbol: "@"),
    SymbolSelectorDefinition(id: "type_symbol", symbol: "~"),
    KeyValueSelectorDefinition(id: "title", key: "title"),
    KeyValueSelectorDefinition(id: "name", key: "name"),
    KeyValueSelectorDefinition(
      id: "id",
      key: "id",
      multiplicity: QueryMultiplicity.single,
    ),
    KeyValueSelectorDefinition(id: "author", key: "author"),
    KeyValueSelectorDefinition(id: "owner", key: "owner"),
    KeyValueSelectorDefinition(
      id: "role",
      key: "role",
      valueMode: QueryValueMode.enumValue,
    ),
    KeyValueSelectorDefinition(
      id: "status",
      key: "status",
      valueMode: QueryValueMode.enumValue,
    ),
    KeyValueSelectorDefinition(
      id: "type",
      key: "type",
      valueMode: QueryValueMode.enumValue,
    ),
    KeyValueSelectorDefinition(id: "chapter", key: "chapter"),
    KeyValueSelectorDefinition(id: "page", key: "page"),
    KeyValueSelectorDefinition(id: "book", key: "book"),
    KeyValueSelectorDefinition(id: "lang", key: "lang"),
    KeyValueSelectorDefinition(id: "locale", key: "locale"),
    KeyValueSelectorDefinition(id: "kind", key: "kind"),
    KeyValueSelectorDefinition(id: "source", key: "source"),
    KeyValueSelectorDefinition(id: "path", key: "path"),
  ];
}
