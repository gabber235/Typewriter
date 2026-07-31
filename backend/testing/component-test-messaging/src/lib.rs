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
        match message.subject.as_str() {
            "test.publish" => messaging::publish("component.out".into(), message.body)
                .await
                .map_err(|error| error.to_string()),
            "test.request" => {
                let response = messaging::request("dependency.echo".into(), message.body)
                    .await
                    .map_err(|error| error.to_string())?;
                messaging::publish("component.result".into(), response.body)
                    .await
                    .map_err(|error| error.to_string())
            }
            _ => Ok(()),
        }
    }
}
