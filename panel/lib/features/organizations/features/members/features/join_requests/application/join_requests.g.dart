// GENERATED CODE. DO NOT MODIFY BY HAND

part of 'join_requests.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE. DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Owns the current organization moderation projection.
///
/// The authenticated user and selected organization determine the stream
/// subjects. Sequenced broker events and confirmed command facts share one
/// admission path. Expired and pending rows are filtered by the derived
/// visibility providers while this owner retains the complete server snapshot.

@ProviderFor(OrganizationJoinRequests)
final organizationJoinRequestsProvider = OrganizationJoinRequestsProvider._();

/// Owns the current organization moderation projection.
///
/// The authenticated user and selected organization determine the stream
/// subjects. Sequenced broker events and confirmed command facts share one
/// admission path. Expired and pending rows are filtered by the derived
/// visibility providers while this owner retains the complete server snapshot.
final class OrganizationJoinRequestsProvider
    extends
        $StreamNotifierProvider<
          OrganizationJoinRequests,
          List<OrganizationJoinRequest>
        > {
  /// Owns the current organization moderation projection.
  ///
  /// The authenticated user and selected organization determine the stream
  /// subjects. Sequenced broker events and confirmed command facts share one
  /// admission path. Expired and pending rows are filtered by the derived
  /// visibility providers while this owner retains the complete server snapshot.
  OrganizationJoinRequestsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'organizationJoinRequestsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$organizationJoinRequestsHash();

  @$internal
  @override
  OrganizationJoinRequests create() => OrganizationJoinRequests();
}

String _$organizationJoinRequestsHash() =>
    r'2f2e17bfe3cdb98d119d573cfb83494df30d8135';

/// Owns the current organization moderation projection.
///
/// The authenticated user and selected organization determine the stream
/// subjects. Sequenced broker events and confirmed command facts share one
/// admission path. Expired and pending rows are filtered by the derived
/// visibility providers while this owner retains the complete server snapshot.

abstract class _$OrganizationJoinRequests
    extends $StreamNotifier<List<OrganizationJoinRequest>> {
  Stream<List<OrganizationJoinRequest>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<OrganizationJoinRequest>>,
              List<OrganizationJoinRequest>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<OrganizationJoinRequest>>,
                List<OrganizationJoinRequest>
              >,
              AsyncValue<List<OrganizationJoinRequest>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Counts unexpired requests in the current moderation projection.
///
/// Loading and error states report zero because the sidebar badge cannot claim
/// a pending count until the projection is available.

@ProviderFor(joinRequestCount)
final joinRequestCountProvider = JoinRequestCountProvider._();

/// Counts unexpired requests in the current moderation projection.
///
/// Loading and error states report zero because the sidebar badge cannot claim
/// a pending count until the projection is available.

final class JoinRequestCountProvider extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// Counts unexpired requests in the current moderation projection.
  ///
  /// Loading and error states report zero because the sidebar badge cannot claim
  /// a pending count until the projection is available.
  JoinRequestCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'joinRequestCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$joinRequestCountHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return joinRequestCount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$joinRequestCountHash() => r'2517beb398fc05db3005e89d5a1a069bcb99e34c';
