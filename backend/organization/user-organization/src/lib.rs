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
    transport_routes::user_organization::{Handlers, dispatch},
    wasmcloud::messaging::{core_handler::Guest, types},
};

struct Component;
wasmcloud_utils::export!(Component);

impl Guest for Component {
    #[otel_wasi::wasi_instrument(service = "user-organization", export)]
    async fn handle_message(msg: types::NatsMessage) -> Result<(), otel_wasi::Error> {
        dispatch(
            msg,
            Handlers {
                user_organization_create: create::handle_create,
                user_organizations_watch: watch::handle_watch,
                user_join_requests_watch: join_requests::handle_watch,
                user_join_request_submit: join_requests::handle_request,
                user_join_request_cancel: join_requests::handle_cancel,
            },
        )
        .await
    }
}
