use std::collections::HashMap;

use prost::Message;
use surrealdb_component::query;
use wasmcloud_component::{debug, info, trace};
use wasmcloud_utils::{
    error_response_bytes, internal_error_fn,
    wasmcloud::messaging::{reply, send, types::BrokerMessage},
};

use crate::{refresh, typewriter, UserJoinRequestRecord};

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

pub fn handle_list(msg: BrokerMessage, params: HashMap<String, String>) -> Result<(), String> {
    debug!("handle_list (user join_requests) invoked");
    let user_id = params
        .get("user_id")
        .ok_or("failed to parse user_id from subject")?;
    debug!("Parsed user_id: {}", user_id);

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
    trace!("handle_request (user join_requests) invoked");
    let user_id = params
        .get("user_id")
        .ok_or("failed to parse user_id from subject")?;
    trace!("Parsed user_id: {}", user_id);

    let request = typewriter::api::v1::RequestToJoinRequest::decode(&msg.body[..])
        .map_err(|e| format!("failed to decode request: {}", e))?;
    trace!("Decoded RequestToJoinRequest: {:?}", request);

    let code = request.code;

    info!("User '{}' requesting to join with code '{}'", user_id, code);

    // Look up the join code and create a join request
    let result = query(
        r#"
        BEGIN TRANSACTION;
        LET $join_code = SELECT * FROM type::thing('join_code', $code)
            WHERE expires_at > time::now()
            FETCH organization;

        IF array::len($join_code) == 0 {
            THROW "Invalid or expired join code";
        };

        LET $org = $join_code[0].organization;
        LET $user = type::thing('user', $user_id);

        LET $existing_member = SELECT * FROM member_of
            WHERE in = $user AND out = $org.id;
        IF array::len($existing_member) > 0 {
            THROW "User is already a member of this organization";
        };

        LET $existing_requests = SELECT * FROM requests_to_join
            WHERE in = $user AND expires_at > time::now()
            GROUP ALL;

        IF array::len($existing_requests) >= 5 {
            THROW "User already has maximum pending requests";
        };

        IF array::any($existing_requests, |$r| $r.out == $org.id) {
            THROW "User already has a pending join request for this organization";
        };

        LET $request = RELATE ONLY $user->requests_to_join->$org.id;
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
    .bind("code", &code)
    .execute()
    .map_err(|e| format!("failed to create join request: {}", e))?;
    trace!("Transaction executed successfully");

    let request_record: Result<UserJoinRequestRecord, String> = result
        .parse_result(0)
        .map_err(|e| format!("failed to parse result: {}", e))?;

    if let Err(e) = request_record {
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

    let request_record = request_record.unwrap();

    trace!("Created join request record: {:?}", request_record);

    let join_request = request_record.into_proto();
    let org_id = join_request.organization_id.clone();

    let response = typewriter::api::v1::RequestToJoinResponse {
        result: Some(typewriter::api::v1::request_to_join_response::Result::Request(join_request)),
    };
    trace!("Prepared RequestToJoinResponse");

    reply(msg, response.encode_to_vec())?;

    refresh::refresh_organization_members_list(&org_id, Some(user_id))?;
    refresh::refresh_members_join_requests_list(&org_id, Some(user_id))?;
    refresh::refresh_organization_members_join_codes_list(&org_id, Some(user_id))?;
    refresh::refresh_user_organization_join_requests_list(user_id)?;
    refresh::refresh_user_organization_list(user_id)?;

    Ok(())
}

pub fn handle_cancel(msg: BrokerMessage, params: HashMap<String, String>) -> Result<(), String> {
    debug!("handle_cancel (user join_requests) invoked");
    let user_id = params
        .get("user_id")
        .ok_or("failed to parse user_id from subject")?;
    debug!("Parsed user_id: {}", user_id);

    let request = typewriter::api::v1::CancelJoinRequestRequest::decode(&msg.body[..])
        .map_err(|e| format!("failed to decode request: {}", e))?;
    trace!("Decoded CancelJoinRequestRequest: {:?}", request);

    let request_id = request.request_id;

    info!("User '{}' canceling join request '{}'", user_id, request_id);

    // Delete the join request (only if it belongs to this user)
    let result = query(
        r#"
        BEGIN TRANSACTION;

        LET $request = SELECT id, out.* as organization, requested_at, expires_at FROM  type::thing('requests_to_join', $request_id)
        WHERE in = type::thing('user', $user_id)
        FETCH out;

        DELETE $request.id;

        RETURN VALUE $request;
        COMMIT TRANSACTION;
        "#,
    )
    .bind("request_id", &request_id)
    .bind("user_id", user_id)
    .execute()
    .map_err(|e| format!("failed to cancel join request: {}", e))?;
    trace!("Delete executed successfully");

    let response = typewriter::api::v1::CancelJoinRequestResponse {
        result: Some(typewriter::api::v1::cancel_join_request_response::Result::Success(true)),
    };
    trace!("Prepared CancelJoinRequestResponse");

    reply(msg, response.encode_to_vec())?;

    let join_request: UserJoinRequestRecord = result
        .parse(0)
        .map_err(|e| format!("failed to fetch join request: {}", e))?;

    let org_id = join_request.organization.id.id;

    refresh::refresh_members_join_requests_list(&org_id, Some(user_id))?;
    refresh::refresh_user_organization_join_requests_list(user_id)?;

    Ok(())
}
