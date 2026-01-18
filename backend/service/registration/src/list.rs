use std::collections::HashMap;

use prost::Message;
use surrealdb_component::query;
use wasmcloud_component::{debug, trace};
use wasmcloud_utils::{
    extract_param, internal_error_fn,
    wasmcloud::messaging::{reply, types::BrokerMessage},
};

use crate::{typewriter, utils, ServiceRecord};

pub fn handle_list(msg: BrokerMessage, params: HashMap<String, String>) -> Result<(), String> {
    debug!("handle_list invoked");
    let org_id = extract_param!(params, org_id);

    let _request = typewriter::api::v1::ListOrganizationServicesRequest::decode(&msg.body[..])
        .map_err(|e| format!("failed to decode request: {}", e))?;
    trace!("Decoded ListOrganizationServicesRequest");

    let result = query(
        r#"
        SELECT * FROM service 
        WHERE organization = type::thing('organization', $org_id)
        ORDER BY name ASC
        "#,
    )
    .bind("org_id", org_id)
    .execute()
    .map_err(|e| format!("failed to query services: {}", e))?;

    let services_data: Vec<ServiceRecord> = result
        .take(0)
        .map_err(|e| format!("failed to parse services: {}", e))?;
    trace!("Fetched {} services", services_data.len());

    let services: Vec<typewriter::models::v1::Service> = services_data
        .into_iter()
        .map(|record| {
            let metadata = record.metadata.as_ref();
            typewriter::models::v1::Service {
                id: record.id.id.to_string(),
                name: record.name,
                service_types: utils::map_service_types(&record.service_types),
                created_at: Some(record.created_at.into()),
                last_seen: record.last_seen.map(|dt| dt.into()),
                metadata: Some(typewriter::models::v1::ServiceMetadata {
                    engine_version: metadata.and_then(|m| m.engine_version.clone()),
                    realm_version: metadata.and_then(|m| m.realm_version.clone()),
                }),
                organization_id: record.organization.map(|o| o.id.to_string()),
            }
        })
        .collect();

    let response = typewriter::api::v1::ListOrganizationServicesResponse {
        result: Some(
            typewriter::api::v1::list_organization_services_response::Result::Services(
                typewriter::api::v1::OrganizationServicesList { services },
            ),
        ),
    };

    reply(msg, response.encode_to_vec())
}

internal_error_fn!(
    internal_error_list,
    typewriter::api::v1::ListOrganizationServicesResponse,
    list_organization_services_response,
    "Internal Server Error when listing services"
);
