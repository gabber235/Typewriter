wit_bindgen::generate!({
    with: {
        "wasmcloud:messaging/consumer@0.3.0": wasmcloud_utils::wasmcloud::messaging::consumer,
        "wasmcloud:messaging/handler@0.3.0": wasmcloud_utils::wasmcloud::messaging::handler,
    },
    generate_all,
});

mod create;
mod join_requests;
mod watch;

use wasmcloud_utils::{
    dispatch_actions,
    wasmcloud::messaging::{handler::Guest, types},
};

struct Component;
wasmcloud_utils::export!(Component);

impl Guest for Component {
    #[otel_wasi::wasi_instrument(service = "user_organization", export)]
    async fn handle_message(msg: types::BrokerMessage) -> Result<(), otel_wasi::Error> {
        handle_message_async(msg).await
    }
}

async fn handle_message_async(msg: types::BrokerMessage) -> Result<(), otel_wasi::Error> {
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
