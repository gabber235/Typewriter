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

use otel_wasi::{ResultWithSlug, main_attribute};
use wasmcloud_utils::{
    skir::base::access::v1::permission::{
        EntityPermissionGrant, EntityPermissionQualifier, GetEntityPermissionRequest,
        GetEntityPermissionResponse, Permissions,
    },
    transport_routes::auth_typewriter_permissions::{Handlers, dispatch},
    wasmcloud::messaging::{core_handler::Guest, types},
};

mod common;
mod services;
mod users;

#[cfg(test)]
mod response_permission_test;

struct TypewriterPermissions;
wasmcloud_utils::export!(TypewriterPermissions);

impl Guest for TypewriterPermissions {
    /// Route one authenticated policy request and return its complete policy response.
    ///
    /// Only the two policy subjects are valid. The response is serialized using the Skir
    /// contract consumed by the auth callout, which preserves the ownership boundary between
    /// policy calculation and NATS claim signing.
    #[otel_wasi::wasi_instrument(service = "auth-typewriter-permissions", export)]
    async fn handle_message(msg: types::NatsMessage) -> Result<(), otel_wasi::Error> {
        dispatch(
            msg,
            Handlers {
                panel_permission_resolve: async |_, request| {
                    permission_response(handle_panel_subject(request).await)
                },
                services_permission_resolve: async |_, request| {
                    permission_response(handle_services_subject(request).await)
                },
            },
        )
        .await
    }
}

fn permission_response(
    result: Result<(Permissions, Vec<String>), otel_wasi::Error>,
) -> Result<GetEntityPermissionResponse, otel_wasi::Error> {
    let (permissions, tags) = result.inspect_err(|_| {
        main_attribute!("auth.outcome" = "failed");
    })?;
    let grant = EntityPermissionGrant {
        permissions,
        tags,
        ..Default::default()
    };
    main_attribute!(
        "auth.outcome" = "authorized",
        "auth.response.permissions.tags.count" = grant.tags.len() as i64,
        "auth.permissions.publish.deny.count" = grant.permissions.publish.deny.len() as i64,
        "auth.permissions.subscribe.deny.count" = grant.permissions.subscribe.deny.len() as i64,
    );
    Ok(GetEntityPermissionResponse::Granted(Box::new(grant)))
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
