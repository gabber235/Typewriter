//! A receiver that applies the framing acceptance rules the services and panel assemblers share.
//!
//! Components only send framed payloads, so production code holds no assembler. The framer's
//! properties and the shared frame vectors are checked against this one: frames group by payload
//! id and may arrive in any order, an identical duplicate is accepted and a changed one rejected,
//! bounds are checked per frame, and a payload is returned only once its size and digest verify.

use std::collections::HashMap;

use sha2::{Digest, Sha256};

use super::frame::{CHUNK_HEADER, FAILURE_HEADER, PAYLOAD_HEADER, SHA256_HEADER, SIZE_HEADER};

/// What one accepted message means for the receiver.
#[derive(Debug, PartialEq, Eq)]
pub(crate) enum Outcome {
    /// More frames are needed.
    Waiting,
    /// A whole payload, verified against its declared size and digest.
    Complete(Vec<u8>),
    /// The frame breaks the protocol; its assembly is dropped.
    Rejected,
    /// The sender reported this transfer failure; its assembly is dropped.
    Failed(String),
}

pub(crate) struct ReferenceAssembler {
    chunk_bytes: usize,
    max_bytes: usize,
    pending: HashMap<String, Parts>,
}

struct Parts {
    size: usize,
    sha256: String,
    parts: Vec<Option<Vec<u8>>>,
}

struct Frame<'a> {
    index: usize,
    count: usize,
    size: usize,
    sha256: &'a str,
}

impl ReferenceAssembler {
    pub(crate) fn new(chunk_bytes: usize, max_bytes: usize) -> Self {
        Self {
            chunk_bytes,
            max_bytes,
            pending: HashMap::new(),
        }
    }

    pub(crate) fn accept(&mut self, headers: &[(&str, &str)], body: &[u8]) -> Outcome {
        let header = |name: &str| {
            headers
                .iter()
                .find(|(candidate, _)| *candidate == name)
                .map(|(_, value)| *value)
        };
        let Some(payload_id) = header(PAYLOAD_HEADER) else {
            return Outcome::Complete(body.to_vec());
        };
        if let Some(failure) = header(FAILURE_HEADER) {
            self.pending.remove(payload_id);
            return Outcome::Failed(failure.to_owned());
        }
        let outcome = self
            .parse(&header, body)
            .map_or(Outcome::Rejected, |frame| {
                self.accept_frame(payload_id, &frame, body)
            });
        if matches!(outcome, Outcome::Rejected | Outcome::Complete(_)) {
            self.pending.remove(payload_id);
        }
        outcome
    }

    fn parse<'a>(
        &self,
        header: &impl Fn(&str) -> Option<&'a str>,
        body: &[u8],
    ) -> Option<Frame<'a>> {
        let (index, count) = header(CHUNK_HEADER)?.split_once('/')?;
        let frame = Frame {
            index: digits(index, 9)?,
            count: digits(count, 9)?,
            size: digits(header(SIZE_HEADER)?, 15)?,
            sha256: header(SHA256_HEADER)?,
        };
        let digest = frame.sha256.len() == 64
            && frame
                .sha256
                .bytes()
                .all(|byte| byte.is_ascii_digit() || (b'a'..=b'f').contains(&byte));
        let bounded = frame.count >= 1
            && frame.count <= self.max_bytes.div_ceil(self.chunk_bytes)
            && frame.index < frame.count
            && frame.size <= self.max_bytes
            && body.len() <= self.chunk_bytes;
        (digest && bounded).then_some(frame)
    }

    fn accept_frame(&mut self, payload_id: &str, frame: &Frame<'_>, body: &[u8]) -> Outcome {
        let entry = self
            .pending
            .entry(payload_id.to_owned())
            .or_insert_with(|| Parts {
                size: frame.size,
                sha256: frame.sha256.to_owned(),
                parts: vec![None; frame.count],
            });
        if entry.parts.len() != frame.count
            || entry.size != frame.size
            || entry.sha256 != frame.sha256
        {
            return Outcome::Rejected;
        }
        if let Some(prior) = &entry.parts[frame.index] {
            return if prior == body {
                Outcome::Waiting
            } else {
                Outcome::Rejected
            };
        }
        entry.parts[frame.index] = Some(body.to_vec());
        let retained: usize = entry.parts.iter().flatten().map(Vec::len).sum();
        if retained > entry.size {
            return Outcome::Rejected;
        }
        if entry.parts.iter().any(Option::is_none) {
            return Outcome::Waiting;
        }
        let bytes: Vec<u8> = entry.parts.iter().flatten().flatten().copied().collect();
        let digest: String = Sha256::digest(&bytes)
            .iter()
            .map(|byte| format!("{byte:02x}"))
            .collect();
        if bytes.len() == entry.size && digest == entry.sha256 {
            Outcome::Complete(bytes)
        } else {
            Outcome::Rejected
        }
    }
}

/// A decimal of one to `max_digits` digits: nine for chunk positions and fifteen for sizes, the
/// bounds every transport, including the panel on the web, parses exactly.
fn digits(value: &str, max_digits: usize) -> Option<usize> {
    (!value.is_empty()
        && value.len() <= max_digits
        && value.bytes().all(|byte| byte.is_ascii_digit()))
    .then(|| value.parse().ok())
    .flatten()
}
