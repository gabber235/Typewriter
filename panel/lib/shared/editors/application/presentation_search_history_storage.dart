import "dart:convert";

import "package:localstorage/localstorage.dart";
import "package:typewriter_panel/typewriter_panel.dart";

abstract interface class PresentationSearchHistoryPersistence {
  String? read(String key);

  void write(String key, String value);
}

final class LocalPresentationSearchHistoryPersistence
    implements PresentationSearchHistoryPersistence {
  const LocalPresentationSearchHistoryPersistence();

  @override
  String? read(String key) => localStorage.getItem(key);

  @override
  void write(String key, String value) => localStorage.setItem(key, value);
}

final class MemoryPresentationSearchHistoryPersistence
    implements PresentationSearchHistoryPersistence {
  final Map<String, String> values = {};

  @override
  String? read(String key) => values[key];

  @override
  void write(String key, String value) => values[key] = value;
}

final class PresentationSearchHistoryDefinition {
  const PresentationSearchHistoryDefinition({
    required this.mapping,
    required this.bindingIds,
  });

  final SearchResultMapping mapping;
  final Set<BindingId> bindingIds;
}

final class PresentationSearchHistoryStorage implements SearchHistoryStorage {
  PresentationSearchHistoryStorage({
    required this.namespace,
    required this.expressions,
    required this.registry,
    this.persistence = const LocalPresentationSearchHistoryPersistence(),
  });

  final String namespace;
  final ExpressionContext expressions;
  final TypeRegistry registry;
  final PresentationSearchHistoryPersistence persistence;
  final Map<String, PresentationSearchHistoryDefinition> _definitions = {};

  void register({
    required String providerKey,
    required SearchResultMapping mapping,
    Iterable<BindingId> contextBindingIds = const [],
  }) {
    _definitions[providerKey] = PresentationSearchHistoryDefinition(
      mapping: mapping,
      bindingIds: {mapping.bindingId, ...contextBindingIds},
    );
  }

  @override
  Future<List<SearchResult>> loadValidResults({
    required String key,
    required int capacity,
  }) async {
    try {
      final encoded = persistence.read(_storageKey(key));
      if (encoded == null) return const [];
      final document = jsonDecode(encoded);
      if (document is! Map<String, dynamic> || document["version"] != 1) {
        return const [];
      }
      final entries = document["results"];
      if (entries is! List) return const [];
      final results = <SearchResult>[];
      for (final entry in entries) {
        final result = _decode(entry);
        if (result != null) results.add(result);
        if (results.length == capacity) break;
      }
      return results;
    } on Object {
      return const [];
    }
  }

  @override
  Future<void> replaceResults({
    required String key,
    required List<SearchResult> results,
  }) async {
    final encoded = results.map(_encode).whereType<Map<String, Object?>>();
    persistence.write(
      _storageKey(key),
      jsonEncode({"version": 1, "results": encoded.toList()}),
    );
  }

  Map<String, Object?>? _encode(SearchResult result) {
    final payload = result.payload;
    if (payload is! PresentationSearchResultPayload) return null;
    final definition = _definitions[payload.providerKey];
    if (definition == null) return null;
    final bindings = <Map<String, Object?>>[];
    for (final id in definition.bindingIds) {
      final binding = payload.expressions.bindings.bindings[id];
      if (binding == null) return null;
      bindings.add({
        "id": id.value,
        "type": const TypeExpressionJsonConverter().toJson(binding.type),
        "value": const DataValueJsonConverter().toJson(binding.value),
      });
    }
    return {
      "id": result.id,
      "title": result.title,
      "subtitle": result.subtitle,
      "provider": payload.providerKey,
      "selectedType": const TypeExpressionJsonConverter().toJson(
        definition.mapping.selectedValue.resultType,
      ),
      "selected": const DataValueJsonConverter().toJson(payload.selectedValue),
      "bindings": bindings,
    };
  }

  SearchResult? _decode(Object? source) {
    if (source is! Map) return null;
    final json = source.cast<String, Object?>();
    final providerKey = json["provider"];
    final id = json["id"];
    if (providerKey is! String || id is! String || id.isEmpty) return null;
    final definition = _definitions[providerKey];
    if (definition == null) return null;
    final selectedTypeJson = json["selectedType"];
    final selectedJson = json["selected"];
    if (selectedTypeJson is! Map || selectedJson is! Map) return null;
    final storedType = const TypeExpressionJsonConverter().fromJson(
      selectedTypeJson.cast<String, Object?>(),
    );
    if (storedType != definition.mapping.selectedValue.resultType) return null;
    final selected = const DataValueJsonConverter().fromJson(
      selectedJson.cast<String, Object?>(),
    );
    if (selected.validateAgainst(storedType, registry: registry).isNotEmpty) {
      return null;
    }
    final restored = <BindingId, BindingSnapshot>{};
    final bindings = json["bindings"];
    if (bindings is! List) return null;
    for (final entry in bindings) {
      if (entry is! Map) return null;
      final value = entry.cast<String, Object?>();
      final bindingId = value["id"];
      if (bindingId is! int) return null;
      final id = BindingId(bindingId);
      if (!definition.bindingIds.contains(id)) continue;
      final typeJson = value["type"];
      final dataJson = value["value"];
      if (typeJson is! Map || dataJson is! Map) return null;
      final type = const TypeExpressionJsonConverter().fromJson(
        typeJson.cast<String, Object?>(),
      );
      final data = const DataValueJsonConverter().fromJson(
        dataJson.cast<String, Object?>(),
      );
      if (data.validateAgainst(type, registry: registry).isNotEmpty) {
        return null;
      }
      restored[id] = BindingSnapshot(
        type: type,
        value: data,
        revision: 0,
        writable: false,
      );
    }
    if (!restored.keys.toSet().containsAll(definition.bindingIds)) return null;
    final context = ExpressionContext(
      bindings: BindingEnvironment({
        ...expressions.bindings.bindings,
        ...restored,
      }),
      conversions: expressions.conversions,
    );
    return SearchResult(
      id: id,
      type: presentationSearchResultType,
      payload: PresentationSearchResultPayload(
        selectedValue: selected,
        presentation: definition.mapping.presentation,
        expressions: context,
        providerKey: providerKey,
      ),
      title: json["title"] as String?,
      subtitle: json["subtitle"] as String?,
    );
  }

  String _storageKey(String key) => "editor.searchHistory.v1.$namespace.$key";
}
