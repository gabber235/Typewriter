part of "services.dart";

/// Lookups over the immutable organization topology read model.
///
/// Hosts carry desired configuration and host observations. Realm and engine
/// lists carry child observations. The topology controller is the mutable
/// owner; the snapshot is replaced as snapshots, watch events, and accepted
/// mutations arrive. A host references its service identity by
/// [skir.ServiceHost.serviceId]; resolve it from the canonical service
/// projection.
extension OrganizationTopologyProjection on skir.OrganizationTopologySnapshot {
  /// Finds the Realm currently reported as owned by [hostId].
  skir.RealmInstance? realmOwnedBy(skir.RecordId hostId) =>
      this.realms.firstWhereOrNull((realm) => realm.ownerHost.id == hostId);

  /// Finds the engine currently reported as owned by [hostId].
  skir.EngineInstance? engineOwnedBy(skir.RecordId hostId) =>
      engines.firstWhereOrNull((engine) => engine.ownerHost.id == hostId);
}

/// Stable presentation keys for host reconciliation states: the Skir variant
/// name of each status.
///
/// The keys select status appearances in portable inspector presentations.
/// Unknown wire values keep their own key so forward compatibility does not
/// hide runtime state from operators.
extension HostRuntimeStatusKey on skir.HostRuntimeStatus {
  /// Every status a presentation can distinguish, including unknown values.
  static const all = [
    skir.HostRuntimeStatus.offline,
    skir.HostRuntimeStatus.reconciling,
    skir.HostRuntimeStatus.active,
    skir.HostRuntimeStatus.failed,
    skir.HostRuntimeStatus.drifted,
    skir.HostRuntimeStatus.unknown,
  ];

  String get key => _variantKey(skir.HostRuntimeStatus.serializer, this);
}

/// Stable presentation keys for Realm and engine lifecycle states: the Skir
/// variant name of each status.
extension ChildRuntimeStatusKey on skir.ChildRuntimeStatus {
  /// Every status a presentation can distinguish, including unknown values.
  static const all = [
    skir.ChildRuntimeStatus.absent,
    skir.ChildRuntimeStatus.staging,
    skir.ChildRuntimeStatus.active,
    skir.ChildRuntimeStatus.quiescing,
    skir.ChildRuntimeStatus.failed,
    skir.ChildRuntimeStatus.rolledBack,
    skir.ChildRuntimeStatus.drifted,
    skir.ChildRuntimeStatus.unknown,
  ];

  String get key => _variantKey(skir.ChildRuntimeStatus.serializer, this);
}

/// The Skir name of the variant of [value], such as `rolled_back`, or
/// `unknown` for a variant this panel does not know.
String _variantKey<E>(skir.EnumSerializer<E> serializer, E value) {
  final variant = serializer.typeDescriptor.getVariant(value);
  return variant.number == 0 ? "unknown" : variant.name;
}
