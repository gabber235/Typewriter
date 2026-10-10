use wasmcloud_utils::{
    database::RecordId,
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
#[tracing::instrument(skip_all)]
pub async fn handle_watch(
    _msg: NatsMessage,
    scope: wasmcloud_utils::transport_routes::UserScope,
    _request: WatchUserOrganizationsRequest,
) -> Result<WatchUserOrganizationsResponse, otel_wasi::Error> {
    let user_id = scope.user.as_str();
    otel_wasi::main_attribute!("user.id" = user_id.to_string());
    wasmcloud_utils::database::organization::snapshots::organizations(RecordId::new(
        "user", user_id,
    ))
    .await
}
