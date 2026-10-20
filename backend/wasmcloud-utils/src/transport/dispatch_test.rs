//! Exercises a generated component dispatcher against the hand written runtime.

use std::cell::Cell;

use otel_wasi::{Error, WasiError as _};

use crate::skirout::base::service::v1::lifecycle::ServiceHeartbeatNotification;
use crate::transport::ServiceScope;
use crate::transport::test_support::{block_on, nats_message};
use crate::transport_routes::service_registration::{Handlers, SUBSCRIPTIONS, dispatch};

/// Service registration handlers where only the heartbeat handler may run.
macro_rules! heartbeat_only {
    ($heartbeat:expr) => {
        Handlers {
            service_binding_query: async |_, _| unreachable!(),
            registration_lease_ensure: async |_, _| unreachable!(),
            service_messaging_scope: async |_, _| unreachable!(),
            service_bind: async |_, _| unreachable!(),
            organization_services_watch: async |_, _| unreachable!(),
            organization_service_update: async |_, _| unreachable!(),
            service_unbind: async |_, _| unreachable!(),
            service_topology_configure: async |_, _| unreachable!(),
            organization_topology_watch: async |_, _| unreachable!(),
            service_host_register: async |_, _| unreachable!(),
            host_execution_watch: async |_, _| unreachable!(),
            host_execution_report: async |_, _| unreachable!(),
            service_heartbeat: $heartbeat,
            service_shutdown: async |_, _| unreachable!(),
        }
    };
}

fn heartbeat_body() -> Vec<u8> {
    ServiceHeartbeatNotification::serializer().to_bytes(&ServiceHeartbeatNotification::default())
}

#[test]
fn unmatched_subject_reports_one_slug() {
    let msg = nats_message("typewriter.from.service.s1.execution.unknown", &[]);
    let error = block_on(dispatch(msg, heartbeat_only!(async |_, _| unreachable!()))).unwrap_err();
    assert_eq!(error.slug(), "transport-unmatched-subject");
}

#[test]
fn event_subject_reaches_its_handler_with_the_captured_scope() {
    let served = Cell::new(false);
    let msg = nats_message("typewriter.from.service.s1.heartbeat", &heartbeat_body());
    block_on(dispatch(
        msg,
        heartbeat_only!(async |scope: ServiceScope, _| -> Result<(), Error> {
            assert_eq!(scope.service.as_str(), "s1");
            served.set(true);
            Ok(())
        }),
    ))
    .unwrap();
    assert!(served.get());
}

#[test]
fn invalid_captured_token_fails_before_the_handler() {
    let msg = nats_message("typewriter.from.service.*.heartbeat", &heartbeat_body());
    let error = block_on(dispatch(msg, heartbeat_only!(async |_, _| unreachable!()))).unwrap_err();
    assert_eq!(error.slug(), "transport-invalid-token");
}

#[test]
fn subscriptions_list_one_exact_subject_per_matched_pattern() {
    assert!(SUBSCRIPTIONS.contains(&"typewriter.from.service.*.heartbeat"));
    assert!(SUBSCRIPTIONS.contains(&"service.*.binding.query"));
    assert!(SUBSCRIPTIONS.iter().all(|subject| !subject.contains('>')));
}
