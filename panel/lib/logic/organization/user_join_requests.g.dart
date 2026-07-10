// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_join_requests.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(UserJoinRequests)
final userJoinRequestsProvider = UserJoinRequestsProvider._();

final class UserJoinRequestsProvider
    extends $StreamNotifierProvider<UserJoinRequests, List<UserJoinRequest>> {
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

String _$userJoinRequestsHash() => r'2c8e649cf3b30167a57e2f1bcdb94fd3f2093146';

abstract class _$UserJoinRequests
    extends $StreamNotifier<List<UserJoinRequest>> {
  Stream<List<UserJoinRequest>> build();
  @$mustCallSuper
  @override
  void runBuild() {
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
    element.handleCreate(ref, build);
  }
}
