wit_bindgen::generate!({
    with: {
        "wasmcloud:messaging/consumer@0.2.0": wasmcloud_utils::wasmcloud::messaging::consumer,
        "wasmcloud:messaging/handler@0.2.0": wasmcloud_utils::wasmcloud::messaging::handler,
    },
    generate_all,
});

use serde_cbor::Value;
use surrealdb_component::query;
use wasmcloud_component::info;
use wasmcloud_utils::wasmcloud::messaging::{handler::Guest, reply, types::BrokerMessage};

struct Organizations;
wasmcloud_utils::export!(Organizations);

impl Guest for Organizations {
    fn handle_message(msg: BrokerMessage) -> Result<(), String> {
        let parts = wasmcloud_utils::wasmcloud::messaging::parse_subject(
            "user.<user_id>.organization.list",
            &msg.subject,
        )?;
        let user_id = parts
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
}
