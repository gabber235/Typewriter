//! Synthetic messaging dependency used by the composed component fixture.
//!
//! It replies only to `dependency.echo`, returning the request body unchanged. The narrow subject
//! check proves that request delivery reaches the configured dependency rather than a general
//! catch all handler.

wit_bindgen::generate!({
    with: {
        "wasmcloud:nats/jetstream@0.1.0": wasmcloud_utils::wasmcloud::messaging::jetstream,
        "wasmcloud:nats/core@0.1.0": wasmcloud_utils::wasmcloud::messaging::core,
        "wasmcloud:nats/core-handler@0.1.0": wasmcloud_utils::wasmcloud::messaging::core_handler,
    },
    generate_all,
});

use wasmcloud_utils::wasmcloud::messaging::{self, core_handler::Guest, types};

struct Component;
wasmcloud_utils::export!(Component);

impl Guest for Component {
    /// Echoes dependency requests through the broker reply route.
    async fn handle_message(message: types::NatsMessage) -> Result<(), String> {
        // Ignore unrelated subjects so the dependency remains safe to compose with other routes.
        if message.subject == "dependency.echo" {
            messaging::reply(message.clone(), message.body)
                .await
                .map_err(|error| error.to_string())?;
        }
        Ok(())
    }
}
