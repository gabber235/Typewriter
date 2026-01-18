//! Handles service shutdown notifications.
//!
//! When a service gracefully shuts down, it sends a shutdown request
//! to update its status to OFFLINE. This provides immediate feedback
//! to the Panel rather than waiting for the 2-minute heartbeat timeout.

use std::collections::HashMap;

use prost::Message;
use surrealdb_component::query;
use wasmcloud_component::debug;
use wasmcloud_utils::{extract_param, wasmcloud::messaging::types::BrokerMessage};

use crate::typewriter;

pub fn handle_shutdown(msg: BrokerMessage, params: HashMap<String, String>) -> Result<(), String> {
    debug!("handle_shutdown invoked");
    let service_id = extract_param!(params, service_id);

    let _request = typewriter::api::v1::ServiceShutdownRequest::decode(&msg.body[..])
        .map_err(|e| format!("failed to decode shutdown request: {}", e))?;

    query(
        r#"
        UPDATE type::thing('service', $service_id) SET state = {
            status: 'OFFLINE',
            last_seen: time::now()
        };
        "#,
    )
    .bind("service_id", &service_id)
    .execute()
    .map_err(|e| format!("failed to update state: {}", e))?;

    debug!(
        "Shutdown recorded for service {} (status: OFFLINE)",
        service_id
    );
    Ok(())
}
