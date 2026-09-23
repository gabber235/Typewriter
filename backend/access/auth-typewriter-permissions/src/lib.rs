//! Typewriter's policy owner for NATS authentication.
//!
//! The auth callout sends validated external claims and an
//! `EntityPermissionQualifier` here through the Skir permission contract. This crate selects the
//! policy route, resolves the user's organization membership or the service's registration and
//! messaging scope, and returns NATS subject permissions plus identity tags. The callout then
//! signs those results into the NATS user claim.
//!
//! The callout owns token authenticity and the NATS signing keys. This crate owns authorization
//! policy and the database and service lookups required to derive it. Qualifiers are untrusted
//! routing context. A user organization is accepted only after membership verification, and a
//! service receives organization and Realm permissions only from authoritative service state.
//! Decode errors, unknown subjects, missing identities, lookup failures, and scope mismatches
//! propagate as failures. They never degrade into an empty or broader authorization grant.

wit_bindgen::generate!({
    with: {
        "wasmcloud:nats/jetstream@0.1.0": wasmcloud_utils::wasmcloud::messaging::jetstream,
        "wasmcloud:nats/core@0.1.0": wasmcloud_utils::wasmcloud::messaging::core,
        "wasmcloud:nats/core-handler@0.1.0": wasmcloud_utils::wasmcloud::messaging::core_handler,
    },
    generate_all,
});

use otel_wasi::{ResultWithSlug, main_attribute, wasi_error};
use wasmcloud_utils::{
    decode_skir,
    skir::base::access::v1::permission::{
        EntityPermissionQualifier, GetEntityPermissionRequest, GetEntityPermissionResponse,
        Permissions,
    },
    wasmcloud::messaging::{core_handler::Guest, reply, types},
};

mod common;
mod services;
mod users;

struct TypewriterPermissions;
wasmcloud_utils::export!(TypewriterPermissions);

const PANEL_SUBJECT: &str = "auth.permissions.typewriter-panel";
const SERVICES_SUBJECT: &str = "auth.permissions.typewriter-services";

impl Guest for TypewriterPermissions {
    #[otel_wasi::wasi_instrument(service = "auth-typewriter-permissions", export)]
    async fn handle_message(msg: types::NatsMessage) -> Result<(), otel_wasi::Error> {
        handle_message_async(msg).await
    }
}

/// Route one authenticated policy request and return its complete policy response.
///
/// Only the two configured policy subjects are valid. The response is serialized using the Skir
/// contract consumed by the auth callout, which preserves the ownership boundary between policy
/// calculation and NATS claim signing.
async fn handle_message_async(msg: types::NatsMessage) -> Result<(), otel_wasi::Error> {
    main_attribute!("messaging.destination.name" = msg.subject.clone());

    let request = match decode_skir!(GetEntityPermissionRequest, &msg.body) {
        Ok(req) => {
            main_attribute!("auth.request.decode.success" = true);
            req
        }
        Err(e) => {
            main_attribute!("auth.outcome" = "failed");
            return Err(e);
        }
    };
    let (permissions, tags) = match msg.subject.as_str() {
        PANEL_SUBJECT => handle_panel_subject(request).await,
        SERVICES_SUBJECT => handle_services_subject(request).await,
        other => Err(wasi_error!(
            "permissions-unknown-subject",
            "Unknown subject: {}",
            other
        )),
    }
    .inspect_err(|_| {
        main_attribute!("auth.outcome" = "failed");
    })?;

    let response = GetEntityPermissionResponse {
        permissions,
        tags,
        ..Default::default()
    };
    let body = GetEntityPermissionResponse::serializer().to_bytes(&response);
    main_attribute!(
        "auth.outcome" = "authorized",
        "auth.response.permissions.tags.count" = response.tags.len() as i64,
        "auth.permissions.publish.deny.count" = response.permissions.publish.deny.len() as i64,
        "auth.permissions.subscribe.deny.count" = response.permissions.subscribe.deny.len() as i64,
    );
    reply(msg, body).await
}

#[tracing::instrument(skip(request))]
/// Resolve policy for a panel identity after the callout has authenticated its JWT.
async fn handle_panel_subject(
    request: GetEntityPermissionRequest,
) -> Result<(Permissions, Vec<String>), otel_wasi::Error> {
    main_attribute!("auth.request.route" = "panel");
    let claims: jose::jwt::Claims<common::AuthentikClaims> =
        serde_json::from_slice(&request.jwt_claims)
            .error_with_slug("permissions-panel-claims-decode-failed")?;

    if let Some(ref issuer) = claims.issuer {
        main_attribute!("auth.jwt.issuer" = issuer.clone());
    }
    if let Some(exp) = claims.expiration {
        main_attribute!("auth.jwt.expires_at" = exp as i64);
    }

    let qualifier_type = match &request.qualifier {
        EntityPermissionQualifier::User(_) => "user",
        EntityPermissionQualifier::Service(_) => "service",
        EntityPermissionQualifier::Unknown(_) => "unknown",
    };
    main_attribute!("auth.request.qualifier_type" = qualifier_type);

    users::handle_panel_user(claims, request.qualifier).await
}

#[tracing::instrument(skip(request))]
/// Resolve policy for a service identity after the callout has authenticated its JWT.
async fn handle_services_subject(
    request: GetEntityPermissionRequest,
) -> Result<(Permissions, Vec<String>), otel_wasi::Error> {
    main_attribute!("auth.request.route" = "services");
    let claims: jose::jwt::Claims<services::ServiceClaims> =
        serde_json::from_slice(&request.jwt_claims)
            .error_with_slug("permissions-service-claims-decode-failed")?;

    if let Some(ref issuer) = claims.issuer {
        main_attribute!("auth.jwt.issuer" = issuer.clone());
    }
    if let Some(exp) = claims.expiration {
        main_attribute!("auth.jwt.expires_at" = exp as i64);
    }

    let qualifier_type = match &request.qualifier {
        EntityPermissionQualifier::User(_) => "user",
        EntityPermissionQualifier::Service(_) => "service",
        EntityPermissionQualifier::Unknown(_) => "unknown",
    };
    main_attribute!("auth.request.qualifier_type" = qualifier_type);

    services::handle_service(claims).await
}
