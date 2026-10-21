//! Handles orderly service termination notifications.
//!
//! Shutdown uses the same state owner as heartbeat. It validates the lifecycle payload, marks the
//! service offline, and publishes the bound service projection when an organization is present.

use wasmcloud_utils::{
    database::RecordId,
    skir::base::service::v1::{lifecycle::ServiceShutdownNotification, service::ServiceStatus},
    transport::ServiceScope,
};

#[tracing::instrument(skip(scope, _event))]
/// Marks the identified service offline after validating its shutdown notification.
///
/// The shared `heartbeat::update_state` path keeps shutdown and heartbeat consistent for the
/// state write, timestamp, missing service error, and conditional organization publication.
pub async fn handle_shutdown(
    scope: ServiceScope,
    _event: ServiceShutdownNotification,
) -> Result<(), otel_wasi::Error> {
    otel_wasi::main_attribute!("service.id" = scope.service.to_string());

    crate::heartbeat::update_state(
        &RecordId::new("service", scope.service.as_str()),
        ServiceStatus::Offline,
    )
    .await
}
