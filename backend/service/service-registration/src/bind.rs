use std::collections::HashMap;

use otel_wasi::ResultWithSlug;
use serde::Deserialize;
use wasmcloud_utils::{
    database::{RecordId, transaction_query},
    decode_skir, extract_params,
    skir::base::service::v1::{
        organization::WatchOrganizationServicesResponse,
        registration::{
            BindServiceRequest, BindServiceResponse, BindServiceResponse_Success,
            ServiceBoundNotification,
        },
    },
    skir_domain_result, skir_variant,
    wasmcloud::messaging::types::BrokerMessage,
};

use wasmcloud_utils::database::{organization::OrganizationRecord, service::ServiceRecord};

#[derive(Debug, Deserialize)]
struct BindResult {
    service: ServiceRecord,
    organization: OrganizationRecord,
}

#[tracing::instrument(skip(msg, params))]
pub async fn handle_bind(
    msg: BrokerMessage,
    params: HashMap<String, String>,
) -> Result<BindServiceResponse, otel_wasi::Error> {
    let (actor_id, org_id) = extract_params!(params, user_id, org_id)?;
    otel_wasi::main_attribute!(
        "actor.id" = actor_id.to_string(),
        "organization.id" = org_id.to_string()
    );
    let request = decode_skir!(BindServiceRequest, &msg.body)?;
    let organization_id = RecordId::new("organization", org_id);

    let response = transaction_query!(
        BindResult,
        r#"
        BEGIN TRANSACTION;

        LET $services = SELECT * FROM service
            WHERE registration.token = $registration_token
                AND registration.expires_at > time::now();

        IF array::is_empty($services) {
            THROW 'invalid-registration-token-error'
        };

        LET $organizations = SELECT id, name FROM $organization_id;
        IF array::is_empty($organizations) {
            THROW 'organization-not-found-error'
        };

        LET $organization = array::first($organizations);
        LET $updated = UPDATE ONLY $services[0].id SET
            organization = $organization.id,
            registration = NONE
        RETURN AFTER;

        RETURN {
            service: $updated,
            organization: $organization
        };

        COMMIT TRANSACTION;
        "#,
    )
    .bind("registration_token", request.registration_token)
    .bind("organization_id", organization_id)
    .execute()
    .await
    .error_with_slug("service-bind-query-failed")?;
    otel_wasi::main_attribute!(
        "db.query.attempts" = response.attempts().get() as i64,
        "db.query.retries" = response.attempts().get().saturating_sub(1) as i64,
    );
    let result = response
        .decode()
        .error_with_slug("service-bind-result-parse-failed")?;
    let result = skir_domain_result!(BindServiceResponse, result);

    let service_id = result.service.id.key.to_string();
    let service_name = result.service.name.clone();
    let role = result.service.role.clone().try_into()?;

    let service = result.service.try_into()?;

    wasmcloud_utils::skir_subjects::organization_services(org_id)
        .publish(WatchOrganizationServicesResponse::Add(Box::new(service)))
        .await?;

    wasmcloud_utils::skir_subjects::service_bound(&service_id)
        .publish(ServiceBoundNotification {
            organization_id: result.organization.id.key.to_string(),
            organization_name: Some(result.organization.name),
            _unrecognized: None,
        })
        .await?;

    otel_wasi::main_attribute!(
        "service.id" = service_id.clone(),
        "service.outcome" = "bound"
    );
    Ok(skir_variant!(BindServiceResponse::Success {
        service_id,
        service_name: Some(service_name),
        service_role: role,
    }))
}
