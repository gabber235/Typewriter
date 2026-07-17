use std::collections::HashMap;
use wasmcloud_utils::database::service::ServiceStatusRecord;

use otel_wasi::ResultWithSlug;
use surrealdb_component_sdk::query;
use wasmcloud_utils::{
    decode_skir, extract_param,
    skir::base::service::v1::{
        lifecycle::ServiceHeartbeatNotification, organization::WatchOrganizationServicesResponse,
    },
    wasmcloud::messaging::types::BrokerMessage,
};

use wasmcloud_utils::database::service::ServiceRecord;

#[tracing::instrument(skip(msg, params))]
pub async fn handle_heartbeat(
    msg: BrokerMessage,
    params: HashMap<String, String>,
) -> Result<(), otel_wasi::Error> {
    let service_id = extract_param!(params, service_id)?;
    otel_wasi::main_attribute!("service.id" = service_id.to_string());
    let _ = decode_skir!(ServiceHeartbeatNotification, &msg.body)?;

    update_state(service_id, &ServiceStatusRecord::Online).await
}

#[tracing::instrument]
pub(crate) async fn update_state(
    service_id: &str,
    status: &ServiceStatusRecord,
) -> Result<(), otel_wasi::Error> {
    let records = query(
        r#"
        UPDATE type::record('service', $service_id) SET state = {
            status: $status,
            last_seen: time::now()
        }
        RETURN AFTER
        "#,
    )
    .bind("service_id", service_id)
    .bind("status", status.to_string())
    .execute()
    .await
    .error_with_slug("service-state-update-query-failed")?
    .take::<Option<ServiceRecord>>(0)
    .error_with_slug("service-state-update-result-parse-failed")?;

    let Some(record) = records.into_iter().next() else {
        return Err(otel_wasi::wasi_error!(
            "service-state-update-not-found",
            "service not found",
        ));
    };
    let Some(organization) = record.organization.clone() else {
        return Ok(());
    };
    let service = record.try_into()?;

    wasmcloud_utils::skir_subjects::organization_services(organization.key)
        .publish(WatchOrganizationServicesResponse::Update(Box::new(service)))
        .await?;

    otel_wasi::main_attribute!("service.state" = status.to_string());
    Ok(())
}
