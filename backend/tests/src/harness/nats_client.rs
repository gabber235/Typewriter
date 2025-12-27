//! NATS client wrapper for sending test messages.
//!
//! Provides a convenient API for sending protobuf-encoded requests
//! and receiving protobuf-encoded responses over NATS.

use std::time::Duration;

use anyhow::{Context, Result};
use prost::Message;

/// NATS client for sending test requests.
pub struct TestNatsClient<'a> {
    client: &'a async_nats::Client,
}

impl<'a> TestNatsClient<'a> {
    /// Create a new test NATS client.
    pub fn new(client: &'a async_nats::Client) -> Self {
        Self { client }
    }

    /// Send a protobuf request and wait for a protobuf response.
    ///
    /// # Arguments
    /// * `subject` - The NATS subject to send to
    /// * `request` - The protobuf request message
    ///
    /// # Returns
    /// The decoded protobuf response message
    pub async fn request<Req, Res>(&self, subject: &str, request: &Req) -> Result<Res>
    where
        Req: Message,
        Res: Message + Default,
    {
        self.request_with_timeout(subject, request, Duration::from_secs(5))
            .await
    }

    /// Send a protobuf request with a custom timeout.
    pub async fn request_with_timeout<Req, Res>(
        &self,
        subject: &str,
        request: &Req,
        timeout: Duration,
    ) -> Result<Res>
    where
        Req: Message,
        Res: Message + Default,
    {
        tracing::debug!(subject = %subject, "Sending NATS request");

        // Encode request to protobuf bytes
        let body = request.encode_to_vec();

        // Send request and wait for response
        let response = tokio::time::timeout(
            timeout,
            self.client.request(subject.to_string(), body.into()),
        )
        .await
        .context("Request timed out")?
        .context("Failed to send NATS request")?;

        tracing::debug!(
            subject = %subject,
            response_len = response.payload.len(),
            "Received NATS response"
        );

        // Decode response from protobuf bytes
        let result = Res::decode(response.payload.as_ref())
            .context("Failed to decode protobuf response")?;

        Ok(result)
    }

    /// Send a request without expecting a response (fire-and-forget).
    pub async fn publish<Req>(&self, subject: &str, request: &Req) -> Result<()>
    where
        Req: Message,
    {
        tracing::debug!(subject = %subject, "Publishing NATS message");

        let body = request.encode_to_vec();
        self.client
            .publish(subject.to_string(), body.into())
            .await
            .context("Failed to publish NATS message")?;

        Ok(())
    }
}
