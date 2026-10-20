//! How a served request's handler result reaches its caller.
//!
//! TODO: the generated-outcomes decision gives every response a generated `SkirResponse`, which
//! leaves [`DomainResponseDelivery`] as the only delivery and removes [`PlainResponseDelivery`]
//! and the [`ResponseDelivery`] trait.

use std::future::Future;

use otel_wasi::Error;

use crate::skir_client::Serializer;
use crate::wasmcloud::messaging::{self, types::NatsMessage};

/// Replies to one served request with its handler result.
///
/// Each generated request route chooses the delivery that fits its response type.
pub trait ResponseDelivery<Response> {
    /// Replies on the request's reply subject and returns the handler error, if any, once the
    /// reply was handled.
    fn reply(
        msg: NatsMessage,
        result: Result<Response, Error>,
        serializer: &Serializer<Response>,
    ) -> impl Future<Output = Result<(), Error>>;
}

/// Delivery for Skir enum responses with typed success, domain error and internal error variants.
///
/// A handler error replies with the response's internal error variant before it is returned, so
/// the caller always receives a typed outcome.
pub struct DomainResponseDelivery;

impl<Response: crate::SkirResponse> ResponseDelivery<Response> for DomainResponseDelivery {
    async fn reply(
        msg: NatsMessage,
        result: Result<Response, Error>,
        _serializer: &Serializer<Response>,
    ) -> Result<(), Error> {
        messaging::reply_handler_result(msg, result).await
    }
}

/// Delivery for Skir struct responses, which have no error variant.
///
/// A handler error sends no reply, so the caller's request times out, and is returned.
pub struct PlainResponseDelivery;

impl<Response: 'static> ResponseDelivery<Response> for PlainResponseDelivery {
    async fn reply(
        msg: NatsMessage,
        result: Result<Response, Error>,
        serializer: &Serializer<Response>,
    ) -> Result<(), Error> {
        let response = result?;
        messaging::reply(msg, serializer.to_bytes(&response)).await
    }
}
