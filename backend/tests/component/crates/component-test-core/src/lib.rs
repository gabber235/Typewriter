//! Embedded wasmCloud component test runtime.

#![forbid(unsafe_code)]

mod builder;
mod diagnostic;
mod http_mock;
mod manifest;
mod messaging_mock;
mod outgoing;
mod runtime;

pub use http_mock::{ExpectationBuilder, HttpMock, MockRequest, MockResponse};
pub use messaging_mock::{
    MessagingExpectation, MessagingMock, MessagingOperation, MessagingTranscriptEntry,
    subject_matches,
};

pub use builder::{
    ComponentConfiguration, FixtureBuilder, FixtureExtension, FixtureSpec, ProvisionContext,
};

use std::{
    any::{Any, TypeId},
    collections::{HashMap, VecDeque},
    future::Future,
    marker::PhantomData,
    net::SocketAddr,
    panic::AssertUnwindSafe,
    pin::Pin,
    sync::{Arc, OnceLock},
    time::Instant,
};

use anyhow::Result;
use component_test_model::{FixtureDescriptor, TestDescriptor};
use futures_util::FutureExt;
use tokio::{
    runtime::{Builder, Runtime},
    sync::{OwnedSemaphorePermit, Semaphore},
};
use wash_runtime::{engine::Engine, plugin::wasmcloud_messaging::InMemoryMessagingDriver};

pub type TestResult = anyhow::Result<()>;
pub type BoxTestFuture<'a> = Pin<Box<dyn Future<Output = TestResult> + Send + 'a>>;

pub trait FixtureDeclaration: Send + Sync + 'static {
    const DESCRIPTOR: FixtureDescriptor;
}

pub struct TestContext<F> {
    descriptor: &'static TestDescriptor,
    http: Option<(SocketAddr, String)>,
    messaging: Option<InMemoryMessagingDriver>,
    messaging_mock: Option<MessagingMock>,
    handles: HashMap<TypeId, Arc<dyn Any + Send + Sync>>,
    transcript: VecDeque<String>,
    marker: PhantomData<F>,
}
impl<F> TestContext<F> {
    pub fn fixture_id(&self) -> &str {
        self.descriptor.fixture_id
    }
    pub fn test(&self) -> &'static TestDescriptor {
        self.descriptor
    }
    pub fn http_address(&self) -> Option<SocketAddr> {
        self.http.as_ref().map(|value| value.0)
    }
    pub fn http_host(&self) -> Option<&str> {
        self.http.as_ref().map(|value| value.1.as_str())
    }
    pub fn http(&self) -> Result<IncomingHttpClient> {
        let (address, host) = self
            .http
            .as_ref()
            .ok_or_else(|| anyhow::anyhow!("fixture has no incoming HTTP server"))?;
        Ok(IncomingHttpClient {
            base: format!("http://{address}"),
            host: host.clone(),
            client: reqwest::Client::new(),
        })
    }
    pub fn http_mock<M: Send + Sync + 'static>(&self) -> Result<HttpMock> {
        self.handles
            .get(&TypeId::of::<M>())
            .cloned()
            .ok_or_else(|| anyhow::anyhow!("outgoing HTTP marker is not registered"))?
            .downcast::<HttpMock>()
            .map(|value| (*value).clone())
            .map_err(|_| anyhow::anyhow!("registered marker is not an HTTP mock"))
    }
    pub fn messaging(&self) -> Result<MessagingClient> {
        self.messaging
            .clone()
            .map(MessagingClient)
            .ok_or_else(|| anyhow::anyhow!("fixture has no messaging interface"))
    }
    pub fn messaging_mock(&self) -> Result<MessagingMock> {
        self.messaging_mock
            .clone()
            .ok_or_else(|| anyhow::anyhow!("fixture has no messaging interface"))
    }
    pub fn extension<T: Send + Sync + 'static>(&self) -> Option<Arc<T>> {
        self.handles
            .get(&TypeId::of::<T>())
            .cloned()?
            .downcast()
            .ok()
    }
    pub fn diagnostic(&mut self, message: impl Into<String>) {
        if self.transcript.len() == 256 {
            self.transcript.pop_front();
        }
        self.transcript.push_back(message.into());
    }
}

#[derive(Clone)]
pub struct IncomingHttpClient {
    base: String,
    host: String,
    client: reqwest::Client,
}
impl IncomingHttpClient {
    pub fn request(&self, method: http::Method, path: &str) -> reqwest::RequestBuilder {
        self.client
            .request(method, format!("{}{path}", self.base))
            .header(http::header::HOST, &self.host)
    }
    pub fn get(&self, path: &str) -> reqwest::RequestBuilder {
        self.request(http::Method::GET, path)
    }
    pub fn post(&self, path: &str, body: impl Into<reqwest::Body>) -> reqwest::RequestBuilder {
        self.request(http::Method::POST, path).body(body)
    }
    pub async fn bytes(
        &self,
        method: http::Method,
        path: &str,
        body: impl Into<reqwest::Body>,
    ) -> Result<bytes::Bytes> {
        Ok(self
            .request(method, path)
            .body(body)
            .send()
            .await?
            .error_for_status()?
            .bytes()
            .await?)
    }
}

#[derive(Clone)]
pub struct MessagingClient(InMemoryMessagingDriver);
impl MessagingClient {
    pub async fn publish(
        &self,
        subject: impl Into<String>,
        body: impl Into<Vec<u8>>,
    ) -> Result<()> {
        self.0
            .publish(host_message(subject, body))
            .await
            .map_err(Into::into)
    }
    pub async fn request(
        &self,
        subject: impl Into<String>,
        body: impl Into<Vec<u8>>,
        timeout: std::time::Duration,
    ) -> Result<Vec<u8>> {
        Ok(self
            .0
            .request(host_message(subject, body), timeout)
            .await?
            .body)
    }
    pub async fn wait_idle(&self) -> Result<()> {
        self.0.wait_idle().await.map_err(Into::into)
    }
}
fn host_message(
    subject: impl Into<String>,
    body: impl Into<Vec<u8>>,
) -> wash_runtime::plugin::wasmcloud_messaging::HostMessage {
    wash_runtime::plugin::wasmcloud_messaging::HostMessage {
        subject: subject.into(),
        reply_to: None,
        body: body.into(),
        trace_context: None,
    }
}

pub trait IntoTestResult {
    fn into_test_result(self) -> TestResult;
}
impl IntoTestResult for () {
    fn into_test_result(self) -> TestResult {
        Ok(())
    }
}
impl<E: Into<anyhow::Error>> IntoTestResult for Result<(), E> {
    fn into_test_result(self) -> TestResult {
        self.map_err(Into::into)
    }
}

struct Globals {
    runtime: Runtime,
    engine: Engine,
    admission: Arc<Semaphore>,
}
static GLOBALS: OnceLock<Result<Globals, String>> = OnceLock::new();
fn globals() -> Result<&'static Globals> {
    GLOBALS
        .get_or_init(|| {
            wash_runtime::init_crypto();
            let runtime = Builder::new_multi_thread()
                .enable_all()
                .build()
                .map_err(|e| format!("initialization phase: Tokio runtime: {e}"))?;
            let engine = Engine::builder()
                .build()
                .map_err(|e| format!("initialization phase: wash engine: {e:#}"))?;
            Ok(Globals {
                runtime,
                engine,
                admission: Arc::new(Semaphore::new(admission_limit(
                    std::thread::available_parallelism()
                        .map(usize::from)
                        .unwrap_or(1),
                    std::env::var("COMPONENT_TEST_JOBS").ok().as_deref(),
                )?)),
            })
        })
        .as_ref()
        .map_err(|e| anyhow::anyhow!(e.clone()))
}
fn admission_limit(available: usize, configured: Option<&str>) -> Result<usize, String> {
    match configured {
        Some(value) => value
            .parse::<usize>()
            .ok()
            .filter(|value| *value > 0)
            .ok_or_else(|| {
                "admission phase: COMPONENT_TEST_JOBS must be a positive integer".to_string()
            }),
        None => Ok(available.clamp(1, 2)),
    }
}

pub fn run_case<F, B>(descriptor: &'static TestDescriptor, body: B)
where
    F: FixtureSpec,
    B: for<'a> FnOnce(&'a mut TestContext<F>) -> BoxTestFuture<'a>,
{
    let globals = match globals() {
        Ok(value) => value,
        Err(error) => panic!("component test failed: {error:#}"),
    };
    let outcome = globals.runtime.block_on(run::<F, B>(
        globals.admission.clone(),
        globals.engine.clone(),
        descriptor,
        body,
    ));
    match outcome {
        Outcome::Pass => {}
        Outcome::Error(report) => panic!("component test failed:\n{report}"),
        Outcome::Panic(payload, report) => {
            eprintln!("component test failed:\n{report}");
            std::panic::resume_unwind(payload);
        }
    }
}
enum Outcome {
    Pass,
    Error(String),
    Panic(Box<dyn Any + Send>, String),
}
async fn run<F: FixtureSpec, B>(
    admission: Arc<Semaphore>,
    engine: Engine,
    descriptor: &'static TestDescriptor,
    body: B,
) -> Outcome
where
    B: for<'a> FnOnce(&'a mut TestContext<F>) -> BoxTestFuture<'a>,
{
    let started = Instant::now();
    let mut diagnostic = diagnostic::DiagnosticReport::new(
        descriptor.fixture_id,
        descriptor.exact_name,
        descriptor.case,
        Vec::new(),
    );
    let _permit: OwnedSemaphorePermit = match admission.acquire_owned().await {
        Ok(value) => value,
        Err(error) => return Outcome::Error(format!("admitted: {error}")),
    };
    diagnostic.phase("validated");
    let artifacts = match manifest::artifacts(&F::DESCRIPTOR) {
        Ok(artifacts) => artifacts,
        Err(error) => {
            return Outcome::Error(format!("validated ({:?}): {error:#}", started.elapsed()));
        }
    };
    let mut builder = F::configure(FixtureBuilder::new());
    if let Err(error) = builder.validate() {
        return Outcome::Error(format!("validated ({:?}): {error:#}", started.elapsed()));
    }
    for artifact in artifacts.values() {
        diagnostic.artifact(&artifact.path, &artifact.digest);
    }
    diagnostic.phase("provisioning");
    let mut provision = ProvisionContext::default();
    let mut failures = Vec::new();
    let mut provisioned = 0;
    for extension in &mut builder.extensions {
        // Provision may allocate before returning or being cancelled, so the
        // current extension must always participate in reverse-order cleanup.
        provisioned += 1;
        match tokio::time::timeout(builder.start_timeout, extension.provision(&mut provision)).await
        {
            Ok(Ok(())) => {}
            Ok(Err(error)) => {
                failures.push(format!("provisioning: {error:#}"));
                break;
            }
            Err(_) => {
                failures.push(format!(
                    "provisioning: timed out after {:?}",
                    builder.start_timeout
                ));
                break;
            }
        }
    }
    let mut handles = provision.handles.clone();
    handles.extend(builder.mock_handles.clone());
    let transcript = provision.diagnostics.iter().cloned().collect();
    let mut report_redactions = provision.redactions.clone();
    report_redactions.extend(
        builder
            .components
            .values()
            .chain(provision.components.values())
            .flat_map(|configuration| {
                configuration
                    .secret_environment
                    .iter()
                    .filter_map(|name| configuration.environment.get(name).cloned())
            }),
    );
    let workload_id = uuid::Uuid::new_v4().to_string();
    let mut running = None;
    diagnostic.phase("host-start/workload-start");
    if failures.is_empty() {
        match runtime::start(
            engine,
            &mut builder,
            &artifacts,
            provision,
            workload_id.clone(),
        )
        .await
        {
            Ok(value) => running = Some(value),
            Err(error) => failures.push(format!("starting: {error:#}")),
        }
    }
    diagnostic.phase("ready");
    if running.is_some() {
        for extension in builder.extensions.iter_mut().take(provisioned) {
            match tokio::time::timeout(builder.start_timeout, extension.before_start()).await {
                Ok(Ok(())) => {}
                Ok(Err(error)) => {
                    failures.push(format!("before_start: {error:#}"));
                    break;
                }
                Err(_) => {
                    failures.push(format!(
                        "before_start: timed out after {:?}",
                        builder.start_timeout
                    ));
                    break;
                }
            }
        }
    }
    let mut context = if let Some(fixture) = &running {
        fixture.context(descriptor, handles, transcript)
    } else {
        TestContext {
            descriptor,
            http: None,
            messaging: None,
            messaging_mock: None,
            handles,
            transcript,
            marker: PhantomData,
        }
    };
    let mut panic = None;
    diagnostic.phase("executing");
    if failures.is_empty() {
        match tokio::time::timeout(
            builder.body_timeout,
            AssertUnwindSafe(body(&mut context)).catch_unwind(),
        )
        .await
        {
            Ok(Ok(Ok(()))) => {}
            Ok(Ok(Err(error))) => failures.push(format!("executing: {error:#}")),
            Ok(Err(payload)) => panic = Some(payload),
            Err(_) => failures.push(format!(
                "executing: timed out after {:?}",
                builder.body_timeout
            )),
        }
    }
    diagnostic.phase("draining");
    if let Some(fixture) = &running
        && let Some(messaging) = &fixture.messaging
    {
        match tokio::time::timeout(builder.drain_timeout, messaging.wait_idle()).await {
            Ok(Ok(())) => {}
            Ok(Err(error)) => failures.push(format!("draining messaging: {error}")),
            Err(_) => failures.push(format!(
                "draining messaging: timed out after {:?}",
                builder.drain_timeout
            )),
        }
    }
    diagnostic.phase("verifying");
    if let Some(fixture) = &mut running {
        tokio::task::yield_now().await;
        if let Err(error) = fixture.stop_messaging_monitors(builder.drain_timeout).await {
            failures.push(format!("stopping messaging monitors: {error:#}"));
        }
        if let Some(mock) = &fixture.messaging_mock
            && let Err(error) = mock.verify()
        {
            failures.push(format!("verifying messaging: {error:#}"));
        }
    }
    if let Err(error) = builder.http_mocks.verify() {
        failures.push(format!("verifying outgoing HTTP: {error:#}"));
    }
    for extension in builder.extensions.iter_mut().take(provisioned) {
        match tokio::time::timeout(builder.stop_timeout, extension.verify()).await {
            Ok(Ok(())) => {}
            Ok(Err(error)) => failures.push(format!("verifying: {error:#}")),
            Err(_) => failures.push(format!(
                "verifying extension: timed out after {:?}",
                builder.stop_timeout
            )),
        }
    }
    diagnostic.phase("stopping workload");
    if let Some(fixture) = running {
        use wash_runtime::{
            host::HostApi,
            types::{WorkloadState, WorkloadStopRequest},
        };
        match tokio::time::timeout(
            builder.stop_timeout,
            fixture.host.workload_stop(WorkloadStopRequest {
                workload_id: fixture.workload_id.clone(),
            }),
        )
        .await
        {
            Ok(Ok(response))
                if response.workload_status.workload_state == WorkloadState::Stopping
                    || response.workload_status.workload_state == WorkloadState::Completed
                    || response.workload_status.workload_state == WorkloadState::NotFound => {}
            Ok(Ok(response)) => failures.push(format!(
                "stopping workload: {:?}: {}",
                response.workload_status.workload_state, response.workload_status.message
            )),
            Ok(Err(error)) => failures.push(format!("stopping workload: {error:#}")),
            Err(_) => failures.push(format!(
                "stopping workload: timed out after {:?}",
                builder.stop_timeout
            )),
        }
        for line in fixture.diagnostics.lines() {
            context.diagnostic(line);
        }
        diagnostic.phase("stopping host");
        if let Err(error) = tokio::time::timeout(builder.stop_timeout, fixture.host.stop())
            .await
            .map_err(|_| anyhow::anyhow!("timed out after {:?}", builder.stop_timeout))
            .and_then(|value| value)
        {
            failures.push(format!("stopping host: {error:#}"));
        }
    }
    diagnostic.phase("cleaning extensions");
    for extension in builder.extensions.iter_mut().take(provisioned).rev() {
        match tokio::time::timeout(builder.stop_timeout, extension.cleanup()).await {
            Ok(Ok(())) => {}
            Ok(Err(error)) => failures.push(format!("cleaning extensions: {error:#}")),
            Err(_) => failures.push(format!(
                "cleaning extension: timed out after {:?}",
                builder.stop_timeout
            )),
        }
    }
    diagnostic.add_redactions(report_redactions);
    for failure in &failures {
        diagnostic.fail(failure);
    }
    for line in context.transcript {
        diagnostic.event(line);
    }
    let report = diagnostic.finish();
    if let Some(payload) = panic {
        Outcome::Panic(payload, report)
    } else if failures.is_empty() {
        Outcome::Pass
    } else {
        Outcome::Error(report)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn admission_defaults_are_conservative() {
        assert_eq!(admission_limit(8, None), Ok(2));
        assert_eq!(admission_limit(0, None), Ok(1));
        assert!(admission_limit(2, Some("0")).is_err());
    }
}
