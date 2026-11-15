part of "services.dart";

/// The services command owner for one organization in the current resource
/// session. Repeated reads share the repository and its mutation boundary.
@Riverpod(keepAlive: true)
ServiceResourceRepository serviceResourceRepository(
  Ref ref,
  skir.RecordId organization,
) {
  final repository = ServiceResourceRepository(
    ref.watch(resourceSessionProvider),
    organization,
  );
  ref.onDispose(repository.dispose);
  return repository;
}

/// Owns organization service and host configuration transport for the resource
/// session.
///
/// It is the mutation boundary, not the application state store. The backend
/// remains authoritative. Snapshot requests provide refresh data, while
/// [acceptService] and [acceptConfiguration] publish canonical observations to the
/// providers that own the corresponding projections. Service identity and host
/// runtime topology remain separate resources even when a host refers to the
/// same service.
///
/// The repository lives as long as its [ResourceSession]. Closing
/// that session closes its streams and makes further operations invalid.
final class ServiceResourceRepository {
  ServiceResourceRepository(this.session, this.organization);
  final ResourceSession session;
  final skir.RecordId organization;
  final _configurations =
      StreamController<skir.HostConfigurationChange>.broadcast(sync: true);
  final _identities =
      StreamController<skir.OrganizationServicesChanged>.broadcast(sync: true);

  /// Canonical host configurations from successful and conflicting commands.
  ///
  /// Consumers apply these changes to the topology projection. The change
  /// carries the resulting host configuration and any affected runtime
  /// resources, so a mutation result can update the projection without
  /// waiting for another snapshot.
  Stream<skir.HostConfigurationChange> get configurations =>
      _configurations.stream;

  /// Canonical service identities from successful and conflicting commands.
  ///
  /// The canonical service provider consumes this stream and reconciles each
  /// value by service identity and revision.
  Stream<skir.OrganizationServicesChanged> get identities => _identities.stream;

  /// Fetches the current topology snapshot for refresh or initial state.
  ///
  /// Topology watches are owned by the provider layer. This request is scoped
  /// to the repository session and does not create a watch lifetime.
  Future<skir.OrganizationTopologySnapshot> topology() async {
    final operation = skir.WatchOrganizationTopologyRequest().operation(
      userId: session.requireUserId(),
      organizationId: organization,
    );
    final response = await session.transport.request(
      operation.subject,
      operation.requestBytes,
      operation.responseSerializer,
    );
    session.checkActive();
    if (response is! skir.WatchOrganizationTopologyResponse_listWrapper) {
      throw StateError("The topology request did not return a snapshot");
    }
    return response.readSnapshot();
  }

  /// Fetches the current service identity snapshot for refresh or initial
  /// state.
  Future<List<skir.Service>> services() async {
    final operation = skir.WatchOrganizationServicesRequest().operation(
      userId: session.requireUserId(),
      organizationId: organization,
    );
    final response = await session.transport.request(
      operation.subject,
      operation.requestBytes,
      operation.responseSerializer,
    );
    session.checkActive();
    return switch (response) {
      skir.WatchOrganizationServicesResponse_listWrapper(:final value) =>
        value.map((service) => service.requireKnown()).toList(),
      _ => throw StateError("The services request did not return a snapshot"),
    };
  }

  /// Publishes a backend configuration result to topology consumers.
  void acceptConfiguration(skir.HostConfigurationChange change) {
    session.checkActive();
    _configurations.add(change);
  }

  /// Publishes a backend service identity result to canonical service
  /// consumers.
  void acceptService(skir.Service service) {
    session.checkActive();
    _identities.add(skir.OrganizationServicesChanged.wrapUpdate(service));
  }

  /// Publishes one confirmed service removal to canonical consumers.
  void acceptServiceRemoval(skir.RecordId service) {
    session.checkActive();
    _identities.add(skir.OrganizationServicesChanged.wrapRemove(service));
  }

  /// Prepares a service binding for the current organization.
  PreparedCommit<skir.BindServiceResponse> bind(String token) {
    session.checkActive();
    final request = skir.BindServiceRequest(registrationToken: token);
    return session.transport.prepare(
      request.operation(
        userId: session.requireUserId(),
        organizationId: organization,
      ),
      label: "Bind service",
      onResponse: _integrateBinding,
    );
  }

  Future<void> _integrateBinding(skir.BindServiceResponse response) async {
    switch (response) {
      case skir.BindServiceResponse_successWrapper():
        final values = await services();
        session.checkActive();
        _identities.add(skir.OrganizationServicesChanged.wrapReplace(values));
      case skir.BindServiceResponse_invalidRegistrationTokenErrorWrapper() ||
          skir.BindServiceResponse_organizationNotFoundErrorWrapper() ||
          skir.BindServiceResponse_internalErrorWrapper() ||
          skir.BindServiceResponse_unknown():
    }
  }

  /// Prepares removal of the bindings of [services] from this organization as
  /// one all or nothing batch.
  PreparedCommit<skir.UnbindServicesResponse> unbind(
    List<skir.RecordId> services,
  ) {
    session.checkActive();
    final request = skir.UnbindServicesRequest(
      serviceIds: [for (final service in services) service.id],
    );
    return session.transport.prepare(
      request.operation(
        userId: session.requireUserId(),
        organizationId: organization,
      ),
      resources: {for (final service in services) (organization, service)},
      label: services.length == 1
          ? "Unbind service: ${services.single.id}"
          : "Unbind ${services.length} services",
      onResponse: (response) => _integrateUnbinding(response, services),
    );
  }

  Future<void> _integrateUnbinding(
    skir.UnbindServicesResponse response,
    List<skir.RecordId> services,
  ) async {
    switch (response) {
      case skir.UnbindServicesResponse_successWrapper():
        for (final service in services) {
          acceptServiceRemoval(service);
        }
      case skir.UnbindServicesResponse_refusedErrorWrapper() ||
          skir.UnbindServicesResponse_internalErrorWrapper() ||
          skir.UnbindServicesResponse_unknown():
    }
  }

  late final _configurationBatches =
      PreparedBatches<
        skir.HostConfigurationEdit,
        skir.ConfigureServiceHostsResponse
      >(
        (configurations) => session.transport.prepare(
          skir.ConfigureServiceHostsRequest(configurations: configurations)
              .operation(
                userId: session.requireUserId(),
                organizationId: organization,
              ),
          resources: {
            for (final configuration in configurations)
              (organization, configuration.hostId),
          },
          replay: SubmissionReplay.identicalRequest,
          label: "Apply Host configurations",
          onResponse: _integrateConfiguration,
        ),
      );

  /// Prepares a host configuration mutation against [revision].
  ///
  /// Configurations prepared in the same turn, as when one Apply covers
  /// several hosts, travel as one all or nothing batch; each caller reads its
  /// own host from the shared reply. The expected revision is an optimistic
  /// concurrency check. The backend answers a repeat whose configuration is
  /// already stored with the stored state, so an unanswered send may be sent
  /// again byte for byte. The prepared commit declares the organization and
  /// host for mutation tracking. Callers reconcile accepted configuration
  /// through the topology provider flow.
  PreparedCommit<skir.ConfigureServiceHostsResponse> configure(
    skir.RecordId host,
    int revision,
    skir.HostExecutionConfiguration execution,
  ) {
    session.requireUserId();
    return _configurationBatches.join(
      skir.HostConfigurationEdit(
        hostId: host,
        expectedRevision: revision,
        execution: execution,
      ),
      resources: {(organization, host)},
      replay: SubmissionReplay.identicalRequest,
      label: "Apply Host configuration: ${host.id}",
    );
  }

  Future<void> _integrateConfiguration(
    skir.ConfigureServiceHostsResponse response,
  ) async {
    switch (response) {
      case skir.ConfigureServiceHostsResponse_successWrapper(:final value):
        value.forEach(acceptConfiguration);
      case skir.ConfigureServiceHostsResponse_refusedErrorWrapper(:final value):
        for (final refused in value) {
          if (refused.reason
              case skir.HostConfigurationRefusal_conflictErrorWrapper(
                :final value,
              )) {
            acceptConfiguration(value.actual);
          }
        }
      case skir.ConfigureServiceHostsResponse_unknown() ||
          skir.ConfigureServiceHostsResponse_internalErrorWrapper():
    }
  }

  late final _renames =
      PreparedBatches<
        skir.ServiceRename,
        skir.UpdateOrganizationServicesResponse
      >(
        (renames) => session.transport.prepare(
          skir.UpdateOrganizationServicesRequest(renames: renames).operation(
            userId: session.requireUserId(),
            organizationId: organization,
          ),
          resources: {
            for (final rename in renames) (organization, rename.serviceId),
          },
          replay: SubmissionReplay.identicalRequest,
          label: "Update services",
          onResponse: _integrateRenames,
        ),
      );

  /// Prepares a service identity rename against [revision].
  ///
  /// Renames prepared in the same turn, as when one edit covers several
  /// selected services, travel as one all or nothing batch; each caller reads
  /// its own service from the shared reply. The service revision protects
  /// identity edits from overwriting a newer canonical value. The backend
  /// answers a repeat whose name is already stored with the stored service,
  /// so an unanswered send may be sent again byte for byte. Runtime topology
  /// is not changed by this operation.
  PreparedCommit<skir.UpdateOrganizationServicesResponse> rename(
    skir.RecordId service,
    int revision,
    String name,
  ) {
    session.requireUserId();
    return _renames.join(
      skir.ServiceRename(
        serviceId: service,
        expectedRevision: revision,
        name: name,
      ),
      resources: {(organization, service)},
      replay: SubmissionReplay.identicalRequest,
      label: "Update service: ${service.id}",
    );
  }

  Future<void> _integrateRenames(
    skir.UpdateOrganizationServicesResponse response,
  ) async {
    switch (response) {
      case skir.UpdateOrganizationServicesResponse_successWrapper(:final value):
        for (final service in value) {
          acceptService(service.requireKnown());
        }
      case skir.UpdateOrganizationServicesResponse_refusedErrorWrapper(
        :final value,
      ):
        for (final refused in value) {
          if (refused.reason
              case skir.ServiceRenameRefusal_conflictErrorWrapper(
                :final value,
              )) {
            acceptService(value.actual.requireKnown());
          }
        }
      case skir.UpdateOrganizationServicesResponse_unknown() ||
          skir.UpdateOrganizationServicesResponse_internalErrorWrapper():
    }
  }

  /// Closes the repository's result streams.
  void dispose() {
    unawaited(_configurations.close());
    unawaited(_identities.close());
  }
}

extension BindServiceResult on skir.BindServiceResponse {
  void requireAcceptedBinding() => switch (this) {
    skir.BindServiceResponse_successWrapper() => null,
    skir.BindServiceResponse_invalidRegistrationTokenErrorWrapper() =>
      throw ApiException.badRequest("Invalid or expired registration token"),
    skir.BindServiceResponse_organizationNotFoundErrorWrapper() =>
      throw ApiException.notFound("Organization"),
    skir.BindServiceResponse_internalErrorWrapper() =>
      throw ApiException.internalServerError(),
    skir.BindServiceResponse_unknown() =>
      throw ApiException.unknownResponseMessage(),
  };
}

/// Unbinds services of one organization through its repository, all
/// selected services in one batch.
///
/// Two unbindings over the same repository are equal, so the unbind
/// operation joins every selected service and host of the organization into
/// one request. Targets are service record ids.
final class ServiceUnbinding implements UnbindBatch {
  const ServiceUnbinding(this.repository, this.work);
  final ServiceResourceRepository repository;
  final LocalWorkCommands work;

  @override
  Future<void> unbind(List<Object> targets) async {
    final services = targets.cast<skir.RecordId>();
    final response = await work.execute(repository.unbind(services));
    switch (response) {
      case skir.UnbindServicesResponse_successWrapper():
        return;
      case skir.UnbindServicesResponse_refusedErrorWrapper(:final value):
        throw RefusedTargets(HoldRefused(value.first.reason.message), {
          for (final refused in value)
            for (final service in services)
              if (service.id == refused.serviceId) service,
        });
      case skir.UnbindServicesResponse_internalErrorWrapper():
        throw ApiException.internalServerError();
      case skir.UnbindServicesResponse_unknown():
        throw ApiException.unknownResponseMessage();
    }
  }

  @override
  bool operator ==(Object other) =>
      other is ServiceUnbinding && identical(other.repository, repository);

  @override
  int get hashCode => identityHashCode(repository);
}

extension on skir.ServiceUnbindRefusal {
  String get message => switch (this) {
    skir.ServiceUnbindRefusal_serviceNotFoundErrorWrapper() =>
      "This service is no longer bound to the organization",
    skir.ServiceUnbindRefusal_duplicateErrorWrapper() =>
      "This service was named twice",
    skir.ServiceUnbindRefusal_unknown() => "This service could not be unbound",
  };
}
