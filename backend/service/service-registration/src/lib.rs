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
    dispatch_event_route, dispatch_route,
    transport_routes::{
        HostExecutionReportRoute, HostExecutionWatchRoute, OrganizationServiceUpdateRoute,
        OrganizationServicesWatchRoute, OrganizationTopologyWatchRoute,
        RegistrationLeaseEnsureRoute, ServiceBindRoute, ServiceBindingQueryRoute,
        ServiceHeartbeatRoute, ServiceHostRegisterRoute, ServiceMessagingScopeRoute,
        ServiceShutdownRoute, ServiceTopologyConfigureRoute, ServiceUnbindRoute, unmatched_route,
    },
    wasmcloud::messaging::{core_handler::Guest, types},
};

struct Component;
wasmcloud_utils::export!(Component);

impl Guest for Component {
    #[otel_wasi::wasi_instrument(service = "service-registration", export)]
    async fn handle_message(msg: types::NatsMessage) -> Result<(), otel_wasi::Error> {
        handle_message_async(msg).await
    }
}

/// Routes generated request and event contracts to their typed handlers.
async fn handle_message_async(msg: types::NatsMessage) -> Result<(), otel_wasi::Error> {
    dispatch_event_route!(msg, ServiceHeartbeatRoute, heartbeat::handle_heartbeat);
    dispatch_route!(msg, ServiceBindingQueryRoute, status::handle_binding);
    dispatch_route!(msg, RegistrationLeaseEnsureRoute, status::handle_lease);
    dispatch_route!(msg, ServiceMessagingScopeRoute, messaging_scope::handle);
    dispatch_route!(msg, ServiceHostRegisterRoute, register_host::handle);
    dispatch_route!(msg, HostExecutionWatchRoute, host_execution::handle_watch);
    dispatch_route!(msg, HostExecutionReportRoute, host_execution::handle_report);
    dispatch_route!(msg, ServiceBindRoute, bind::handle_bind);
    dispatch_route!(msg, OrganizationServicesWatchRoute, watch::handle_watch);
    dispatch_route!(msg, OrganizationServiceUpdateRoute, update::handle_update);
    dispatch_route!(msg, ServiceUnbindRoute, unbind::handle_unbind);
    dispatch_route!(
        msg,
        ServiceTopologyConfigureRoute,
        configure_topology::handle_configure
    );
    dispatch_route!(
        msg,
        OrganizationTopologyWatchRoute,
        watch_topology::handle_watch
    );

    dispatch_event_route!(msg, ServiceShutdownRoute, shutdown::handle_shutdown);

    Err(unmatched_route(&msg, "dispatch-action-unknown"))
}
