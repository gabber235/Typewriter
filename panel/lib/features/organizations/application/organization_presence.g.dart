// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'organization_presence.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(OrganizationPresence)
final organizationPresenceProvider = OrganizationPresenceProvider._();

final class OrganizationPresenceProvider
    extends
        $AsyncNotifierProvider<
          OrganizationPresence,
          Map<PresenceSessionKey, ActivePanelPresence>
        > {
  OrganizationPresenceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'organizationPresenceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$organizationPresenceHash();

  @$internal
  @override
  OrganizationPresence create() => OrganizationPresence();
}

String _$organizationPresenceHash() =>
    r'33c4a20d11d71d4b6f2c7ef54cde0c22624a145a';

abstract class _$OrganizationPresence
    extends $AsyncNotifier<Map<PresenceSessionKey, ActivePanelPresence>> {
  FutureOr<Map<PresenceSessionKey, ActivePanelPresence>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<Map<PresenceSessionKey, ActivePanelPresence>>,
              Map<PresenceSessionKey, ActivePanelPresence>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<Map<PresenceSessionKey, ActivePanelPresence>>,
                Map<PresenceSessionKey, ActivePanelPresence>
              >,
              AsyncValue<Map<PresenceSessionKey, ActivePanelPresence>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
