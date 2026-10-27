//! Properties of the framer, checked against a receiver that follows the shared framing rules.
//!
//! Any body under any chunk size reassembles byte identical however its frames are ordered or
//! duplicated, and a payload missing or altering a frame never yields bytes. Seeds and case counts
//! are fixed so every run checks the same cases; a shrunk failure becomes an example test below.

use proptest::prelude::*;
use proptest::sample::Index;
use proptest::test_runner::{Config, RngSeed};

use super::frame::{PayloadFrame, PayloadPlan, plan_within};
use super::reference_assembler::{Outcome, ReferenceAssembler};

/// The receiver's ceiling; bodies stay below it so every plan is framed or single.
const MAX_BYTES: usize = 4096;

fn config() -> Config {
    Config {
        cases: 256,
        rng_seed: RngSeed::Fixed(0x7970_6577_7269_7465),
        failure_persistence: None,
        ..Config::default()
    }
}

/// A body, a chunk size it spans with at least two frames, and an order to deliver them in.
fn framed_body() -> impl Strategy<Value = (Vec<u8>, usize, Vec<usize>)> {
    (1usize..64)
        .prop_flat_map(|chunk| {
            (
                proptest::collection::vec(any::<u8>(), chunk + 1..=(chunk * 40).min(MAX_BYTES)),
                Just(chunk),
            )
        })
        .prop_flat_map(|(body, chunk)| {
            let order: Vec<usize> = (0..body.len().div_ceil(chunk)).collect();
            (Just(body), Just(chunk), Just(order).prop_shuffle())
        })
}

fn frames_of(body: Vec<u8>, chunk: usize) -> Vec<PayloadFrame> {
    match plan_within(body, chunk, MAX_BYTES) {
        PayloadPlan::Framed { frames, .. } => frames,
        plan => panic!("a body above one chunk plans as frames, not {plan:?}"),
    }
}

/// Every outcome of delivering `frames` in order to a fresh receiver.
fn deliver<'a>(chunk: usize, frames: impl IntoIterator<Item = &'a PayloadFrame>) -> Vec<Outcome> {
    let mut receiver = ReferenceAssembler::new(chunk, MAX_BYTES);
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

fn completions(outcomes: &[Outcome]) -> Vec<&[u8]> {
    outcomes
        .iter()
        .filter_map(|outcome| match outcome {
            Outcome::Complete(bytes) => Some(bytes.as_slice()),
            _ => None,
        })
        .collect()
}

proptest! {
    #![proptest_config(config())]

    #[test]
    fn a_body_within_one_chunk_arrives_as_itself(
        body in proptest::collection::vec(any::<u8>(), 0..64),
        extra in 0usize..64,
    ) {
        let chunk = body.len().max(1) + extra;
        let PayloadPlan::Single(sent) = plan_within(body.clone(), chunk, MAX_BYTES) else {
            panic!("a body within one chunk is one message");
        };
        let outcomes = deliver(chunk, &[PayloadFrame { headers: Vec::new(), body: sent }]);
        prop_assert_eq!(outcomes, vec![Outcome::Complete(body)]);
    }

    #[test]
    fn shuffled_and_duplicated_frames_assemble_byte_identical(
        (body, chunk, order) in framed_body(),
        duplicates in proptest::collection::vec((any::<Index>(), any::<Index>()), 0..6),
    ) {
        let frames = frames_of(body.clone(), chunk);
        let mut delivered: Vec<&PayloadFrame> = order.iter().map(|&index| &frames[index]).collect();
        for (frame, position) in duplicates {
            let duplicate = &frames[frame.index(frames.len())];
            delivered.insert(position.index(delivered.len() + 1), duplicate);
        }
        let outcomes = deliver(chunk, delivered);
        prop_assert!(!outcomes.contains(&Outcome::Rejected), "{outcomes:?}");
        // A completed payload leaves the receiver, so duplicates of every frame arriving after it
        // assemble it again, exactly as a redelivered plain message arrives twice.
        let completions = completions(&outcomes);
        prop_assert!(!completions.is_empty(), "{outcomes:?}");
        prop_assert!(completions.iter().all(|bytes| *bytes == body.as_slice()), "{outcomes:?}");
    }

    #[test]
    fn a_payload_missing_a_frame_never_yields_bytes(
        (body, chunk, order) in framed_body(),
        dropped in any::<Index>(),
    ) {
        let frames = frames_of(body, chunk);
        let missing = order[dropped.index(order.len())];
        let delivered = order.iter().filter(|&&index| index != missing).map(|&index| &frames[index]);
        let outcomes = deliver(chunk, delivered);
        prop_assert!(outcomes.iter().all(|outcome| *outcome == Outcome::Waiting), "{outcomes:?}");
    }

    #[test]
    fn a_payload_with_an_altered_frame_never_yields_bytes(
        (body, chunk, order) in framed_body(),
        altered in any::<Index>(),
        byte in any::<Index>(),
        flip in 1u8..=255,
    ) {
        let mut frames = frames_of(body, chunk);
        let frame = altered.index(frames.len());
        let position = byte.index(frames[frame].body.len());
        frames[frame].body[position] ^= flip;
        let outcomes = deliver(chunk, order.iter().map(|&index| &frames[index]));
        prop_assert!(completions(&outcomes).is_empty(), "{outcomes:?}");
        prop_assert_eq!(outcomes.last(), Some(&Outcome::Rejected));
    }
}
