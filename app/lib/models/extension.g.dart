// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'extension.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ExtensionImpl _$$ExtensionImplFromJson(Map<String, dynamic> json) =>
    _$ExtensionImpl(
      extension:
          ExtensionInfo.fromJson(json['extension'] as Map<String, dynamic>),
      entries: (json['entries'] as List<dynamic>?)
              ?.map((e) => EntryBlueprint.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      globalContextKeys: (json['globalContextKeys'] as List<dynamic>?)
              ?.map((e) => GlobalContextKey.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      translations: (json['translations'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, Map<String, String>.from(e as Map)),
          ) ??
          const {},
    );

Map<String, dynamic> _$$ExtensionImplToJson(_$ExtensionImpl instance) =>
    <String, dynamic>{
      'extension': instance.extension.toJson(),
      'entries': instance.entries.map((e) => e.toJson()).toList(),
      'globalContextKeys':
          instance.globalContextKeys.map((e) => e.toJson()).toList(),
      'translations': instance.translations,
    };

_$ExtensionInfoImpl _$$ExtensionInfoImplFromJson(Map<String, dynamic> json) =>
    _$ExtensionInfoImpl(
      name: json['name'] as String,
      shortDescription: json['shortDescription'] as String,
      description: json['description'] as String,
      version: json['version'] as String,
      key: json['key'] as String? ?? "",
    );

Map<String, dynamic> _$$ExtensionInfoImplToJson(_$ExtensionInfoImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'shortDescription': instance.shortDescription,
      'description': instance.description,
      'version': instance.version,
      'key': instance.key,
    };

_$GlobalContextKeyImpl _$$GlobalContextKeyImplFromJson(
        Map<String, dynamic> json) =>
    _$GlobalContextKeyImpl(
      name: json['name'] as String,
      klassName: json['klassName'] as String,
      blueprint:
          DataBlueprint.fromJson(json['blueprint'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$GlobalContextKeyImplToJson(
        _$GlobalContextKeyImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'klassName': instance.klassName,
      'blueprint': instance.blueprint.toJson(),
    };

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$extensionsHash() => r'10f9edbc062d3761b5fdbeb067a30725925444ba';

/// A generated provider to fetch and cache a list of [Extension]s.
///
/// Copied from [extensions].
@ProviderFor(extensions)
final extensionsProvider = AutoDisposeProvider<List<Extension>>.internal(
  extensions,
  name: r'extensionsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$extensionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ExtensionsRef = AutoDisposeProviderRef<List<Extension>>;
String _$globalContextKeysHash() => r'458b1e989a01e07d6a1258b5209569633d2ef92b';

/// See also [globalContextKeys].
@ProviderFor(globalContextKeys)
final globalContextKeysProvider =
    AutoDisposeProvider<List<GlobalContextKey>>.internal(
  globalContextKeys,
  name: r'globalContextKeysProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$globalContextKeysHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef GlobalContextKeysRef = AutoDisposeProviderRef<List<GlobalContextKey>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
