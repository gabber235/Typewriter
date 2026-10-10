import "dart:convert";

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
    final user = userId._transportIdentity;

    final method = _lib_organization_v1_organization.createOrganizationMethod;
    return SkirRouteOperation(
      subject:
          "cloud" +
          "." +
          "to" +
          "." +
          "user" +
          "." +
          user +
          "." +
          "organization" +
          "." +
          "create",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
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
    final user = userId._transportIdentity;

    final method = _lib_organization_v1_user.watchUserOrganizationsMethod;
    return SkirRouteOperation(
      subject:
          "cloud" +
          "." +
          "to" +
          "." +
          "user" +
          "." +
          user +
          "." +
          "organization" +
          "." +
          "watch",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
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
    final user = userId._transportIdentity;

    final operation = this.operation(userId: userId);
    return ref.watchProjection<
      TData,
      _lib_organization_v1_user.WatchUserOrganizationsResponse,
      _lib_organization_v1_organization.UserOrganizationsChanged
    >(
      subject: operation.subject,
      eventSubject:
          "cloud" +
          "." +
          "from" +
          "." +
          "user" +
          "." +
          user +
          "." +
          "organizations" +
          "." +
          "changed",
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
    final user = userId._transportIdentity;

    final method = _lib_organization_v1_user.watchUserJoinRequestsMethod;
    return SkirRouteOperation(
      subject:
          "cloud" +
          "." +
          "to" +
          "." +
          "user" +
          "." +
          user +
          "." +
          "organization" +
          "." +
          "join_requests" +
          "." +
          "watch",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
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
    final user = userId._transportIdentity;

    final operation = this.operation(userId: userId);
    return ref.watchProjection<
      TData,
      _lib_organization_v1_user.WatchUserJoinRequestsResponse,
      _lib_organization_v1_join_request.UserJoinRequestsChanged
    >(
      subject: operation.subject,
      eventSubject:
          "cloud" +
          "." +
          "from" +
          "." +
          "user" +
          "." +
          user +
          "." +
          "join_requests" +
          "." +
          "changed",
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
    final user = userId._transportIdentity;

    final method = _lib_organization_v1_user.submitUserJoinRequestMethod;
    return SkirRouteOperation(
      subject:
          "cloud" +
          "." +
          "to" +
          "." +
          "user" +
          "." +
          user +
          "." +
          "organization" +
          "." +
          "join_requests" +
          "." +
          "request",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
    );
  }
}

extension UserJoinRequestCancelRouteNats
    on _lib_organization_v1_user.CancelUserJoinRequestRequest {
  SkirRouteOperation<_lib_organization_v1_user.CancelUserJoinRequestResponse>
  operation({required String userId}) {
    final user = userId._transportIdentity;

    final method = _lib_organization_v1_user.cancelUserJoinRequestMethod;
    return SkirRouteOperation(
      subject:
          "cloud" +
          "." +
          "to" +
          "." +
          "user" +
          "." +
          user +
          "." +
          "organization" +
          "." +
          "join_requests" +
          "." +
          "cancel",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
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
    final user = userId._transportIdentity;

    final organization = organizationId.id._transportIdentity;

    final method = _lib_organization_v1_member.watchOrganizationMembersMethod;
    return SkirRouteOperation(
      subject:
          "cloud" +
          "." +
          "to" +
          "." +
          "user" +
          "." +
          user +
          "." +
          "organization" +
          "." +
          organization +
          "." +
          "members" +
          "." +
          "watch",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
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
    final user = userId._transportIdentity;

    final organization = organizationId.id._transportIdentity;

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
      eventSubject:
          "cloud" +
          "." +
          "from" +
          "." +
          "organization" +
          "." +
          organization +
          "." +
          "members" +
          "." +
          "changed",
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
    final user = userId._transportIdentity;

    final organization = organizationId.id._transportIdentity;

    final method =
        _lib_organization_v1_member.updateOrganizationMemberRolesMethod;
    return SkirRouteOperation(
      subject:
          "cloud" +
          "." +
          "to" +
          "." +
          "user" +
          "." +
          user +
          "." +
          "organization" +
          "." +
          organization +
          "." +
          "members" +
          "." +
          "update",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
    );
  }
}

extension OrganizationMemberRemoveRouteNats
    on _lib_organization_v1_member.RemoveOrganizationMemberRequest {
  SkirRouteOperation<
    _lib_organization_v1_member.RemoveOrganizationMemberResponse
  >
  operation({required String userId, required _skir.RecordId organizationId}) {
    final user = userId._transportIdentity;

    final organization = organizationId.id._transportIdentity;

    final method = _lib_organization_v1_member.removeOrganizationMemberMethod;
    return SkirRouteOperation(
      subject:
          "cloud" +
          "." +
          "to" +
          "." +
          "user" +
          "." +
          user +
          "." +
          "organization" +
          "." +
          organization +
          "." +
          "members" +
          "." +
          "remove",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
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
    final user = userId._transportIdentity;

    final organization = organizationId.id._transportIdentity;

    final method =
        _lib_organization_v1_join_request.watchOrganizationJoinRequestsMethod;
    return SkirRouteOperation(
      subject:
          "cloud" +
          "." +
          "to" +
          "." +
          "user" +
          "." +
          user +
          "." +
          "organization" +
          "." +
          organization +
          "." +
          "members" +
          "." +
          "join_requests" +
          "." +
          "watch",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
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
    final user = userId._transportIdentity;

    final organization = organizationId.id._transportIdentity;

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
          "cloud" +
          "." +
          "from" +
          "." +
          "organization" +
          "." +
          organization +
          "." +
          "join_requests" +
          "." +
          "changed",
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
    final user = userId._transportIdentity;

    final organization = organizationId.id._transportIdentity;

    final method =
        _lib_organization_v1_join_request.approveOrganizationJoinRequestsMethod;
    return SkirRouteOperation(
      subject:
          "cloud" +
          "." +
          "to" +
          "." +
          "user" +
          "." +
          user +
          "." +
          "organization" +
          "." +
          organization +
          "." +
          "members" +
          "." +
          "join_requests" +
          "." +
          "approve",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
    );
  }
}

extension OrganizationJoinRequestDeclineRouteNats
    on _lib_organization_v1_join_request.DeclineOrganizationJoinRequestRequest {
  SkirRouteOperation<
    _lib_organization_v1_join_request.DeclineOrganizationJoinRequestResponse
  >
  operation({required String userId, required _skir.RecordId organizationId}) {
    final user = userId._transportIdentity;

    final organization = organizationId.id._transportIdentity;

    final method =
        _lib_organization_v1_join_request.declineOrganizationJoinRequestMethod;
    return SkirRouteOperation(
      subject:
          "cloud" +
          "." +
          "to" +
          "." +
          "user" +
          "." +
          user +
          "." +
          "organization" +
          "." +
          organization +
          "." +
          "members" +
          "." +
          "join_requests" +
          "." +
          "decline",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
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
    final user = userId._transportIdentity;

    final organization = organizationId.id._transportIdentity;

    final method =
        _lib_organization_v1_join_codes.watchOrganizationJoinCodesMethod;
    return SkirRouteOperation(
      subject:
          "cloud" +
          "." +
          "to" +
          "." +
          "user" +
          "." +
          user +
          "." +
          "organization" +
          "." +
          organization +
          "." +
          "members" +
          "." +
          "join_codes" +
          "." +
          "watch",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
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
    final user = userId._transportIdentity;

    final organization = organizationId.id._transportIdentity;

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
      eventSubject:
          "cloud" +
          "." +
          "from" +
          "." +
          "organization" +
          "." +
          organization +
          "." +
          "join_codes" +
          "." +
          "changed",
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
    final user = userId._transportIdentity;

    final organization = organizationId.id._transportIdentity;

    final method =
        _lib_organization_v1_join_codes.generateOrganizationJoinCodeMethod;
    return SkirRouteOperation(
      subject:
          "cloud" +
          "." +
          "to" +
          "." +
          "user" +
          "." +
          user +
          "." +
          "organization" +
          "." +
          organization +
          "." +
          "members" +
          "." +
          "join_codes" +
          "." +
          "generate",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
    );
  }
}

extension OrganizationJoinCodeRevokeRouteNats
    on _lib_organization_v1_join_codes.RevokeOrganizationJoinCodeRequest {
  SkirRouteOperation<
    _lib_organization_v1_join_codes.RevokeOrganizationJoinCodeResponse
  >
  operation({required String userId, required _skir.RecordId organizationId}) {
    final user = userId._transportIdentity;

    final organization = organizationId.id._transportIdentity;

    final method =
        _lib_organization_v1_join_codes.revokeOrganizationJoinCodeMethod;
    return SkirRouteOperation(
      subject:
          "cloud" +
          "." +
          "to" +
          "." +
          "user" +
          "." +
          user +
          "." +
          "organization" +
          "." +
          organization +
          "." +
          "members" +
          "." +
          "join_codes" +
          "." +
          "revoke",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
    );
  }
}

extension OrganizationRolesWatchRouteNats
    on _lib_organization_v1_role.WatchOrganizationRolesRequest {
  SkirRouteOperation<_lib_organization_v1_role.WatchOrganizationRolesResponse>
  operation({required String userId, required _skir.RecordId organizationId}) {
    final user = userId._transportIdentity;

    final organization = organizationId.id._transportIdentity;

    final method = _lib_organization_v1_role.watchOrganizationRolesMethod;
    return SkirRouteOperation(
      subject:
          "cloud" +
          "." +
          "to" +
          "." +
          "user" +
          "." +
          user +
          "." +
          "organization" +
          "." +
          organization +
          "." +
          "roles" +
          "." +
          "watch",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
    );
  }
}

extension ServiceBindRouteNats
    on _lib_service_v1_registration.BindServiceRequest {
  SkirRouteOperation<_lib_service_v1_registration.BindServiceResponse>
  operation({required String userId, required _skir.RecordId organizationId}) {
    final user = userId._transportIdentity;

    final organization = organizationId.id._transportIdentity;

    final method = _lib_service_v1_registration.bindServiceMethod;
    return SkirRouteOperation(
      subject:
          "cloud" +
          "." +
          "to" +
          "." +
          "user" +
          "." +
          user +
          "." +
          "organization" +
          "." +
          organization +
          "." +
          "services" +
          "." +
          "bind",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
    );
  }
}

extension OrganizationServicesWatchRouteNats
    on _lib_service_v1_organization.WatchOrganizationServicesRequest {
  SkirRouteOperation<
    _lib_service_v1_organization.WatchOrganizationServicesResponse
  >
  operation({required String userId, required _skir.RecordId organizationId}) {
    final user = userId._transportIdentity;

    final organization = organizationId.id._transportIdentity;

    final method = _lib_service_v1_organization.watchOrganizationServicesMethod;
    return SkirRouteOperation(
      subject:
          "cloud" +
          "." +
          "to" +
          "." +
          "user" +
          "." +
          user +
          "." +
          "organization" +
          "." +
          organization +
          "." +
          "services" +
          "." +
          "watch",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
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
    final user = userId._transportIdentity;

    final organization = organizationId.id._transportIdentity;

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
      eventSubject:
          "cloud" +
          "." +
          "from" +
          "." +
          "organization" +
          "." +
          organization +
          "." +
          "services" +
          "." +
          "watch",
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
    final user = userId._transportIdentity;

    final organization = organizationId.id._transportIdentity;

    final method = _lib_service_v1_organization.updateOrganizationServiceMethod;
    return SkirRouteOperation(
      subject:
          "cloud" +
          "." +
          "to" +
          "." +
          "user" +
          "." +
          user +
          "." +
          "organization" +
          "." +
          organization +
          "." +
          "services" +
          "." +
          "update",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
    );
  }
}

extension ServiceUnbindRouteNats
    on _lib_service_v1_registration.UnbindServiceRequest {
  SkirRouteOperation<_lib_service_v1_registration.UnbindServiceResponse>
  operation({required String userId, required _skir.RecordId organizationId}) {
    final user = userId._transportIdentity;

    final organization = organizationId.id._transportIdentity;

    final method = _lib_service_v1_registration.unbindServiceMethod;
    return SkirRouteOperation(
      subject:
          "cloud" +
          "." +
          "to" +
          "." +
          "user" +
          "." +
          user +
          "." +
          "organization" +
          "." +
          organization +
          "." +
          "services" +
          "." +
          "unbind",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
    );
  }
}

extension ServiceTopologyConfigureRouteNats
    on _lib_service_v1_topology.ConfigureServiceHostRequest {
  SkirRouteOperation<_lib_service_v1_topology.ConfigureServiceHostResponse>
  operation({required String userId, required _skir.RecordId organizationId}) {
    final user = userId._transportIdentity;

    final organization = organizationId.id._transportIdentity;

    final method = _lib_service_v1_topology.configureServiceHostMethod;
    return SkirRouteOperation(
      subject:
          "cloud" +
          "." +
          "to" +
          "." +
          "user" +
          "." +
          user +
          "." +
          "organization" +
          "." +
          organization +
          "." +
          "topology" +
          "." +
          "configure",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
    );
  }
}

extension OrganizationTopologyWatchRouteNats
    on _lib_service_v1_topology.WatchOrganizationTopologyRequest {
  SkirRouteOperation<_lib_service_v1_topology.WatchOrganizationTopologyResponse>
  operation({required String userId, required _skir.RecordId organizationId}) {
    final user = userId._transportIdentity;

    final organization = organizationId.id._transportIdentity;

    final method = _lib_service_v1_topology.watchOrganizationTopologyMethod;
    return SkirRouteOperation(
      subject:
          "cloud" +
          "." +
          "to" +
          "." +
          "user" +
          "." +
          user +
          "." +
          "organization" +
          "." +
          organization +
          "." +
          "topology" +
          "." +
          "watch",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
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
    final user = userId._transportIdentity;

    final organization = organizationId.id._transportIdentity;

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
      eventSubject:
          "cloud" +
          "." +
          "from" +
          "." +
          "organization" +
          "." +
          organization +
          "." +
          "topology" +
          "." +
          "watch",
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
  Stream<_lib_editor_v1_catalog.CatalogFetchResult> watch(
    SkirMutationClient transport, {
    required _skir.RecordId organizationId,

    required _skir.RecordId realmId,
  }) {
    final organization = organizationId.id._transportIdentity;

    final realm = realmId.id._transportIdentity;

    final method = _lib_editor_v1_catalog.fetchEditorCatalogMethod;
    return transport.watchRequest(
      "service" +
          "." +
          "to" +
          "." +
          realm +
          "." +
          "organization" +
          "." +
          organization +
          "." +
          "realm" +
          "." +
          "editor" +
          "." +
          "catalog" +
          "." +
          "fetch",
      "service" +
          "." +
          "from" +
          "." +
          realm +
          "." +
          "organization" +
          "." +
          organization +
          "." +
          "realm" +
          "." +
          "editor" +
          "." +
          "catalog" +
          "." +
          "fetch" +
          "." +
          this.transferId._transportTransfer,
      method.requestSerializer.toBytes(this),
      method.responseSerializer,
    );
  }
}

extension EditorCatalogWatchRouteNats
    on _lib_editor_v1_catalog.WatchEditorCatalogRequest {
  SkirRouteOperation<_lib_editor_v1_catalog.CatalogInvalidated> operation({
    required _skir.RecordId organizationId,

    required _skir.RecordId realmId,
  }) {
    final organization = organizationId.id._transportIdentity;

    final realm = realmId.id._transportIdentity;

    final method = _lib_editor_v1_catalog.watchEditorCatalogMethod;
    return SkirRouteOperation(
      subject:
          "service" +
          "." +
          "to" +
          "." +
          realm +
          "." +
          "organization" +
          "." +
          organization +
          "." +
          "realm" +
          "." +
          "editor" +
          "." +
          "catalog" +
          "." +
          "invalidate",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
    );
  }

  Stream<TData> watch<TData>(
    Ref ref, {
    required _skir.RecordId organizationId,

    required _skir.RecordId realmId,

    required TData Function(_lib_editor_v1_catalog.CatalogInvalidated) snapshot,
    required TData Function(TData, _lib_editor_v1_catalog.CatalogInvalidated)
    reduce,
    required ProjectionReconciliation<
      TData,
      _lib_editor_v1_catalog.CatalogInvalidated,
      _lib_editor_v1_catalog.CatalogInvalidated
    >
    reconciliation,
    Stream<_lib_editor_v1_catalog.CatalogInvalidated>? confirmedEvents,
    TData Function(TData, _lib_editor_v1_catalog.CatalogInvalidated)?
    reduceConfirmed,
    TData Function(TData, TData)? reconcileSnapshot,
    TData? initialValue,
  }) {
    final organization = organizationId.id._transportIdentity;

    final realm = realmId.id._transportIdentity;

    final operation = this.operation(
      organizationId: organizationId,

      realmId: realmId,
    );
    return ref.watchProjection<
      TData,
      _lib_editor_v1_catalog.CatalogInvalidated,
      _lib_editor_v1_catalog.CatalogInvalidated
    >(
      subject: operation.subject,
      eventSubject:
          "service" +
          "." +
          "from" +
          "." +
          realm +
          "." +
          "organization" +
          "." +
          organization +
          "." +
          "realm" +
          "." +
          "editor" +
          "." +
          "catalog" +
          "." +
          "invalidate",
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
    on _lib_editor_v1_catalog.ValuePreparationRequest {
  SkirRouteOperation<_lib_editor_v1_catalog.PrepareValueResult> operation({
    required _skir.RecordId organizationId,

    required _skir.RecordId realmId,
  }) {
    final organization = organizationId.id._transportIdentity;

    final realm = realmId.id._transportIdentity;

    final method = _lib_editor_v1_catalog.prepareValueMethod;
    return SkirRouteOperation(
      subject:
          "service" +
          "." +
          "to" +
          "." +
          realm +
          "." +
          "organization" +
          "." +
          organization +
          "." +
          "realm" +
          "." +
          "editor" +
          "." +
          "creation" +
          "." +
          "prepare",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
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
    final organization = organizationId.id._transportIdentity;

    final realm = realmId.id._transportIdentity;

    final method = _lib_editor_v1_search.watchRealmPresentationSearchMethod;
    return SkirRouteOperation(
      subject:
          "service" +
          "." +
          "to" +
          "." +
          realm +
          "." +
          "organization" +
          "." +
          organization +
          "." +
          "realm" +
          "." +
          "editor" +
          "." +
          "presentation" +
          "." +
          "search",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
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
    final organization = organizationId.id._transportIdentity;

    final realm = realmId.id._transportIdentity;

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
          "service" +
          "." +
          "from" +
          "." +
          realm +
          "." +
          "organization" +
          "." +
          organization +
          "." +
          "realm" +
          "." +
          "editor" +
          "." +
          "presentation" +
          "." +
          "search",
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
    final organization = organizationId.id._transportIdentity;

    final realm = realmId.id._transportIdentity;

    final method = _lib_editor_v1_search.cancelRealmPresentationSearchMethod;
    return SkirRouteOperation(
      subject:
          "service" +
          "." +
          "to" +
          "." +
          realm +
          "." +
          "organization" +
          "." +
          organization +
          "." +
          "realm" +
          "." +
          "editor" +
          "." +
          "presentation" +
          "." +
          "search" +
          "." +
          "cancel",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
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
    final organization = organizationId.id._transportIdentity;

    final realm = realmId.id._transportIdentity;

    final method = _lib_editor_v1_capability.invokeRealmComputationMethod;
    return SkirRouteOperation(
      subject:
          "service" +
          "." +
          "to" +
          "." +
          realm +
          "." +
          "organization" +
          "." +
          organization +
          "." +
          "realm" +
          "." +
          "editor" +
          "." +
          "capability" +
          "." +
          "computation" +
          "." +
          "invoke",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
    );
  }
}

extension EditorCapabilityCommandInvokeRouteNats
    on _lib_editor_v1_capability.CapabilityInvocationRequest {
  SkirRouteOperation<_lib_editor_v1_capability.CommandResult> commandOperation({
    required _skir.RecordId organizationId,

    required _skir.RecordId realmId,
  }) {
    final organization = organizationId.id._transportIdentity;

    final realm = realmId.id._transportIdentity;

    final method = _lib_editor_v1_capability.invokeRealmCommandMethod;
    return SkirRouteOperation(
      subject:
          "service" +
          "." +
          "to" +
          "." +
          realm +
          "." +
          "organization" +
          "." +
          organization +
          "." +
          "realm" +
          "." +
          "editor" +
          "." +
          "capability" +
          "." +
          "command" +
          "." +
          "invoke",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
    );
  }
}

extension AuthoringStateQueryRouteNats
    on _lib_editor_v1_authoring.QueryAuthoringStateRequest {
  Stream<_lib_editor_v1_authoring.QueryAuthoringStateResponse> watch(
    SkirMutationClient transport, {
    required _skir.RecordId organizationId,

    required _skir.RecordId realmId,
  }) {
    final organization = organizationId.id._transportIdentity;

    final realm = realmId.id._transportIdentity;

    final method = _lib_editor_v1_authoring.queryAuthoringStateMethod;
    return transport.watchRequest(
      "service" +
          "." +
          "to" +
          "." +
          realm +
          "." +
          "organization" +
          "." +
          organization +
          "." +
          "realm" +
          "." +
          "editor" +
          "." +
          "authoring" +
          "." +
          "state" +
          "." +
          "query",
      "service" +
          "." +
          "from" +
          "." +
          realm +
          "." +
          "organization" +
          "." +
          organization +
          "." +
          "realm" +
          "." +
          "editor" +
          "." +
          "authoring" +
          "." +
          "state" +
          "." +
          "query" +
          "." +
          this.transferId._transportTransfer,
      method.requestSerializer.toBytes(this),
      method.responseSerializer,
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
    final organization = organizationId.id._transportIdentity;

    final realm = realmId.id._transportIdentity;

    final method = _lib_editor_v1_authoring.commitPreparedEditMethod;
    return SkirRouteOperation(
      subject:
          "service" +
          "." +
          "to" +
          "." +
          realm +
          "." +
          "organization" +
          "." +
          organization +
          "." +
          "realm" +
          "." +
          "editor" +
          "." +
          "authoring" +
          "." +
          "edit" +
          "." +
          "commit",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
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
    final organization = organizationId.id._transportIdentity;

    final realm = realmId.id._transportIdentity;

    final method = _lib_editor_v1_authoring.previewTypeArgumentChangeMethod;
    return SkirRouteOperation(
      subject:
          "service" +
          "." +
          "to" +
          "." +
          realm +
          "." +
          "organization" +
          "." +
          organization +
          "." +
          "realm" +
          "." +
          "editor" +
          "." +
          "authoring" +
          "." +
          "type" +
          "." +
          "preview",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
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
    final organization = organizationId.id._transportIdentity;

    final realm = realmId.id._transportIdentity;

    final method = _lib_editor_v1_authoring.prepareTypeArgumentChangeMethod;
    return SkirRouteOperation(
      subject:
          "service" +
          "." +
          "to" +
          "." +
          realm +
          "." +
          "organization" +
          "." +
          organization +
          "." +
          "realm" +
          "." +
          "editor" +
          "." +
          "authoring" +
          "." +
          "type" +
          "." +
          "commit",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
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
    final organization = organizationId.id._transportIdentity;

    final realm = realmId.id._transportIdentity;

    final method = _lib_editor_v1_authoring.searchAuthoringMethod;
    return SkirRouteOperation(
      subject:
          "service" +
          "." +
          "to" +
          "." +
          realm +
          "." +
          "organization" +
          "." +
          organization +
          "." +
          "realm" +
          "." +
          "editor" +
          "." +
          "authoring" +
          "." +
          "search",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
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
    final organization = organizationId.id._transportIdentity;

    final realm = realmId.id._transportIdentity;

    return "service" +
        "." +
        "from" +
        "." +
        realm +
        "." +
        "organization" +
        "." +
        organization +
        "." +
        "realm" +
        "." +
        "editor" +
        "." +
        "authoring" +
        "." +
        "changed";
  }
}

extension AuthoringCompiledQueryRouteNats
    on _lib_editor_v1_compiled_content.QueryPublishedContentRequest {
  Stream<_lib_editor_v1_compiled_content.QueryPublishedContentResponse> watch(
    SkirMutationClient transport, {
    required _skir.RecordId organizationId,

    required _skir.RecordId realmId,
  }) {
    final organization = organizationId.id._transportIdentity;

    final realm = realmId.id._transportIdentity;

    final method = _lib_editor_v1_compiled_content.queryPublishedContentMethod;
    return transport.watchRequest(
      "service" +
          "." +
          "to" +
          "." +
          realm +
          "." +
          "organization" +
          "." +
          organization +
          "." +
          "realm" +
          "." +
          "editor" +
          "." +
          "authoring" +
          "." +
          "compiled" +
          "." +
          "query",
      "service" +
          "." +
          "from" +
          "." +
          realm +
          "." +
          "organization" +
          "." +
          organization +
          "." +
          "realm" +
          "." +
          "editor" +
          "." +
          "authoring" +
          "." +
          "compiled" +
          "." +
          "query" +
          "." +
          this.transferId._transportTransfer,
      method.requestSerializer.toBytes(this),
      method.responseSerializer,
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
    final organization = organizationId.id._transportIdentity;

    final realm = realmId.id._transportIdentity;

    return "service" +
        "." +
        "from" +
        "." +
        realm +
        "." +
        "organization" +
        "." +
        organization +
        "." +
        "realm" +
        "." +
        "editor" +
        "." +
        "authoring" +
        "." +
        "compiled" +
        "." +
        "changed";
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
    final organization = organizationId.id._transportIdentity;

    final realm = realmId.id._transportIdentity;

    final method =
        _lib_editor_v1_compiled_content.queryCompiledResourceStatusMethod;
    return SkirRouteOperation(
      subject:
          "service" +
          "." +
          "to" +
          "." +
          realm +
          "." +
          "organization" +
          "." +
          organization +
          "." +
          "realm" +
          "." +
          "editor" +
          "." +
          "authoring" +
          "." +
          "compiled" +
          "." +
          "status" +
          "." +
          "query",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
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
    final organization = organizationId.id._transportIdentity;

    final realm = realmId.id._transportIdentity;

    final method = _lib_editor_v1_publication.publishAuthoringMethod;
    return SkirRouteOperation(
      subject:
          "service" +
          "." +
          "to" +
          "." +
          realm +
          "." +
          "organization" +
          "." +
          organization +
          "." +
          "realm" +
          "." +
          "editor" +
          "." +
          "authoring" +
          "." +
          "publish",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
    );
  }
}

extension AuthoringPublicationWatchRouteNats
    on _lib_editor_v1_publication.WatchPublicationRequest {
  SkirRouteOperation<_lib_editor_v1_publication.PublicationReport> operation({
    required _skir.RecordId organizationId,

    required _skir.RecordId realmId,
  }) {
    final organization = organizationId.id._transportIdentity;

    final realm = realmId.id._transportIdentity;

    final method = _lib_editor_v1_publication.watchPublicationMethod;
    return SkirRouteOperation(
      subject:
          "service" +
          "." +
          "to" +
          "." +
          realm +
          "." +
          "organization" +
          "." +
          organization +
          "." +
          "realm" +
          "." +
          "editor" +
          "." +
          "authoring" +
          "." +
          "publication" +
          "." +
          "watch",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
    );
  }

  Stream<TData> watch<TData>(
    Ref ref, {
    required _skir.RecordId organizationId,

    required _skir.RecordId realmId,

    required TData Function(_lib_editor_v1_publication.PublicationReport)
    snapshot,
    required TData Function(TData, _lib_editor_v1_publication.PublicationReport)
    reduce,
    required ProjectionReconciliation<
      TData,
      _lib_editor_v1_publication.PublicationReport,
      _lib_editor_v1_publication.PublicationReport
    >
    reconciliation,
    Stream<_lib_editor_v1_publication.PublicationReport>? confirmedEvents,
    TData Function(TData, _lib_editor_v1_publication.PublicationReport)?
    reduceConfirmed,
    TData Function(TData, TData)? reconcileSnapshot,
    TData? initialValue,
  }) {
    final organization = organizationId.id._transportIdentity;

    final realm = realmId.id._transportIdentity;

    final operation = this.operation(
      organizationId: organizationId,

      realmId: realmId,
    );
    return ref.watchProjection<
      TData,
      _lib_editor_v1_publication.PublicationReport,
      _lib_editor_v1_publication.PublicationReport
    >(
      subject: operation.subject,
      eventSubject:
          "service" +
          "." +
          "from" +
          "." +
          realm +
          "." +
          "organization" +
          "." +
          organization +
          "." +
          "realm" +
          "." +
          "editor" +
          "." +
          "authoring" +
          "." +
          "publication" +
          "." +
          "watch",
      requestBytes: operation.requestBytes,
      responseSerializer: operation.responseSerializer,
      eventSerializer: _lib_editor_v1_publication.PublicationReport.serializer,
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
    final organization = organizationId.id._transportIdentity;

    final realm = realmId.id._transportIdentity;

    final method = _lib_service_v1_artifact.fetchSharedArtifactCatalogMethod;
    return SkirRouteOperation(
      subject:
          "service" +
          "." +
          "to" +
          "." +
          realm +
          "." +
          "organization" +
          "." +
          organization +
          "." +
          "realm" +
          "." +
          "shared" +
          "." +
          "catalog" +
          "." +
          "fetch",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
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
    final organization = organizationId.id._transportIdentity;

    final realm = realmId.id._transportIdentity;

    final method = _lib_service_v1_artifact.publishSharedArtifactMethod;
    return SkirRouteOperation(
      subject:
          "service" +
          "." +
          "to" +
          "." +
          realm +
          "." +
          "organization" +
          "." +
          organization +
          "." +
          "realm" +
          "." +
          "shared" +
          "." +
          "publish",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
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
    final organization = organizationId.id._transportIdentity;

    final realm = realmId.id._transportIdentity;

    final method = _lib_service_v1_artifact.fetchArtifactBlobMetadataMethod;
    return SkirRouteOperation(
      subject:
          "service" +
          "." +
          "to" +
          "." +
          realm +
          "." +
          "organization" +
          "." +
          organization +
          "." +
          "realm" +
          "." +
          "shared" +
          "." +
          "blob" +
          "." +
          "metadata",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
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
    final organization = organizationId.id._transportIdentity;

    final realm = realmId.id._transportIdentity;

    final method = _lib_service_v1_artifact.readArtifactBlobMethod;
    return SkirRouteOperation(
      subject:
          "service" +
          "." +
          "to" +
          "." +
          realm +
          "." +
          "organization" +
          "." +
          organization +
          "." +
          "realm" +
          "." +
          "shared" +
          "." +
          "blob" +
          "." +
          "read",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
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
    final organization = organizationId.id._transportIdentity;

    final realm = realmId.id._transportIdentity;

    final method = _lib_service_v1_artifact.beginArtifactBlobWriteMethod;
    return SkirRouteOperation(
      subject:
          "service" +
          "." +
          "to" +
          "." +
          realm +
          "." +
          "organization" +
          "." +
          organization +
          "." +
          "realm" +
          "." +
          "shared" +
          "." +
          "blob" +
          "." +
          "begin",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
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
    final organization = organizationId.id._transportIdentity;

    final realm = realmId.id._transportIdentity;

    final method = _lib_service_v1_artifact.writeArtifactBlobChunkMethod;
    return SkirRouteOperation(
      subject:
          "service" +
          "." +
          "to" +
          "." +
          realm +
          "." +
          "organization" +
          "." +
          organization +
          "." +
          "realm" +
          "." +
          "shared" +
          "." +
          "blob" +
          "." +
          "write",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
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
    final organization = organizationId.id._transportIdentity;

    final realm = realmId.id._transportIdentity;

    final method = _lib_service_v1_artifact.completeArtifactBlobWriteMethod;
    return SkirRouteOperation(
      subject:
          "service" +
          "." +
          "to" +
          "." +
          realm +
          "." +
          "organization" +
          "." +
          organization +
          "." +
          "realm" +
          "." +
          "shared" +
          "." +
          "blob" +
          "." +
          "complete",
      requestBytes: method.requestSerializer.toBytes(this),
      responseSerializer: method.responseSerializer,
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
    final user = userId._transportIdentity;

    final organization = organizationId.id._transportIdentity;

    return "typewriter" +
        "." +
        "presence" +
        "." +
        "organization" +
        "." +
        organization +
        "." +
        "user" +
        "." +
        user;
  }

  static String subscriptionPattern({required _skir.RecordId organizationId}) {
    final organization = organizationId.id._transportIdentity;
    return "typewriter" +
        "." +
        "presence" +
        "." +
        "organization" +
        "." +
        organization +
        "." +
        "user" +
        "." +
        "*";
  }

  static String? userIdFromSubject(
    String subject, {
    required _skir.RecordId organizationId,
  }) {
    final organization = organizationId.id._transportIdentity;
    final parts = subject.split(".");
    if (parts.length != 6 ||
        parts[0] != "typewriter" ||
        parts[1] != "presence" ||
        parts[2] != "organization" ||
        parts[3] != organization ||
        parts[4] != "user")
      return null;
    final userId = parts[5];
    return userId._isTransportIdentity ? userId : null;
  }
}

final class TransportPermissionGrant {
  TransportPermissionGrant({
    required Set<String> publish,
    required Set<String> subscribe,
  }) : publish = Set.unmodifiable(publish),
       subscribe = Set.unmodifiable(subscribe);
  final Set<String> publish;
  final Set<String> subscribe;
}

TransportPermissionGrant panelTransportPermissions({
  required String actorId,
  required _skir.RecordId? organizationId,
  required String connectionSession,
  required Iterable<_skir.RecordId> realmIds,
}) {
  final user = actorId._transportIdentity;
  final session = connectionSession._transportSession;
  final publish = <String>{"\$SYS.REQ.USER.INFO"};
  final subscribe = <String>{"_INBOX.$user.$session.*"};
  publish.add(
    "cloud" +
        "." +
        "to" +
        "." +
        "user" +
        "." +
        user +
        "." +
        "organization" +
        "." +
        "create",
  );

  publish.add(
    "cloud" +
        "." +
        "to" +
        "." +
        "user" +
        "." +
        user +
        "." +
        "organization" +
        "." +
        "watch",
  );

  subscribe.add(
    "cloud" +
        "." +
        "from" +
        "." +
        "user" +
        "." +
        user +
        "." +
        "organizations" +
        "." +
        "changed",
  );

  _grantPersistentProjection(
    publish,
    stream: "TYPEWRITER_MEMBERSHIP",
    consumer: _persistentConsumerName(
      actor: user,
      organization: null,
      session: session,
      projection: "user_organizations_changed",
    ),
    filter:
        "cloud" +
        "." +
        "from" +
        "." +
        "user" +
        "." +
        user +
        "." +
        "organizations" +
        "." +
        "changed",
  );

  publish.add(
    "cloud" +
        "." +
        "to" +
        "." +
        "user" +
        "." +
        user +
        "." +
        "organization" +
        "." +
        "join_requests" +
        "." +
        "watch",
  );

  subscribe.add(
    "cloud" +
        "." +
        "from" +
        "." +
        "user" +
        "." +
        user +
        "." +
        "join_requests" +
        "." +
        "changed",
  );

  _grantPersistentProjection(
    publish,
    stream: "TYPEWRITER_MEMBERSHIP",
    consumer: _persistentConsumerName(
      actor: user,
      organization: null,
      session: session,
      projection: "user_join_requests_changed",
    ),
    filter:
        "cloud" +
        "." +
        "from" +
        "." +
        "user" +
        "." +
        user +
        "." +
        "join_requests" +
        "." +
        "changed",
  );

  publish.add(
    "cloud" +
        "." +
        "to" +
        "." +
        "user" +
        "." +
        user +
        "." +
        "organization" +
        "." +
        "join_requests" +
        "." +
        "request",
  );

  publish.add(
    "cloud" +
        "." +
        "to" +
        "." +
        "user" +
        "." +
        user +
        "." +
        "organization" +
        "." +
        "join_requests" +
        "." +
        "cancel",
  );

  final organization = organizationId?.id._transportIdentity;
  final realms = realmIds.map((value) => value.id._transportIdentity).toSet();
  if (organizationId != null || realms.isNotEmpty) {
    if (organization == null)
      throw StateError("Realm permissions require an admitted organization");
    publish.add(
      "cloud" +
          "." +
          "to" +
          "." +
          "user" +
          "." +
          user +
          "." +
          "organization" +
          "." +
          organization +
          "." +
          "members" +
          "." +
          "watch",
    );

    subscribe.add(
      "cloud" +
          "." +
          "from" +
          "." +
          "organization" +
          "." +
          organization +
          "." +
          "members" +
          "." +
          "changed",
    );

    _grantPersistentProjection(
      publish,
      stream: "TYPEWRITER_MEMBERSHIP",
      consumer: _persistentConsumerName(
        actor: user,
        organization: organization,
        session: session,
        projection: "organization_members_changed",
      ),
      filter:
          "cloud" +
          "." +
          "from" +
          "." +
          "organization" +
          "." +
          organization +
          "." +
          "members" +
          "." +
          "changed",
    );

    publish.add(
      "cloud" +
          "." +
          "to" +
          "." +
          "user" +
          "." +
          user +
          "." +
          "organization" +
          "." +
          organization +
          "." +
          "members" +
          "." +
          "update",
    );

    publish.add(
      "cloud" +
          "." +
          "to" +
          "." +
          "user" +
          "." +
          user +
          "." +
          "organization" +
          "." +
          organization +
          "." +
          "members" +
          "." +
          "remove",
    );

    publish.add(
      "cloud" +
          "." +
          "to" +
          "." +
          "user" +
          "." +
          user +
          "." +
          "organization" +
          "." +
          organization +
          "." +
          "members" +
          "." +
          "join_requests" +
          "." +
          "watch",
    );

    subscribe.add(
      "cloud" +
          "." +
          "from" +
          "." +
          "organization" +
          "." +
          organization +
          "." +
          "join_requests" +
          "." +
          "changed",
    );

    _grantPersistentProjection(
      publish,
      stream: "TYPEWRITER_MEMBERSHIP",
      consumer: _persistentConsumerName(
        actor: user,
        organization: organization,
        session: session,
        projection: "organization_join_requests_changed",
      ),
      filter:
          "cloud" +
          "." +
          "from" +
          "." +
          "organization" +
          "." +
          organization +
          "." +
          "join_requests" +
          "." +
          "changed",
    );

    publish.add(
      "cloud" +
          "." +
          "to" +
          "." +
          "user" +
          "." +
          user +
          "." +
          "organization" +
          "." +
          organization +
          "." +
          "members" +
          "." +
          "join_requests" +
          "." +
          "approve",
    );

    publish.add(
      "cloud" +
          "." +
          "to" +
          "." +
          "user" +
          "." +
          user +
          "." +
          "organization" +
          "." +
          organization +
          "." +
          "members" +
          "." +
          "join_requests" +
          "." +
          "decline",
    );

    publish.add(
      "cloud" +
          "." +
          "to" +
          "." +
          "user" +
          "." +
          user +
          "." +
          "organization" +
          "." +
          organization +
          "." +
          "members" +
          "." +
          "join_codes" +
          "." +
          "watch",
    );

    subscribe.add(
      "cloud" +
          "." +
          "from" +
          "." +
          "organization" +
          "." +
          organization +
          "." +
          "join_codes" +
          "." +
          "changed",
    );

    _grantPersistentProjection(
      publish,
      stream: "TYPEWRITER_MEMBERSHIP",
      consumer: _persistentConsumerName(
        actor: user,
        organization: organization,
        session: session,
        projection: "organization_join_codes_changed",
      ),
      filter:
          "cloud" +
          "." +
          "from" +
          "." +
          "organization" +
          "." +
          organization +
          "." +
          "join_codes" +
          "." +
          "changed",
    );

    publish.add(
      "cloud" +
          "." +
          "to" +
          "." +
          "user" +
          "." +
          user +
          "." +
          "organization" +
          "." +
          organization +
          "." +
          "members" +
          "." +
          "join_codes" +
          "." +
          "generate",
    );

    publish.add(
      "cloud" +
          "." +
          "to" +
          "." +
          "user" +
          "." +
          user +
          "." +
          "organization" +
          "." +
          organization +
          "." +
          "members" +
          "." +
          "join_codes" +
          "." +
          "revoke",
    );

    publish.add(
      "cloud" +
          "." +
          "to" +
          "." +
          "user" +
          "." +
          user +
          "." +
          "organization" +
          "." +
          organization +
          "." +
          "roles" +
          "." +
          "watch",
    );

    publish.add(
      "cloud" +
          "." +
          "to" +
          "." +
          "user" +
          "." +
          user +
          "." +
          "organization" +
          "." +
          organization +
          "." +
          "services" +
          "." +
          "bind",
    );

    publish.add(
      "cloud" +
          "." +
          "to" +
          "." +
          "user" +
          "." +
          user +
          "." +
          "organization" +
          "." +
          organization +
          "." +
          "services" +
          "." +
          "watch",
    );

    subscribe.add(
      "cloud" +
          "." +
          "from" +
          "." +
          "organization" +
          "." +
          organization +
          "." +
          "services" +
          "." +
          "watch",
    );

    publish.add(
      "cloud" +
          "." +
          "to" +
          "." +
          "user" +
          "." +
          user +
          "." +
          "organization" +
          "." +
          organization +
          "." +
          "services" +
          "." +
          "update",
    );

    publish.add(
      "cloud" +
          "." +
          "to" +
          "." +
          "user" +
          "." +
          user +
          "." +
          "organization" +
          "." +
          organization +
          "." +
          "services" +
          "." +
          "unbind",
    );

    publish.add(
      "cloud" +
          "." +
          "to" +
          "." +
          "user" +
          "." +
          user +
          "." +
          "organization" +
          "." +
          organization +
          "." +
          "topology" +
          "." +
          "configure",
    );

    publish.add(
      "cloud" +
          "." +
          "to" +
          "." +
          "user" +
          "." +
          user +
          "." +
          "organization" +
          "." +
          organization +
          "." +
          "topology" +
          "." +
          "watch",
    );

    subscribe.add(
      "cloud" +
          "." +
          "from" +
          "." +
          "organization" +
          "." +
          organization +
          "." +
          "topology" +
          "." +
          "watch",
    );

    publish.add(
      "typewriter" +
          "." +
          "presence" +
          "." +
          "organization" +
          "." +
          organization +
          "." +
          "user" +
          "." +
          user,
    );

    subscribe.add(
      "typewriter" +
          "." +
          "presence" +
          "." +
          "organization" +
          "." +
          organization +
          "." +
          "user" +
          "." +
          "*",
    );

    for (final realm in realms) {
      publish.add(
        "service" +
            "." +
            "to" +
            "." +
            realm +
            "." +
            "organization" +
            "." +
            organization +
            "." +
            "realm" +
            "." +
            "editor" +
            "." +
            "catalog" +
            "." +
            "fetch",
      );

      subscribe.add(
        "service" +
            "." +
            "from" +
            "." +
            realm +
            "." +
            "organization" +
            "." +
            organization +
            "." +
            "realm" +
            "." +
            "editor" +
            "." +
            "catalog" +
            "." +
            "fetch" +
            "." +
            "*",
      );

      publish.add(
        "service" +
            "." +
            "to" +
            "." +
            realm +
            "." +
            "organization" +
            "." +
            organization +
            "." +
            "realm" +
            "." +
            "editor" +
            "." +
            "catalog" +
            "." +
            "invalidate",
      );

      subscribe.add(
        "service" +
            "." +
            "from" +
            "." +
            realm +
            "." +
            "organization" +
            "." +
            organization +
            "." +
            "realm" +
            "." +
            "editor" +
            "." +
            "catalog" +
            "." +
            "invalidate",
      );

      publish.add(
        "service" +
            "." +
            "to" +
            "." +
            realm +
            "." +
            "organization" +
            "." +
            organization +
            "." +
            "realm" +
            "." +
            "editor" +
            "." +
            "creation" +
            "." +
            "prepare",
      );

      publish.add(
        "service" +
            "." +
            "to" +
            "." +
            realm +
            "." +
            "organization" +
            "." +
            organization +
            "." +
            "realm" +
            "." +
            "editor" +
            "." +
            "presentation" +
            "." +
            "search",
      );

      subscribe.add(
        "service" +
            "." +
            "from" +
            "." +
            realm +
            "." +
            "organization" +
            "." +
            organization +
            "." +
            "realm" +
            "." +
            "editor" +
            "." +
            "presentation" +
            "." +
            "search",
      );

      publish.add(
        "service" +
            "." +
            "to" +
            "." +
            realm +
            "." +
            "organization" +
            "." +
            organization +
            "." +
            "realm" +
            "." +
            "editor" +
            "." +
            "presentation" +
            "." +
            "search" +
            "." +
            "cancel",
      );

      publish.add(
        "service" +
            "." +
            "to" +
            "." +
            realm +
            "." +
            "organization" +
            "." +
            organization +
            "." +
            "realm" +
            "." +
            "editor" +
            "." +
            "capability" +
            "." +
            "computation" +
            "." +
            "invoke",
      );

      publish.add(
        "service" +
            "." +
            "to" +
            "." +
            realm +
            "." +
            "organization" +
            "." +
            organization +
            "." +
            "realm" +
            "." +
            "editor" +
            "." +
            "capability" +
            "." +
            "command" +
            "." +
            "invoke",
      );

      publish.add(
        "service" +
            "." +
            "to" +
            "." +
            realm +
            "." +
            "organization" +
            "." +
            organization +
            "." +
            "realm" +
            "." +
            "editor" +
            "." +
            "authoring" +
            "." +
            "state" +
            "." +
            "query",
      );

      subscribe.add(
        "service" +
            "." +
            "from" +
            "." +
            realm +
            "." +
            "organization" +
            "." +
            organization +
            "." +
            "realm" +
            "." +
            "editor" +
            "." +
            "authoring" +
            "." +
            "state" +
            "." +
            "query" +
            "." +
            "*",
      );

      publish.add(
        "service" +
            "." +
            "to" +
            "." +
            realm +
            "." +
            "organization" +
            "." +
            organization +
            "." +
            "realm" +
            "." +
            "editor" +
            "." +
            "authoring" +
            "." +
            "edit" +
            "." +
            "commit",
      );

      publish.add(
        "service" +
            "." +
            "to" +
            "." +
            realm +
            "." +
            "organization" +
            "." +
            organization +
            "." +
            "realm" +
            "." +
            "editor" +
            "." +
            "authoring" +
            "." +
            "type" +
            "." +
            "preview",
      );

      publish.add(
        "service" +
            "." +
            "to" +
            "." +
            realm +
            "." +
            "organization" +
            "." +
            organization +
            "." +
            "realm" +
            "." +
            "editor" +
            "." +
            "authoring" +
            "." +
            "type" +
            "." +
            "commit",
      );

      publish.add(
        "service" +
            "." +
            "to" +
            "." +
            realm +
            "." +
            "organization" +
            "." +
            organization +
            "." +
            "realm" +
            "." +
            "editor" +
            "." +
            "authoring" +
            "." +
            "search",
      );

      subscribe.add(
        "service" +
            "." +
            "from" +
            "." +
            realm +
            "." +
            "organization" +
            "." +
            organization +
            "." +
            "realm" +
            "." +
            "editor" +
            "." +
            "authoring" +
            "." +
            "changed",
      );

      publish.add(
        "service" +
            "." +
            "to" +
            "." +
            realm +
            "." +
            "organization" +
            "." +
            organization +
            "." +
            "realm" +
            "." +
            "editor" +
            "." +
            "authoring" +
            "." +
            "compiled" +
            "." +
            "query",
      );

      subscribe.add(
        "service" +
            "." +
            "from" +
            "." +
            realm +
            "." +
            "organization" +
            "." +
            organization +
            "." +
            "realm" +
            "." +
            "editor" +
            "." +
            "authoring" +
            "." +
            "compiled" +
            "." +
            "query" +
            "." +
            "*",
      );

      subscribe.add(
        "service" +
            "." +
            "from" +
            "." +
            realm +
            "." +
            "organization" +
            "." +
            organization +
            "." +
            "realm" +
            "." +
            "editor" +
            "." +
            "authoring" +
            "." +
            "compiled" +
            "." +
            "changed",
      );

      publish.add(
        "service" +
            "." +
            "to" +
            "." +
            realm +
            "." +
            "organization" +
            "." +
            organization +
            "." +
            "realm" +
            "." +
            "editor" +
            "." +
            "authoring" +
            "." +
            "compiled" +
            "." +
            "status" +
            "." +
            "query",
      );

      publish.add(
        "service" +
            "." +
            "to" +
            "." +
            realm +
            "." +
            "organization" +
            "." +
            organization +
            "." +
            "realm" +
            "." +
            "editor" +
            "." +
            "authoring" +
            "." +
            "publish",
      );

      publish.add(
        "service" +
            "." +
            "to" +
            "." +
            realm +
            "." +
            "organization" +
            "." +
            organization +
            "." +
            "realm" +
            "." +
            "editor" +
            "." +
            "authoring" +
            "." +
            "publication" +
            "." +
            "watch",
      );

      subscribe.add(
        "service" +
            "." +
            "from" +
            "." +
            realm +
            "." +
            "organization" +
            "." +
            organization +
            "." +
            "realm" +
            "." +
            "editor" +
            "." +
            "authoring" +
            "." +
            "publication" +
            "." +
            "watch",
      );

      publish.add(
        "service" +
            "." +
            "to" +
            "." +
            realm +
            "." +
            "organization" +
            "." +
            organization +
            "." +
            "realm" +
            "." +
            "shared" +
            "." +
            "catalog" +
            "." +
            "fetch",
      );

      publish.add(
        "service" +
            "." +
            "to" +
            "." +
            realm +
            "." +
            "organization" +
            "." +
            organization +
            "." +
            "realm" +
            "." +
            "shared" +
            "." +
            "publish",
      );

      publish.add(
        "service" +
            "." +
            "to" +
            "." +
            realm +
            "." +
            "organization" +
            "." +
            organization +
            "." +
            "realm" +
            "." +
            "shared" +
            "." +
            "blob" +
            "." +
            "metadata",
      );

      publish.add(
        "service" +
            "." +
            "to" +
            "." +
            realm +
            "." +
            "organization" +
            "." +
            organization +
            "." +
            "realm" +
            "." +
            "shared" +
            "." +
            "blob" +
            "." +
            "read",
      );

      publish.add(
        "service" +
            "." +
            "to" +
            "." +
            realm +
            "." +
            "organization" +
            "." +
            organization +
            "." +
            "realm" +
            "." +
            "shared" +
            "." +
            "blob" +
            "." +
            "begin",
      );

      publish.add(
        "service" +
            "." +
            "to" +
            "." +
            realm +
            "." +
            "organization" +
            "." +
            organization +
            "." +
            "realm" +
            "." +
            "shared" +
            "." +
            "blob" +
            "." +
            "write",
      );

      publish.add(
        "service" +
            "." +
            "to" +
            "." +
            realm +
            "." +
            "organization" +
            "." +
            organization +
            "." +
            "realm" +
            "." +
            "shared" +
            "." +
            "blob" +
            "." +
            "complete",
      );
    }
  }
  return TransportPermissionGrant(publish: publish, subscribe: subscribe);
}

extension GeneratedRealmAdmission on ServerPermissionSnapshot {
  Set<_skir.RecordId> admittedRealms(NatsClient client) {
    final organization = client.organizationId?._transportIdentity;
    if (organization == null) return const {};
    const prefix = "service.to.";
    final suffix =
        ".organization." + organization + ".realm.editor.catalog.fetch";
    return publish
        .where(
          (subject) => subject.startsWith(prefix) && subject.endsWith(suffix),
        )
        .map(
          (subject) =>
              subject.substring(prefix.length, subject.length - suffix.length),
        )
        .where((realm) => realm._isTransportIdentity)
        .map(
          (realm) => _skir.RecordId(
            table: "realm_instance",
            key: _skir.RecordIdKey.wrapString(realm),
          ),
        )
        .where((realm) => realm.admittedBy(this, client))
        .toSet();
  }
}

extension GeneratedRealmPermission on _skir.RecordId {
  bool admittedBy(ServerPermissionSnapshot snapshot, NatsClient client) {
    final required = panelTransportPermissions(
      actorId: client.actorId,
      organizationId: client.organizationId == null
          ? null
          : _skir.RecordId(
              table: "organization",
              key: _skir.RecordIdKey.wrapString(client.organizationId!),
            ),
      connectionSession: client.connectionSession,
      realmIds: [this],
    );
    return snapshot.publish.containsAll(required.publish) &&
        snapshot.subscribe.containsAll(required.subscribe);
  }
}

void _grantPersistentProjection(
  Set<String> publish, {
  required String stream,
  required String consumer,
  required String filter,
}) {
  publish.addAll({
    "\$JS.API.STREAM.INFO.$stream",
    "\$JS.API.CONSUMER.CREATE.$stream.$consumer.$filter",
    "\$JS.API.CONSUMER.INFO.$stream.$consumer",
    "\$JS.API.CONSUMER.MSG.NEXT.$stream.$consumer",
    "\$JS.API.CONSUMER.DELETE.$stream.$consumer",
  });
}

final class PersistentProjectionRoute {
  const PersistentProjectionRoute({
    required this.id,
    required this.organizationScoped,
  });
  final String id;
  final bool organizationScoped;
  String consumerName(NatsClient client) {
    final organization = client.organizationId;
    if (organizationScoped && organization == null) {
      throw StateError(
        "Persistent organization projection requires an admitted organization",
      );
    }
    return _persistentConsumerName(
      actor: client.actorId._transportIdentity,
      organization: organizationScoped
          ? organization?._transportIdentity
          : null,
      session: client.connectionSession._transportSession,
      projection: id,
    );
  }
}

String _persistentConsumerName({
  required String actor,
  required String? organization,
  required String session,
  required String projection,
}) {
  final identity = jsonEncode([actor, organization, session, projection]);
  final encoded = base64Url.encode(utf8.encode(identity)).replaceAll("=", "");
  return "TW_$encoded";
}

extension _TransportSegment on String {
  static final _identity = RegExp("^[^\\s.*>{}]+\$");
  static final _transfer = RegExp("^[A-Za-z0-9_\\-]{1,64}\$");
  static final _session = RegExp("^[a-f0-9]{32}\$");
  bool get _isTransportIdentity => _identity.hasMatch(this);
  String get _transportIdentity {
    if (!_isTransportIdentity)
      throw ArgumentError.value(this, "identity", "Invalid identity segment");
    return this;
  }

  String get _transportTransfer {
    if (!_transfer.hasMatch(this))
      throw ArgumentError.value(this, "transferId", "Invalid transfer segment");
    return this;
  }

  String get _transportSession {
    if (!_session.hasMatch(this))
      throw ArgumentError.value(
        this,
        "connectionSession",
        "Invalid connection session",
      );
    return this;
  }
}
