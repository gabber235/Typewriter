use std::{
    collections::{HashMap, HashSet, VecDeque},
    future::Future,
    ops::RangeInclusive,
    pin::Pin,
    sync::{Arc, Mutex},
    time::Duration,
};

use anyhow::{Result, anyhow, bail};
use bytes::Bytes;
use http::{HeaderMap, Method, StatusCode, Uri};
use serde::Serialize;

const MAX_BODY: usize = 64 * 1024;
const MAX_TRANSCRIPT: usize = 256;
const SECRET_HEADERS: [&str; 4] = [
    "authorization",
    "cookie",
    "set-cookie",
    "proxy-authorization",
];

#[derive(Clone, Debug)]
pub struct MockRequest {
    pub method: Method,
    pub uri: Uri,
    pub headers: HeaderMap,
    pub body: Bytes,
}
#[derive(Clone, Debug)]
pub struct MockResponse {
    pub status: StatusCode,
    pub headers: HeaderMap,
    pub body: Bytes,
    pub delay: Duration,
    pub failure: Option<String>,
}
impl Default for MockResponse {
    fn default() -> Self {
        Self {
            status: StatusCode::OK,
            headers: HeaderMap::new(),
            body: Bytes::new(),
            delay: Duration::ZERO,
            failure: None,
        }
    }
}

type Predicate = Arc<dyn Fn(&[u8]) -> bool + Send + Sync>;
type HandlerFuture = Pin<Box<dyn Future<Output = Result<MockResponse>> + Send>>;
type Handler = Arc<dyn Fn(MockRequest) -> HandlerFuture + Send + Sync>;
#[derive(Clone)]
enum BodyMatcher {
    Exact(Bytes),
    Json(serde_json::Value),
    Predicate(Predicate),
}
#[derive(Clone)]
struct Expectation {
    method: Option<Method>,
    authority: Option<String>,
    path_query: Option<String>,
    headers: HeaderMap,
    exact_headers: bool,
    body: Option<BodyMatcher>,
    count: RangeInclusive<usize>,
    seen: usize,
    response: MockResponse,
}
#[derive(Default)]
struct State {
    expectations: Vec<Expectation>,
    unexpected: Vec<String>,
    transcript: VecDeque<String>,
    handler: Option<Handler>,
    secrets: Vec<String>,
}
#[derive(Clone)]
pub struct HttpMock {
    pub(crate) authority: String,
    state: Arc<Mutex<State>>,
}
impl HttpMock {
    pub(crate) fn new(authority: String) -> Self {
        Self {
            authority,
            state: Arc::new(Mutex::new(State::default())),
        }
    }
    pub fn authority(&self) -> &str {
        &self.authority
    }
    pub fn expect(&self) -> ExpectationBuilder {
        ExpectationBuilder {
            mock: self.clone(),
            expectation: Expectation {
                method: None,
                authority: Some(self.authority.clone()),
                path_query: None,
                headers: HeaderMap::new(),
                exact_headers: false,
                body: None,
                count: 1..=1,
                seen: 0,
                response: MockResponse::default(),
            },
        }
    }
    pub fn handler<F, Fut>(&self, handler: F)
    where
        F: Fn(MockRequest) -> Fut + Send + Sync + 'static,
        Fut: Future<Output = Result<MockResponse>> + Send + 'static,
    {
        if let Ok(mut s) = self.state.lock() {
            s.handler = Some(Arc::new(move |r| Box::pin(handler(r))));
        }
    }
    pub fn redact(&self, secret: impl Into<String>) {
        if let Ok(mut s) = self.state.lock() {
            s.secrets.push(secret.into());
        }
    }
    pub fn transcript(&self) -> Vec<String> {
        self.state
            .lock()
            .map(|s| s.transcript.iter().cloned().collect())
            .unwrap_or_default()
    }
    pub(crate) async fn dispatch(&self, request: MockRequest) -> Result<MockResponse> {
        let handler = self
            .state
            .lock()
            .map_err(|_| anyhow!("HTTP mock lock poisoned"))?
            .handler
            .clone();
        if let Some(handler) = handler {
            return handler(request).await;
        }
        let mut state = self
            .state
            .lock()
            .map_err(|_| anyhow!("HTTP mock lock poisoned"))?;
        let summary = redacted_request(&request, &state.secrets);
        push_bounded(&mut state.transcript, summary.clone());
        let mut nearest = None;
        for (index, expectation) in state.expectations.iter().enumerate() {
            let differences = differences(expectation, &request);
            if differences.is_empty() && expectation.seen < *expectation.count.end() {
                nearest = Some((index, differences));
                break;
            }
            if nearest
                .as_ref()
                .is_none_or(|(_, old): &(usize, Vec<String>)| differences.len() < old.len())
            {
                nearest = Some((index, differences));
            }
        }
        if let Some((index, ref differences)) = nearest
            && differences.is_empty()
        {
            let e = &mut state.expectations[index];
            e.seen += 1;
            return Ok(e.response.clone());
        }
        let detail = nearest
            .map(|(_, d)| d.join(", "))
            .unwrap_or_else(|| "no expectations registered".into());
        let message =
            format!("unexpected outgoing HTTP call: {summary}; nearest mismatch: {detail}");
        state.unexpected.push(message.clone());
        bail!(message)
    }
    pub(crate) fn verify(&self) -> Result<()> {
        let state = self
            .state
            .lock()
            .map_err(|_| anyhow!("HTTP mock lock poisoned"))?;
        let mut errors = state.unexpected.clone();
        for e in &state.expectations {
            if !e.count.contains(&e.seen) {
                errors.push(format!(
                    "unmet HTTP expectation {} {}: expected {:?}, observed {}",
                    e.method.as_ref().map_or("*", Method::as_str),
                    e.path_query.as_deref().unwrap_or("*"),
                    e.count,
                    e.seen
                ));
            }
        }
        if errors.is_empty() {
            Ok(())
        } else {
            bail!(
                "{}\ntranscript:\n{}",
                errors.join("\n"),
                state
                    .transcript
                    .iter()
                    .cloned()
                    .collect::<Vec<_>>()
                    .join("\n")
            )
        }
    }
}
fn push_bounded(queue: &mut VecDeque<String>, value: String) {
    if queue.len() == MAX_TRANSCRIPT {
        queue.pop_front();
    }
    queue.push_back(value)
}
fn differences(e: &Expectation, r: &MockRequest) -> Vec<String> {
    let mut d = vec![];
    if e.method.as_ref().is_some_and(|v| v != r.method) {
        d.push(format!("method expected {:?}, got {}", e.method, r.method));
    }
    if e.authority
        .as_deref()
        .is_some_and(|v| Some(v) != r.uri.authority().map(|a| a.as_str()))
    {
        d.push("authority differs".into());
    }
    if e.path_query
        .as_deref()
        .is_some_and(|v| v != r.uri.path_and_query().map_or("/", |p| p.as_str()))
    {
        d.push("path/query differs".into());
    }
    for (k, v) in &e.headers {
        if r.headers.get_all(k).iter().all(|got| got != v) {
            d.push(format!("header {} differs", k));
        }
    }
    if e.exact_headers && e.headers != r.headers {
        d.push("header set differs".into());
    }
    match &e.body {
        Some(BodyMatcher::Exact(v)) if v.as_ref() != r.body => d.push("body bytes differ".into()),
        Some(BodyMatcher::Json(v))
            if serde_json::from_slice::<serde_json::Value>(&r.body)
                .ok()
                .as_ref()
                != Some(v) =>
        {
            d.push("JSON body differs".into())
        }
        Some(BodyMatcher::Predicate(v)) if !v(&r.body) => {
            d.push("body predicate rejected value".into())
        }
        _ => {}
    }
    d
}
fn redacted_request(r: &MockRequest, secrets: &[String]) -> String {
    let mut headers = vec![];
    for (k, v) in &r.headers {
        let value = if SECRET_HEADERS.contains(&k.as_str()) {
            "[REDACTED]".into()
        } else {
            String::from_utf8_lossy(v.as_bytes()).into_owned()
        };
        headers.push(format!("{k}: {value}"));
    }
    let mut body = String::from_utf8_lossy(&r.body[..r.body.len().min(MAX_BODY)]).into_owned();
    for secret in secrets {
        if !secret.is_empty() {
            body = body.replace(secret, "[REDACTED]");
        }
    }
    format!(
        "{} {} headers=[{}] body={body}",
        r.method,
        r.uri,
        headers.join(", ")
    )
}

pub struct ExpectationBuilder {
    mock: HttpMock,
    expectation: Expectation,
}
impl ExpectationBuilder {
    pub fn method(mut self, method: Method) -> Self {
        self.expectation.method = Some(method);
        self
    }
    pub fn get(self) -> Self {
        self.method(Method::GET)
    }
    pub fn post(self) -> Self {
        self.method(Method::POST)
    }
    pub fn authority(mut self, value: impl Into<String>) -> Self {
        self.expectation.authority = Some(value.into());
        self
    }
    pub fn path_query(mut self, value: impl Into<String>) -> Self {
        self.expectation.path_query = Some(value.into());
        self
    }
    pub fn header(mut self, name: http::HeaderName, value: http::HeaderValue) -> Self {
        self.expectation.headers.append(name, value);
        self
    }
    pub fn exact_headers(mut self) -> Self {
        self.expectation.exact_headers = true;
        self
    }
    pub fn body(mut self, value: impl Into<Bytes>) -> Self {
        self.expectation.body = Some(BodyMatcher::Exact(value.into()));
        self
    }
    pub fn json<T: Serialize>(mut self, value: &T) -> Result<Self> {
        self.expectation.body = Some(BodyMatcher::Json(serde_json::to_value(value)?));
        Ok(self)
    }
    pub fn body_matches(mut self, p: impl Fn(&[u8]) -> bool + Send + Sync + 'static) -> Self {
        self.expectation.body = Some(BodyMatcher::Predicate(Arc::new(p)));
        self
    }
    pub fn times(mut self, count: usize) -> Self {
        self.expectation.count = count..=count;
        self
    }
    pub fn optional(mut self) -> Self {
        self.expectation.count = 0..=1;
        self
    }
    pub fn count(mut self, range: RangeInclusive<usize>) -> Self {
        self.expectation.count = range;
        self
    }
    pub fn status(mut self, status: StatusCode) -> Self {
        self.expectation.response.status = status;
        self
    }
    pub fn response_header(mut self, name: http::HeaderName, value: http::HeaderValue) -> Self {
        self.expectation.response.headers.append(name, value);
        self
    }
    pub fn response_body(mut self, value: impl Into<Bytes>) -> Self {
        self.expectation.response.body = value.into();
        self
    }
    pub fn response_json<T: Serialize>(mut self, value: &T) -> Result<Self> {
        self.expectation.response.body = Bytes::from(serde_json::to_vec(value)?);
        self.expectation.response.headers.insert(
            http::header::CONTENT_TYPE,
            http::HeaderValue::from_static("application/json"),
        );
        Ok(self)
    }
    pub fn delay(mut self, value: Duration) -> Self {
        self.expectation.response.delay = value;
        self
    }
    pub fn transport_failure(mut self, message: impl Into<String>) -> Self {
        self.expectation.response.failure = Some(message.into());
        self
    }
    pub fn register(self) -> Result<()> {
        let mut state = self
            .mock
            .state
            .lock()
            .map_err(|_| anyhow!("HTTP mock lock poisoned"))?;
        state.expectations.push(self.expectation);
        Ok(())
    }
}

#[derive(Clone, Default)]
pub(crate) struct MockRegistry {
    mocks: HashMap<String, HttpMock>,
    identities: HashSet<std::any::TypeId>,
}
impl MockRegistry {
    pub fn insert<M: Send + Sync + 'static>(&mut self, authority: String) -> Result<HttpMock> {
        if !self.identities.insert(std::any::TypeId::of::<M>()) {
            bail!("duplicate outgoing HTTP marker");
        }
        if self.mocks.contains_key(&authority) {
            bail!("duplicate outgoing HTTP authority `{authority}`");
        }
        let mock = HttpMock::new(authority.clone());
        self.mocks.insert(authority, mock.clone());
        Ok(mock)
    }
    pub fn find(&self, authority: &str) -> Option<HttpMock> {
        self.mocks.get(authority).cloned()
    }
    pub fn verify(&self) -> Result<()> {
        let errors = self
            .mocks
            .values()
            .filter_map(|m| m.verify().err().map(|e| e.to_string()))
            .collect::<Vec<_>>();
        if errors.is_empty() {
            Ok(())
        } else {
            bail!(errors.join("\n"))
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    fn request(body: impl Into<Bytes>) -> MockRequest {
        MockRequest {
            method: Method::POST,
            uri: "http://mock.test/items?a=1".parse().unwrap(),
            headers: HeaderMap::new(),
            body: body.into(),
        }
    }

    #[tokio::test]
    async fn matches_json_headers_counts_and_response() {
        let mock = HttpMock::new("mock.test".into());
        mock.expect()
            .post()
            .path_query("/items?a=1")
            .header(
                http::header::ACCEPT,
                http::HeaderValue::from_static("application/json"),
            )
            .json(&json!({"a": 1}))
            .unwrap()
            .times(2)
            .status(StatusCode::CREATED)
            .response_json(&json!({"ok": true}))
            .unwrap()
            .register()
            .unwrap();
        let mut value = request(br#"{"a":1}"#.as_slice());
        value.headers.insert(
            http::header::ACCEPT,
            http::HeaderValue::from_static("application/json"),
        );
        assert_eq!(
            mock.dispatch(value.clone()).await.unwrap().status,
            StatusCode::CREATED
        );
        mock.dispatch(value).await.unwrap();
        assert!(mock.verify().is_ok());
    }

    #[tokio::test]
    async fn reports_no_call_unmet_and_unexpected() {
        let mock = HttpMock::new("mock.test".into());
        mock.expect().get().register().unwrap();
        assert!(mock.verify().unwrap_err().to_string().contains("unmet"));
        assert!(
            mock.dispatch(request(Bytes::new()))
                .await
                .unwrap_err()
                .to_string()
                .contains("nearest mismatch")
        );
    }

    #[tokio::test]
    async fn supports_delay_failure_predicate_optional_and_redaction() {
        let mock = HttpMock::new("mock.test".into());
        mock.redact("body-secret");
        mock.expect()
            .body_matches(|body| body == b"failure")
            .delay(Duration::from_millis(1))
            .transport_failure("reset")
            .register()
            .unwrap();
        let response = mock.dispatch(request("failure")).await.unwrap();
        assert_eq!(response.failure.as_deref(), Some("reset"));
        mock.expect().get().optional().register().unwrap();
        let mut secret = request("body-secret");
        secret.headers.insert(
            http::header::AUTHORIZATION,
            http::HeaderValue::from_static("token"),
        );
        let _ = mock.dispatch(secret).await;
        let transcript = mock.transcript().join("\n");
        assert!(!transcript.contains("token"));
        assert!(!transcript.contains("body-secret"));
    }

    #[tokio::test]
    async fn scoped_handler_is_an_escape_hatch() {
        let mock = HttpMock::new("mock.test".into());
        mock.handler(|request| async move {
            Ok(MockResponse {
                status: if request.body == "yes" {
                    StatusCode::ACCEPTED
                } else {
                    StatusCode::BAD_REQUEST
                },
                ..Default::default()
            })
        });
        assert_eq!(
            mock.dispatch(request("yes")).await.unwrap().status,
            StatusCode::ACCEPTED
        );
    }
}
