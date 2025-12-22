use std::collections::HashMap;

use prost::Message;
use surrealdb_component::query;
use wasmcloud_component::{debug, info, trace};
use wasmcloud_utils::{
    error_response_bytes, internal_error_fn,
    wasmcloud::messaging::{reply, types::BrokerMessage},
};

use crate::{typewriter, JoinRequestRecord, MemberWithRolesRecord};

pub fn handle_list(msg: BrokerMessage, params: HashMap<String, String>) -> Result<(), String> {
    debug!("handle_list (join_requests) invoked");
    let org_id = params
        .get("org_id")
        .ok_or("failed to parse org_id from subject")?;
    debug!("Parsed org_id: {}", org_id);

    let _request = typewriter::api::v1::ListJoinRequestsRequest::decode(&msg.body[..])
        .map_err(|e| format!("failed to decode request: {}", e))?;
    trace!("Decoded ListJoinRequestsRequest");

    // Query from the requests_to_join graph relation
    let result = query(
        r#"
        SELECT
            id,
            in.* as user,
            requested_at,
            expires_at
        FROM requests_to_join
        WHERE out = type::thing('organization', $org_id)
          AND expires_at > time::now()
        FETCH in
        "#,
    )
    .bind("org_id", org_id)
    .execute()
    .map_err(|e| format!("failed to query join requests: {}", e))?;
    trace!("Query executed successfully");

    let requests_data: Vec<JoinRequestRecord> = result
        .take(0)
        .map_err(|e| format!("failed to take result: {}", e))?;
    trace!("Fetched join requests data: {:?}", requests_data);

    let requests: Vec<typewriter::models::v1::JoinRequest> = requests_data
        .into_iter()
        .map(|record| record.into())
        .collect();
    trace!("Converted to JoinRequest structs: {:?}", requests);

    let response = typewriter::api::v1::ListJoinRequestsResponse {
        result: Some(
            typewriter::api::v1::list_join_requests_response::Result::Requests(
                typewriter::api::v1::ListJoinRequests { requests },
            ),
        ),
    };
    trace!("Prepared ListJoinRequestsResponse");

    reply(msg, response.encode_to_vec())
}

pub fn handle_approve(msg: BrokerMessage, params: HashMap<String, String>) -> Result<(), String> {
    debug!("handle_approve (join_requests) invoked");
    let org_id = params
        .get("org_id")
        .ok_or("failed to parse org_id from subject")?;
    trace!("Parsed org_id: {}", org_id);

    let request = typewriter::api::v1::ApproveJoinRequestRequest::decode(&msg.body[..])
        .map_err(|e| format!("failed to decode request: {}", e))?;
    trace!("Decoded ApproveJoinRequestRequest: {:?}", request);

    let request_id = request.request_id;
    let role_ids: Vec<String> = request.role_ids;

    info!(
        "Approving join request '{}' with roles {:?}",
        request_id, role_ids
    );

    let result = query(
        r#"
        BEGIN TRANSACTION;

        LET $request = SELECT * FROM type::thing('requests_to_join', $request_id) FETCH in;

        IF array::len($request) == 0 {
            THROW "Join request not found";
        };

        LET $org = type::thing('organization', $org_id);

        IF $request[0].out != $org {
            THROW "Join request is for a different organization";
        };

        LET $user = $request[0].in;

        LET $roles = SELECT VALUE id FROM $role_ids.map(|$id| type::thing('role', $id)) WHERE organization = $org;

        IF array::len($roles) != array::len($role_ids) {
            THROW "Some roles not found for the organization";
        };

        IF array::len($roles) == 0 {
            THROW "No roles found for the organization";
        };

        LET $member = RELATE ONLY $user->member_of->$org SET
            roles = $roles;

        DELETE type::thing('requests_to_join', $request_id);

        RETURN SELECT
            id,
            in.* as user,
            joined_at,
            roles.* AS roles
        FROM ONLY $member
        FETCH in, roles;

        COMMIT TRANSACTION;
        "#,
    )
    .bind("request_id", &request_id)
    .bind("org_id", org_id)
    .bind("role_ids", &role_ids)
    .execute()
    .map_err(|e| format!("failed to approve join request: {}", e))?;
    trace!("Transaction executed successfully");

    let member_record: Result<MemberWithRolesRecord, String> = result
        .parse_result(0)
        .map_err(|e| format!("failed to parse result: {}", e))?;

    if let Err(e) = member_record {
        return reply(
            msg,
            error_response_bytes!(
                typewriter::api::v1::ApproveJoinRequestResponse,
                approve_join_request_response,
                403,
                e
            ),
        );
    }

    let member_record = member_record.unwrap();

    trace!("Created member record: {:?}", member_record);

    let response = typewriter::api::v1::ApproveJoinRequestResponse {
        result: Some(
            typewriter::api::v1::approve_join_request_response::Result::Member(
                member_record.into(),
            ),
        ),
    };
    trace!("Prepared ApproveJoinRequestResponse");

    reply(msg, response.encode_to_vec())
}

pub fn handle_decline(msg: BrokerMessage, params: HashMap<String, String>) -> Result<(), String> {
    debug!("handle_decline (join_requests) invoked");
    let org_id = params
        .get("org_id")
        .ok_or("failed to parse org_id from subject")?;
    debug!("Parsed org_id: {}", org_id);

    let request = typewriter::api::v1::DeclineJoinRequestRequest::decode(&msg.body[..])
        .map_err(|e| format!("failed to decode request: {}", e))?;
    trace!("Decoded DeclineJoinRequestRequest: {:?}", request);

    let request_id = request.request_id;

    info!("Declining join request '{}'", request_id);

    query("DELETE type::thing('requests_to_join', $request_id)")
        .bind("request_id", &request_id)
        .execute()
        .map_err(|e| format!("failed to decline join request: {}", e))?;
    trace!("Delete executed successfully");

    let response = typewriter::api::v1::DeclineJoinRequestResponse {
        result: Some(typewriter::api::v1::decline_join_request_response::Result::Success(true)),
    };
    trace!("Prepared DeclineJoinRequestResponse");

    reply(msg, response.encode_to_vec())
}

internal_error_fn!(
    internal_error_list,
    typewriter::api::v1::ListJoinRequestsResponse,
    list_join_requests_response,
    "Internal Server Error when listing join requests"
);

internal_error_fn!(
    internal_error_approve,
    typewriter::api::v1::ApproveJoinRequestResponse,
    approve_join_request_response,
    "Internal Server Error when approving join request"
);

internal_error_fn!(
    internal_error_decline,
    typewriter::api::v1::DeclineJoinRequestResponse,
    decline_join_request_response,
    "Internal Server Error when declining join request"
);
