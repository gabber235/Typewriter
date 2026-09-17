// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_join_requests.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Owns the authenticated user's pending join request projection.
///
/// Snapshot and change events are reconciled by the user scoped sequence. A gap
/// invalidates the provider for a fresh snapshot. Mutations use operation
/// identities and classify uncertain responses through the shared mutation layer.
/// Cancellation is optimistic, but any failure restores the previous list and
/// invalidates the stream so recovery uses server state.

@ProviderFor(UserJoinRequests)
final userJoinRequestsProvider = UserJoinRequestsProvider._();

/// Owns the authenticated user's pending join request projection.
///
/// Snapshot and change events are reconciled by the user scoped sequence. A gap
/// invalidates the provider for a fresh snapshot. Mutations use operation
/// identities and classify uncertain responses through the shared mutation layer.
/// Cancellation is optimistic, but any failure restores the previous list and
/// invalidates the stream so recovery uses server state.
final class UserJoinRequestsProvider
    extends $StreamNotifierProvider<UserJoinRequests, List<UserJoinRequest>> {
  /// Owns the authenticated user's pending join request projection.
  ///
  /// Snapshot and change events are reconciled by the user scoped sequence. A gap
  /// invalidates the provider for a fresh snapshot. Mutations use operation
  /// identities and classify uncertain responses through the shared mutation layer.
  /// Cancellation is optimistic, but any failure restores the previous list and
  /// invalidates the stream so recovery uses server state.
  UserJoinRequestsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userJoinRequestsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userJoinRequestsHash();

  @$internal
  @override
  UserJoinRequests create() => UserJoinRequests();
}

String _$userJoinRequestsHash() => r'953d4a3b7a2aa42ad32991f1756f2f9659668cd8';

/// Owns the authenticated user's pending join request projection.
///
/// Snapshot and change events are reconciled by the user scoped sequence. A gap
/// invalidates the provider for a fresh snapshot. Mutations use operation
/// identities and classify uncertain responses through the shared mutation layer.
/// Cancellation is optimistic, but any failure restores the previous list and
/// invalidates the stream so recovery uses server state.

abstract class _$UserJoinRequests
    extends $StreamNotifier<List<UserJoinRequest>> {
  Stream<List<UserJoinRequest>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<UserJoinRequest>>, List<UserJoinRequest>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<UserJoinRequest>>,
                List<UserJoinRequest>
              >,
              AsyncValue<List<UserJoinRequest>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
