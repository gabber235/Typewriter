use std::collections::HashMap;

use otel_wasi::ResultWithSlug;
use wasmcloud_utils::{
    database::{RecordId, transaction_query},
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
    let service_id = RecordId::new("service", request.service_id.as_str());
    let organization_id = RecordId::new("organization", org_id);

    let result = transaction_query!(
        Option<ServiceRecord>,
        r#"
        BEGIN TRANSACTION;

        RETURN UPDATE ONLY $service_id SET
            organization = NONE,
            registration = NONE
        WHERE organization = $organization_id
        RETURN BEFORE;

        COMMIT TRANSACTION;
        "#,
    )
    .bind("service_id", service_id)
    .bind("organization_id", organization_id)
    .execute()
    .await
    .error_with_slug("service-unbind-query-failed")?
    .decode()
    .error_with_slug("service-unbind-result-parse-failed")?;
    let record = wasmcloud_utils::skir_domain_result!(UnbindServiceResponse, result);

    let Some(record) = record else {
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
