wit_bindgen::generate!({
    with: {
        "wasmcloud:messaging/consumer@0.2.0": wasmcloud_utils::wasmcloud::messaging::consumer,
        "wasmcloud:messaging/handler@0.2.0": wasmcloud_utils::wasmcloud::messaging::handler,
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
    wasmcloud::messaging::{handler::Guest, reply, types},
};

mod common;
mod services;
mod users;

struct TypewriterPermissions;
wasmcloud_utils::export!(TypewriterPermissions);

const PANEL_SUBJECT: &str = "auth.permissions.typewriter-panel";
const SERVICES_SUBJECT: &str = "auth.permissions.typewriter-services";

impl Guest for TypewriterPermissions {
    #[otel_wasi::wasi_instrument(service = "auth_typewriter_permissions", export)]
    async fn handle_message(msg: types::BrokerMessage) -> Result<(), otel_wasi::Error> {
        handle_message_async(msg).await
    }
}

async fn handle_message_async(msg: types::BrokerMessage) -> Result<(), otel_wasi::Error> {
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
    .map_err(|e| {
        main_attribute!("auth.outcome" = "failed");
        e
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
