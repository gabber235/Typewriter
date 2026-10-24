//! Helpers for unit testing the transport runtime on the host.

use std::future::Future;
use std::pin::pin;
use std::task::{Context, Poll, Waker};

use crate::wasmcloud::messaging::types::NatsMessage;

/// Runs a future that completes without waiting, as every transport path that reaches no broker
/// call does.
pub(crate) fn block_on<F: Future>(future: F) -> F::Output {
    let mut future = pin!(future);
    match future
        .as_mut()
        .poll(&mut Context::from_waker(Waker::noop()))
    {
        Poll::Ready(output) => output,
        Poll::Pending => panic!("transport test future waited on a broker call"),
    }
}

/// A received message without reply subject or headers.
pub(crate) fn nats_message(subject: &str, body: &[u8]) -> NatsMessage {
    NatsMessage {
        subject: subject.to_owned(),
        body: body.to_vec(),
        reply_to: None,
        headers: None,
    }
}
