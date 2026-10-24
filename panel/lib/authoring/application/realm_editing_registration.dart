import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "realm_editing_registration.g.dart";

@riverpod
AsyncValue<AuthoringDocument> confirmedAuthoringDocument(
  Ref ref,
  AuthoringScope scope,
) {
  final state = ref.watch(
    authoringSessionProvider(scope.organizationId, scope.realmId),
  );
  final document = state.confirmedDocument;
  if (document != null) return AsyncData(document);
  if (state.failure case final error?) {
    return AsyncError(error, StackTrace.current);
  }
  return const AsyncLoading();
}

@Riverpod(keepAlive: true)
RealmEditPersistence realmEditPersistence(Ref ref, AuthoringScope scope) {
  AuthoringSession session() => ref.read(
    authoringSessionProvider(scope.organizationId, scope.realmId).notifier,
  );
  return RealmEditPersistence(
    request: (edit) => session().prepareCommit(edit),
    reservations: (edits) => {
      for (final edit in edits)
        for (final resource in edit.editedResources)
          (scope.organizationId, scope.realmId, resource),
    },
    observe: () async {
      await session().refresh();
      return ref
              .read(
                authoringSessionProvider(scope.organizationId, scope.realmId),
              )
              .confirmedDocument ??
          (throw StateError("Current Realm values are unavailable"));
    },
  );
}

/// Registers one editing driver per authoring scope in the application local work owner.
///
/// Confirmed session updates feed the retained workspace. Widget providers acquire
/// leases to that driver, so route and inspector disposal do not discard its journal.
/// The destination supplies a route back to the Realm when pending work needs review.
extension RealmEditingRegistration on LocalWork {
  EditingWorkDriver<AuthoringDocument, RealmPreparedEdit>
  getOrRegisterRealmEditing(AuthoringScope scope) => getOrRegisterScoped(
    WorkDriverId(domain: "authoring", scope: scope),
    (ref) {
      final workspace = EditingWorkspace<AuthoringDocument, RealmPreparedEdit>(
        model: const RealmEditModel(),
        persistence: ref.read(realmEditPersistenceProvider(scope)),
        submissions: this,
      );
      final subscription = ref.listen(
        confirmedAuthoringDocumentProvider(scope),
        (_, next) {
          if (next.value case final document?) {
            workspace.acceptConfirmed(document);
          } else if (next.error case final error?) {
            workspace.acceptFailure(error);
          }
        },
        fireImmediately: true,
      );
      return EditingWorkDriver(
        id: WorkDriverId(domain: "authoring", scope: scope),
        workspace: workspace,
        onDispose: subscription.close,
        reviewFactory: (id) => WorkReviewContent(
          body: RealmEditingReview(
            workspace: RealmEditing.fromWorkspace(workspace),
            id: id,
          ),
        ),
      );
    },
    destination: (ref) => RealmWorkDestination.of(ref, scope),
  );
}

@riverpod
RealmEditing realmEditing(Ref ref, AuthoringScope scope) {
  ref
    ..watch(localWorkScopeProvider)
    ..watch(localWorkControllerProvider);
  final work = ref.read(localWorkProvider.notifier);
  final driver = work.getOrRegisterRealmEditing(scope);
  final lease = work.lease(driver.id);
  ref.onDispose(lease.release);
  return RealmEditing.fromWorkspace(driver.workspace);
}

@riverpod
EditingState<AuthoringDocument> realmEditingState(
  Ref ref,
  AuthoringScope scope,
) {
  final workspace = ref.watch(realmEditingProvider(scope))
    ..addListener(ref.invalidateSelf);
  ref.onDispose(() => workspace.removeListener(ref.invalidateSelf));
  return workspace.state;
}

@riverpod
AsyncValue<AuthoringDocument> workingAuthoringDocument(
  Ref ref,
  AuthoringScope scope,
) {
  final state = ref.watch(realmEditingStateProvider(scope));
  if (state.working case final document?) return AsyncData(document);
  if (state.failure case final error?) {
    return AsyncError(error, StackTrace.current);
  }
  return const AsyncLoading();
}

@riverpod
AuthoringScope? selectedAuthoringScope(Ref ref) {
  final organization = ref.watch(organizationIdProvider);
  final realm = ref.watch(realmIdProvider);
  return organization == null || realm == null
      ? null
      : AuthoringScope(organizationId: organization, realmId: realm);
}

@riverpod
AsyncValue<AuthoringDocument> selectedWorkingAuthoringDocument(Ref ref) {
  final scope = ref.watch(selectedAuthoringScopeProvider);
  return scope == null
      ? const AsyncLoading()
      : ref.watch(workingAuthoringDocumentProvider(scope));
}

extension RealmEditingRef on Ref {
  RealmEditing readRealmEditing() {
    final scope = read(selectedAuthoringScopeProvider);
    if (scope == null) throw StateError("No Realm selected");
    return read(realmEditingProvider(scope));
  }
}

extension RealmEditingWidgetRef on WidgetRef {
  RealmEditing readRealmEditing() {
    final scope = read(selectedAuthoringScopeProvider);
    if (scope == null) throw StateError("No Realm selected");
    return read(realmEditingProvider(scope));
  }
}

final class RealmWorkDestination extends WorkDestination {
  RealmWorkDestination(this.router, this.route, this.scope) {
    router.addListener(notifyListeners);
  }

  /// The destination of [scope], navigating to its realm route.
  factory RealmWorkDestination.of(Ref ref, AuthoringScope scope) =>
      RealmWorkDestination(
        ref.read(navigationRouterProvider),
        ref.read(realmRoutesProvider).realm(scope),
        scope,
      );

  final NavigationRouter router;

  /// The realm route [open] navigates to.
  final PageRouteInfo<Object?> route;
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
    await router.navigate(route);
  }

  @override
  void dispose() {
    router.removeListener(notifyListeners);
    super.dispose();
  }
}
