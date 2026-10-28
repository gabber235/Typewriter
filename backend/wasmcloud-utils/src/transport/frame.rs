//! Payload framing shared with the services and panel transports.
//!
//! A payload of at most [`CHUNK_BYTES`] travels as one plain message without framing headers. A
//! larger payload travels as frames: each carries a slice of at most [`CHUNK_BYTES`] and the
//! headers `Typewriter-Payload` (the payload id), `Typewriter-Chunk` (`index/count`),
//! `Typewriter-Size` and `Typewriter-Sha256` of the complete payload.
//!
//! A reply to a route whose generated `REPLY_CREDIT` holds flows in credit windows. The sender may
//! send the frames below its current grant, which starts at [`WINDOW_FRAMES`]. The last frame of a
//! window that is not the final frame goes out as a request; the receiver answers it with
//! `Typewriter-Credit`, the new grant, or with a `Typewriter-Transfer-Failure` that ends the
//! transfer. Every other frame is only published. A sender waits at most [`FRAME_INACTIVITY_MS`]
//! for a credit. A reply to a route a panel role calls streams every frame without waiting, because
//! granting a credit is a NATS response and panel connections hold no response permission. A reply
//! still sending [`REPLY_TTL_MS`] after its request arrived stops, since NATS no longer delivers it.
//! A sender that fails after its first frame publishes an interrupted frame so the receiver drops
//! its assembly at once.
//!
//! Components only send framed replies: they never receive framed requests, and as requesters they
//! receive only the first message of a reply. A reply above [`REPLY_MAX_BYTES`] is not framed; one
//! `Typewriter-Transfer-Failure: too-large` message carries its size and the limit instead.

use std::time::{Duration, Instant};

use sha2::{Digest, Sha256};

use crate::transport_routes::{
    CHUNK_BYTES, FRAME_INACTIVITY_MS, REPLY_MAX_BYTES, REPLY_TTL_MS, WINDOW_FRAMES,
};
use crate::wasmcloud::messaging::types::NatsMessage;

/// Header naming the payload a frame belongs to.
pub const PAYLOAD_HEADER: &str = "Typewriter-Payload";
/// Header carrying a frame's `index/count` position.
pub const CHUNK_HEADER: &str = "Typewriter-Chunk";
/// Header carrying the byte size of the complete payload.
pub const SIZE_HEADER: &str = "Typewriter-Size";
/// Header carrying the lowercase hexadecimal SHA 256 digest of the complete payload.
pub const SHA256_HEADER: &str = "Typewriter-Sha256";
/// Header of a message that ends a transfer without its payload; its value is one of
/// [`TOO_LARGE`], [`INTERRUPTED`], [`INCOMPLETE`], [`BUSY`] or [`REJECTED`].
pub const FAILURE_HEADER: &str = "Typewriter-Transfer-Failure";
/// Header carrying the largest payload size the direction carries, on a [`TOO_LARGE`] failure.
pub const LIMIT_HEADER: &str = "Typewriter-Limit";
/// Header of the answer to a window end: frames with an index below its value may be sent.
pub const CREDIT_HEADER: &str = "Typewriter-Credit";

/// Failure: the payload exceeds its direction's ceiling and was never framed.
pub const TOO_LARGE: &str = "too-large";
/// Failure: the sender stopped part way.
pub const INTERRUPTED: &str = "interrupted";
/// Failure: the receiver missed a frame below a window end.
pub const INCOMPLETE: &str = "incomplete";
/// Failure: the receiver holds no room for another assembly.
pub const BUSY: &str = "busy";
/// Failure: the receiver rejected a frame that broke the framing rules and dropped the payload.
pub const REJECTED: &str = "rejected";

/// How a component sends the frames of one reply.
#[derive(Clone, Copy, Debug)]
pub struct ReplyPacing {
    /// Whether each window end waits for the requester's credit: the generated `REPLY_CREDIT` of
    /// the route the request arrived on.
    pub credit: bool,
    /// When the request arrived, which starts its reply time to live.
    pub received: Instant,
}

impl ReplyPacing {
    /// The pacing of a reply to `Route`, whose request arrived at `received`.
    pub fn of<Route: super::RequestRoute>(received: Instant) -> Self {
        Self {
            credit: Route::REPLY_CREDIT,
            received,
        }
    }

    /// The moment a reply stops, [`REPLY_TTL_MS`] after its request arrived.
    fn deadline(&self) -> Instant {
        self.received + Duration::from_millis(REPLY_TTL_MS.unsigned_abs())
    }
}

/// One message of a framed payload: its framing headers and its slice of the encoded payload.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct PayloadFrame {
    pub headers: Vec<(&'static str, String)>,
    pub body: Vec<u8>,
}

/// How one encoded payload crosses the transport, decided before any frame is allocated.
#[derive(Debug, PartialEq, Eq)]
pub enum PayloadPlan {
    /// The payload fits one message, which carries no framing headers.
    Single(Vec<u8>),
    /// The payload exceeds the ceiling; the sender sends this failure message instead.
    TooLarge { size: usize, frame: PayloadFrame },
    /// The payload travels as these frames, which share `payload_id`, the size and the digest.
    Framed {
        payload_id: String,
        frames: Vec<PayloadFrame>,
    },
}

/// Plans the reply carrying `body` with the generated chunk size and reply ceiling.
pub fn plan_reply(body: Vec<u8>) -> PayloadPlan {
    plan_within(body, CHUNK_BYTES, REPLY_MAX_BYTES)
}

/// Plans a payload with explicit limits. The size check runs before the payload is hashed or any
/// frame is allocated.
///
/// Every payload gets a fresh random payload id, as in the services and panel transports, so the
/// frames of several senders on one subject never mix.
pub(crate) fn plan_within(body: Vec<u8>, chunk_bytes: usize, max_bytes: usize) -> PayloadPlan {
    if body.len() <= chunk_bytes {
        return PayloadPlan::Single(body);
    }
    let payload_id = uuid::Uuid::new_v4().simple().to_string();
    if body.len() > max_bytes {
        return PayloadPlan::TooLarge {
            size: body.len(),
            frame: PayloadFrame {
                headers: vec![
                    (PAYLOAD_HEADER, payload_id),
                    (FAILURE_HEADER, TOO_LARGE.to_owned()),
                    (SIZE_HEADER, body.len().to_string()),
                    (LIMIT_HEADER, max_bytes.to_string()),
                ],
                body: Vec::new(),
            },
        };
    }
    let digest = hex(&Sha256::digest(&body));
    let count = body.len().div_ceil(chunk_bytes);
    let frames = body
        .chunks(chunk_bytes)
        .enumerate()
        .map(|(index, slice)| PayloadFrame {
            headers: vec![
                (PAYLOAD_HEADER, payload_id.clone()),
                (CHUNK_HEADER, format!("{index}/{count}")),
                (SIZE_HEADER, body.len().to_string()),
                (SHA256_HEADER, digest.clone()),
            ],
            body: slice.to_vec(),
        })
        .collect();
    PayloadPlan::Framed { payload_id, frames }
}

/// The frame that tells the receiver payload `payload_id` stopped part way.
pub fn interrupted_frame(payload_id: &str) -> PayloadFrame {
    PayloadFrame {
        headers: vec![
            (PAYLOAD_HEADER, payload_id.to_owned()),
            (FAILURE_HEADER, INTERRUPTED.to_owned()),
        ],
        body: Vec::new(),
    }
}

/// The grant carried by the answer to a window end, or `None` when it carries no valid
/// `Typewriter-Credit`.
pub fn credit(answer: &NatsMessage) -> Option<usize> {
    header(answer, CREDIT_HEADER)?.parse().ok()
}

/// Where a framed reply goes: plain publishes, and requests for window ends answered within
/// `timeout_ms`.
pub(crate) trait FrameSink {
    async fn publish(&mut self, frame: PayloadFrame) -> Result<(), otel_wasi::Error>;
    async fn request(
        &mut self,
        frame: PayloadFrame,
        timeout_ms: u32,
    ) -> Result<NatsMessage, otel_wasi::Error>;
}

/// Sends the frames of one reply as `pacing` says: in credit windows of [`WINDOW_FRAMES`], or
/// streamed without waiting.
///
/// The final frame is only published, since a reply ends without an answer. A reply past its time
/// to live fails with `transport-transfer-interrupted`. On any failure an interrupted frame
/// follows, and the original failure stays the result.
pub(crate) async fn send_reply_frames(
    sink: &mut impl FrameSink,
    payload_id: &str,
    frames: Vec<PayloadFrame>,
    pacing: ReplyPacing,
) -> Result<(), otel_wasi::Error> {
    let window_frames = pacing.credit.then_some(WINDOW_FRAMES);
    send_frames_within(sink, payload_id, frames, window_frames, pacing.deadline()).await
}

async fn send_frames_within(
    sink: &mut impl FrameSink,
    payload_id: &str,
    frames: Vec<PayloadFrame>,
    window_frames: Option<usize>,
    deadline: Instant,
) -> Result<(), otel_wasi::Error> {
    let count = frames.len();
    let mut granted = window_frames.unwrap_or(count).min(count);
    for (index, frame) in frames.into_iter().enumerate() {
        let sent = index + 1;
        let remaining = deadline.saturating_duration_since(Instant::now());
        let result = if remaining.is_zero() {
            Err(otel_wasi::Error::new(
                "transport-transfer-interrupted",
                "the reply outlived its time to live before every frame was sent",
            ))
        } else if sent == granted && sent < count {
            let timeout_ms = u32::try_from(remaining.as_millis())
                .unwrap_or(u32::MAX)
                .min(FRAME_INACTIVITY_MS);
            match sink.request(frame, timeout_ms).await {
                Ok(answer) => next_grant(&answer, sent).map(|grant| granted = grant.min(count)),
                Err(error) => Err(error),
            }
        } else {
            sink.publish(frame).await
        };
        if let Err(error) = result {
            // The receiver learns at once; the original failure stays the result.
            #[expect(
                clippy::let_underscore_must_use,
                reason = "the original failure is the result; a failed notice adds nothing"
            )]
            let _ = sink.publish(interrupted_frame(payload_id)).await;
            return Err(error);
        }
    }
    Ok(())
}

/// Reads the grant answering a window end after `sent` frames, which must let the sender go on.
fn next_grant(answer: &NatsMessage, sent: usize) -> Result<usize, otel_wasi::Error> {
    if let Some(failure) = header(answer, FAILURE_HEADER) {
        return Err(otel_wasi::Error::new(
            failure_slug(failure),
            format!("the receiver ended the transfer: {failure}"),
        ));
    }
    match credit(answer) {
        Some(grant) if grant > sent => Ok(grant),
        _ => Err(otel_wasi::Error::new(
            "transport-credit-missing",
            "The receiver granted no credit",
        )),
    }
}

/// The error slug of a reply a component cannot use, or `None` for a plain reply.
///
/// A failure message maps its failure to `transport-transfer-too-large`,
/// `transport-transfer-interrupted` or, for any other failure, `transport-transfer-rejected`, as
/// the services and panel transports distinguish them. Components receive only the first message
/// of a reply, so a reply split into frames is too large for them.
pub fn unusable_reply_slug<'a>(
    headers: impl IntoIterator<Item = (&'a str, &'a str)>,
) -> Option<&'static str> {
    let mut framed = false;
    for (name, value) in headers {
        if name.eq_ignore_ascii_case(FAILURE_HEADER) {
            return Some(failure_slug(value));
        }
        framed |= name.eq_ignore_ascii_case(PAYLOAD_HEADER);
    }
    framed.then_some("transport-transfer-too-large")
}

fn failure_slug(failure: &str) -> &'static str {
    match failure {
        TOO_LARGE => "transport-transfer-too-large",
        INTERRUPTED => "transport-transfer-interrupted",
        _ => "transport-transfer-rejected",
    }
}

fn header<'a>(message: &'a NatsMessage, name: &str) -> Option<&'a str> {
    message
        .headers
        .iter()
        .flatten()
        .find(|entry| entry.name.eq_ignore_ascii_case(name))
        .map(|entry| entry.value.as_str())
}

fn hex(bytes: &[u8]) -> String {
    bytes.iter().map(|byte| format!("{byte:02x}")).collect()
}

#[cfg(test)]
mod tests {
    use std::collections::VecDeque;

    use otel_wasi::WasiError;

    use super::*;
    use crate::transport::test_support::{block_on, nats_message};
    use crate::wasmcloud::messaging::types::HeaderEntry;

    fn frame_header<'a>(frame: &'a PayloadFrame, name: &str) -> Option<&'a str> {
        frame
            .headers
            .iter()
            .find(|(candidate, _)| *candidate == name)
            .map(|(_, value)| value.as_str())
    }

    fn answer(headers: &[(&str, &str)]) -> NatsMessage {
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

    fn framed(body: Vec<u8>, chunk_bytes: usize) -> (String, Vec<PayloadFrame>) {
        match plan_within(body, chunk_bytes, usize::MAX) {
            PayloadPlan::Framed { payload_id, frames } => (payload_id, frames),
            plan => panic!("expected frames, got {plan:?}"),
        }
    }

    #[derive(Debug, PartialEq, Eq)]
    enum Sent {
        Published(String),
        Requested(String),
    }

    /// Records what a sender sent and answers each window end with the next scripted answer.
    #[derive(Default)]
    struct Receiver {
        sent: Vec<Sent>,
        answers: VecDeque<Result<NatsMessage, otel_wasi::Error>>,
    }

    impl Receiver {
        fn answering(
            answers: impl IntoIterator<Item = Result<NatsMessage, otel_wasi::Error>>,
        ) -> Self {
            Self {
                sent: Vec::new(),
                answers: answers.into_iter().collect(),
            }
        }
    }

    fn label(frame: &PayloadFrame) -> String {
        frame_header(frame, CHUNK_HEADER)
            .or(frame_header(frame, FAILURE_HEADER))
            .unwrap_or_default()
            .to_owned()
    }

    impl FrameSink for Receiver {
        async fn publish(&mut self, frame: PayloadFrame) -> Result<(), otel_wasi::Error> {
            self.sent.push(Sent::Published(label(&frame)));
            Ok(())
        }

        async fn request(
            &mut self,
            frame: PayloadFrame,
            _timeout_ms: u32,
        ) -> Result<NatsMessage, otel_wasi::Error> {
            self.sent.push(Sent::Requested(label(&frame)));
            self.answers
                .pop_front()
                .expect("the sender requested beyond the scripted window ends")
        }
    }

    fn send(receiver: &mut Receiver, frames: usize, window: usize) -> Result<(), otel_wasi::Error> {
        send_paced(receiver, frames, Some(window), far_deadline())
    }

    fn send_paced(
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

    fn far_deadline() -> Instant {
        Instant::now() + Duration::from_secs(3_600)
    }

    #[test]
    fn a_payload_within_one_chunk_stays_one_plain_message() {
        assert_eq!(
            plan_within(vec![1; 8], 8, 32),
            PayloadPlan::Single(vec![1; 8])
        );
        assert_eq!(
            plan_within(Vec::new(), 8, 32),
            PayloadPlan::Single(Vec::new())
        );
    }

    #[test]
    fn a_larger_payload_splits_into_frames_sharing_size_and_digest() {
        let body: Vec<u8> = (0..19).collect();
        let (payload_id, frames) = framed(body.clone(), 8);
        assert_eq!(
            frames
                .iter()
                .map(|frame| frame_header(frame, CHUNK_HEADER))
                .collect::<Vec<_>>(),
            [Some("0/3"), Some("1/3"), Some("2/3")]
        );
        let digest = hex(&Sha256::digest(&body));
        for frame in &frames {
            assert_eq!(
                frame_header(frame, PAYLOAD_HEADER),
                Some(payload_id.as_str())
            );
            assert_eq!(frame_header(frame, SIZE_HEADER), Some("19"));
            assert_eq!(frame_header(frame, SHA256_HEADER), Some(digest.as_str()));
            assert!(frame.body.len() <= 8);
        }
        let joined: Vec<u8> = frames.iter().flat_map(|frame| frame.body.clone()).collect();
        assert_eq!(joined, body);
    }

    #[test]
    fn a_payload_at_its_ceiling_is_framed_and_one_byte_more_is_too_large() {
        assert!(matches!(
            plan_within(vec![0; 32], 8, 32),
            PayloadPlan::Framed { .. }
        ));
        let PayloadPlan::TooLarge { size, frame } = plan_within(vec![0; 33], 8, 32) else {
            panic!("expected a too large plan");
        };
        assert_eq!(size, 33);
        assert_eq!(frame_header(&frame, FAILURE_HEADER), Some(TOO_LARGE));
        assert_eq!(frame_header(&frame, SIZE_HEADER), Some("33"));
        assert_eq!(frame_header(&frame, LIMIT_HEADER), Some("32"));
        assert!(frame_header(&frame, PAYLOAD_HEADER).is_some());
        assert!(frame.body.is_empty());
    }

    #[test]
    fn replies_are_planned_against_the_generated_reply_ceiling() {
        assert!(matches!(
            plan_reply(vec![0; CHUNK_BYTES]),
            PayloadPlan::Single(_)
        ));
        let PayloadPlan::TooLarge { frame, .. } = plan_reply(vec![0; REPLY_MAX_BYTES + 1]) else {
            panic!("expected a too large plan");
        };
        assert_eq!(
            frame_header(&frame, LIMIT_HEADER),
            Some(REPLY_MAX_BYTES.to_string().as_str())
        );
    }

    #[test]
    fn every_payload_uses_a_fresh_payload_id() {
        let first = framed(vec![1; 9], 4).0;
        assert_eq!(first.len(), 32);
        assert_ne!(first, framed(vec![1; 9], 4).0);
    }

    #[test]
    fn a_reply_within_one_window_is_only_published() {
        let mut receiver = Receiver::default();
        send(&mut receiver, 8, 8).unwrap();
        assert_eq!(
            receiver.sent,
            (0..8)
                .map(|index| Sent::Published(format!("{index}/8")))
                .collect::<Vec<_>>()
        );
    }

    #[test]
    fn a_sender_waits_for_credit_at_each_window_end_and_publishes_the_final_frame() {
        // Nine frames in windows of eight: frame 7 asks for credit, frame 8 ends the reply.
        let mut receiver = Receiver::answering([Ok(answer(&[(CREDIT_HEADER, "9")]))]);
        send(&mut receiver, 9, 8).unwrap();
        let mut expected: Vec<Sent> = (0..7)
            .map(|index| Sent::Published(format!("{index}/9")))
            .collect();
        expected.push(Sent::Requested("7/9".to_owned()));
        expected.push(Sent::Published("8/9".to_owned()));
        assert_eq!(receiver.sent, expected);
    }

    #[test]
    fn a_sender_never_runs_beyond_its_grant() {
        // The receiver grants one more frame each time, so every frame but the final one asks.
        let mut receiver = Receiver::answering([
            Ok(answer(&[(CREDIT_HEADER, "3")])),
            Ok(answer(&[(CREDIT_HEADER, "4")])),
        ]);
        send(&mut receiver, 4, 2).unwrap();
        assert_eq!(
            receiver.sent,
            [
                Sent::Published("0/4".to_owned()),
                Sent::Requested("1/4".to_owned()),
                Sent::Requested("2/4".to_owned()),
                Sent::Published("3/4".to_owned()),
            ]
        );
    }

    #[test]
    fn a_reply_without_credit_streams_every_frame() {
        let mut receiver = Receiver::default();
        send_paced(&mut receiver, 20, None, far_deadline()).unwrap();
        assert_eq!(
            receiver.sent,
            (0..20)
                .map(|index| Sent::Published(format!("{index}/20")))
                .collect::<Vec<_>>()
        );
    }

    #[test]
    fn the_route_decides_whether_its_reply_waits_for_credit() {
        use crate::transport_routes::{ServiceBindingQueryRoute, UserOrganizationCreateRoute};
        let received = Instant::now();
        assert!(!ReplyPacing::of::<UserOrganizationCreateRoute>(received).credit);
        assert!(ReplyPacing::of::<ServiceBindingQueryRoute>(received).credit);
    }

    #[test]
    fn a_reply_past_its_time_to_live_stops_as_interrupted() {
        let mut receiver = Receiver::default();
        let error = send_paced(&mut receiver, 3, None, Instant::now()).unwrap_err();
        assert_eq!(error.slug(), "transport-transfer-interrupted");
        assert_eq!(receiver.sent, [Sent::Published(INTERRUPTED.to_owned())]);
    }

    #[test]
    fn a_window_end_without_usable_credit_interrupts_the_reply() {
        let failing = [
            (answer(&[]), "transport-credit-missing"),
            (answer(&[(CREDIT_HEADER, "2")]), "transport-credit-missing"),
            (
                answer(&[(CREDIT_HEADER, "many")]),
                "transport-credit-missing",
            ),
            (
                answer(&[(PAYLOAD_HEADER, "id"), (FAILURE_HEADER, INCOMPLETE)]),
                "transport-transfer-rejected",
            ),
            (
                answer(&[(PAYLOAD_HEADER, "id"), (FAILURE_HEADER, BUSY)]),
                "transport-transfer-rejected",
            ),
        ];
        for (reply, slug) in failing {
            let mut receiver = Receiver::answering([Ok(reply)]);
            let error = send(&mut receiver, 5, 2).unwrap_err();
            assert_eq!(error.slug(), slug);
            assert_eq!(
                receiver.sent,
                [
                    Sent::Published("0/5".to_owned()),
                    Sent::Requested("1/5".to_owned()),
                    Sent::Published(INTERRUPTED.to_owned()),
                ]
            );
        }
    }

    #[test]
    fn an_unanswered_window_end_interrupts_the_reply_with_its_failure() {
        let mut receiver = Receiver::answering([Err(otel_wasi::Error::new(
            "transport-credit-failed",
            "timed out",
        ))]);
        let error = send(&mut receiver, 3, 2).unwrap_err();
        assert_eq!(error.slug(), "transport-credit-failed");
        assert_eq!(
            receiver.sent.last(),
            Some(&Sent::Published(INTERRUPTED.to_owned()))
        );
    }

    #[test]
    fn credit_reads_the_grant_in_any_header_case() {
        assert_eq!(credit(&answer(&[("typewriter-credit", "16")])), Some(16));
        assert_eq!(credit(&answer(&[(CREDIT_HEADER, "-1")])), None);
        assert_eq!(credit(&answer(&[])), None);
        assert_eq!(credit(&nats_message("_INBOX.sender", b"")), None);
    }

    #[test]
    fn unusable_replies_name_their_transfer_failure_in_any_case() {
        let slug = |headers: &[(&str, &str)]| unusable_reply_slug(headers.iter().copied());
        assert_eq!(slug(&[("traceparent", "00")]), None);
        assert_eq!(
            slug(&[("typewriter-payload", "id"), ("typewriter-chunk", "0/2")]),
            Some("transport-transfer-too-large")
        );
        for (failure, expected) in [
            (TOO_LARGE, "transport-transfer-too-large"),
            (INTERRUPTED, "transport-transfer-interrupted"),
            (INCOMPLETE, "transport-transfer-rejected"),
            (BUSY, "transport-transfer-rejected"),
            (REJECTED, "transport-transfer-rejected"),
            ("unknown", "transport-transfer-rejected"),
        ] {
            assert_eq!(
                slug(&[
                    ("Typewriter-Payload", "id"),
                    ("TYPEWRITER-TRANSFER-FAILURE", failure)
                ]),
                Some(expected)
            );
        }
        assert_eq!(
            frame_header(&interrupted_frame("id"), FAILURE_HEADER),
            Some(INTERRUPTED)
        );
    }
}
