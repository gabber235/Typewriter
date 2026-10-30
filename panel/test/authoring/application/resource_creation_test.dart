import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  final fixture = ResourceCreationFixture();
  final request = fixture.request("Book");
  final saved = fixture.document();
  final detail = skir.InitializationDiagnostic(
    field: null,
    code: "preparation_detail",
    message: "A retained preparation finding",
    relativePath: skir.ValuePath(segments: const []),
  );

  testWidgets("a creation stages its resource with the Realm's preparation "
      "findings and saves it in its single store", (tester) async {
    final reply = Completer<void>();
    final panel = await tester.pumpPanel([
      ...adaServing(saved),
      heldPreparations(reply.future, findings: [detail]),
    ]);

    final creation = await panel.create(request);
    // Nothing is staged while the Realm prepares the resource.
    expect(panel.workingDocument.resource(request.id), isNull);
    reply.complete();
    await panel.settle();

    expect(creation.created?.resourceId, request.id);
    expect(
      panel.workingDocument.initializationFindings.single.diagnostic.code,
      "preparation_detail",
    );
    final realm = panel.world.requireRealm;
    await panel.eventually(() => expect(realm.saves, hasLength(1)));
    expect(
      realm.document.entry(request.id)?.content.configuration,
      request.configuration,
    );
    // The single store holds the resource without an owner question.
    expect(realm.document.relations.parents[request.id], [fixture.store]);
  });

  final cancellations = <String, Future<void> Function(PanelDriver panel)>{
    "leaving the Realm": (panel) => panel.container
        .read(appRouterProvider)
        .navigate(OrganizationRoute(organizationId: acme.organizationId.id)),
    "leaving and returning to the Realm": (panel) async {
      final router = panel.container.read(appRouterProvider);
      await router.navigate(
        OrganizationRoute(organizationId: acme.organizationId.id),
      );
      await panel.settle();
      await router.navigate(
        const RealmRouteTree().realm(panel.world.requireRealm.scope),
      );
    },
    "a catalog change": (panel) async => panel.world.requireRealm.serve(
      saved.withCatalogGeneration("catalog:changed"),
    ),
    "a catalog change undone before the reply": (panel) async {
      final realm = panel.world.requireRealm
        ..serve(saved.withCatalogGeneration("catalog:changed"));
      await panel.settle();
      realm.serve(saved);
    },
  };
  for (final MapEntry(key: change, value: apply) in cancellations.entries) {
    testWidgets("$change cancels a creation waiting for its preparation", (
      tester,
    ) async {
      final reply = Completer<void>();
      final panel = await tester.pumpPanel([
        ...adaServing(saved),
        heldPreparations(reply.future, findings: [detail]),
      ]);

      final creation = await panel.create(request);
      await apply(panel);
      await panel.settle();
      reply.complete();
      await panel.settle();

      expect(creation.done, isTrue);
      expect(creation.created, isNull);
      expect(panel.world.requireRealm.saves, isEmpty);
      expect(panel.world.requireRealm.document.resource(request.id), isNull);
    });
  }

  testWidgets("closing the panel cancels a creation waiting for its "
      "preparation", (tester) async {
    final reply = Completer<void>();
    final panel = await tester.pumpPanel([
      ...adaServing(saved),
      heldPreparations(reply.future, findings: [detail]),
    ]);
    final realm = panel.world.requireRealm;

    final creation = await panel.create(request);
    await tester.pumpWidget(const SizedBox());
    reply.complete();
    await tester.pump();

    expect(creation.created, isNull);
    expect(realm.saves, isEmpty);
  });

  testWidgets("a creation for a Realm the panel no longer shows never "
      "starts", (tester) async {
    final reply = Completer<void>()..complete();
    final panel = await tester.pumpPanel([
      ...adaServing(saved),
      heldPreparations(reply.future, findings: [detail]),
    ]);
    final realm = panel.world.requireRealm;
    var prepared = false;
    realm.answerPrepareStep = (step) async {
      prepared = true;
      return realm.document.prepareStep(step);
    };
    final left = AuthoringScope(
      organizationId: realm.scope.organizationId,
      realmId: skir.recordId("realm_instance:left"),
    );

    final creation = await panel.create(request, scope: left);

    expect(creation.done, isTrue);
    expect(creation.created, isNull);
    expect(prepared, isFalse);
    expect(realm.saves, isEmpty);
  });
}
