//! Helpers for unit testing the transport runtime on the host: running handlers, messages, a
//! scripted frame receiver, the reference receiver driven by planned frames or by the written
//! frame vectors, generators for properties, and example routes and handlers.

use std::collections::VecDeque;
use std::future::Future;
use std::path::Path;
use std::pin::pin;
use std::task::{Context, Poll, Waker};
use std::time::{Duration, Instant};

use base64::{Engine as _, engine::general_purpose::STANDARD};
use proptest::prelude::*;
use serde_json::Value;

use super::frame::{
    CHUNK_HEADER, FAILURE_HEADER, FrameSink, PayloadFrame, PayloadPlan, plan_within,
    send_frames_within,
};
use super::reference_assembler::{Outcome, ReferenceAssembler};
use super::{EventRoute, RequestRoute, ServiceScope};
use crate::skir_client::{Method, Serializer};
use crate::skirout::base::access::v1::permission::{
    GetEntityPermissionRequest, GetEntityPermissionResponse, get_entity_permission_method,
};
use crate::skirout::base::service::v1::lifecycle::ServiceHeartbeatNotification;
use crate::wasmcloud::messaging::types::{HeaderEntry, NatsMessage};

/// Runs a future that completes without waiting, as every transport path that reaches no broker
/// call does, inside the main span a component handler runs in.
pub(crate) fn block_on<F: Future>(future: F) -> F::Output {
    let _main_span = otel_wasi::enter_main_span(tracing::info_span!("transport_test"));
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

/// A received message carrying `headers`, as a receiver answers a window end.
pub(crate) fn answer(headers: &[(&str, &str)]) -> NatsMessage {
    NatsMessage {
        headers: Some(
            headers
                .iter()
                .map(|(name, value)| HeaderEntry {
                    name: (*name).to_owned(),
                    value: (*value).to_owned(),
                })
                .collect(),
        ),
        ..nats_message("_INBOX.sender", b"")
    }
}

/// The value of header `name` on `frame`.
pub(crate) fn frame_header<'a>(frame: &'a PayloadFrame, name: &str) -> Option<&'a str> {
    frame
        .headers
        .iter()
        .find(|(candidate, _)| *candidate == name)
        .map(|(_, value)| value.as_str())
}

/// The payload id and frames of a body spanning more than one chunk, without a ceiling.
pub(crate) fn framed(body: Vec<u8>, chunk_bytes: usize) -> (String, Vec<PayloadFrame>) {
    match plan_within(body, chunk_bytes, usize::MAX) {
        PayloadPlan::Framed { payload_id, frames } => (payload_id, frames),
        plan => panic!("expected frames, got {plan:?}"),
    }
}

/// What a sender sent, by the chunk or failure header of the frame.
#[derive(Debug, PartialEq, Eq)]
pub(crate) enum Sent {
    Published(String),
    Requested(String),
}

/// Records what a sender sent and answers each window end with the next scripted answer.
#[derive(Default)]
pub(crate) struct Receiver {
    pub(crate) sent: Vec<Sent>,
    answers: VecDeque<Result<NatsMessage, otel_wasi::Error>>,
}

impl Receiver {
    pub(crate) fn answering(
        answers: impl IntoIterator<Item = Result<NatsMessage, otel_wasi::Error>>,
    ) -> Self {
        Self {
            sent: Vec::new(),
            answers: answers.into_iter().collect(),
        }
    }

    fn label(frame: &PayloadFrame) -> String {
        frame_header(frame, CHUNK_HEADER)
            .or(frame_header(frame, FAILURE_HEADER))
            .expect("every sent frame carries a chunk or failure header")
            .to_owned()
    }
}

impl FrameSink for Receiver {
    async fn publish(&mut self, frame: PayloadFrame) -> Result<(), otel_wasi::Error> {
        self.sent.push(Sent::Published(Self::label(&frame)));
        Ok(())
    }

    async fn request(
        &mut self,
        frame: PayloadFrame,
        _timeout_ms: u32,
    ) -> Result<NatsMessage, otel_wasi::Error> {
        self.sent.push(Sent::Requested(Self::label(&frame)));
        self.answers
            .pop_front()
            .expect("the sender requested beyond the scripted window ends")
    }
}

/// Sends `frames` one byte frames to `receiver` in windows of `window`, an hour before the deadline.
pub(crate) fn send(
    receiver: &mut Receiver,
    frames: usize,
    window: usize,
) -> Result<(), otel_wasi::Error> {
    send_paced(receiver, frames, Some(window), far_deadline())
}

/// Sends `frames` one byte frames to `receiver`, paced by `window` and bounded by `deadline`.
pub(crate) fn send_paced(
    receiver: &mut Receiver,
    frames: usize,
    window: Option<usize>,
    deadline: Instant,
) -> Result<(), otel_wasi::Error> {
    let (payload_id, frames) = framed(vec![7; frames], 1);
    block_on(send_frames_within(
        receiver,
        &payload_id,
        frames,
        window,
        deadline,
    ))
}

/// A deadline no test reaches.
pub(crate) fn far_deadline() -> Instant {
    Instant::now() + Duration::from_secs(3_600)
}

/// The reference receiver's ceiling in properties; generated bodies stay below it.
pub(crate) const PROPERTY_MAX_BYTES: usize = 4096;

/// A body, a chunk size it spans with at least two frames, and an order to deliver them in.
pub(crate) fn framed_body() -> impl Strategy<Value = (Vec<u8>, usize, Vec<usize>)> {
    (1usize..64)
        .prop_flat_map(|chunk| {
            (
                proptest::collection::vec(
                    any::<u8>(),
                    chunk + 1..=(chunk * 40).min(PROPERTY_MAX_BYTES),
                ),
                Just(chunk),
            )
        })
        .prop_flat_map(|(body, chunk)| {
            let order: Vec<usize> = (0..body.len().div_ceil(chunk)).collect();
            (Just(body), Just(chunk), Just(order).prop_shuffle())
        })
}

/// Every outcome of delivering `frames` in order to a fresh reference receiver.
pub(crate) fn deliver<'a>(
    chunk: usize,
    frames: impl IntoIterator<Item = &'a PayloadFrame>,
) -> Vec<Outcome> {
    let mut receiver = ReferenceAssembler::new(chunk, PROPERTY_MAX_BYTES);
    frames
        .into_iter()
        .map(|frame| {
            let headers: Vec<(&str, &str)> = frame
                .headers
                .iter()
                .map(|(name, value)| (*name, value.as_str()))
                .collect();
            receiver.accept(&headers, &frame.body)
        })
        .collect()
}

/// The bytes of every completed payload among `outcomes`.
pub(crate) fn completions(outcomes: &[Outcome]) -> Vec<&[u8]> {
    outcomes
        .iter()
        .filter_map(|outcome| match outcome {
            Outcome::Complete(bytes) => Some(bytes.as_slice()),
            _ => None,
        })
        .collect()
}

/// The frame vectors every transport reads; `cargo xtask generate` writes them.
pub(crate) fn written_vectors() -> Value {
    let path = Path::new(env!("CARGO_MANIFEST_DIR"))
        .join("../../skir-src/transport/v1/fixtures/frames.json");
    let json = std::fs::read_to_string(&path).unwrap_or_else(|error| {
        panic!(
            "cannot read {}; run cargo xtask generate: {error}",
            path.display()
        )
    });
    serde_json::from_str(&json).expect("the frame vectors are JSON")
}

/// A string field of a frame vector.
pub(crate) fn vector_text(value: &Value) -> &str {
    value.as_str().expect("a vector field is a string")
}

/// The outcome a frame vector expects its last frame to reach.
pub(crate) fn vector_outcome(expect: &Value) -> Outcome {
    if let Some(bytes) = expect.get("bytes") {
        Outcome::Complete(
            STANDARD
                .decode(vector_text(bytes))
                .expect("expected bytes are base64"),
        )
    } else if expect.get("pending").is_some() {
        Outcome::Waiting
    } else if expect.get("rejected").is_some() {
        Outcome::Rejected
    } else {
        Outcome::Failed(vector_text(&expect["failure"]).to_owned())
    }
}

/// Identifiers as the backend meets them: generated uuids, slugs, and arbitrary text from an
/// identity provider or a client.
pub(crate) fn identifier() -> impl Strategy<Value = String> {
    prop_oneof![
        any::<u128>().prop_map(|bits| uuid::Uuid::from_u128(bits).simple().to_string()),
        any::<u128>().prop_map(|bits| uuid::Uuid::from_u128(bits).to_string()),
        "[a-z0-9_:@|-]{1,40}",
        any::<String>(),
        "[a-z]{0,4}[.*> \t\n{}\u{a0}\u{2028}][a-z]{0,4}",
    ]
}

/// A request route a service serves: the entity permission query.
pub(crate) struct PermissionRoute;

impl RequestRoute for PermissionRoute {
    const REPLY_CREDIT: bool = false;

    type Scope = ServiceScope;
    type Request = GetEntityPermissionRequest;
    type Response = GetEntityPermissionResponse;

    fn method() -> &'static Method<Self::Request, Self::Response> {
        get_entity_permission_method()
    }
}

/// An event route a service serves: its heartbeat.
pub(crate) struct HeartbeatRoute;

impl EventRoute for HeartbeatRoute {
    type Scope = ServiceScope;
    type Event = ServiceHeartbeatNotification;

    fn serializer() -> Serializer<Self::Event> {
        ServiceHeartbeatNotification::serializer()
    }
}

/// The serialized body of a permission request.
pub(crate) fn permission_request_body() -> Vec<u8> {
    GetEntityPermissionRequest::serializer().to_bytes(&GetEntityPermissionRequest {
        jwt_claims: b"claims".to_vec(),
        ..Default::default()
    })
}

/// The serialized body of a default heartbeat.
pub(crate) fn heartbeat_body() -> Vec<u8> {
    ServiceHeartbeatNotification::serializer().to_bytes(&ServiceHeartbeatNotification::default())
}

/// Service registration handlers where only the heartbeat handler may run.
macro_rules! heartbeat_only {
    ($heartbeat:expr) => {
        $crate::transport_routes::service_registration::Handlers {
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
pub(crate) use heartbeat_only;
