use std::collections::HashMap;

use wasmcloud_utils::{
    decode_skir, extract_param, skir::base::service::v1::lifecycle::ServiceShutdownNotification,
    wasmcloud::messaging::types::BrokerMessage,
};

#[tracing::instrument(skip(msg, params))]
pub async fn handle_shutdown(
    msg: BrokerMessage,
    params: HashMap<String, String>,
) -> Result<(), otel_wasi::Error> {
    let service_id = extract_param!(params, service_id)?;
    otel_wasi::main_attribute!("service.id" = service_id.to_string());
    let _ = decode_skir!(ServiceShutdownNotification, &msg.body)?;

    crate::heartbeat::update_state(service_id, &crate::ServiceStatusRecord::Offline).await
}
