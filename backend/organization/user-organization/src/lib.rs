wit_bindgen::generate!({
    with: {
        "wasmcloud:messaging/consumer@0.2.0": wasmcloud_utils::wasmcloud::messaging::consumer,
        "wasmcloud:messaging/handler@0.2.0": wasmcloud_utils::wasmcloud::messaging::handler,
    },
    generate_all,
});

mod create;
mod join_requests;
mod list;

use otel_wasi::main_attribute;
use wasmcloud_utils::wasmcloud::messaging::{handler::Guest, types};

struct Component;
wasmcloud_utils::export!(Component);

impl Guest for Component {
    #[otel_wasi::wasi_instrument(service = "user_organization", export)]
    fn handle_message(msg: types::BrokerMessage) -> Result<(), otel_wasi::Error> {
        main_attribute!("messaging.destination.name" = msg.subject.clone());

        wasmcloud_utils::dispatch_actions!(
            msg,
            "typewriter.in.user.<user_id>.organization.<action>",
            "create" => create::handle_create,
            "list" => list::handle_list,
            "join_requests.list" => join_requests::handle_list,
            "join_requests.request" => join_requests::handle_request,
            "join_requests.cancel" => join_requests::handle_cancel,
        )
    }
}
