import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Local storage codec for committed portable search selections.
///
/// Only generated wire values and provider identity are persisted. Decoding
/// rejects malformed values and named types absent from the active checked
/// catalog before history enters the result tree.
final class PortableLocalSearchHistoryStorage implements SearchHistoryStorage {
  const PortableLocalSearchHistoryStorage({required this.catalog});

  final CheckedEditorCatalog catalog;

  @override
  Future<List<SearchResult>> loadValidResults({
    required String key,
    required int capacity,
  }) async {
    final encoded = localStorage.getItem(_storageKey(key));
    if (encoded == null) return const [];
    try {
      final document = jsonDecode(encoded);
      if (document is! List<Object?>) return const [];
      return document
          .map(_decode)
          .nonNulls
          .take(capacity)
          .toList(growable: false);
    } on Object {
      return const [];
    }
  }

  @override
  Future<void> replaceResults({
    required String key,
    required List<SearchResult> results,
  }) async {
    final encoded = results.map(_encode).nonNulls.toList(growable: false);
    localStorage.setItem(_storageKey(key), jsonEncode(encoded));
  }

  String _storageKey(String key) => "portable_search_history:$key";

  Map<String, Object?>? _encode(SearchResult result) {
    final payload = result.payload;
    if (payload is! PortableSearchPayload) return null;
    final common = <String, Object?>{
      "id": result.id,
      "title": result.title,
      "subtitle": result.subtitle,
      "provider": payload.providerPath,
    };
    return switch (payload) {
      PortableMappedSearchPayload(
        :final sourceValue,
        :final selectedValue,
        :final mapping,
        :final distinctKey,
      ) =>
        {
          ...common,
          "kind": "mapped",
          "source": base64Encode(
            skir.DataValue.serializer.toBytes(sourceValue),
          ),
          "selected": base64Encode(
            skir.DataValue.serializer.toBytes(selectedValue),
          ),
          "mapping": base64Encode(
            skir.SearchResultMapping.serializer.toBytes(mapping),
          ),
          "distinctKey": distinctKey,
        },
      PortableCustomSearchPayload(:final selectedValue) => {
        ...common,
        "kind": "custom",
        "selected": base64Encode(
          skir.DataValue.serializer.toBytes(selectedValue),
        ),
      },
    };
  }

  SearchResult? _decode(Object? encoded) {
    if (encoded is! Map<String, Object?>) return null;
    final id = encoded["id"];
    final provider = encoded["provider"];
    final kind = encoded["kind"];
    final selected = encoded["selected"];
    if (id is! String ||
        id.isEmpty ||
        provider is! String ||
        provider.isEmpty ||
        selected is! String ||
        kind is! String) {
      return null;
    }
    try {
      final selectedValue = skir.DataValue.serializer.fromBytes(
        base64Decode(selected),
      );
      if (!_availableNamedValue(selectedValue)) {
        return null;
      }
      final payload = switch (kind) {
        "mapped" => _decodeMapped(encoded, provider, selectedValue),
        "custom" => PortableSearchPayload.custom(
          selectedValue: selectedValue,
          providerPath: provider,
          query: SearchQueryContext.empty,
        ),
        _ => null,
      };
      if (payload == null) return null;
      return SearchResult(
        id: id,
        type: portableSearchResultType,
        payload: payload,
        title: encoded["title"] as String?,
        subtitle: encoded["subtitle"] as String?,
      );
    } on Object {
      return null;
    }
  }

  PortableSearchPayload? _decodeMapped(
    Map<String, Object?> encoded,
    String provider,
    skir.DataValue selectedValue,
  ) {
    final source = encoded["source"];
    final mapping = encoded["mapping"];
    final distinctKey = encoded["distinctKey"];
    if (source is! String ||
        mapping is! String ||
        distinctKey is! String ||
        distinctKey.isEmpty) {
      return null;
    }
    final sourceValue = skir.DataValue.serializer.fromBytes(
      base64Decode(source),
    );
    if (!_availableNamedValue(sourceValue)) return null;
    return PortableSearchPayload.mapped(
      sourceValue: sourceValue,
      selectedValue: selectedValue,
      mapping: skir.SearchResultMapping.serializer.fromBytes(
        base64Decode(mapping),
      ),
      providerPath: provider,
      distinctKey: distinctKey,
      query: SearchQueryContext.empty,
    );
  }

  bool _availableNamedValue(skir.DataValue value) {
    final payload = value.authoredPayload;
    if (value case skir.DataValue_namedWrapper(:final value)) {
      final published = catalog.published(value.actualType.definition);
      if (published == null ||
          published.status != skir.DeclarationStatus.ready) {
        return false;
      }
      return _availableNamedValue(value.payload);
    }
    return switch (payload) {
      skir.DataValue_listValueWrapper(:final value) ||
      skir.DataValue_setValueWrapper(
        :final value,
      ) => value.items.every((item) => _availableNamedValue(item.value)),
      skir.DataValue_mapValueWrapper(:final value) => value.rows.every(
        (row) =>
            _availableNamedValue(row.key) && _availableNamedValue(row.value),
      ),
      skir.DataValue_recordWrapper(:final value) => value.fields.every(
        (field) => _availableNamedValue(field.value),
      ),
      _ => true,
    };
  }
}
