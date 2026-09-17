// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'organization_presence.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Publishes and observes ephemeral collaboration presence for one organization.
///
/// The provider owns one session identity, its heartbeat timers, subscription,
/// sequence counter, and cleanup. Heartbeats are best effort and remote sessions
/// expire locally after missed heartbeats. Presence is never used as durable
/// organization state, and malformed or out of order observations are discarded
/// at this boundary.

@ProviderFor(OrganizationPresence)
final organizationPresenceProvider = OrganizationPresenceProvider._();

/// Publishes and observes ephemeral collaboration presence for one organization.
///
/// The provider owns one session identity, its heartbeat timers, subscription,
/// sequence counter, and cleanup. Heartbeats are best effort and remote sessions
/// expire locally after missed heartbeats. Presence is never used as durable
/// organization state, and malformed or out of order observations are discarded
/// at this boundary.
final class OrganizationPresenceProvider
    extends
        $AsyncNotifierProvider<
          OrganizationPresence,
          Map<PresenceSessionKey, ActivePanelPresence>
        > {
  /// Publishes and observes ephemeral collaboration presence for one organization.
  ///
  /// The provider owns one session identity, its heartbeat timers, subscription,
  /// sequence counter, and cleanup. Heartbeats are best effort and remote sessions
  /// expire locally after missed heartbeats. Presence is never used as durable
  /// organization state, and malformed or out of order observations are discarded
  /// at this boundary.
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
    r'7e84dd45ebae5f4e5b491aeb0acf965a2071e9d5';

/// Publishes and observes ephemeral collaboration presence for one organization.
///
/// The provider owns one session identity, its heartbeat timers, subscription,
/// sequence counter, and cleanup. Heartbeats are best effort and remote sessions
/// expire locally after missed heartbeats. Presence is never used as durable
/// organization state, and malformed or out of order observations are discarded
/// at this boundary.

abstract class _$OrganizationPresence
    extends $AsyncNotifier<Map<PresenceSessionKey, ActivePanelPresence>> {
  FutureOr<Map<PresenceSessionKey, ActivePanelPresence>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
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
    return element.handleCreate(ref, build);
  }
}
