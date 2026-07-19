// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'members.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(OrganizationMembers)
final organizationMembersProvider = OrganizationMembersProvider._();

final class OrganizationMembersProvider
    extends
        $StreamNotifierProvider<OrganizationMembers, List<OrganizationMember>> {
  OrganizationMembersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'organizationMembersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$organizationMembersHash();

  @$internal
  @override
  OrganizationMembers create() => OrganizationMembers();
}

String _$organizationMembersHash() =>
    r'e2e548f37cf16c5825cc6f851c52574615285703';

abstract class _$OrganizationMembers
    extends $StreamNotifier<List<OrganizationMember>> {
  Stream<List<OrganizationMember>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<OrganizationMember>>,
              List<OrganizationMember>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<OrganizationMember>>,
                List<OrganizationMember>
              >,
              AsyncValue<List<OrganizationMember>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
