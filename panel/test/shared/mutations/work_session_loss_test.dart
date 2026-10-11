import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

LocalWorkScope _scope(String? organization) => LocalWorkScope(
  userId: "user",
  organizationId: organization == null
      ? null
      : skir.recordId("organization:$organization"),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalWorkScope current;
  late bool blocksNavigation;
  late WorkSessionLossController controller;

  setUp(() {
    current = _scope("one");
    blocksNavigation = true;
    controller = WorkSessionLossController(
      () => current,
      () => blocksNavigation,
    );
  });

  test(
    "session loss reads live work through the production router graph",
    () async {
      final container = ProviderContainer.test(
        overrides: [userIdProvider.overrideWith((ref) async => "user")],
      );
      await container.read(userIdProvider.future);
      final owner = container.read(workSessionLossProvider);
      final router = container.read(appRouterProvider);
      final scope = container.read(localWorkScopeProvider);
      container.read(localWorkProvider);

      expect(router.workSessionLoss, same(owner));
      expect(owner.currentScope, scope);
      expect(
        await owner.allowScopeLoss(
          destination: _scope("one"),
          confirm: () async => throw StateError("No protected work"),
        ),
        isTrue,
      );

      final source =
          container
              .read(localWorkControllerProvider)
              .editor(
                fakeEditorTarget(
                  targetId: "resource",
                  label: "Draft",
                  scope: EditorResourceScope(
                    organizationId: skir.recordId("organization:one"),
                  ),
                  document: EditorDocument(
                    rootType: skir.TypeUse.wrapScalar(skir.ScalarKind.text),
                    catalog: CheckedEditorCatalog(
                      skir.EditorCatalogWireSnapshot.defaultInstance,
                    ),
                    confirmedValue: skir.DataValue.wrapStringValue("Original"),
                    revision: 1,
                  ),
                  validation: acceptTestEditorMutation,
                  commitPolicy: EditorCommitPolicy.applyResource,
                  commit: (_) async => throw StateError("No save expected"),
                ),
              )
            ..update(editorRootPath, skir.DataValue.wrapStringValue("Draft"));
      await container.pump();
      expect(container.read(localWorkProvider).blocksNavigation, isTrue);
      var confirmations = 0;
      expect(
        await owner.allowScopeLoss(
          destination: _scope("one"),
          confirm: () async {
            confirmations++;
            return false;
          },
        ),
        isFalse,
      );
      expect(confirmations, 1);
      expect(
        source.value(editorRootPath).valueOrNull,
        skir.DataValue.wrapStringValue("Draft"),
      );
    },
  );

  test(
    "initial deep link admits navigation with live local work providers",
    () async {
      final container = ProviderContainer.test(
        overrides: [userIdProvider.overrideWith((ref) async => "user")],
      );
      await container.read(userIdProvider.future);
      final router = container.read(appRouterProvider);
      final owner = container.read(workSessionLossProvider);
      container.read(localWorkProvider);
      router.access.authentication.setDecision(
        const RouteAuthenticationDecision.authenticated(),
      );
      router.access.organizations.setState(
        const OrganizationRouteAccessState.available(
          principalId: "user",
          organizationIds: {"one"},
        ),
      );
      final uri = Uri.parse("/organization/one/services");

      await router.delegate().setInitialRoutePath(
        UrlState(uri, router.matcher.match(uri.path)!),
      );
      container.invalidate(routeParamProvider);
      await container.pump();

      expect(router.current.name, OrganizationRoute.name);
      expect(router.current.pendingChildren.single.name, ServicesRoute.name);
      expect(owner.currentScope, _scope("one"));
      expect(container.read(appRouterProvider), same(router));
      expect(container.read(workSessionLossProvider), same(owner));
    },
  );

  test("account and router share the application scoped coordinator and disposal ends consent", () {
    final container = ProviderContainer.test(
      overrides: [localWorkScopeProvider.overrideWithValue(_scope("one"))],
    );
    final accountPolicy = container.read(workSessionLossProvider);
    final router = container.read(appRouterProvider);
    expect(router.workSessionLoss, same(accountPolicy));
    expect(accountPolicy.currentScope, _scope("one"));
    container.dispose();
    expect(() => accountPolicy.currentScope, throwsStateError);
  });

  test("disposed coordination rejects pending consent without reading a released owner", () async {
    var scopeReads = 0;
    final owner = WorkSessionLossController(() {
      scopeReads++;
      return _scope("one");
    }, () => true);
    final answer = Completer<bool>();
    final decision = owner.allowScopeLoss(
      destination: _scope("two"),
      confirm: () => answer.future,
    );
    expect(scopeReads, 1);
    owner.dispose();
    expect(await decision, isFalse);
    answer.complete(true);
    await Future<void>.delayed(Duration.zero);
    expect(scopeReads, 1);
    expect(
      await owner.allowScopeLoss(
        destination: _scope("two"),
        confirm: () async => true,
      ),
      isFalse,
    );
    owner.dispose();
  });

  test("same scope navigation remains free", () async {
    var confirmations = 0;

    final allowed = await controller.allowScopeLoss(
      destination: _scope("one"),
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
      destination: _scope("two"),
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
      destination: _scope("two"),
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
        destination: _scope("two"),
        confirm: () async => decision,
      ),
      isFalse,
    );

    decision = true;
    expect(
      await controller.allowScopeLoss(
        destination: _scope("two"),
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
      destination: _scope("two"),
      confirm: confirm,
    );
    final duplicate = controller.allowScopeLoss(
      destination: _scope("two"),
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
        destination: _scope("two"),
        confirm: () => decision.future,
      );

      final different = await controller.allowScopeLoss(
        destination: _scope("three"),
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
      destination: _scope("two"),
      confirm: () => decision.future,
    );

    current = _scope("three");
    decision.complete(true);

    expect(await pending, isFalse);
  });

  test("forced revocation invalidates an older pending decision", () async {
    final decision = Completer<bool>();
    final pending = controller.allowScopeLoss(
      destination: _scope("two"),
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
        destination: _scope("two"),
        confirm: () => throw StateError("dialog failed"),
      );
      await expectLater(failed, throwsStateError);

      expect(
        await controller.allowScopeLoss(
          destination: _scope("two"),
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
