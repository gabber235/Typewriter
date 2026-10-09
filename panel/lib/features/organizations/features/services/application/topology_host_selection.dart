part of "services.dart";

class _ServiceHostSelectable
    extends InspectableSelectable<ServiceHostIdentifier> {
  const _ServiceHostSelectable({
    required this.id,
    required this.host,
    required this.service,
    required this.topology,
    required this.connected,
    required this.configurationTarget,
    required this.onUnbind,
    required this.serviceIdentityTarget,
  });

  @override
  final ServiceHostIdentifier id;
  final TopologyHost host;
  final Service? service;
  final OrganizationTopology topology;
  final bool connected;
  final EditorTarget configurationTarget;
  final Future<void> Function()? onUnbind;
  final EditorTarget? serviceIdentityTarget;

  @override
  List<PortableMultiInspectionSurface> get portableMultiInspectionSurfaces => [
    if (serviceIdentityTarget case final target?)
      _ServiceIdentityPortableSurface(target),
    _ServiceHostConfigurationPortableSurface(
      selectable: this,
      target: configurationTarget,
    ),
  ];

  HostEditorSnapshot get _configuration =>
      configurationTarget.snapshot as HostEditorSnapshot;
  Map<String, List<String>> get _realmTargets => _configuration._realmTargets;
  Map<String, List<String>> get _engineTargets => _configuration._engineTargets;

  @override
  String get name => service?.displayName ?? host.hostId.id;

  @override
  List<SelectionCapability> get capabilities => [
    if (onUnbind case final unbind?)
      UnbindSelectionCapability(onUnbind: unbind),
  ];

  @override
  InspectionContent buildInspection(EditorOwnerScope owners) {
    final configurationOwner = owners.editor(configurationTarget);
    final identityOwner = serviceIdentityTarget == null
        ? null
        : owners.editor(serviceIdentityTarget!);
    return InspectionContent(
      host: topologyHostPortableHost(
        host: host,
        service: service,
        connected: connected,
        configurationOwner: configurationOwner,
        identityOwner: identityOwner,
        realmTargets: _realmTargets,
        engineTargets: _engineTargets,
        realms: topology.realmInstances
            .where((realm) => realm.ownerHost.id != host.hostId)
            .toList(),
      ),
    );
  }
}

final class _ServiceHostConfigurationPortableSurface
    implements PortableMultiInspectionSurface {
  const _ServiceHostConfigurationPortableSurface({
    required this.selectable,
    required this.target,
  });

  final _ServiceHostSelectable selectable;

  @override
  Object get id => "service.host.configuration";

  @override
  final EditorTarget target;

  @override
  TypeExpression get rootType => _hostConfigurationType;

  @override
  TypeCatalog get typeCatalog => _hostConfigurationCatalog;

  @override
  bool isCompatibleWith(PortableMultiInspectionSurface other) =>
      other is _ServiceHostConfigurationPortableSurface;

  @override
  PortablePresentationHost buildHost(
    List<PortableMultiInspectionSurface> members,
    EditOwner combinedOwner,
    Future<void> Function() commit,
  ) {
    final hosts = members
        .cast<_ServiceHostConfigurationPortableSurface>()
        .map((surface) => surface.selectable)
        .toList();
    final first = hosts.first;
    final selectedHostIds = hosts.map((host) => host.host.hostId).toSet();
    return topologyHostPortableHost(
      host: first.host,
      service: first.service,
      connected: hosts.every((host) => host.connected),
      configurationOwner: combinedOwner,
      identityOwner: null,
      realmTargets: _commonTargets(hosts.map((host) => host._realmTargets)),
      engineTargets: _commonTargets(hosts.map((host) => host._engineTargets)),
      realms: first.topology.realmInstances
          .where((realm) => !selectedHostIds.contains(realm.ownerHost.id))
          .toList(),
      configurationOnly: true,
      commit: commit,
    );
  }
}

Map<String, List<String>> _commonTargets(
  Iterable<Map<String, List<String>>> values,
) {
  final inputs = values.toList();
  if (inputs.isEmpty) return const {};
  return {
    for (final entry in inputs.first.entries)
      if (inputs.skip(1).every((value) => value.containsKey(entry.key)))
        entry.key: entry.value
            .where(
              (version) => inputs
                  .skip(1)
                  .every((value) => value[entry.key]!.contains(version)),
            )
            .toList(),
  }..removeWhere((key, versions) => versions.isEmpty);
}
