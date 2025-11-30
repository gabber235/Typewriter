// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'entries_graph.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$graphableEntriesHash() => r'3dde1fe342473495999596e26f794b803e6c4a6a';

/// See also [graphableEntries].
@ProviderFor(graphableEntries)
final graphableEntriesProvider = AutoDisposeProvider<List<Entry>>.internal(
  graphableEntries,
  name: r'graphableEntriesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$graphableEntriesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef GraphableEntriesRef = AutoDisposeProviderRef<List<Entry>>;
String _$graphableEntryIdsHash() => r'80228ea635d8a323eb54cfc0e07ea895fc2fbb5c';

/// See also [graphableEntryIds].
@ProviderFor(graphableEntryIds)
final graphableEntryIdsProvider = AutoDisposeProvider<List<String>>.internal(
  graphableEntryIds,
  name: r'graphableEntryIdsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$graphableEntryIdsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef GraphableEntryIdsRef = AutoDisposeProviderRef<List<String>>;
String _$isTriggerEntryHash() => r'593a29e659e942fc5a781652ba28e472d7f4d38a';

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

/// See also [isTriggerEntry].
@ProviderFor(isTriggerEntry)
const isTriggerEntryProvider = IsTriggerEntryFamily();

/// See also [isTriggerEntry].
class IsTriggerEntryFamily extends Family<bool> {
  /// See also [isTriggerEntry].
  const IsTriggerEntryFamily();

  /// See also [isTriggerEntry].
  IsTriggerEntryProvider call(
    String entryId,
  ) {
    return IsTriggerEntryProvider(
      entryId,
    );
  }

  @override
  IsTriggerEntryProvider getProviderOverride(
    covariant IsTriggerEntryProvider provider,
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
  String? get name => r'isTriggerEntryProvider';
}

/// See also [isTriggerEntry].
class IsTriggerEntryProvider extends AutoDisposeProvider<bool> {
  /// See also [isTriggerEntry].
  IsTriggerEntryProvider(
    String entryId,
  ) : this._internal(
          (ref) => isTriggerEntry(
            ref as IsTriggerEntryRef,
            entryId,
          ),
          from: isTriggerEntryProvider,
          name: r'isTriggerEntryProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$isTriggerEntryHash,
          dependencies: IsTriggerEntryFamily._dependencies,
          allTransitiveDependencies:
              IsTriggerEntryFamily._allTransitiveDependencies,
          entryId: entryId,
        );

  IsTriggerEntryProvider._internal(
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
    bool Function(IsTriggerEntryRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: IsTriggerEntryProvider._internal(
        (ref) => create(ref as IsTriggerEntryRef),
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
  AutoDisposeProviderElement<bool> createElement() {
    return _IsTriggerEntryProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is IsTriggerEntryProvider && other.entryId == entryId;
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
mixin IsTriggerEntryRef on AutoDisposeProviderRef<bool> {
  /// The parameter `entryId` of this provider.
  String get entryId;
}

class _IsTriggerEntryProviderElement extends AutoDisposeProviderElement<bool>
    with IsTriggerEntryRef {
  _IsTriggerEntryProviderElement(super.provider);

  @override
  String get entryId => (origin as IsTriggerEntryProvider).entryId;
}

String _$isTriggerableEntryHash() =>
    r'0f48f6ff2df4d56a552745a4b59c3dd471de033c';

/// See also [isTriggerableEntry].
@ProviderFor(isTriggerableEntry)
const isTriggerableEntryProvider = IsTriggerableEntryFamily();

/// See also [isTriggerableEntry].
class IsTriggerableEntryFamily extends Family<bool> {
  /// See also [isTriggerableEntry].
  const IsTriggerableEntryFamily();

  /// See also [isTriggerableEntry].
  IsTriggerableEntryProvider call(
    String entryId,
  ) {
    return IsTriggerableEntryProvider(
      entryId,
    );
  }

  @override
  IsTriggerableEntryProvider getProviderOverride(
    covariant IsTriggerableEntryProvider provider,
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
  String? get name => r'isTriggerableEntryProvider';
}

/// See also [isTriggerableEntry].
class IsTriggerableEntryProvider extends AutoDisposeProvider<bool> {
  /// See also [isTriggerableEntry].
  IsTriggerableEntryProvider(
    String entryId,
  ) : this._internal(
          (ref) => isTriggerableEntry(
            ref as IsTriggerableEntryRef,
            entryId,
          ),
          from: isTriggerableEntryProvider,
          name: r'isTriggerableEntryProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$isTriggerableEntryHash,
          dependencies: IsTriggerableEntryFamily._dependencies,
          allTransitiveDependencies:
              IsTriggerableEntryFamily._allTransitiveDependencies,
          entryId: entryId,
        );

  IsTriggerableEntryProvider._internal(
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
    bool Function(IsTriggerableEntryRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: IsTriggerableEntryProvider._internal(
        (ref) => create(ref as IsTriggerableEntryRef),
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
  AutoDisposeProviderElement<bool> createElement() {
    return _IsTriggerableEntryProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is IsTriggerableEntryProvider && other.entryId == entryId;
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
mixin IsTriggerableEntryRef on AutoDisposeProviderRef<bool> {
  /// The parameter `entryId` of this provider.
  String get entryId;
}

class _IsTriggerableEntryProviderElement
    extends AutoDisposeProviderElement<bool> with IsTriggerableEntryRef {
  _IsTriggerableEntryProviderElement(super.provider);

  @override
  String get entryId => (origin as IsTriggerableEntryProvider).entryId;
}

String _$entryTriggersHash() => r'c464677e64a89eb92087b2803ad41e8d44dade71';

/// See also [entryTriggers].
@ProviderFor(entryTriggers)
const entryTriggersProvider = EntryTriggersFamily();

/// See also [entryTriggers].
class EntryTriggersFamily extends Family<Set<String>?> {
  /// See also [entryTriggers].
  const EntryTriggersFamily();

  /// See also [entryTriggers].
  EntryTriggersProvider call(
    String entryId,
  ) {
    return EntryTriggersProvider(
      entryId,
    );
  }

  @override
  EntryTriggersProvider getProviderOverride(
    covariant EntryTriggersProvider provider,
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
  String? get name => r'entryTriggersProvider';
}

/// See also [entryTriggers].
class EntryTriggersProvider extends AutoDisposeProvider<Set<String>?> {
  /// See also [entryTriggers].
  EntryTriggersProvider(
    String entryId,
  ) : this._internal(
          (ref) => entryTriggers(
            ref as EntryTriggersRef,
            entryId,
          ),
          from: entryTriggersProvider,
          name: r'entryTriggersProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$entryTriggersHash,
          dependencies: EntryTriggersFamily._dependencies,
          allTransitiveDependencies:
              EntryTriggersFamily._allTransitiveDependencies,
          entryId: entryId,
        );

  EntryTriggersProvider._internal(
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
    Set<String>? Function(EntryTriggersRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: EntryTriggersProvider._internal(
        (ref) => create(ref as EntryTriggersRef),
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
  AutoDisposeProviderElement<Set<String>?> createElement() {
    return _EntryTriggersProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is EntryTriggersProvider && other.entryId == entryId;
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
mixin EntryTriggersRef on AutoDisposeProviderRef<Set<String>?> {
  /// The parameter `entryId` of this provider.
  String get entryId;
}

class _EntryTriggersProviderElement
    extends AutoDisposeProviderElement<Set<String>?> with EntryTriggersRef {
  _EntryTriggersProviderElement(super.provider);

  @override
  String get entryId => (origin as EntryTriggersProvider).entryId;
}

String _$graphHash() => r'2452c3b9af51100a76c3ac944fed3e48221d079f';

/// See also [graph].
@ProviderFor(graph)
final graphProvider = AutoDisposeProvider<Graph>.internal(
  graph,
  name: r'graphProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$graphHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef GraphRef = AutoDisposeProviderRef<Graph>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
