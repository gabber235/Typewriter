use std::collections::HashMap;

use otel_wasi::ResultWithSlug;
use serde::Deserialize;
use surrealdb_component_sdk::query;
use wasmcloud_utils::{
    decode_skir, extract_param,
    skir::base::service::v1::status::{
        GetServiceStatusRequest, GetServiceStatusResponse, GetServiceStatusResponse_Status,
        ServiceBinding, ServiceBinding_Bound, ServiceBinding_Unbound,
    },
    skir_domain_result,
    wasmcloud::messaging::types::BrokerMessage,
};

use crate::utils;
use wasmcloud_utils::database::organization::OrganizationRecord;

#[derive(Debug, Deserialize)]
struct StatusQueryResult {
    organization: Option<OrganizationRecord>,
    token: Option<String>,
}

#[tracing::instrument(skip(msg, params))]
pub async fn handle_status(
    msg: BrokerMessage,
    params: HashMap<String, String>,
) -> Result<GetServiceStatusResponse, otel_wasi::Error> {
    let service_id = extract_param!(params, service_id)?;
    otel_wasi::main_attribute!("service.id" = service_id.to_string());
    let _ = decode_skir!(GetServiceStatusRequest, &msg.body)?;

    let result = query(
        r#"
        BEGIN TRANSACTION;

        LET $services = SELECT
            IF organization THEN { id: organization.id, name: organization.name } ELSE NONE END AS organization,
            registration.token AS existing_token,
            registration.expires_at AS existing_expires_at
        FROM type::thing('service', $service_id)
        FETCH organization;

        IF array::is_empty($services) {
            THROW 'service-not-found-error'
        };

        LET $service = array::first($services);
        IF $service.organization != NONE {
            RETURN { organization: $service.organization, token: NONE }
        };

        LET $token = IF $service.existing_token != NONE AND $service.existing_expires_at > time::now() {
            $service.existing_token
        } ELSE {
            $new_token
        };

        UPDATE type::thing('service', $service_id) SET registration = {
            token: $token,
            expires_at: time::now() + 2m30s
        };

        RETURN { organization: NONE, token: $token };
        COMMIT TRANSACTION;
        "#,
    )
    .bind("service_id", service_id)
    .bind("new_token", utils::generate_registration_token())
    .execute()
    .await
    .error_with_slug("service-status-query-failed")?
    .parse_result::<StatusQueryResult>(0)
    .error_with_slug("service-status-result-parse-failed")?;

    let status = skir_domain_result!(GetServiceStatusResponse, result);

    let binding = if let Some(organization) = status.organization {
        ServiceBinding::Bound(Box::new(ServiceBinding_Bound {
            organization_id: organization.id.key.to_string(),
            organization_name: Some(organization.name),
            _unrecognized: None,
        }))
    } else {
        ServiceBinding::Unbound(Box::new(ServiceBinding_Unbound {
            registration_token: status.token,
            _unrecognized: None,
        }))
    };

    Ok(GetServiceStatusResponse::Status(Box::new(
        GetServiceStatusResponse_Status {
            binding,
            _unrecognized: None,
        },
    )))
}
