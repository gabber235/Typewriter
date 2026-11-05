//! The frame vectors every transport's assembler is checked against.
//!
//! `cargo xtask generate` writes them to `skir-src/transport/v1/fixtures/frames.json` from this
//! framer, so the services, panel and backend agree on one set of framed messages. Each case names
//! the receiver's chunk size and payload ceiling and lists messages in delivery order; every
//! message but the last leaves the receiver waiting, and the last one produces `expect`:
//!
//! - `{"bytes": base64}`: the whole payload, byte identical to what was planned;
//! - `{"pending": true}`: the receiver still waits;
//! - `{"rejected": true}`: the receiver refuses the frame and drops the assembly;
//! - `{"failure": name}`: the sender reported this transfer failure.
//!
//! Frame headers keep the framer's order, and the random payload id is replaced by a fixed one so
//! the output only changes when the framing does.

use base64::{Engine as _, engine::general_purpose::STANDARD};
use serde_json::{Value, json};

use super::frame::{
    INTERRUPTED, PAYLOAD_HEADER, PayloadFrame, PayloadPlan, SHA256_HEADER, interrupted_frame,
    plan_within,
};

/// The receiver's chunk size in every case: small, so a short body spans several frames.
const CHUNK_BYTES: usize = 8;
/// The receiver's payload ceiling in every case.
const MAX_BYTES: usize = 64;
/// The payload id every framed case carries.
const PAYLOAD_ID: &str = "0123456789abcdef0123456789abcdef";

/// The vectors as the JSON document the generator writes.
pub fn frame_vectors() -> Value {
    let framed_body = b"Typewriter frames this payload in order".to_vec();
    let frames = framed(framed_body.clone());
    let last = frames.len() - 1;
    let pick = |order: &[usize]| -> Vec<PayloadFrame> {
        order.iter().map(|&index| frames[index].clone()).collect()
    };
    let mut altered = frames.clone();
    altered[1].body[0] ^= 0x20;
    let mut altered_duplicate = frames[0].clone();
    altered_duplicate.body[0] ^= 0x20;
    let mut altered_digest = frames[last].clone();
    for (name, value) in &mut altered_digest.headers {
        if *name == SHA256_HEADER {
            *value = "0".repeat(64);
        }
    }
    let mut reversed = frames.clone();
    reversed.reverse();
    let shuffled = {
        let mut order: Vec<usize> = (0..=last).collect();
        order.rotate_left(2);
        order.swap(0, 1);
        order
    };
    let single_body = b"a frame".to_vec();
    let bytes = json!({ "bytes": STANDARD.encode(&framed_body) });
    let cases = vec![
        case(
            "a payload within one chunk is one plain message",
            CHUNK_BYTES,
            &[single(single_body.clone())],
            &json!({ "bytes": STANDARD.encode(&single_body) }),
        ),
        case("frames in order assemble", CHUNK_BYTES, &frames, &bytes),
        case("frames in reverse assemble", CHUNK_BYTES, &reversed, &bytes),
        case(
            "shuffled frames assemble",
            CHUNK_BYTES,
            &pick(&shuffled),
            &bytes,
        ),
        case(
            "an identical duplicate is ignored",
            CHUNK_BYTES,
            &pick(&[0, 1, 0, 1].into_iter().chain(2..=last).collect::<Vec<_>>()),
            &bytes,
        ),
        case(
            "a dropped frame leaves the payload pending",
            CHUNK_BYTES,
            &pick(&(0..last).collect::<Vec<_>>()),
            &json!({ "pending": true }),
        ),
        case(
            "an altered frame fails the digest",
            CHUNK_BYTES,
            &altered,
            &json!({ "rejected": true }),
        ),
        case(
            "a changed duplicate is rejected",
            CHUNK_BYTES,
            &[frames[0].clone(), frames[1].clone(), altered_duplicate],
            &json!({ "rejected": true }),
        ),
        case(
            "a frame with a different digest is rejected",
            CHUNK_BYTES,
            &[frames[0].clone(), altered_digest],
            &json!({ "rejected": true }),
        ),
        case(
            "a frame above the chunk size is rejected",
            CHUNK_BYTES - 1,
            &[frames[0].clone()],
            &json!({ "rejected": true }),
        ),
        case(
            "a payload above the ceiling arrives as a too large failure",
            CHUNK_BYTES,
            &[too_large()],
            &json!({ "failure": "too-large" }),
        ),
        case(
            "an interrupted payload ends its assembly",
            CHUNK_BYTES,
            &[frames[0].clone(), interrupted_frame(PAYLOAD_ID)],
            &json!({ "failure": INTERRUPTED }),
        ),
    ];
    json!({ "cases": cases })
}

fn single(body: Vec<u8>) -> PayloadFrame {
    match plan_within(body, CHUNK_BYTES, MAX_BYTES) {
        PayloadPlan::Single(body) => PayloadFrame {
            headers: Vec::new(),
            body,
        },
        plan => unreachable!("a body within one chunk plans as one message, not {plan:?}"),
    }
}

fn too_large() -> PayloadFrame {
    match plan_within(vec![b'x'; MAX_BYTES + 1], CHUNK_BYTES, MAX_BYTES) {
        PayloadPlan::TooLarge { frame, .. } => with_fixed_id(frame),
        plan => unreachable!("a body above the ceiling plans as too large, not {plan:?}"),
    }
}

fn framed(body: Vec<u8>) -> Vec<PayloadFrame> {
    match plan_within(body, CHUNK_BYTES, MAX_BYTES) {
        PayloadPlan::Framed { frames, .. } => frames.into_iter().map(with_fixed_id).collect(),
        plan => unreachable!("a body above one chunk plans as frames, not {plan:?}"),
    }
}

fn with_fixed_id(mut frame: PayloadFrame) -> PayloadFrame {
    for (name, value) in &mut frame.headers {
        if *name == PAYLOAD_HEADER {
            PAYLOAD_ID.clone_into(value);
        }
    }
    frame
}

fn case(name: &str, chunk_bytes: usize, frames: &[PayloadFrame], expect: &Value) -> Value {
    let frames: Vec<Value> = frames
        .iter()
        .map(|frame| {
            json!({
                "headers": frame.headers,
                "body": STANDARD.encode(&frame.body),
            })
        })
        .collect();
    json!({
        "name": name,
        "chunkBytes": chunk_bytes,
        "maxBytes": MAX_BYTES,
        "frames": frames,
        "expect": expect,
    })
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::transport::reference_assembler::{Outcome, ReferenceAssembler};
    use crate::transport::test_support::{vector_outcome, vector_text as text, written_vectors};

    #[test]
    fn the_written_vectors_are_what_this_framer_plans() {
        assert_eq!(written_vectors(), frame_vectors());
    }

    #[test]
    fn a_receiver_following_the_protocol_reaches_every_vector_outcome() {
        let vectors = written_vectors();
        for case in vectors["cases"].as_array().expect("cases") {
            let name = text(&case["name"]);
            let chunk_bytes = case["chunkBytes"].as_u64().expect("chunk size");
            let max_bytes = case["maxBytes"].as_u64().expect("ceiling");
            let mut receiver = ReferenceAssembler::new(
                usize::try_from(chunk_bytes).expect("chunk size fits"),
                usize::try_from(max_bytes).expect("ceiling fits"),
            );
            let frames = case["frames"].as_array().expect("frames");
            let outcomes: Vec<Outcome> = frames
                .iter()
                .map(|frame| {
                    let headers: Vec<(&str, &str)> = frame["headers"]
                        .as_array()
                        .expect("headers")
                        .iter()
                        .map(|pair| (text(&pair[0]), text(&pair[1])))
                        .collect();
                    let body = STANDARD
                        .decode(text(&frame["body"]))
                        .expect("body is base64");
                    receiver.accept(&headers, &body)
                })
                .collect();
            let (last, earlier) = outcomes.split_last().expect("a case has a frame");
            assert!(
                earlier.iter().all(|outcome| *outcome == Outcome::Waiting),
                "{name}: {outcomes:?}"
            );
            assert_eq!(*last, vector_outcome(&case["expect"]), "{name}");
        }
    }
}
