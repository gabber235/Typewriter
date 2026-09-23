use std::collections::HashMap;

use wasmcloud_utils::{
    database::RecordId,
    decode_skir, extract_param,
    skir::base::organization::v1::user::{
        WatchUserOrganizationsRequest, WatchUserOrganizationsResponse,
    },
    wasmcloud::messaging::types::NatsMessage,
};

/// Returns the current organization list for the user in the message subject.
///
/// The snapshot helper reads memberships and the user's organization sequence. Later membership
/// changes are delivered on the user's organization change stream, so callers can apply deltas or
/// request a fresh snapshot after a sequence gap.
#[tracing::instrument(skip(msg, params))]
pub async fn handle_watch(
    msg: NatsMessage,
    params: HashMap<String, String>,
) -> Result<WatchUserOrganizationsResponse, otel_wasi::Error> {
    let user_id = extract_param!(params, user_id)?;
    otel_wasi::main_attribute!("user.id" = user_id.to_string());
    let _request = decode_skir!(WatchUserOrganizationsRequest, &msg.body)?;

    wasmcloud_utils::database::organization::snapshots::organizations(RecordId::new(
        "user", user_id,
    ))
    .await
}
