import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

final _organization = acme.organizationId;

final _service = service("one", status: null);

final _host = paperHost("one", service: _service.serviceId);

final _topology = skir.OrganizationTopologySnapshot(
  hosts: [_host],
  realms: [],
  engines: [],
);

void main() {
  testWidgets("the open organization's services follow its backend", (
    tester,
  ) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      servicesBackend(),
    ]);
    expect(panel.container.read(canonicalServicesProvider).value, isEmpty);

    panel.world.nats.announceServices(
      _organization,
      skir.OrganizationServicesChanged.wrapReplace([_service]),
    );

    await panel.eventually(
      () => expect(panel.container.read(canonicalServicesProvider).value, [
        _service,
      ]),
    );
    await panel.settle();
  });

  testWidgets("the open organization's topology follows its backend", (
    tester,
  ) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      servicesBackend(),
    ]);
    expect(
      panel.container.read(organizationTopologyProvider).value,
      skir.OrganizationTopologySnapshot.defaultInstance,
    );

    panel.world.nats.announceTopology(
      _organization,
      skir.OrganizationTopologyChanged.wrapReplace(_topology),
    );

    await panel.eventually(
      () => expect(
        panel.container.read(organizationTopologyProvider).value,
        _topology,
      ),
    );
    await panel.settle();
  });

  testWidgets("a failed services watch fails the open organization's "
      "services", (tester) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      servicesBackend(),
    ]);

    panel.world.nats.announceServices(
      _organization,
      skir.OrganizationServicesChanged.unknown,
    );

    await panel.eventually(
      () => expect(
        panel.container.read(canonicalServicesProvider).error,
        isA<ApiException>().having((error) => error.code, "code", 422),
      ),
    );
    await panel.settle();
  });
}
