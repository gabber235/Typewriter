//! Handles orderly service termination notifications.
//!
//! Shutdown uses the same state owner as heartbeat. It validates the lifecycle payload, marks the
//! service offline, and publishes the bound service projection when an organization is present.

use wasmcloud_utils::database::{RecordId, service::ServiceStatusRecord};

use wasmcloud_utils::{
    skir::base::service::v1::lifecycle::ServiceShutdownNotification,
    transport_routes::ServiceScope, wasmcloud::messaging::types::NatsMessage,
};

#[tracing::instrument(skip(msg, scope, _event))]
/// Marks the identified service offline after validating its shutdown notification.
///
/// The shared `heartbeat::update_state` path keeps shutdown and heartbeat consistent for the
/// state write, timestamp, missing service error, and conditional organization publication.
pub async fn handle_shutdown(
    msg: NatsMessage,
    scope: ServiceScope,
    _event: ServiceShutdownNotification,
) -> Result<(), otel_wasi::Error> {
    let _ = msg;
    otel_wasi::main_attribute!("service.id" = scope.service.to_string());

    crate::heartbeat::update_state(
        &RecordId::new("service", scope.service.as_str()),
        &ServiceStatusRecord::Offline,
    )
    .await
}
