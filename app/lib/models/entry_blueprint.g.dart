// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'entry_blueprint.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$EntryBlueprintImpl _$$EntryBlueprintImplFromJson(Map<String, dynamic> json) =>
    _$EntryBlueprintImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      extension: json['extension'] as String,
      dataBlueprint: ObjectBlueprint.fromJson(
          json['dataBlueprint'] as Map<String, dynamic>),
      color: json['color'] == null
          ? Colors.grey
          : const ColorConverter().fromJson(json['color'] as String),
      icon: json['icon'] as String? ?? TWIcons.help,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const <String>[],
      genericConstraints: (json['genericConstraints'] as List<dynamic>?)
              ?.map((e) => DataBlueprint.fromJson(e as Map<String, dynamic>))
              .toList() ??
          null,
      variableDataBlueprint: json['variableDataBlueprint'] == null
          ? null
          : DataBlueprint.fromJson(
              json['variableDataBlueprint'] as Map<String, dynamic>),
      contextKeys: (json['contextKeys'] as List<dynamic>?)
              ?.map((e) => ContextKey.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      modifiers: (json['modifiers'] as List<dynamic>?)
              ?.map((e) => EntryModifier.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      titleKey: json['titleKey'] as String? ?? "",
      descriptionKey: json['descriptionKey'] as String? ?? "",
    );

Map<String, dynamic> _$$EntryBlueprintImplToJson(
        _$EntryBlueprintImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'extension': instance.extension,
      'dataBlueprint': instance.dataBlueprint.toJson(),
      'color': const ColorConverter().toJson(instance.color),
      'icon': instance.icon,
      'tags': instance.tags,
      'genericConstraints':
          instance.genericConstraints?.map((e) => e.toJson()).toList(),
      'variableDataBlueprint': instance.variableDataBlueprint?.toJson(),
      'contextKeys': instance.contextKeys.map((e) => e.toJson()).toList(),
      'modifiers': instance.modifiers.map((e) => e.toJson()).toList(),
      'titleKey': instance.titleKey,
      'descriptionKey': instance.descriptionKey,
    };

_$DataBlueprintTypeImpl _$$DataBlueprintTypeImplFromJson(
        Map<String, dynamic> json) =>
    _$DataBlueprintTypeImpl(
      internalDefaultValue: json['default'],
      modifiers: (json['modifiers'] as List<dynamic>?)
              ?.map((e) => Modifier.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      $type: json['kind'] as String?,
    );

Map<String, dynamic> _$$DataBlueprintTypeImplToJson(
        _$DataBlueprintTypeImpl instance) =>
    <String, dynamic>{
      'default': instance.internalDefaultValue,
      'modifiers': instance.modifiers.map((e) => e.toJson()).toList(),
      'kind': instance.$type,
    };

_$PrimitiveBlueprintImpl _$$PrimitiveBlueprintImplFromJson(
        Map<String, dynamic> json) =>
    _$PrimitiveBlueprintImpl(
      type: $enumDecode(_$PrimitiveTypeEnumMap, json['type']),
      internalDefaultValue: json['default'],
      modifiers: (json['modifiers'] as List<dynamic>?)
              ?.map((e) => Modifier.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      $type: json['kind'] as String?,
    );

Map<String, dynamic> _$$PrimitiveBlueprintImplToJson(
        _$PrimitiveBlueprintImpl instance) =>
    <String, dynamic>{
      'type': _$PrimitiveTypeEnumMap[instance.type]!,
      'default': instance.internalDefaultValue,
      'modifiers': instance.modifiers.map((e) => e.toJson()).toList(),
      'kind': instance.$type,
    };

const _$PrimitiveTypeEnumMap = {
  PrimitiveType.boolean: 'boolean',
  PrimitiveType.double: 'double',
  PrimitiveType.integer: 'integer',
  PrimitiveType.string: 'string',
};

_$EnumBlueprintImpl _$$EnumBlueprintImplFromJson(Map<String, dynamic> json) =>
    _$EnumBlueprintImpl(
      values:
          (json['values'] as List<dynamic>).map((e) => e as String).toList(),
      internalDefaultValue: json['default'],
      modifiers: (json['modifiers'] as List<dynamic>?)
              ?.map((e) => Modifier.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      $type: json['kind'] as String?,
    );

Map<String, dynamic> _$$EnumBlueprintImplToJson(_$EnumBlueprintImpl instance) =>
    <String, dynamic>{
      'values': instance.values,
      'default': instance.internalDefaultValue,
      'modifiers': instance.modifiers.map((e) => e.toJson()).toList(),
      'kind': instance.$type,
    };

_$ListBlueprintImpl _$$ListBlueprintImplFromJson(Map<String, dynamic> json) =>
    _$ListBlueprintImpl(
      type: DataBlueprint.fromJson(json['type'] as Map<String, dynamic>),
      internalDefaultValue: json['default'],
      modifiers: (json['modifiers'] as List<dynamic>?)
              ?.map((e) => Modifier.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      $type: json['kind'] as String?,
    );

Map<String, dynamic> _$$ListBlueprintImplToJson(_$ListBlueprintImpl instance) =>
    <String, dynamic>{
      'type': instance.type.toJson(),
      'default': instance.internalDefaultValue,
      'modifiers': instance.modifiers.map((e) => e.toJson()).toList(),
      'kind': instance.$type,
    };

_$MapBlueprintImpl _$$MapBlueprintImplFromJson(Map<String, dynamic> json) =>
    _$MapBlueprintImpl(
      key: DataBlueprint.fromJson(json['key'] as Map<String, dynamic>),
      value: DataBlueprint.fromJson(json['value'] as Map<String, dynamic>),
      internalDefaultValue: json['default'],
      modifiers: (json['modifiers'] as List<dynamic>?)
              ?.map((e) => Modifier.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      $type: json['kind'] as String?,
    );

Map<String, dynamic> _$$MapBlueprintImplToJson(_$MapBlueprintImpl instance) =>
    <String, dynamic>{
      'key': instance.key.toJson(),
      'value': instance.value.toJson(),
      'default': instance.internalDefaultValue,
      'modifiers': instance.modifiers.map((e) => e.toJson()).toList(),
      'kind': instance.$type,
    };

_$ObjectBlueprintImpl _$$ObjectBlueprintImplFromJson(
        Map<String, dynamic> json) =>
    _$ObjectBlueprintImpl(
      fields: (json['fields'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry(k, DataBlueprint.fromJson(e as Map<String, dynamic>)),
      ),
      internalDefaultValue: json['default'],
      modifiers: (json['modifiers'] as List<dynamic>?)
              ?.map((e) => Modifier.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      $type: json['kind'] as String?,
    );

Map<String, dynamic> _$$ObjectBlueprintImplToJson(
        _$ObjectBlueprintImpl instance) =>
    <String, dynamic>{
      'fields': instance.fields.map((k, e) => MapEntry(k, e.toJson())),
      'default': instance.internalDefaultValue,
      'modifiers': instance.modifiers.map((e) => e.toJson()).toList(),
      'kind': instance.$type,
    };

_$AlgebraicBlueprintImpl _$$AlgebraicBlueprintImplFromJson(
        Map<String, dynamic> json) =>
    _$AlgebraicBlueprintImpl(
      cases: (json['cases'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry(k, DataBlueprint.fromJson(e as Map<String, dynamic>)),
      ),
      internalDefaultValue: json['default'],
      modifiers: (json['modifiers'] as List<dynamic>?)
              ?.map((e) => Modifier.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      $type: json['kind'] as String?,
    );

Map<String, dynamic> _$$AlgebraicBlueprintImplToJson(
        _$AlgebraicBlueprintImpl instance) =>
    <String, dynamic>{
      'cases': instance.cases.map((k, e) => MapEntry(k, e.toJson())),
      'default': instance.internalDefaultValue,
      'modifiers': instance.modifiers.map((e) => e.toJson()).toList(),
      'kind': instance.$type,
    };

_$CustomBlueprintImpl _$$CustomBlueprintImplFromJson(
        Map<String, dynamic> json) =>
    _$CustomBlueprintImpl(
      editor: json['editor'] as String,
      shape: DataBlueprint.fromJson(json['shape'] as Map<String, dynamic>),
      internalDefaultValue: json['default'],
      modifiers: (json['modifiers'] as List<dynamic>?)
              ?.map((e) => Modifier.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      $type: json['kind'] as String?,
    );

Map<String, dynamic> _$$CustomBlueprintImplToJson(
        _$CustomBlueprintImpl instance) =>
    <String, dynamic>{
      'editor': instance.editor,
      'shape': instance.shape.toJson(),
      'default': instance.internalDefaultValue,
      'modifiers': instance.modifiers.map((e) => e.toJson()).toList(),
      'kind': instance.$type,
    };

_$ModifierImpl _$$ModifierImplFromJson(Map<String, dynamic> json) =>
    _$ModifierImpl(
      name: json['name'] as String,
      data: json['data'],
    );

Map<String, dynamic> _$$ModifierImplToJson(_$ModifierImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'data': instance.data,
    };

_$ContextKeyImpl _$$ContextKeyImplFromJson(Map<String, dynamic> json) =>
    _$ContextKeyImpl(
      name: json['name'] as String,
      klassName: json['klassName'] as String,
      blueprint:
          DataBlueprint.fromJson(json['blueprint'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$ContextKeyImplToJson(_$ContextKeyImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'klassName': instance.klassName,
      'blueprint': instance.blueprint.toJson(),
    };

_$EmptyModifierImpl _$$EmptyModifierImplFromJson(Map<String, dynamic> json) =>
    _$EmptyModifierImpl(
      $type: json['kind'] as String?,
    );

Map<String, dynamic> _$$EmptyModifierImplToJson(_$EmptyModifierImpl instance) =>
    <String, dynamic>{
      'kind': instance.$type,
    };

_$DeprecatedModifierImpl _$$DeprecatedModifierImplFromJson(
        Map<String, dynamic> json) =>
    _$DeprecatedModifierImpl(
      reason: json['reason'] as String? ?? "",
      $type: json['kind'] as String?,
    );

Map<String, dynamic> _$$DeprecatedModifierImplToJson(
        _$DeprecatedModifierImpl instance) =>
    <String, dynamic>{
      'reason': instance.reason,
      'kind': instance.$type,
    };

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$entryBlueprintsHash() => r'7c332657f0558d980c13827627ce297ca4263865';

/// A generated provider to fetch and cache a list of all the [EntryBlueprint]s.
///
/// Copied from [entryBlueprints].
@ProviderFor(entryBlueprints)
final entryBlueprintsProvider =
    AutoDisposeProvider<List<EntryBlueprint>>.internal(
  entryBlueprints,
  name: r'entryBlueprintsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$entryBlueprintsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef EntryBlueprintsRef = AutoDisposeProviderRef<List<EntryBlueprint>>;
String _$entryBlueprintHash() => r'7db7dd388f5998fccd421ff822e75b951c8047b0';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// A generated provider to fetch and cache a specific [EntryBlueprint] by its [blueprintId].
///
/// Copied from [entryBlueprint].
@ProviderFor(entryBlueprint)
const entryBlueprintProvider = EntryBlueprintFamily();

/// A generated provider to fetch and cache a specific [EntryBlueprint] by its [blueprintId].
///
/// Copied from [entryBlueprint].
class EntryBlueprintFamily extends Family<EntryBlueprint?> {
  /// A generated provider to fetch and cache a specific [EntryBlueprint] by its [blueprintId].
  ///
  /// Copied from [entryBlueprint].
  const EntryBlueprintFamily();

  /// A generated provider to fetch and cache a specific [EntryBlueprint] by its [blueprintId].
  ///
  /// Copied from [entryBlueprint].
  EntryBlueprintProvider call(
    String blueprintId,
  ) {
    return EntryBlueprintProvider(
      blueprintId,
    );
  }

  @override
  EntryBlueprintProvider getProviderOverride(
    covariant EntryBlueprintProvider provider,
  ) {
    return call(
      provider.blueprintId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'entryBlueprintProvider';
}

/// A generated provider to fetch and cache a specific [EntryBlueprint] by its [blueprintId].
///
/// Copied from [entryBlueprint].
class EntryBlueprintProvider extends AutoDisposeProvider<EntryBlueprint?> {
  /// A generated provider to fetch and cache a specific [EntryBlueprint] by its [blueprintId].
  ///
  /// Copied from [entryBlueprint].
  EntryBlueprintProvider(
    String blueprintId,
  ) : this._internal(
          (ref) => entryBlueprint(
            ref as EntryBlueprintRef,
            blueprintId,
          ),
          from: entryBlueprintProvider,
          name: r'entryBlueprintProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$entryBlueprintHash,
          dependencies: EntryBlueprintFamily._dependencies,
          allTransitiveDependencies:
              EntryBlueprintFamily._allTransitiveDependencies,
          blueprintId: blueprintId,
        );

  EntryBlueprintProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.blueprintId,
  }) : super.internal();

  final String blueprintId;

  @override
  Override overrideWith(
    EntryBlueprint? Function(EntryBlueprintRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: EntryBlueprintProvider._internal(
        (ref) => create(ref as EntryBlueprintRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        blueprintId: blueprintId,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<EntryBlueprint?> createElement() {
    return _EntryBlueprintProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is EntryBlueprintProvider && other.blueprintId == blueprintId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, blueprintId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin EntryBlueprintRef on AutoDisposeProviderRef<EntryBlueprint?> {
  /// The parameter `blueprintId` of this provider.
  String get blueprintId;
}

class _EntryBlueprintProviderElement
    extends AutoDisposeProviderElement<EntryBlueprint?> with EntryBlueprintRef {
  _EntryBlueprintProviderElement(super.provider);

  @override
  String get blueprintId => (origin as EntryBlueprintProvider).blueprintId;
}

String _$entryBlueprintTagsHash() =>
    r'd4fb86b5fc8d9a206c4140b770b50d799923565c';

/// See also [entryBlueprintTags].
@ProviderFor(entryBlueprintTags)
const entryBlueprintTagsProvider = EntryBlueprintTagsFamily();

/// See also [entryBlueprintTags].
class EntryBlueprintTagsFamily extends Family<List<String>> {
  /// See also [entryBlueprintTags].
  const EntryBlueprintTagsFamily();

  /// See also [entryBlueprintTags].
  EntryBlueprintTagsProvider call(
    String blueprintId,
  ) {
    return EntryBlueprintTagsProvider(
      blueprintId,
    );
  }

  @override
  EntryBlueprintTagsProvider getProviderOverride(
    covariant EntryBlueprintTagsProvider provider,
  ) {
    return call(
      provider.blueprintId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'entryBlueprintTagsProvider';
}

/// See also [entryBlueprintTags].
class EntryBlueprintTagsProvider extends AutoDisposeProvider<List<String>> {
  /// See also [entryBlueprintTags].
  EntryBlueprintTagsProvider(
    String blueprintId,
  ) : this._internal(
          (ref) => entryBlueprintTags(
            ref as EntryBlueprintTagsRef,
            blueprintId,
          ),
          from: entryBlueprintTagsProvider,
          name: r'entryBlueprintTagsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$entryBlueprintTagsHash,
          dependencies: EntryBlueprintTagsFamily._dependencies,
          allTransitiveDependencies:
              EntryBlueprintTagsFamily._allTransitiveDependencies,
          blueprintId: blueprintId,
        );

  EntryBlueprintTagsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.blueprintId,
  }) : super.internal();

  final String blueprintId;

  @override
  Override overrideWith(
    List<String> Function(EntryBlueprintTagsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: EntryBlueprintTagsProvider._internal(
        (ref) => create(ref as EntryBlueprintTagsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        blueprintId: blueprintId,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<List<String>> createElement() {
    return _EntryBlueprintTagsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is EntryBlueprintTagsProvider &&
        other.blueprintId == blueprintId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, blueprintId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin EntryBlueprintTagsRef on AutoDisposeProviderRef<List<String>> {
  /// The parameter `blueprintId` of this provider.
  String get blueprintId;
}

class _EntryBlueprintTagsProviderElement
    extends AutoDisposeProviderElement<List<String>>
    with EntryBlueprintTagsRef {
  _EntryBlueprintTagsProviderElement(super.provider);

  @override
  String get blueprintId => (origin as EntryBlueprintTagsProvider).blueprintId;
}

String _$entryTagsHash() => r'8e3671fafea112b0c5718862f6cac60872444179';

/// See also [entryTags].
@ProviderFor(entryTags)
const entryTagsProvider = EntryTagsFamily();

/// See also [entryTags].
class EntryTagsFamily extends Family<List<String>> {
  /// See also [entryTags].
  const EntryTagsFamily();

  /// See also [entryTags].
  EntryTagsProvider call(
    String entryId,
  ) {
    return EntryTagsProvider(
      entryId,
    );
  }

  @override
  EntryTagsProvider getProviderOverride(
    covariant EntryTagsProvider provider,
  ) {
    return call(
      provider.entryId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'entryTagsProvider';
}

/// See also [entryTags].
class EntryTagsProvider extends AutoDisposeProvider<List<String>> {
  /// See also [entryTags].
  EntryTagsProvider(
    String entryId,
  ) : this._internal(
          (ref) => entryTags(
            ref as EntryTagsRef,
            entryId,
          ),
          from: entryTagsProvider,
          name: r'entryTagsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$entryTagsHash,
          dependencies: EntryTagsFamily._dependencies,
          allTransitiveDependencies: EntryTagsFamily._allTransitiveDependencies,
          entryId: entryId,
        );

  EntryTagsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.entryId,
  }) : super.internal();

  final String entryId;

  @override
  Override overrideWith(
    List<String> Function(EntryTagsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: EntryTagsProvider._internal(
        (ref) => create(ref as EntryTagsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        entryId: entryId,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<List<String>> createElement() {
    return _EntryTagsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is EntryTagsProvider && other.entryId == entryId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, entryId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin EntryTagsRef on AutoDisposeProviderRef<List<String>> {
  /// The parameter `entryId` of this provider.
  String get entryId;
}

class _EntryTagsProviderElement extends AutoDisposeProviderElement<List<String>>
    with EntryTagsRef {
  _EntryTagsProviderElement(super.provider);

  @override
  String get entryId => (origin as EntryTagsProvider).entryId;
}

String _$entryBlueprintPageTypeHash() =>
    r'de37953ce77af7052651105704e4f829f4753e71';

/// See also [entryBlueprintPageType].
@ProviderFor(entryBlueprintPageType)
const entryBlueprintPageTypeProvider = EntryBlueprintPageTypeFamily();

/// See also [entryBlueprintPageType].
class EntryBlueprintPageTypeFamily extends Family<PageType> {
  /// See also [entryBlueprintPageType].
  const EntryBlueprintPageTypeFamily();

  /// See also [entryBlueprintPageType].
  EntryBlueprintPageTypeProvider call(
    String blueprintId,
  ) {
    return EntryBlueprintPageTypeProvider(
      blueprintId,
    );
  }

  @override
  EntryBlueprintPageTypeProvider getProviderOverride(
    covariant EntryBlueprintPageTypeProvider provider,
  ) {
    return call(
      provider.blueprintId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'entryBlueprintPageTypeProvider';
}

/// See also [entryBlueprintPageType].
class EntryBlueprintPageTypeProvider extends AutoDisposeProvider<PageType> {
  /// See also [entryBlueprintPageType].
  EntryBlueprintPageTypeProvider(
    String blueprintId,
  ) : this._internal(
          (ref) => entryBlueprintPageType(
            ref as EntryBlueprintPageTypeRef,
            blueprintId,
          ),
          from: entryBlueprintPageTypeProvider,
          name: r'entryBlueprintPageTypeProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$entryBlueprintPageTypeHash,
          dependencies: EntryBlueprintPageTypeFamily._dependencies,
          allTransitiveDependencies:
              EntryBlueprintPageTypeFamily._allTransitiveDependencies,
          blueprintId: blueprintId,
        );

  EntryBlueprintPageTypeProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.blueprintId,
  }) : super.internal();

  final String blueprintId;

  @override
  Override overrideWith(
    PageType Function(EntryBlueprintPageTypeRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: EntryBlueprintPageTypeProvider._internal(
        (ref) => create(ref as EntryBlueprintPageTypeRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        blueprintId: blueprintId,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<PageType> createElement() {
    return _EntryBlueprintPageTypeProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is EntryBlueprintPageTypeProvider &&
        other.blueprintId == blueprintId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, blueprintId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin EntryBlueprintPageTypeRef on AutoDisposeProviderRef<PageType> {
  /// The parameter `blueprintId` of this provider.
  String get blueprintId;
}

class _EntryBlueprintPageTypeProviderElement
    extends AutoDisposeProviderElement<PageType>
    with EntryBlueprintPageTypeRef {
  _EntryBlueprintPageTypeProviderElement(super.provider);

  @override
  String get blueprintId =>
      (origin as EntryBlueprintPageTypeProvider).blueprintId;
}

String _$fieldModifiersHash() => r'3568ba69f15d904253ba445e8f5b7740823d8246';

/// Gets all the modifiers with a given name.
///
/// Copied from [fieldModifiers].
@ProviderFor(fieldModifiers)
const fieldModifiersProvider = FieldModifiersFamily();

/// Gets all the modifiers with a given name.
///
/// Copied from [fieldModifiers].
class FieldModifiersFamily extends Family<Map<String, Modifier>> {
  /// Gets all the modifiers with a given name.
  ///
  /// Copied from [fieldModifiers].
  const FieldModifiersFamily();

  /// Gets all the modifiers with a given name.
  ///
  /// Copied from [fieldModifiers].
  FieldModifiersProvider call(
    String blueprintId,
    String modifierName,
  ) {
    return FieldModifiersProvider(
      blueprintId,
      modifierName,
    );
  }

  @override
  FieldModifiersProvider getProviderOverride(
    covariant FieldModifiersProvider provider,
  ) {
    return call(
      provider.blueprintId,
      provider.modifierName,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'fieldModifiersProvider';
}

/// Gets all the modifiers with a given name.
///
/// Copied from [fieldModifiers].
class FieldModifiersProvider
    extends AutoDisposeProvider<Map<String, Modifier>> {
  /// Gets all the modifiers with a given name.
  ///
  /// Copied from [fieldModifiers].
  FieldModifiersProvider(
    String blueprintId,
    String modifierName,
  ) : this._internal(
          (ref) => fieldModifiers(
            ref as FieldModifiersRef,
            blueprintId,
            modifierName,
          ),
          from: fieldModifiersProvider,
          name: r'fieldModifiersProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$fieldModifiersHash,
          dependencies: FieldModifiersFamily._dependencies,
          allTransitiveDependencies:
              FieldModifiersFamily._allTransitiveDependencies,
          blueprintId: blueprintId,
          modifierName: modifierName,
        );

  FieldModifiersProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.blueprintId,
    required this.modifierName,
  }) : super.internal();

  final String blueprintId;
  final String modifierName;

  @override
  Override overrideWith(
    Map<String, Modifier> Function(FieldModifiersRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FieldModifiersProvider._internal(
        (ref) => create(ref as FieldModifiersRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        blueprintId: blueprintId,
        modifierName: modifierName,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<Map<String, Modifier>> createElement() {
    return _FieldModifiersProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FieldModifiersProvider &&
        other.blueprintId == blueprintId &&
        other.modifierName == modifierName;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, blueprintId.hashCode);
    hash = _SystemHash.combine(hash, modifierName.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin FieldModifiersRef on AutoDisposeProviderRef<Map<String, Modifier>> {
  /// The parameter `blueprintId` of this provider.
  String get blueprintId;

  /// The parameter `modifierName` of this provider.
  String get modifierName;
}

class _FieldModifiersProviderElement
    extends AutoDisposeProviderElement<Map<String, Modifier>>
    with FieldModifiersRef {
  _FieldModifiersProviderElement(super.provider);

  @override
  String get blueprintId => (origin as FieldModifiersProvider).blueprintId;
  @override
  String get modifierName => (origin as FieldModifiersProvider).modifierName;
}

String _$modifierPathsHash() => r'0d2ddb4b557172710e792a47651f26c346c1edbf';

/// Gets all the paths from fields with a given modifier.
///
/// Copied from [modifierPaths].
@ProviderFor(modifierPaths)
const modifierPathsProvider = ModifierPathsFamily();

/// Gets all the paths from fields with a given modifier.
///
/// Copied from [modifierPaths].
class ModifierPathsFamily extends Family<List<String>> {
  /// Gets all the paths from fields with a given modifier.
  ///
  /// Copied from [modifierPaths].
  const ModifierPathsFamily();

  /// Gets all the paths from fields with a given modifier.
  ///
  /// Copied from [modifierPaths].
  ModifierPathsProvider call(
    String blueprintId,
    String modifierName, [
    String? data,
  ]) {
    return ModifierPathsProvider(
      blueprintId,
      modifierName,
      data,
    );
  }

  @override
  ModifierPathsProvider getProviderOverride(
    covariant ModifierPathsProvider provider,
  ) {
    return call(
      provider.blueprintId,
      provider.modifierName,
      provider.data,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'modifierPathsProvider';
}

/// Gets all the paths from fields with a given modifier.
///
/// Copied from [modifierPaths].
class ModifierPathsProvider extends AutoDisposeProvider<List<String>> {
  /// Gets all the paths from fields with a given modifier.
  ///
  /// Copied from [modifierPaths].
  ModifierPathsProvider(
    String blueprintId,
    String modifierName, [
    String? data,
  ]) : this._internal(
          (ref) => modifierPaths(
            ref as ModifierPathsRef,
            blueprintId,
            modifierName,
            data,
          ),
          from: modifierPathsProvider,
          name: r'modifierPathsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$modifierPathsHash,
          dependencies: ModifierPathsFamily._dependencies,
          allTransitiveDependencies:
              ModifierPathsFamily._allTransitiveDependencies,
          blueprintId: blueprintId,
          modifierName: modifierName,
          data: data,
        );

  ModifierPathsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.blueprintId,
    required this.modifierName,
    required this.data,
  }) : super.internal();

  final String blueprintId;
  final String modifierName;
  final String? data;

  @override
  Override overrideWith(
    List<String> Function(ModifierPathsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ModifierPathsProvider._internal(
        (ref) => create(ref as ModifierPathsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        blueprintId: blueprintId,
        modifierName: modifierName,
        data: data,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<List<String>> createElement() {
    return _ModifierPathsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ModifierPathsProvider &&
        other.blueprintId == blueprintId &&
        other.modifierName == modifierName &&
        other.data == data;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, blueprintId.hashCode);
    hash = _SystemHash.combine(hash, modifierName.hashCode);
    hash = _SystemHash.combine(hash, data.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ModifierPathsRef on AutoDisposeProviderRef<List<String>> {
  /// The parameter `blueprintId` of this provider.
  String get blueprintId;

  /// The parameter `modifierName` of this provider.
  String get modifierName;

  /// The parameter `data` of this provider.
  String? get data;
}

class _ModifierPathsProviderElement
    extends AutoDisposeProviderElement<List<String>> with ModifierPathsRef {
  _ModifierPathsProviderElement(super.provider);

  @override
  String get blueprintId => (origin as ModifierPathsProvider).blueprintId;
  @override
  String get modifierName => (origin as ModifierPathsProvider).modifierName;
  @override
  String? get data => (origin as ModifierPathsProvider).data;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
