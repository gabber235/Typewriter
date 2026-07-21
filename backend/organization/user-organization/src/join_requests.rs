use std::collections::HashMap;

use otel_wasi::ResultWithSlug;
use serde::{Deserialize, Serialize};
use surrealdb_component_sdk::query;
use wasmcloud_utils::{
    decode_skir, extract_param,
    skir::base::{
        kernel::v1::record_id::RecordId,
        organization::v1::{
            join_codes::*, join_request::*, member::*, role::OrganizationRole, user::*,
        },
    },
    skir_domain_result, skir_variant,
    wasmcloud::messaging::types::BrokerMessage,
};

use wasmcloud_utils::database::organization::{
    OrganizationRecord,
    projections::{JoinRequestProjection, OrganizationMemberProjection},
};

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct JoinRequestCodeRecord {
    organization: OrganizationRecord,
    single_use: bool,
    auto_accept_roles: Vec<surrealdb_component_sdk::RecordId>,
}

#[tracing::instrument(skip(msg, params))]
pub async fn handle_watch(
    msg: BrokerMessage,
    params: HashMap<String, String>,
) -> Result<WatchUserJoinRequestsResponse, otel_wasi::Error> {
    let user_id = extract_param!(params, user_id)?;
    otel_wasi::main_attribute!("user.id" = user_id.to_string());
    let _request = decode_skir!(WatchUserJoinRequestsRequest, &msg.body)?;

    let join_requests = query(
        r#"
        SELECT
            id,
            in.* as user,
            out.* as organization,
            requested_at,
            expires_at
        FROM request_to_join
        WHERE in = type::record('user', $user_id)
          AND expires_at > time::now()
        "#,
    )
    .bind("user_id", user_id)
    .execute()
    .await
    .error_with_slug("join-request-watch-query-failed")?
    .take::<Vec<JoinRequestProjection>>(0)
    .error_with_slug("join-request-watch-result-parse-failed")?
    .into_iter()
    .map(UserJoinRequest::from)
    .collect::<Vec<_>>();

    otel_wasi::main_attribute!(
        "join_request.result_count" = join_requests.len() as i64,
        "join_request.outcome" = "listed"
    );
    Ok(WatchUserJoinRequestsResponse::List(join_requests))
}

#[tracing::instrument(skip(msg, params))]
pub async fn handle_request(
    msg: BrokerMessage,
    params: HashMap<String, String>,
) -> Result<SubmitUserJoinRequestResponse, otel_wasi::Error> {
    let user_id = extract_param!(params, user_id)?;
    otel_wasi::main_attribute!("user.id" = user_id.to_string());
    let request = decode_skir!(SubmitUserJoinRequestRequest, &msg.body)?;
    wasmcloud_utils::validate_record_ids!(
        SubmitUserJoinRequestResponse,
        request.code,
        "organization_join_code"
    );

    let code = request.code;

    let Some(join_code) = fetch_join_code(&code).await? else {
        otel_wasi::main_attribute!("join_request.outcome" = "code_not_found");
        return Ok(skir_variant!(
            SubmitUserJoinRequestResponse::CodeNotFoundError { code }
        ));
    };

    let org = join_code.organization;
    let single_use = join_code.single_use;
    let auto_accept_roles = join_code.auto_accept_roles;
    otel_wasi::main_attribute!(
        "organization.id" = org.id.key.to_string(),
        "join_request.single_use" = single_use,
        "join_request.acceptance_mode" = if auto_accept_roles.is_empty() {
            "manual"
        } else {
            "automatic"
        },
        "join_request.auto_accept_role_count" = auto_accept_roles.len() as i64
    );

    if !auto_accept_roles.is_empty() {
        handle_auto_accept(user_id, &org, &code, single_use, &auto_accept_roles).await
    } else {
        handle_manual_accept(user_id, &org.id, &code, single_use).await
    }
}

#[tracing::instrument(skip(code))]
async fn fetch_join_code(
    code: &RecordId,
) -> Result<Option<JoinRequestCodeRecord>, otel_wasi::Error> {
    query(
        r#"
        SELECT
            organization.*,
            single_use,
            auto_accept_roles
        FROM $code
        WHERE expires_at IS NONE OR expires_at > time::now()
        "#,
    )
    .bind("code", surrealdb_component_sdk::RecordId::from(code))
    .execute()
    .await
    .error_with_slug("join-request-code-query-failed")?
    .take(0)
    .error_with_slug("join-request-code-result-parse-failed")
}

#[tracing::instrument(skip(user_id, org, code, auto_accept_roles))]
async fn handle_auto_accept(
    user_id: &str,
    org: &OrganizationRecord,
    code: &RecordId,
    single_use: bool,
    auto_accept_roles: &[surrealdb_component_sdk::RecordId],
) -> Result<SubmitUserJoinRequestResponse, otel_wasi::Error> {
    let result = query(
        r#"
        BEGIN TRANSACTION;

        LET $user = type::record('user', $user_id);

        IF $single_use {
            DELETE $code;
        };

        LET $existing_member = SELECT id FROM member_of
            WHERE in = $user AND out = $org;
        IF array::len($existing_member) > 0 {
            THROW "already-member-error";
        };

        LET $valid_roles = SELECT VALUE id FROM $auto_accept_roles
            WHERE organization = $org AND assignable;

        LET $roles = IF array::len($valid_roles) > 0 {
            $valid_roles
        } ELSE {
            SELECT VALUE id FROM role WHERE organization = $org AND default_role = true
        };

        IF array::len($roles) == 0 {
            THROW "no-assignable-roles-error";
        };

        LET $member = RELATE ONLY $user->member_of->$org SET
            roles = $roles;

        RETURN SELECT
            in.id AS user_id,
            in.name AS name,
            in.email AS email,
            in.avatar_url AS avatar_url,
            roles.* AS roles,
            joined_at
        FROM ONLY $member
        FETCH roles;

        COMMIT TRANSACTION;
        "#,
    )
    .bind("user_id", user_id)
    .bind("org", org.id.clone())
    .bind("code", surrealdb_component_sdk::RecordId::from(code))
    .bind("single_use", single_use)
    .bind("auto_accept_roles", auto_accept_roles)
    .execute()
    .await
    .error_with_slug("join-request-auto-accept-query-failed")?
    .parse_result::<OrganizationMemberProjection>(9)
    .error_with_slug("join-request-auto-accept-result-parse-failed")?;

    let member = skir_domain_result!(SubmitUserJoinRequestResponse, result);
    let roles = member
        .roles
        .clone()
        .into_iter()
        .map(OrganizationRole::from)
        .collect::<Vec<_>>();

    wasmcloud_utils::skir_subjects::user_organizations(user_id)
        .publish(WatchUserOrganizationsResponse::Add(Box::new(
            org.clone().into(),
        )))
        .await?;

    wasmcloud_utils::skir_subjects::organization_members(org.id.key.to_string())
        .publish(WatchOrganizationMembersResponse::Add(Box::new(
            member.into(),
        )))
        .await?;

    if single_use {
        wasmcloud_utils::skir_subjects::organization_join_codes(org.id.key.to_string())
            .publish(WatchOrganizationJoinCodesResponse::Remove(
                code.clone().into(),
            ))
            .await?;
    }

    otel_wasi::main_attribute!("join_request.outcome" = "auto_accepted");
    Ok(SubmitUserJoinRequestResponse::AutoAccepted(Box::new(
        AutoAcceptedMember {
            organization_id: org.id.clone().into(),
            organization_name: org.name.clone(),
            organization_logo_url: org.logo_url.clone(),
            roles,
            _unrecognized: None,
        },
    )))
}

#[tracing::instrument(skip(user_id, org_id, code))]
async fn handle_manual_accept(
    user_id: &str,
    org_id: &surrealdb_component_sdk::RecordId,
    code: &RecordId,
    single_use: bool,
) -> Result<SubmitUserJoinRequestResponse, otel_wasi::Error> {
    let result = query(
        r#"
        BEGIN TRANSACTION;

        LET $user = type::record('user', $user_id);

        IF $single_use {
            DELETE $code;
        };

        LET $existing_member = SELECT id FROM member_of
            WHERE in = $user AND out = $org;
        IF array::len($existing_member) > 0 {
            THROW "already-member-error";
        };

        LET $existing_requests = SELECT out FROM request_to_join
            WHERE in = $user AND expires_at > time::now();

        IF array::len($existing_requests) >= 5 {
            THROW "max-pending-requests-error";
        };

        IF array::any($existing_requests, |$r| $r.out == $org) {
            THROW "pending-request-exists-error";
        };

        LET $request = RELATE ONLY $user->request_to_join->$org;

        RETURN SELECT
            id,
            in.* as user,
            out.* as organization,
            requested_at,
            expires_at
        FROM ONLY $request;

        COMMIT TRANSACTION;
        "#,
    )
    .bind("user_id", user_id)
    .bind("org", org_id.clone())
    .bind("code", surrealdb_component_sdk::RecordId::from(code))
    .bind("single_use", single_use)
    .execute()
    .await
    .error_with_slug("join-request-create-query-failed")?
    .parse_result::<JoinRequestProjection>(9)
    .error_with_slug("join-request-create-result-parse-failed")?;

    let request_record = skir_domain_result!(SubmitUserJoinRequestResponse, result);

    wasmcloud_utils::skir_subjects::user_join_requests(user_id)
        .publish(WatchUserJoinRequestsResponse::Add(Box::new(
            request_record.clone().into(),
        )))
        .await?;

    wasmcloud_utils::skir_subjects::organization_join_requests(org_id.key.to_string())
        .publish(WatchOrganizationJoinRequestsResponse::Add(Box::new(
            request_record.clone().into(),
        )))
        .await?;

    if single_use {
        wasmcloud_utils::skir_subjects::organization_join_codes(org_id.key.to_string())
            .publish(WatchOrganizationJoinCodesResponse::Remove(
                code.clone().into(),
            ))
            .await?;
    }

    otel_wasi::main_attribute!("join_request.outcome" = "request_made");
    Ok(SubmitUserJoinRequestResponse::RequestMade(Box::new(
        request_record.into(),
    )))
}

#[tracing::instrument(skip(msg, params))]
pub async fn handle_cancel(
    msg: BrokerMessage,
    params: HashMap<String, String>,
) -> Result<CancelUserJoinRequestResponse, otel_wasi::Error> {
    let user_id = extract_param!(params, user_id)?;
    otel_wasi::main_attribute!("user.id" = user_id.to_string());
    let request = decode_skir!(CancelUserJoinRequestRequest, &msg.body)?;
    wasmcloud_utils::validate_record_ids!(
        CancelUserJoinRequestResponse,
        request.request_id,
        "request_to_join"
    );

    let request_id = request.request_id;

    let join_request = query(
        r#"
            BEGIN TRANSACTION;

            LET $request = SELECT id, in.* as user, out.* as organization, requested_at, expires_at FROM $request
            WHERE in = type::record('user', $user_id);

            DELETE $request.id;

            RETURN $request;
            COMMIT TRANSACTION;
            "#,
    )
    .bind(
        "request",
        surrealdb_component_sdk::RecordId::from(&request_id),
    )
    .bind("user_id", user_id)
    .execute()
    .await
    .error_with_slug("join-request-cancel-query-failed")?
    .take::<Option<JoinRequestProjection>>(3)
    .error_with_slug("join-request-cancel-result-parse-failed")?;

    let Some(join_request) = join_request else {
        otel_wasi::main_attribute!("join_request.outcome" = "request_not_found");
        return Ok(skir_variant!(
            CancelUserJoinRequestResponse::RequestNotFoundError { request_id }
        ));
    };

    wasmcloud_utils::skir_subjects::user_join_requests(user_id)
        .publish(WatchUserJoinRequestsResponse::Remove(Box::new(
            join_request.id.clone().into(),
        )))
        .await?;

    wasmcloud_utils::skir_subjects::organization_join_requests(
        join_request.organization.id.key.to_string(),
    )
    .publish(WatchOrganizationJoinRequestsResponse::Remove(Box::new(
        join_request.id.into(),
    )))
    .await?;

    otel_wasi::main_attribute!(
        "organization.id" = join_request.organization.id.key.to_string(),
        "join_request.outcome" = "cancelled"
    );
    Ok(skir_variant!(CancelUserJoinRequestResponse::Success))
}
