use std::collections::HashMap;

use prost::Message;
use surrealdb_component::query;
use wasmcloud_component::debug;
use wasmcloud_utils::{extract_param, wasmcloud::messaging::types::BrokerMessage};

use crate::{notifications::refresh_organization_services_list, typewriter};

pub fn handle_heartbeat(msg: BrokerMessage, params: HashMap<String, String>) -> Result<(), String> {
    debug!("handle_heartbeat invoked");
    let service_id = extract_param!(params, service_id);

    let _request = typewriter::api::v1::ServiceHeartbeatRequest::decode(&msg.body[..])
        .map_err(|e| format!("failed to decode heartbeat request: {}", e))?;

    query(
        r#"
        UPDATE type::thing('service', $service_id) SET state = {
            status: 'ONLINE',
            last_seen: time::now()
        };
        "#,
    )
    .bind("service_id", &service_id)
    .execute()
    .map_err(|e| format!("failed to update state: {}", e))?;

    debug!(
        "Heartbeat recorded for service {} (status: ONLINE)",
        service_id
    );

    let org_id: Option<String> =
        query(r#"SELECT VALUE <string>record::id(organization) FROM type::thing('service', $service_id);"#)
            .bind("service_id", &service_id)
            .execute()
            .map_err(|e| format!("failed to fetch organization: {}", e))?
            .take(0)
            .map_err(|e| format!("failed to parse organization: {}", e))?;

    if let Some(org_id) = org_id {
        refresh_organization_services_list(&org_id, None)?;
        debug!("Refreshed services list for organization {}", org_id);
    }

    Ok(())
}
