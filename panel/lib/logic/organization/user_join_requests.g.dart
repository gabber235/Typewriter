// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_join_requests.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(UserJoinRequests)
const userJoinRequestsProvider = UserJoinRequestsProvider._();

final class UserJoinRequestsProvider
    extends $AsyncNotifierProvider<UserJoinRequests, List<UserJoinRequest>> {
  const UserJoinRequestsProvider._()
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

String _$userJoinRequestsHash() => r'6a1e86efca5d3bc7dc53a604703fa79d67b76a41';

abstract class _$UserJoinRequests
    extends $AsyncNotifier<List<UserJoinRequest>> {
  FutureOr<List<UserJoinRequest>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
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
    element.handleValue(ref, created);
  }
}
