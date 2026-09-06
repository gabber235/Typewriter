wit_bindgen::generate!({
    with: {
        "wasmcloud:messaging/consumer@0.4.0": wasmcloud_utils::wasmcloud::messaging::consumer,
        "wasmcloud:messaging/handler@0.4.0": wasmcloud_utils::wasmcloud::messaging::handler,
    },
    generate_all,
});

mod bind;
mod configure_topology;
mod heartbeat;
mod host_execution;
mod messaging_scope;
mod register_host;
mod shutdown;
mod status;
mod unbind;
mod update;
mod utils;
mod watch;
mod watch_topology;

use wasmcloud_utils::{
    dispatch_actions,
    wasmcloud::messaging::{handler::Guest, parse_subject, types},
};

struct Component;
wasmcloud_utils::export!(Component);

impl Guest for Component {
    #[otel_wasi::wasi_instrument(service = "service-registration", export)]
    async fn handle_message(msg: types::BrokerMessage) -> Result<(), otel_wasi::Error> {
        handle_message_async(msg).await
    }
}

async fn handle_message_async(msg: types::BrokerMessage) -> Result<(), otel_wasi::Error> {
    if let Ok(params) = parse_subject(
        "[typewriter.from.]service.<service_id>.heartbeat",
        &msg.subject,
    ) {
        return heartbeat::handle_heartbeat(msg, params).await;
    }

    if let Ok(params) = parse_subject(
        "[typewriter.from.]service.<service_id>.shutdown",
        &msg.subject,
    ) {
        return shutdown::handle_shutdown(msg, params).await;
    }

    dispatch_actions!(
        msg,
        services: "[typewriter.from.]service.<service_id>",
        user_services: "[typewriter.from.]user.<user_id>.organization.<org_id>.services",
        user_topology: "[typewriter.from.]user.<user_id>.organization.<org_id>.topology",
        host_execution: "[typewriter.from.]service.<service_id>.execution";
        "{services}.status" => async status::handle_status,
        "{services}.messaging.scope" => async messaging_scope::handle,
        "{user_services}.bind" => async bind::handle_bind,
        "{user_services}.watch" => async watch::handle_watch,
        "{user_services}.update" => async update::handle_update,
        "{user_services}.unbind" => async unbind::handle_unbind,
        "{user_topology}.configure" => async configure_topology::handle_configure,
        "{user_topology}.watch" => async watch_topology::handle_watch,
        "{host_execution}.register" => async register_host::handle,
        "{host_execution}.watch" => async host_execution::handle_watch,
        "{host_execution}.report" => async host_execution::handle_report,
    )
}
