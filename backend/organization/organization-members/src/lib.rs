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
    dispatch_actions,
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
    dispatch_actions!(msg, "typewriter.from.user.<user_id>.organization.<org_id>.members.<action>",
        "watch" => async members::handle_watch,
        "update" => async members::handle_update,
        "remove" => async members::handle_remove,
        "join_requests.watch" => async join_requests::handle_watch,
        "join_requests.approve" => async join_requests::handle_approve,
        "join_requests.decline" => async join_requests::handle_decline,
        "join_codes.watch" => async join_codes::handle_watch,
        "join_codes.generate" => async join_codes::handle_generate,
        "join_codes.revoke" => async join_codes::handle_revoke,
    )
}
