import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  late LocalWorkScope current;
  late bool blocksNavigation;
  late WorkSessionLossController controller;

  setUp(() {
    current = workScopeIn("one");
    blocksNavigation = true;
    controller = WorkSessionLossController(
      () => current,
      () => blocksNavigation,
    );
  });

  final globex = organization("Globex");

  testWidgets("a draft makes leaving the organization ask, and staying keeps "
      "it", (tester) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme, others: [globex]),
      realm(),
    ]);
    final realmScope = panel.world.requireRealm.scope;
    final source =
        fakeEditorTarget(
            targetId: "resource",
            label: "Draft",
            scope: EditorResourceScope(
              organizationId: realmScope.organizationId,
              realmId: realmScope.realmId,
            ),
            document: EditorDocument(
              rootType: skir.TypeUse.wrapScalar(skir.ScalarKind.text),
              catalog: CheckedEditorCatalog(skir.EditorCatalog.defaultInstance),
              confirmedValue: skir.DataValue.wrapStringValue("Original"),
              revision: 1,
            ),
            validation: acceptTestEditorMutation,
            commitPolicy: EditorCommitPolicy.applyResource,
            commit: (_) async => throw StateError("No save expected"),
          ).acquire(panel.container.read(localWorkControllerProvider))
          ..update(editorRootPath, skir.DataValue.wrapStringValue("Draft"));
    await panel.settle();
    final before = panel.path;

    unawaited(
      panel.container
          .read(appRouterProvider)
          .navigate(
            OrganizationRoute(organizationId: globex.organizationId.id),
          ),
    );
    await panel.settle();
    await panel.dialog.choose("Stay", message: "Leave this work session?");

    expect(panel.path, before);
    expect(
      source.value(editorRootPath).valueOrNull,
      skir.DataValue.wrapStringValue("Draft"),
    );
  });

  testWidgets("a deep link opens an organization page", (tester) async {
    final panel = await tester.pumpPanel(
      [signedIn(ada, organization: acme)],
      at: PanelLocation.route(
        OrganizationRoute(
          organizationId: acme.organizationId.id,
          children: [const ServicesRoute()],
        ),
      ),
    );

    expect(panel.path, "/organization/${acme.organizationId.id}/services");
  });

  test("disposed coordination rejects pending consent", () async {
    final owner = WorkSessionLossController(
      () => workScopeIn("one"),
      () => true,
    );
    final answer = Completer<bool>();
    final decision = owner.allowScopeLoss(
      destination: workScopeIn("two"),
      confirm: () => answer.future,
    );
    owner.dispose();
    expect(await decision, isFalse);
    answer.complete(true);
    await Future<void>.delayed(Duration.zero);
    expect(
      await owner.allowScopeLoss(
        destination: workScopeIn("two"),
        confirm: () async => true,
      ),
      isFalse,
    );
    owner.dispose();
  });

  test("same scope navigation remains free", () async {
    var confirmations = 0;

    final allowed = await controller.allowScopeLoss(
      destination: workScopeIn("one"),
      confirm: () async {
        confirmations++;
        return false;
      },
    );

    expect(allowed, isTrue);
    expect(confirmations, 0);
  });

  test("scope loss remains free without protected work", () async {
    blocksNavigation = false;
    var confirmations = 0;

    final allowed = await controller.allowScopeLoss(
      destination: workScopeIn("two"),
      confirm: () async {
        confirmations++;
        return false;
      },
    );

    expect(allowed, isTrue);
    expect(confirmations, 0);
  });

  test("retained publication work does not protect navigation", () async {
    const driver = WorkDriverId(domain: "publication", scope: "realm");
    const entry = WorkEntryId(driver: driver, identity: "publication");
    final state = LocalWorkState(
      entries: {
        entry: WorkEntryState(
          id: entry,
          label: "Publishing",
          phase: "Publishing",
          retained: true,
          hasWork: true,
        ),
      },
    );
    controller = WorkSessionLossController(
      () => current,
      () => state.blocksNavigation,
    );
    var confirmations = 0;

    final allowed = await controller.allowScopeLoss(
      destination: workScopeIn("two"),
      confirm: () async {
        confirmations++;
        return false;
      },
    );

    expect(allowed, isTrue);
    expect(confirmations, 0);
  });

  test("scope loss follows one confirmation decision", () async {
    var decision = false;

    expect(
      await controller.allowScopeLoss(
        destination: workScopeIn("two"),
        confirm: () async => decision,
      ),
      isFalse,
    );

    decision = true;
    expect(
      await controller.allowScopeLoss(
        destination: workScopeIn("two"),
        confirm: () async => decision,
      ),
      isTrue,
    );
  });

  test("duplicate requests share one pending confirmation", () async {
    final decision = Completer<bool>();
    var confirmations = 0;

    Future<bool> confirm() {
      confirmations++;
      return decision.future;
    }

    final first = controller.allowScopeLoss(
      destination: workScopeIn("two"),
      confirm: confirm,
    );
    final duplicate = controller.allowScopeLoss(
      destination: workScopeIn("two"),
      confirm: confirm,
    );

    expect(confirmations, 1);
    decision.complete(true);
    expect(await first, isTrue);
    expect(await duplicate, isTrue);
  });

  test(
    "a different concurrent request cannot reuse the pending decision",
    () async {
      final decision = Completer<bool>();
      final first = controller.allowScopeLoss(
        destination: workScopeIn("two"),
        confirm: () => decision.future,
      );

      final different = await controller.allowScopeLoss(
        destination: workScopeIn("three"),
        confirm: () async => true,
      );

      expect(different, isFalse);
      decision.complete(true);
      expect(await first, isTrue);
    },
  );

  test("confirmation cannot authorize a changed source scope", () async {
    final decision = Completer<bool>();
    final pending = controller.allowScopeLoss(
      destination: workScopeIn("two"),
      confirm: () => decision.future,
    );

    current = workScopeIn("three");
    decision.complete(true);

    expect(await pending, isFalse);
  });

  test("forced revocation invalidates an older pending decision", () async {
    final decision = Completer<bool>();
    final pending = controller.allowScopeLoss(
      destination: workScopeIn("two"),
      confirm: () => decision.future,
    );

    expect(
      await controller.allowScopeLoss(
        destination: const LocalWorkScope(userId: null, organizationId: null),
        forced: true,
        confirm: () async => false,
      ),
      isTrue,
    );
    decision.complete(true);

    expect(await pending, isFalse);
  });

  test(
    "a synchronous confirmation failure releases pending ownership",
    () async {
      final failed = controller.allowScopeLoss(
        destination: workScopeIn("two"),
        confirm: () => throw StateError("dialog failed"),
      );
      await expectLater(failed, throwsStateError);

      expect(
        await controller.allowScopeLoss(
          destination: workScopeIn("two"),
          confirm: () async => true,
        ),
        isTrue,
      );
    },
  );

  test("forced revocation bypasses protected work", () async {
    var confirmations = 0;

    final allowed = await controller.allowScopeLoss(
      destination: const LocalWorkScope(userId: null, organizationId: null),
      forced: true,
      confirm: () async {
        confirmations++;
        return false;
      },
    );

    expect(allowed, isTrue);
    expect(confirmations, 0);
  });
}
