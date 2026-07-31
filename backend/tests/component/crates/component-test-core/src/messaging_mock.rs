use std::{
    collections::VecDeque,
    fmt,
    ops::RangeInclusive,
    sync::{Arc, Mutex},
    time::Duration,
};

use anyhow::{Result, bail};
use wash_runtime::plugin::wasmcloud_messaging::{HostMessage, ResponderRequest};

const TRANSCRIPT_LIMIT: usize = 128;

type BodyPredicate = Arc<dyn Fn(&[u8]) -> bool + Send + Sync>;

#[derive(Clone)]
pub struct MessagingMock {
    state: Arc<Mutex<State>>,
}

struct State {
    expectations: Vec<Expectation>,
    transcript: VecDeque<MessagingTranscriptEntry>,
    failures: Vec<String>,
    redactions: Vec<Vec<u8>>,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct MessagingTranscriptEntry {
    pub operation: MessagingOperation,
    pub subject: String,
    pub body: String,
    pub matched: bool,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum MessagingOperation {
    Publish,
    Request,
}

struct Expectation {
    operation: MessagingOperation,
    pattern: String,
    body: BodyMatch,
    minimum: usize,
    maximum: usize,
    seen: usize,
    reply: Option<ScriptedReply>,
}

enum BodyMatch {
    Any,
    Exact(Vec<u8>),
    Predicate(BodyPredicate),
}

#[derive(Clone)]
enum ScriptedReply {
    Bytes(Vec<u8>, Duration),
    Error(String, Duration),
}

pub struct MessagingExpectation {
    mock: MessagingMock,
    index: usize,
}

impl MessagingMock {
    pub(crate) fn new(redactions: Vec<Vec<u8>>) -> Self {
        Self {
            state: Arc::new(Mutex::new(State {
                expectations: Vec::new(),
                transcript: VecDeque::new(),
                failures: Vec::new(),
                redactions,
            })),
        }
    }

    pub fn expect_publish(&self, pattern: impl Into<String>) -> MessagingExpectation {
        self.push(MessagingOperation::Publish, pattern.into())
    }

    pub fn expect_request(&self, pattern: impl Into<String>) -> MessagingExpectation {
        self.push(MessagingOperation::Request, pattern.into())
    }

    fn push(&self, operation: MessagingOperation, pattern: String) -> MessagingExpectation {
        let mut state = self.state.lock().unwrap_or_else(|error| error.into_inner());
        let index = state.expectations.len();
        state.expectations.push(Expectation {
            operation,
            pattern,
            body: BodyMatch::Any,
            minimum: 1,
            maximum: 1,
            seen: 0,
            reply: None,
        });
        MessagingExpectation {
            mock: self.clone(),
            index,
        }
    }

    pub fn transcript(&self) -> Vec<MessagingTranscriptEntry> {
        self.state
            .lock()
            .unwrap_or_else(|error| error.into_inner())
            .transcript
            .iter()
            .cloned()
            .collect()
    }

    pub(crate) fn record_publish(&self, message: &HostMessage) {
        self.match_message(MessagingOperation::Publish, message);
    }

    pub(crate) fn record_request(&self, request: &ResponderRequest) -> Option<ScriptedResponse> {
        self.match_message(MessagingOperation::Request, &request.message)
            .map(|reply| ScriptedResponse {
                reply: Some(reply),
                request: None,
            })
    }

    fn match_message(
        &self,
        operation: MessagingOperation,
        message: &HostMessage,
    ) -> Option<ScriptedReply> {
        let mut state = self.state.lock().unwrap_or_else(|error| error.into_inner());
        let matched = state.expectations.iter().position(|expectation| {
            expectation.operation == operation
                && expectation.seen < expectation.maximum
                && subject_matches(&expectation.pattern, &message.subject)
                && expectation.body.matches(&message.body)
        });
        let reply = if let Some(index) = matched {
            state.expectations[index].seen += 1;
            state.expectations[index].reply.clone()
        } else {
            state.failures.push(format!(
                "unexpected messaging {operation}: `{}`",
                message.subject
            ));
            None
        };
        let was_matched = matched.is_some();
        let body = redact_body(&message.body, &state.redactions);
        if state.transcript.len() == TRANSCRIPT_LIMIT {
            state.transcript.pop_front();
        }
        state.transcript.push_back(MessagingTranscriptEntry {
            operation,
            subject: message.subject.clone(),
            body,
            matched: was_matched,
        });
        reply
    }

    pub(crate) fn verify(&self) -> Result<()> {
        let state = self.state.lock().unwrap_or_else(|error| error.into_inner());
        let mut failures = state.failures.clone();
        failures.extend(
            state
                .expectations
                .iter()
                .filter(|item| item.seen < item.minimum)
                .map(|item| {
                    format!(
                        "unmet messaging {} expectation `{}`: expected {}..={}, observed {}",
                        item.operation, item.pattern, item.minimum, item.maximum, item.seen
                    )
                }),
        );
        if failures.is_empty() {
            return Ok(());
        }
        let transcript = state
            .transcript
            .iter()
            .map(|entry| {
                format!(
                    "  {} `{}` body={} {}",
                    entry.operation,
                    entry.subject,
                    entry.body,
                    if entry.matched {
                        "matched"
                    } else {
                        "unexpected"
                    }
                )
            })
            .collect::<Vec<_>>()
            .join("\n");
        bail!(
            "{}\nmessaging transcript:\n{}",
            failures.join("\n"),
            transcript
        )
    }
}

impl MessagingExpectation {
    fn update(self, update: impl FnOnce(&mut Expectation)) -> Self {
        {
            let mut state = self
                .mock
                .state
                .lock()
                .unwrap_or_else(|error| error.into_inner());
            if let Some(expectation) = state.expectations.get_mut(self.index) {
                update(expectation);
            }
        }
        self
    }

    pub fn body(self, body: impl Into<Vec<u8>>) -> Self {
        self.update(|item| item.body = BodyMatch::Exact(body.into()))
    }

    pub fn body_matches(self, predicate: impl Fn(&[u8]) -> bool + Send + Sync + 'static) -> Self {
        self.update(|item| item.body = BodyMatch::Predicate(Arc::new(predicate)))
    }

    pub fn times(self, count: usize) -> Self {
        self.update(|item| {
            item.minimum = count;
            item.maximum = count;
        })
    }

    pub fn optional(self) -> Self {
        self.update(|item| {
            item.minimum = 0;
            item.maximum = 1;
        })
    }

    pub fn range(self, range: RangeInclusive<usize>) -> Self {
        self.update(|item| {
            item.minimum = *range.start();
            item.maximum = *range.end();
        })
    }

    pub fn reply(self, body: impl Into<Vec<u8>>) -> Self {
        self.reply_after(body, Duration::ZERO)
    }

    pub fn reply_after(self, body: impl Into<Vec<u8>>, delay: Duration) -> Self {
        self.update(|item| item.reply = Some(ScriptedReply::Bytes(body.into(), delay)))
    }

    pub fn reply_error(self, message: impl Into<String>) -> Self {
        self.reply_error_after(message, Duration::ZERO)
    }

    pub fn reply_error_after(self, message: impl Into<String>, delay: Duration) -> Self {
        self.update(|item| item.reply = Some(ScriptedReply::Error(message.into(), delay)))
    }
}

impl BodyMatch {
    fn matches(&self, body: &[u8]) -> bool {
        match self {
            Self::Any => true,
            Self::Exact(expected) => expected == body,
            Self::Predicate(predicate) => predicate(body),
        }
    }
}

pub(crate) struct ScriptedResponse {
    reply: Option<ScriptedReply>,
    request: Option<ResponderRequest>,
}

impl ScriptedResponse {
    pub(crate) async fn send(mut self, request: ResponderRequest) -> Result<()> {
        self.request = Some(request);
        match self.reply {
            Some(ScriptedReply::Bytes(body, delay)) => {
                tokio::time::sleep(delay).await;
                let subject = self
                    .request
                    .as_ref()
                    .and_then(|value| value.message.reply_to.clone())
                    .unwrap_or_default();
                self.request
                    .take()
                    .ok_or_else(|| anyhow::anyhow!("missing responder request"))?
                    .reply(HostMessage {
                        subject,
                        reply_to: None,
                        body,
                        trace_context: None,
                    })?;
            }
            Some(ScriptedReply::Error(message, delay)) => {
                tokio::time::sleep(delay).await;
                drop(message);
            }
            None => {}
        }
        Ok(())
    }
}

pub fn subject_matches(pattern: &str, subject: &str) -> bool {
    let pattern = pattern.split('.').collect::<Vec<_>>();
    let subject = subject.split('.').collect::<Vec<_>>();
    for (index, token) in pattern.iter().enumerate() {
        if *token == ">" {
            return index + 1 == pattern.len() && index < subject.len();
        }
        if subject
            .get(index)
            .is_none_or(|value| *token != "*" && token != value)
        {
            return false;
        }
    }
    pattern.len() == subject.len()
}

fn redact_body(body: &[u8], redactions: &[Vec<u8>]) -> String {
    if redactions.iter().any(|secret| {
        !secret.is_empty() && body.windows(secret.len()).any(|window| window == secret)
    }) {
        return "[REDACTED]".into();
    }
    const DISPLAY_LIMIT: usize = 96;
    let mut value = String::from_utf8_lossy(&body[..body.len().min(DISPLAY_LIMIT)]).into_owned();
    if body.len() > DISPLAY_LIMIT {
        value.push('…');
    }
    format!("{:?}", value)
}

impl fmt::Display for MessagingOperation {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        formatter.write_str(match self {
            Self::Publish => "publish",
            Self::Request => "request",
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn message(subject: &str, body: &[u8]) -> HostMessage {
        HostMessage {
            subject: subject.into(),
            reply_to: None,
            body: body.into(),
            trace_context: None,
        }
    }

    #[test]
    fn nats_wildcards_match_tokens() {
        assert!(subject_matches("events.*", "events.one"));
        assert!(!subject_matches("events.*", "events.one.two"));
        assert!(subject_matches("events.>", "events.one.two"));
        assert!(!subject_matches("events.>", "events"));
    }

    #[test]
    fn unexpected_unmet_counts_and_redaction_are_reported() {
        let mock = MessagingMock::new(vec![b"secret".to_vec()]);
        mock.expect_publish("ok").body(b"body".to_vec()).times(2);
        mock.record_publish(&message("bad", b"secret"));
        let error = mock.verify().unwrap_err().to_string();
        assert!(error.contains("unexpected"));
        assert!(error.contains("observed 0"));
        assert!(error.contains("[REDACTED]"));
        assert!(!error.contains("secret"));
    }

    #[test]
    fn transcript_is_bounded() {
        let mock = MessagingMock::new(Vec::new());
        mock.expect_publish(">").times(TRANSCRIPT_LIMIT + 1);
        for index in 0..=TRANSCRIPT_LIMIT {
            mock.record_publish(&message(&format!("event.{index}"), b"body"));
        }
        assert_eq!(mock.transcript().len(), TRANSCRIPT_LIMIT);
    }
}
