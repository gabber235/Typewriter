use crate::http_mock::{MockRegistry, MockRequest, MockResponse};
use bytes::Bytes;
use http_body_util::{BodyExt, Full};
use std::sync::Arc;
use wash_runtime::host::http::{OutgoingHandler, RequestIoFuture, SendFuture};
use wasmtime_wasi_http::{Error, RequestOptions, WasiBody};

#[derive(Clone)]
pub(crate) struct DispatchOutgoingHandler {
    registry: Arc<MockRegistry>,
}
impl DispatchOutgoingHandler {
    pub fn new(registry: Arc<MockRegistry>) -> Self {
        Self { registry }
    }
    async fn dispatch(
        &self,
        parts: http::request::Parts,
        body: Bytes,
    ) -> anyhow::Result<MockResponse> {
        let authority = parts
            .uri
            .authority()
            .map(|v| v.as_str())
            .ok_or_else(|| anyhow::anyhow!("outgoing request has no authority"))?;
        let mock = self
            .registry
            .find(authority)
            .ok_or_else(|| anyhow::anyhow!("no outgoing HTTP mock registered for `{authority}`"))?;
        mock.dispatch(MockRequest {
            method: parts.method,
            uri: parts.uri,
            headers: parts.headers,
            body,
        })
        .await
    }
}
impl OutgoingHandler for DispatchOutgoingHandler {
    fn send_request(
        &self,
        _: &str,
        request: hyper::Request<WasiBody>,
        _: Option<RequestOptions>,
        _: RequestIoFuture,
    ) -> SendFuture {
        let this = self.clone();
        Box::new(async move {
            let (parts, body) = buffered(request).await?;
            let response = this
                .dispatch(parts, body)
                .await
                .map_err(|error| Error::InternalError(Some(error.to_string())))?;
            if !response.delay.is_zero() {
                tokio::time::sleep(response.delay).await;
            }
            if let Some(failure) = response.failure {
                return Err(Error::InternalError(Some(failure)));
            }
            wasi_response(response.status, response.headers, response.body)
        })
    }
}

/// A component's outgoing request with its whole body read.
pub async fn buffered(
    request: hyper::Request<WasiBody>,
) -> Result<(http::request::Parts, Bytes), Error> {
    let (parts, body) = request.into_parts();
    Ok((parts, body.collect().await?.to_bytes()))
}

/// A complete response for a component's outgoing request, with nothing left to stream.
pub fn wasi_response(
    status: http::StatusCode,
    headers: http::HeaderMap,
    body: Bytes,
) -> Result<(hyper::Response<WasiBody>, RequestIoFuture), Error> {
    let mut result = hyper::Response::builder().status(status);
    *result
        .headers_mut()
        .ok_or_else(|| Error::InternalError(Some("response builder unavailable".into())))? =
        headers;
    let body: WasiBody = Full::new(body)
        .map_err(|never| match never {})
        .boxed_unsync();
    let response = result
        .body(body)
        .map_err(|error| Error::InternalError(Some(error.to_string())))?;
    let io: RequestIoFuture = Box::new(async { Ok(()) });
    Ok((response, io))
}
