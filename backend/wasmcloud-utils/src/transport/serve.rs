//! Serves one received message on the route its subject matched.
//!
//! The generated component dispatchers split a subject once, rebuild the route scope from its
//! tokens and hand the message to [`serve_request`] or [`serve_event`]. Messages are moved, never
//! cloned, from the dispatcher through decoding into the reply.

use std::time::Instant;

use otel_wasi::Error;

use super::frame::ReplyPacing;
use super::route::{EventRoute, RequestRoute, decode};
use crate::SkirResponse;
use crate::wasmcloud::messaging::{self, types::NatsMessage};

/// Decodes one matched request, runs its handler and replies with the typed response.
///
/// An invalid scope or an undecodable request skips the handler and is handled like a handler
/// error: the caller receives the response's internal_error variant and the error is returned.
/// Undecodable requests fail with `transport-decode`.
pub async fn serve_request<Route: RequestRoute>(
    msg: NatsMessage,
    scope: Result<Route::Scope, Error>,
    handler: impl AsyncFnOnce(Route::Scope, Route::Request) -> Result<Route::Response, Error>,
) -> Result<(), Error>
where
    Route::Response: SkirResponse,
{
    let pacing = ReplyPacing::of::<Route>(Instant::now());
    let result = handle::<Route>(&msg.body, scope, handler).await;
    messaging::reply_handler_result(msg, result, pacing).await
}

/// Decodes a matched request and runs its handler, skipping it on an invalid scope or request.
async fn handle<Route: RequestRoute>(
    body: &[u8],
    scope: Result<Route::Scope, Error>,
    handler: impl AsyncFnOnce(Route::Scope, Route::Request) -> Result<Route::Response, Error>,
) -> Result<Route::Response, Error> {
    let scope = scope?;
    let request = decode(&Route::method().request_serializer, body)?;
    handler(scope, request).await
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

    struct PermissionRoute;

    impl RequestRoute for PermissionRoute {
        const REPLY_CREDIT: bool = false;

        type Scope = ServiceScope;
        type Request = GetEntityPermissionRequest;
        type Response = GetEntityPermissionResponse;

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

    fn request_body() -> Vec<u8> {
        GetEntityPermissionRequest::serializer().to_bytes(&GetEntityPermissionRequest {
            jwt_claims: b"claims".to_vec(),
            ..Default::default()
        })
    }

    #[test]
    fn handle_passes_scope_and_request_to_the_handler() {
        let response = GetEntityPermissionResponse::Granted(Box::new(EntityPermissionGrant {
            tags: vec!["seen".to_owned()],
            ..Default::default()
        }));
        let handled = block_on(handle::<PermissionRoute>(
            &request_body(),
            ServiceScope::from_tokens("s1"),
            async |scope: ServiceScope, request: GetEntityPermissionRequest| {
                assert_eq!(scope.service, SubjectToken::try_from("s1").unwrap());
                assert_eq!(request.jwt_claims, b"claims");
                Ok(response.clone())
            },
        ))
        .unwrap();
        assert_eq!(handled, response);
    }

    #[test]
    fn handle_skips_the_handler_on_scope_and_decode_failures() {
        let invalid_scope = block_on(handle::<PermissionRoute>(
            &request_body(),
            ServiceScope::from_tokens("*"),
            async |_, _| -> Result<GetEntityPermissionResponse, Error> {
                unreachable!("an invalid scope never reaches the handler")
            },
        ))
        .unwrap_err();
        assert_eq!(invalid_scope.slug(), "transport-invalid-token");

        let undecodable = block_on(handle::<PermissionRoute>(
            b"not skir",
            ServiceScope::from_tokens("s1"),
            async |_, _| -> Result<GetEntityPermissionResponse, Error> {
                unreachable!("an undecodable request never reaches the handler")
            },
        ))
        .unwrap_err();
        assert_eq!(undecodable.slug(), "transport-decode");
    }

    #[test]
    fn a_failed_request_falls_back_to_the_internal_error_variant() {
        let fallback = GetEntityPermissionResponse::internal_error();
        assert!(matches!(
            fallback,
            GetEntityPermissionResponse::InternalError(_)
        ));
        assert_eq!(fallback.variant_slug(), "internal-error");
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
