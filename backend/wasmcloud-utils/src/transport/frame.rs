//! Reply framing shared with the services and panel transports.
//!
//! A reply of at most [`RESPONSE_CHUNK_BYTES`] travels as one plain message without framing
//! headers. A larger reply travels as frames on the requester's reply subject: each carries a
//! slice of at most [`RESPONSE_CHUNK_BYTES`] and the headers `Typewriter-Reply` (the reply id),
//! `Typewriter-Chunk` (`index/count`), `Typewriter-Size` and `Typewriter-Sha256` of the complete
//! reply. A reply needing more than [`MAX_RESPONSE_CHUNKS`] frames is not sent; one
//! `Typewriter-Transfer-Failure: too-large` frame carries its size and the limit instead.

use sha2::{Digest, Sha256};

use crate::transport_routes::{MAX_RESPONSE_CHUNKS, RESPONSE_CHUNK_BYTES};

/// Header naming the reply a frame belongs to.
pub const REPLY_HEADER: &str = "Typewriter-Reply";
/// Header carrying a frame's `index/count` position.
pub const CHUNK_HEADER: &str = "Typewriter-Chunk";
/// Header carrying the byte size of the complete reply.
pub const SIZE_HEADER: &str = "Typewriter-Size";
/// Header carrying the lowercase hexadecimal SHA 256 digest of the complete reply.
pub const SHA256_HEADER: &str = "Typewriter-Sha256";
/// Header of a frame that ends its reply without the reply: `too-large` or `interrupted`.
pub const FAILURE_HEADER: &str = "Typewriter-Transfer-Failure";
/// Header carrying the largest reply size the transport carries, on a `too-large` frame.
pub const LIMIT_HEADER: &str = "Typewriter-Limit";

/// One message of a framed reply: its framing headers and its slice of the encoded reply.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct ReplyFrame {
    pub headers: Vec<(&'static str, String)>,
    pub body: Vec<u8>,
}

/// How one encoded reply crosses the transport, decided before any frame is allocated.
#[derive(Debug, PartialEq, Eq)]
pub enum ReplyPlan {
    /// The reply fits one message, which carries no framing headers.
    Single(Vec<u8>),
    /// The reply exceeds the limit; the responder sends this failure frame instead.
    TooLarge { size: usize, frame: ReplyFrame },
    /// The reply travels as these frames, which share `reply_id`, the size and the digest.
    Framed {
        reply_id: String,
        frames: Vec<ReplyFrame>,
    },
}

/// Plans the reply carrying `body` with the generated transport limits.
pub fn plan_reply(body: Vec<u8>) -> ReplyPlan {
    plan_reply_within(body, RESPONSE_CHUNK_BYTES, MAX_RESPONSE_CHUNKS)
}

/// Plans a reply with explicit limits; the size check runs before any frame is allocated.
///
/// The reply id is the start of the reply's digest. Components answer only unary requests, so the
/// id only has to keep different replies on one reply subject apart, and the frames of identical
/// replies from two responders are identical and merge without harm.
pub(crate) fn plan_reply_within(body: Vec<u8>, chunk_bytes: usize, max_chunks: usize) -> ReplyPlan {
    if body.len() <= chunk_bytes {
        return ReplyPlan::Single(body);
    }
    let digest = hex(&Sha256::digest(&body));
    let reply_id = digest[..32].to_owned();
    let limit = chunk_bytes * max_chunks;
    if body.len() > limit {
        return ReplyPlan::TooLarge {
            size: body.len(),
            frame: ReplyFrame {
                headers: vec![
                    (REPLY_HEADER, reply_id),
                    (FAILURE_HEADER, "too-large".to_owned()),
                    (SIZE_HEADER, body.len().to_string()),
                    (LIMIT_HEADER, limit.to_string()),
                ],
                body: Vec::new(),
            },
        };
    }
    let count = body.len().div_ceil(chunk_bytes);
    let frames = body
        .chunks(chunk_bytes)
        .enumerate()
        .map(|(index, slice)| ReplyFrame {
            headers: vec![
                (REPLY_HEADER, reply_id.clone()),
                (CHUNK_HEADER, format!("{index}/{count}")),
                (SIZE_HEADER, body.len().to_string()),
                (SHA256_HEADER, digest.clone()),
            ],
            body: slice.to_vec(),
        })
        .collect();
    ReplyPlan::Framed { reply_id, frames }
}

/// The frame that tells the requester reply `reply_id` stopped part way.
pub fn interrupted_frame(reply_id: &str) -> ReplyFrame {
    ReplyFrame {
        headers: vec![
            (REPLY_HEADER, reply_id.to_owned()),
            (FAILURE_HEADER, "interrupted".to_owned()),
        ],
        body: Vec::new(),
    }
}

/// Whether headers with these names belong to a framed reply or a transfer failure frame.
pub fn is_framed<'a>(mut names: impl Iterator<Item = &'a str>) -> bool {
    names.any(|name| {
        name.eq_ignore_ascii_case(REPLY_HEADER) || name.eq_ignore_ascii_case(FAILURE_HEADER)
    })
}

fn hex(bytes: &[u8]) -> String {
    bytes.iter().map(|byte| format!("{byte:02x}")).collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    fn header<'a>(frame: &'a ReplyFrame, name: &str) -> Option<&'a str> {
        frame
            .headers
            .iter()
            .find(|(candidate, _)| *candidate == name)
            .map(|(_, value)| value.as_str())
    }

    #[test]
    fn a_reply_within_one_chunk_stays_one_plain_message() {
        assert_eq!(
            plan_reply_within(vec![1; 8], 8, 4),
            ReplyPlan::Single(vec![1; 8])
        );
        assert_eq!(
            plan_reply_within(Vec::new(), 8, 4),
            ReplyPlan::Single(Vec::new())
        );
    }

    #[test]
    fn a_larger_reply_splits_into_frames_sharing_size_and_digest() {
        let body: Vec<u8> = (0..19).collect();
        let ReplyPlan::Framed { reply_id, frames } = plan_reply_within(body.clone(), 8, 4) else {
            panic!("expected frames");
        };
        assert_eq!(frames.len(), 3);
        assert_eq!(
            frames
                .iter()
                .map(|frame| header(frame, CHUNK_HEADER))
                .collect::<Vec<_>>(),
            [Some("0/3"), Some("1/3"), Some("2/3")]
        );
        let digest = hex(&Sha256::digest(&body));
        for frame in &frames {
            assert_eq!(header(frame, REPLY_HEADER), Some(reply_id.as_str()));
            assert_eq!(header(frame, SIZE_HEADER), Some("19"));
            assert_eq!(header(frame, SHA256_HEADER), Some(digest.as_str()));
            assert!(frame.body.len() <= 8);
        }
        let joined: Vec<u8> = frames.iter().flat_map(|frame| frame.body.clone()).collect();
        assert_eq!(joined, body);
    }

    #[test]
    fn an_oversize_reply_becomes_one_failure_frame_with_its_size_and_limit() {
        let ReplyPlan::TooLarge { size, frame } = plan_reply_within(vec![0; 33], 8, 4) else {
            panic!("expected a too large plan");
        };
        assert_eq!(size, 33);
        assert_eq!(header(&frame, FAILURE_HEADER), Some("too-large"));
        assert_eq!(header(&frame, SIZE_HEADER), Some("33"));
        assert_eq!(header(&frame, LIMIT_HEADER), Some("32"));
        assert!(frame.body.is_empty());
    }

    #[test]
    fn different_replies_use_different_reply_ids() {
        let id = |body: Vec<u8>| match plan_reply_within(body, 4, 4) {
            ReplyPlan::Framed { reply_id, .. } => reply_id,
            plan => panic!("expected frames, got {plan:?}"),
        };
        assert_ne!(id(vec![1; 9]), id(vec![2; 9]));
        assert_eq!(id(vec![1; 9]), id(vec![1; 9]));
    }

    #[test]
    fn the_generated_limits_keep_the_maximum_reply_size() {
        assert_eq!(RESPONSE_CHUNK_BYTES * MAX_RESPONSE_CHUNKS, 33_554_432);
    }

    #[test]
    fn framing_headers_are_recognized_in_any_case() {
        assert!(is_framed(["traceparent", "typewriter-reply"].into_iter()));
        assert!(is_framed(["Typewriter-Transfer-Failure"].into_iter()));
        assert!(!is_framed(["traceparent"].into_iter()));
        assert_eq!(
            header(&interrupted_frame("id"), FAILURE_HEADER),
            Some("interrupted")
        );
    }
}
