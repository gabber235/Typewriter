//! Records service liveness from heartbeat notifications.
//!
//! A heartbeat is accepted only after its Skir payload decodes. The service state is updated with
//! the current time. Bound services additionally publish the resulting service projection to
//! their organization's watch subject; unbound services remain database only.

use std::collections::HashMap;
use wasmcloud_utils::database::service::ServiceStatusRecord;

use otel_wasi::ResultWithSlug;
use wasmcloud_utils::{
    database::{RecordId, transaction_query},
    decode_skir, extract_param,
    skir::base::service::v1::{
        lifecycle::ServiceHeartbeatNotification, organization::WatchOrganizationServicesResponse,
    },
    wasmcloud::messaging::types::NatsMessage,
};

use wasmcloud_utils::database::service::ServiceRecord;

#[tracing::instrument(skip(msg, params))]
/// Marks the service online and propagates the new state when it belongs to an organization.
///
/// The notification body carries no state to merge. Its subject identifies the service, while
/// `update_state` owns the database write and the conditional organization publication.
pub async fn handle_heartbeat(
    msg: NatsMessage,
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
/// Writes service liveness and publishes the bound service projection.
///
/// The state write and `last_seen` timestamp are one database update. A missing service is an
/// error. A service without an organization is valid during onboarding and produces no watch
/// event because there is no organization projection to update.
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
