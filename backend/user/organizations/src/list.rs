use std::collections::HashMap;

use prost::Message;
use surrealdb_component::query;
use wasmcloud_component::{debug, info, trace};
use wasmcloud_utils::{
    internal_error_fn,
    wasmcloud::messaging::{reply, types::BrokerMessage},
};

use crate::{typewriter, OrganizationRecord};

internal_error_fn!(
    internal_error_data,
    typewriter::api::v1::ListOrganizationsResponse,
    list_organizations_response,
    "Internal Server Error when listing organizations"
);

pub fn handle_list(msg: BrokerMessage, params: HashMap<String, String>) -> Result<(), String> {
    debug!("handle_list invoked");
    let user_id = params
        .get("user_id")
        .ok_or("failed to parse user_id from subject")?;
    debug!("Parsed user_id: {}", user_id);

    let _request = typewriter::api::v1::ListOrganizationsRequest::decode(&msg.body[..])
        .map_err(|e| format!("failed to decode request: {}", e))?;
    trace!("Decoded ListOrganizationsRequest: {:?}", _request);

    let result = query(
        "SELECT VALUE ->member_of->organization.* AS orgs FROM type::thing('user', $user_id)",
    )
    .bind("user_id", user_id)
    .execute()
    .map_err(|e| format!("failed to query organizations: {}", e))?;
    trace!("Query executed successfully");

    let organizations_data: Option<Vec<OrganizationRecord>> = result
        .take(0)
        .map_err(|e| format!("failed to take result: {}", e))?;
    let organizations_data = organizations_data.unwrap_or_default();
    trace!("Fetched organizations data: {:?}", organizations_data);

    info!("organizations: {:?}", organizations_data);

    let organizations: Vec<typewriter::models::v1::OrganizationData> = organizations_data
        .into_iter()
        .map(|record| record.into())
        .collect();
    trace!("Converted to OrganizationData structs: {:?}", organizations);

    let response = typewriter::api::v1::ListOrganizationsResponse {
        result: Some(
            typewriter::api::v1::list_organizations_response::Result::Organizations(
                typewriter::api::v1::ListOrganizations { organizations },
            ),
        ),
    };
    trace!("Prepared ListOrganizationsResponse");

    reply(msg, response.encode_to_vec())
}
