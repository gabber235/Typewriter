use crate::http_mock::{MockRegistry, MockRequest, MockResponse};
use bytes::Bytes;
use http_body_util::{BodyExt, Full};
use std::{sync::Arc, time::Duration};
use wash_runtime::host::{
    http::OutgoingHandler,
    http_p3::{P3Body, P3RequestErrorFuture, P3SendFuture},
};
use wasmtime_wasi_http::p2::{
    HttpResult,
    body::{HyperIncomingBody, HyperOutgoingBody},
    types::{HostFutureIncomingResponse, IncomingResponse, OutgoingRequestConfig},
};

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
        request: hyper::Request<HyperOutgoingBody>,
        _: OutgoingRequestConfig,
    ) -> HttpResult<HostFutureIncomingResponse> {
        let this = self.clone();
        let handle = wasmtime_wasi::runtime::spawn(async move {
            let result = async move {
                let (parts, body) = request.into_parts();
                let body = body
                    .collect()
                    .await
                    .map_err(|e| {
                        wasmtime_wasi_http::p2::bindings::http::types::ErrorCode::InternalError(
                            Some(e.to_string()),
                        )
                    })?
                    .to_bytes();
                let response = this.dispatch(parts, body).await.map_err(|e| {
                    wasmtime_wasi_http::p2::bindings::http::types::ErrorCode::InternalError(Some(
                        e.to_string(),
                    ))
                })?;
                if !response.delay.is_zero() {
                    tokio::time::sleep(response.delay).await;
                }
                if let Some(failure) = response.failure {
                    return Err(
                        wasmtime_wasi_http::p2::bindings::http::types::ErrorCode::InternalError(
                            Some(failure),
                        ),
                    );
                }
                let mut result = hyper::Response::builder().status(response.status);
                *result.headers_mut().ok_or_else(|| {
                    wasmtime_wasi_http::p2::bindings::http::types::ErrorCode::InternalError(Some(
                        "response builder unavailable".into(),
                    ))
                })? = response.headers;
                let body: HyperIncomingBody = Full::new(response.body)
                    .map_err(|never| match never {})
                    .boxed_unsync();
                let resp = result.body(body).map_err(|e| {
                    wasmtime_wasi_http::p2::bindings::http::types::ErrorCode::InternalError(Some(
                        e.to_string(),
                    ))
                })?;
                Ok(IncomingResponse {
                    resp,
                    worker: None,
                    between_bytes_timeout: Duration::from_secs(30),
                })
            }
            .await;
            Ok::<_, wash_runtime::wasmtime::Error>(result)
        });
        Ok(HostFutureIncomingResponse::pending(handle))
    }
    fn send_request_p3(
        &self,
        _: &str,
        request: hyper::Request<P3Body>,
        _: Option<wasmtime_wasi_http::p3::RequestOptions>,
        _: P3RequestErrorFuture,
    ) -> P3SendFuture {
        let this = self.clone();
        Box::new(async move {
            let (parts, body) = request.into_parts();
            let response = this
                .dispatch(
                    parts,
                    body.collect()
                        .await
                        .map_err(wasmtime_wasi::TrappableError::trap)?
                        .to_bytes(),
                )
                .await
                .map_err(|e| {
                    wasmtime_wasi::TrappableError::trap(wash_runtime::wasmtime::Error::msg(
                        e.to_string(),
                    ))
                })?;
            if !response.delay.is_zero() {
                tokio::time::sleep(response.delay).await;
            }
            if let Some(failure) = response.failure {
                return Err(wasmtime_wasi::TrappableError::trap(
                    wash_runtime::wasmtime::Error::msg(failure),
                ));
            }
            let mut result = hyper::Response::builder().status(response.status);
            if let Some(headers) = result.headers_mut() {
                *headers = response.headers;
            }
            let body: P3Body = Full::new(response.body)
                .map_err(|never| match never {})
                .boxed_unsync();
            let resp = result.body(body).map_err(|e| {
                wasmtime_wasi::TrappableError::trap(wash_runtime::wasmtime::Error::msg(
                    e.to_string(),
                ))
            })?;
            let io: P3RequestErrorFuture = Box::new(async { Ok(()) });
            Ok((resp, io))
        })
    }
}
