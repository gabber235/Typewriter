//! Moderation of pending organization join requests.
//!
//! The organization and user request views are separate projections with separate sequences.
//! Approval changes both request and membership state in one database transaction, then publishes
//! organization and user events for reconciliation. Decline removes one request from both views.
//! Mutation receipts make committed approval and decline operations replayable without reapplying
//! database changes.

use otel_wasi::ResultWithSlug;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use wasmcloud_utils::database::organization::projections::{
    JoinRequestProjection, OrganizationMemberProjection,
};
use wasmcloud_utils::{
    database::{RecordId, TransactionOutcome, transaction_query},
    decode_skir, extract_params,
    skir::base::organization::v1::{join_request::*, member::OrganizationMember},
    skir_transaction_outcome,
    skir_utils::{IntoSkirRecordIds, IntoSurrealRecordIds},
    skir_variant,
    wasmcloud::messaging::types::NatsMessage,
};

#[derive(Clone, Debug, Serialize, Deserialize)]
struct ApprovalRecord {
    request: JoinRequestProjection,
    member: OrganizationMemberProjection,
    user_join_requests_sequence: i64,
    user_organizations_sequence: i64,
}

#[derive(Debug, Deserialize)]
struct DeclinedRequest {
    request: JoinRequestProjection,
    organization_sequence: i64,
    user_sequence: i64,
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
    RolesRequiredError,
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
            Self::RolesRequiredError => "roles-required-error",
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
#[tracing::instrument(skip(msg, params))]
pub async fn handle_watch(
    msg: NatsMessage,
    params: HashMap<String, String>,
) -> Result<WatchOrganizationJoinRequestsResponse, otel_wasi::Error> {
    let (actor_id, org_id) = extract_params!(params, user_id, org_id)?;
    otel_wasi::main_attribute!(
        "actor.id" = actor_id.to_string(),
        "organization.id" = org_id.to_string()
    );
    let _ = decode_skir!(WatchOrganizationJoinRequestsRequest, &msg.body)?;

    wasmcloud_utils::database::organization::snapshots::join_requests(RecordId::new(
        "organization",
        org_id,
    ))
    .await
}

/// Approves all selected pending requests with one shared role selection.
///
/// The database transaction validates request freshness, role existence and assignability, duplicate
/// users, and existing memberships before creating memberships and deleting requests. Any invalid
/// selection rejects the complete batch. Success returns events for the organization request and
/// member projections, while each affected user also receives request and organization changes.
#[tracing::instrument(skip(msg, params))]
pub async fn handle_approve(
    msg: NatsMessage,
    params: HashMap<String, String>,
) -> Result<ApproveOrganizationJoinRequestsResponse, otel_wasi::Error> {
    let (actor_id, org_id) = extract_params!(params, user_id, org_id)?;
    let req = decode_skir!(ApproveOrganizationJoinRequestsRequest, &msg.body)?;
    wasmcloud_utils::validate_record_ids!(
        ApproveOrganizationJoinRequestsResponse,
        req.request_ids,
        "request_to_join"
    );
    wasmcloud_utils::validate_record_ids!(
        ApproveOrganizationJoinRequestsResponse,
        req.role_ids,
        "organization_role"
    );
    let request_ids = req.request_ids.clone();
    let role_ids = req.role_ids.clone();
    otel_wasi::main_attribute!(
        "actor.id" = actor_id.to_string(),
        "organization.id" = org_id.to_string(),
        "request.result_count" = request_ids.len() as i64,
        "role.result_count" = role_ids.len() as i64
    );
    let request_record_ids = request_ids.as_slice().into_surreal_record_ids();
    let organization_id = RecordId::new("organization", org_id);
    let receipt = wasmcloud_utils::database::mutation::receipt_id(
        actor_id,
        org_id,
        "members.join_requests.approve",
        &req.operation_id,
    );
    if req.operation_id.is_empty() {
        return Ok(skir_variant!(
            ApproveOrganizationJoinRequestsResponse::InvalidSelectionError
        ));
    }

    let db_role_ids = role_ids.as_slice().into_surreal_record_ids();
    let result = transaction_query!(
        ApprovalOutcome,
        r#"
        BEGIN TRANSACTION;

        RETURN fn::organization::members::approve_requests($org, $requests, $roles, $receipt, $request_bytes);

        COMMIT TRANSACTION;
        "#,
    )
    .bind("requests", request_record_ids)
    .bind("org", organization_id)
    .bind("roles", db_role_ids)
    .bind("receipt", receipt)
    .bind("request_bytes", msg.body.clone())
    .execute()
    .await
    .error_with_slug("join-request-approve-query-failed")?
    .decode()
    .error_with_slug("join-request-approve-result-parse-failed")?;

    let result = wasmcloud_utils::skir_domain_result!(ApproveOrganizationJoinRequestsResponse, result,
        "operation-identity-reused-error" => {}
    );
    otel_wasi::main_attribute!("join_request.outcome" = result.as_str());
    let approvals = skir_transaction_outcome!(
        ApproveOrganizationJoinRequestsResponse,
        result,
        success ApprovalOutcome::Approved { approvals, join_requests_sequence, members_sequence } => (approvals, join_requests_sequence, members_sequence),
        errors {
            ApprovalOutcome::RequestNotFoundError { request_ids } => {
                request_ids: request_ids.into_skir_record_ids()
            },
            ApprovalOutcome::RolesRequiredError => {},
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
    let join_requests_event = OrganizationJoinRequestsChanged {
        sequence: join_requests_sequence,
        operation_id: req.operation_id.clone(),
        changes: approvals
            .iter()
            .map(|approved| {
                OrganizationJoinRequestsChange::Remove(Box::new(approved.request.id.clone().into()))
            })
            .collect(),
        ..Default::default()
    };
    wasmcloud_utils::skir_subjects::organization_join_requests_changed(org_id)
        .persist(join_requests_event.clone())
        .await?;
    let member_values: Vec<OrganizationMember> = approvals
        .iter()
        .map(|approved| approved.member.clone().into())
        .collect();
    let members_event = wasmcloud_utils::skir::base::organization::v1::member::OrganizationMembersChanged {
        sequence: members_sequence,
        operation_id: req.operation_id.clone(),
        changes: member_values
            .iter()
            .cloned()
            .map(|member| wasmcloud_utils::skir::base::organization::v1::member::OrganizationMembersChange::Add(Box::new(member)))
            .collect(),
        ..Default::default()
    };
    wasmcloud_utils::skir_subjects::organization_members_changed(org_id)
        .persist(members_event.clone())
        .await?;
    let mut results = Vec::with_capacity(approvals.len());
    for approved in approvals {
        let request_id: wasmcloud_utils::skir::base::kernel::v1::record_id::RecordId =
            approved.request.id.clone().into();
        let member: OrganizationMember = approved.member.into();

        let user_id = approved.request.user.id.key.to_string();

        let user_request_event = UserJoinRequestsChanged {
            sequence: approved.user_join_requests_sequence,
            operation_id: req.operation_id.clone(),
            changes: vec![UserJoinRequestsChange::Remove(Box::new(request_id.clone()))],
            ..Default::default()
        };
        wasmcloud_utils::skir_subjects::user_join_requests_changed(&user_id)
            .persist(user_request_event)
            .await?;
        let organization: wasmcloud_utils::skir::base::organization::v1::organization::Organization =
            approved.request.organization.into();
        let user_organization_event = wasmcloud_utils::skir::base::organization::v1::organization::UserOrganizationsChanged {
            sequence: approved.user_organizations_sequence,
            operation_id: req.operation_id.clone(),
            changes: vec![wasmcloud_utils::skir::base::organization::v1::organization::UserOrganizationsChange::Add(Box::new(organization))],
            ..Default::default()
        };
        wasmcloud_utils::skir_subjects::user_organizations_changed(&user_id)
            .persist(user_organization_event)
            .await?;

        results.push(ApprovedOrganizationJoinRequest {
            request_id,
            member,
            ..Default::default()
        });
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

/// Declines one unexpired join request.
///
/// The transaction deletes the request and advances the request sequence for both its organization
/// and user. The organization event is returned to the caller; the matching user event is published
/// separately so both projections can converge.
#[tracing::instrument(skip(msg, params))]
pub async fn handle_decline(
    msg: NatsMessage,
    params: HashMap<String, String>,
) -> Result<DeclineOrganizationJoinRequestResponse, otel_wasi::Error> {
    let (actor_id, org_id) = extract_params!(params, user_id, org_id)?;
    let req = decode_skir!(DeclineOrganizationJoinRequestRequest, &msg.body)?;
    if req.operation_id.is_empty() {
        return Ok(wasmcloud_utils::skir_variant!(
            DeclineOrganizationJoinRequestResponse::InvalidOperationIdError
        ));
    }
    let receipt = wasmcloud_utils::database::mutation::receipt_id(
        actor_id,
        org_id,
        "DeclineOrganizationJoinRequest",
        &req.operation_id,
    );
    wasmcloud_utils::validate_record_ids!(
        DeclineOrganizationJoinRequestResponse,
        req.request_id,
        "request_to_join"
    );
    let request_id = req.request_id.clone();
    otel_wasi::main_attribute!(
        "actor.id" = actor_id.to_string(),
        "organization.id" = org_id.to_string(),
        "request.id" = request_id.key.to_string()
    );
    let request_record_id = RecordId::from(&request_id);
    let organization_id = RecordId::new("organization", org_id);

    let row = transaction_query!(
        Option<DeclinedRequest>,
        r#"
        BEGIN TRANSACTION;
        RETURN {
            LET $previous = fn::mutation::recall($receipt, $request_bytes);
            IF $previous != NONE { RETURN $previous.value };
            LET $result = {
LET $r = SELECT
            id,
            in.* AS user,
            out.* AS organization,
            requested_at,
            expires_at
        FROM $request
        WHERE out = $org
            AND expires_at > time::now();

        IF array::len($r) = 0 { RETURN NONE };
        DELETE $r.id;
        LET $organization_sequence = UPDATE ONLY $org SET join_requests_sequence += 1
            RETURN VALUE join_requests_sequence;
        LET $user_sequence = UPDATE ONLY $r[0].user.id SET join_requests_sequence += 1
            RETURN VALUE join_requests_sequence;

        RETURN {
            request: $r[0],
            organization_sequence: $organization_sequence,
            user_sequence: $user_sequence
        };
            };
            IF $result != NONE {
                LET $stored = fn::mutation::commit($receipt, $request_bytes, { value: $result });
                RETURN $stored.value;
            };
            RETURN $result;
        };
        COMMIT TRANSACTION;
        "#,
    )
    .bind("request", request_record_id)
    .bind("org", organization_id)
    .bind("receipt", receipt)
    .bind("request_bytes", msg.body.clone())
    .execute()
    .await
    .error_with_slug("join-request-decline-query-failed")?
    .decode()
    .error_with_slug("join-request-decline-result-parse-failed")?;

    if let TransactionOutcome::Rejected(error) = &row {
        otel_wasi::main_attribute!("join_request.outcome" = error.message().to_owned());
    }

    let row = wasmcloud_utils::skir_domain_result!(DeclineOrganizationJoinRequestResponse, row,
        "operation-identity-reused-error" => {},
        "request-not-found-error" => { request_id: request_id.clone() }
    );

    let Some(row) = row else {
        otel_wasi::main_attribute!("join_request.outcome" = "request_not_found");
        return Ok(skir_variant!(
            DeclineOrganizationJoinRequestResponse::RequestNotFoundError { request_id }
        ));
    };

    let event = OrganizationJoinRequestsChanged {
        sequence: row.organization_sequence,
        operation_id: req.operation_id.clone(),
        changes: vec![OrganizationJoinRequestsChange::Remove(Box::new(
            request_id.clone(),
        ))],
        ..Default::default()
    };
    wasmcloud_utils::skir_subjects::organization_join_requests_changed(org_id)
        .persist(event.clone())
        .await?;
    let user_event = UserJoinRequestsChanged {
        sequence: row.user_sequence,
        operation_id: req.operation_id,
        changes: vec![UserJoinRequestsChange::Remove(Box::new(request_id))],
        ..Default::default()
    };
    wasmcloud_utils::skir_subjects::user_join_requests_changed(row.request.user.id.key.to_string())
        .persist(user_event)
        .await?;

    otel_wasi::main_attribute!("join_request.outcome" = "declined");
    Ok(skir_variant!(
        DeclineOrganizationJoinRequestResponse::Success { event }
    ))
}
