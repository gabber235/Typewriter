wit_bindgen::generate!({
    with: {
        "wasmcloud:messaging/consumer@0.4.0": wasmcloud_utils::wasmcloud::messaging::consumer,
        "wasmcloud:messaging/handler@0.4.0": wasmcloud_utils::wasmcloud::messaging::handler,
    },
    generate_all,
});

use wasmcloud_utils::wasmcloud::messaging::{self, handler::Guest, types};

struct Component;
wasmcloud_utils::export!(Component);

impl Guest for Component {
    async fn handle_message(message: types::BrokerMessage) -> Result<(), String> {
        if message.subject == "dependency.echo" {
            messaging::reply(message.clone(), message.body)
                .await
                .map_err(|error| error.to_string())?;
        }
        Ok(())
    }
}
