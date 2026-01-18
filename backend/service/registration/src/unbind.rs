use std::collections::HashMap;

use prost::Message;
use surrealdb_component::query;
use wasmcloud_component::{debug, info, trace};
use wasmcloud_utils::{
    error_response_bytes, extract_param, internal_error_fn,
    wasmcloud::messaging::{reply, types::BrokerMessage},
};

use crate::{notifications, typewriter, ServiceRecord};

pub fn handle_unbind(msg: BrokerMessage, params: HashMap<String, String>) -> Result<(), String> {
    debug!("handle_unbind invoked");
    let org_id = extract_param!(params, org_id);

    let request = typewriter::api::v1::UnbindServiceRequest::decode(&msg.body[..])
        .map_err(|e| format!("failed to decode request: {}", e))?;
    trace!("Decoded UnbindServiceRequest");

    let service_id = &request.service_id;
    info!(
        "Unbinding service {} from organization {}",
        service_id, org_id
    );

    let result = query(
        r#"
        UPDATE type::thing('service', $service_id) SET
            organization = NONE,
            registration = NONE
        WHERE organization = type::thing('organization', $org_id)
        RETURN BEFORE;
        "#,
    )
    .bind("service_id", service_id)
    .bind("org_id", org_id)
    .execute()
    .map_err(|e| format!("failed to unbind service: {}", e))?;

    let affected: Vec<ServiceRecord> = result
        .take(0)
        .map_err(|e| format!("failed to parse result: {}", e))?;

    if affected.is_empty() {
        return reply(
            msg,
            error_response_bytes!(
                typewriter::api::v1::UnbindServiceResponse,
                unbind_service_response,
                404,
                "Service not found or not in this organization"
            ),
        );
    }

    let response = typewriter::api::v1::UnbindServiceResponse {
        result: Some(typewriter::api::v1::unbind_service_response::Result::Success(true)),
    };

    reply(msg, response.encode_to_vec())?;

    notifications::refresh_organization_services_list(org_id, params.get("user_id"))?;

    Ok(())
}

internal_error_fn!(
    internal_error_unbind,
    typewriter::api::v1::UnbindServiceResponse,
    unbind_service_response,
    "Internal Server Error when unbinding service"
);
