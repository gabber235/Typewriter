part of "services.dart";

/// Owns organization service and host configuration transport for the resource
/// session.
///
/// It is the mutation boundary, not the application state store. The backend
/// remains authoritative. Snapshot requests provide refresh data, while
/// [acceptService] and [acceptConfiguration] publish committed results to the
/// providers that own the corresponding projections. Service identity and host
/// runtime topology remain separate resources even when a host refers to the
/// same service.
///
/// The repository lives as long as its [ResourceRepositories] session. Closing
/// that session closes its streams and makes further operations invalid.
final class ServiceResourceRepository {
  ServiceResourceRepository(this.session, this.organization);
  final ResourceRepositories session;
  final skir.RecordId organization;
  final _configurations =
      StreamController<skir.HostConfigurationChange>.broadcast(sync: true);
  final _identities =
      StreamController<skir.OrganizationServicesChanged>.broadcast(sync: true);

  /// Committed host configuration changes for the organization.
  ///
  /// Consumers apply these changes to the topology projection. The change
  /// carries the resulting host configuration and any affected runtime
  /// resources, so a mutation result can update the projection without
  /// waiting for another snapshot.
  Stream<skir.HostConfigurationChange> get configurations =>
      _configurations.stream;

  /// Committed service identity changes for the organization.
  ///
  /// The canonical service provider consumes this stream and reconciles each
  /// value by service identity and revision.
  Stream<skir.OrganizationServicesChanged> get identities => _identities.stream;

  /// Fetches the current topology snapshot for refresh or initial state.
  ///
  /// Topology watches are owned by the provider layer. This request is scoped
  /// to the repository session and does not create a watch lifetime.
  Future<OrganizationTopology> topology() async {
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
  Future<List<Service>> services() async {
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
        value.map(Service.fromSkir).toList(),
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
  void acceptService(Service service) {
    session.checkActive();
    _identities.add(
      skir.OrganizationServicesChanged.wrapUpdate(service.toSkir()),
    );
  }

  /// Publishes one confirmed service removal to canonical consumers.
  void acceptServiceRemoval(skir.RecordId service) {
    session.checkActive();
    _identities.add(skir.OrganizationServicesChanged.wrapRemove(service));
  }

  /// Prepares a service binding with stable request identity and replay bytes.
  PreparedCommit<skir.BindServiceResponse> bind(String token) {
    session.checkActive();
    final request = skir.BindServiceRequest(
      operationId: uuid.v4(),
      registrationToken: token,
    );
    return session.transport.prepare(
      request.operation(
        userId: session.requireUserId(),
        organizationId: organization,
      ),
      submissionId: request.operationId,
      replay: SubmissionReplay.identicalRequest,
      label: "Bind service",
      classify: (response) => switch (response) {
        skir.BindServiceResponse_successWrapper() =>
          MutationResponseDisposition.confirmed,
        skir.BindServiceResponse_unknown() ||
        skir.BindServiceResponse_internalErrorWrapper() =>
          MutationResponseDisposition.uncertain,
        _ => MutationResponseDisposition.rejected,
      },
      onResponse: _integrateBinding,
    );
  }

  Future<void> _integrateBinding(skir.BindServiceResponse response) async {
    switch (response) {
      case skir.BindServiceResponse_successWrapper():
        final values = await services();
        session.checkActive();
        _identities.add(
          skir.OrganizationServicesChanged.wrapReplace(
            values.map((service) => service.toSkir()).toList(),
          ),
        );
      case skir.BindServiceResponse_invalidOperationIdErrorWrapper() ||
          skir.BindServiceResponse_operationIdentityReusedErrorWrapper() ||
          skir.BindServiceResponse_invalidRegistrationTokenErrorWrapper() ||
          skir.BindServiceResponse_organizationNotFoundErrorWrapper() ||
          skir.BindServiceResponse_internalErrorWrapper() ||
          skir.BindServiceResponse_unknown():
    }
  }

  /// Prepares removal of one service binding from this organization.
  PreparedCommit<skir.UnbindServiceResponse> unbind(skir.RecordId service) {
    session.checkActive();
    final request = skir.UnbindServiceRequest(
      operationId: uuid.v4(),
      serviceId: service.id,
    );
    return session.transport.prepare(
      request.operation(
        userId: session.requireUserId(),
        organizationId: organization,
      ),
      submissionId: request.operationId,
      replay: SubmissionReplay.identicalRequest,
      resources: {(organization, service)},
      label: "Unbind service: ${service.id}",
      classify: (response) => switch (response) {
        skir.UnbindServiceResponse_successWrapper() =>
          MutationResponseDisposition.confirmed,
        skir.UnbindServiceResponse_unknown() ||
        skir.UnbindServiceResponse_internalErrorWrapper() =>
          MutationResponseDisposition.uncertain,
        _ => MutationResponseDisposition.rejected,
      },
      onResponse: (response) => _integrateUnbinding(response, service),
    );
  }

  Future<void> _integrateUnbinding(
    skir.UnbindServiceResponse response,
    skir.RecordId service,
  ) async {
    switch (response) {
      case skir.UnbindServiceResponse_successWrapper():
        acceptServiceRemoval(service);
      case skir.UnbindServiceResponse_invalidOperationIdErrorWrapper() ||
          skir.UnbindServiceResponse_operationIdentityReusedErrorWrapper() ||
          skir.UnbindServiceResponse_serviceNotFoundErrorWrapper() ||
          skir.UnbindServiceResponse_internalErrorWrapper() ||
          skir.UnbindServiceResponse_unknown():
    }
  }

  /// Prepares a host configuration mutation against [revision].
  ///
  /// The expected revision is an optimistic concurrency check. The prepared
  /// commit reserves the organization and host for mutation tracking. Callers
  /// reconcile accepted configuration through the topology provider flow.
  PreparedCommit<skir.ConfigureServiceHostResponse> configure(
    skir.RecordId host,
    int revision,
    skir.HostExecutionConfiguration execution,
  ) {
    session.checkActive();
    final request = skir.ConfigureServiceHostRequest(
      operationId: uuid.v4(),
      hostId: host,
      expectedRevision: revision,
      execution: execution,
    );
    return session.transport.prepare(
      request.operation(
        userId: session.requireUserId(),
        organizationId: organization,
      ),
      submissionId: request.operationId,
      replay: SubmissionReplay.identicalRequest,
      resources: {(organization, host)},
      label: "Apply Host configuration: ${host.id}",
      classify: (response) => switch (response) {
        skir.ConfigureServiceHostResponse_successWrapper() =>
          MutationResponseDisposition.confirmed,
        skir.ConfigureServiceHostResponse_unknown() ||
        skir.ConfigureServiceHostResponse_internalErrorWrapper() =>
          MutationResponseDisposition.uncertain,
        _ => MutationResponseDisposition.rejected,
      },
      onResponse: _integrateConfiguration,
    );
  }

  Future<void> _integrateConfiguration(
    skir.ConfigureServiceHostResponse response,
  ) async {
    switch (response) {
      case skir.ConfigureServiceHostResponse_successWrapper(:final value):
        acceptConfiguration(value);
      case skir.ConfigureServiceHostResponse_conflictErrorWrapper(:final value):
        acceptConfiguration(value.actual);
      case skir.ConfigureServiceHostResponse_unknown() ||
          skir.ConfigureServiceHostResponse_internalErrorWrapper() ||
          skir.ConfigureServiceHostResponse_invalidOperationIdErrorWrapper() ||
          skir.ConfigureServiceHostResponse_operationIdentityReusedErrorWrapper() ||
          skir.ConfigureServiceHostResponse_invalidRecordIdErrorWrapper() ||
          skir.ConfigureServiceHostResponse_invalidConfigurationErrorWrapper() ||
          skir.ConfigureServiceHostResponse_incompatibleEngineErrorWrapper() ||
          skir.ConfigureServiceHostResponse_realmNotFoundErrorWrapper():
    }
  }

  /// Prepares a service identity rename against [revision].
  ///
  /// The service revision protects identity edits from overwriting a newer
  /// canonical value. Runtime topology is not changed by this operation.
  PreparedCommit<skir.UpdateOrganizationServiceResponse> rename(
    skir.RecordId service,
    int revision,
    String name,
  ) {
    session.checkActive();
    final request = skir.UpdateOrganizationServiceRequest(
      operationId: uuid.v4(),
      serviceId: service,
      expectedRevision: revision,
      name: name,
    );
    return session.transport.prepare(
      request.operation(
        userId: session.requireUserId(),
        organizationId: organization,
      ),
      submissionId: request.operationId,
      replay: SubmissionReplay.identicalRequest,
      resources: {(organization, service)},
      label: "Update service: ${service.id}",
      classify: (response) => switch (response) {
        skir.UpdateOrganizationServiceResponse_successWrapper() =>
          MutationResponseDisposition.confirmed,
        skir.UpdateOrganizationServiceResponse_unknown() ||
        skir.UpdateOrganizationServiceResponse_internalErrorWrapper() =>
          MutationResponseDisposition.uncertain,
        _ => MutationResponseDisposition.rejected,
      },
      onResponse: _integrateRename,
    );
  }

  Future<void> _integrateRename(
    skir.UpdateOrganizationServiceResponse response,
  ) async {
    switch (response) {
      case skir.UpdateOrganizationServiceResponse_successWrapper(:final value):
        acceptService(Service.fromSkir(value));
      case skir.UpdateOrganizationServiceResponse_conflictErrorWrapper(
        :final value,
      ):
        acceptService(Service.fromSkir(value.actual));
      case skir.UpdateOrganizationServiceResponse_unknown() ||
          skir.UpdateOrganizationServiceResponse_internalErrorWrapper() ||
          skir.UpdateOrganizationServiceResponse_invalidOperationIdErrorWrapper() ||
          skir.UpdateOrganizationServiceResponse_operationIdentityReusedErrorWrapper() ||
          skir.UpdateOrganizationServiceResponse_invalidRecordIdErrorWrapper() ||
          skir.UpdateOrganizationServiceResponse_serviceNotFoundErrorWrapper() ||
          skir.UpdateOrganizationServiceResponse_validationErrorWrapper():
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
    skir.BindServiceResponse_invalidOperationIdErrorWrapper() =>
      throw ApiException.badRequest("Operation identity is required"),
    skir.BindServiceResponse_operationIdentityReusedErrorWrapper() =>
      throw ApiException.conflict(
        "Operation identity was reused with different input",
      ),
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

extension UnbindServiceResult on skir.UnbindServiceResponse {
  void requireAcceptedUnbinding() => switch (this) {
    skir.UnbindServiceResponse_successWrapper() => null,
    skir.UnbindServiceResponse_invalidOperationIdErrorWrapper() =>
      throw ApiException.badRequest("Operation identity is required"),
    skir.UnbindServiceResponse_operationIdentityReusedErrorWrapper() =>
      throw ApiException.conflict(
        "Operation identity was reused with different input",
      ),
    skir.UnbindServiceResponse_serviceNotFoundErrorWrapper() =>
      throw ApiException.notFound("Service"),
    skir.UnbindServiceResponse_internalErrorWrapper() =>
      throw ApiException.internalServerError(),
    skir.UnbindServiceResponse_unknown() =>
      throw ApiException.unknownResponseMessage(),
  };
}
