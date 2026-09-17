// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'join_requests.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Owns the current organization moderation projection and its mutations.
///
/// The authenticated user and selected organization determine the stream
/// subjects. Approval is one server transaction for all selected requests and
/// roles, while decline removes one request optimistically. Both mutations use
/// operation identities and classify uncertain delivery through the shared
/// mutation layer. Failed mutations invalidate the provider so the next
/// snapshot resolves concurrent server decisions; decline also restores its
/// prior local projection before that refresh.

@ProviderFor(OrganizationJoinRequests)
final organizationJoinRequestsProvider = OrganizationJoinRequestsProvider._();

/// Owns the current organization moderation projection and its mutations.
///
/// The authenticated user and selected organization determine the stream
/// subjects. Approval is one server transaction for all selected requests and
/// roles, while decline removes one request optimistically. Both mutations use
/// operation identities and classify uncertain delivery through the shared
/// mutation layer. Failed mutations invalidate the provider so the next
/// snapshot resolves concurrent server decisions; decline also restores its
/// prior local projection before that refresh.
final class OrganizationJoinRequestsProvider
    extends
        $StreamNotifierProvider<
          OrganizationJoinRequests,
          List<OrganizationJoinRequest>
        > {
  /// Owns the current organization moderation projection and its mutations.
  ///
  /// The authenticated user and selected organization determine the stream
  /// subjects. Approval is one server transaction for all selected requests and
  /// roles, while decline removes one request optimistically. Both mutations use
  /// operation identities and classify uncertain delivery through the shared
  /// mutation layer. Failed mutations invalidate the provider so the next
  /// snapshot resolves concurrent server decisions; decline also restores its
  /// prior local projection before that refresh.
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
    r'edebe69476a0ea2be6bf35ee068f82d44ab287c7';

/// Owns the current organization moderation projection and its mutations.
///
/// The authenticated user and selected organization determine the stream
/// subjects. Approval is one server transaction for all selected requests and
/// roles, while decline removes one request optimistically. Both mutations use
/// operation identities and classify uncertain delivery through the shared
/// mutation layer. Failed mutations invalidate the provider so the next
/// snapshot resolves concurrent server decisions; decline also restores its
/// prior local projection before that refresh.

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

String _$joinRequestCountHash() => r'297dcfa4f5bd0b642bcc4f3b163ee3ac79fac7bd';
