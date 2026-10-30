import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/core/world.dart";

/// The services of one organization as the panel's application layer sees
/// them: the commands its editors and pages send and the services its
/// projection lists.
///
/// Commands are prepared by the organization's service repository and run
/// through the panel's local work, the way every editor save and page action
/// runs them.
final class OrganizationServices {
  OrganizationServices(this.world, this.organization);

  /// The world the panel runs in.
  final World world;

  /// The organization whose services these are.
  final skir.RecordId organization;

  /// The repository that prepares and accepts the organization's service
  /// commands.
  ServiceResourceRepository get repository =>
      world.container.read(serviceResourceRepositoryProvider(organization));

  /// Runs [commit] through the panel's local work.
  Future<T> execute<T>(PreparedCommit<T> commit) =>
      world.container.read(localWorkControllerProvider).execute(commit);

  /// Saves [name] over [service], the way the service name editor does.
  Future<TypedMutationResult> rename(skir.Service service, String name) {
    final snapshot = service.editorSnapshot;
    return execute(
      ServiceEditPersistence(repository, service.serviceId).prepareValue(
        snapshot,
        EditorCommit(
          expectedRevision: service.revision,
          localRevision: 1,
          rootValue: (service.toMutable()..name = name)
              .toFrozen()
              .identityValue,
          baseValue: snapshot.document.confirmedValue,
          changedPaths: {editorRootPath.field("name")},
          mutations: const [],
        ),
      ),
    );
  }

  /// Applies [host]'s current configuration unchanged, the way Apply in the
  /// host editor does for a topology holding only [host].
  Future<TypedMutationResult> applyHost(skir.ServiceHost host) {
    final snapshot = HostEditorSnapshot(
      host,
      skir.OrganizationTopologySnapshot(hosts: [host], realms: [], engines: []),
    );
    return execute(
      HostEditPersistence(repository, host.hostId).prepareValue(
        snapshot,
        EditorCommit(
          expectedRevision: host.revision,
          localRevision: 1,
          rootValue: snapshot.document.confirmedValue,
          baseValue: snapshot.document.confirmedValue,
          changedPaths: {editorRootPath},
          mutations: const [],
        ),
      ),
    );
  }

  /// Configures [host] at its revision with [execution], neither a Realm
  /// nor an engine by default.
  Future<skir.ConfigureServiceHostResponse> configure(
    skir.ServiceHost host, [
    skir.HostExecutionConfiguration? execution,
  ]) => execute(
    repository.configure(
      host.hostId,
      host.revision,
      execution ??
          skir.HostExecutionConfiguration(realm: null, primaryEngine: null),
    ),
  );

  /// Keeps the organization's services projection watched for the rest of
  /// the test and returns the first services it lists.
  Future<List<skir.Service>> watch() {
    world.container.listen(_projection, (_, _) {});
    return world.container.read(_projection.future);
  }

  /// The services the organization's projection lists once the changes
  /// already sent have arrived.
  Future<List<skir.Service>> listed() async {
    await world.container.pump();
    return world.container.read(_projection.future);
  }

  CanonicalOrganizationServicesProvider get _projection =>
      canonicalOrganizationServicesProvider(organization);
}

/// Reaching an organization's services from a world.
extension OrganizationServicesOfWorld on World {
  /// The services of [organization].
  OrganizationServices servicesOf(skir.RecordId organization) =>
      OrganizationServices(this, organization);
}
