use std::{future::Future, sync::Arc, time::Duration};

use anyhow::{Context, Result};
use component_test::{IncomingHttpClient, MessagingExpectation, TestContext};
use skir_client::UnrecognizedValues;
use wasmcloud_utils::SkirType;

use crate::{DatabaseHandle, topology};

/// How long a request waits for the component's reply.
pub const REQUEST_TIMEOUT: Duration = Duration::from_secs(5);

pub struct SkirHttpResponse<T> {
    pub status: reqwest::StatusCode,
    pub headers: reqwest::header::HeaderMap,
    pub body: T,
}

/// Skir requests to a fixture's incoming HTTP routes, with serializers taken from the types.
pub trait SkirHttpExt {
    /// Posts `request` as Skir binary and decodes the reply as `Resp`.
    fn skir_post<Req: SkirType + Sync, Resp: SkirType>(
        &self,
        path: &str,
        request: &Req,
    ) -> impl Future<Output = Result<SkirHttpResponse<Resp>>> + Send;
}

impl SkirHttpExt for IncomingHttpClient {
    fn skir_post<Req: SkirType + Sync, Resp: SkirType>(
        &self,
        path: &str,
        request: &Req,
    ) -> impl Future<Output = Result<SkirHttpResponse<Resp>>> + Send {
        let request = self
            .request(reqwest::Method::POST, path)
            .header(reqwest::header::CONTENT_TYPE, "application/octet-stream")
            .header("x-typewriter-format", "skir-binary")
            .body(<Req as SkirType>::serializer().to_bytes(request));
        async move {
            let response = request.send().await?;
            let status = response.status();
            let headers = response.headers().clone();
            let bytes = response.bytes().await?;
            let body = <Resp as SkirType>::serializer()
                .from_bytes(&bytes, UnrecognizedValues::Drop)
                .context("decoding Skir HTTP response")?;
            Ok(SkirHttpResponse {
                status,
                headers,
                body,
            })
        }
    }
}

/// Typewriter's view of a running fixture: its database and typed Skir messaging.
///
/// Requests wait [`REQUEST_TIMEOUT`] and drop fields the test's schema does not know. Raw byte
/// messaging stays available through `context.messaging()` for malformed payload cases.
pub trait TypewriterContext {
    /// The fixture's database.
    fn database(&self) -> Result<Arc<DatabaseHandle>>;

    /// Sends a request and decodes the component's reply.
    fn request<Req: SkirType + Sync, Resp: SkirType>(
        &self,
        subject: impl Into<String>,
        request: &Req,
    ) -> impl Future<Output = Result<Resp>> + Send;

    /// Sends a request whose effects are setup for the case, not its subject.
    ///
    /// The broker traffic it causes, such as the events a created organization publishes, is
    /// neither expected nor unexpected; the call returns once that traffic has settled.
    fn arrange<Req: SkirType + Sync, Resp: SkirType + Send>(
        &self,
        subject: impl Into<String>,
        request: &Req,
    ) -> impl Future<Output = Result<Resp>> + Send;

    /// Publishes one event into the fixture's broker.
    fn publish<T: SkirType + Sync>(
        &self,
        subject: impl Into<String>,
        event: &T,
    ) -> impl Future<Output = Result<()>> + Send;

    /// Expects one component publish on `subject` whose event satisfies `matches`.
    ///
    /// A subject the topology persists into a stream is expected as a persisted publish, so the
    /// event must also have been accepted by its stream.
    fn expect_publish<T: SkirType>(
        &self,
        subject: impl Into<String>,
        matches: impl Fn(&T) -> bool + Send + Sync + 'static,
    ) -> Result<MessagingExpectation>;

    /// States that no component publishes on `subject` during the case.
    fn expect_no_publish(&self, subject: impl Into<String>) -> Result<()>;
}

impl<F> TypewriterContext for TestContext<F> {
    fn database(&self) -> Result<Arc<DatabaseHandle>> {
        self.extension::<DatabaseHandle>()
            .context("fixture has no Typewriter database")
    }

    fn request<Req: SkirType + Sync, Resp: SkirType>(
        &self,
        subject: impl Into<String>,
        request: &Req,
    ) -> impl Future<Output = Result<Resp>> + Send {
        let messaging = self.messaging();
        let subject = subject.into();
        let body = <Req as SkirType>::serializer().to_bytes(request);
        async move {
            let bytes = messaging?
                .request(subject.clone(), body, REQUEST_TIMEOUT)
                .await
                .with_context(|| format!("requesting `{subject}`"))?;
            <Resp as SkirType>::serializer()
                .from_bytes(&bytes, UnrecognizedValues::Drop)
                .with_context(|| format!("decoding the reply to `{subject}`"))
        }
    }

    fn arrange<Req: SkirType + Sync, Resp: SkirType + Send>(
        &self,
        subject: impl Into<String>,
        request: &Req,
    ) -> impl Future<Output = Result<Resp>> + Send {
        let mock = self.messaging_mock();
        let messaging = self.messaging();
        let reply = self.request(subject, request);
        async move {
            let _arranging = mock?.arranging();
            let reply = reply.await?;
            messaging?.wait_idle().await?;
            Ok(reply)
        }
    }

    fn publish<T: SkirType + Sync>(
        &self,
        subject: impl Into<String>,
        event: &T,
    ) -> impl Future<Output = Result<()>> + Send {
        let messaging = self.messaging();
        let subject = subject.into();
        let body = <T as SkirType>::serializer().to_bytes(event);
        async move { messaging?.publish(subject, body).await }
    }

    fn expect_publish<T: SkirType>(
        &self,
        subject: impl Into<String>,
        matches: impl Fn(&T) -> bool + Send + Sync + 'static,
    ) -> Result<MessagingExpectation> {
        let subject = subject.into();
        let mock = self.messaging_mock()?;
        let expectation = if topology::is_persisted(&subject) {
            mock.expect_persisted_publish(subject)
        } else {
            mock.expect_publish(subject)
        };
        Ok(expectation.body_matches(move |body| {
            <T as SkirType>::serializer()
                .from_bytes(body, UnrecognizedValues::Drop)
                .is_ok_and(|event| matches(&event))
        }))
    }

    fn expect_no_publish(&self, subject: impl Into<String>) -> Result<()> {
        let subject = subject.into();
        let mock = self.messaging_mock()?;
        if topology::is_persisted(&subject) {
            mock.expect_persisted_publish(subject).times(0);
        } else {
            mock.expect_publish(subject).times(0);
        }
        Ok(())
    }
}

/// Typed bodies and replies for expectations on requests a component sends.
pub trait SkirMessagingExpectationExt {
    /// Requires the request body to be exactly `value`.
    fn body_skir<T: SkirType>(self, value: &T) -> Self;
    /// Answers the request with `value`.
    fn reply_skir<T: SkirType>(self, value: &T) -> Self;
}

impl SkirMessagingExpectationExt for MessagingExpectation {
    fn body_skir<T: SkirType>(self, value: &T) -> Self {
        self.body(<T as SkirType>::serializer().to_bytes(value))
    }
    fn reply_skir<T: SkirType>(self, value: &T) -> Self {
        self.reply(<T as SkirType>::serializer().to_bytes(value))
    }
}
