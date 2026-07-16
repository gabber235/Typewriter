use std::collections::HashMap;

use otel_wasi::ResultWithSlug;
use surrealdb_component_sdk::query;
use wasmcloud_utils::{
    decode_skir, extract_params,
    skir::base::service::v1::organization::{
        UpdateOrganizationServiceRequest, UpdateOrganizationServiceResponse,
        UpdateOrganizationServiceResponse_ServiceNotFoundError,
        UpdateOrganizationServiceResponse_Success, WatchOrganizationServicesResponse,
    },
    skir_variant,
    wasmcloud::messaging::types::BrokerMessage,
};

use wasmcloud_utils::database::service::ServiceRecord;

#[tracing::instrument(skip(msg, params))]
pub async fn handle_update(
    msg: BrokerMessage,
    params: HashMap<String, String>,
) -> Result<UpdateOrganizationServiceResponse, otel_wasi::Error> {
    let (actor_id, org_id) = extract_params!(params, user_id, org_id)?;
    let request = decode_skir!(UpdateOrganizationServiceRequest, &msg.body)?;
    otel_wasi::main_attribute!(
        "actor.id" = actor_id.to_string(),
        "organization.id" = org_id.to_string(),
        "service.id" = request.service_id.to_string()
    );

    if request.service_id.table != "service" {
        return Err(otel_wasi::Error::new(
            "service-update-id-invalid",
            "service id must reference service table",
        ));
    }

    let service_id = surrealdb_component_sdk::RecordId::from(&request.service_id);
    let records = query(
        r#"
        UPDATE $service_id SET
            name = IF $name != NONE THEN $name ELSE name END
        WHERE organization = type::record('organization', $org_id)
        RETURN AFTER
        "#,
    )
    .bind("service_id", service_id)
    .bind("org_id", org_id)
    .bind("name", request.name)
    .execute()
    .await
    .error_with_slug("service-update-query-failed")?
    .take::<Option<ServiceRecord>>(0)
    .error_with_slug("service-update-result-parse-failed")?;

    let Some(record) = records else {
        otel_wasi::main_attribute!("service.outcome" = "not_found");
        return Ok(skir_variant!(
            UpdateOrganizationServiceResponse::ServiceNotFoundError
        ));
    };
    let service = record.try_into()?;

    wasmcloud_utils::skir_subjects::organization_services(org_id)
        .publish(WatchOrganizationServicesResponse::Update(Box::new(service)))
        .await?;

    otel_wasi::main_attribute!("service.outcome" = "updated");
    Ok(skir_variant!(UpdateOrganizationServiceResponse::Success))
}
