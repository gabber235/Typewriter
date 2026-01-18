use std::collections::HashMap;

use prost::Message;
use surrealdb_component::query;
use wasmcloud_component::debug;
use wasmcloud_utils::{extract_param, wasmcloud::messaging::types::BrokerMessage};

use crate::typewriter;

pub fn handle_heartbeat(msg: BrokerMessage, params: HashMap<String, String>) -> Result<(), String> {
    debug!("handle_heartbeat invoked");
    let service_id = extract_param!(params, service_id);

    let _request = typewriter::api::v1::ServiceHeartbeatRequest::decode(&msg.body[..])
        .map_err(|e| format!("failed to decode heartbeat request: {}", e))?;

    query(
        r#"
        UPDATE type::thing('service', $service_id) SET last_seen = time::now();
        "#,
    )
    .bind("service_id", &service_id)
    .execute()
    .map_err(|e| format!("failed to update last_seen: {}", e))?;

    debug!("Heartbeat recorded for service {}", service_id);
    Ok(())
}
