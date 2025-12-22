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
    typewriter::api::v1::CreateOrganizationResponse,
    create_organization_response,
    "Internal Server Error when creating organization"
);

pub fn handle_create(msg: BrokerMessage, params: HashMap<String, String>) -> Result<(), String> {
    debug!("handle_create invoked");
    let user_id = params
        .get("user_id")
        .ok_or("failed to parse user_id from subject")?;
    debug!("Parsed user_id: {}", user_id);

    let request = typewriter::api::v1::CreateOrganizationRequest::decode(&msg.body[..])
        .map_err(|e| format!("failed to decode request: {}", e))?;
    trace!("Decoded CreateOrganizationRequest: {:?}", request);

    let name = request.name;
    let icon_url = request.icon_url;

    info!(
        "Creating organization '{}' for user '{}' with icon '{}'",
        name, user_id, icon_url
    );

    // TODO: When permissions are implemented, we need to update the role stuff to include those permissions
    let result = query(
        r#"
        BEGIN TRANSACTION;

        LET $org = CREATE ONLY organization SET
            name = $name,
            icon_url = $icon_url;

        LET $founder_role = CREATE ONLY role SET
            name = 'founder',
            organization = $org.id,
            color = 5483216,
            deletable = false,
            assignable = false,
            priority = 9223372036854775807;

        LET $writer_role = CREATE ONLY role SET
            name = 'writer',
            organization = $org.id,
            deletable = false,
            assignable = true,
            default_role = true,
            priority = 0;

        LET $user = type::thing('user', $user_id);
        RELATE $user->member_of->$org SET
            roles = [$founder_role.id];

        RETURN $org;

        COMMIT TRANSACTION;
        "#,
    )
    .bind("name", &name)
    .bind("icon_url", &icon_url)
    .bind("user_id", user_id)
    .execute()
    .map_err(|e| format!("failed to create organization: {}", e))?;
    trace!("Transaction executed successfully");

    let organization_record: OrganizationRecord = result
        .parse(0)
        .map_err(|e| format!("failed to take result: {}", e))?;

    trace!("Created organization: {:?}", organization_record);

    let organization: typewriter::models::v1::OrganizationData = organization_record.into();
    trace!("Prepared OrganizationData: {:?}", organization);

    let response = typewriter::api::v1::CreateOrganizationResponse {
        result: Some(
            typewriter::api::v1::create_organization_response::Result::Organization(organization),
        ),
    };
    trace!("Prepared CreateOrganizationResponse");

    let response_bytes = response.encode_to_vec();
    debug!(
        "Replying with CreateOrganizationResponse ({} bytes)",
        response_bytes.len()
    );
    reply(msg, response_bytes)
}
