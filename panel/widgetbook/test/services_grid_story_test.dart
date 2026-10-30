import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook_workspace/data/features/topology.dart";
import "package:widgetbook_workspace/stories/features/services/presentation/route.stories.dart";

import "support/stories.dart";

void main() {
  test("the complete scenario covers every host role and runtime state", () {
    final now = DateTime.utc(2026, 8, 22, 12);
    withClock(Clock.fixed(now), () {
      final scenario = completeTopologyScenario();
      final topology = scenario.topology;

      expect(topology.hosts.map((host) => host.entrypoint).toSet(), {
        "PAPER",
        "STANDALONE",
      });
      expect(topology.hosts.map((host) => host.state.status).toSet(), {
        skir.HostRuntimeStatus.active,
        skir.HostRuntimeStatus.reconciling,
        skir.HostRuntimeStatus.drifted,
        skir.HostRuntimeStatus.failed,
        skir.HostRuntimeStatus.offline,
      });
      expect(
        {
          ...topology.realms.map((realm) => realm.state.status),
          ...topology.engines.map((engine) => engine.state.status),
        },
        {
          skir.ChildRuntimeStatus.absent,
          skir.ChildRuntimeStatus.staging,
          skir.ChildRuntimeStatus.active,
          skir.ChildRuntimeStatus.quiescing,
          skir.ChildRuntimeStatus.failed,
          skir.ChildRuntimeStatus.rolledBack,
          skir.ChildRuntimeStatus.drifted,
        },
      );
      expect(
        scenario.services.where((service) => service.isConnectedAt(now)),
        isNotEmpty,
      );
      expect(
        scenario.services.where((service) => !service.isConnectedAt(now)),
        isNotEmpty,
      );
      expect(
        scenario.services.where((service) => service.isCustom),
        hasLength(4),
      );
    });
  });

  testWidgets("selecting a host in the graph inspects it", (tester) async {
    final panel = (await tester.pumpStory(servicesPageUseCase))!;

    await tester.tap(find.text("PAPER HOST").first);
    await tester.runStory();

    for (final label in [
      "CONNECTION",
      "Entry point",
      "Realm hosting",
      "RUNTIME HEALTH",
      "Host a Realm",
      "Run an execution engine",
    ]) {
      expect(panel.shows(label), isTrue, reason: label);
    }
    expect(panel.shows("Apply"), isFalse);
  });

  testWidgets("a service inspector shows its connection", (tester) async {
    final service = completeTopologyScenario().services.first;
    final panel = (await tester.pumpStory(
      servicesInspectorUseCase,
      knobs: {"Selected": "Service ${service.name}, online"},
    ))!;

    for (final label in [
      service.name,
      "CONNECTION",
      "Connected",
      "Version",
      service.role.version,
      "Last seen",
    ]) {
      expect(panel.shows(label), isTrue, reason: label);
    }
    expect(panel.shows("The presentation value is not text"), isFalse);
  });

  testWidgets("every host inspector shows its capabilities and health", (
    tester,
  ) async {
    for (final host in completeTopologyScenario().topology.hosts) {
      final panel = (await tester.pumpStory(
        servicesInspectorUseCase,
        knobs: {"Selected": _hostLabel(host)},
      ))!;

      expect(panel.shows("CAPABILITIES"), isTrue, reason: host.hostId.id);
      expect(panel.shows("RUNTIME HEALTH"), isTrue, reason: host.hostId.id);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets("turning Realm hosting off asks which Realm to assign", (
    tester,
  ) async {
    final host = completeTopologyScenario().topology.hosts.first;
    final panel = (await tester.pumpStory(
      servicesInspectorUseCase,
      knobs: {"Selected": _hostLabel(host)},
    ))!;
    expect(panel.shows("Assigned Realm"), isFalse);

    await tester.ensureVisible(find.text("Host a Realm"));
    tester.semantics.tap(_toggle("Host a Realm"));
    await tester.runStory();

    expect(panel.shows("Assigned Realm"), isTrue);
  });

  testWidgets(
    "from the name field, Tab reaches the Realm hosting toggle and Space turns it off",
    (tester) async {
      final host = completeTopologyScenario().topology.hosts.first;
      final panel = (await tester.pumpStory(
        servicesInspectorUseCase,
        knobs: {"Selected": _hostLabel(host)},
      ))!;

      await panel.field("Name").focus();
      // The toggle reads its label twice, so focus is matched by containment.
      bool focused() => panel.focused?.contains("Host a Realm") ?? false;
      for (var tabs = 0; tabs < 20 && !focused(); tabs++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
      }
      expect(focused(), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.runStory();

      expect(panel.shows("Assigned Realm"), isTrue);
    },
  );

  testWidgets("turning the execution engine on asks for its target", (
    tester,
  ) async {
    final host = completeTopologyScenario().topology.hosts.first;
    final panel = (await tester.pumpStory(
      servicesInspectorUseCase,
      knobs: {"Selected": _hostLabel(host)},
    ))!;
    final targeted = panel.shows("Engine target");

    await tester.ensureVisible(find.text("Run an execution engine"));
    tester.semantics.tap(_toggle("Run an execution engine"));
    await tester.runStory();

    expect(panel.shows("Engine target"), !targeted);
  });

  testWidgets("a failed Realm inspector keeps its status message", (
    tester,
  ) async {
    final failed = completeTopologyScenario().topology.realms.firstWhere(
      (realm) => realm.state.status == skir.ChildRuntimeStatus.failed,
    );
    final panel = (await tester.pumpStory(
      servicesInspectorUseCase,
      knobs: {"Selected": "Realm ${failed.realmId.id}, Failed"},
    ))!;

    expect(panel.shows(failed.state.message!), isTrue);
    expect(panel.shows("ASSIGNMENT"), isTrue);
    expect(panel.shows("Assigned Realm"), isFalse);
  });

  testWidgets("a rolled back engine inspector shows its assigned Realm", (
    tester,
  ) async {
    final engine = completeTopologyScenario().topology.engines.firstWhere(
      (engine) => engine.state.status == skir.ChildRuntimeStatus.rolledBack,
    );
    final panel = (await tester.pumpStory(
      servicesInspectorUseCase,
      knobs: {"Selected": "Engine ${engine.engineId.id}, Rolled back"},
    ))!;

    expect(panel.shows("Assigned Realm"), isTrue);
  });
}

/// The checkbox of the inspector toggle [label]; it reads its label twice,
/// so the label is matched by containment.
SemanticsFinder _toggle(String label) => find.semantics.byPredicate(
  (node) =>
      node.label.contains(label) &&
      node.getSemanticsData().flagsCollection.isChecked != CheckedState.none,
);

/// The label the inspector story lists [host] under.
String _hostLabel(skir.ServiceHost host) =>
    "Host ${host.hostId.id}, ${hostRuntimeStatusLabel(host.state.status)}";
