//! Moderation of pending organization join requests.
//!
//! The organization and user request views are separate projections with separate sequences.
//! Approval changes both request and membership state in one database transaction, then publishes
//! organization and user events for reconciliation. Decline removes a selection of requests from
//! both views. Each mutation applies to its complete selection or to none of it.

use otel_wasi::ResultWithSlug;
use serde::{Deserialize, Serialize};
use wasmcloud_utils::database::organization::projections::{
    JoinRequestProjection, OrganizationMemberProjection,
};
use wasmcloud_utils::{
    database::{RecordId, transaction_query},
    skir::base::organization::v1::{join_request::*, member::OrganizationMember},
    skir_transaction_outcome,
    skir_utils::{IntoSkirRecordIds, IntoSurrealRecordIds, RecordIdKeyIdentity},
    skir_variant,
};

#[derive(Clone, Debug, Serialize, Deserialize)]
struct ApprovalRecord {
    request: JoinRequestProjection,
    member: OrganizationMemberProjection,
    user_join_requests_sequence: i64,
    user_organizations_sequence: i64,
}

/// One request to approve and its new member's roles, as the database function reads it.
#[derive(Debug, Serialize)]
struct ApprovalRequestRecord {
    request: RecordId,
    roles: Vec<RecordId>,
}

/// One declined request and the sequence of its user's request view after the decline.
#[derive(Debug, Deserialize)]
struct DeclinedRequest {
    id: RecordId,
    user: RecordId,
    user_sequence: i64,
}

#[derive(Debug, Deserialize)]
#[serde(tag = "outcome", rename_all = "kebab-case")]
enum DeclineOutcome {
    Declined {
        declined: Vec<DeclinedRequest>,
        organization_sequence: i64,
    },
    RequestNotFoundError {
        request_ids: Vec<RecordId>,
    },
    InvalidSelectionError,
}

impl DeclineOutcome {
    fn as_str(&self) -> &'static str {
        match self {
            Self::Declined { .. } => "declined",
            Self::RequestNotFoundError { .. } => "request-not-found-error",
            Self::InvalidSelectionError => "invalid-selection-error",
        }
    }
}

#[derive(Debug, Deserialize)]
#[serde(tag = "outcome", rename_all = "kebab-case")]
enum ApprovalOutcome {
    Approved {
        approvals: Vec<ApprovalRecord>,
        join_requests_sequence: i64,
        members_sequence: i64,
    },
    RequestNotFoundError {
        request_ids: Vec<RecordId>,
    },
    InvalidSelectionError,
    RolesRequiredError {
        request_ids: Vec<RecordId>,
    },
    RolesNotFoundError {
        role_ids: Vec<RecordId>,
    },
    RolesNotAssignableError {
        role_ids: Vec<RecordId>,
    },
    UserAlreadyMemberError {
        user_ids: Vec<RecordId>,
    },
}

impl ApprovalOutcome {
    fn as_str(&self) -> &'static str {
        match self {
            Self::Approved { .. } => "approved",
            Self::RequestNotFoundError { .. } => "request-not-found-error",
            Self::InvalidSelectionError => "invalid-selection-error",
            Self::RolesRequiredError { .. } => "roles-required-error",
            Self::RolesNotFoundError { .. } => "roles-not-found-error",
            Self::RolesNotAssignableError { .. } => "roles-not-assignable-error",
            Self::UserAlreadyMemberError { .. } => "user-already-member-error",
        }
    }
}

/// Returns the current unexpired join requests for organization moderation.
///
/// The response pairs the organization request projection with its sequence. User request changes
/// use a different sequence and are published by the corresponding mutation path.
#[tracing::instrument(skip_all)]
pub async fn handle_watch(
    scope: wasmcloud_utils::transport::OrganizationActorScope,
    _request: WatchOrganizationJoinRequestsRequest,
) -> Result<WatchOrganizationJoinRequestsResponse, otel_wasi::Error> {
    let actor_id = scope.user.as_str();
    let org_id = scope.organization.as_str();
    otel_wasi::main_attribute!(
        "actor.id" = actor_id.to_string(),
        "organization.id" = org_id.to_string()
    );

    wasmcloud_utils::database::organization::snapshots::join_requests(RecordId::new(
        "organization",
        org_id,
    ))
    .await
}

/// Approves all selected pending requests, each with its own role selection.
///
/// The database transaction validates request freshness, that every request has roles, role
/// existence and assignability, duplicate users, and existing memberships before creating
/// memberships and deleting requests. Any invalid approval rejects the complete batch. Success
/// returns events for the organization request and member projections, while each affected user
/// also receives request and organization changes.
#[tracing::instrument(skip_all)]
pub async fn handle_approve(
    scope: wasmcloud_utils::transport::OrganizationActorScope,
    req: ApproveOrganizationJoinRequestsRequest,
) -> Result<ApproveOrganizationJoinRequestsResponse, otel_wasi::Error> {
    let actor_id = scope.user.as_str();
    let org_id = scope.organization.as_str();
    for approval in &req.approvals {
        wasmcloud_utils::validate_record_ids!(
            ApproveOrganizationJoinRequestsResponse,
            approval.request_id,
            "request_to_join"
        );
        wasmcloud_utils::validate_record_ids!(
            ApproveOrganizationJoinRequestsResponse,
            approval.role_ids,
            "organization_role"
        );
    }
    otel_wasi::main_attribute!(
        "actor.id" = actor_id.to_string(),
        "organization.id" = org_id.to_string(),
        "request.result_count" = req.approvals.len() as i64
    );
    let organization_id = RecordId::new("organization", org_id);
    let approvals: Vec<ApprovalRequestRecord> = req
        .approvals
        .iter()
        .map(|approval| ApprovalRequestRecord {
            request: RecordId::from(&approval.request_id),
            roles: approval.role_ids.as_slice().into_surreal_record_ids(),
        })
        .collect();

    let result = transaction_query!(
        ApprovalOutcome,
        r#"
        BEGIN TRANSACTION;

        RETURN fn::organization::members::approve_requests($org, $approvals);

        COMMIT TRANSACTION;
        "#,
    )
    .bind("approvals", approvals)
    .bind("org", organization_id)
    .execute()
    .await
    .error_with_slug("join-request-approve-query-failed")?
    .decode()
    .error_with_slug("join-request-approve-result-parse-failed")?;

    let result =
        wasmcloud_utils::skir_domain_result!(ApproveOrganizationJoinRequestsResponse, result);
    otel_wasi::main_attribute!("join_request.outcome" = result.as_str());
    let approvals = skir_transaction_outcome!(
        ApproveOrganizationJoinRequestsResponse,
        result,
        success ApprovalOutcome::Approved { approvals, join_requests_sequence, members_sequence } => (approvals, join_requests_sequence, members_sequence),
        errors {
            ApprovalOutcome::RequestNotFoundError { request_ids } => {
                request_ids: request_ids.into_skir_record_ids()
            },
            ApprovalOutcome::RolesRequiredError { request_ids } => {
                request_ids: request_ids.into_skir_record_ids()
            },
            ApprovalOutcome::InvalidSelectionError => {},
            ApprovalOutcome::RolesNotFoundError { role_ids } => {
                role_ids: role_ids.into_skir_record_ids()
            },
            ApprovalOutcome::RolesNotAssignableError { role_ids } => {
                role_ids: role_ids.into_skir_record_ids()
            },
            ApprovalOutcome::UserAlreadyMemberError { user_ids } => {
                user_ids: user_ids.into_skir_record_ids()
            },
        }
    );

    let (approvals, join_requests_sequence, members_sequence) = approvals;
    let join_requests_event =
        publish_requests_removed(org_id, &approvals, join_requests_sequence).await?;
    let members_event = publish_members_added(org_id, &approvals, members_sequence).await?;
    let mut results = Vec::with_capacity(approvals.len());
    for approved in approvals {
        results.push(publish_user_approval(approved).await?);
    }
    otel_wasi::main_attribute!("join_request.outcome" = "approved");
    Ok(skir_variant!(
        ApproveOrganizationJoinRequestsResponse::Success {
            approvals: results,
            join_requests_event,
            members_event
        }
    ))
}

/// Publishes the removal of every approved request from the organization request projection.
async fn publish_requests_removed(
    org_id: &str,
    approvals: &[ApprovalRecord],
    sequence: i64,
) -> Result<OrganizationJoinRequestsChanged, otel_wasi::Error> {
    let join_requests_event = OrganizationJoinRequestsChanged {
        sequence,
        changes: approvals
            .iter()
            .map(|approved| {
                OrganizationJoinRequestsChange::Remove(Box::new(approved.request.id.clone().into()))
            })
            .collect(),
        ..Default::default()
    };
    wasmcloud_utils::transport_routes::OrganizationJoinRequestsWatchRoute::delivery(
        &wasmcloud_utils::transport::OrganizationScope::try_from(org_id)?,
    )
    .persist(join_requests_event.clone())
    .await?;
    Ok(join_requests_event)
}

/// Publishes the members created by the approval to the organization member projection.
async fn publish_members_added(
    org_id: &str,
    approvals: &[ApprovalRecord],
    sequence: i64,
) -> Result<
    wasmcloud_utils::skir::base::organization::v1::member::OrganizationMembersChanged,
    otel_wasi::Error,
> {
    let member_values: Vec<OrganizationMember> = approvals
        .iter()
        .map(|approved| approved.member.clone().into())
        .collect();
    let members_event = wasmcloud_utils::skir::base::organization::v1::member::OrganizationMembersChanged {
        sequence,
        changes: member_values
            .iter()
            .cloned()
            .map(|member| wasmcloud_utils::skir::base::organization::v1::member::OrganizationMembersChange::Add(Box::new(member)))
            .collect(),
        ..Default::default()
    };
    wasmcloud_utils::transport_routes::OrganizationMembersWatchRoute::delivery(
        &wasmcloud_utils::transport::OrganizationScope::try_from(org_id)?,
    )
    .persist(members_event.clone())
    .await?;
    Ok(members_event)
}

/// Publishes one approval to the approved user, removing the request from their request view and
/// adding the organization to their organization view.
async fn publish_user_approval(
    approved: ApprovalRecord,
) -> Result<ApprovedOrganizationJoinRequest, otel_wasi::Error> {
    let request_id: wasmcloud_utils::skir::base::kernel::v1::record_id::RecordId =
        approved.request.id.clone().into();
    let member: OrganizationMember = approved.member.into();

    let user_id = approved.request.user.id.key.raw_identity()?;

    let user_request_event = UserJoinRequestsChanged {
        sequence: approved.user_join_requests_sequence,
        changes: vec![UserJoinRequestsChange::Remove(Box::new(request_id.clone()))],
        ..Default::default()
    };
    wasmcloud_utils::transport_routes::UserJoinRequestsWatchRoute::delivery(
        &wasmcloud_utils::transport::UserScope::try_from(user_id)?,
    )
    .persist(user_request_event)
    .await?;
    let organization: wasmcloud_utils::skir::base::organization::v1::organization::Organization =
        approved.request.organization.into();
    let user_organization_event = wasmcloud_utils::skir::base::organization::v1::organization::UserOrganizationsChanged {
        sequence: approved.user_organizations_sequence,
        changes: vec![wasmcloud_utils::skir::base::organization::v1::organization::UserOrganizationsChange::Add(Box::new(organization))],
        ..Default::default()
    };
    wasmcloud_utils::transport_routes::UserOrganizationsWatchRoute::delivery(
        &wasmcloud_utils::transport::UserScope::try_from(user_id)?,
    )
    .persist(user_organization_event)
    .await?;

    Ok(ApprovedOrganizationJoinRequest {
        request_id,
        member,
        ..Default::default()
    })
}

/// Declines every selected unexpired join request in one transaction.
///
/// An empty or repeated selection, or any missing or expired request, rejects the complete
/// selection. The transaction deletes the requests, advances the organization request sequence
/// once and each user's request sequence. The organization event is returned to the caller; each
/// user event is published separately so both projections can converge.
#[tracing::instrument(skip_all)]
pub async fn handle_decline(
    scope: wasmcloud_utils::transport::OrganizationActorScope,
    req: DeclineOrganizationJoinRequestsRequest,
) -> Result<DeclineOrganizationJoinRequestsResponse, otel_wasi::Error> {
    let actor_id = scope.user.as_str();
    let org_id = scope.organization.as_str();
    wasmcloud_utils::validate_record_ids!(
        DeclineOrganizationJoinRequestsResponse,
        req.request_ids,
        "request_to_join"
    );
    otel_wasi::main_attribute!(
        "actor.id" = actor_id.to_string(),
        "organization.id" = org_id.to_string(),
        "request.result_count" = req.request_ids.len() as i64
    );
    let organization_id = RecordId::new("organization", org_id);

    let result = transaction_query!(
        DeclineOutcome,
        r#"
        BEGIN TRANSACTION;
        RETURN {
            IF array::is_empty($requests) OR array::len(array::distinct($requests)) != array::len($requests) {
                RETURN { outcome: 'invalid-selection-error' }
            };

            LET $pending = SELECT id, in AS user FROM $requests
                WHERE out = $org
                AND expires_at > time::now();
            LET $missing = array::complement($requests, $pending.id);
            IF array::len($missing) > 0 {
                RETURN { outcome: 'request-not-found-error', request_ids: $missing }
            };

            FOR $request IN $pending {
                DELETE $request.id;
                UPDATE ONLY $request.user SET join_requests_sequence += 1;
            };
            LET $organization_sequence = UPDATE ONLY $org SET join_requests_sequence += 1
                RETURN VALUE join_requests_sequence;

            RETURN {
                outcome: 'declined',
                declined: $pending.map(|$request| {
                    RETURN {
                        id: $request.id,
                        user: $request.user,
                        user_sequence: (SELECT VALUE join_requests_sequence FROM ONLY $request.user)
                    };
                }),
                organization_sequence: $organization_sequence
            };
        };
        COMMIT TRANSACTION;
        "#,
    )
    .bind("requests", req.request_ids.as_slice().into_surreal_record_ids())
    .bind("org", organization_id)
    .execute()
    .await
    .error_with_slug("join-request-decline-query-failed")?
    .decode()
    .error_with_slug("join-request-decline-result-parse-failed")?;

    let result =
        wasmcloud_utils::skir_domain_result!(DeclineOrganizationJoinRequestsResponse, result);
    otel_wasi::main_attribute!("join_request.outcome" = result.as_str());
    let (declined, organization_sequence) = skir_transaction_outcome!(
        DeclineOrganizationJoinRequestsResponse,
        result,
        success DeclineOutcome::Declined { declined, organization_sequence } => (declined, organization_sequence),
        errors {
            DeclineOutcome::RequestNotFoundError { request_ids } => {
                request_ids: request_ids.into_skir_record_ids()
            },
            DeclineOutcome::InvalidSelectionError => {},
        }
    );

    let event = publish_declines(org_id, declined, organization_sequence).await?;
    Ok(skir_variant!(
        DeclineOrganizationJoinRequestsResponse::Success { event }
    ))
}

/// Publishes the removal of every declined request to the organization request view, and to each
/// applicant's own request view, returning the organization event.
async fn publish_declines(
    org_id: &str,
    declined: Vec<DeclinedRequest>,
    organization_sequence: i64,
) -> Result<OrganizationJoinRequestsChanged, otel_wasi::Error> {
    let event = OrganizationJoinRequestsChanged {
        sequence: organization_sequence,
        changes: declined
            .iter()
            .map(|request| {
                OrganizationJoinRequestsChange::Remove(Box::new(request.id.clone().into()))
            })
            .collect(),
        ..Default::default()
    };
    wasmcloud_utils::transport_routes::OrganizationJoinRequestsWatchRoute::delivery(
        &wasmcloud_utils::transport::OrganizationScope::try_from(org_id)?,
    )
    .persist(event.clone())
    .await?;
    for request in declined {
        let user_event = UserJoinRequestsChanged {
            sequence: request.user_sequence,
            changes: vec![UserJoinRequestsChange::Remove(Box::new(request.id.into()))],
            ..Default::default()
        };
        wasmcloud_utils::transport_routes::UserJoinRequestsWatchRoute::delivery(
            &wasmcloud_utils::transport::UserScope::try_from(request.user.key.raw_identity()?)?,
        )
        .persist(user_event)
        .await?;
    }

    Ok(event)
}
