//! Broker entrypoint for service registration, liveness, binding, and host topology.
//!
//! Lifecycle messages use service scoped subjects. User scoped requests use the dispatch table
//! below. Mutations persist database state first, then publish the typed watch event that backs
//! panel and runtime consumers. Host execution has a second stream because the runtime consumes
//! desired assignments and reports observations independently from organization topology.

wit_bindgen::generate!({
    with: {
        "wasmcloud:nats/jetstream@0.1.0": wasmcloud_utils::wasmcloud::messaging::jetstream,
        "wasmcloud:nats/core@0.1.0": wasmcloud_utils::wasmcloud::messaging::core,
        "wasmcloud:nats/core-handler@0.1.0": wasmcloud_utils::wasmcloud::messaging::core_handler,
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
    wasmcloud::messaging::{core_handler::Guest, parse_subject, types},
};

struct Component;
wasmcloud_utils::export!(Component);

impl Guest for Component {
    #[otel_wasi::wasi_instrument(service = "service-registration", export)]
    async fn handle_message(msg: types::NatsMessage) -> Result<(), otel_wasi::Error> {
        handle_message_async(msg).await
    }
}

/// Routes lifecycle subjects before delegating request and watch subjects to their handlers.
///
/// Heartbeat and shutdown are matched explicitly because they have no request response. All
/// other subjects are expanded by `dispatch_actions!`, which supplies the path parameters used by
/// the handlers.
async fn handle_message_async(msg: types::NatsMessage) -> Result<(), otel_wasi::Error> {
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
