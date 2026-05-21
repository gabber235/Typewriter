// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'localized_entry_blueprint_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$entryBlueprintLocalizedTitleHash() =>
    r'2b92f1206c0bc093dfd7fa9cbe189b758c9bf721';

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

/// Provides localized title for an entry blueprint
///
/// Copied from [entryBlueprintLocalizedTitle].
@ProviderFor(entryBlueprintLocalizedTitle)
const entryBlueprintLocalizedTitleProvider =
    EntryBlueprintLocalizedTitleFamily();

/// Provides localized title for an entry blueprint
///
/// Copied from [entryBlueprintLocalizedTitle].
class EntryBlueprintLocalizedTitleFamily extends Family<String> {
  /// Provides localized title for an entry blueprint
  ///
  /// Copied from [entryBlueprintLocalizedTitle].
  const EntryBlueprintLocalizedTitleFamily();

  /// Provides localized title for an entry blueprint
  ///
  /// Copied from [entryBlueprintLocalizedTitle].
  EntryBlueprintLocalizedTitleProvider call(
    String blueprintId,
  ) {
    return EntryBlueprintLocalizedTitleProvider(
      blueprintId,
    );
  }

  @override
  EntryBlueprintLocalizedTitleProvider getProviderOverride(
    covariant EntryBlueprintLocalizedTitleProvider provider,
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
  String? get name => r'entryBlueprintLocalizedTitleProvider';
}

/// Provides localized title for an entry blueprint
///
/// Copied from [entryBlueprintLocalizedTitle].
class EntryBlueprintLocalizedTitleProvider extends AutoDisposeProvider<String> {
  /// Provides localized title for an entry blueprint
  ///
  /// Copied from [entryBlueprintLocalizedTitle].
  EntryBlueprintLocalizedTitleProvider(
    String blueprintId,
  ) : this._internal(
          (ref) => entryBlueprintLocalizedTitle(
            ref as EntryBlueprintLocalizedTitleRef,
            blueprintId,
          ),
          from: entryBlueprintLocalizedTitleProvider,
          name: r'entryBlueprintLocalizedTitleProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$entryBlueprintLocalizedTitleHash,
          dependencies: EntryBlueprintLocalizedTitleFamily._dependencies,
          allTransitiveDependencies:
              EntryBlueprintLocalizedTitleFamily._allTransitiveDependencies,
          blueprintId: blueprintId,
        );

  EntryBlueprintLocalizedTitleProvider._internal(
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
    String Function(EntryBlueprintLocalizedTitleRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: EntryBlueprintLocalizedTitleProvider._internal(
        (ref) => create(ref as EntryBlueprintLocalizedTitleRef),
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
  AutoDisposeProviderElement<String> createElement() {
    return _EntryBlueprintLocalizedTitleProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is EntryBlueprintLocalizedTitleProvider &&
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
mixin EntryBlueprintLocalizedTitleRef on AutoDisposeProviderRef<String> {
  /// The parameter `blueprintId` of this provider.
  String get blueprintId;
}

class _EntryBlueprintLocalizedTitleProviderElement
    extends AutoDisposeProviderElement<String>
    with EntryBlueprintLocalizedTitleRef {
  _EntryBlueprintLocalizedTitleProviderElement(super.provider);

  @override
  String get blueprintId =>
      (origin as EntryBlueprintLocalizedTitleProvider).blueprintId;
}

String _$entryBlueprintLocalizedDescriptionHash() =>
    r'6bff710a933930802b08609e2427e98a8ce5723c';

/// Provides localized description for an entry blueprint
///
/// Copied from [entryBlueprintLocalizedDescription].
@ProviderFor(entryBlueprintLocalizedDescription)
const entryBlueprintLocalizedDescriptionProvider =
    EntryBlueprintLocalizedDescriptionFamily();

/// Provides localized description for an entry blueprint
///
/// Copied from [entryBlueprintLocalizedDescription].
class EntryBlueprintLocalizedDescriptionFamily extends Family<String> {
  /// Provides localized description for an entry blueprint
  ///
  /// Copied from [entryBlueprintLocalizedDescription].
  const EntryBlueprintLocalizedDescriptionFamily();

  /// Provides localized description for an entry blueprint
  ///
  /// Copied from [entryBlueprintLocalizedDescription].
  EntryBlueprintLocalizedDescriptionProvider call(
    String blueprintId,
  ) {
    return EntryBlueprintLocalizedDescriptionProvider(
      blueprintId,
    );
  }

  @override
  EntryBlueprintLocalizedDescriptionProvider getProviderOverride(
    covariant EntryBlueprintLocalizedDescriptionProvider provider,
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
  String? get name => r'entryBlueprintLocalizedDescriptionProvider';
}

/// Provides localized description for an entry blueprint
///
/// Copied from [entryBlueprintLocalizedDescription].
class EntryBlueprintLocalizedDescriptionProvider
    extends AutoDisposeProvider<String> {
  /// Provides localized description for an entry blueprint
  ///
  /// Copied from [entryBlueprintLocalizedDescription].
  EntryBlueprintLocalizedDescriptionProvider(
    String blueprintId,
  ) : this._internal(
          (ref) => entryBlueprintLocalizedDescription(
            ref as EntryBlueprintLocalizedDescriptionRef,
            blueprintId,
          ),
          from: entryBlueprintLocalizedDescriptionProvider,
          name: r'entryBlueprintLocalizedDescriptionProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$entryBlueprintLocalizedDescriptionHash,
          dependencies: EntryBlueprintLocalizedDescriptionFamily._dependencies,
          allTransitiveDependencies: EntryBlueprintLocalizedDescriptionFamily
              ._allTransitiveDependencies,
          blueprintId: blueprintId,
        );

  EntryBlueprintLocalizedDescriptionProvider._internal(
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
    String Function(EntryBlueprintLocalizedDescriptionRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: EntryBlueprintLocalizedDescriptionProvider._internal(
        (ref) => create(ref as EntryBlueprintLocalizedDescriptionRef),
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
  AutoDisposeProviderElement<String> createElement() {
    return _EntryBlueprintLocalizedDescriptionProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is EntryBlueprintLocalizedDescriptionProvider &&
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
mixin EntryBlueprintLocalizedDescriptionRef on AutoDisposeProviderRef<String> {
  /// The parameter `blueprintId` of this provider.
  String get blueprintId;
}

class _EntryBlueprintLocalizedDescriptionProviderElement
    extends AutoDisposeProviderElement<String>
    with EntryBlueprintLocalizedDescriptionRef {
  _EntryBlueprintLocalizedDescriptionProviderElement(super.provider);

  @override
  String get blueprintId =>
      (origin as EntryBlueprintLocalizedDescriptionProvider).blueprintId;
}

String _$fieldLocalizedLabelHash() =>
    r'3ba3269731b87f36dd752921eff20157edd2bf38';

/// Provides localized label for a field
///
/// Copied from [fieldLocalizedLabel].
@ProviderFor(fieldLocalizedLabel)
const fieldLocalizedLabelProvider = FieldLocalizedLabelFamily();

/// Provides localized label for a field
///
/// Copied from [fieldLocalizedLabel].
class FieldLocalizedLabelFamily extends Family<String> {
  /// Provides localized label for a field
  ///
  /// Copied from [fieldLocalizedLabel].
  const FieldLocalizedLabelFamily();

  /// Provides localized label for a field
  ///
  /// Copied from [fieldLocalizedLabel].
  FieldLocalizedLabelProvider call(
    String blueprintId,
    String fieldPath,
  ) {
    return FieldLocalizedLabelProvider(
      blueprintId,
      fieldPath,
    );
  }

  @override
  FieldLocalizedLabelProvider getProviderOverride(
    covariant FieldLocalizedLabelProvider provider,
  ) {
    return call(
      provider.blueprintId,
      provider.fieldPath,
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
  String? get name => r'fieldLocalizedLabelProvider';
}

/// Provides localized label for a field
///
/// Copied from [fieldLocalizedLabel].
class FieldLocalizedLabelProvider extends AutoDisposeProvider<String> {
  /// Provides localized label for a field
  ///
  /// Copied from [fieldLocalizedLabel].
  FieldLocalizedLabelProvider(
    String blueprintId,
    String fieldPath,
  ) : this._internal(
          (ref) => fieldLocalizedLabel(
            ref as FieldLocalizedLabelRef,
            blueprintId,
            fieldPath,
          ),
          from: fieldLocalizedLabelProvider,
          name: r'fieldLocalizedLabelProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$fieldLocalizedLabelHash,
          dependencies: FieldLocalizedLabelFamily._dependencies,
          allTransitiveDependencies:
              FieldLocalizedLabelFamily._allTransitiveDependencies,
          blueprintId: blueprintId,
          fieldPath: fieldPath,
        );

  FieldLocalizedLabelProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.blueprintId,
    required this.fieldPath,
  }) : super.internal();

  final String blueprintId;
  final String fieldPath;

  @override
  Override overrideWith(
    String Function(FieldLocalizedLabelRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FieldLocalizedLabelProvider._internal(
        (ref) => create(ref as FieldLocalizedLabelRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        blueprintId: blueprintId,
        fieldPath: fieldPath,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<String> createElement() {
    return _FieldLocalizedLabelProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FieldLocalizedLabelProvider &&
        other.blueprintId == blueprintId &&
        other.fieldPath == fieldPath;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, blueprintId.hashCode);
    hash = _SystemHash.combine(hash, fieldPath.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin FieldLocalizedLabelRef on AutoDisposeProviderRef<String> {
  /// The parameter `blueprintId` of this provider.
  String get blueprintId;

  /// The parameter `fieldPath` of this provider.
  String get fieldPath;
}

class _FieldLocalizedLabelProviderElement
    extends AutoDisposeProviderElement<String> with FieldLocalizedLabelRef {
  _FieldLocalizedLabelProviderElement(super.provider);

  @override
  String get blueprintId => (origin as FieldLocalizedLabelProvider).blueprintId;
  @override
  String get fieldPath => (origin as FieldLocalizedLabelProvider).fieldPath;
}

String _$fieldLocalizedHelpHash() =>
    r'fff6b4400158aa81823a34e80f8add4860dd71f1';

/// Provides localized help text for a field
///
/// Copied from [fieldLocalizedHelp].
@ProviderFor(fieldLocalizedHelp)
const fieldLocalizedHelpProvider = FieldLocalizedHelpFamily();

/// Provides localized help text for a field
///
/// Copied from [fieldLocalizedHelp].
class FieldLocalizedHelpFamily extends Family<String?> {
  /// Provides localized help text for a field
  ///
  /// Copied from [fieldLocalizedHelp].
  const FieldLocalizedHelpFamily();

  /// Provides localized help text for a field
  ///
  /// Copied from [fieldLocalizedHelp].
  FieldLocalizedHelpProvider call(
    String blueprintId,
    String fieldPath,
  ) {
    return FieldLocalizedHelpProvider(
      blueprintId,
      fieldPath,
    );
  }

  @override
  FieldLocalizedHelpProvider getProviderOverride(
    covariant FieldLocalizedHelpProvider provider,
  ) {
    return call(
      provider.blueprintId,
      provider.fieldPath,
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
  String? get name => r'fieldLocalizedHelpProvider';
}

/// Provides localized help text for a field
///
/// Copied from [fieldLocalizedHelp].
class FieldLocalizedHelpProvider extends AutoDisposeProvider<String?> {
  /// Provides localized help text for a field
  ///
  /// Copied from [fieldLocalizedHelp].
  FieldLocalizedHelpProvider(
    String blueprintId,
    String fieldPath,
  ) : this._internal(
          (ref) => fieldLocalizedHelp(
            ref as FieldLocalizedHelpRef,
            blueprintId,
            fieldPath,
          ),
          from: fieldLocalizedHelpProvider,
          name: r'fieldLocalizedHelpProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$fieldLocalizedHelpHash,
          dependencies: FieldLocalizedHelpFamily._dependencies,
          allTransitiveDependencies:
              FieldLocalizedHelpFamily._allTransitiveDependencies,
          blueprintId: blueprintId,
          fieldPath: fieldPath,
        );

  FieldLocalizedHelpProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.blueprintId,
    required this.fieldPath,
  }) : super.internal();

  final String blueprintId;
  final String fieldPath;

  @override
  Override overrideWith(
    String? Function(FieldLocalizedHelpRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FieldLocalizedHelpProvider._internal(
        (ref) => create(ref as FieldLocalizedHelpRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        blueprintId: blueprintId,
        fieldPath: fieldPath,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<String?> createElement() {
    return _FieldLocalizedHelpProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FieldLocalizedHelpProvider &&
        other.blueprintId == blueprintId &&
        other.fieldPath == fieldPath;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, blueprintId.hashCode);
    hash = _SystemHash.combine(hash, fieldPath.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin FieldLocalizedHelpRef on AutoDisposeProviderRef<String?> {
  /// The parameter `blueprintId` of this provider.
  String get blueprintId;

  /// The parameter `fieldPath` of this provider.
  String get fieldPath;
}

class _FieldLocalizedHelpProviderElement
    extends AutoDisposeProviderElement<String?> with FieldLocalizedHelpRef {
  _FieldLocalizedHelpProviderElement(super.provider);

  @override
  String get blueprintId => (origin as FieldLocalizedHelpProvider).blueprintId;
  @override
  String get fieldPath => (origin as FieldLocalizedHelpProvider).fieldPath;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
