use std::collections::HashMap;

use prost::Message;
use surrealdb_component::query;
use wasmcloud_component::{debug, trace};
use wasmcloud_utils::{
    error_response_bytes, extract_param, internal_error_fn,
    wasmcloud::messaging::{reply, types::BrokerMessage},
};

use crate::{typewriter, utils, OrganizationRecord};

#[derive(Debug, serde::Deserialize)]
struct StatusQueryResult {
    organization: Option<OrganizationRecord>,
    token: Option<String>,
}

pub fn handle_status(msg: BrokerMessage, params: HashMap<String, String>) -> Result<(), String> {
    debug!("handle_status invoked");
    let service_id = extract_param!(params, service_id);

    let _request = typewriter::api::v1::GetServiceStatusRequest::decode(&msg.body[..])
        .map_err(|e| format!("failed to decode request: {}", e))?;
    trace!("Decoded GetServiceStatusRequest");

    let result = query(
        r#"
        BEGIN TRANSACTION;

        LET $service = SELECT 
            id, 
            IF organization THEN {id: organization.id, name: organization.name} ELSE null END AS organization,
            registration.token AS existing_token
        FROM type::thing('service', $service_id)
        FETCH organization;

        IF array::is_empty($service) {
            THROW "Service not found";
        };

        LET $svc = array::first($service);

        -- If bound, just return organization info without updating registration
        IF $svc.organization {
            RETURN {
                organization: $svc.organization,
                token: null
            };
        };

        LET $registration_token = IF $svc.existing_token {
            $svc.existing_token
        } ELSE {
            $new_token
        };

        UPDATE type::thing('service', $service_id) SET
            registration = {
                token: $registration_token,
                expires_at: time::now() + 2m30s
            };

        RETURN {
            organization: null,
            token: $registration_token
        };

        COMMIT TRANSACTION;
        "#,
    )
    .bind("service_id", &service_id)
    .bind("new_token", utils::generate_registration_token())
    .execute()
    .map_err(|e| format!("failed to query service: {}", e))?;

    let status: Result<StatusQueryResult, String> = result
        .parse_result(0)
        .map_err(|e| format!("failed to parse result: {}", e))?;

    let status = match status {
        Ok(s) => s,
        Err(e) => {
            if e.contains("not found") {
                return reply(
                    msg,
                    error_response_bytes!(
                        typewriter::api::v1::GetServiceStatusResponse,
                        get_service_status_response,
                        404,
                        "Service not found"
                    ),
                );
            }
            return Err(e);
        }
    };

    if let Some(org) = status.organization {
        let response = typewriter::api::v1::GetServiceStatusResponse {
            result: Some(
                typewriter::api::v1::get_service_status_response::Result::Status(
                    typewriter::api::v1::ServiceStatus {
                        binding: Some(typewriter::api::v1::service_status::Binding::Bound(
                            typewriter::api::v1::BoundStatus {
                                organization_id: org.id.id.to_string(),
                                organization_name: org.name,
                            },
                        )),
                    },
                ),
            ),
        };
        return reply(msg, response.encode_to_vec());
    }

    let Some(token) = status.token else {
        return Err("Expected token for unbound service".to_string());
    };

    let response = typewriter::api::v1::GetServiceStatusResponse {
        result: Some(
            typewriter::api::v1::get_service_status_response::Result::Status(
                typewriter::api::v1::ServiceStatus {
                    binding: Some(typewriter::api::v1::service_status::Binding::Unbound(
                        typewriter::api::v1::UnboundStatus {
                            registration_token: token,
                        },
                    )),
                },
            ),
        ),
    };
    reply(msg, response.encode_to_vec())
}

internal_error_fn!(
    internal_error_status,
    typewriter::api::v1::GetServiceStatusResponse,
    get_service_status_response,
    "Internal Server Error when getting service status"
);
