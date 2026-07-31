use std::{future::Future, time::Duration};

use anyhow::{Context, Result};
use component_test::{IncomingHttpClient, MessagingClient, MessagingExpectation};
use skir_client::{Serializer, UnrecognizedValues};

pub struct SkirHttpResponse<T> {
    pub status: reqwest::StatusCode,
    pub headers: reqwest::header::HeaderMap,
    pub body: T,
}

pub trait SkirHttpExt {
    fn skir_post<Req: Sync, Resp>(
        &self,
        path: &str,
        request: &Req,
        request_serializer: Serializer<Req>,
        response_serializer: Serializer<Resp>,
    ) -> impl Future<Output = Result<SkirHttpResponse<Resp>>> + Send;
    fn skir_request<Req: Sync, Resp>(
        &self,
        method: reqwest::Method,
        path: &str,
        request: &Req,
        request_serializer: Serializer<Req>,
        response_serializer: Serializer<Resp>,
        unrecognized: UnrecognizedValues,
    ) -> impl Future<Output = Result<SkirHttpResponse<Resp>>> + Send;
}

impl SkirHttpExt for IncomingHttpClient {
    async fn skir_post<Req: Sync, Resp>(
        &self,
        path: &str,
        request: &Req,
        request_serializer: Serializer<Req>,
        response_serializer: Serializer<Resp>,
    ) -> Result<SkirHttpResponse<Resp>> {
        self.skir_request(
            reqwest::Method::POST,
            path,
            request,
            request_serializer,
            response_serializer,
            UnrecognizedValues::Drop,
        )
        .await
    }

    async fn skir_request<Req: Sync, Resp>(
        &self,
        method: reqwest::Method,
        path: &str,
        request: &Req,
        request_serializer: Serializer<Req>,
        response_serializer: Serializer<Resp>,
        unrecognized: UnrecognizedValues,
    ) -> Result<SkirHttpResponse<Resp>> {
        let response = self
            .request(method, path)
            .header(reqwest::header::CONTENT_TYPE, "application/octet-stream")
            .header("x-typewriter-format", "skir-binary")
            .body(request_serializer.to_bytes(request))
            .send()
            .await?;
        let status = response.status();
        let headers = response.headers().clone();
        let bytes = response.bytes().await?;
        let body = response_serializer
            .from_bytes(&bytes, unrecognized)
            .context("decoding Skir HTTP response")?;
        Ok(SkirHttpResponse {
            status,
            headers,
            body,
        })
    }
}

pub trait SkirMessagingExt {
    fn publish_skir<T: Sync>(
        &self,
        subject: impl Into<String> + Send,
        value: &T,
        serializer: Serializer<T>,
    ) -> impl Future<Output = Result<()>> + Send;
    fn request_skir<Req: Sync, Resp>(
        &self,
        subject: impl Into<String> + Send,
        value: &Req,
        request_serializer: Serializer<Req>,
        response_serializer: Serializer<Resp>,
        timeout: Duration,
        unrecognized: UnrecognizedValues,
    ) -> impl Future<Output = Result<Resp>> + Send;
}

impl SkirMessagingExt for MessagingClient {
    async fn publish_skir<T: Sync>(
        &self,
        subject: impl Into<String> + Send,
        value: &T,
        serializer: Serializer<T>,
    ) -> Result<()> {
        self.publish(subject, serializer.to_bytes(value)).await
    }

    async fn request_skir<Req: Sync, Resp>(
        &self,
        subject: impl Into<String> + Send,
        value: &Req,
        request_serializer: Serializer<Req>,
        response_serializer: Serializer<Resp>,
        timeout: Duration,
        unrecognized: UnrecognizedValues,
    ) -> Result<Resp> {
        let bytes = self
            .request(subject, request_serializer.to_bytes(value), timeout)
            .await?;
        response_serializer
            .from_bytes(&bytes, unrecognized)
            .context("decoding Skir messaging response")
    }
}

pub trait SkirMessagingExpectationExt {
    fn body_skir<T>(self, value: &T, serializer: Serializer<T>) -> Self;
    fn reply_skir<T>(self, value: &T, serializer: Serializer<T>) -> Self;
}

impl SkirMessagingExpectationExt for MessagingExpectation {
    fn body_skir<T>(self, value: &T, serializer: Serializer<T>) -> Self {
        self.body(serializer.to_bytes(value))
    }
    fn reply_skir<T>(self, value: &T, serializer: Serializer<T>) -> Self {
        self.reply(serializer.to_bytes(value))
    }
}
