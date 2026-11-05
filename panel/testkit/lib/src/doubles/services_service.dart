import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/doubles/nats.dart";

/// The services side of one organization, answering the panel over NATS:
/// the organization list, the runtime topology and the services.
///
/// The panel's real projections and service commands run against it. It
/// keeps what the panel sends in memory: a registration token binds a new
/// service, a rename renames, an unbind removes, and a host configuration
/// is confirmed at the next revision; each reply carries the outcome the
/// projections apply. It holds no service rules: every command succeeds.
///
/// [topology] or [services] left null never arrives, so the page keeps
/// loading, or fails with [failure] when one is given. Every command answers
/// after [latency], or fails with [commandFailure] when one is given, and
/// changes nothing.
final class FakeServicesService {
  FakeServicesService({
    List<skir.Service>? services = const [],
    skir.OrganizationTopologySnapshot? topology,
    this.topologyArrives = true,
    this.failure,
    this.commandFailure,
    this.latency = Duration.zero,
  }) : _services = services == null ? null : [...services],
       _topology =
           topology ?? skir.OrganizationTopologySnapshot.defaultInstance;

  final List<skir.Service>? _services;
  skir.OrganizationTopologySnapshot _topology;

  /// Whether the topology arrives; false keeps it loading or failing.
  final bool topologyArrives;

  /// What every source that never arrives fails with; null keeps it loading.
  final Object? failure;

  /// What every command fails with; null lets commands succeed.
  final Object? commandFailure;

  /// How long the backend takes to answer a command.
  Duration latency;

  var _bound = 0;

  /// The services as the backend holds them now.
  List<skir.Service> get services => [...?_services];

  /// Answers the requests [user] makes about [organizations] on [nats]; the
  /// first organization is the one whose services this backend holds.
  void serve(
    FakeNats nats, {
    required String user,
    required List<skir.Organization> organizations,
  }) {
    final organization = organizations.first.organizationId;

    Future<Uint8List> withheld() {
      if (failure case final error?) return Future.error(error);
      return Completer<Uint8List>().future;
    }

    final command = nats.commands(
      latency: latency,
      failure: () => commandFailure,
    );

    final organizationsWatch = skir.WatchUserOrganizationsRequest().operation(
      userId: user,
    );
    nats.registerHandler(
      organizationsWatch.subject,
      (_) => organizationsWatch.responseSerializer.toBytes(
        skir.WatchUserOrganizationsResponse.createSnapshot(
          sequence: 1,
          values: organizations,
        ),
      ),
    );
    final topologyWatch = skir.WatchOrganizationTopologyRequest().operation(
      userId: user,
      organizationId: organization,
    );
    nats.registerHandler(
      topologyWatch.subject,
      (_) => topologyArrives
          ? topologyWatch.responseSerializer.toBytes(
              skir.WatchOrganizationTopologyResponse.wrapList(_topology),
            )
          : withheld(),
    );
    final servicesWatch = skir.WatchOrganizationServicesRequest().operation(
      userId: user,
      organizationId: organization,
    );
    nats.registerHandler(servicesWatch.subject, (_) {
      final services = _services;
      if (services == null) return withheld();
      return servicesWatch.responseSerializer.toBytes(
        skir.WatchOrganizationServicesResponse.wrapList(services),
      );
    });

    command(
      skir.BindServiceRequest.defaultInstance.operation(
        userId: user,
        organizationId: organization,
      ),
      skir.BindServiceRequest.serializer,
      (request) => _bind(request, organization),
    );
    command(
      skir.UnbindServiceRequest.defaultInstance.operation(
        userId: user,
        organizationId: organization,
      ),
      skir.UnbindServiceRequest.serializer,
      _unbind,
    );
    command(
      skir.UpdateOrganizationServiceRequest.defaultInstance.operation(
        userId: user,
        organizationId: organization,
      ),
      skir.UpdateOrganizationServiceRequest.serializer,
      _rename,
    );
    command(
      skir.ConfigureServiceHostRequest.defaultInstance.operation(
        userId: user,
        organizationId: organization,
      ),
      skir.ConfigureServiceHostRequest.serializer,
      _configure,
    );
  }

  skir.BindServiceResponse _bind(
    skir.BindServiceRequest request,
    skir.RecordId organization,
  ) {
    final name = "service_${++_bound}";
    final role = skir.ServiceRole.createCustom(
      name: "integration",
      version: "1.0.0",
    );
    _services?.add(
      skir.Service(
        serviceId: skir.recordId("service:$name"),
        revision: 1,
        name: name,
        role: role,
        createdAt: clock.now(),
        organization: organization,
        state: skir.ServiceState(
          status: skir.ServiceStatus.online,
          lastSeen: clock.now(),
        ),
        registration: null,
      ),
    );
    return skir.BindServiceResponse.wrapSuccess(
      skir.BindServiceResponse_Success(
        serviceId: "service:$name",
        serviceName: name,
        serviceRole: role,
      ),
    );
  }

  skir.UnbindServiceResponse _unbind(skir.UnbindServiceRequest request) {
    _services?.removeWhere(
      (service) => service.serviceId.id == request.serviceId,
    );
    return skir.UnbindServiceResponse.wrapSuccess(
      skir.UnbindServiceResponse_Success.defaultInstance,
    );
  }

  skir.UpdateOrganizationServiceResponse _rename(
    skir.UpdateOrganizationServiceRequest request,
  ) {
    final services = _services ?? <skir.Service>[];
    final index = services.indexWhere(
      (service) => service.serviceId == request.serviceId,
    );
    final current = services[index];
    final renamed = skir.Service(
      serviceId: current.serviceId,
      revision: current.revision + 1,
      name: request.name,
      role: current.role,
      createdAt: current.createdAt,
      organization: current.organization,
      state: current.state,
      registration: current.registration,
    );
    services[index] = renamed;
    return skir.UpdateOrganizationServiceResponse.wrapSuccess(renamed);
  }

  skir.ConfigureServiceHostResponse _configure(
    skir.ConfigureServiceHostRequest request,
  ) {
    final hosts = [..._topology.hosts];
    final index = hosts.indexWhere((host) => host.hostId == request.hostId);
    final current = hosts[index];
    final revision = current.revision + 1;
    final configured = skir.ServiceHost(
      hostId: current.hostId,
      serviceId: current.serviceId,
      revision: revision,
      entrypoint: current.entrypoint,
      canHostRealm: current.canHostRealm,
      supportedEngines: current.supportedEngines,
      topologyRevision: skir.ReconciledRevision(
        desired: revision,
        applied: revision,
      ),
      state: current.state,
    );
    hosts[index] = configured;
    _topology = skir.OrganizationTopologySnapshot(
      hosts: hosts,
      realms: _topology.realms,
      engines: _topology.engines,
    );
    return skir.ConfigureServiceHostResponse.wrapSuccess(
      skir.HostConfigurationChange(
        host: configured,
        realm: null,
        engine: null,
        removedResources: const [],
      ),
    );
  }
}
