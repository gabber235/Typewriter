// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'editors.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$fieldValueHash() => r'a3fbbd771e487619c7f511e3b1ebc1869503c737';

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

/// See also [fieldValue].
@ProviderFor(fieldValue)
const fieldValueProvider = FieldValueFamily();

/// See also [fieldValue].
class FieldValueFamily extends Family<dynamic> {
  /// See also [fieldValue].
  const FieldValueFamily();

  /// See also [fieldValue].
  FieldValueProvider call(
    String path, [
    dynamic defaultValue,
  ]) {
    return FieldValueProvider(
      path,
      defaultValue,
    );
  }

  @override
  FieldValueProvider getProviderOverride(
    covariant FieldValueProvider provider,
  ) {
    return call(
      provider.path,
      provider.defaultValue,
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
  String? get name => r'fieldValueProvider';
}

/// See also [fieldValue].
class FieldValueProvider extends AutoDisposeProvider<dynamic> {
  /// See also [fieldValue].
  FieldValueProvider(
    String path, [
    dynamic defaultValue,
  ]) : this._internal(
          (ref) => fieldValue(
            ref as FieldValueRef,
            path,
            defaultValue,
          ),
          from: fieldValueProvider,
          name: r'fieldValueProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$fieldValueHash,
          dependencies: FieldValueFamily._dependencies,
          allTransitiveDependencies:
              FieldValueFamily._allTransitiveDependencies,
          path: path,
          defaultValue: defaultValue,
        );

  FieldValueProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.path,
    required this.defaultValue,
  }) : super.internal();

  final String path;
  final dynamic defaultValue;

  @override
  Override overrideWith(
    dynamic Function(FieldValueRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FieldValueProvider._internal(
        (ref) => create(ref as FieldValueRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        path: path,
        defaultValue: defaultValue,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<dynamic> createElement() {
    return _FieldValueProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FieldValueProvider &&
        other.path == path &&
        other.defaultValue == defaultValue;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, path.hashCode);
    hash = _SystemHash.combine(hash, defaultValue.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin FieldValueRef on AutoDisposeProviderRef<dynamic> {
  /// The parameter `path` of this provider.
  String get path;

  /// The parameter `defaultValue` of this provider.
  dynamic get defaultValue;
}

class _FieldValueProviderElement extends AutoDisposeProviderElement<dynamic>
    with FieldValueRef {
  _FieldValueProviderElement(super.provider);

  @override
  String get path => (origin as FieldValueProvider).path;
  @override
  dynamic get defaultValue => (origin as FieldValueProvider).defaultValue;
}

String _$editorFiltersHash() => r'9b50ca70165451bf50e9d54e8b3cc5104386c652';

/// See also [editorFilters].
@ProviderFor(editorFilters)
final editorFiltersProvider = AutoDisposeProvider<List<EditorFilter>>.internal(
  editorFilters,
  name: r'editorFiltersProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$editorFiltersHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef EditorFiltersRef = AutoDisposeProviderRef<List<EditorFilter>>;
String _$pathDisplayNameHash() => r'0aaa7ed9dece787bdeb95ac3f9841dad38ae87bb';

/// See also [pathDisplayName].
@ProviderFor(pathDisplayName)
const pathDisplayNameProvider = PathDisplayNameFamily();

/// See also [pathDisplayName].
class PathDisplayNameFamily extends Family<String> {
  /// See also [pathDisplayName].
  const PathDisplayNameFamily();

  /// See also [pathDisplayName].
  PathDisplayNameProvider call(
    String path,
  ) {
    return PathDisplayNameProvider(
      path,
    );
  }

  @override
  PathDisplayNameProvider getProviderOverride(
    covariant PathDisplayNameProvider provider,
  ) {
    return call(
      provider.path,
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
  String? get name => r'pathDisplayNameProvider';
}

/// See also [pathDisplayName].
class PathDisplayNameProvider extends AutoDisposeProvider<String> {
  /// See also [pathDisplayName].
  PathDisplayNameProvider(
    String path,
  ) : this._internal(
          (ref) => pathDisplayName(
            ref as PathDisplayNameRef,
            path,
          ),
          from: pathDisplayNameProvider,
          name: r'pathDisplayNameProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$pathDisplayNameHash,
          dependencies: PathDisplayNameFamily._dependencies,
          allTransitiveDependencies:
              PathDisplayNameFamily._allTransitiveDependencies,
          path: path,
        );

  PathDisplayNameProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.path,
  }) : super.internal();

  final String path;

  @override
  Override overrideWith(
    String Function(PathDisplayNameRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PathDisplayNameProvider._internal(
        (ref) => create(ref as PathDisplayNameRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        path: path,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<String> createElement() {
    return _PathDisplayNameProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PathDisplayNameProvider && other.path == path;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, path.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PathDisplayNameRef on AutoDisposeProviderRef<String> {
  /// The parameter `path` of this provider.
  String get path;
}

class _PathDisplayNameProviderElement extends AutoDisposeProviderElement<String>
    with PathDisplayNameRef {
  _PathDisplayNameProviderElement(super.provider);

  @override
  String get path => (origin as PathDisplayNameProvider).path;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
