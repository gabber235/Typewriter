//! Serves organization role reads over the user scoped messaging API.
//!
//! The generated route admits the organization actor scope. Role records are read from the
//! organization role table and encoded as the SKIR response expected by the panel and component tests.

wit_bindgen::generate!({
    with: {
        "wasmcloud:nats/jetstream@0.1.0": wasmcloud_utils::wasmcloud::messaging::jetstream,
        "wasmcloud:nats/core@0.1.0": wasmcloud_utils::wasmcloud::messaging::core,
        "wasmcloud:nats/core-handler@0.1.0": wasmcloud_utils::wasmcloud::messaging::core_handler,
    },
    generate_all,
});

mod watch;

use wasmcloud_utils::{
    transport_routes::organization_roles::{Handlers, dispatch},
    wasmcloud::messaging::{core_handler::Guest, types},
};

struct Component;
wasmcloud_utils::export!(Component);

impl Guest for Component {
    #[otel_wasi::wasi_instrument(service = "organization-roles", export)]
    async fn handle_message(msg: types::NatsMessage) -> Result<(), otel_wasi::Error> {
        dispatch(
            msg,
            Handlers {
                organization_roles_watch: watch::handle_watch,
            },
        )
        .await
    }
}
