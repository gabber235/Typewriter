//! Route contracts the generated transport routes implement, and the outbound operations on them.
//!
//! The generated module declares one type per manifest route and implements these traits for it.
//! Inbound routes are served by the generated component dispatchers; outbound routes are used
//! directly by components through [`request_route`] and [`EventDelivery`].

use std::marker::PhantomData;

use otel_wasi::Error;

use crate::skir_client::{Method, Serializer, UnrecognizedValues};
use crate::wasmcloud::messaging;

/// A Skir request route between backend components or from a role to a component.
///
/// Every response implements the generated [`crate::SkirResponse`], so a served route replies
/// with its typed outcome and falls back to the response's internal_error variant.
pub trait RequestRoute {
    /// The identities the request subject captures.
    type Scope;
    type Request: 'static;
    type Response: 'static;

    fn method() -> &'static Method<Self::Request, Self::Response>;
}

/// A request route that a backend component calls on another component.
pub trait OutboundRequestRoute: RequestRoute {
    /// The subject the caller publishes the request to.
    fn subject(scope: &Self::Scope) -> String;
}

/// A Skir event route that a backend component subscribes to.
pub trait EventRoute {
    /// The identities the event subject captures.
    type Scope;
    type Event: 'static;

    fn serializer() -> Serializer<Self::Event>;
}

/// An event a backend component publishes, such as the updates of a watch route.
pub trait OutboundEventRoute {
    /// The identities the event subject renders.
    type Scope;
    type Event: 'static;

    fn serializer() -> Serializer<Self::Event>;
    fn subject(scope: &Self::Scope) -> String;
}

/// An outbound event persisted through JetStream into one stream.
pub trait PersistentEventRoute: OutboundEventRoute {
    /// The stream the event subject must land in.
    fn stream() -> &'static str;
}

/// An outbound event published on core NATS without persistence.
pub trait TransientEventRoute: OutboundEventRoute {}

/// The rendered subject of one outbound event route, ready to publish or persist events on.
pub struct EventDelivery<Route: OutboundEventRoute> {
    subject: String,
    route: PhantomData<Route>,
}

impl<Route: OutboundEventRoute> EventDelivery<Route> {
    /// Renders the route subject for `scope`.
    pub fn new(scope: &Route::Scope) -> Self {
        Self {
            subject: Route::subject(scope),
            route: PhantomData,
        }
    }

    pub fn subject(&self) -> &str {
        &self.subject
    }
}

impl<Route: TransientEventRoute> EventDelivery<Route> {
    /// Publishes one event on core NATS.
    pub async fn publish(&self, event: Route::Event) -> Result<(), Error> {
        messaging::publish(self.subject.clone(), Route::serializer().to_bytes(&event)).await
    }
}

impl<Route: PersistentEventRoute> EventDelivery<Route> {
    /// Persists one event and fails with `transport-event-wrong-stream` when JetStream stored it
    /// in a stream other than the route's.
    pub async fn persist(&self, event: Route::Event) -> Result<(), Error> {
        let acknowledgement =
            messaging::persist(self.subject.clone(), Route::serializer().to_bytes(&event)).await?;
        if acknowledgement.stream_name != Route::stream() {
            return Err(Error::new(
                "transport-event-wrong-stream",
                format!(
                    "expected {}, got {}",
                    Route::stream(),
                    acknowledgement.stream_name
                ),
            ));
        }
        Ok(())
    }
}

/// Sends one request to the component serving the route and decodes its reply.
///
/// Broker failures surface as `message-request-failed`, undecodable replies as
/// `transport-decode`.
pub async fn request_route<Route: OutboundRequestRoute>(
    scope: &Route::Scope,
    request: &Route::Request,
) -> Result<Route::Response, Error> {
    let method = Route::method();
    let response = messaging::request(
        Route::subject(scope),
        method.request_serializer.to_bytes(request),
    )
    .await?;
    decode(&method.response_serializer, &response.body)
}

/// Decodes a Skir payload, dropping values this component does not know.
pub(super) fn decode<T>(serializer: &Serializer<T>, body: &[u8]) -> Result<T, Error> {
    serializer
        .from_bytes(body, UnrecognizedValues::Drop)
        .map_err(|error| Error::new("transport-decode", error.to_string()))
}
