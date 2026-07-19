// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'join_requests.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(OrganizationJoinRequests)
final organizationJoinRequestsProvider = OrganizationJoinRequestsProvider._();

final class OrganizationJoinRequestsProvider
    extends
        $StreamNotifierProvider<
          OrganizationJoinRequests,
          List<OrganizationJoinRequest>
        > {
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
    r'a54be2bbd6f4ce22d30ed33d6d4ecbf75ecb87ef';

abstract class _$OrganizationJoinRequests
    extends $StreamNotifier<List<OrganizationJoinRequest>> {
  Stream<List<OrganizationJoinRequest>> build();
  @$mustCallSuper
  @override
  void runBuild() {
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
    element.handleCreate(ref, build);
  }
}

/// Provider for the count of pending join requests.

@ProviderFor(joinRequestCount)
final joinRequestCountProvider = JoinRequestCountProvider._();

/// Provider for the count of pending join requests.

final class JoinRequestCountProvider extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// Provider for the count of pending join requests.
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
