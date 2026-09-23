//! Handles orderly service termination notifications.
//!
//! Shutdown uses the same state owner as heartbeat. It validates the lifecycle payload, marks the
//! service offline, and publishes the bound service projection when an organization is present.

use std::collections::HashMap;
use wasmcloud_utils::database::{RecordId, service::ServiceStatusRecord};

use wasmcloud_utils::{
    decode_skir, extract_param, skir::base::service::v1::lifecycle::ServiceShutdownNotification,
    wasmcloud::messaging::types::NatsMessage,
};

#[tracing::instrument(skip(msg, params))]
/// Marks the identified service offline after validating its shutdown notification.
///
/// The shared `heartbeat::update_state` path keeps shutdown and heartbeat consistent for the
/// state write, timestamp, missing service error, and conditional organization publication.
pub async fn handle_shutdown(
    msg: NatsMessage,
    params: HashMap<String, String>,
) -> Result<(), otel_wasi::Error> {
    let service_id = extract_param!(params, service_id)?;
    otel_wasi::main_attribute!("service.id" = service_id.to_string());
    let _ = decode_skir!(ServiceShutdownNotification, &msg.body)?;

    crate::heartbeat::update_state(
        &RecordId::new("service", service_id),
        &ServiceStatusRecord::Offline,
    )
    .await
}
