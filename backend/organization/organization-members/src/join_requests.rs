use crate::validate_roles;
use otel_wasi::ResultWithSlug;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use surrealdb_component_sdk::query;
use wasmcloud_utils::database::organization::projections::{
    JoinRequestProjection, OrganizationMemberProjection,
};
use wasmcloud_utils::{
    decode_skir, extract_params,
    skir::base::organization::v1::{
        join_request::*,
        member::{OrganizationMember, WatchOrganizationMembersResponse},
        user::{WatchUserJoinRequestsResponse, WatchUserOrganizationsResponse},
    },
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
struct RequesterRecord {
    user_id: surrealdb_component_sdk::RecordId,
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

    let rows = query(
        r#"
        SELECT
            id,
            in.* AS user,
            out.* AS organization,
            requested_at,
            expires_at
        FROM request_to_join
        WHERE out = type::record('organization',$org_id)
            AND expires_at > time::now()
        "#,
    )
    .bind("org_id", org_id)
    .execute()
    .await
    .error_with_slug("join-request-watch-query-failed")?
    .take::<Vec<JoinRequestProjection>>(0)
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
    let request_id = req.request_id.clone();
    let role_ids = req.role_ids.clone();
    otel_wasi::main_attribute!(
        "actor.id" = actor_id.to_string(),
        "organization.id" = org_id.to_string(),
        "request.id" = request_id.key.to_string(),
        "role.result_count" = role_ids.len() as i64
    );

    let requester = query(
        r#"
        SELECT
            in AS user_id
        FROM ONLY $request
        WHERE out = $org
            AND expires_at > time::now()
        "#,
    )
    .bind(
        "request",
        surrealdb_component_sdk::RecordId::from(&request_id),
    )
    .bind(
        "org",
        surrealdb_component_sdk::RecordId::new("organization", org_id),
    )
    .execute()
    .await
    .error_with_slug("join-request-approve-requester-query-failed")?
    .take::<Option<RequesterRecord>>(0)
    .error_with_slug("join-request-approve-requester-result-parse-failed")?;

    let Some(requester) = requester else {
        otel_wasi::main_attribute!("join_request.outcome" = "request_not_found");
        return Ok(skir_variant!(
            ApproveOrganizationJoinRequestResponse::RequestNotFoundError { request_id }
        ));
    };

    let requester_id: wasmcloud_utils::skir::base::kernel::v1::record_id::RecordId =
        requester.user_id.into();
    otel_wasi::main_attribute!("requester.id" = requester_id.key.to_string());

    if role_ids.is_empty() {
        otel_wasi::main_attribute!("join_request.outcome" = "roles-required-error");
        return Ok(skir_variant!(
            ApproveOrganizationJoinRequestResponse::RolesRequiredError
        ));
    }

    let db_role_ids = role_ids.as_slice().into_surreal_record_ids();
    let validation = validate_roles(
        &org_id,
        &db_role_ids,
        &[],
        "join-request-approve-role-validation-query-failed",
        "join-request-approve-role-validation-result-parse-failed",
    )
    .await?;

    if !validation.missing.is_empty() {
        otel_wasi::main_attribute!("join_request.outcome" = "roles-not-found-error");
        return Ok(skir_variant!(
            ApproveOrganizationJoinRequestResponse::RolesNotFoundError {
                role_ids: validation.missing.into_skir_record_ids()
            }
        ));
    }

    if !validation.unassignable.is_empty() {
        otel_wasi::main_attribute!("join_request.outcome" = "roles-not-assignable-error");
        return Ok(skir_variant!(
            ApproveOrganizationJoinRequestResponse::RolesNotAssignableError {
                role_ids: validation.unassignable.into_skir_record_ids()
            }
        ));
    }

    let roles = db_role_ids;
    let result = query(
        r#"
        BEGIN TRANSACTION;

        LET $request = SELECT id, in.* AS user, out.* AS organization, requested_at, expires_at
            FROM $request
            WHERE out = $org AND expires_at > time::now();

        IF array::len($request) = 0 {
            THROW 'request-not-found-error'
        };

        IF array::len($roles) = 0 {
            THROW 'roles-required-error'
        };

        LET $valid = SELECT * FROM $roles WHERE organization = $org;
        IF array::len($valid) != array::len(array::distinct($roles)) {
            THROW 'roles-not-found-error'
        };

        IF array::any($valid, |$r| !$r.assignable) {
            THROW 'roles-not-assignable-error'
        };

        IF array::len(SELECT * FROM member_of WHERE in = $request[0].user.id AND out = $org) > 0 {
            THROW 'user-already-member-error'
        };

        LET $member = RELATE ONLY $request[0].user.id->member_of->$org SET roles = $roles;

        DELETE $request[0].id;

        RETURN {
            request: $request[0],
            member: (
                SELECT
                    in.id AS user_id,
                    in.name AS name,
                    in.email AS email,
                    in.avatar_url AS avatar_url,
                    roles.* AS roles,
                    joined_at
                FROM ONLY $member
                FETCH roles
            )
        };
        COMMIT TRANSACTION;"#,
    )
    .bind(
        "request",
        surrealdb_component_sdk::RecordId::from(&request_id),
    )
    .bind(
        "org",
        surrealdb_component_sdk::RecordId::new("organization", org_id),
    )
    .bind("roles", roles)
    .execute()
    .await
    .error_with_slug("join-request-approve-query-failed")?
    .parse_result::<ApprovalRecord>(0)
    .error_with_slug("join-request-approve-result-parse-failed")?;

    if let Err(slug) = &result {
        otel_wasi::main_attribute!("join_request.outcome" = slug.clone());
    }
    let approved = wasmcloud_utils::skir_domain_result!(ApproveOrganizationJoinRequestResponse, result,
        "request-not-found-error" => { request_id: request_id.clone() },
        "roles-not-found-error" => { role_ids: role_ids.clone() },
        "roles-not-assignable-error" => { role_ids: role_ids.clone() },
        "user-already-member-error" => { user_id: requester_id.clone() }
    );

    let member: OrganizationMember = approved.member.into();

    let user_id = approved.request.user.id.key.to_string();

    wasmcloud_utils::skir_subjects::organization_join_requests(&org_id)
        .publish(WatchOrganizationJoinRequestsResponse::Remove(Box::new(
            request_id.clone(),
        )))
        .await?;

    wasmcloud_utils::skir_subjects::user_join_requests(&user_id)
        .publish(WatchUserJoinRequestsResponse::Remove(Box::new(request_id)))
        .await?;

    wasmcloud_utils::skir_subjects::organization_members(&org_id)
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
    let request_id = req.request_id.clone();
    otel_wasi::main_attribute!(
        "actor.id" = actor_id.to_string(),
        "organization.id" = org_id.to_string(),
        "request.id" = request_id.key.to_string()
    );

    let row = query(
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
    .bind(
        "request",
        surrealdb_component_sdk::RecordId::from(&request_id),
    )
    .bind(
        "org",
        surrealdb_component_sdk::RecordId::new("organization", org_id),
    )
    .execute()
    .await
    .error_with_slug("join-request-decline-query-failed")?
    .parse_result::<Option<JoinRequestProjection>>(0)
    .error_with_slug("join-request-decline-result-parse-failed")?;

    if let Err(slug) = &row {
        otel_wasi::main_attribute!("join_request.outcome" = slug.clone());
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

    wasmcloud_utils::skir_subjects::organization_join_requests(&org_id)
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
