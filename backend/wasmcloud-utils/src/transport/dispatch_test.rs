//! Exercises a generated component dispatcher against the hand written runtime.

use std::cell::Cell;

use otel_wasi::{Error, WasiError as _};

use crate::transport::ServiceScope;
use crate::transport::test_support::{block_on, heartbeat_body, heartbeat_only, nats_message};
use crate::transport_routes::service_registration::{SUBSCRIPTIONS, dispatch};

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
fn every_subscription_is_listed_once_and_reaches_a_route() {
    let mut seen = std::collections::HashSet::new();
    for subscription in SUBSCRIPTIONS {
        assert!(seen.insert(subscription), "{subscription} is listed twice");
        assert!(!subscription.contains('>'), "{subscription} is not exact");

        let subject = subscription.replace('*', "s1");
        let error = block_on(dispatch(
            nats_message(&subject, b"not skir"),
            heartbeat_only!(async |_, _| unreachable!()),
        ))
        .unwrap_err();
        assert_ne!(
            error.slug(),
            "transport-unmatched-subject",
            "{subscription} matches no route"
        );
    }
}
