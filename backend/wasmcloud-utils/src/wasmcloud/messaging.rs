//! Messaging helpers shared by wasmCloud components.
//!
//! This module owns the transport boundary for broker messages, including trace context
//! propagation, request and reply error slugs, and typed SKIR replies. Generated transport
//! routes own subject parsing and construction.

use otel_wasi::ResultWithSlug;

pub use crate::bindings::exports::wasmcloud::nats::*;
pub use crate::bindings::wasmcloud::nats::*;

fn current_trace_headers() -> Option<Vec<types::HeaderEntry>> {
    otel_wasi::current_propagation_context().map(|context| {
        let mut headers = vec![types::HeaderEntry {
            name: "traceparent".into(),
            value: context.traceparent,
        }];
        if let Some(value) = context.tracestate {
            headers.push(types::HeaderEntry {
                name: "tracestate".into(),
                value,
            });
        }
        headers
    })
}

/// Reply on the subject carried by a broker message.
///
/// The input must contain `reply_to`. The reply has no nested reply target and uses
/// `message-reply-failed` for broker failures, or `message-no-reply-to` when the input
/// cannot be answered.
pub async fn reply(
    reply_to: types::NatsMessage,
    data: impl Into<Vec<u8>>,
) -> Result<(), otel_wasi::Error> {
    if let Some(reply_to) = reply_to.reply_to {
        core::publish(types::NatsMessage {
            subject: reply_to,
            reply_to: None,
            body: data.into(),
            headers: current_trace_headers(),
        })
        .await
        .map_err(|e| otel_wasi::Error::new("message-reply-failed", e.to_string()))
    } else {
        Err(otel_wasi::Error::new(
            "message-no-reply-to",
            "No reply_to field in message",
        ))
    }
}

/// Publish a message with an explicit reply subject.
///
/// This is the low level operation for callers that need to choose the reply route.
/// Broker failures are returned as `message-send-failed`.
pub async fn send(
    subject: String,
    reply_to: String,
    data: impl Into<Vec<u8>>,
) -> Result<(), otel_wasi::Error> {
    core::publish(types::NatsMessage {
        subject,
        reply_to: Some(reply_to),
        body: data.into(),
        headers: current_trace_headers(),
    })
    .await
    .error_with_slug("message-send-failed")
}

/// Publish a message without a reply target.
///
/// Use this for notifications and other one way messages. Broker failures are returned
/// as `message-publish-failed`.
pub async fn publish(subject: String, data: impl Into<Vec<u8>>) -> Result<(), otel_wasi::Error> {
    core::publish(types::NatsMessage {
        subject,
        reply_to: None,
        body: data.into(),
        headers: current_trace_headers(),
    })
    .await
    .error_with_slug("message-publish-failed")
}

/// Send a request and wait up to five seconds for its broker reply.
///
/// The returned message is untyped because the caller owns response decoding. Broker
/// failures and timeout are returned as `message-request-failed`.
pub async fn request(
    subject: String,
    data: impl Into<Vec<u8>>,
) -> Result<types::NatsMessage, otel_wasi::Error> {
    core::request(
        types::NatsMessage {
            subject,
            body: data.into(),
            reply_to: None,
            headers: current_trace_headers(),
        },
        5000,
    )
    .await
    .error_with_slug("message-request-failed")
}

/// Publish durably through JetStream and return its typed acknowledgement.
pub async fn persist(
    subject: String,
    body: Vec<u8>,
) -> Result<jetstream::PublishAck, otel_wasi::Error> {
    jetstream::publish(types::NatsMessage {
        subject,
        body,
        reply_to: None,
        headers: current_trace_headers(),
    })
    .await
    .error_with_slug("message-persist-failed")
}

/// Serialize and reply with a handler result while preserving typed SKIR outcomes.
///
/// A successful result is sent as its selected success or domain variant. An error sends
/// the enum's generic `InternalError` variant, then returns the original error so the
/// dispatch boundary can retain its logging and tracing context.
pub async fn reply_handler_result<R>(
    msg: types::NatsMessage,
    result: Result<R, otel_wasi::Error>,
) -> Result<(), otel_wasi::Error>
where
    R: crate::SkirResponse,
{
    match result {
        Ok(response) => reply_response(msg, response).await,
        Err(error) => {
            let response = R::internal_error();

            otel_wasi::main_attribute!(
                "messaging.response.variant" = response.variant_slug(),
                "messaging.response.outcome" = crate::SkirResponseOutcome::InternalError.as_str(),
                "messaging.response.success" = false,
            );

            reply(msg, response.to_skir_bytes()).await?;
            Err(error)
        }
    }
}

async fn reply_response<R>(msg: types::NatsMessage, response: R) -> Result<(), otel_wasi::Error>
where
    R: crate::SkirResponse,
{
    let outcome = response.outcome();
    let slug = response.variant_slug();
    let message = response.variant_message();

    otel_wasi::main_attribute!(
        "messaging.response.variant" = slug,
        "messaging.response.outcome" = outcome.as_str(),
        "messaging.response.success" = outcome == crate::SkirResponseOutcome::Success,
    );

    if outcome == crate::SkirResponseOutcome::DomainError {
        otel_wasi::main_attribute!("messaging.response.message" = message.clone(),);
    }

    reply(msg, response.to_skir_bytes()).await?;

    match outcome {
        crate::SkirResponseOutcome::Success | crate::SkirResponseOutcome::DomainError => Ok(()),
        crate::SkirResponseOutcome::InternalError => Err(otel_wasi::Error::new(slug, message)),
    }
}
