use std::collections::HashMap;

use otel_wasi::ResultWithSlug;
use surrealdb_component_sdk::query;
use wasmcloud_utils::{
    decode_skir, extract_params,
    skir::base::service::v1::{
        organization::WatchOrganizationServicesResponse,
        registration::{
            UnbindServiceRequest, UnbindServiceResponse,
            UnbindServiceResponse_ServiceNotFoundError, UnbindServiceResponse_Success,
        },
    },
    skir_variant,
    wasmcloud::messaging::types::BrokerMessage,
};

use wasmcloud_utils::database::service::ServiceRecord;

#[tracing::instrument(skip(msg, params))]
pub async fn handle_unbind(
    msg: BrokerMessage,
    params: HashMap<String, String>,
) -> Result<UnbindServiceResponse, otel_wasi::Error> {
    let (actor_id, org_id) = extract_params!(params, user_id, org_id)?;
    let request = decode_skir!(UnbindServiceRequest, &msg.body)?;
    otel_wasi::main_attribute!(
        "actor.id" = actor_id.to_string(),
        "organization.id" = org_id.to_string(),
        "service.id" = request.service_id.clone()
    );

    let records = query(
        r#"
        UPDATE type::thing('service', $service_id) SET
            organization = NONE,
            registration = NONE
        WHERE organization = type::thing('organization', $org_id)
        RETURN BEFORE
        "#,
    )
    .bind("service_id", &request.service_id)
    .bind("org_id", org_id)
    .execute()
    .await
    .error_with_slug("service-unbind-query-failed")?
    .take::<Option<ServiceRecord>>(0)
    .error_with_slug("service-unbind-result-parse-failed")?;

    let Some(record) = records else {
        otel_wasi::main_attribute!("service.outcome" = "not_found");
        return Ok(skir_variant!(UnbindServiceResponse::ServiceNotFoundError));
    };

    wasmcloud_utils::skir_subjects::organization_services(org_id)
        .publish(WatchOrganizationServicesResponse::Remove(Box::new(
            record.id.into(),
        )))
        .await?;

    otel_wasi::main_attribute!("service.outcome" = "unbound");
    Ok(skir_variant!(UnbindServiceResponse::Success))
}
