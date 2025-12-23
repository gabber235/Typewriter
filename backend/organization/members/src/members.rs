use std::collections::HashMap;

use prost::Message;
use surrealdb_component::query;
use wasmcloud_component::{debug, info, trace};
use wasmcloud_utils::{
    error_response_bytes, extract_param, internal_error_fn,
    wasmcloud::messaging::{reply, types::BrokerMessage},
};

use crate::{refresh, typewriter, MemberWithRolesRecord};

pub fn handle_list(msg: BrokerMessage, params: HashMap<String, String>) -> Result<(), String> {
    debug!("handle_list (members) invoked");
    let org_id = extract_param!(params, org_id);

    let _request = typewriter::api::v1::ListMembersRequest::decode(&msg.body[..])
        .map_err(|e| format!("failed to decode request: {}", e))?;
    trace!("Decoded ListMembersRequest");

    let result = query(
        r#"
        SELECT
            id,
            in.* as user,
            joined_at,
            roles.* AS roles
        FROM member_of
        WHERE out = type::thing('organization', $org_id)
        FETCH in, roles
        "#,
    )
    .bind("org_id", org_id)
    .execute()
    .map_err(|e| format!("failed to query members: {}", e))?;
    trace!("Query executed successfully");

    let members_data: Vec<MemberWithRolesRecord> = result
        .take(0)
        .map_err(|e| format!("failed to take result: {}", e))?;
    trace!("Fetched members data: {:?}", members_data);

    let members: Vec<typewriter::models::v1::OrganizationMember> = members_data
        .into_iter()
        .map(|record| record.into())
        .collect();

    trace!("Converted to OrganizationMember structs: {:?}", members);

    let response = typewriter::api::v1::ListMembersResponse {
        result: Some(typewriter::api::v1::list_members_response::Result::Members(
            typewriter::api::v1::ListMembers { members },
        )),
    };
    trace!("Prepared ListMembersResponse");

    reply(msg, response.encode_to_vec())
}

pub fn handle_update(msg: BrokerMessage, params: HashMap<String, String>) -> Result<(), String> {
    debug!("handle_update (members) invoked");
    let org_id = extract_param!(params, org_id);

    let request = typewriter::api::v1::UpdateMemberRolesRequest::decode(&msg.body[..])
        .map_err(|e| format!("failed to decode request: {}", e))?;
    trace!("Decoded UpdateMemberRolesRequest: {:?}", request);

    let member_id = request.member_id;
    let role_ids: Vec<String> = request.role_ids;

    info!("Updating member '{}' roles to {:?}", member_id, role_ids);

    let result = query(
        r#"
        BEGIN TRANSACTION;
        LET $requested_roles = $role_ids.map(|$id| type::thing('role', $id));

        LET $member = SELECT id, roles FROM ONLY member_of WHERE out = type::thing('organization', $org_id) AND in = type::thing('user', $member_id);

        IF !$member {
            THROW "Not a member of the organization";
        };

        LET $roles = array::concat(
            $member.roles.filter(|$role| !$role.assignable),
            $requested_roles.filter(|$role| $role.assignable)
        );

        IF array::is_empty($roles) {
            THROW "A user must have at least one valid role";
        };

        UPDATE $member.id SET
            roles = $roles;

        RETURN SELECT
            id,
            in.* as user,
            joined_at,
            roles.* AS roles
        FROM ONLY $member.id
        FETCH in, roles;
        COMMIT TRANSACTION;
        "#,
    )
    .bind("org_id", &org_id)
    .bind("member_id", &member_id)
    .bind("role_ids", &role_ids)
    .execute()
    .map_err(|e| format!("failed to update member roles: {}", e))?;
    trace!("Update executed successfully");

    let updated_record: Result<MemberWithRolesRecord, String> = result
        .parse_result(0)
        .map_err(|e| format!("failed to take result: {}", e))?;

    if let Err(e) = updated_record {
        return reply(
            msg,
            error_response_bytes!(
                typewriter::api::v1::UpdateMemberRolesResponse,
                update_member_roles_response,
                403,
                e
            ),
        );
    }
    let updated_record = updated_record.unwrap();

    trace!("Updated member record: {:?}", updated_record);

    let response = typewriter::api::v1::UpdateMemberRolesResponse {
        result: Some(
            typewriter::api::v1::update_member_roles_response::Result::Member(
                updated_record.into(),
            ),
        ),
    };
    trace!("Prepared UpdateMemberRolesResponse");

    reply(msg, response.encode_to_vec())?;

    refresh::refresh_organization_members_list(org_id, params.get("user_id"))?;
    Ok(())
}

pub fn handle_remove(msg: BrokerMessage, params: HashMap<String, String>) -> Result<(), String> {
    debug!("handle_remove (members) invoked");
    let org_id = extract_param!(params, org_id);

    let request = typewriter::api::v1::RemoveMemberRequest::decode(&msg.body[..])
        .map_err(|e| format!("failed to decode request: {}", e))?;
    trace!("Decoded RemoveMemberRequest: {:?}", request);

    let member_id = request.member_id;

    info!("Removing member '{}'", member_id);

    query(
    r#"
        LET $member = SELECT VALUE id FROM ONLY member_of WHERE out = type::thing('organization', $org_id) AND in = type::thing('user', $member_id);
        DELETE $member
        "#,
    )
    .bind("org_id", &org_id)
        .bind("member_id", &member_id)
        .execute()
        .map_err(|e| format!("failed to remove member: {}", e))?;
    trace!("Delete executed successfully");

    let response = typewriter::api::v1::RemoveMemberResponse {
        result: Some(typewriter::api::v1::remove_member_response::Result::Success(true)),
    };
    trace!("Prepared RemoveMemberResponse");

    reply(msg, response.encode_to_vec())?;

    refresh::refresh_organization_members_list(org_id, params.get("user_id"))?;
    refresh::refresh_user_organization_list(&member_id)?;
    Ok(())
}

internal_error_fn!(
    internal_error_list,
    typewriter::api::v1::ListMembersResponse,
    list_members_response,
    "Internal Server Error when listing members"
);

internal_error_fn!(
    internal_error_update,
    typewriter::api::v1::UpdateMemberRolesResponse,
    update_member_roles_response,
    "Internal Server Error when updating member roles"
);

internal_error_fn!(
    internal_error_remove,
    typewriter::api::v1::RemoveMemberResponse,
    remove_member_response,
    "Internal Server Error when removing member"
);
