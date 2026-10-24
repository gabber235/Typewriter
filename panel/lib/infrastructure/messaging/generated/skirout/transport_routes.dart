// GENERATED CODE. DO NOT MODIFY BY HAND
// ignore_for_file: cascade_invocations, constant_identifier_names, curly_braces_in_flow_control_structures, no_leading_underscores_for_library_prefixes, unnecessary_this, use_raw_strings

import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as _skir;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/authoring.dart"
    as _lib_editor_v1_authoring;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/capability.dart"
    as _lib_editor_v1_capability;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/catalog.dart"
    as _lib_editor_v1_catalog;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/compiled_content.dart"
    as _lib_editor_v1_compiled_content;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/publication.dart"
    as _lib_editor_v1_publication;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/resource_operations.dart"
    as _lib_editor_v1_resource_operations;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/search.dart"
    as _lib_editor_v1_search;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/organization/v1/join_codes.dart"
    as _lib_organization_v1_join_codes;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/organization/v1/join_request.dart"
    as _lib_organization_v1_join_request;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/organization/v1/member.dart"
    as _lib_organization_v1_member;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/organization/v1/organization.dart"
    as _lib_organization_v1_organization;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/organization/v1/presence.dart"
    as _lib_organization_v1_presence;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/organization/v1/role.dart"
    as _lib_organization_v1_role;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/organization/v1/user.dart"
    as _lib_organization_v1_user;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/service/v1/artifact.dart"
    as _lib_service_v1_artifact;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/service/v1/organization.dart"
    as _lib_service_v1_organization;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/service/v1/registration.dart"
    as _lib_service_v1_registration;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/service/v1/topology.dart"
    as _lib_service_v1_topology;
import "package:typewriter_panel/typewriter_panel.dart";

extension UserOrganizationCreateRouteNats
    on _lib_organization_v1_organization.CreateOrganizationRequest {
  SkirRouteOperation<
    _lib_organization_v1_organization.CreateOrganizationResponse
  >
  operation({required String userId}) {
    final user = userId.transportIdentity;

    final method = _lib_organization_v1_organization.createOrganizationMethod;
    return SkirRouteOperation(
      subject: "cloud.to.user.$user.organization.create",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
      outcome: _createOrganizationOutcome,
    );
  }
}

const UserOrganizationsWatchRouteProjection = PersistentProjectionRoute(
  id: "user_organizations_changed",
  organizationScoped: false,
);

extension UserOrganizationsWatchRouteNats
    on _lib_organization_v1_user.WatchUserOrganizationsRequest {
  SkirRouteOperation<_lib_organization_v1_user.WatchUserOrganizationsResponse>
  operation({required String userId}) {
    final user = userId.transportIdentity;

    final method = _lib_organization_v1_user.watchUserOrganizationsMethod;
    return SkirRouteOperation(
      subject: "cloud.to.user.$user.organization.watch",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
      outcome: _watchUserOrganizationsOutcome,
    );
  }

  Stream<TData> watch<TData>(
    Ref ref, {
    required String userId,

    required TData Function(
      _lib_organization_v1_user.WatchUserOrganizationsResponse,
    )
    snapshot,
    required TData Function(
      TData,
      _lib_organization_v1_organization.UserOrganizationsChanged,
    )
    reduce,
    required ProjectionReconciliation<
      TData,
      _lib_organization_v1_user.WatchUserOrganizationsResponse,
      _lib_organization_v1_organization.UserOrganizationsChanged
    >
    reconciliation,
    Stream<_lib_organization_v1_organization.UserOrganizationsChanged>?
    confirmedEvents,
    TData Function(
      TData,
      _lib_organization_v1_organization.UserOrganizationsChanged,
    )?
    reduceConfirmed,
    TData Function(TData, TData)? reconcileSnapshot,
    TData? initialValue,
  }) {
    final user = userId.transportIdentity;

    final operation = this.operation(userId: userId);
    return ref.watchProjection<
      TData,
      _lib_organization_v1_user.WatchUserOrganizationsResponse,
      _lib_organization_v1_organization.UserOrganizationsChanged
    >(
      subject: operation.subject,
      eventSubject: "cloud.from.user.$user.organizations.changed",
      requestBytes: operation.requestBytes,
      responseSerializer: operation.responseSerializer,
      eventSerializer:
          _lib_organization_v1_organization.UserOrganizationsChanged.serializer,
      snapshot: snapshot,
      reduce: reduce,
      delivery: ProjectionDelivery.persistent(
        stream: "TYPEWRITER_MEMBERSHIP",
        consumer: UserOrganizationsWatchRouteProjection.consumerName(
          ref.read(natsProvider),
        ),
      ),
      reconciliation: reconciliation,
      confirmedEvents: confirmedEvents,
      reduceConfirmed: reduceConfirmed,
      reconcileSnapshot: reconcileSnapshot,
      initialValue: initialValue,
    );
  }
}

const UserJoinRequestsWatchRouteProjection = PersistentProjectionRoute(
  id: "user_join_requests_changed",
  organizationScoped: false,
);

extension UserJoinRequestsWatchRouteNats
    on _lib_organization_v1_user.WatchUserJoinRequestsRequest {
  SkirRouteOperation<_lib_organization_v1_user.WatchUserJoinRequestsResponse>
  operation({required String userId}) {
    final user = userId.transportIdentity;

    final method = _lib_organization_v1_user.watchUserJoinRequestsMethod;
    return SkirRouteOperation(
      subject: "cloud.to.user.$user.organization.join_requests.watch",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
      outcome: _watchUserJoinRequestsOutcome,
    );
  }

  Stream<TData> watch<TData>(
    Ref ref, {
    required String userId,

    required TData Function(
      _lib_organization_v1_user.WatchUserJoinRequestsResponse,
    )
    snapshot,
    required TData Function(
      TData,
      _lib_organization_v1_join_request.UserJoinRequestsChanged,
    )
    reduce,
    required ProjectionReconciliation<
      TData,
      _lib_organization_v1_user.WatchUserJoinRequestsResponse,
      _lib_organization_v1_join_request.UserJoinRequestsChanged
    >
    reconciliation,
    Stream<_lib_organization_v1_join_request.UserJoinRequestsChanged>?
    confirmedEvents,
    TData Function(
      TData,
      _lib_organization_v1_join_request.UserJoinRequestsChanged,
    )?
    reduceConfirmed,
    TData Function(TData, TData)? reconcileSnapshot,
    TData? initialValue,
  }) {
    final user = userId.transportIdentity;

    final operation = this.operation(userId: userId);
    return ref.watchProjection<
      TData,
      _lib_organization_v1_user.WatchUserJoinRequestsResponse,
      _lib_organization_v1_join_request.UserJoinRequestsChanged
    >(
      subject: operation.subject,
      eventSubject: "cloud.from.user.$user.join_requests.changed",
      requestBytes: operation.requestBytes,
      responseSerializer: operation.responseSerializer,
      eventSerializer:
          _lib_organization_v1_join_request.UserJoinRequestsChanged.serializer,
      snapshot: snapshot,
      reduce: reduce,
      delivery: ProjectionDelivery.persistent(
        stream: "TYPEWRITER_MEMBERSHIP",
        consumer: UserJoinRequestsWatchRouteProjection.consumerName(
          ref.read(natsProvider),
        ),
      ),
      reconciliation: reconciliation,
      confirmedEvents: confirmedEvents,
      reduceConfirmed: reduceConfirmed,
      reconcileSnapshot: reconcileSnapshot,
      initialValue: initialValue,
    );
  }
}

extension UserJoinRequestSubmitRouteNats
    on _lib_organization_v1_user.SubmitUserJoinRequestRequest {
  SkirRouteOperation<_lib_organization_v1_user.SubmitUserJoinRequestResponse>
  operation({required String userId}) {
    final user = userId.transportIdentity;

    final method = _lib_organization_v1_user.submitUserJoinRequestMethod;
    return SkirRouteOperation(
      subject: "cloud.to.user.$user.organization.join_requests.request",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
      outcome: _submitUserJoinRequestOutcome,
    );
  }
}

extension UserJoinRequestCancelRouteNats
    on _lib_organization_v1_user.CancelUserJoinRequestRequest {
  SkirRouteOperation<_lib_organization_v1_user.CancelUserJoinRequestResponse>
  operation({required String userId}) {
    final user = userId.transportIdentity;

    final method = _lib_organization_v1_user.cancelUserJoinRequestMethod;
    return SkirRouteOperation(
      subject: "cloud.to.user.$user.organization.join_requests.cancel",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
      outcome: _cancelUserJoinRequestOutcome,
    );
  }
}

const OrganizationMembersWatchRouteProjection = PersistentProjectionRoute(
  id: "organization_members_changed",
  organizationScoped: true,
);

extension OrganizationMembersWatchRouteNats
    on _lib_organization_v1_member.WatchOrganizationMembersRequest {
  SkirRouteOperation<
    _lib_organization_v1_member.WatchOrganizationMembersResponse
  >
  operation({required String userId, required _skir.RecordId organizationId}) {
    final user = userId.transportIdentity;

    final organization = organizationId.id.transportIdentity;

    final method = _lib_organization_v1_member.watchOrganizationMembersMethod;
    return SkirRouteOperation(
      subject: "cloud.to.user.$user.organization.$organization.members.watch",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
      outcome: _watchOrganizationMembersOutcome,
    );
  }

  Stream<TData> watch<TData>(
    Ref ref, {
    required String userId,

    required _skir.RecordId organizationId,

    required TData Function(
      _lib_organization_v1_member.WatchOrganizationMembersResponse,
    )
    snapshot,
    required TData Function(
      TData,
      _lib_organization_v1_member.OrganizationMembersChanged,
    )
    reduce,
    required ProjectionReconciliation<
      TData,
      _lib_organization_v1_member.WatchOrganizationMembersResponse,
      _lib_organization_v1_member.OrganizationMembersChanged
    >
    reconciliation,
    Stream<_lib_organization_v1_member.OrganizationMembersChanged>?
    confirmedEvents,
    TData Function(
      TData,
      _lib_organization_v1_member.OrganizationMembersChanged,
    )?
    reduceConfirmed,
    TData Function(TData, TData)? reconcileSnapshot,
    TData? initialValue,
  }) {
    final organization = organizationId.id.transportIdentity;

    final operation = this.operation(
      userId: userId,

      organizationId: organizationId,
    );
    return ref.watchProjection<
      TData,
      _lib_organization_v1_member.WatchOrganizationMembersResponse,
      _lib_organization_v1_member.OrganizationMembersChanged
    >(
      subject: operation.subject,
      eventSubject: "cloud.from.organization.$organization.members.changed",
      requestBytes: operation.requestBytes,
      responseSerializer: operation.responseSerializer,
      eventSerializer:
          _lib_organization_v1_member.OrganizationMembersChanged.serializer,
      snapshot: snapshot,
      reduce: reduce,
      delivery: ProjectionDelivery.persistent(
        stream: "TYPEWRITER_MEMBERSHIP",
        consumer: OrganizationMembersWatchRouteProjection.consumerName(
          ref.read(natsProvider),
        ),
      ),
      reconciliation: reconciliation,
      confirmedEvents: confirmedEvents,
      reduceConfirmed: reduceConfirmed,
      reconcileSnapshot: reconcileSnapshot,
      initialValue: initialValue,
    );
  }
}

extension OrganizationMembersUpdateRouteNats
    on _lib_organization_v1_member.UpdateOrganizationMemberRolesRequest {
  SkirRouteOperation<
    _lib_organization_v1_member.UpdateOrganizationMemberRolesResponse
  >
  operation({required String userId, required _skir.RecordId organizationId}) {
    final user = userId.transportIdentity;

    final organization = organizationId.id.transportIdentity;

    final method =
        _lib_organization_v1_member.updateOrganizationMemberRolesMethod;
    return SkirRouteOperation(
      subject: "cloud.to.user.$user.organization.$organization.members.update",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
      outcome: _updateOrganizationMemberRolesOutcome,
    );
  }
}

extension OrganizationMemberRemoveRouteNats
    on _lib_organization_v1_member.RemoveOrganizationMemberRequest {
  SkirRouteOperation<
    _lib_organization_v1_member.RemoveOrganizationMemberResponse
  >
  operation({required String userId, required _skir.RecordId organizationId}) {
    final user = userId.transportIdentity;

    final organization = organizationId.id.transportIdentity;

    final method = _lib_organization_v1_member.removeOrganizationMemberMethod;
    return SkirRouteOperation(
      subject: "cloud.to.user.$user.organization.$organization.members.remove",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
      outcome: _removeOrganizationMemberOutcome,
    );
  }
}

const OrganizationJoinRequestsWatchRouteProjection = PersistentProjectionRoute(
  id: "organization_join_requests_changed",
  organizationScoped: true,
);

extension OrganizationJoinRequestsWatchRouteNats
    on _lib_organization_v1_join_request.WatchOrganizationJoinRequestsRequest {
  SkirRouteOperation<
    _lib_organization_v1_join_request.WatchOrganizationJoinRequestsResponse
  >
  operation({required String userId, required _skir.RecordId organizationId}) {
    final user = userId.transportIdentity;

    final organization = organizationId.id.transportIdentity;

    final method =
        _lib_organization_v1_join_request.watchOrganizationJoinRequestsMethod;
    return SkirRouteOperation(
      subject:
          "cloud.to.user.$user.organization.$organization.members.join_requests.watch",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
      outcome: _watchOrganizationJoinRequestsOutcome,
    );
  }

  Stream<TData> watch<TData>(
    Ref ref, {
    required String userId,

    required _skir.RecordId organizationId,

    required TData Function(
      _lib_organization_v1_join_request.WatchOrganizationJoinRequestsResponse,
    )
    snapshot,
    required TData Function(
      TData,
      _lib_organization_v1_join_request.OrganizationJoinRequestsChanged,
    )
    reduce,
    required ProjectionReconciliation<
      TData,
      _lib_organization_v1_join_request.WatchOrganizationJoinRequestsResponse,
      _lib_organization_v1_join_request.OrganizationJoinRequestsChanged
    >
    reconciliation,
    Stream<_lib_organization_v1_join_request.OrganizationJoinRequestsChanged>?
    confirmedEvents,
    TData Function(
      TData,
      _lib_organization_v1_join_request.OrganizationJoinRequestsChanged,
    )?
    reduceConfirmed,
    TData Function(TData, TData)? reconcileSnapshot,
    TData? initialValue,
  }) {
    final organization = organizationId.id.transportIdentity;

    final operation = this.operation(
      userId: userId,

      organizationId: organizationId,
    );
    return ref.watchProjection<
      TData,
      _lib_organization_v1_join_request.WatchOrganizationJoinRequestsResponse,
      _lib_organization_v1_join_request.OrganizationJoinRequestsChanged
    >(
      subject: operation.subject,
      eventSubject:
          "cloud.from.organization.$organization.join_requests.changed",
      requestBytes: operation.requestBytes,
      responseSerializer: operation.responseSerializer,
      eventSerializer: _lib_organization_v1_join_request
          .OrganizationJoinRequestsChanged
          .serializer,
      snapshot: snapshot,
      reduce: reduce,
      delivery: ProjectionDelivery.persistent(
        stream: "TYPEWRITER_MEMBERSHIP",
        consumer: OrganizationJoinRequestsWatchRouteProjection.consumerName(
          ref.read(natsProvider),
        ),
      ),
      reconciliation: reconciliation,
      confirmedEvents: confirmedEvents,
      reduceConfirmed: reduceConfirmed,
      reconcileSnapshot: reconcileSnapshot,
      initialValue: initialValue,
    );
  }
}

extension OrganizationJoinRequestsApproveRouteNats
    on _lib_organization_v1_join_request.ApproveOrganizationJoinRequestsRequest {
  SkirRouteOperation<
    _lib_organization_v1_join_request.ApproveOrganizationJoinRequestsResponse
  >
  operation({required String userId, required _skir.RecordId organizationId}) {
    final user = userId.transportIdentity;

    final organization = organizationId.id.transportIdentity;

    final method =
        _lib_organization_v1_join_request.approveOrganizationJoinRequestsMethod;
    return SkirRouteOperation(
      subject:
          "cloud.to.user.$user.organization.$organization.members.join_requests.approve",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
      outcome: _approveOrganizationJoinRequestsOutcome,
    );
  }
}

extension OrganizationJoinRequestDeclineRouteNats
    on _lib_organization_v1_join_request.DeclineOrganizationJoinRequestRequest {
  SkirRouteOperation<
    _lib_organization_v1_join_request.DeclineOrganizationJoinRequestResponse
  >
  operation({required String userId, required _skir.RecordId organizationId}) {
    final user = userId.transportIdentity;

    final organization = organizationId.id.transportIdentity;

    final method =
        _lib_organization_v1_join_request.declineOrganizationJoinRequestMethod;
    return SkirRouteOperation(
      subject:
          "cloud.to.user.$user.organization.$organization.members.join_requests.decline",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
      outcome: _declineOrganizationJoinRequestOutcome,
    );
  }
}

const OrganizationJoinCodesWatchRouteProjection = PersistentProjectionRoute(
  id: "organization_join_codes_changed",
  organizationScoped: true,
);

extension OrganizationJoinCodesWatchRouteNats
    on _lib_organization_v1_join_codes.WatchOrganizationJoinCodesRequest {
  SkirRouteOperation<
    _lib_organization_v1_join_codes.WatchOrganizationJoinCodesResponse
  >
  operation({required String userId, required _skir.RecordId organizationId}) {
    final user = userId.transportIdentity;

    final organization = organizationId.id.transportIdentity;

    final method =
        _lib_organization_v1_join_codes.watchOrganizationJoinCodesMethod;
    return SkirRouteOperation(
      subject:
          "cloud.to.user.$user.organization.$organization.members.join_codes.watch",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
      outcome: _watchOrganizationJoinCodesOutcome,
    );
  }

  Stream<TData> watch<TData>(
    Ref ref, {
    required String userId,

    required _skir.RecordId organizationId,

    required TData Function(
      _lib_organization_v1_join_codes.WatchOrganizationJoinCodesResponse,
    )
    snapshot,
    required TData Function(
      TData,
      _lib_organization_v1_join_codes.OrganizationJoinCodesChanged,
    )
    reduce,
    required ProjectionReconciliation<
      TData,
      _lib_organization_v1_join_codes.WatchOrganizationJoinCodesResponse,
      _lib_organization_v1_join_codes.OrganizationJoinCodesChanged
    >
    reconciliation,
    Stream<_lib_organization_v1_join_codes.OrganizationJoinCodesChanged>?
    confirmedEvents,
    TData Function(
      TData,
      _lib_organization_v1_join_codes.OrganizationJoinCodesChanged,
    )?
    reduceConfirmed,
    TData Function(TData, TData)? reconcileSnapshot,
    TData? initialValue,
  }) {
    final organization = organizationId.id.transportIdentity;

    final operation = this.operation(
      userId: userId,

      organizationId: organizationId,
    );
    return ref.watchProjection<
      TData,
      _lib_organization_v1_join_codes.WatchOrganizationJoinCodesResponse,
      _lib_organization_v1_join_codes.OrganizationJoinCodesChanged
    >(
      subject: operation.subject,
      eventSubject: "cloud.from.organization.$organization.join_codes.changed",
      requestBytes: operation.requestBytes,
      responseSerializer: operation.responseSerializer,
      eventSerializer: _lib_organization_v1_join_codes
          .OrganizationJoinCodesChanged
          .serializer,
      snapshot: snapshot,
      reduce: reduce,
      delivery: ProjectionDelivery.persistent(
        stream: "TYPEWRITER_MEMBERSHIP",
        consumer: OrganizationJoinCodesWatchRouteProjection.consumerName(
          ref.read(natsProvider),
        ),
      ),
      reconciliation: reconciliation,
      confirmedEvents: confirmedEvents,
      reduceConfirmed: reduceConfirmed,
      reconcileSnapshot: reconcileSnapshot,
      initialValue: initialValue,
    );
  }
}

extension OrganizationJoinCodeGenerateRouteNats
    on _lib_organization_v1_join_codes.GenerateOrganizationJoinCodeRequest {
  SkirRouteOperation<
    _lib_organization_v1_join_codes.GenerateOrganizationJoinCodeResponse
  >
  operation({required String userId, required _skir.RecordId organizationId}) {
    final user = userId.transportIdentity;

    final organization = organizationId.id.transportIdentity;

    final method =
        _lib_organization_v1_join_codes.generateOrganizationJoinCodeMethod;
    return SkirRouteOperation(
      subject:
          "cloud.to.user.$user.organization.$organization.members.join_codes.generate",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
      outcome: _generateOrganizationJoinCodeOutcome,
    );
  }
}

extension OrganizationJoinCodeRevokeRouteNats
    on _lib_organization_v1_join_codes.RevokeOrganizationJoinCodeRequest {
  SkirRouteOperation<
    _lib_organization_v1_join_codes.RevokeOrganizationJoinCodeResponse
  >
  operation({required String userId, required _skir.RecordId organizationId}) {
    final user = userId.transportIdentity;

    final organization = organizationId.id.transportIdentity;

    final method =
        _lib_organization_v1_join_codes.revokeOrganizationJoinCodeMethod;
    return SkirRouteOperation(
      subject:
          "cloud.to.user.$user.organization.$organization.members.join_codes.revoke",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
      outcome: _revokeOrganizationJoinCodeOutcome,
    );
  }
}

extension OrganizationRolesWatchRouteNats
    on _lib_organization_v1_role.WatchOrganizationRolesRequest {
  SkirRouteOperation<_lib_organization_v1_role.WatchOrganizationRolesResponse>
  operation({required String userId, required _skir.RecordId organizationId}) {
    final user = userId.transportIdentity;

    final organization = organizationId.id.transportIdentity;

    final method = _lib_organization_v1_role.watchOrganizationRolesMethod;
    return SkirRouteOperation(
      subject: "cloud.to.user.$user.organization.$organization.roles.watch",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
      outcome: _watchOrganizationRolesOutcome,
    );
  }
}

extension ServiceBindRouteNats
    on _lib_service_v1_registration.BindServiceRequest {
  SkirRouteOperation<_lib_service_v1_registration.BindServiceResponse>
  operation({required String userId, required _skir.RecordId organizationId}) {
    final user = userId.transportIdentity;

    final organization = organizationId.id.transportIdentity;

    final method = _lib_service_v1_registration.bindServiceMethod;
    return SkirRouteOperation(
      subject: "cloud.to.user.$user.organization.$organization.services.bind",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
      outcome: _bindServiceOutcome,
    );
  }
}

extension OrganizationServicesWatchRouteNats
    on _lib_service_v1_organization.WatchOrganizationServicesRequest {
  SkirRouteOperation<
    _lib_service_v1_organization.WatchOrganizationServicesResponse
  >
  operation({required String userId, required _skir.RecordId organizationId}) {
    final user = userId.transportIdentity;

    final organization = organizationId.id.transportIdentity;

    final method = _lib_service_v1_organization.watchOrganizationServicesMethod;
    return SkirRouteOperation(
      subject: "cloud.to.user.$user.organization.$organization.services.watch",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
      outcome: _watchOrganizationServicesOutcome,
    );
  }

  Stream<TData> watch<TData>(
    Ref ref, {
    required String userId,

    required _skir.RecordId organizationId,

    required TData Function(
      _lib_service_v1_organization.WatchOrganizationServicesResponse,
    )
    snapshot,
    required TData Function(
      TData,
      _lib_service_v1_organization.OrganizationServicesChanged,
    )
    reduce,
    required ProjectionReconciliation<
      TData,
      _lib_service_v1_organization.WatchOrganizationServicesResponse,
      _lib_service_v1_organization.OrganizationServicesChanged
    >
    reconciliation,
    Stream<_lib_service_v1_organization.OrganizationServicesChanged>?
    confirmedEvents,
    TData Function(
      TData,
      _lib_service_v1_organization.OrganizationServicesChanged,
    )?
    reduceConfirmed,
    TData Function(TData, TData)? reconcileSnapshot,
    TData? initialValue,
  }) {
    final organization = organizationId.id.transportIdentity;

    final operation = this.operation(
      userId: userId,

      organizationId: organizationId,
    );
    return ref.watchProjection<
      TData,
      _lib_service_v1_organization.WatchOrganizationServicesResponse,
      _lib_service_v1_organization.OrganizationServicesChanged
    >(
      subject: operation.subject,
      eventSubject: "cloud.from.organization.$organization.services.watch",
      requestBytes: operation.requestBytes,
      responseSerializer: operation.responseSerializer,
      eventSerializer:
          _lib_service_v1_organization.OrganizationServicesChanged.serializer,
      snapshot: snapshot,
      reduce: reduce,
      delivery: const ProjectionDelivery.ephemeral(),
      reconciliation: reconciliation,
      confirmedEvents: confirmedEvents,
      reduceConfirmed: reduceConfirmed,
      reconcileSnapshot: reconcileSnapshot,
      initialValue: initialValue,
    );
  }
}

extension OrganizationServiceUpdateRouteNats
    on _lib_service_v1_organization.UpdateOrganizationServiceRequest {
  SkirRouteOperation<
    _lib_service_v1_organization.UpdateOrganizationServiceResponse
  >
  operation({required String userId, required _skir.RecordId organizationId}) {
    final user = userId.transportIdentity;

    final organization = organizationId.id.transportIdentity;

    final method = _lib_service_v1_organization.updateOrganizationServiceMethod;
    return SkirRouteOperation(
      subject: "cloud.to.user.$user.organization.$organization.services.update",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
      outcome: _updateOrganizationServiceOutcome,
    );
  }
}

extension ServiceUnbindRouteNats
    on _lib_service_v1_registration.UnbindServiceRequest {
  SkirRouteOperation<_lib_service_v1_registration.UnbindServiceResponse>
  operation({required String userId, required _skir.RecordId organizationId}) {
    final user = userId.transportIdentity;

    final organization = organizationId.id.transportIdentity;

    final method = _lib_service_v1_registration.unbindServiceMethod;
    return SkirRouteOperation(
      subject: "cloud.to.user.$user.organization.$organization.services.unbind",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
      outcome: _unbindServiceOutcome,
    );
  }
}

extension ServiceTopologyConfigureRouteNats
    on _lib_service_v1_topology.ConfigureServiceHostRequest {
  SkirRouteOperation<_lib_service_v1_topology.ConfigureServiceHostResponse>
  operation({required String userId, required _skir.RecordId organizationId}) {
    final user = userId.transportIdentity;

    final organization = organizationId.id.transportIdentity;

    final method = _lib_service_v1_topology.configureServiceHostMethod;
    return SkirRouteOperation(
      subject:
          "cloud.to.user.$user.organization.$organization.topology.configure",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
      outcome: _configureServiceHostOutcome,
    );
  }
}

extension OrganizationTopologyWatchRouteNats
    on _lib_service_v1_topology.WatchOrganizationTopologyRequest {
  SkirRouteOperation<_lib_service_v1_topology.WatchOrganizationTopologyResponse>
  operation({required String userId, required _skir.RecordId organizationId}) {
    final user = userId.transportIdentity;

    final organization = organizationId.id.transportIdentity;

    final method = _lib_service_v1_topology.watchOrganizationTopologyMethod;
    return SkirRouteOperation(
      subject: "cloud.to.user.$user.organization.$organization.topology.watch",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
      outcome: _watchOrganizationTopologyOutcome,
    );
  }

  Stream<TData> watch<TData>(
    Ref ref, {
    required String userId,

    required _skir.RecordId organizationId,

    required TData Function(
      _lib_service_v1_topology.WatchOrganizationTopologyResponse,
    )
    snapshot,
    required TData Function(
      TData,
      _lib_service_v1_topology.OrganizationTopologyChanged,
    )
    reduce,
    required ProjectionReconciliation<
      TData,
      _lib_service_v1_topology.WatchOrganizationTopologyResponse,
      _lib_service_v1_topology.OrganizationTopologyChanged
    >
    reconciliation,
    Stream<_lib_service_v1_topology.OrganizationTopologyChanged>?
    confirmedEvents,
    TData Function(TData, _lib_service_v1_topology.OrganizationTopologyChanged)?
    reduceConfirmed,
    TData Function(TData, TData)? reconcileSnapshot,
    TData? initialValue,
  }) {
    final organization = organizationId.id.transportIdentity;

    final operation = this.operation(
      userId: userId,

      organizationId: organizationId,
    );
    return ref.watchProjection<
      TData,
      _lib_service_v1_topology.WatchOrganizationTopologyResponse,
      _lib_service_v1_topology.OrganizationTopologyChanged
    >(
      subject: operation.subject,
      eventSubject: "cloud.from.organization.$organization.topology.watch",
      requestBytes: operation.requestBytes,
      responseSerializer: operation.responseSerializer,
      eventSerializer:
          _lib_service_v1_topology.OrganizationTopologyChanged.serializer,
      snapshot: snapshot,
      reduce: reduce,
      delivery: const ProjectionDelivery.ephemeral(),
      reconciliation: reconciliation,
      confirmedEvents: confirmedEvents,
      reduceConfirmed: reduceConfirmed,
      reconcileSnapshot: reconcileSnapshot,
      initialValue: initialValue,
    );
  }
}

extension EditorCatalogFetchRouteNats
    on _lib_editor_v1_catalog.CatalogFetchRequest {
  SkirRouteOperation<_lib_editor_v1_catalog.CatalogFetchResult> operation({
    required _skir.RecordId organizationId,

    required _skir.RecordId realmId,
  }) {
    final organization = organizationId.id.transportIdentity;

    final realm = realmId.id.transportIdentity;

    final method = _lib_editor_v1_catalog.fetchEditorCatalogMethod;
    return SkirRouteOperation(
      subject:
          "service.to.$realm.organization.$organization.realm.editor.catalog.fetch",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
      outcome: _fetchEditorCatalogOutcome,
    );
  }
}

extension EditorCatalogWatchRouteNats
    on _lib_editor_v1_catalog.WatchEditorCatalogRequest {
  SkirRouteOperation<_lib_editor_v1_catalog.WatchEditorCatalogResponse>
  operation({
    required _skir.RecordId organizationId,

    required _skir.RecordId realmId,
  }) {
    final organization = organizationId.id.transportIdentity;

    final realm = realmId.id.transportIdentity;

    final method = _lib_editor_v1_catalog.watchEditorCatalogMethod;
    return SkirRouteOperation(
      subject:
          "service.to.$realm.organization.$organization.realm.editor.catalog.invalidate",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
      outcome: _watchEditorCatalogOutcome,
    );
  }

  Stream<TData> watch<TData>(
    Ref ref, {
    required _skir.RecordId organizationId,

    required _skir.RecordId realmId,

    required TData Function(_lib_editor_v1_catalog.WatchEditorCatalogResponse)
    snapshot,
    required TData Function(TData, _lib_editor_v1_catalog.CatalogInvalidated)
    reduce,
    required ProjectionReconciliation<
      TData,
      _lib_editor_v1_catalog.WatchEditorCatalogResponse,
      _lib_editor_v1_catalog.CatalogInvalidated
    >
    reconciliation,
    Stream<_lib_editor_v1_catalog.CatalogInvalidated>? confirmedEvents,
    TData Function(TData, _lib_editor_v1_catalog.CatalogInvalidated)?
    reduceConfirmed,
    TData Function(TData, TData)? reconcileSnapshot,
    TData? initialValue,
  }) {
    final organization = organizationId.id.transportIdentity;

    final realm = realmId.id.transportIdentity;

    final operation = this.operation(
      organizationId: organizationId,

      realmId: realmId,
    );
    return ref.watchProjection<
      TData,
      _lib_editor_v1_catalog.WatchEditorCatalogResponse,
      _lib_editor_v1_catalog.CatalogInvalidated
    >(
      subject: operation.subject,
      eventSubject:
          "service.from.$realm.organization.$organization.realm.editor.catalog.invalidate",
      requestBytes: operation.requestBytes,
      responseSerializer: operation.responseSerializer,
      eventSerializer: _lib_editor_v1_catalog.CatalogInvalidated.serializer,
      snapshot: snapshot,
      reduce: reduce,
      delivery: const ProjectionDelivery.ephemeral(),
      reconciliation: reconciliation,
      confirmedEvents: confirmedEvents,
      reduceConfirmed: reduceConfirmed,
      reconcileSnapshot: reconcileSnapshot,
      initialValue: initialValue,
    );
  }
}

extension EditorValuePrepareRouteNats
    on _lib_editor_v1_catalog.PreparationOperation {
  SkirRouteOperation<_lib_editor_v1_catalog.PrepareValueResult> operation({
    required _skir.RecordId organizationId,

    required _skir.RecordId realmId,
  }) {
    final organization = organizationId.id.transportIdentity;

    final realm = realmId.id.transportIdentity;

    final method = _lib_editor_v1_catalog.prepareValueMethod;
    return SkirRouteOperation(
      subject:
          "service.to.$realm.organization.$organization.realm.editor.creation.prepare",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
      outcome: _prepareValueOutcome,
    );
  }
}

extension EditorPresentationSearchRouteNats
    on _lib_editor_v1_search.RealmPresentationSearchRequest {
  SkirRouteOperation<_lib_editor_v1_search.RealmPresentationSearchUpdate>
  operation({
    required _skir.RecordId organizationId,

    required _skir.RecordId realmId,
  }) {
    final organization = organizationId.id.transportIdentity;

    final realm = realmId.id.transportIdentity;

    final method = _lib_editor_v1_search.watchRealmPresentationSearchMethod;
    return SkirRouteOperation(
      subject:
          "service.to.$realm.organization.$organization.realm.editor.presentation.search",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
      outcome: _watchRealmPresentationSearchOutcome,
    );
  }

  Stream<TData> watch<TData>(
    Ref ref, {
    required _skir.RecordId organizationId,

    required _skir.RecordId realmId,

    required TData Function(_lib_editor_v1_search.RealmPresentationSearchUpdate)
    snapshot,
    required TData Function(
      TData,
      _lib_editor_v1_search.RealmPresentationSearchUpdate,
    )
    reduce,
    required ProjectionReconciliation<
      TData,
      _lib_editor_v1_search.RealmPresentationSearchUpdate,
      _lib_editor_v1_search.RealmPresentationSearchUpdate
    >
    reconciliation,
    Stream<_lib_editor_v1_search.RealmPresentationSearchUpdate>?
    confirmedEvents,
    TData Function(TData, _lib_editor_v1_search.RealmPresentationSearchUpdate)?
    reduceConfirmed,
    TData Function(TData, TData)? reconcileSnapshot,
    TData? initialValue,
  }) {
    final organization = organizationId.id.transportIdentity;

    final realm = realmId.id.transportIdentity;

    final operation = this.operation(
      organizationId: organizationId,

      realmId: realmId,
    );
    return ref.watchProjection<
      TData,
      _lib_editor_v1_search.RealmPresentationSearchUpdate,
      _lib_editor_v1_search.RealmPresentationSearchUpdate
    >(
      subject: operation.subject,
      eventSubject:
          "service.from.$realm.organization.$organization.realm.editor.presentation.search",
      requestBytes: operation.requestBytes,
      responseSerializer: operation.responseSerializer,
      eventSerializer:
          _lib_editor_v1_search.RealmPresentationSearchUpdate.serializer,
      snapshot: snapshot,
      reduce: reduce,
      delivery: const ProjectionDelivery.ephemeral(),
      reconciliation: reconciliation,
      confirmedEvents: confirmedEvents,
      reduceConfirmed: reduceConfirmed,
      reconcileSnapshot: reconcileSnapshot,
      initialValue: initialValue,
    );
  }
}

extension EditorPresentationSearchCancelRouteNats
    on _lib_editor_v1_search.CancelRealmPresentationSearchRequest {
  SkirRouteOperation<_lib_editor_v1_search.CancelRealmPresentationSearchResult>
  operation({
    required _skir.RecordId organizationId,

    required _skir.RecordId realmId,
  }) {
    final organization = organizationId.id.transportIdentity;

    final realm = realmId.id.transportIdentity;

    final method = _lib_editor_v1_search.cancelRealmPresentationSearchMethod;
    return SkirRouteOperation(
      subject:
          "service.to.$realm.organization.$organization.realm.editor.presentation.search.cancel",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
      outcome: _cancelRealmPresentationSearchOutcome,
    );
  }
}

extension EditorCapabilityComputationInvokeRouteNats
    on _lib_editor_v1_capability.CapabilityInvocationRequest {
  SkirRouteOperation<_lib_editor_v1_capability.ComputationResult>
  computationOperation({
    required _skir.RecordId organizationId,

    required _skir.RecordId realmId,
  }) {
    final organization = organizationId.id.transportIdentity;

    final realm = realmId.id.transportIdentity;

    final method = _lib_editor_v1_capability.invokeRealmComputationMethod;
    return SkirRouteOperation(
      subject:
          "service.to.$realm.organization.$organization.realm.editor.capability.computation.invoke",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
      outcome: _invokeRealmComputationOutcome,
    );
  }
}

extension EditorCapabilityCommandInvokeRouteNats
    on _lib_editor_v1_capability.CapabilityInvocationRequest {
  SkirRouteOperation<_lib_editor_v1_capability.CommandResult> commandOperation({
    required _skir.RecordId organizationId,

    required _skir.RecordId realmId,
  }) {
    final organization = organizationId.id.transportIdentity;

    final realm = realmId.id.transportIdentity;

    final method = _lib_editor_v1_capability.invokeRealmCommandMethod;
    return SkirRouteOperation(
      subject:
          "service.to.$realm.organization.$organization.realm.editor.capability.command.invoke",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
      outcome: _invokeRealmCommandOutcome,
    );
  }
}

extension ResourceOperationsResolveRouteNats
    on _lib_editor_v1_resource_operations.ResolveResourceOperationsRequest {
  SkirRouteOperation<
    _lib_editor_v1_resource_operations.ResolveResourceOperationsResult
  >
  operation({
    required _skir.RecordId organizationId,

    required _skir.RecordId realmId,
  }) {
    final organization = organizationId.id.transportIdentity;

    final realm = realmId.id.transportIdentity;

    final method =
        _lib_editor_v1_resource_operations.resolveResourceOperationsMethod;
    return SkirRouteOperation(
      subject:
          "service.to.$realm.organization.$organization.realm.editor.resources.operations.resolve",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
      outcome: _resolveResourceOperationsOutcome,
    );
  }
}

extension ResourceDropCandidatesResolveRouteNats
    on _lib_editor_v1_resource_operations.ResolveDropCandidatesRequest {
  SkirRouteOperation<
    _lib_editor_v1_resource_operations.ResolveDropCandidatesResult
  >
  operation({
    required _skir.RecordId organizationId,

    required _skir.RecordId realmId,
  }) {
    final organization = organizationId.id.transportIdentity;

    final realm = realmId.id.transportIdentity;

    final method =
        _lib_editor_v1_resource_operations.resolveDropCandidatesMethod;
    return SkirRouteOperation(
      subject:
          "service.to.$realm.organization.$organization.realm.editor.resources.drops.resolve",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
      outcome: _resolveDropCandidatesOutcome,
    );
  }
}

extension AuthoringActionPrepareRouteNats
    on _lib_editor_v1_resource_operations.PrepareAuthoringActionRequest {
  SkirRouteOperation<_lib_editor_v1_resource_operations.AuthoringActionResult>
  operation({
    required _skir.RecordId organizationId,

    required _skir.RecordId realmId,
  }) {
    final organization = organizationId.id.transportIdentity;

    final realm = realmId.id.transportIdentity;

    final method =
        _lib_editor_v1_resource_operations.prepareAuthoringActionMethod;
    return SkirRouteOperation(
      subject:
          "service.to.$realm.organization.$organization.realm.editor.resources.actions.prepare",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
      outcome: _prepareAuthoringActionOutcome,
    );
  }
}

extension AuthoringStateQueryRouteNats
    on _lib_editor_v1_authoring.QueryAuthoringStateRequest {
  SkirRouteOperation<_lib_editor_v1_authoring.QueryAuthoringStateResponse>
  operation({
    required _skir.RecordId organizationId,

    required _skir.RecordId realmId,
  }) {
    final organization = organizationId.id.transportIdentity;

    final realm = realmId.id.transportIdentity;

    final method = _lib_editor_v1_authoring.queryAuthoringStateMethod;
    return SkirRouteOperation(
      subject:
          "service.to.$realm.organization.$organization.realm.editor.authoring.state.query",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
      outcome: _queryAuthoringStateOutcome,
    );
  }
}

extension AuthoringEditCommitRouteNats
    on _lib_editor_v1_authoring.PreparedEdit {
  SkirRouteOperation<_lib_editor_v1_authoring.CommitPreparedEditResponse>
  operation({
    required _skir.RecordId organizationId,

    required _skir.RecordId realmId,
  }) {
    final organization = organizationId.id.transportIdentity;

    final realm = realmId.id.transportIdentity;

    final method = _lib_editor_v1_authoring.commitPreparedEditMethod;
    return SkirRouteOperation(
      subject:
          "service.to.$realm.organization.$organization.realm.editor.authoring.edit.commit",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
      outcome: _commitPreparedEditOutcome,
    );
  }
}

extension AuthoringTypePreviewRouteNats
    on _lib_editor_v1_authoring.PreviewTypeArgumentChangeRequest {
  SkirRouteOperation<_lib_editor_v1_authoring.PreviewTypeArgumentChangeResponse>
  operation({
    required _skir.RecordId organizationId,

    required _skir.RecordId realmId,
  }) {
    final organization = organizationId.id.transportIdentity;

    final realm = realmId.id.transportIdentity;

    final method = _lib_editor_v1_authoring.previewTypeArgumentChangeMethod;
    return SkirRouteOperation(
      subject:
          "service.to.$realm.organization.$organization.realm.editor.authoring.type.preview",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
      outcome: _previewTypeArgumentChangeOutcome,
    );
  }
}

extension AuthoringTypeCommitRouteNats
    on _lib_editor_v1_authoring.TypeArgumentChangePreview {
  SkirRouteOperation<_lib_editor_v1_authoring.PrepareTypeArgumentChangeResponse>
  operation({
    required _skir.RecordId organizationId,

    required _skir.RecordId realmId,
  }) {
    final organization = organizationId.id.transportIdentity;

    final realm = realmId.id.transportIdentity;

    final method = _lib_editor_v1_authoring.prepareTypeArgumentChangeMethod;
    return SkirRouteOperation(
      subject:
          "service.to.$realm.organization.$organization.realm.editor.authoring.type.commit",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
      outcome: _prepareTypeArgumentChangeOutcome,
    );
  }
}

extension AuthoringSearchRouteNats
    on _lib_editor_v1_authoring.SearchAuthoringRequest {
  SkirRouteOperation<_lib_editor_v1_authoring.SearchAuthoringResponse>
  operation({
    required _skir.RecordId organizationId,

    required _skir.RecordId realmId,
  }) {
    final organization = organizationId.id.transportIdentity;

    final realm = realmId.id.transportIdentity;

    final method = _lib_editor_v1_authoring.searchAuthoringMethod;
    return SkirRouteOperation(
      subject:
          "service.to.$realm.organization.$organization.realm.editor.authoring.search",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
      outcome: _searchAuthoringOutcome,
    );
  }
}

final class AuthoringChangedRouteEvent {
  const AuthoringChangedRouteEvent._();

  static final serializer =
      _lib_editor_v1_authoring.AuthoringChanged.serializer;

  static String subject({
    required _skir.RecordId organizationId,

    required _skir.RecordId realmId,
  }) {
    final organization = organizationId.id.transportIdentity;

    final realm = realmId.id.transportIdentity;

    return "service.from.$realm.organization.$organization.realm.editor.authoring.changed";
  }
}

extension AuthoringCompiledQueryRouteNats
    on _lib_editor_v1_compiled_content.QueryPublishedContentRequest {
  SkirRouteOperation<
    _lib_editor_v1_compiled_content.QueryPublishedContentResponse
  >
  operation({
    required _skir.RecordId organizationId,

    required _skir.RecordId realmId,
  }) {
    final organization = organizationId.id.transportIdentity;

    final realm = realmId.id.transportIdentity;

    final method = _lib_editor_v1_compiled_content.queryPublishedContentMethod;
    return SkirRouteOperation(
      subject:
          "service.to.$realm.organization.$organization.realm.editor.authoring.compiled.query",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
      outcome: _queryPublishedContentOutcome,
    );
  }
}

final class AuthoringCompiledChangedRouteEvent {
  const AuthoringCompiledChangedRouteEvent._();

  static final serializer =
      _lib_editor_v1_compiled_content.CompiledContentChanged.serializer;

  static String subject({
    required _skir.RecordId organizationId,

    required _skir.RecordId realmId,
  }) {
    final organization = organizationId.id.transportIdentity;

    final realm = realmId.id.transportIdentity;

    return "service.from.$realm.organization.$organization.realm.editor.authoring.compiled.changed";
  }
}

extension AuthoringCompiledStatusQueryRouteNats
    on _lib_editor_v1_compiled_content.QueryCompiledResourceStatusRequest {
  SkirRouteOperation<
    _lib_editor_v1_compiled_content.QueryCompiledResourceStatusResponse
  >
  operation({
    required _skir.RecordId organizationId,

    required _skir.RecordId realmId,
  }) {
    final organization = organizationId.id.transportIdentity;

    final realm = realmId.id.transportIdentity;

    final method =
        _lib_editor_v1_compiled_content.queryCompiledResourceStatusMethod;
    return SkirRouteOperation(
      subject:
          "service.to.$realm.organization.$organization.realm.editor.authoring.compiled.status.query",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
      outcome: _queryCompiledResourceStatusOutcome,
    );
  }
}

extension AuthoringPublishRouteNats
    on _lib_editor_v1_publication.PublishAuthoringRequest {
  SkirRouteOperation<_lib_editor_v1_publication.PublishAuthoringResponse>
  operation({
    required _skir.RecordId organizationId,

    required _skir.RecordId realmId,
  }) {
    final organization = organizationId.id.transportIdentity;

    final realm = realmId.id.transportIdentity;

    final method = _lib_editor_v1_publication.publishAuthoringMethod;
    return SkirRouteOperation(
      subject:
          "service.to.$realm.organization.$organization.realm.editor.authoring.publish",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
      outcome: _publishAuthoringOutcome,
    );
  }
}

extension AuthoringPublicationQueryRouteNats
    on _lib_editor_v1_publication.QueryPublicationViewRequest {
  SkirRouteOperation<_lib_editor_v1_publication.QueryPublicationViewResponse>
  operation({
    required _skir.RecordId organizationId,

    required _skir.RecordId realmId,
  }) {
    final organization = organizationId.id.transportIdentity;

    final realm = realmId.id.transportIdentity;

    final method = _lib_editor_v1_publication.queryPublicationViewMethod;
    return SkirRouteOperation(
      subject:
          "service.to.$realm.organization.$organization.realm.editor.authoring.publication.query",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
      outcome: _queryPublicationViewOutcome,
    );
  }
}

extension AuthoringPublicationWatchRouteNats
    on _lib_editor_v1_publication.WatchPublicationRequest {
  SkirRouteOperation<_lib_editor_v1_publication.WatchPublicationResponse>
  operation({
    required _skir.RecordId organizationId,

    required _skir.RecordId realmId,
  }) {
    final organization = organizationId.id.transportIdentity;

    final realm = realmId.id.transportIdentity;

    final method = _lib_editor_v1_publication.watchPublicationMethod;
    return SkirRouteOperation(
      subject:
          "service.to.$realm.organization.$organization.realm.editor.authoring.publication.watch",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
      outcome: _watchPublicationOutcome,
    );
  }

  Stream<TData> watch<TData>(
    Ref ref, {
    required _skir.RecordId organizationId,

    required _skir.RecordId realmId,

    required TData Function(_lib_editor_v1_publication.WatchPublicationResponse)
    snapshot,
    required TData Function(
      TData,
      _lib_editor_v1_publication.PublicationViewChanged,
    )
    reduce,
    required ProjectionReconciliation<
      TData,
      _lib_editor_v1_publication.WatchPublicationResponse,
      _lib_editor_v1_publication.PublicationViewChanged
    >
    reconciliation,
    Stream<_lib_editor_v1_publication.PublicationViewChanged>? confirmedEvents,
    TData Function(TData, _lib_editor_v1_publication.PublicationViewChanged)?
    reduceConfirmed,
    TData Function(TData, TData)? reconcileSnapshot,
    TData? initialValue,
  }) {
    final organization = organizationId.id.transportIdentity;

    final realm = realmId.id.transportIdentity;

    final operation = this.operation(
      organizationId: organizationId,

      realmId: realmId,
    );
    return ref.watchProjection<
      TData,
      _lib_editor_v1_publication.WatchPublicationResponse,
      _lib_editor_v1_publication.PublicationViewChanged
    >(
      subject: operation.subject,
      eventSubject:
          "service.from.$realm.organization.$organization.realm.editor.authoring.publication.watch",
      requestBytes: operation.requestBytes,
      responseSerializer: operation.responseSerializer,
      eventSerializer:
          _lib_editor_v1_publication.PublicationViewChanged.serializer,
      snapshot: snapshot,
      reduce: reduce,
      delivery: const ProjectionDelivery.ephemeral(),
      reconciliation: reconciliation,
      confirmedEvents: confirmedEvents,
      reduceConfirmed: reduceConfirmed,
      reconcileSnapshot: reconcileSnapshot,
      initialValue: initialValue,
    );
  }
}

extension SharedCatalogFetchRouteNats
    on _lib_service_v1_artifact.FetchSharedArtifactCatalogRequest {
  SkirRouteOperation<
    _lib_service_v1_artifact.FetchSharedArtifactCatalogResponse
  >
  operation({
    required _skir.RecordId organizationId,

    required _skir.RecordId realmId,
  }) {
    final organization = organizationId.id.transportIdentity;

    final realm = realmId.id.transportIdentity;

    final method = _lib_service_v1_artifact.fetchSharedArtifactCatalogMethod;
    return SkirRouteOperation(
      subject:
          "service.to.$realm.organization.$organization.realm.shared.catalog.fetch",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
      outcome: _fetchSharedArtifactCatalogOutcome,
    );
  }
}

extension SharedPublishRouteNats
    on _lib_service_v1_artifact.PublishSharedArtifactRequest {
  SkirRouteOperation<_lib_service_v1_artifact.PublishSharedArtifactResponse>
  operation({
    required _skir.RecordId organizationId,

    required _skir.RecordId realmId,
  }) {
    final organization = organizationId.id.transportIdentity;

    final realm = realmId.id.transportIdentity;

    final method = _lib_service_v1_artifact.publishSharedArtifactMethod;
    return SkirRouteOperation(
      subject:
          "service.to.$realm.organization.$organization.realm.shared.publish",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
      outcome: _publishSharedArtifactOutcome,
    );
  }
}

extension SharedBlobMetadataRouteNats
    on _lib_service_v1_artifact.FetchArtifactBlobMetadataRequest {
  SkirRouteOperation<_lib_service_v1_artifact.FetchArtifactBlobMetadataResponse>
  operation({
    required _skir.RecordId organizationId,

    required _skir.RecordId realmId,
  }) {
    final organization = organizationId.id.transportIdentity;

    final realm = realmId.id.transportIdentity;

    final method = _lib_service_v1_artifact.fetchArtifactBlobMetadataMethod;
    return SkirRouteOperation(
      subject:
          "service.to.$realm.organization.$organization.realm.shared.blob.metadata",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
      outcome: _fetchArtifactBlobMetadataOutcome,
    );
  }
}

extension SharedBlobReadRouteNats
    on _lib_service_v1_artifact.ReadArtifactBlobRequest {
  SkirRouteOperation<_lib_service_v1_artifact.ReadArtifactBlobResponse>
  operation({
    required _skir.RecordId organizationId,

    required _skir.RecordId realmId,
  }) {
    final organization = organizationId.id.transportIdentity;

    final realm = realmId.id.transportIdentity;

    final method = _lib_service_v1_artifact.readArtifactBlobMethod;
    return SkirRouteOperation(
      subject:
          "service.to.$realm.organization.$organization.realm.shared.blob.read",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
      outcome: _readArtifactBlobOutcome,
    );
  }
}

extension SharedBlobBeginRouteNats
    on _lib_service_v1_artifact.BeginArtifactBlobWriteRequest {
  SkirRouteOperation<_lib_service_v1_artifact.BeginArtifactBlobWriteResponse>
  operation({
    required _skir.RecordId organizationId,

    required _skir.RecordId realmId,
  }) {
    final organization = organizationId.id.transportIdentity;

    final realm = realmId.id.transportIdentity;

    final method = _lib_service_v1_artifact.beginArtifactBlobWriteMethod;
    return SkirRouteOperation(
      subject:
          "service.to.$realm.organization.$organization.realm.shared.blob.begin",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
      outcome: _beginArtifactBlobWriteOutcome,
    );
  }
}

extension SharedBlobWriteRouteNats
    on _lib_service_v1_artifact.WriteArtifactBlobChunkRequest {
  SkirRouteOperation<_lib_service_v1_artifact.WriteArtifactBlobChunkResponse>
  operation({
    required _skir.RecordId organizationId,

    required _skir.RecordId realmId,
  }) {
    final organization = organizationId.id.transportIdentity;

    final realm = realmId.id.transportIdentity;

    final method = _lib_service_v1_artifact.writeArtifactBlobChunkMethod;
    return SkirRouteOperation(
      subject:
          "service.to.$realm.organization.$organization.realm.shared.blob.write",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
      outcome: _writeArtifactBlobChunkOutcome,
    );
  }
}

extension SharedBlobCompleteRouteNats
    on _lib_service_v1_artifact.CompleteArtifactBlobWriteRequest {
  SkirRouteOperation<_lib_service_v1_artifact.CompleteArtifactBlobWriteResponse>
  operation({
    required _skir.RecordId organizationId,

    required _skir.RecordId realmId,
  }) {
    final organization = organizationId.id.transportIdentity;

    final realm = realmId.id.transportIdentity;

    final method = _lib_service_v1_artifact.completeArtifactBlobWriteMethod;
    return SkirRouteOperation(
      subject:
          "service.to.$realm.organization.$organization.realm.shared.blob.complete",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
      outcome: _completeArtifactBlobWriteOutcome,
    );
  }
}

final class OrganizationPresenceRouteEvent {
  const OrganizationPresenceRouteEvent._();

  static final serializer =
      _lib_organization_v1_presence.PresenceEvent.serializer;

  static String subject({
    required String userId,

    required _skir.RecordId organizationId,
  }) {
    final user = userId.transportIdentity;

    final organization = organizationId.id.transportIdentity;

    return "typewriter.presence.organization.$organization.user.$user";
  }

  static String subscriptionPattern({required _skir.RecordId organizationId}) {
    final organization = organizationId.id.transportIdentity;
    return "typewriter.presence.organization.$organization.user.*";
  }

  static String? userIdFromSubject(
    String subject, {
    required _skir.RecordId organizationId,
  }) {
    final organization = organizationId.id.transportIdentity;
    final parts = subject.split(".");
    if (parts.length != 6 ||
        parts[0] != "typewriter" ||
        parts[1] != "presence" ||
        parts[2] != "organization" ||
        parts[3] != organization ||
        parts[4] != "user")
      return null;
    final userId = parts[5];
    return userId.isTransportIdentity ? userId : null;
  }
}

ResponseOutcome _createOrganizationOutcome(
  _lib_organization_v1_organization.CreateOrganizationResponse response,
) => switch (response.kind) {
  _lib_organization_v1_organization
      .CreateOrganizationResponse_kind
      .successWrapper =>
    ResponseOutcome.success,
  // internal_error and the generated unknown variant
  _ => ResponseOutcome.internalError,
};

ResponseOutcome _watchUserOrganizationsOutcome(
  _lib_organization_v1_user.WatchUserOrganizationsResponse response,
) => switch (response.kind) {
  _lib_organization_v1_user
      .WatchUserOrganizationsResponse_kind
      .snapshotWrapper ||
  _lib_organization_v1_user
      .WatchUserOrganizationsResponse_kind
      .changedWrapper => ResponseOutcome.success,
  // internal_error and the generated unknown variant
  _ => ResponseOutcome.internalError,
};

ResponseOutcome _watchUserJoinRequestsOutcome(
  _lib_organization_v1_user.WatchUserJoinRequestsResponse response,
) => switch (response.kind) {
  _lib_organization_v1_user
      .WatchUserJoinRequestsResponse_kind
      .snapshotWrapper ||
  _lib_organization_v1_user.WatchUserJoinRequestsResponse_kind.changedWrapper =>
    ResponseOutcome.success,
  // internal_error and the generated unknown variant
  _ => ResponseOutcome.internalError,
};

ResponseOutcome _submitUserJoinRequestOutcome(
  _lib_organization_v1_user.SubmitUserJoinRequestResponse response,
) => switch (response.kind) {
  _lib_organization_v1_user
      .SubmitUserJoinRequestResponse_kind
      .requestMadeWrapper ||
  _lib_organization_v1_user
      .SubmitUserJoinRequestResponse_kind
      .autoAcceptedWrapper => ResponseOutcome.success,
  _lib_organization_v1_user
      .SubmitUserJoinRequestResponse_kind
      .codeNotFoundErrorWrapper ||
  _lib_organization_v1_user
      .SubmitUserJoinRequestResponse_kind
      .alreadyMemberErrorWrapper ||
  _lib_organization_v1_user
      .SubmitUserJoinRequestResponse_kind
      .noAssignableRolesErrorWrapper ||
  _lib_organization_v1_user
      .SubmitUserJoinRequestResponse_kind
      .maxPendingRequestsErrorWrapper ||
  _lib_organization_v1_user
      .SubmitUserJoinRequestResponse_kind
      .pendingRequestExistsErrorWrapper ||
  _lib_organization_v1_user
      .SubmitUserJoinRequestResponse_kind
      .invalidRecordIdErrorWrapper => ResponseOutcome.domainError,
  // internal_error and the generated unknown variant
  _ => ResponseOutcome.internalError,
};

ResponseOutcome _cancelUserJoinRequestOutcome(
  _lib_organization_v1_user.CancelUserJoinRequestResponse response,
) => switch (response.kind) {
  _lib_organization_v1_user.CancelUserJoinRequestResponse_kind.successWrapper =>
    ResponseOutcome.success,
  _lib_organization_v1_user
      .CancelUserJoinRequestResponse_kind
      .requestNotFoundErrorWrapper ||
  _lib_organization_v1_user
      .CancelUserJoinRequestResponse_kind
      .invalidRecordIdErrorWrapper => ResponseOutcome.domainError,
  // internal_error and the generated unknown variant
  _ => ResponseOutcome.internalError,
};

ResponseOutcome _watchOrganizationMembersOutcome(
  _lib_organization_v1_member.WatchOrganizationMembersResponse response,
) => switch (response.kind) {
  _lib_organization_v1_member
      .WatchOrganizationMembersResponse_kind
      .snapshotWrapper =>
    ResponseOutcome.success,
  // internal_error and the generated unknown variant
  _ => ResponseOutcome.internalError,
};

ResponseOutcome _updateOrganizationMemberRolesOutcome(
  _lib_organization_v1_member.UpdateOrganizationMemberRolesResponse response,
) => switch (response.kind) {
  _lib_organization_v1_member
      .UpdateOrganizationMemberRolesResponse_kind
      .successWrapper =>
    ResponseOutcome.success,
  _lib_organization_v1_member
      .UpdateOrganizationMemberRolesResponse_kind
      .userNotFoundErrorWrapper ||
  _lib_organization_v1_member
      .UpdateOrganizationMemberRolesResponse_kind
      .rolesNotFoundErrorWrapper ||
  _lib_organization_v1_member
      .UpdateOrganizationMemberRolesResponse_kind
      .rolesNotAssignableErrorWrapper ||
  _lib_organization_v1_member
      .UpdateOrganizationMemberRolesResponse_kind
      .rolesRequiredErrorWrapper ||
  _lib_organization_v1_member
      .UpdateOrganizationMemberRolesResponse_kind
      .founderRoleRequiredErrorWrapper ||
  _lib_organization_v1_member
      .UpdateOrganizationMemberRolesResponse_kind
      .invalidSelectionErrorWrapper ||
  _lib_organization_v1_member
      .UpdateOrganizationMemberRolesResponse_kind
      .invalidRecordIdErrorWrapper => ResponseOutcome.domainError,
  // internal_error and the generated unknown variant
  _ => ResponseOutcome.internalError,
};

ResponseOutcome _removeOrganizationMemberOutcome(
  _lib_organization_v1_member.RemoveOrganizationMemberResponse response,
) => switch (response.kind) {
  _lib_organization_v1_member
      .RemoveOrganizationMemberResponse_kind
      .successWrapper =>
    ResponseOutcome.success,
  _lib_organization_v1_member
      .RemoveOrganizationMemberResponse_kind
      .userNotMemberErrorWrapper ||
  _lib_organization_v1_member
      .RemoveOrganizationMemberResponse_kind
      .founderCannotBeRemovedErrorWrapper ||
  _lib_organization_v1_member
      .RemoveOrganizationMemberResponse_kind
      .invalidRecordIdErrorWrapper => ResponseOutcome.domainError,
  // internal_error and the generated unknown variant
  _ => ResponseOutcome.internalError,
};

ResponseOutcome _watchOrganizationJoinRequestsOutcome(
  _lib_organization_v1_join_request.WatchOrganizationJoinRequestsResponse
  response,
) => switch (response.kind) {
  _lib_organization_v1_join_request
      .WatchOrganizationJoinRequestsResponse_kind
      .snapshotWrapper ||
  _lib_organization_v1_join_request
      .WatchOrganizationJoinRequestsResponse_kind
      .changedWrapper => ResponseOutcome.success,
  // internal_error and the generated unknown variant
  _ => ResponseOutcome.internalError,
};

ResponseOutcome _approveOrganizationJoinRequestsOutcome(
  _lib_organization_v1_join_request.ApproveOrganizationJoinRequestsResponse
  response,
) => switch (response.kind) {
  _lib_organization_v1_join_request
      .ApproveOrganizationJoinRequestsResponse_kind
      .successWrapper =>
    ResponseOutcome.success,
  _lib_organization_v1_join_request
      .ApproveOrganizationJoinRequestsResponse_kind
      .requestNotFoundErrorWrapper ||
  _lib_organization_v1_join_request
      .ApproveOrganizationJoinRequestsResponse_kind
      .rolesNotFoundErrorWrapper ||
  _lib_organization_v1_join_request
      .ApproveOrganizationJoinRequestsResponse_kind
      .rolesNotAssignableErrorWrapper ||
  _lib_organization_v1_join_request
      .ApproveOrganizationJoinRequestsResponse_kind
      .rolesRequiredErrorWrapper ||
  _lib_organization_v1_join_request
      .ApproveOrganizationJoinRequestsResponse_kind
      .userAlreadyMemberErrorWrapper ||
  _lib_organization_v1_join_request
      .ApproveOrganizationJoinRequestsResponse_kind
      .invalidSelectionErrorWrapper ||
  _lib_organization_v1_join_request
      .ApproveOrganizationJoinRequestsResponse_kind
      .invalidRecordIdErrorWrapper => ResponseOutcome.domainError,
  // internal_error and the generated unknown variant
  _ => ResponseOutcome.internalError,
};

ResponseOutcome _declineOrganizationJoinRequestOutcome(
  _lib_organization_v1_join_request.DeclineOrganizationJoinRequestResponse
  response,
) => switch (response.kind) {
  _lib_organization_v1_join_request
      .DeclineOrganizationJoinRequestResponse_kind
      .successWrapper =>
    ResponseOutcome.success,
  _lib_organization_v1_join_request
      .DeclineOrganizationJoinRequestResponse_kind
      .requestNotFoundErrorWrapper ||
  _lib_organization_v1_join_request
      .DeclineOrganizationJoinRequestResponse_kind
      .invalidRecordIdErrorWrapper => ResponseOutcome.domainError,
  // internal_error and the generated unknown variant
  _ => ResponseOutcome.internalError,
};

ResponseOutcome _watchOrganizationJoinCodesOutcome(
  _lib_organization_v1_join_codes.WatchOrganizationJoinCodesResponse response,
) => switch (response.kind) {
  _lib_organization_v1_join_codes
      .WatchOrganizationJoinCodesResponse_kind
      .snapshotWrapper ||
  _lib_organization_v1_join_codes
      .WatchOrganizationJoinCodesResponse_kind
      .changedWrapper => ResponseOutcome.success,
  // internal_error and the generated unknown variant
  _ => ResponseOutcome.internalError,
};

ResponseOutcome _generateOrganizationJoinCodeOutcome(
  _lib_organization_v1_join_codes.GenerateOrganizationJoinCodeResponse response,
) => switch (response.kind) {
  _lib_organization_v1_join_codes
      .GenerateOrganizationJoinCodeResponse_kind
      .successWrapper =>
    ResponseOutcome.success,
  _lib_organization_v1_join_codes
      .GenerateOrganizationJoinCodeResponse_kind
      .rolesNotFoundErrorWrapper ||
  _lib_organization_v1_join_codes
      .GenerateOrganizationJoinCodeResponse_kind
      .rolesNotAssignableErrorWrapper ||
  _lib_organization_v1_join_codes
      .GenerateOrganizationJoinCodeResponse_kind
      .invalidExpirationErrorWrapper ||
  _lib_organization_v1_join_codes
      .GenerateOrganizationJoinCodeResponse_kind
      .invalidRecordIdErrorWrapper => ResponseOutcome.domainError,
  // internal_error and the generated unknown variant
  _ => ResponseOutcome.internalError,
};

ResponseOutcome _revokeOrganizationJoinCodeOutcome(
  _lib_organization_v1_join_codes.RevokeOrganizationJoinCodeResponse response,
) => switch (response.kind) {
  _lib_organization_v1_join_codes
      .RevokeOrganizationJoinCodeResponse_kind
      .successWrapper =>
    ResponseOutcome.success,
  _lib_organization_v1_join_codes
      .RevokeOrganizationJoinCodeResponse_kind
      .codeNotFoundErrorWrapper ||
  _lib_organization_v1_join_codes
      .RevokeOrganizationJoinCodeResponse_kind
      .invalidRecordIdErrorWrapper => ResponseOutcome.domainError,
  // internal_error and the generated unknown variant
  _ => ResponseOutcome.internalError,
};

ResponseOutcome _watchOrganizationRolesOutcome(
  _lib_organization_v1_role.WatchOrganizationRolesResponse response,
) => switch (response.kind) {
  _lib_organization_v1_role.WatchOrganizationRolesResponse_kind.listWrapper ||
  _lib_organization_v1_role.WatchOrganizationRolesResponse_kind.addWrapper ||
  _lib_organization_v1_role.WatchOrganizationRolesResponse_kind.updateWrapper ||
  _lib_organization_v1_role.WatchOrganizationRolesResponse_kind.removeWrapper =>
    ResponseOutcome.success,
  // internal_error and the generated unknown variant
  _ => ResponseOutcome.internalError,
};

ResponseOutcome _bindServiceOutcome(
  _lib_service_v1_registration.BindServiceResponse response,
) => switch (response.kind) {
  _lib_service_v1_registration.BindServiceResponse_kind.successWrapper =>
    ResponseOutcome.success,
  _lib_service_v1_registration
      .BindServiceResponse_kind
      .invalidRegistrationTokenErrorWrapper ||
  _lib_service_v1_registration
      .BindServiceResponse_kind
      .organizationNotFoundErrorWrapper => ResponseOutcome.domainError,
  // internal_error and the generated unknown variant
  _ => ResponseOutcome.internalError,
};

ResponseOutcome _watchOrganizationServicesOutcome(
  _lib_service_v1_organization.WatchOrganizationServicesResponse response,
) => switch (response.kind) {
  _lib_service_v1_organization
      .WatchOrganizationServicesResponse_kind
      .listWrapper =>
    ResponseOutcome.success,
  // internal_error and the generated unknown variant
  _ => ResponseOutcome.internalError,
};

ResponseOutcome _updateOrganizationServiceOutcome(
  _lib_service_v1_organization.UpdateOrganizationServiceResponse response,
) => switch (response.kind) {
  _lib_service_v1_organization
      .UpdateOrganizationServiceResponse_kind
      .successWrapper =>
    ResponseOutcome.success,
  _lib_service_v1_organization
      .UpdateOrganizationServiceResponse_kind
      .conflictErrorWrapper ||
  _lib_service_v1_organization
      .UpdateOrganizationServiceResponse_kind
      .serviceNotFoundErrorWrapper ||
  _lib_service_v1_organization
      .UpdateOrganizationServiceResponse_kind
      .validationErrorWrapper ||
  _lib_service_v1_organization
      .UpdateOrganizationServiceResponse_kind
      .invalidRecordIdErrorWrapper => ResponseOutcome.domainError,
  // internal_error and the generated unknown variant
  _ => ResponseOutcome.internalError,
};

ResponseOutcome _unbindServiceOutcome(
  _lib_service_v1_registration.UnbindServiceResponse response,
) => switch (response.kind) {
  _lib_service_v1_registration.UnbindServiceResponse_kind.successWrapper =>
    ResponseOutcome.success,
  _lib_service_v1_registration
      .UnbindServiceResponse_kind
      .serviceNotFoundErrorWrapper =>
    ResponseOutcome.domainError,
  // internal_error and the generated unknown variant
  _ => ResponseOutcome.internalError,
};

ResponseOutcome _configureServiceHostOutcome(
  _lib_service_v1_topology.ConfigureServiceHostResponse response,
) => switch (response.kind) {
  _lib_service_v1_topology.ConfigureServiceHostResponse_kind.successWrapper =>
    ResponseOutcome.success,
  _lib_service_v1_topology
      .ConfigureServiceHostResponse_kind
      .conflictErrorWrapper ||
  _lib_service_v1_topology
      .ConfigureServiceHostResponse_kind
      .invalidConfigurationErrorWrapper ||
  _lib_service_v1_topology
      .ConfigureServiceHostResponse_kind
      .incompatibleEngineErrorWrapper ||
  _lib_service_v1_topology
      .ConfigureServiceHostResponse_kind
      .realmNotFoundErrorWrapper ||
  _lib_service_v1_topology
      .ConfigureServiceHostResponse_kind
      .invalidRecordIdErrorWrapper => ResponseOutcome.domainError,
  // internal_error and the generated unknown variant
  _ => ResponseOutcome.internalError,
};

ResponseOutcome _watchOrganizationTopologyOutcome(
  _lib_service_v1_topology.WatchOrganizationTopologyResponse response,
) => switch (response.kind) {
  _lib_service_v1_topology.WatchOrganizationTopologyResponse_kind.listWrapper =>
    ResponseOutcome.success,
  // internal_error and the generated unknown variant
  _ => ResponseOutcome.internalError,
};

ResponseOutcome _fetchEditorCatalogOutcome(
  _lib_editor_v1_catalog.CatalogFetchResult response,
) => switch (response.kind) {
  _lib_editor_v1_catalog.CatalogFetchResult_kind.catalogWrapper =>
    ResponseOutcome.success,
  _lib_editor_v1_catalog
      .CatalogFetchResult_kind
      .generationChangedErrorWrapper =>
    ResponseOutcome.domainError,
  // internal_error and the generated unknown variant
  _ => ResponseOutcome.internalError,
};

ResponseOutcome _watchEditorCatalogOutcome(
  _lib_editor_v1_catalog.WatchEditorCatalogResponse response,
) => switch (response.kind) {
  _lib_editor_v1_catalog.WatchEditorCatalogResponse_kind.invalidatedWrapper =>
    ResponseOutcome.success,
  // internal_error and the generated unknown variant
  _ => ResponseOutcome.internalError,
};

ResponseOutcome _prepareValueOutcome(
  _lib_editor_v1_catalog.PrepareValueResult response,
) => switch (response.kind) {
  _lib_editor_v1_catalog.PrepareValueResult_kind.readyWrapper ||
  _lib_editor_v1_catalog.PrepareValueResult_kind.needsInputWrapper =>
    ResponseOutcome.success,
  _lib_editor_v1_catalog.PrepareValueResult_kind.unavailableErrorWrapper ||
  _lib_editor_v1_catalog.PrepareValueResult_kind.catalogChangedErrorWrapper =>
    ResponseOutcome.domainError,
  // internal_error and the generated unknown variant
  _ => ResponseOutcome.internalError,
};

ResponseOutcome _watchRealmPresentationSearchOutcome(
  _lib_editor_v1_search.RealmPresentationSearchUpdate response,
) => switch (response.kind) {
  _lib_editor_v1_search.RealmPresentationSearchUpdate_kind.snapshotWrapper =>
    ResponseOutcome.success,
  _lib_editor_v1_search
      .RealmPresentationSearchUpdate_kind
      .unavailableErrorWrapper ||
  _lib_editor_v1_search
      .RealmPresentationSearchUpdate_kind
      .staleObservationErrorWrapper => ResponseOutcome.domainError,
  // internal_error and the generated unknown variant
  _ => ResponseOutcome.internalError,
};

ResponseOutcome _cancelRealmPresentationSearchOutcome(
  _lib_editor_v1_search.CancelRealmPresentationSearchResult response,
) => switch (response.kind) {
  _lib_editor_v1_search
      .CancelRealmPresentationSearchResult_kind
      .canceledConst =>
    ResponseOutcome.success,
  _lib_editor_v1_search
      .CancelRealmPresentationSearchResult_kind
      .notFoundErrorConst =>
    ResponseOutcome.domainError,
  // internal_error and the generated unknown variant
  _ => ResponseOutcome.internalError,
};

ResponseOutcome _invokeRealmComputationOutcome(
  _lib_editor_v1_capability.ComputationResult response,
) => switch (response.kind) {
  _lib_editor_v1_capability.ComputationResult_kind.successWrapper =>
    ResponseOutcome.success,
  _lib_editor_v1_capability.ComputationResult_kind.invalidErrorWrapper ||
  _lib_editor_v1_capability.ComputationResult_kind.unavailableErrorWrapper ||
  _lib_editor_v1_capability
      .ComputationResult_kind
      .permissionDeniedErrorWrapper ||
  _lib_editor_v1_capability
      .ComputationResult_kind
      .staleGenerationErrorWrapper => ResponseOutcome.domainError,
  // internal_error and the generated unknown variant
  _ => ResponseOutcome.internalError,
};

ResponseOutcome _invokeRealmCommandOutcome(
  _lib_editor_v1_capability.CommandResult response,
) => switch (response.kind) {
  _lib_editor_v1_capability.CommandResult_kind.successWrapper =>
    ResponseOutcome.success,
  _lib_editor_v1_capability.CommandResult_kind.invalidErrorWrapper ||
  _lib_editor_v1_capability.CommandResult_kind.unavailableErrorWrapper ||
  _lib_editor_v1_capability.CommandResult_kind.permissionDeniedErrorWrapper ||
  _lib_editor_v1_capability.CommandResult_kind.staleGenerationErrorWrapper =>
    ResponseOutcome.domainError,
  // internal_error and the generated unknown variant
  _ => ResponseOutcome.internalError,
};

ResponseOutcome _resolveResourceOperationsOutcome(
  _lib_editor_v1_resource_operations.ResolveResourceOperationsResult response,
) => switch (response.kind) {
  _lib_editor_v1_resource_operations
      .ResolveResourceOperationsResult_kind
      .resolvedWrapper =>
    ResponseOutcome.success,
  _lib_editor_v1_resource_operations
      .ResolveResourceOperationsResult_kind
      .staleObservationErrorWrapper ||
  _lib_editor_v1_resource_operations
      .ResolveResourceOperationsResult_kind
      .invalidErrorWrapper ||
  _lib_editor_v1_resource_operations
      .ResolveResourceOperationsResult_kind
      .catalogChangedErrorWrapper ||
  _lib_editor_v1_resource_operations
      .ResolveResourceOperationsResult_kind
      .permissionDeniedErrorWrapper ||
  _lib_editor_v1_resource_operations
      .ResolveResourceOperationsResult_kind
      .failedErrorWrapper => ResponseOutcome.domainError,
  // internal_error and the generated unknown variant
  _ => ResponseOutcome.internalError,
};

ResponseOutcome _resolveDropCandidatesOutcome(
  _lib_editor_v1_resource_operations.ResolveDropCandidatesResult response,
) => switch (response.kind) {
  _lib_editor_v1_resource_operations
      .ResolveDropCandidatesResult_kind
      .resolvedWrapper =>
    ResponseOutcome.success,
  _lib_editor_v1_resource_operations
      .ResolveDropCandidatesResult_kind
      .staleObservationErrorWrapper ||
  _lib_editor_v1_resource_operations
      .ResolveDropCandidatesResult_kind
      .invalidErrorWrapper ||
  _lib_editor_v1_resource_operations
      .ResolveDropCandidatesResult_kind
      .catalogChangedErrorWrapper ||
  _lib_editor_v1_resource_operations
      .ResolveDropCandidatesResult_kind
      .permissionDeniedErrorWrapper ||
  _lib_editor_v1_resource_operations
      .ResolveDropCandidatesResult_kind
      .failedErrorWrapper => ResponseOutcome.domainError,
  // internal_error and the generated unknown variant
  _ => ResponseOutcome.internalError,
};

ResponseOutcome _prepareAuthoringActionOutcome(
  _lib_editor_v1_resource_operations.AuthoringActionResult response,
) => switch (response.kind) {
  _lib_editor_v1_resource_operations
      .AuthoringActionResult_kind
      .needsInputWrapper ||
  _lib_editor_v1_resource_operations
      .AuthoringActionResult_kind
      .previewWrapper => ResponseOutcome.success,
  _lib_editor_v1_resource_operations
      .AuthoringActionResult_kind
      .staleObservationErrorWrapper ||
  _lib_editor_v1_resource_operations
      .AuthoringActionResult_kind
      .invalidErrorWrapper ||
  _lib_editor_v1_resource_operations
      .AuthoringActionResult_kind
      .unavailableErrorWrapper ||
  _lib_editor_v1_resource_operations
      .AuthoringActionResult_kind
      .catalogChangedErrorWrapper ||
  _lib_editor_v1_resource_operations
      .AuthoringActionResult_kind
      .permissionDeniedErrorWrapper ||
  _lib_editor_v1_resource_operations
      .AuthoringActionResult_kind
      .failedErrorWrapper => ResponseOutcome.domainError,
  // internal_error and the generated unknown variant
  _ => ResponseOutcome.internalError,
};

ResponseOutcome _queryAuthoringStateOutcome(
  _lib_editor_v1_authoring.QueryAuthoringStateResponse response,
) => switch (response.kind) {
  _lib_editor_v1_authoring.QueryAuthoringStateResponse_kind.stateWrapper =>
    ResponseOutcome.success,
  _lib_editor_v1_authoring
      .QueryAuthoringStateResponse_kind
      .catalogChangedErrorWrapper =>
    ResponseOutcome.domainError,
  // internal_error and the generated unknown variant
  _ => ResponseOutcome.internalError,
};

ResponseOutcome _commitPreparedEditOutcome(
  _lib_editor_v1_authoring.CommitPreparedEditResponse response,
) => switch (response.kind) {
  _lib_editor_v1_authoring.CommitPreparedEditResponse_kind.committedConst =>
    ResponseOutcome.success,
  _lib_editor_v1_authoring
      .CommitPreparedEditResponse_kind
      .conflictErrorWrapper ||
  _lib_editor_v1_authoring
      .CommitPreparedEditResponse_kind
      .rejectedErrorWrapper ||
  _lib_editor_v1_authoring
      .CommitPreparedEditResponse_kind
      .catalogChangedErrorWrapper => ResponseOutcome.domainError,
  // internal_error and the generated unknown variant
  _ => ResponseOutcome.internalError,
};

ResponseOutcome _previewTypeArgumentChangeOutcome(
  _lib_editor_v1_authoring.PreviewTypeArgumentChangeResponse response,
) => switch (response.kind) {
  _lib_editor_v1_authoring
      .PreviewTypeArgumentChangeResponse_kind
      .readyWrapper ||
  _lib_editor_v1_authoring
      .PreviewTypeArgumentChangeResponse_kind
      .incompleteWrapper => ResponseOutcome.success,
  _lib_editor_v1_authoring
      .PreviewTypeArgumentChangeResponse_kind
      .invalidArgumentsErrorWrapper ||
  _lib_editor_v1_authoring
      .PreviewTypeArgumentChangeResponse_kind
      .rejectedErrorWrapper => ResponseOutcome.domainError,
  // internal_error and the generated unknown variant
  _ => ResponseOutcome.internalError,
};

ResponseOutcome _prepareTypeArgumentChangeOutcome(
  _lib_editor_v1_authoring.PrepareTypeArgumentChangeResponse response,
) => switch (response.kind) {
  _lib_editor_v1_authoring
      .PrepareTypeArgumentChangeResponse_kind
      .preparedWrapper ||
  _lib_editor_v1_authoring
      .PrepareTypeArgumentChangeResponse_kind
      .needsInputWrapper => ResponseOutcome.success,
  _lib_editor_v1_authoring
      .PrepareTypeArgumentChangeResponse_kind
      .rejectedErrorWrapper =>
    ResponseOutcome.domainError,
  // internal_error and the generated unknown variant
  _ => ResponseOutcome.internalError,
};

ResponseOutcome _searchAuthoringOutcome(
  _lib_editor_v1_authoring.SearchAuthoringResponse response,
) => switch (response.kind) {
  _lib_editor_v1_authoring.SearchAuthoringResponse_kind.successWrapper =>
    ResponseOutcome.success,
  _lib_editor_v1_authoring.SearchAuthoringResponse_kind.invalidErrorWrapper ||
  _lib_editor_v1_authoring
      .SearchAuthoringResponse_kind
      .catalogChangedErrorWrapper => ResponseOutcome.domainError,
  // internal_error and the generated unknown variant
  _ => ResponseOutcome.internalError,
};

ResponseOutcome _queryPublishedContentOutcome(
  _lib_editor_v1_compiled_content.QueryPublishedContentResponse response,
) => switch (response.kind) {
  _lib_editor_v1_compiled_content
      .QueryPublishedContentResponse_kind
      .contentWrapper ||
  _lib_editor_v1_compiled_content
      .QueryPublishedContentResponse_kind
      .absentWrapper => ResponseOutcome.success,
  // internal_error and the generated unknown variant
  _ => ResponseOutcome.internalError,
};

ResponseOutcome _queryCompiledResourceStatusOutcome(
  _lib_editor_v1_compiled_content.QueryCompiledResourceStatusResponse response,
) => switch (response.kind) {
  _lib_editor_v1_compiled_content
      .QueryCompiledResourceStatusResponse_kind
      .successWrapper =>
    ResponseOutcome.success,
  // internal_error and the generated unknown variant
  _ => ResponseOutcome.internalError,
};

ResponseOutcome _publishAuthoringOutcome(
  _lib_editor_v1_publication.PublishAuthoringResponse response,
) => switch (response.kind) {
  _lib_editor_v1_publication.PublishAuthoringResponse_kind.publishingConst ||
  _lib_editor_v1_publication.PublishAuthoringResponse_kind.activatedWrapper ||
  _lib_editor_v1_publication.PublishAuthoringResponse_kind.noChangesConst =>
    ResponseOutcome.success,
  _lib_editor_v1_publication
      .PublishAuthoringResponse_kind
      .blockedErrorWrapper ||
  _lib_editor_v1_publication
      .PublishAuthoringResponse_kind
      .interruptedErrorWrapper ||
  _lib_editor_v1_publication
      .PublishAuthoringResponse_kind
      .candidateChangedErrorWrapper => ResponseOutcome.domainError,
  // internal_error and the generated unknown variant
  _ => ResponseOutcome.internalError,
};

ResponseOutcome _queryPublicationViewOutcome(
  _lib_editor_v1_publication.QueryPublicationViewResponse response,
) => switch (response.kind) {
  _lib_editor_v1_publication.QueryPublicationViewResponse_kind.viewWrapper =>
    ResponseOutcome.success,
  _lib_editor_v1_publication
      .QueryPublicationViewResponse_kind
      .viewChangedErrorWrapper =>
    ResponseOutcome.domainError,
  // internal_error and the generated unknown variant
  _ => ResponseOutcome.internalError,
};

ResponseOutcome _watchPublicationOutcome(
  _lib_editor_v1_publication.WatchPublicationResponse response,
) => switch (response.kind) {
  _lib_editor_v1_publication.WatchPublicationResponse_kind.viewChangedWrapper =>
    ResponseOutcome.success,
  // internal_error and the generated unknown variant
  _ => ResponseOutcome.internalError,
};

ResponseOutcome _fetchSharedArtifactCatalogOutcome(
  _lib_service_v1_artifact.FetchSharedArtifactCatalogResponse response,
) => switch (response.kind) {
  _lib_service_v1_artifact
      .FetchSharedArtifactCatalogResponse_kind
      .successWrapper =>
    ResponseOutcome.success,
  // internal_error and the generated unknown variant
  _ => ResponseOutcome.internalError,
};

ResponseOutcome _publishSharedArtifactOutcome(
  _lib_service_v1_artifact.PublishSharedArtifactResponse response,
) => switch (response.kind) {
  _lib_service_v1_artifact
      .PublishSharedArtifactResponse_kind
      .publishedWrapper ||
  _lib_service_v1_artifact
      .PublishSharedArtifactResponse_kind
      .unchangedWrapper => ResponseOutcome.success,
  _lib_service_v1_artifact
      .PublishSharedArtifactResponse_kind
      .conflictErrorWrapper =>
    ResponseOutcome.domainError,
  // internal_error and the generated unknown variant
  _ => ResponseOutcome.internalError,
};

ResponseOutcome _fetchArtifactBlobMetadataOutcome(
  _lib_service_v1_artifact.FetchArtifactBlobMetadataResponse response,
) => switch (response.kind) {
  _lib_service_v1_artifact
      .FetchArtifactBlobMetadataResponse_kind
      .successWrapper =>
    ResponseOutcome.success,
  _lib_service_v1_artifact
      .FetchArtifactBlobMetadataResponse_kind
      .notFoundErrorWrapper ||
  _lib_service_v1_artifact
      .FetchArtifactBlobMetadataResponse_kind
      .invalidErrorWrapper => ResponseOutcome.domainError,
  // internal_error and the generated unknown variant
  _ => ResponseOutcome.internalError,
};

ResponseOutcome _readArtifactBlobOutcome(
  _lib_service_v1_artifact.ReadArtifactBlobResponse response,
) => switch (response.kind) {
  _lib_service_v1_artifact.ReadArtifactBlobResponse_kind.successWrapper =>
    ResponseOutcome.success,
  _lib_service_v1_artifact.ReadArtifactBlobResponse_kind.notFoundErrorWrapper ||
  _lib_service_v1_artifact.ReadArtifactBlobResponse_kind.invalidErrorWrapper =>
    ResponseOutcome.domainError,
  // internal_error and the generated unknown variant
  _ => ResponseOutcome.internalError,
};

ResponseOutcome _beginArtifactBlobWriteOutcome(
  _lib_service_v1_artifact.BeginArtifactBlobWriteResponse response,
) => switch (response.kind) {
  _lib_service_v1_artifact
      .BeginArtifactBlobWriteResponse_kind
      .acceptedWrapper =>
    ResponseOutcome.success,
  _lib_service_v1_artifact
      .BeginArtifactBlobWriteResponse_kind
      .invalidErrorWrapper ||
  _lib_service_v1_artifact
      .BeginArtifactBlobWriteResponse_kind
      .conflictErrorWrapper => ResponseOutcome.domainError,
  // internal_error and the generated unknown variant
  _ => ResponseOutcome.internalError,
};

ResponseOutcome _writeArtifactBlobChunkOutcome(
  _lib_service_v1_artifact.WriteArtifactBlobChunkResponse response,
) => switch (response.kind) {
  _lib_service_v1_artifact
      .WriteArtifactBlobChunkResponse_kind
      .acceptedWrapper =>
    ResponseOutcome.success,
  _lib_service_v1_artifact
      .WriteArtifactBlobChunkResponse_kind
      .notFoundErrorWrapper ||
  _lib_service_v1_artifact
      .WriteArtifactBlobChunkResponse_kind
      .invalidErrorWrapper ||
  _lib_service_v1_artifact
      .WriteArtifactBlobChunkResponse_kind
      .conflictErrorWrapper => ResponseOutcome.domainError,
  // internal_error and the generated unknown variant
  _ => ResponseOutcome.internalError,
};

ResponseOutcome _completeArtifactBlobWriteOutcome(
  _lib_service_v1_artifact.CompleteArtifactBlobWriteResponse response,
) => switch (response.kind) {
  _lib_service_v1_artifact
      .CompleteArtifactBlobWriteResponse_kind
      .successWrapper =>
    ResponseOutcome.success,
  _lib_service_v1_artifact
      .CompleteArtifactBlobWriteResponse_kind
      .notFoundErrorWrapper ||
  _lib_service_v1_artifact
      .CompleteArtifactBlobWriteResponse_kind
      .invalidErrorWrapper ||
  _lib_service_v1_artifact
      .CompleteArtifactBlobWriteResponse_kind
      .conflictErrorWrapper => ResponseOutcome.domainError,
  // internal_error and the generated unknown variant
  _ => ResponseOutcome.internalError,
};

/// Reply framing limits of the transport route manifest: frame size and frames per reply.
const transportLimits = TransportLimits(chunkBytes: 524288, maxChunks: 64);

/// Names a connection's persistent projection consumer. The backend grants the same name.
String persistentConsumerName({
  required String actor,
  required String? organization,
  required String session,
  required String projection,
}) {
  final identity = jsonEncode([actor, organization, session, projection]);
  final encoded = base64Url.encode(utf8.encode(identity)).replaceAll("=", "");
  return "TW_$encoded";
}

/// The reply inbox prefix of a panel connection, `_INBOX.{user}.{session}`. Its reply inboxes are single
/// tokens below it, and the backend grants the connection exactly those.
String panelReplyInboxPrefix({required String user, required String session}) =>
    "_INBOX.${user.transportIdentity}.${session.transportSession}";
