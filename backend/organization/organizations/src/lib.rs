wit_bindgen::generate!({
    with: {
        "wasmcloud:messaging/consumer@0.2.0": wasmcloud_utils::wasmcloud::messaging::consumer,
        "wasmcloud:messaging/handler@0.2.0": wasmcloud_utils::wasmcloud::messaging::handler,
    },
    generate_all,
});

use std::collections::HashMap;
use serde_cbor::Value;
use serde_json::json;
use surrealdb_component::query;
use wasmcloud_component::info;
use wasmcloud_utils::wasmcloud::messaging::{handler::Guest, reply, types::BrokerMessage};
use wasmcloud_utils::dispatch_actions;

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

    let result = query("SELECT ->member_of->organizations FROM type::thing('user', $user_id)")
        .bind("user_id", user_id)
        .execute()
        .map_err(|e| format!("failed to query organizations: {}", e))?;

    let organizations: Vec<Value> = result
        .take(0)
        .map_err(|e| format!("failed to take result: {}", e))?;

    info!("organizations: {:?}", organizations);
    // TODO properly parse the result

    reply(msg, vec![])
}

/// Handle the 'create' action - create a new organization
fn handle_create(msg: BrokerMessage, params: HashMap<String, String>) -> Result<(), String> {
    let user_id = params
        .get("user_id")
        .ok_or("failed to parse user_id from subject")?;

    let body_str = String::from_utf8(msg.body.clone())
        .map_err(|e| format!("failed to parse body as UTF-8: {}", e))?;

    let request: serde_json::Value = serde_json::from_str(&body_str)
        .map_err(|e| format!("failed to parse JSON body: {}", e))?;

    let name = request.get("name")
        .and_then(|v| v.as_str())
        .ok_or("missing or invalid 'name' field in request body")?;

    let icon_url = request.get("iconUrl")
        .and_then(|v| v.as_str())
        .ok_or("missing or invalid 'iconUrl' field in request body")?;

    info!("Creating organization '{}' for user '{}' with icon '{}'", name, user_id, icon_url);

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

    // Return the organization ID
    let response = json!(org_id).to_string();
    reply(msg, response.into_bytes())
}
