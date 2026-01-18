use std::collections::HashMap;

use prost::Message;
use surrealdb_component::query;
use wasmcloud_component::{debug, info, trace};
use wasmcloud_utils::{
    error_response_bytes, extract_param, internal_error_fn,
    wasmcloud::messaging::{reply, types::BrokerMessage},
};

use crate::{notifications, typewriter, utils, OrganizationRecord, ServiceRecord};

#[derive(Debug, serde::Deserialize)]
struct BindResult {
    service: ServiceRecord,
    organization: OrganizationRecord,
}

pub fn handle_bind(msg: BrokerMessage, params: HashMap<String, String>) -> Result<(), String> {
    debug!("handle_bind invoked");
    let org_id = extract_param!(params, org_id);

    let request = typewriter::api::v1::BindServiceRequest::decode(&msg.body[..])
        .map_err(|e| format!("failed to decode request: {}", e))?;
    trace!("Decoded BindServiceRequest");

    let token = request.registration_token;
    info!("Attempting to bind service with token: {}", token);

    let result = query(
        r#"
        BEGIN TRANSACTION;

        LET $service = SELECT * FROM service 
            WHERE registration.token = $registration_token 
            AND registration.expires_at > time::now();

        IF array::is_empty($service) {
            THROW "Invalid or expired registration token";
        };

        LET $orgs = SELECT id, name FROM type::thing('organization', $org_id);

        IF array::len($orgs) == 0 {
            THROW "Organization not found";
        };

        LET $org = array::first($orgs);

        LET $updated = UPDATE $service[0].id SET
            organization = $org.id,
            registration = NONE
        RETURN AFTER;

        RETURN {
            service: $updated[0],
            organization: $org
        };

        COMMIT TRANSACTION;
        "#,
    )
    .bind("registration_token", &token)
    .bind("org_id", org_id)
    .execute();

    let result = match result {
        Ok(r) => r,
        Err(e) => {
            let error_msg = e.to_string();
            if error_msg.contains("Invalid or expired") || error_msg.contains("Organization not found") {
                return reply(
                    msg,
                    error_response_bytes!(
                        typewriter::api::v1::BindServiceResponse,
                        bind_service_response,
                        400,
                        error_msg
                    ),
                );
            }
            return Err(format!("failed to bind service: {}", e));
        }
    };

    let bind_result: Result<BindResult, String> = result
        .parse_result(0)
        .map_err(|e| format!("failed to parse bind result: {}", e))?;

    let bind_result = match bind_result {
        Ok(r) => r,
        Err(e) => {
            return reply(
                msg,
                error_response_bytes!(
                    typewriter::api::v1::BindServiceResponse,
                    bind_service_response,
                    400,
                    e
                ),
            );
        }
    };

    let service = bind_result.service;
    let org = bind_result.organization;
    let service_id = service.id.id.to_string();

    trace!("Bound service {} to organization {}", service_id, org.name);

    let response = typewriter::api::v1::BindServiceResponse {
        result: Some(typewriter::api::v1::bind_service_response::Result::Service(
            typewriter::api::v1::BoundService {
                service_id: service_id.clone(),
                service_name: service.name,
                service_types: utils::map_service_types(&service.service_types),
            },
        )),
    };

    reply(msg, response.encode_to_vec())?;

    notifications::publish_bound_notification(&service_id, &org.id.id.to_string(), &org.name)?;

    notifications::refresh_organization_services_list(&org.id.id.to_string(), params.get("user_id"))?;

    Ok(())
}

internal_error_fn!(
    internal_error_bind,
    typewriter::api::v1::BindServiceResponse,
    bind_service_response,
    "Internal Server Error when binding service"
);
