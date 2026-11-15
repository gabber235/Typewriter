/// Composable [SearchSource] decorators and adapters.
///
/// Sources transform query snapshots, result trees, or source lifecycle without
/// taking ownership of the search controller's selection and action state.
library;

export "cached_search_source.dart";
export "debounced_search_source.dart";
export "delegating_search_source.dart";
export "distinct_search_source.dart";
export "gated_search_source.dart";
export "historical_search_source.dart";
export "limited_search_source.dart";
export "list_search_source.dart";
export "merged_search_source.dart";
export "ranked_search_source.dart";
export "section_search_source.dart";
