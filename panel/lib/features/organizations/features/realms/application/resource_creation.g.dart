// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resource_creation.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(resourceCreation)
final resourceCreationProvider = ResourceCreationFamily._();

final class ResourceCreationProvider
    extends
        $FunctionalProvider<
          ResourceCreationSession,
          ResourceCreationSession,
          ResourceCreationSession
        >
    with $Provider<ResourceCreationSession> {
  ResourceCreationProvider._({
    required ResourceCreationFamily super.from,
    required AuthoringScope super.argument,
  }) : super(
         retry: null,
         name: r'resourceCreationProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$resourceCreationHash();

  @override
  String toString() {
    return r'resourceCreationProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<ResourceCreationSession> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ResourceCreationSession create(Ref ref) {
    final argument = this.argument as AuthoringScope;
    return resourceCreation(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ResourceCreationSession value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ResourceCreationSession>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ResourceCreationProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$resourceCreationHash() => r'1887f281cb65fdbd22e85a1ee1040411be69a255';

final class ResourceCreationFamily extends $Family
    with $FunctionalFamilyOverride<ResourceCreationSession, AuthoringScope> {
  ResourceCreationFamily._()
    : super(
        retry: null,
        name: r'resourceCreationProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  ResourceCreationProvider call(AuthoringScope scope) =>
      ResourceCreationProvider._(argument: scope, from: this);

  @override
  String toString() => r'resourceCreationProvider';
}

/// Resolves the creation template for [definition] in the selected Realm.
///
/// Null means creation is unavailable: no Realm is selected, its working
/// catalog is not ready, or the catalog cannot configure the definition.

@ProviderFor(selectedResourceCreationTemplate)
final selectedResourceCreationTemplateProvider =
    SelectedResourceCreationTemplateFamily._();

/// Resolves the creation template for [definition] in the selected Realm.
///
/// Null means creation is unavailable: no Realm is selected, its working
/// catalog is not ready, or the catalog cannot configure the definition.

final class SelectedResourceCreationTemplateProvider
    extends
        $FunctionalProvider<
          ResourceCreationTemplate?,
          ResourceCreationTemplate?,
          ResourceCreationTemplate?
        >
    with $Provider<ResourceCreationTemplate?> {
  /// Resolves the creation template for [definition] in the selected Realm.
  ///
  /// Null means creation is unavailable: no Realm is selected, its working
  /// catalog is not ready, or the catalog cannot configure the definition.
  SelectedResourceCreationTemplateProvider._({
    required SelectedResourceCreationTemplateFamily super.from,
    required skir.ResourceDefinitionId super.argument,
  }) : super(
         retry: null,
         name: r'selectedResourceCreationTemplateProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$selectedResourceCreationTemplateHash();

  @override
  String toString() {
    return r'selectedResourceCreationTemplateProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<ResourceCreationTemplate?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ResourceCreationTemplate? create(Ref ref) {
    final argument = this.argument as skir.ResourceDefinitionId;
    return selectedResourceCreationTemplate(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ResourceCreationTemplate? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ResourceCreationTemplate?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SelectedResourceCreationTemplateProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$selectedResourceCreationTemplateHash() =>
    r'40cb0d7d714a14dc301eede49125454679554417';

/// Resolves the creation template for [definition] in the selected Realm.
///
/// Null means creation is unavailable: no Realm is selected, its working
/// catalog is not ready, or the catalog cannot configure the definition.

final class SelectedResourceCreationTemplateFamily extends $Family
    with
        $FunctionalFamilyOverride<
          ResourceCreationTemplate?,
          skir.ResourceDefinitionId
        > {
  SelectedResourceCreationTemplateFamily._()
    : super(
        retry: null,
        name: r'selectedResourceCreationTemplateProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Resolves the creation template for [definition] in the selected Realm.
  ///
  /// Null means creation is unavailable: no Realm is selected, its working
  /// catalog is not ready, or the catalog cannot configure the definition.

  SelectedResourceCreationTemplateProvider call(
    skir.ResourceDefinitionId definition,
  ) => SelectedResourceCreationTemplateProvider._(
    argument: definition,
    from: this,
  );

  @override
  String toString() => r'selectedResourceCreationTemplateProvider';
}
