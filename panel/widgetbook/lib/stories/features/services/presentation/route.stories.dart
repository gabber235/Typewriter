import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/features/topology.dart";
import "package:widgetbook_workspace/stories/features/members/membership_story.dart";
import "package:widgetbook_workspace/support/story.dart";

@widgetbook.UseCase(name: "Default", type: ServicesPage)
Widget servicesPageUseCase(BuildContext context) {
  final scenario = completeTopologyScenario();
  const unreachable = "The services backend is unreachable";
  return Story([
    signedIn(ada, organization: acme),
    ...context.knobs.traits("Services", {
      "Complete": [
        servicesService(
          services: scenario.services,
          topology: scenario.topology,
        ),
      ],
      "No services": [servicesService()],
      "Services loading": [
        servicesService(services: null, topology: scenario.topology),
      ],
      "Services failing": [
        servicesService(
          services: null,
          topology: scenario.topology,
          failure: StateError(unreachable),
        ),
      ],
      "Topology loading": [
        servicesService(services: scenario.services, topologyArrives: false),
      ],
      "Topology failing": [
        servicesService(
          services: scenario.services,
          topologyArrives: false,
          failure: StateError(unreachable),
        ),
      ],
    }),
    ...context.knobs.traits("Window", {
      "Desktop": const [],
      "Compact": const [compact],
    }),
  ], at: _servicesRoute);
}

/// The services page with one node of the complete topology selected, so the
/// inspector shows it; every service, host, Realm and engine is listed by
/// what it is and the state it is in.
@widgetbook.UseCase(name: "Inspector", type: ServicesPage)
Widget servicesInspectorUseCase(BuildContext context) {
  final scenario = completeTopologyScenario();
  final topology = scenario.topology;
  return Story([
    signedIn(ada, organization: acme),
    servicesService(services: scenario.services, topology: topology),
    ...context.knobs.traits("Selected", {
      for (final service in scenario.services)
        "Service ${service.name}, ${service.state?.status == skir.ServiceStatus.online ? "online" : "offline"}":
            [
              selected([ServiceIdentifier(service.serviceId)]),
            ],
      for (final host in topology.hosts)
        "Host ${host.hostId.id}, ${hostRuntimeStatusLabel(host.state.status)}":
            [
              selected([ServiceHostIdentifier(host.hostId)]),
            ],
      for (final realm in topology.realms)
        "Realm ${realm.realmId.id}, ${childRuntimeStatusLabel(realm.state.status)}":
            [
              selected([RealmInstanceIdentifier(realm.realmId)]),
            ],
      for (final engine in topology.engines)
        "Engine ${engine.engineId.id}, ${childRuntimeStatusLabel(engine.state.status)}":
            [
              selected([EngineInstanceIdentifier(engine.engineId)]),
            ],
    }),
  ], at: _servicesRoute);
}

/// The registration token input on the services page, where it binds a new
/// service: an invalid token is refused before it is sent, a valid one
/// (`ABCDE12345`) adds a service to the graph, slowly or with a failure.
@widgetbook.UseCase(name: "Default", type: RegistrationTokenInput)
Widget registrationTokenInputUseCase(BuildContext context) {
  final answers = context.knobs.object.dropdown(
    label: "Service answers",
    options: const ["At once", "Slowly", "With a failure"],
    initialOption: "At once",
  );
  return Story([
    signedIn(ada, organization: acme),
    servicesService(
      commandFailure: answers == "With a failure"
          ? StateError("The registration token is unknown")
          : null,
    ),
    if (answers == "Slowly") latency(const Duration(seconds: 3)),
  ], at: _servicesRoute);
}

/// The services graph on its own, over the topology it is handed.
@widgetbook.UseCase(name: "Default", type: ServicesGraph)
Widget servicesGraphUseCase(BuildContext context) {
  final scenario = completeTopologyScenario();
  final first = scenario.topology.hosts.first;
  final graphs = {
    "Complete": scenario,
    "Single host": TopologyScenario(
      topology: skir.OrganizationTopologySnapshot(
        hosts: [first],
        realms: [
          for (final realm in scenario.topology.realms)
            if (realm.ownerHost.id == first.hostId) realm,
        ],
        engines: [
          for (final engine in scenario.topology.engines)
            if (engine.ownerHost.id == first.hostId) engine,
        ],
      ),
      services: [
        for (final service in scenario.services)
          if (service.serviceId == first.serviceId) service,
      ],
    ),
    "Empty": TopologyScenario(
      topology: skir.OrganizationTopologySnapshot.defaultInstance,
      services: const [],
    ),
  };
  final graph = context.knobs.object.dropdown(
    label: "Graph",
    options: graphs.keys.toList(),
    initialOption: "Complete",
  );
  final shown = graphs[graph]!;
  return Story(
    [signedIn(ada, organization: acme)],
    at: PanelLocation.component(
      ServicesGraph(services: shown.services, topology: shown.topology),
    ),
  );
}

final _servicesRoute = PanelLocation.route(
  organizationPage(const ServicesRoute()),
);
