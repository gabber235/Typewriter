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
mod host_configuration_input;
mod host_execution;
mod messaging_scope;
mod publication;
mod register_host;
mod shutdown;
mod status;
mod unbind;
mod update;
mod utils;
mod watch;
mod watch_topology;

use wasmcloud_utils::{
    transport_routes::service_registration::{Handlers, dispatch},
    wasmcloud::messaging::{core_handler::Guest, types},
};

struct Component;
wasmcloud_utils::export!(Component);

impl Guest for Component {
    #[otel_wasi::wasi_instrument(service = "service-registration", export)]
    async fn handle_message(msg: types::NatsMessage) -> Result<(), otel_wasi::Error> {
        dispatch(
            msg,
            Handlers {
                service_binding_query: status::handle_binding,
                registration_lease_ensure: status::handle_lease,
                service_messaging_scope: messaging_scope::handle,
                service_bind: bind::handle_bind,
                organization_services_watch: watch::handle_watch,
                organization_service_update: update::handle_update,
                service_unbind: unbind::handle_unbind,
                service_topology_configure: configure_topology::handle_configure,
                organization_topology_watch: watch_topology::handle_watch,
                service_host_register: register_host::handle,
                host_execution_watch: host_execution::handle_watch,
                host_execution_report: host_execution::handle_report,
                service_heartbeat: heartbeat::handle_heartbeat,
                service_shutdown: shutdown::handle_shutdown,
            },
        )
        .await
    }
}
