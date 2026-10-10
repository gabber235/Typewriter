//! Organization scoped membership administration over the organization read models.
//!
//! Requests arrive on user scoped subjects and carry the organization identifier in the subject
//! parameters. Mutations execute their database transaction first, then publish sequenced changes
//! for every affected projection. Watch operations return a snapshot containing the current
//! projection and its sequence. The database functions own validation, invariants, and mutation
//! receipts; these handlers own protocol decoding, response conversion, and event publication.

wit_bindgen::generate!({
    with: {
        "wasmcloud:nats/jetstream@0.1.0": wasmcloud_utils::wasmcloud::messaging::jetstream,
        "wasmcloud:nats/core@0.1.0": wasmcloud_utils::wasmcloud::messaging::core,
        "wasmcloud:nats/core-handler@0.1.0": wasmcloud_utils::wasmcloud::messaging::core_handler,
    },
    generate_all,
});

mod join_codes;
mod join_requests;
mod members;

use wasmcloud_utils::{
    dispatch_route,
    transport_routes::{
        OrganizationJoinCodeGenerateRoute, OrganizationJoinCodeRevokeRoute,
        OrganizationJoinCodesWatchRoute, OrganizationJoinRequestDeclineRoute,
        OrganizationJoinRequestsApproveRoute, OrganizationJoinRequestsWatchRoute,
        OrganizationMemberRemoveRoute, OrganizationMembersUpdateRoute,
        OrganizationMembersWatchRoute, unmatched_route,
    },
    wasmcloud::messaging::{core_handler::Guest, types},
};

struct Component;
wasmcloud_utils::export!(Component);

impl Guest for Component {
    #[otel_wasi::wasi_instrument(service = "organization-members", export)]
    async fn handle_message(msg: types::NatsMessage) -> Result<(), otel_wasi::Error> {
        handle_message_async(msg).await
    }
}

async fn handle_message_async(msg: types::NatsMessage) -> Result<(), otel_wasi::Error> {
    dispatch_route!(msg, OrganizationMembersWatchRoute, members::handle_watch);
    dispatch_route!(msg, OrganizationMembersUpdateRoute, members::handle_update);
    dispatch_route!(msg, OrganizationMemberRemoveRoute, members::handle_remove);
    dispatch_route!(
        msg,
        OrganizationJoinRequestsWatchRoute,
        join_requests::handle_watch
    );
    dispatch_route!(
        msg,
        OrganizationJoinRequestsApproveRoute,
        join_requests::handle_approve
    );
    dispatch_route!(
        msg,
        OrganizationJoinRequestDeclineRoute,
        join_requests::handle_decline
    );
    dispatch_route!(
        msg,
        OrganizationJoinCodesWatchRoute,
        join_codes::handle_watch
    );
    dispatch_route!(
        msg,
        OrganizationJoinCodeGenerateRoute,
        join_codes::handle_generate
    );
    dispatch_route!(
        msg,
        OrganizationJoinCodeRevokeRoute,
        join_codes::handle_revoke
    );
    Err(unmatched_route(&msg, "dispatch-action-unknown"))
}
