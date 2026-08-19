use otel_wasi::ResultWithSlug;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use wasmcloud_utils::database::organization::projections::{
    JoinRequestProjection, OrganizationMemberProjection,
};
use wasmcloud_utils::{
    database::{RecordId, TransactionOutcome, read_query, transaction_query},
    decode_skir, extract_params,
    skir::base::organization::v1::{
        join_request::*,
        member::{OrganizationMember, WatchOrganizationMembersResponse},
        user::{WatchUserJoinRequestsResponse, WatchUserOrganizationsResponse},
    },
    skir_transaction_outcome,
    skir_utils::{IntoSkirRecordIds, IntoSurrealRecordIds},
    skir_variant,
    wasmcloud::messaging::types::BrokerMessage,
};

#[derive(Debug, Serialize, Deserialize)]
struct ApprovalRecord {
    request: JoinRequestProjection,
    member: OrganizationMemberProjection,
}

#[derive(Debug, Deserialize)]
#[serde(tag = "outcome", rename_all = "kebab-case")]
enum ApprovalOutcome {
    Approved { approval: Box<ApprovalRecord> },
    RequestNotFoundError,
    RolesRequiredError,
    RolesNotFoundError { role_ids: Vec<RecordId> },
    RolesNotAssignableError { role_ids: Vec<RecordId> },
    UserAlreadyMemberError { user_id: RecordId },
}

impl ApprovalOutcome {
    fn as_str(&self) -> &'static str {
        match self {
            Self::Approved { .. } => "approved",
            Self::RequestNotFoundError => "request-not-found-error",
            Self::RolesRequiredError => "roles-required-error",
            Self::RolesNotFoundError { .. } => "roles-not-found-error",
            Self::RolesNotAssignableError { .. } => "roles-not-assignable-error",
            Self::UserAlreadyMemberError { .. } => "user-already-member-error",
        }
    }
}

#[tracing::instrument(skip(msg, params))]
pub async fn handle_watch(
    msg: BrokerMessage,
    params: HashMap<String, String>,
) -> Result<WatchOrganizationJoinRequestsResponse, otel_wasi::Error> {
    let (actor_id, org_id) = extract_params!(params, user_id, org_id)?;
    otel_wasi::main_attribute!(
        "actor.id" = actor_id.to_string(),
        "organization.id" = org_id.to_string()
    );
    let _ = decode_skir!(WatchOrganizationJoinRequestsRequest, &msg.body)?;

    let organization_id = RecordId::new("organization", org_id);
    let rows = read_query!(
        r#"
        SELECT
            id,
            in.* AS user,
            out.* AS organization,
            requested_at,
            expires_at
        FROM request_to_join
        WHERE out = $org_id
            AND expires_at > time::now()
        "#,
    )
    .bind("org_id", organization_id)
    .execute()
    .await
    .error_with_slug("join-request-watch-query-failed")?
    .take::<Vec<JoinRequestProjection>>()
    .error_with_slug("join-request-watch-result-parse-failed")?;

    otel_wasi::main_attribute!(
        "join_request.outcome" = "listed",
        "join_request.result_count" = rows.len() as i64
    );

    Ok(WatchOrganizationJoinRequestsResponse::List(
        rows.into_iter().map(Into::into).collect(),
    ))
}

#[tracing::instrument(skip(msg, params))]
pub async fn handle_approve(
    msg: BrokerMessage,
    params: HashMap<String, String>,
) -> Result<ApproveOrganizationJoinRequestResponse, otel_wasi::Error> {
    let (actor_id, org_id) = extract_params!(params, user_id, org_id)?;
    let req = decode_skir!(ApproveOrganizationJoinRequestRequest, &msg.body)?;
    wasmcloud_utils::validate_record_ids!(
        ApproveOrganizationJoinRequestResponse,
        req.request_id,
        "request_to_join"
    );
    wasmcloud_utils::validate_record_ids!(
        ApproveOrganizationJoinRequestResponse,
        req.role_ids,
        "organization_role"
    );
    let request_id = req.request_id.clone();
    let role_ids = req.role_ids.clone();
    otel_wasi::main_attribute!(
        "actor.id" = actor_id.to_string(),
        "organization.id" = org_id.to_string(),
        "request.id" = request_id.key.to_string(),
        "role.result_count" = role_ids.len() as i64
    );
    let request_record_id = RecordId::from(&request_id);
    let organization_id = RecordId::new("organization", org_id);

    let db_role_ids = role_ids.as_slice().into_surreal_record_ids();
    let result = transaction_query!(
        ApprovalOutcome,
        r#"
        BEGIN TRANSACTION;

        RETURN {
            LET $requests = SELECT id, in.* AS user, out.* AS organization, requested_at, expires_at
                FROM $request
                WHERE out = $org AND expires_at > time::now();

            IF array::is_empty($requests) {
                RETURN { outcome: 'request-not-found-error' }
            };

            IF array::is_empty($roles) {
                RETURN { outcome: 'roles-required-error' }
            };

            LET $requested = SELECT * FROM $roles WHERE organization = $org;
            LET $missing = array::complement(array::distinct($roles), $requested.id);
            IF array::len($missing) > 0 {
                RETURN { outcome: 'roles-not-found-error', role_ids: $missing }
            };

            LET $unassignable = SELECT VALUE id FROM $requested WHERE !assignable;
            IF array::len($unassignable) > 0 {
                RETURN { outcome: 'roles-not-assignable-error', role_ids: $unassignable }
            };

            LET $join_request = array::first($requests);
            LET $request_user = $join_request.user.id;
            IF array::len(SELECT * FROM member_of WHERE in = $request_user AND out = $org) > 0 {
                RETURN { outcome: 'user-already-member-error', user_id: $request_user }
            };

            LET $member = RELATE ONLY $request_user->member_of->$org SET roles = $roles;
            DELETE $join_request.id;

            RETURN {
                outcome: 'approved',
                approval: {
                    request: $join_request,
                    member: (SELECT
                        in.id AS user_id,
                        in.name AS name,
                        in.email AS email,
                        in.avatar_url AS avatar_url,
                        roles.* AS roles,
                        joined_at
                    FROM ONLY $member
                    FETCH roles)
                }
            }
        };
        COMMIT TRANSACTION;
        "#,
    )
    .bind("request", request_record_id)
    .bind("org", organization_id)
    .bind("roles", db_role_ids)
    .execute()
    .await
    .error_with_slug("join-request-approve-query-failed")?
    .decode()
    .error_with_slug("join-request-approve-result-parse-failed")?;

    let result =
        wasmcloud_utils::skir_domain_result!(ApproveOrganizationJoinRequestResponse, result);
    otel_wasi::main_attribute!("join_request.outcome" = result.as_str());
    let approved = skir_transaction_outcome!(
        ApproveOrganizationJoinRequestResponse,
        result,
        success ApprovalOutcome::Approved { approval } => approval,
        errors {
            ApprovalOutcome::RequestNotFoundError => {
                request_id: request_id.clone()
            },
            ApprovalOutcome::RolesRequiredError => {},
            ApprovalOutcome::RolesNotFoundError { role_ids } => {
                role_ids: role_ids.into_skir_record_ids()
            },
            ApprovalOutcome::RolesNotAssignableError { role_ids } => {
                role_ids: role_ids.into_skir_record_ids()
            },
            ApprovalOutcome::UserAlreadyMemberError { user_id } => {
                user_id: user_id.into()
            },
        }
    );

    let member: OrganizationMember = approved.member.into();

    let user_id = approved.request.user.id.key.to_string();

    wasmcloud_utils::skir_subjects::organization_join_requests(org_id)
        .publish(WatchOrganizationJoinRequestsResponse::Remove(Box::new(
            request_id.clone(),
        )))
        .await?;

    wasmcloud_utils::skir_subjects::user_join_requests(&user_id)
        .publish(WatchUserJoinRequestsResponse::Remove(Box::new(request_id)))
        .await?;

    wasmcloud_utils::skir_subjects::organization_members(org_id)
        .publish(WatchOrganizationMembersResponse::Add(Box::new(
            member.clone(),
        )))
        .await?;

    wasmcloud_utils::skir_subjects::user_organizations(&user_id)
        .publish(WatchUserOrganizationsResponse::Add(Box::new(
            approved.request.organization.into(),
        )))
        .await?;

    otel_wasi::main_attribute!("join_request.outcome" = "approved");
    Ok(ApproveOrganizationJoinRequestResponse::Success(Box::new(
        member,
    )))
}

#[tracing::instrument(skip(msg, params))]
pub async fn handle_decline(
    msg: BrokerMessage,
    params: HashMap<String, String>,
) -> Result<DeclineOrganizationJoinRequestResponse, otel_wasi::Error> {
    let (actor_id, org_id) = extract_params!(params, user_id, org_id)?;
    let req = decode_skir!(DeclineOrganizationJoinRequestRequest, &msg.body)?;
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
        Option<JoinRequestProjection>,
        r#"
        BEGIN TRANSACTION;

        LET $r = SELECT
            id,
            in.* AS user,
            out.* AS organization,
            requested_at,
            expires_at
        FROM $request
        WHERE out = $org
            AND expires_at > time::now();

        DELETE $r.id;

        RETURN $r[0];

        COMMIT TRANSACTION;
        "#,
    )
    .bind("request", request_record_id)
    .bind("org", organization_id)
    .execute()
    .await
    .error_with_slug("join-request-decline-query-failed")?
    .decode()
    .error_with_slug("join-request-decline-result-parse-failed")?;

    if let TransactionOutcome::Rejected(error) = &row {
        otel_wasi::main_attribute!("join_request.outcome" = error.message().to_owned());
    }

    let row = wasmcloud_utils::skir_domain_result!(DeclineOrganizationJoinRequestResponse, row,
        "request-not-found-error" => { request_id: request_id.clone() }
    );

    let Some(row) = row else {
        otel_wasi::main_attribute!("join_request.outcome" = "request_not_found");
        return Ok(skir_variant!(
            DeclineOrganizationJoinRequestResponse::RequestNotFoundError { request_id }
        ));
    };

    wasmcloud_utils::skir_subjects::organization_join_requests(org_id)
        .publish(WatchOrganizationJoinRequestsResponse::Remove(Box::new(
            request_id.clone(),
        )))
        .await?;

    wasmcloud_utils::skir_subjects::user_join_requests(row.user.id.key.to_string())
        .publish(WatchUserJoinRequestsResponse::Remove(Box::new(request_id)))
        .await?;

    otel_wasi::main_attribute!("join_request.outcome" = "declined");
    Ok(skir_variant!(
        DeclineOrganizationJoinRequestResponse::Success
    ))
}
