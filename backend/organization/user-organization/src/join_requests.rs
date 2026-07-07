use std::collections::HashMap;

use otel_wasi::ResultWithSlug;
use serde::{Deserialize, Serialize};
use surrealdb_component_sdk::{Datetime, query};
use wasmcloud_utils::{
    decode_skir, extract_param,
    skir::base::{
        kernel::v1::record_id::RecordId,
        organization::v1::{
            join_request::{
                AutoAcceptedMember, CancelJoinRequestRequest, CancelJoinRequestResponse,
                CancelJoinRequestResponse_RequestNotFoundError, CancelJoinRequestResponse_Success,
                RequestToJoinRequest, RequestToJoinResponse,
                RequestToJoinResponse_CodeNotFoundError, UserJoinRequest,
                WatchUserJoinRequestsRequest, WatchUserJoinRequestsResponse,
            },
            member::Role,
        },
    },
    skir_domain_result,
    wasmcloud::messaging::types::BrokerMessage,
};

use crate::OrganizationRecord;

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct UserJoinRequestRecord {
    id: surrealdb_component_sdk::RecordId,
    organization: OrganizationRecord,
    requested_at: Datetime,
    expires_at: Datetime,
}

impl From<UserJoinRequestRecord> for UserJoinRequest {
    fn from(value: UserJoinRequestRecord) -> Self {
        UserJoinRequest {
            request_id: value.id.into(),
            organization_id: value.organization.id.into(),
            organization_name: value.organization.name,
            organization_logo_url: value.organization.logo_url,
            requested_at: value.requested_at.into(),
            expires_at: value.expires_at.into(),
            _unrecognized: None,
        }
    }
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct JoinRequestCodeData {
    organization: OrganizationRecord,
    single_use: bool,
    auto_accept_roles: Vec<surrealdb_component_sdk::RecordId>,
}

#[derive(Debug, Serialize, Deserialize)]
struct MemberRolesResult {
    roles: Vec<RoleRecord>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct RoleRecord {
    id: surrealdb_component_sdk::RecordId,
    name: String,
    color: i64,
    default_role: bool,
    assignable: bool,
    deletable: bool,
}

impl From<RoleRecord> for Role {
    fn from(value: RoleRecord) -> Self {
        Role {
            role_id: value.id.into(),
            name: value.name,
            color: value.color.into(),
            default_role: value.default_role,
            assignable: value.assignable,
            deletable: value.deletable,
            _unrecognized: None,
        }
    }
}

pub async fn handle_watch(
    msg: BrokerMessage,
    params: HashMap<String, String>,
) -> Result<WatchUserJoinRequestsResponse, otel_wasi::Error> {
    let user_id = extract_param!(params, user_id)?;
    let _request = decode_skir!(WatchUserJoinRequestsRequest, &msg.body)?;

    let join_requests = query(
        r#"
        SELECT
            id,
            out.* as organization,
            requested_at,
            expires_at
        FROM request_to_join
        WHERE in = type::thing('user', $user_id)
          AND expires_at > time::now()
        "#,
    )
    .bind("user_id", user_id)
    .execute()
    .await
    .error_with_slug("join-request-watch-query-failed")?
    .take::<Vec<UserJoinRequestRecord>>(0)
    .error_with_slug("join-request-watch-result-parse-failed")?
    .into_iter()
    .map(UserJoinRequest::from)
    .collect::<Vec<_>>();

    Ok(WatchUserJoinRequestsResponse::List(join_requests))
}

pub async fn handle_request(
    msg: BrokerMessage,
    params: HashMap<String, String>,
) -> Result<RequestToJoinResponse, otel_wasi::Error> {
    let user_id = extract_param!(params, user_id)?;
    let request = decode_skir!(RequestToJoinRequest, &msg.body)?;

    let code = request.code;

    let Some(join_code) = fetch_join_code(&code).await? else {
        return Ok(RequestToJoinResponse::CodeNotFoundError(Box::new(
            RequestToJoinResponse_CodeNotFoundError {
                code,
                _unrecognized: None,
            },
        )));
    };

    let org = join_code.organization;
    let single_use = join_code.single_use;
    let auto_accept_roles = join_code.auto_accept_roles;

    if !auto_accept_roles.is_empty() {
        handle_auto_accept(&user_id, &org, &code, single_use, &auto_accept_roles).await
    } else {
        handle_manual_accept(&user_id, &org.id, &code, single_use).await
    }
}

async fn fetch_join_code(code: &RecordId) -> Result<Option<JoinRequestCodeData>, otel_wasi::Error> {
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
    .bind(
        "code",
        surrealdb_component_sdk::RecordId::from(code.clone()),
    )
    .execute()
    .await
    .error_with_slug("join-request-code-query-failed")?
    .take(0)
    .error_with_slug("join-request-code-result-parse-failed")
}

async fn handle_auto_accept(
    user_id: &str,
    org: &OrganizationRecord,
    code: &RecordId,
    single_use: bool,
    auto_accept_roles: &[surrealdb_component_sdk::RecordId],
) -> Result<RequestToJoinResponse, otel_wasi::Error> {
    let result = query(
        r#"
        BEGIN TRANSACTION;

        LET $user = type::thing('user', $user_id);

        IF $single_use {
            DELETE $code;
        };

        LET $existing_member = SELECT * FROM member_of
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
            roles.* AS roles
        FROM ONLY $member
        FETCH roles;

        COMMIT TRANSACTION;
        "#,
    )
    .bind("user_id", user_id)
    .bind("org", org.id.clone())
    .bind(
        "code",
        surrealdb_component_sdk::RecordId::from(code.clone()),
    )
    .bind("single_use", single_use)
    .bind("auto_accept_roles", auto_accept_roles)
    .execute()
    .await
    .error_with_slug("join-request-auto-accept-query-failed")?
    .parse_result::<MemberRolesResult>(0)
    .error_with_slug("join-request-auto-accept-result-parse-failed")?;

    let member_roles = skir_domain_result!(RequestToJoinResponse, result).roles;
    let roles = member_roles.into_iter().map(Role::from).collect::<Vec<_>>();

    // TODO: Send refreshment updates for member list, join codes, and user's organization list.

    Ok(RequestToJoinResponse::AutoAccepted(Box::new(
        AutoAcceptedMember {
            organization_id: org.id.clone().into(),
            organization_name: org.name.clone(),
            organization_logo_url: Some(org.logo_url.clone()),
            roles,
            _unrecognized: None,
        },
    )))
}

async fn handle_manual_accept(
    user_id: &str,
    org_id: &surrealdb_component_sdk::RecordId,
    code: &RecordId,
    single_use: bool,
) -> Result<RequestToJoinResponse, otel_wasi::Error> {
    let result = query(
        r#"
        BEGIN TRANSACTION;

        LET $user = type::thing('user', $user_id);

        IF $single_use {
            DELETE $code;
        };

        LET $existing_member = SELECT * FROM member_of
            WHERE in = $user AND out = $org;
        IF array::len($existing_member) > 0 {
            THROW "already-member-error";
        };

        LET $existing_requests = SELECT * FROM request_to_join
            WHERE in = $user AND expires_at > time::now()
            GROUP ALL;

        IF array::len($existing_requests) >= 5 {
            THROW "max-pending-requests-error";
        };

        IF array::any($existing_requests, |$r| $r.out == $org) {
            THROW "pending-request-exists-error";
        };

        LET $request = RELATE ONLY $user->request_to_join->$org;

        RETURN SELECT
            id,
            out.* as organization,
            requested_at,
            expires_at
        FROM ONLY $request;

        COMMIT TRANSACTION;
        "#,
    )
    .bind("user_id", user_id)
    .bind("org", org_id.clone())
    .bind(
        "code",
        surrealdb_component_sdk::RecordId::from(code.clone()),
    )
    .bind("single_use", single_use)
    .execute()
    .await
    .error_with_slug("join-request-create-query-failed")?
    .parse_result::<UserJoinRequestRecord>(0)
    .error_with_slug("join-request-create-result-parse-failed")?;

    let request_record = skir_domain_result!(RequestToJoinResponse, result);

    // TODO: Send refreshment updates for member list, join requests list, join codes, and user's join requests list and user's organization list.

    Ok(RequestToJoinResponse::RequestMade(Box::new(
        request_record.into(),
    )))
}

pub async fn handle_cancel(
    msg: BrokerMessage,
    params: HashMap<String, String>,
) -> Result<CancelJoinRequestResponse, otel_wasi::Error> {
    let user_id = extract_param!(params, user_id)?;
    let request = decode_skir!(CancelJoinRequestRequest, &msg.body)?;

    let request_id = request.request_id;

    let join_request = query(
        r#"
            BEGIN TRANSACTION;

            LET $request = SELECT id, out.* as organization, requested_at, expires_at FROM $request
            WHERE in = type::thing('user', $user_id);

            DELETE $request.id;

            RETURN $request;
            COMMIT TRANSACTION;
            "#,
    )
    .bind(
        "request",
        surrealdb_component_sdk::RecordId::from(request_id.clone()),
    )
    .bind("user_id", user_id)
    .execute()
    .await
    .error_with_slug("join-request-cancel-query-failed")?
    .take::<Option<UserJoinRequestRecord>>(0)
    .error_with_slug("join-request-cancel-result-parse-failed")?;

    let Some(_join_request) = join_request else {
        return Ok(CancelJoinRequestResponse::RequestNotFoundError(Box::new(
            CancelJoinRequestResponse_RequestNotFoundError {
                request_id,
                _unrecognized: None,
            },
        )));
    };

    // TODO: refresh members join quests list, users's join requests list

    Ok(CancelJoinRequestResponse::Success(Box::new(
        CancelJoinRequestResponse_Success {
            _unrecognized: None,
        },
    )))
}
