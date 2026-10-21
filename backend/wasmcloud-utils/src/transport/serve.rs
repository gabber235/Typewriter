//! Serves one received message on the route its subject matched.
//!
//! The generated component dispatchers split a subject once, rebuild the route scope from its
//! tokens and hand the message to [`serve_request`] or [`serve_event`]. Messages are moved, never
//! cloned, from the dispatcher through decoding into the reply.

use otel_wasi::Error;

use super::delivery::ResponseDelivery;
use super::route::{EventRoute, RequestRoute, decode};
use crate::wasmcloud::messaging::types::NatsMessage;

/// Decodes one matched request, runs its handler and replies with the handler result.
///
/// An invalid scope or an undecodable request skips the handler and is delivered like a handler
/// error, so the route's [`ResponseDelivery`] decides what the caller receives. Undecodable
/// requests fail with `transport-decode`.
pub async fn serve_request<Route: RequestRoute>(
    msg: NatsMessage,
    scope: Result<Route::Scope, Error>,
    handler: impl AsyncFnOnce(Route::Scope, Route::Request) -> Result<Route::Response, Error>,
) -> Result<(), Error> {
    let method = Route::method();
    let result = async {
        let scope = scope?;
        let request = decode(&method.request_serializer, &msg.body)?;
        handler(scope, request).await
    }
    .await;
    Route::Delivery::reply(msg, result, &method.response_serializer).await
}

/// Decodes one matched event and runs its handler; events have no reply.
///
/// An invalid scope or an undecodable event skips the handler and is returned, the latter as
/// `transport-decode`.
pub async fn serve_event<Route: EventRoute>(
    msg: NatsMessage,
    scope: Result<Route::Scope, Error>,
    handler: impl AsyncFnOnce(Route::Scope, Route::Event) -> Result<(), Error>,
) -> Result<(), Error> {
    let scope = scope?;
    let event = decode(&Route::serializer(), &msg.body)?;
    handler(scope, event).await
}

/// The error of a message whose subject matches none of the component's routes.
///
/// Subscriptions are generated from the same routes as the dispatcher, so this only happens when
/// a deployment drifted from the generated subscriptions.
pub fn unmatched(msg: &NatsMessage) -> Error {
    Error::new(
        "transport-unmatched-subject",
        format!("Unknown subject: {}", msg.subject),
    )
}

#[cfg(test)]
mod tests {
    use std::cell::RefCell;

    use otel_wasi::WasiError as _;

    use super::*;
    use crate::skir_client::{Method, Serializer};
    use crate::skirout::base::access::v1::permission::{
        EntityPermissionGrant, GetEntityPermissionRequest, GetEntityPermissionResponse,
        get_entity_permission_method,
    };
    use crate::skirout::base::service::v1::lifecycle::ServiceHeartbeatNotification;
    use crate::transport::test_support::{block_on, nats_message};
    use crate::transport::{ServiceScope, SubjectToken};

    thread_local! {
        /// The serialized response or error slug of every reply the recording delivery saw.
        static REPLIES: RefCell<Vec<Result<Vec<u8>, &'static str>>> = const { RefCell::new(Vec::new()) };
    }

    /// Records replies instead of publishing them.
    struct RecordingDelivery;

    impl<Response> ResponseDelivery<Response> for RecordingDelivery {
        async fn reply(
            _msg: NatsMessage,
            result: Result<Response, Error>,
            serializer: &Serializer<Response>,
        ) -> Result<(), Error> {
            let reply = match &result {
                Ok(response) => Ok(serializer.to_bytes(response)),
                Err(error) => Err(error.slug()),
            };
            REPLIES.with_borrow_mut(|replies| replies.push(reply));
            result.map(|_| ())
        }
    }

    struct PermissionRoute;

    impl RequestRoute for PermissionRoute {
        type Scope = ServiceScope;
        type Request = GetEntityPermissionRequest;
        type Response = GetEntityPermissionResponse;
        type Delivery = RecordingDelivery;

        fn method() -> &'static Method<Self::Request, Self::Response> {
            get_entity_permission_method()
        }
    }

    struct HeartbeatRoute;

    impl EventRoute for HeartbeatRoute {
        type Scope = ServiceScope;
        type Event = ServiceHeartbeatNotification;

        fn serializer() -> Serializer<Self::Event> {
            ServiceHeartbeatNotification::serializer()
        }
    }

    fn take_replies() -> Vec<Result<Vec<u8>, &'static str>> {
        REPLIES.with_borrow_mut(std::mem::take)
    }

    fn request_body() -> Vec<u8> {
        GetEntityPermissionRequest::serializer().to_bytes(&GetEntityPermissionRequest {
            jwt_claims: b"claims".to_vec(),
            ..Default::default()
        })
    }

    #[test]
    fn serve_request_hands_scope_and_request_to_the_handler_and_replies() {
        let msg = nats_message("auth.permissions.test", &request_body());
        let response = GetEntityPermissionResponse::Granted(Box::new(EntityPermissionGrant {
            tags: vec!["seen".to_owned()],
            ..Default::default()
        }));
        let expected = GetEntityPermissionResponse::serializer().to_bytes(&response);
        block_on(serve_request::<PermissionRoute>(
            msg,
            ServiceScope::from_tokens("s1"),
            async |scope: ServiceScope, request: GetEntityPermissionRequest| {
                assert_eq!(scope.service, SubjectToken::try_from("s1").unwrap());
                assert_eq!(request.jwt_claims, b"claims");
                Ok(response)
            },
        ))
        .unwrap();
        assert_eq!(take_replies(), vec![Ok(expected)]);
    }

    #[test]
    fn serve_request_delivers_scope_and_decode_failures_without_running_the_handler() {
        let invalid_scope = block_on(serve_request::<PermissionRoute>(
            nats_message("auth.permissions.test", &request_body()),
            ServiceScope::from_tokens("*"),
            async |_, _| -> Result<GetEntityPermissionResponse, Error> {
                unreachable!("an invalid scope never reaches the handler")
            },
        ))
        .unwrap_err();
        assert_eq!(invalid_scope.slug(), "transport-invalid-token");

        let undecodable = block_on(serve_request::<PermissionRoute>(
            nats_message("auth.permissions.test", b"not skir"),
            ServiceScope::from_tokens("s1"),
            async |_, _| -> Result<GetEntityPermissionResponse, Error> {
                unreachable!("an undecodable request never reaches the handler")
            },
        ))
        .unwrap_err();
        assert_eq!(undecodable.slug(), "transport-decode");
        assert_eq!(
            take_replies(),
            vec![Err("transport-invalid-token"), Err("transport-decode")]
        );
    }

    #[test]
    fn serve_event_hands_scope_and_event_to_the_handler() {
        let body = ServiceHeartbeatNotification::serializer()
            .to_bytes(&ServiceHeartbeatNotification::default());
        let mut seen = None;
        block_on(serve_event::<HeartbeatRoute>(
            nats_message("typewriter.from.service.s1.heartbeat", &body),
            ServiceScope::from_tokens("s1"),
            async |scope: ServiceScope, _| {
                seen = Some(scope.service);
                Ok(())
            },
        ))
        .unwrap();
        assert_eq!(seen, Some(SubjectToken::try_from("s1").unwrap()));

        let undecodable = block_on(serve_event::<HeartbeatRoute>(
            nats_message("typewriter.from.service.s1.heartbeat", b"not skir"),
            ServiceScope::from_tokens("s1"),
            async |_, _| unreachable!("an undecodable event never reaches the handler"),
        ))
        .unwrap_err();
        assert_eq!(undecodable.slug(), "transport-decode");
    }

    #[test]
    fn unmatched_names_the_subject() {
        let error = unmatched(&nats_message("typewriter.from.nowhere", &[]));
        assert_eq!(error.slug(), "transport-unmatched-subject");
        assert_eq!(error.message(), "Unknown subject: typewriter.from.nowhere");
    }
}
