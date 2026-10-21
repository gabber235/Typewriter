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
    extends
        $StreamNotifierProvider<UserJoinRequests, List<skir.UserJoinRequest>> {
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

String _$userJoinRequestsHash() => r'7c13e5b9681e63ef8d7df05980040c25b8e29c8c';

/// Owns the authenticated user's pending join request projection.
///
/// Snapshot and change events are reconciled by the user scoped sequence. A gap
/// invalidates the provider for a fresh snapshot. Mutations use operation
/// identities and classify uncertain responses through the shared mutation layer.
/// Cancellation is optimistic, but any failure restores the previous list and
/// invalidates the stream so recovery uses server state.

abstract class _$UserJoinRequests
    extends $StreamNotifier<List<skir.UserJoinRequest>> {
  Stream<List<skir.UserJoinRequest>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<skir.UserJoinRequest>>,
              List<skir.UserJoinRequest>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<skir.UserJoinRequest>>,
                List<skir.UserJoinRequest>
              >,
              AsyncValue<List<skir.UserJoinRequest>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
