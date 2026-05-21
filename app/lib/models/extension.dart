import "package:flutter/foundation.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter/models/book.dart";
import "package:typewriter/models/entry_blueprint.dart";

part "extension.freezed.dart";
part "extension.g.dart";

/// A generated provider to fetch and cache a list of [Extension]s.
@riverpod
List<Extension> extensions(Ref ref) => ref.watch(bookProvider).extensions;

@riverpod
List<GlobalContextKey> globalContextKeys(Ref ref) =>
    ref.watch(extensionsProvider).expand((e) => e.globalContextKeys).toList();

/// A data model that represents an extension.
@freezed
class Extension with _$Extension {
  const factory Extension({
    required ExtensionInfo extension,
    @Default([]) List<EntryBlueprint> entries,
    @Default([]) List<GlobalContextKey> globalContextKeys,
    @Default({}) Map<String, Map<String, String>> translations,
  }) = _Extension;

  factory Extension.fromJson(Map<String, dynamic> json) =>
      _$ExtensionFromJson(json);
}

@freezed
class ExtensionInfo with _$ExtensionInfo {
  const factory ExtensionInfo({
    required String name,
    required String shortDescription,
    required String description,
    required String version,
    @Default("") String key, // Unique extension identifier for translations
  }) = _ExtensionInfo;

  factory ExtensionInfo.fromJson(Map<String, dynamic> json) =>
      _$ExtensionInfoFromJson(json);
}

@freezed
class GlobalContextKey with _$GlobalContextKey {
  const factory GlobalContextKey({
    required String name,
    required String klassName,
    required DataBlueprint blueprint,
  }) = _GlobalContextKey;

  factory GlobalContextKey.fromJson(Map<String, dynamic> json) =>
      _$GlobalContextKeyFromJson(json);
}
