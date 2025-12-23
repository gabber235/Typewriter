use std::collections::HashMap;

use prost::Message;
use surrealdb_component::query;
use wasmcloud_component::{debug, trace};
use wasmcloud_utils::{
    extract_param, internal_error_fn,
    wasmcloud::messaging::{reply, types::BrokerMessage},
};

use crate::{typewriter, RoleRecord};

internal_error_fn!(
    internal_error_data,
    typewriter::api::v1::ListRolesResponse,
    list_roles_response,
    "Internal Server Error when listing roles"
);

pub fn handle_list(msg: BrokerMessage, params: HashMap<String, String>) -> Result<(), String> {
    debug!("handle_list invoked");
    let org_id = extract_param!(params, org_id);

    let _request = typewriter::api::v1::ListRolesRequest::decode(&msg.body[..])
        .map_err(|e| format!("failed to decode request: {}", e))?;
    trace!("Decoded ListRolesRequest");

    let result = query(
        r#"
        SELECT * FROM role
        WHERE organization = type::thing('organization', $org_id)
        ORDER BY priority DESC
        "#,
    )
    .bind("org_id", org_id)
    .execute()
    .map_err(|e| format!("failed to query roles: {}", e))?;
    trace!("Query executed successfully");

    let roles: Vec<RoleRecord> = result
        .take(0)
        .map_err(|e| format!("failed to take result: {}", e))?;
    trace!("Fetched roles: {:?}", roles);

    let roles: Vec<typewriter::models::v1::Role> = roles.into_iter().map(|r| r.into()).collect();
    trace!("Converted to Role protos: {:?}", roles);

    let response = typewriter::api::v1::ListRolesResponse {
        result: Some(typewriter::api::v1::list_roles_response::Result::Roles(
            typewriter::api::v1::ListRoles { roles },
        )),
    };
    trace!("Prepared ListRolesResponse");

    reply(msg, response.encode_to_vec())
}
