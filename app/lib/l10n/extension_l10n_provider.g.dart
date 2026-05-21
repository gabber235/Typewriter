// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'extension_l10n_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$extensionL10nResolverHash() =>
    r'030b42eef53f3ab9ffbbdbc715c785c87f393b04';

/// Provides access to the extension localization resolver
///
/// Copied from [extensionL10nResolver].
@ProviderFor(extensionL10nResolver)
final extensionL10nResolverProvider =
    AutoDisposeProvider<ExtensionLocalizationResolver>.internal(
  extensionL10nResolver,
  name: r'extensionL10nResolverProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$extensionL10nResolverHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ExtensionL10nResolverRef
    = AutoDisposeProviderRef<ExtensionLocalizationResolver>;
String _$extensionL10nInitializerHash() =>
    r'cd6be851df2753261d28cbe472247778dece4990';

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

/// Helper provider that initializes translations for all loaded extensions
///
/// Copied from [extensionL10nInitializer].
@ProviderFor(extensionL10nInitializer)
const extensionL10nInitializerProvider = ExtensionL10nInitializerFamily();

/// Helper provider that initializes translations for all loaded extensions
///
/// Copied from [extensionL10nInitializer].
class ExtensionL10nInitializerFamily extends Family<void> {
  /// Helper provider that initializes translations for all loaded extensions
  ///
  /// Copied from [extensionL10nInitializer].
  const ExtensionL10nInitializerFamily();

  /// Helper provider that initializes translations for all loaded extensions
  ///
  /// Copied from [extensionL10nInitializer].
  ExtensionL10nInitializerProvider call(
    List<Extension> extensions,
  ) {
    return ExtensionL10nInitializerProvider(
      extensions,
    );
  }

  @override
  ExtensionL10nInitializerProvider getProviderOverride(
    covariant ExtensionL10nInitializerProvider provider,
  ) {
    return call(
      provider.extensions,
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
  String? get name => r'extensionL10nInitializerProvider';
}

/// Helper provider that initializes translations for all loaded extensions
///
/// Copied from [extensionL10nInitializer].
class ExtensionL10nInitializerProvider extends AutoDisposeProvider<void> {
  /// Helper provider that initializes translations for all loaded extensions
  ///
  /// Copied from [extensionL10nInitializer].
  ExtensionL10nInitializerProvider(
    List<Extension> extensions,
  ) : this._internal(
          (ref) => extensionL10nInitializer(
            ref as ExtensionL10nInitializerRef,
            extensions,
          ),
          from: extensionL10nInitializerProvider,
          name: r'extensionL10nInitializerProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$extensionL10nInitializerHash,
          dependencies: ExtensionL10nInitializerFamily._dependencies,
          allTransitiveDependencies:
              ExtensionL10nInitializerFamily._allTransitiveDependencies,
          extensions: extensions,
        );

  ExtensionL10nInitializerProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.extensions,
  }) : super.internal();

  final List<Extension> extensions;

  @override
  Override overrideWith(
    void Function(ExtensionL10nInitializerRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ExtensionL10nInitializerProvider._internal(
        (ref) => create(ref as ExtensionL10nInitializerRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        extensions: extensions,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<void> createElement() {
    return _ExtensionL10nInitializerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ExtensionL10nInitializerProvider &&
        other.extensions == extensions;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, extensions.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ExtensionL10nInitializerRef on AutoDisposeProviderRef<void> {
  /// The parameter `extensions` of this provider.
  List<Extension> get extensions;
}

class _ExtensionL10nInitializerProviderElement
    extends AutoDisposeProviderElement<void> with ExtensionL10nInitializerRef {
  _ExtensionL10nInitializerProviderElement(super.provider);

  @override
  List<Extension> get extensions =>
      (origin as ExtensionL10nInitializerProvider).extensions;
}

String _$resolveExtensionKeyHash() =>
    r'0864212d15c57610ba56b11d4bb358c711dc585b';

/// Resolve a localization key for an extension
///
/// Copied from [resolveExtensionKey].
@ProviderFor(resolveExtensionKey)
const resolveExtensionKeyProvider = ResolveExtensionKeyFamily();

/// Resolve a localization key for an extension
///
/// Copied from [resolveExtensionKey].
class ResolveExtensionKeyFamily extends Family<String> {
  /// Resolve a localization key for an extension
  ///
  /// Copied from [resolveExtensionKey].
  const ResolveExtensionKeyFamily();

  /// Resolve a localization key for an extension
  ///
  /// Copied from [resolveExtensionKey].
  ResolveExtensionKeyProvider call(
    String extensionKey,
    String key, {
    String? fallback,
  }) {
    return ResolveExtensionKeyProvider(
      extensionKey,
      key,
      fallback: fallback,
    );
  }

  @override
  ResolveExtensionKeyProvider getProviderOverride(
    covariant ResolveExtensionKeyProvider provider,
  ) {
    return call(
      provider.extensionKey,
      provider.key,
      fallback: provider.fallback,
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
  String? get name => r'resolveExtensionKeyProvider';
}

/// Resolve a localization key for an extension
///
/// Copied from [resolveExtensionKey].
class ResolveExtensionKeyProvider extends AutoDisposeProvider<String> {
  /// Resolve a localization key for an extension
  ///
  /// Copied from [resolveExtensionKey].
  ResolveExtensionKeyProvider(
    String extensionKey,
    String key, {
    String? fallback,
  }) : this._internal(
          (ref) => resolveExtensionKey(
            ref as ResolveExtensionKeyRef,
            extensionKey,
            key,
            fallback: fallback,
          ),
          from: resolveExtensionKeyProvider,
          name: r'resolveExtensionKeyProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$resolveExtensionKeyHash,
          dependencies: ResolveExtensionKeyFamily._dependencies,
          allTransitiveDependencies:
              ResolveExtensionKeyFamily._allTransitiveDependencies,
          extensionKey: extensionKey,
          key: key,
          fallback: fallback,
        );

  ResolveExtensionKeyProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.extensionKey,
    required this.key,
    required this.fallback,
  }) : super.internal();

  final String extensionKey;
  final String key;
  final String? fallback;

  @override
  Override overrideWith(
    String Function(ResolveExtensionKeyRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ResolveExtensionKeyProvider._internal(
        (ref) => create(ref as ResolveExtensionKeyRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        extensionKey: extensionKey,
        key: key,
        fallback: fallback,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<String> createElement() {
    return _ResolveExtensionKeyProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ResolveExtensionKeyProvider &&
        other.extensionKey == extensionKey &&
        other.key == key &&
        other.fallback == fallback;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, extensionKey.hashCode);
    hash = _SystemHash.combine(hash, key.hashCode);
    hash = _SystemHash.combine(hash, fallback.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ResolveExtensionKeyRef on AutoDisposeProviderRef<String> {
  /// The parameter `extensionKey` of this provider.
  String get extensionKey;

  /// The parameter `key` of this provider.
  String get key;

  /// The parameter `fallback` of this provider.
  String? get fallback;
}

class _ResolveExtensionKeyProviderElement
    extends AutoDisposeProviderElement<String> with ResolveExtensionKeyRef {
  _ResolveExtensionKeyProviderElement(super.provider);

  @override
  String get extensionKey =>
      (origin as ResolveExtensionKeyProvider).extensionKey;
  @override
  String get key => (origin as ResolveExtensionKeyProvider).key;
  @override
  String? get fallback => (origin as ResolveExtensionKeyProvider).fallback;
}

String _$resolveExtensionOptionsHash() =>
    r'd7423a8aa6c03e11353b524ddfbc328f31b9a1fa';

/// Resolve option labels for an extension enum/select field
///
/// Copied from [resolveExtensionOptions].
@ProviderFor(resolveExtensionOptions)
const resolveExtensionOptionsProvider = ResolveExtensionOptionsFamily();

/// Resolve option labels for an extension enum/select field
///
/// Copied from [resolveExtensionOptions].
class ResolveExtensionOptionsFamily extends Family<Map<String, String>> {
  /// Resolve option labels for an extension enum/select field
  ///
  /// Copied from [resolveExtensionOptions].
  const ResolveExtensionOptionsFamily();

  /// Resolve option labels for an extension enum/select field
  ///
  /// Copied from [resolveExtensionOptions].
  ResolveExtensionOptionsProvider call(
    String extensionKey,
    String keyPrefix,
    List<String> optionValues, {
    Map<String, String>? fallbacks,
  }) {
    return ResolveExtensionOptionsProvider(
      extensionKey,
      keyPrefix,
      optionValues,
      fallbacks: fallbacks,
    );
  }

  @override
  ResolveExtensionOptionsProvider getProviderOverride(
    covariant ResolveExtensionOptionsProvider provider,
  ) {
    return call(
      provider.extensionKey,
      provider.keyPrefix,
      provider.optionValues,
      fallbacks: provider.fallbacks,
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
  String? get name => r'resolveExtensionOptionsProvider';
}

/// Resolve option labels for an extension enum/select field
///
/// Copied from [resolveExtensionOptions].
class ResolveExtensionOptionsProvider
    extends AutoDisposeProvider<Map<String, String>> {
  /// Resolve option labels for an extension enum/select field
  ///
  /// Copied from [resolveExtensionOptions].
  ResolveExtensionOptionsProvider(
    String extensionKey,
    String keyPrefix,
    List<String> optionValues, {
    Map<String, String>? fallbacks,
  }) : this._internal(
          (ref) => resolveExtensionOptions(
            ref as ResolveExtensionOptionsRef,
            extensionKey,
            keyPrefix,
            optionValues,
            fallbacks: fallbacks,
          ),
          from: resolveExtensionOptionsProvider,
          name: r'resolveExtensionOptionsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$resolveExtensionOptionsHash,
          dependencies: ResolveExtensionOptionsFamily._dependencies,
          allTransitiveDependencies:
              ResolveExtensionOptionsFamily._allTransitiveDependencies,
          extensionKey: extensionKey,
          keyPrefix: keyPrefix,
          optionValues: optionValues,
          fallbacks: fallbacks,
        );

  ResolveExtensionOptionsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.extensionKey,
    required this.keyPrefix,
    required this.optionValues,
    required this.fallbacks,
  }) : super.internal();

  final String extensionKey;
  final String keyPrefix;
  final List<String> optionValues;
  final Map<String, String>? fallbacks;

  @override
  Override overrideWith(
    Map<String, String> Function(ResolveExtensionOptionsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ResolveExtensionOptionsProvider._internal(
        (ref) => create(ref as ResolveExtensionOptionsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        extensionKey: extensionKey,
        keyPrefix: keyPrefix,
        optionValues: optionValues,
        fallbacks: fallbacks,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<Map<String, String>> createElement() {
    return _ResolveExtensionOptionsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ResolveExtensionOptionsProvider &&
        other.extensionKey == extensionKey &&
        other.keyPrefix == keyPrefix &&
        other.optionValues == optionValues &&
        other.fallbacks == fallbacks;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, extensionKey.hashCode);
    hash = _SystemHash.combine(hash, keyPrefix.hashCode);
    hash = _SystemHash.combine(hash, optionValues.hashCode);
    hash = _SystemHash.combine(hash, fallbacks.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ResolveExtensionOptionsRef
    on AutoDisposeProviderRef<Map<String, String>> {
  /// The parameter `extensionKey` of this provider.
  String get extensionKey;

  /// The parameter `keyPrefix` of this provider.
  String get keyPrefix;

  /// The parameter `optionValues` of this provider.
  List<String> get optionValues;

  /// The parameter `fallbacks` of this provider.
  Map<String, String>? get fallbacks;
}

class _ResolveExtensionOptionsProviderElement
    extends AutoDisposeProviderElement<Map<String, String>>
    with ResolveExtensionOptionsRef {
  _ResolveExtensionOptionsProviderElement(super.provider);

  @override
  String get extensionKey =>
      (origin as ResolveExtensionOptionsProvider).extensionKey;
  @override
  String get keyPrefix => (origin as ResolveExtensionOptionsProvider).keyPrefix;
  @override
  List<String> get optionValues =>
      (origin as ResolveExtensionOptionsProvider).optionValues;
  @override
  Map<String, String>? get fallbacks =>
      (origin as ResolveExtensionOptionsProvider).fallbacks;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
