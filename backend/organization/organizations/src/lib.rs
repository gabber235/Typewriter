wit_bindgen::generate!({
    with: {
        "wasmcloud:messaging/consumer@0.2.0": wasmcloud_utils::wasmcloud::messaging::consumer,
        "wasmcloud:messaging/handler@0.2.0": wasmcloud_utils::wasmcloud::messaging::handler,
    },
    generate_all,
});

use prost::Message;
use serde_cbor::Value;
use std::collections::HashMap;
use surrealdb_component::query;
use wasmcloud_component::info;
use wasmcloud_utils::dispatch_actions;
use wasmcloud_utils::wasmcloud::messaging::{handler::Guest, reply, types::BrokerMessage};

mod typewriter {
    pub mod models {
        pub mod v1 {
            include!("generated/typewriter.models.v1.rs");
        }
    }
    pub mod api {
        pub mod v1 {
            include!("generated/typewriter.api.v1.rs");
        }
    }
}

struct Organizations;
wasmcloud_utils::export!(Organizations);

impl Guest for Organizations {
    fn handle_message(msg: BrokerMessage) -> Result<(), String> {
        dispatch_actions!(
            msg,
            "user.<user_id>.organization.<action>",
            "list" => handle_list,
            "create" => handle_create,
        )
    }
}

/// Handle the 'list' action - retrieve all organizations for a user
fn handle_list(msg: BrokerMessage, params: HashMap<String, String>) -> Result<(), String> {
    let user_id = params
        .get("user_id")
        .ok_or("failed to parse user_id from subject")?;

    // Parse the request (should be empty for list)
    let _request = typewriter::api::v1::ListOrganizationsRequest::decode(&msg.body[..])
        .map_err(|e| format!("failed to decode request: {}", e))?;

    let result = query("SELECT ->member_of->organizations FROM type::thing('user', $user_id)")
        .bind("user_id", user_id)
        .execute()
        .map_err(|e| format!("failed to query organizations: {}", e))?;

    let organizations_data: Vec<Value> = result
        .take(0)
        .map_err(|e| format!("failed to take result: {}", e))?;

    info!("organizations: {:?}", organizations_data);

    let organizations: Vec<typewriter::models::v1::Organization> = organizations_data
        .into_iter()
        .filter_map(|data| serde_cbor::value::from_value(data).ok())
        .collect();

    let response = typewriter::api::v1::ListOrganizationsResponse { organizations };

    let response_bytes = response.encode_to_vec();
    reply(msg, response_bytes)
}

/// Handle the 'create' action - create a new organization
fn handle_create(msg: BrokerMessage, params: HashMap<String, String>) -> Result<(), String> {
    let user_id = params
        .get("user_id")
        .ok_or("failed to parse user_id from subject")?;

    let request = typewriter::api::v1::CreateOrganizationRequest::decode(&msg.body[..])
        .map_err(|e| format!("failed to decode request: {}", e))?;

    let name = request.name;
    let icon_url = request.icon_url;

    info!(
        "Creating organization '{}' for user '{}' with icon '{}'",
        name, user_id, icon_url
    );

    // Create the organization in the database
    // TODO: Implement the actual creation logic with SurrealDB
    // For now, generate a placeholder ID
    let org_id = format!("org_{}", uuid::Uuid::new_v4().to_string());

    // Example query (adjust based on your schema):
    // let result = query("CREATE organizations SET name = $name, icon_url = $icon_url")
    //     .bind("name", name)
    //     .bind("icon_url", icon_url)
    //     .execute()
    //     .map_err(|e| format!("failed to create organization: {}", e))?;

    info!("Created organization with id: {}", org_id);

    // Create the organization proto response
    let organization = typewriter::models::v1::Organization {
        id: org_id.clone(),
        name,
        icon_url,
        member_ids: vec![user_id.clone()],
        created_at: chrono::Utc::now().timestamp(),
        updated_at: chrono::Utc::now().timestamp(),
    };

    let response = typewriter::api::v1::CreateOrganizationResponse {
        result: Some(
            typewriter::api::v1::create_organization_response::Result::Organization(organization),
        ),
    };

    let response_bytes = response.encode_to_vec();
    reply(msg, response_bytes)
}
