//! Messaging helpers shared by wasmCloud components.
//!
//! This module owns the transport boundary for broker messages, including trace context
//! propagation, payload framing, request and reply error slugs, and typed SKIR replies.
//! Generated transport routes own subject parsing and construction.

use otel_wasi::ResultWithSlug;

use crate::transport;

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
/// The input must contain `reply_to`. A reply above the generated chunk size travels as frames
/// (see [`crate::transport::plan_reply`]) paced by `pacing`. With credit, the last frame of each
/// window that is not the final frame goes out as a request on the requester's inbox, whose answer
/// must grant the next window within [`crate::transport_routes::FRAME_INACTIVITY_MS`]; without
/// credit every frame streams at once. A frame that cannot be sent, a missing credit
/// (`transport-credit-missing`), a failure answer (the slug of its failure), an unanswered window
/// end (`transport-credit-failed`) or a reply past its time to live
/// (`transport-transfer-interrupted`) is followed by an interrupted frame so the requester fails
/// at once. A reply above the reply ceiling sends one too large message and fails with
/// `transport-transfer-too-large`. Broker failures use `message-reply-failed`, and an input without
/// `reply_to` fails with `message-no-reply-to`.
pub async fn reply(
    reply_to: types::NatsMessage,
    data: impl Into<Vec<u8>>,
    pacing: transport::ReplyPacing,
) -> Result<(), otel_wasi::Error> {
    let Some(subject) = reply_to.reply_to else {
        return Err(otel_wasi::Error::new(
            "message-no-reply-to",
            "No reply_to field in message",
        ));
    };
    match transport::plan_reply(data.into()) {
        transport::PayloadPlan::Single(body) => publish_reply(&subject, body, Vec::new()).await,
        transport::PayloadPlan::TooLarge { size, frame } => {
            publish_reply(&subject, frame.body, frame.headers).await?;
            Err(otel_wasi::Error::new(
                "transport-transfer-too-large",
                format!("the reply of {size} bytes exceeds the transport limit"),
            ))
        }
        transport::PayloadPlan::Framed { payload_id, frames } => {
            transport::send_reply_frames(
                &mut ReplySink { subject: &subject },
                &payload_id,
                frames,
                pacing,
            )
            .await
        }
    }
}

/// The requester's reply subject, as the destination of a framed reply.
struct ReplySink<'a> {
    subject: &'a str,
}

impl transport::FrameSink for ReplySink<'_> {
    async fn publish(&mut self, frame: transport::PayloadFrame) -> Result<(), otel_wasi::Error> {
        publish_reply(self.subject, frame.body, frame.headers).await
    }

    async fn request(
        &mut self,
        frame: transport::PayloadFrame,
        timeout_ms: u32,
    ) -> Result<types::NatsMessage, otel_wasi::Error> {
        core::request(
            reply_message(self.subject, frame.body, frame.headers),
            timeout_ms,
        )
        .await
        .error_with_slug("transport-credit-failed")
    }
}

async fn publish_reply(
    subject: &str,
    body: Vec<u8>,
    framing: Vec<(&'static str, String)>,
) -> Result<(), otel_wasi::Error> {
    core::publish(reply_message(subject, body, framing))
        .await
        .map_err(|e| otel_wasi::Error::new("message-reply-failed", e.to_string()))
}

fn reply_message(
    subject: &str,
    body: Vec<u8>,
    framing: Vec<(&'static str, String)>,
) -> types::NatsMessage {
    let mut headers = current_trace_headers().unwrap_or_default();
    headers.extend(framing.into_iter().map(|(name, value)| types::HeaderEntry {
        name: name.to_owned(),
        value,
    }));
    types::NatsMessage {
        subject: subject.to_owned(),
        reply_to: None,
        body,
        headers: (!headers.is_empty()).then_some(headers),
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
/// failures and timeout are returned as `message-request-failed`. Components receive only
/// the first reply message, so a framed reply fails as `transport-transfer-too-large`
/// instead of returning a partial body, and a failure frame fails with the slug of its
/// failure (see [`crate::transport::unusable_reply_slug`]).
pub async fn request(
    subject: String,
    data: impl Into<Vec<u8>>,
) -> Result<types::NatsMessage, otel_wasi::Error> {
    let reply = core::request(
        types::NatsMessage {
            subject,
            body: data.into(),
            reply_to: None,
            headers: current_trace_headers(),
        },
        5000,
    )
    .await
    .error_with_slug("message-request-failed")?;
    let headers = reply
        .headers
        .iter()
        .flatten()
        .map(|entry| (entry.name.as_str(), entry.value.as_str()));
    if let Some(slug) = transport::unusable_reply_slug(headers) {
        return Err(otel_wasi::Error::new(
            slug,
            "the reply is framed or failed, and components receive only its first message",
        ));
    }
    Ok(reply)
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
/// the enum's generic `InternalError` variant, then returns the original error if that
/// reply succeeds. A reply failure is returned instead when the broker cannot accept it.
pub async fn reply_handler_result<R>(
    msg: types::NatsMessage,
    result: Result<R, otel_wasi::Error>,
    pacing: transport::ReplyPacing,
) -> Result<(), otel_wasi::Error>
where
    R: crate::SkirResponse,
{
    match result {
        Ok(response) => reply_response(msg, response, pacing).await,
        Err(error) => {
            let response = R::internal_error();

            otel_wasi::main_attribute!(
                "messaging.response.variant" = response.variant_slug(),
                "messaging.response.outcome" = crate::SkirResponseOutcome::InternalError.as_str(),
                "messaging.response.success" = false,
            );

            reply(msg, response.to_skir_bytes(), pacing).await?;
            Err(error)
        }
    }
}

async fn reply_response<R>(
    msg: types::NatsMessage,
    response: R,
    pacing: transport::ReplyPacing,
) -> Result<(), otel_wasi::Error>
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

    reply(msg, response.to_skir_bytes(), pacing).await?;

    match outcome {
        crate::SkirResponseOutcome::Success | crate::SkirResponseOutcome::DomainError => Ok(()),
        crate::SkirResponseOutcome::InternalError => Err(otel_wasi::Error::new(slug, message)),
    }
}
