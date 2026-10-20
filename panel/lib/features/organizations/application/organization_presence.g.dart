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
/// organization state. Unknown subject identities and older active sequence
/// numbers are ignored; payload decoding still reports malformed wire data.

@ProviderFor(OrganizationPresence)
final organizationPresenceProvider = OrganizationPresenceProvider._();

/// Publishes and observes ephemeral collaboration presence for one organization.
///
/// The provider owns one session identity, its heartbeat timers, subscription,
/// sequence counter, and cleanup. Heartbeats are best effort and remote sessions
/// expire locally after missed heartbeats. Presence is never used as durable
/// organization state. Unknown subject identities and older active sequence
/// numbers are ignored; payload decoding still reports malformed wire data.
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
  /// organization state. Unknown subject identities and older active sequence
  /// numbers are ignored; payload decoding still reports malformed wire data.
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
    r'f2a98efce1a1ff51b9b4194587fb6507370e01af';

/// Publishes and observes ephemeral collaboration presence for one organization.
///
/// The provider owns one session identity, its heartbeat timers, subscription,
/// sequence counter, and cleanup. Heartbeats are best effort and remote sessions
/// expire locally after missed heartbeats. Presence is never used as durable
/// organization state. Unknown subject identities and older active sequence
/// numbers are ignored; payload decoding still reports malformed wire data.

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
