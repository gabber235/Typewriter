import "package:typewriter_panel/logic/search/query/query.dart";
import "package:typewriter_panel/utils/color.dart";

const List<String> _roleSuggestionValues = ["admin", "editor", "viewer"];
const List<String> _statusSuggestionValues = ["active", "archived", "draft"];
const List<String> _typeSuggestionValues = ["quest", "book", "chapter"];

final List<QuerySelectorDefinition> mockQuerySelectors = [
  KeyValueSelectorDefinition(
    id: "tag",
    key: "#",
    multiplicity: QueryMultiplicity.single,
    value: QuerySelectorValue.enumValue(_typeSuggestionValues),
    color: safeColors[4],
  ),
  KeyValueSelectorDefinition(
    id: "user",
    key: "@",
    value: QuerySelectorValue.enumValue(_roleSuggestionValues),
    color: safeColors[6],
  ),
  KeyValueSelectorDefinition(id: "free", key: "~"),
  KeyValueSelectorDefinition(
    id: "name",
    key: "name:",
    multiplicity: QueryMultiplicity.single,
  ),
  KeyValueSelectorDefinition(
    id: "id",
    key: "id:",
    multiplicity: QueryMultiplicity.single,
    color: safeColors[7],
  ),
  KeyValueSelectorDefinition(
    id: "role",
    key: "role:",
    value: QuerySelectorValue.enumValue(_roleSuggestionValues),
    color: safeColors[6],
  ),
  KeyValueSelectorDefinition(
    id: "status",
    key: "status:",
    value: QuerySelectorValue.enumValue(_statusSuggestionValues),
    color: safeColors[8],
  ),
  KeyValueSelectorDefinition(
    id: "type",
    key: "type:",
    multiplicity: QueryMultiplicity.single,
    value: QuerySelectorValue.enumValue(_typeSuggestionValues),
    color: safeColors[4],
  ),
];
