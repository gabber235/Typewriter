// GENERATED CODE. DO NOT MODIFY BY HAND

part of 'resource_repositories.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE. DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides one resource repository owner for the active local work scope.
///
/// The owner retains its repositories across authenticated transport replacement
/// and rebinds their active watches. Scope disposal cascades to every cached child.

@ProviderFor(resourceRepositories)
final resourceRepositoriesProvider = ResourceRepositoriesProvider._();

/// Provides one resource repository owner for the active local work scope.
///
/// The owner retains its repositories across authenticated transport replacement
/// and rebinds their active watches. Scope disposal cascades to every cached child.

final class ResourceRepositoriesProvider
    extends
        $FunctionalProvider<
          ResourceRepositories,
          ResourceRepositories,
          ResourceRepositories
        >
    with $Provider<ResourceRepositories> {
  /// Provides one resource repository owner for the active local work scope.
  ///
  /// The owner retains its repositories across authenticated transport replacement
  /// and rebinds their active watches. Scope disposal cascades to every cached child.
  ResourceRepositoriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'resourceRepositoriesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$resourceRepositoriesHash();

  @$internal
  @override
  $ProviderElement<ResourceRepositories> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ResourceRepositories create(Ref ref) {
    return resourceRepositories(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ResourceRepositories value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ResourceRepositories>(value),
    );
  }
}

String _$resourceRepositoriesHash() =>
    r'0aa03b8f9081c46e4749269339042eb07895da72';
