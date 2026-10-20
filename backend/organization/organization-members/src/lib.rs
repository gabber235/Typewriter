//! Organization scoped membership administration over the organization read models.
//!
//! Requests arrive on user scoped subjects and carry the organization identifier in the subject
//! parameters. Mutations execute their database transaction first, then publish sequenced changes
//! for every affected projection. Watch operations return a snapshot containing the current
//! projection and its sequence. The database functions own validation and invariants; these
//! handlers own protocol decoding, response conversion, and event publication.

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
    transport_routes::organization_members::{Handlers, dispatch},
    wasmcloud::messaging::{core_handler::Guest, types},
};

struct Component;
wasmcloud_utils::export!(Component);

impl Guest for Component {
    #[otel_wasi::wasi_instrument(service = "organization-members", export)]
    async fn handle_message(msg: types::NatsMessage) -> Result<(), otel_wasi::Error> {
        dispatch(
            msg,
            Handlers {
                organization_members_watch: members::handle_watch,
                organization_members_update: members::handle_update,
                organization_member_remove: members::handle_remove,
                organization_join_requests_watch: join_requests::handle_watch,
                organization_join_requests_approve: join_requests::handle_approve,
                organization_join_request_decline: join_requests::handle_decline,
                organization_join_codes_watch: join_codes::handle_watch,
                organization_join_code_generate: join_codes::handle_generate,
                organization_join_code_revoke: join_codes::handle_revoke,
            },
        )
        .await
    }
}
