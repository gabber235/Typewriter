// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'join_codes.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for the join codes in the current organization.

@ProviderFor(OrganizationJoinCodes)
final organizationJoinCodesProvider = OrganizationJoinCodesProvider._();

/// Provider for the join codes in the current organization.
final class OrganizationJoinCodesProvider
    extends
        $StreamNotifierProvider<
          OrganizationJoinCodes,
          List<OrganizationJoinCode>
        > {
  /// Provider for the join codes in the current organization.
  OrganizationJoinCodesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'organizationJoinCodesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$organizationJoinCodesHash();

  @$internal
  @override
  OrganizationJoinCodes create() => OrganizationJoinCodes();
}

String _$organizationJoinCodesHash() =>
    r'f1c5efbd6f0a67f49100e50a0b9d2658ad8551ef';

/// Provider for the join codes in the current organization.

abstract class _$OrganizationJoinCodes
    extends $StreamNotifier<List<OrganizationJoinCode>> {
  Stream<List<OrganizationJoinCode>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<OrganizationJoinCode>>,
              List<OrganizationJoinCode>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<OrganizationJoinCode>>,
                List<OrganizationJoinCode>
              >,
              AsyncValue<List<OrganizationJoinCode>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Provider for the count of active join codes.

@ProviderFor(joinCodeCount)
final joinCodeCountProvider = JoinCodeCountProvider._();

/// Provider for the count of active join codes.

final class JoinCodeCountProvider extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// Provider for the count of active join codes.
  JoinCodeCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'joinCodeCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$joinCodeCountHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return joinCodeCount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$joinCodeCountHash() => r'422bf73b9b48b40efcf2dc1e9e2cf897eddbbfbc';
