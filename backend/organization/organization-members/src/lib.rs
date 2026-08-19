wit_bindgen::generate!({
    with: {
        "wasmcloud:messaging/consumer@0.4.0": wasmcloud_utils::wasmcloud::messaging::consumer,
        "wasmcloud:messaging/handler@0.4.0": wasmcloud_utils::wasmcloud::messaging::handler,
    },
    generate_all,
});

mod join_codes;
mod join_requests;
mod members;

use wasmcloud_utils::{
    dispatch_actions,
    wasmcloud::messaging::{handler::Guest, types},
};

struct Component;
wasmcloud_utils::export!(Component);

impl Guest for Component {
    #[otel_wasi::wasi_instrument(service = "organization-members", export)]
    async fn handle_message(msg: types::BrokerMessage) -> Result<(), otel_wasi::Error> {
        handle_message_async(msg).await
    }
}

async fn handle_message_async(msg: types::BrokerMessage) -> Result<(), otel_wasi::Error> {
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
