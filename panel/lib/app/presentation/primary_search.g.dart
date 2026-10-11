// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'primary_search.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Resolves the primary search surface for the current route context.
///
/// Keeping the complete request behind a provider lets alternate application
/// hosts supply their own data source while retaining the production surface
/// and result renderers.

@ProviderFor(primarySearchRequest)
final primarySearchRequestProvider = PrimarySearchRequestProvider._();

/// Resolves the primary search surface for the current route context.
///
/// Keeping the complete request behind a provider lets alternate application
/// hosts supply their own data source while retaining the production surface
/// and result renderers.

final class PrimarySearchRequestProvider
    extends
        $FunctionalProvider<
          PrimarySearchRequest,
          PrimarySearchRequest,
          PrimarySearchRequest
        >
    with $Provider<PrimarySearchRequest> {
  /// Resolves the primary search surface for the current route context.
  ///
  /// Keeping the complete request behind a provider lets alternate application
  /// hosts supply their own data source while retaining the production surface
  /// and result renderers.
  PrimarySearchRequestProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'primarySearchRequestProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$primarySearchRequestHash();

  @$internal
  @override
  $ProviderElement<PrimarySearchRequest> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PrimarySearchRequest create(Ref ref) {
    return primarySearchRequest(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PrimarySearchRequest value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PrimarySearchRequest>(value),
    );
  }
}

String _$primarySearchRequestHash() =>
    r'afc2fe822e3e03184065220cac0df835b38ce366';
