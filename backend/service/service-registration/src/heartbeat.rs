use std::collections::HashMap;
use wasmcloud_utils::database::service::ServiceStatusRecord;

use otel_wasi::ResultWithSlug;
use wasmcloud_utils::{
    database::{RecordId, transaction_query},
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

    update_state(
        &RecordId::new("service", service_id),
        &ServiceStatusRecord::Online,
    )
    .await
}

#[tracing::instrument]
pub(crate) async fn update_state(
    service_id: &RecordId,
    status: &ServiceStatusRecord,
) -> Result<(), otel_wasi::Error> {
    let result = transaction_query!(
        Option<ServiceRecord>,
        r#"
        BEGIN TRANSACTION;

        RETURN UPDATE ONLY $service_id SET state = {
            status: $status,
            last_seen: time::now()
        }
        RETURN AFTER;

        COMMIT TRANSACTION;
        "#,
    )
    .bind("service_id", service_id)
    .bind("status", status.to_string())
    .execute()
    .await
    .error_with_slug("service-state-update-query-failed")?
    .decode()
    .error_with_slug("service-state-update-result-parse-failed")?;
    let record = match result {
        wasmcloud_utils::database::TransactionOutcome::Committed(record) => record,
        wasmcloud_utils::database::TransactionOutcome::Rejected(error) => {
            return Err(otel_wasi::Error::new(
                "service-state-update-rejected",
                error.message(),
            ));
        }
    };

    let Some(record) = record else {
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
