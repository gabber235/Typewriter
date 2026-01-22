use std::collections::HashMap;

use prost::Message;
use surrealdb_component::query;
use wasmcloud_component::{debug, trace};
use wasmcloud_utils::{
    error_response_bytes, extract_param, internal_error_fn,
    wasmcloud::messaging::{reply, types::BrokerMessage},
};

use crate::{notifications, typewriter, utils, ServiceRecord};

pub fn handle_update(msg: BrokerMessage, params: HashMap<String, String>) -> Result<(), String> {
    debug!("handle_update invoked");
    let org_id = extract_param!(params, org_id);

    let request = typewriter::api::v1::UpdateServiceRequest::decode(&msg.body[..])
        .map_err(|e| format!("failed to decode request: {}", e))?;
    trace!("Decoded UpdateServiceRequest");

    let service_id = &request.service_id;
    let new_name = &request.name;

    let result = query(
        r#"
        UPDATE type::thing('service', $service_id) SET name = $name
        WHERE organization = type::thing('organization', $org_id)
        RETURN AFTER;
        "#,
    )
    .bind("service_id", service_id)
    .bind("org_id", org_id)
    .bind("name", new_name)
    .execute()
    .map_err(|e| format!("failed to update service: {}", e))?;

    let services: Vec<ServiceRecord> = result
        .take(0)
        .map_err(|e| format!("failed to parse result: {}", e))?;

    if services.is_empty() {
        return reply(
            msg,
            error_response_bytes!(
                typewriter::api::v1::UpdateServiceResponse,
                update_service_response,
                404,
                "Service not found or not in this organization"
            ),
        );
    }

    let service = &services[0];
    let metadata = service.metadata.as_ref();
    let state = service.state.as_ref();

    let response = typewriter::api::v1::UpdateServiceResponse {
        result: Some(
            typewriter::api::v1::update_service_response::Result::Service(
                typewriter::models::v1::Service {
                    id: service.id.id.to_string(),
                    name: service.name.clone(),
                    service_types: utils::map_service_types(&service.service_types),
                    created_at: Some(service.created_at.clone().into()),
                    state: state.map(|s| typewriter::models::v1::ServiceState {
                        status: match s.status.as_deref() {
                            Some("ONLINE") => typewriter::models::v1::ServiceStatus::Online as i32,
                            Some("OFFLINE") => typewriter::models::v1::ServiceStatus::Offline as i32,
                            _ => typewriter::models::v1::ServiceStatus::Unspecified as i32,
                        },
                        last_seen: s.last_seen.clone().map(|dt| dt.into()),
                    }),
                    metadata: Some(typewriter::models::v1::ServiceMetadata {
                        engine_version: metadata.and_then(|m| m.engine_version.clone()),
                        realm_version: metadata.and_then(|m| m.realm_version.clone()),
                    }),
                    organization_id: service.organization.as_ref().map(|o| o.id.to_string()),
                },
            ),
        ),
    };

    reply(msg, response.encode_to_vec())?;

    notifications::refresh_organization_services_list(org_id, params.get("user_id"))?;

    Ok(())
}

internal_error_fn!(
    internal_error_update,
    typewriter::api::v1::UpdateServiceResponse,
    update_service_response,
    "Internal Server Error when updating service"
);
