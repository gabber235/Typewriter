//! User scoped organization operations for the authenticated messaging surface.
//!
//! The component owns organization creation and user views for memberships and pending join
//! requests. Organization records and membership edges are canonical database state. Watch
//! handlers expose snapshots, while successful mutations persist sequenced changes on the user
//! or organization stream that owns each projection.

wit_bindgen::generate!({
    with: {
        "wasmcloud:nats/jetstream@0.1.0": wasmcloud_utils::wasmcloud::messaging::jetstream,
        "wasmcloud:nats/core@0.1.0": wasmcloud_utils::wasmcloud::messaging::core,
        "wasmcloud:nats/core-handler@0.1.0": wasmcloud_utils::wasmcloud::messaging::core_handler,
    },
    generate_all,
});

mod create;
mod join_requests;
mod watch;

use wasmcloud_utils::{
    dispatch_actions,
    wasmcloud::messaging::{core_handler::Guest, types},
};

struct Component;
wasmcloud_utils::export!(Component);

impl Guest for Component {
    #[otel_wasi::wasi_instrument(service = "user-organization", export)]
    async fn handle_message(msg: types::NatsMessage) -> Result<(), otel_wasi::Error> {
        handle_message_async(msg).await
    }
}

async fn handle_message_async(msg: types::NatsMessage) -> Result<(), otel_wasi::Error> {
    dispatch_actions!(
        msg,
        "typewriter.from.user.<user_id>.organization.<action>",
        "create" => async create::handle_create,
        "watch" => async watch::handle_watch,
        "join_requests.watch" => async join_requests::handle_watch,
        "join_requests.request" => async join_requests::handle_request,
        "join_requests.cancel" => async join_requests::handle_cancel,
    )
}
