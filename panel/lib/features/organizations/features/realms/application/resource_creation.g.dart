// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resource_creation.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(resourceCreation)
final resourceCreationProvider = ResourceCreationProvider._();

final class ResourceCreationProvider
    extends
        $FunctionalProvider<
          ResourceCreationSession,
          ResourceCreationSession,
          ResourceCreationSession
        >
    with $Provider<ResourceCreationSession> {
  ResourceCreationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'resourceCreationProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$resourceCreationHash();

  @$internal
  @override
  $ProviderElement<ResourceCreationSession> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ResourceCreationSession create(Ref ref) {
    return resourceCreation(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ResourceCreationSession value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ResourceCreationSession>(value),
    );
  }
}

String _$resourceCreationHash() => r'81823c8c95eda44a36bd3468bb9f885e621cd275';
