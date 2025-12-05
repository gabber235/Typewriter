// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'material.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$materialPropertiesHash() =>
    r'06bdf69c856589203d392aba18d7a6aa9eec115b';

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

/// See also [materialProperties].
@ProviderFor(materialProperties)
const materialPropertiesProvider = MaterialPropertiesFamily();

/// See also [materialProperties].
class MaterialPropertiesFamily extends Family<List<MaterialProperty>> {
  /// See also [materialProperties].
  const MaterialPropertiesFamily();

  /// See also [materialProperties].
  MaterialPropertiesProvider call(
    String meta,
  ) {
    return MaterialPropertiesProvider(
      meta,
    );
  }

  @override
  MaterialPropertiesProvider getProviderOverride(
    covariant MaterialPropertiesProvider provider,
  ) {
    return call(
      provider.meta,
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
  String? get name => r'materialPropertiesProvider';
}

/// See also [materialProperties].
class MaterialPropertiesProvider
    extends AutoDisposeProvider<List<MaterialProperty>> {
  /// See also [materialProperties].
  MaterialPropertiesProvider(
    String meta,
  ) : this._internal(
          (ref) => materialProperties(
            ref as MaterialPropertiesRef,
            meta,
          ),
          from: materialPropertiesProvider,
          name: r'materialPropertiesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$materialPropertiesHash,
          dependencies: MaterialPropertiesFamily._dependencies,
          allTransitiveDependencies:
              MaterialPropertiesFamily._allTransitiveDependencies,
          meta: meta,
        );

  MaterialPropertiesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.meta,
  }) : super.internal();

  final String meta;

  @override
  Override overrideWith(
    List<MaterialProperty> Function(MaterialPropertiesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: MaterialPropertiesProvider._internal(
        (ref) => create(ref as MaterialPropertiesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        meta: meta,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<List<MaterialProperty>> createElement() {
    return _MaterialPropertiesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MaterialPropertiesProvider && other.meta == meta;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, meta.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin MaterialPropertiesRef on AutoDisposeProviderRef<List<MaterialProperty>> {
  /// The parameter `meta` of this provider.
  String get meta;
}

class _MaterialPropertiesProviderElement
    extends AutoDisposeProviderElement<List<MaterialProperty>>
    with MaterialPropertiesRef {
  _MaterialPropertiesProviderElement(super.provider);

  @override
  String get meta => (origin as MaterialPropertiesProvider).meta;
}

String _$availableMaterialsMapHash() =>
    r'9169cdc2fc7d6e4254311c037da9efe18abcb324';

/// See also [availableMaterialsMap].
@ProviderFor(availableMaterialsMap)
final availableMaterialsMapProvider =
    AutoDisposeProvider<Map<String, MinecraftMaterial>>.internal(
  availableMaterialsMap,
  name: r'availableMaterialsMapProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$availableMaterialsMapHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AvailableMaterialsMapRef
    = AutoDisposeProviderRef<Map<String, MinecraftMaterial>>;
String _$isMaterialAvailableHash() =>
    r'3f6983400f1c0cf8356a47cca4da6fbae874c615';

/// See also [isMaterialAvailable].
@ProviderFor(isMaterialAvailable)
const isMaterialAvailableProvider = IsMaterialAvailableFamily();

/// See also [isMaterialAvailable].
class IsMaterialAvailableFamily extends Family<bool> {
  /// See also [isMaterialAvailable].
  const IsMaterialAvailableFamily();

  /// See also [isMaterialAvailable].
  IsMaterialAvailableProvider call(
    String material,
  ) {
    return IsMaterialAvailableProvider(
      material,
    );
  }

  @override
  IsMaterialAvailableProvider getProviderOverride(
    covariant IsMaterialAvailableProvider provider,
  ) {
    return call(
      provider.material,
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
  String? get name => r'isMaterialAvailableProvider';
}

/// See also [isMaterialAvailable].
class IsMaterialAvailableProvider extends AutoDisposeProvider<bool> {
  /// See also [isMaterialAvailable].
  IsMaterialAvailableProvider(
    String material,
  ) : this._internal(
          (ref) => isMaterialAvailable(
            ref as IsMaterialAvailableRef,
            material,
          ),
          from: isMaterialAvailableProvider,
          name: r'isMaterialAvailableProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$isMaterialAvailableHash,
          dependencies: IsMaterialAvailableFamily._dependencies,
          allTransitiveDependencies:
              IsMaterialAvailableFamily._allTransitiveDependencies,
          material: material,
        );

  IsMaterialAvailableProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.material,
  }) : super.internal();

  final String material;

  @override
  Override overrideWith(
    bool Function(IsMaterialAvailableRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: IsMaterialAvailableProvider._internal(
        (ref) => create(ref as IsMaterialAvailableRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        material: material,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<bool> createElement() {
    return _IsMaterialAvailableProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is IsMaterialAvailableProvider && other.material == material;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, material.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin IsMaterialAvailableRef on AutoDisposeProviderRef<bool> {
  /// The parameter `material` of this provider.
  String get material;
}

class _IsMaterialAvailableProviderElement
    extends AutoDisposeProviderElement<bool> with IsMaterialAvailableRef {
  _IsMaterialAvailableProviderElement(super.provider);

  @override
  String get material => (origin as IsMaterialAvailableProvider).material;
}

String _$fuzzyMaterialsHash() => r'cc0018d4b841683bd6ff3e53cb094af4bb2af8ba';

/// See also [_fuzzyMaterials].
@ProviderFor(_fuzzyMaterials)
final _fuzzyMaterialsProvider =
    AutoDisposeProvider<Fuzzy<CombinedMaterial>>.internal(
  _fuzzyMaterials,
  name: r'_fuzzyMaterialsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$fuzzyMaterialsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef _FuzzyMaterialsRef = AutoDisposeProviderRef<Fuzzy<CombinedMaterial>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
