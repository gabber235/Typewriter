import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Keeps graph planning with the workspace and gives its lifetime to the scoped owner.
final class AuthoringWorkDriver extends ChangeNotifier implements WorkDriver {
  AuthoringWorkDriver(this.scope, this.workspace) {
    workspace.addListener(notifyListeners);
  }
  final AuthoringScope scope;
  final AuthoringWorkspace workspace;
  ProviderSubscription<AsyncValue<AuthoringDocument>>? confirmed;
  @override
  WorkDriverId get id => WorkDriverId(domain: "authoring", scope: scope);

  @override
  WorkDriverSnapshot get snapshot => WorkDriverSnapshot(
    entries: [
      if (workspace.isPreparing)
        WorkEntryState(
          id: WorkEntryId(driver: id, identity: "preparation"),
          label: "Prepare changes",
          phase: "Preparing changes",
          retained: true,
          hasWork: true,
          blocksNavigation: true,
        ),
      for (final group in workspace.state.groups.values)
        WorkEntryState(
          id: WorkEntryId(driver: id, identity: group.id),
          label: group.label,
          phase: group.phase.message,
          details: [
            WorkFact(label: "Operations", value: "${group.operationCount}"),
            WorkFact(
              label: "Resources",
              value: group.resources
                  .map((resource) => resource.value)
                  .join(", "),
            ),
            if (group.phase case AuthoringGroupAwaitingDependency(
              :final groups,
            ))
              WorkFact(
                label: "Dependencies",
                value: groups.map((group) => group.value).join(", "),
              ),
            if (group.phase case AuthoringGroupConflict(
              :final expected,
              :final actual,
            )) ...[
              WorkFact(label: "Expected", value: expected.toString()),
              WorkFact(label: "Observed", value: actual.toString()),
            ],
          ],
          retained: true,
          hasWork: group.operationCount > 0,
          canSave: workspace.canSave(group.id),
          canDiscard: workspace.canDiscard(group.id),
          canRetry: workspace.canRetry(group.id),
          blocksNavigation: group.operationCount > 0,
          saving: group.phase is AuthoringGroupSaving,
          needsAttention: group.phase.blocked,
        ),
    ],
  );

  AuthoringGroupId _group(WorkEntryId entry) {
    if (entry.driver != id || entry.identity is! AuthoringGroupId) {
      throw StateError("The graph work entry belongs to another driver");
    }
    return entry.identity as AuthoringGroupId;
  }

  @override
  Future<void> save(WorkEntryId entry) => workspace.save(_group(entry));
  @override
  bool discard(WorkEntryId entry) => workspace.discard(_group(entry));
  @override
  Future<void> retry(WorkEntryId entry) => workspace.retry(_group(entry));

  @override
  void dispose() {
    confirmed?.close();
    workspace
      ..removeListener(notifyListeners)
      ..dispose();
    super.dispose();
  }
}

/// Registers the transport and confirmed observation on the scoped provider owner.
extension AuthoringWorkRegistration on LocalWork {
  AuthoringWorkDriver getOrRegisterAuthoring(AuthoringScope scope) =>
      getOrRegisterScoped(
        WorkDriverId(domain: "authoring", scope: scope),
        (ref) {
          final driver = AuthoringWorkDriver(
            scope,
            AuthoringWorkspace(
              transport: ref.read(authoringWorkspaceTransportProvider(scope)),
            ),
          );
          driver.confirmed = ref.listen(
            confirmedAuthoringDocumentProvider(scope),
            (_, next) {
              if (next.value case final document?) {
                driver.workspace.acceptConfirmed(document);
              } else if (next.error case final error?) {
                driver.workspace.acceptFailure(error);
              }
            },
            fireImmediately: true,
          );
          return driver;
        },
        destination: (ref) =>
            RealmWorkDestination(ref.read(appRouterProvider), scope),
      );
}

final class RealmWorkDestination extends WorkDestination {
  RealmWorkDestination(this.router, this.scope) {
    router.addListener(notifyListeners);
  }
  final AppRouter router;
  final AuthoringScope scope;
  @override
  bool get isCurrent {
    final path =
        "/organization/${scope.organizationId.id}/realm/${scope.realmId.id}";
    return router.currentPath == path ||
        router.currentPath.startsWith("$path/");
  }

  @override
  Future<void> open() async {
    await router.navigate(
      OrganizationRoute(
        organizationId: scope.organizationId.id,
        children: [RealmRoute(realmId: scope.realmId.id)],
      ),
    );
  }

  @override
  void dispose() {
    router.removeListener(notifyListeners);
    super.dispose();
  }
}
