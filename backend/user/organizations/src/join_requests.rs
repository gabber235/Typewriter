use std::collections::HashMap;

use prost::Message;
use serde::{Deserialize, Serialize};
use surrealdb_component::{query, RecordId};
use wasmcloud_component::{debug, info, trace};
use wasmcloud_utils::{
    error_response_bytes, extract_param, internal_error_fn,
    wasmcloud::messaging::{reply, types::BrokerMessage},
};

use crate::{
    refresh,
    typewriter::{self, api::v1::CancelJoinRequestResponse},
    UserJoinRequestRecord,
};

internal_error_fn!(
    internal_error_list,
    typewriter::api::v1::ListUserJoinRequestsResponse,
    list_user_join_requests_response,
    "Internal Server Error when listing join requests"
);

internal_error_fn!(
    internal_error_request,
    typewriter::api::v1::RequestToJoinResponse,
    request_to_join_response,
    "Internal Server Error when requesting to join"
);

internal_error_fn!(
    internal_error_cancel,
    typewriter::api::v1::CancelJoinRequestResponse,
    cancel_join_request_response,
    "Internal Server Error when canceling join request"
);

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct JoinCodeData {
    organization: crate::OrganizationRecord,
    single_use: bool,
    auto_accept_roles: Vec<RecordId>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct RoleRecord {
    id: RecordId,
    name: String,
    color: i64,
    default_role: bool,
    assignable: bool,
    deletable: bool,
}

impl From<RoleRecord> for typewriter::models::v1::Role {
    fn from(record: RoleRecord) -> Self {
        typewriter::models::v1::Role {
            id: record.id.id.to_string(),
            name: record.name,
            color: record.color as u32,
            default_role: record.default_role,
            assignable: record.assignable,
            deletable: record.deletable,
        }
    }
}

#[derive(Debug, Serialize, Deserialize)]
struct MemberRolesResult {
    roles: Vec<RoleRecord>,
}

pub fn handle_list(msg: BrokerMessage, params: HashMap<String, String>) -> Result<(), String> {
    debug!("handle_list (user join_requests) invoked");
    let user_id = extract_param!(params, user_id);

    let _request = typewriter::api::v1::ListUserJoinRequestsRequest::decode(&msg.body[..])
        .map_err(|e| format!("failed to decode request: {}", e))?;
    trace!("Decoded ListUserJoinRequestsRequest");

    let result = query(
        r#"
        SELECT
            id,
            out.* as organization,
            requested_at,
            expires_at
        FROM requests_to_join
        WHERE in = type::thing('user', $user_id)
          AND expires_at > time::now()
        FETCH out
        "#,
    )
    .bind("user_id", user_id)
    .execute()
    .map_err(|e| format!("failed to query join requests: {}", e))?;
    trace!("Query executed successfully");

    let requests_data: Vec<UserJoinRequestRecord> = result
        .take(0)
        .map_err(|e| format!("failed to take result: {}", e))?;
    trace!("Fetched join requests data: {:?}", requests_data);

    let requests: Vec<typewriter::models::v1::UserJoinRequest> = requests_data
        .into_iter()
        .map(|record| record.into_proto())
        .collect();
    trace!("Converted to UserJoinRequest structs: {:?}", requests);

    let response = typewriter::api::v1::ListUserJoinRequestsResponse {
        result: Some(
            typewriter::api::v1::list_user_join_requests_response::Result::Requests(
                typewriter::api::v1::ListUserJoinRequests { requests },
            ),
        ),
    };
    trace!("Prepared ListUserJoinRequestsResponse");

    reply(msg, response.encode_to_vec())
}

pub fn handle_request(msg: BrokerMessage, params: HashMap<String, String>) -> Result<(), String> {
    debug!("handle_request (user join_requests) invoked");
    let user_id = extract_param!(params, user_id);

    let request = decode_join_request(&msg)?;
    let code = request.code.clone();

    info!("User '{}' requesting to join with code '{}'", user_id, code);

    let Some(join_code) = fetch_join_code(&code)? else {
        debug!(
            "User {} tried to join with an invalid or expired join code",
            user_id
        );
        return reply(
            msg,
            error_response_bytes!(
                typewriter::api::v1::RequestToJoinResponse,
                request_to_join_response,
                403,
                "Invalid or expired join code"
            ),
        );
    };

    let org = join_code.organization;
    let org_id = org.id.id.to_string();
    let single_use = join_code.single_use;
    let auto_accept_roles = join_code.auto_accept_roles;

    trace!(
        "Join code data: single_use={}, auto_accept_roles={:?}",
        single_use,
        auto_accept_roles
    );

    if !auto_accept_roles.is_empty() {
        handle_auto_accept(
            msg,
            &user_id,
            &org,
            &org_id,
            &code,
            single_use,
            &auto_accept_roles,
        )
    } else {
        handle_join_request(msg, &user_id, &org_id, &code, single_use)
    }
}

fn decode_join_request(
    msg: &BrokerMessage,
) -> Result<typewriter::api::v1::RequestToJoinRequest, String> {
    typewriter::api::v1::RequestToJoinRequest::decode(&msg.body[..])
        .map_err(|e| format!("failed to decode request: {}", e))
}

fn fetch_join_code(code: &str) -> Result<Option<JoinCodeData>, String> {
    let result = query(
        r#"
        SELECT
            organization.*,
            single_use,
            auto_accept_roles
        FROM type::thing('join_code', $code)
        WHERE expires_at IS NONE OR expires_at > time::now()
        FETCH organization
        "#,
    )
    .bind("code", code)
    .execute()
    .map_err(|e| format!("failed to query join code: {}", e))?;

    result
        .take(0)
        .map_err(|e| format!("failed to take join code result: {}", e))
}

fn handle_auto_accept(
    msg: BrokerMessage,
    user_id: &str,
    org: &crate::OrganizationRecord,
    org_id: &str,
    code: &str,
    single_use: bool,
    auto_accept_roles: &[RecordId],
) -> Result<(), String> {
    let result = query(
        r#"
        BEGIN TRANSACTION;

        LET $user = type::thing('user', $user_id);
        LET $org = type::thing('organization', $org_id);

        IF $single_use {
            DELETE type::thing('join_code', $code);
        };

        LET $existing_member = SELECT * FROM member_of
            WHERE in = $user AND out = $org;
        IF array::len($existing_member) > 0 {
            THROW "User is already a member of this organization";
        };

        LET $valid_roles = SELECT VALUE id FROM $auto_accept_role_ids.map(|$id| type::thing('role', $id))
            WHERE organization = $org;

        LET $roles = IF array::len($valid_roles) > 0 {
            $valid_roles
        } ELSE {
            SELECT VALUE id FROM role WHERE organization = $org AND default_role = true
        };

        IF array::len($roles) == 0 {
            THROW "No roles available for this organization";
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
    .bind("org_id", org_id)
    .bind("code", code)
    .bind("single_use", single_use)
    .bind(
        "auto_accept_role_ids",
        auto_accept_roles
            .iter()
            .map(|r| r.id.to_string())
            .collect::<Vec<_>>(),
    )
    .execute()
    .map_err(|e| format!("failed to auto-accept member: {}", e))?;

    trace!("Auto-accept transaction executed successfully");

    let member_result: Result<MemberRolesResult, String> = result
        .parse_result(0)
        .map_err(|e| format!("failed to parse result: {}", e))?;

    let member_roles = match member_result {
        Ok(r) => r,
        Err(e) => {
            debug!("Failed to auto-accept member: {}", e);
            return reply(
                msg,
                error_response_bytes!(
                    typewriter::api::v1::RequestToJoinResponse,
                    request_to_join_response,
                    403,
                    e
                ),
            );
        }
    };

    trace!("Auto-accepted member with roles: {:?}", member_roles.roles);

    let roles: Vec<typewriter::models::v1::Role> =
        member_roles.roles.into_iter().map(|r| r.into()).collect();

    let auto_accepted_member = typewriter::api::v1::AutoAcceptedMember {
        organization_id: org_id.to_string(),
        organization_name: org.name.clone(),
        organization_icon_url: org.icon_url.clone(),
        roles,
    };

    let response = typewriter::api::v1::RequestToJoinResponse {
        result: Some(
            typewriter::api::v1::request_to_join_response::Result::Success(
                typewriter::api::v1::RequestToJoinResult {
                    outcome: Some(
                        typewriter::api::v1::request_to_join_result::Outcome::Member(
                            auto_accepted_member,
                        ),
                    ),
                },
            ),
        ),
    };
    trace!("Prepared auto-accept RequestToJoinResponse");

    reply(msg, response.encode_to_vec())?;

    // Refresh caches
    refresh::refresh_organization_members_list(org_id, Some(user_id))?;
    refresh::refresh_organization_members_join_codes_list(org_id, Some(user_id))?;
    refresh::refresh_user_organization_list(user_id)?;

    Ok(())
}

fn handle_join_request(
    msg: BrokerMessage,
    user_id: &str,
    org_id: &str,
    code: &str,
    single_use: bool,
) -> Result<(), String> {
    let result = query(
        r#"
        BEGIN TRANSACTION;

        LET $user = type::thing('user', $user_id);
        LET $org = type::thing('organization', $org_id);

        IF $single_use {
            DELETE type::thing('join_code', $code);
        };

        LET $existing_member = SELECT * FROM member_of
            WHERE in = $user AND out = $org;
        IF array::len($existing_member) > 0 {
            THROW "User is already a member of this organization";
        };

        LET $existing_requests = SELECT * FROM requests_to_join
            WHERE in = $user AND expires_at > time::now()
            GROUP ALL;

        IF array::len($existing_requests) >= 5 {
            THROW "User already has maximum pending requests";
        };

        IF array::any($existing_requests, |$r| $r.out == $org) {
            THROW "User already has a pending join request for this organization";
        };

        LET $request = RELATE ONLY $user->requests_to_join->$org;

        RETURN SELECT
            id,
            out.* as organization,
            requested_at,
            expires_at
        FROM ONLY $request
        FETCH out;

        COMMIT TRANSACTION;
        "#,
    )
    .bind("user_id", user_id)
    .bind("org_id", org_id)
    .bind("code", code)
    .bind("single_use", single_use)
    .execute()
    .map_err(|e| format!("failed to create join request: {}", e))?;

    trace!("Join request transaction executed successfully");

    let request_record: Result<UserJoinRequestRecord, String> = result
        .parse_result(0)
        .map_err(|e| format!("failed to parse result: {}", e))?;

    let request_record = match request_record {
        Ok(r) => r,
        Err(e) => {
            debug!("Failed to create join request record: {}", e);
            return reply(
                msg,
                error_response_bytes!(
                    typewriter::api::v1::RequestToJoinResponse,
                    request_to_join_response,
                    403,
                    e
                ),
            );
        }
    };

    trace!("Created join request record: {:?}", request_record);

    let join_request = request_record.into_proto();

    let response = typewriter::api::v1::RequestToJoinResponse {
        result: Some(
            typewriter::api::v1::request_to_join_response::Result::Success(
                typewriter::api::v1::RequestToJoinResult {
                    outcome: Some(
                        typewriter::api::v1::request_to_join_result::Outcome::Request(join_request),
                    ),
                },
            ),
        ),
    };
    trace!("Prepared join request RequestToJoinResponse");

    reply(msg, response.encode_to_vec())?;

    refresh::refresh_organization_members_list(org_id, Some(user_id))?;
    refresh::refresh_members_join_requests_list(org_id, Some(user_id))?;
    refresh::refresh_organization_members_join_codes_list(org_id, Some(user_id))?;
    refresh::refresh_user_organization_join_requests_list(user_id)?;
    refresh::refresh_user_organization_list(user_id)?;

    Ok(())
}

pub fn handle_cancel(msg: BrokerMessage, params: HashMap<String, String>) -> Result<(), String> {
    debug!("handle_cancel (user join_requests) invoked");
    let user_id = extract_param!(params, user_id);

    let request = typewriter::api::v1::CancelJoinRequestRequest::decode(&msg.body[..])
        .map_err(|e| format!("failed to decode request: {}", e))?;
    trace!("Decoded CancelJoinRequestRequest: {:?}", request);

    let request_id = request.request_id;

    info!("User '{}' canceling join request '{}'", user_id, request_id);

    let result = query(
        r#"
        BEGIN TRANSACTION;

        LET $request = SELECT id, out.* as organization, requested_at, expires_at FROM  type::thing('requests_to_join', $request_id)
        WHERE in = type::thing('user', $user_id)
        FETCH out;

        DELETE $request.id;

        RETURN $request;
        COMMIT TRANSACTION;
        "#,
    )
    .bind("request_id", &request_id)
    .bind("user_id", user_id)
    .execute()
    .map_err(|e| format!("failed to cancel join request: {}", e))?;
    trace!("Delete executed successfully");

    let join_request: Option<UserJoinRequestRecord> = result
        .take(0)
        .map_err(|e| format!("failed to fetch join request: {}", e))?;
    let Some(join_request) = join_request else {
        return reply(
            msg,
            error_response_bytes!(
                CancelJoinRequestResponse,
                cancel_join_request_response,
                403,
                "No pending join request found"
            ),
        );
    };

    let response = typewriter::api::v1::CancelJoinRequestResponse {
        result: Some(typewriter::api::v1::cancel_join_request_response::Result::Success(true)),
    };
    trace!("Prepared CancelJoinRequestResponse");

    reply(msg, response.encode_to_vec())?;

    let org_id = join_request.organization.id.id;

    refresh::refresh_members_join_requests_list(&org_id, Some(user_id))?;
    refresh::refresh_user_organization_join_requests_list(user_id)?;

    Ok(())
}
