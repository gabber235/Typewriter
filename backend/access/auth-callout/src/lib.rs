wit_bindgen::generate!({
    with: {
        "wasmcloud:messaging/consumer@0.2.0": wasmcloud_utils::wasmcloud::messaging::consumer,
        "wasmcloud:messaging/handler@0.2.0": wasmcloud_utils::wasmcloud::messaging::handler,
    },
    generate_all,
});

use std::collections::HashMap;

use anyhow::{Result, anyhow};
use base64::Engine;
use config::IssuerConfig;
use jose::UntypedAdditionalProperties;
use nats_jwt_rs::{
    Claim, Claims,
    authorization::{AuthRequest, AuthResponse, ClientInfo, ConnectOpts, ServerID},
    types::{GenericFields, Permissions as NatsPermissions},
    user::User,
};
use nkeys::KeyPair;
use otel_wasi::{attribute, main_attribute};
use serde::{Deserialize, Serialize};
use wasmcloud_utils::{
    skir::base::access::v1::permission::{
        EntityPermissionQualifier, GetEntityPermissionRequest, GetEntityPermissionResponse,
        Permissions,
    },
    skir_client::UnrecognizedValues::{self, Drop},
    wasmcloud::messaging::{consumer, handler::Guest, reply, types},
};

pub mod config;
pub mod jwt;

struct AuthCallout;
wasmcloud_utils::export!(AuthCallout);

const PERMISSIONS_REQUEST_TIMEOUT_MS: u32 = 1000;
const EXPECTED_AUDIENCE: &str = "nats-authorization-request";

pub(crate) fn record_error(slug: &'static str, message: &str) {
    main_attribute!(
        "error" = true,
        "exception.slug" = slug,
        "exception.message" = message.to_string(),
    );
}

impl Guest for AuthCallout {
    #[otel_wasi::wasi_instrument(service = "auth_callout")]
    fn handle_message(msg: types::BrokerMessage) -> Result<(), String> {
        main_attribute!(
            "messaging.destination.name" = msg.subject.clone(),
            "messaging.message.body.size" = msg.body.len() as i64,
            "messaging.reply_to.present" = msg.reply_to.is_some(),
        );

        let keypair = match get_nats_issuer_keypair() {
            Ok(kp) => {
                main_attribute!("auth.nats_issuer_keypair.loaded" = true);
                kp
            }
            Err(e) => {
                record_error("auth-callout-keypair-load-failed", &e);
                return Err(e);
            }
        };

        let request = match decode_auth_request(&msg.body) {
            Ok(req) => {
                main_attribute!(
                    "auth.request.decode.success" = true,
                    "auth.request.user_nkey" = req.payload().user_nkey.clone(),
                    "auth.request.server.id" = req.payload().server.id.clone(),
                    "auth.request.issuer" = req.iss.clone(),
                    "auth.request.connect.user.present" = req.payload().connect_opts.user.is_some(),
                    "auth.request.qualifier.present" = req.payload().connect_opts.nkey.is_some(),
                );
                if let Some(audience) = &req.aud {
                    main_attribute!("auth.request.audience" = audience.clone());
                }
                req
            }
            Err(e) => {
                main_attribute!("auth.request.decode.success" = false);
                record_error("auth-callout-request-decode-failed", &e.to_string());
                return Err(e.to_string());
            }
        };

        let user_nkey = request.payload().user_nkey.clone();
        let server_id = request.payload().server.id.clone();

        let mut response = create_auth_response(user_nkey.clone(), server_id.clone());
        main_attribute!(
            "auth.response.created" = true,
            "auth.response.user_nkey" = user_nkey,
            "auth.response.server.id" = server_id,
        );

        match process_user_jwt(&request) {
            Ok(Some(jwt)) => {
                main_attribute!(
                    "auth.outcome" = "authorized",
                    "auth.response.jwt.present" = true,
                );
                response.payload_mut().jwt = jwt;
            }
            Ok(None) => {
                main_attribute!(
                    "auth.outcome" = "denied",
                    "auth.response.jwt.present" = false,
                    "auth.response.error" = "user not authorized",
                );
                response.payload_mut().error = "user not authorized".to_string();
            }
            Err(e) => {
                main_attribute!("auth.outcome" = "failed");
                record_error("auth-callout-jwt-processing-failed", &e.to_string());
                return Err(e.to_string());
            }
        };

        let data = match response.encode(&keypair) {
            Ok(data) => data,
            Err(e) => {
                main_attribute!("auth.outcome" = "failed");
                record_error("auth-callout-response-encode-failed", &e.to_string());
                return Err(e.to_string());
            }
        };
        main_attribute!("auth.response.encoded.size" = data.len() as i64);

        if let Err(e) = reply(msg, data) {
            main_attribute!("auth.outcome" = "failed");
            record_error("auth-callout-reply-failed", &e);
            return Err(e);
        }
        main_attribute!("auth.reply.sent" = true);
        Ok(())
    }
}

#[tracing::instrument]
fn get_nats_issuer_keypair() -> Result<KeyPair, String> {
    let seed = std::env::var("NATS_ISSUER_SEED")
        .map_err(|_| "NATS_ISSUER_SEED not found in environment".to_string())?;

    KeyPair::from_seed(&seed).map_err(|e| e.to_string())
}

#[tracing::instrument]
fn create_auth_response(user_nkey: String, server_id: String) -> Claims<AuthResponse> {
    let mut response = AuthResponse::generic_claim(user_nkey);
    response.aud = Some(server_id);
    response
}

#[tracing::instrument]
fn process_user_jwt(request: &Claims<AuthRequest>) -> Result<Option<String>, anyhow::Error> {
    let Some(raw_jwt) = request.payload().connect_opts.pass.clone() else {
        main_attribute!("auth.jwt.present" = false, "auth.outcome" = "denied",);
        return Ok(None);
    };
    main_attribute!(
        "auth.jwt.present" = true,
        "auth.jwt.raw.size" = raw_jwt.len() as i64,
    );

    let configs = load_issuer_configs()?;
    main_attribute!("auth.issuer_config.count" = configs.len() as i64);

    let (jwt, issuer) = match validate_user_jwt(&raw_jwt, &configs, request) {
        Ok(result) => {
            main_attribute!(
                "auth.jwt.validation.success" = true,
                "auth.jwt.issuer_config.id" = result.1.id.clone(),
            );
            result
        }
        Err(e) => {
            main_attribute!(
                "auth.jwt.validation.success" = false,
                "auth.outcome" = "denied",
            );
            record_error("auth-callout-jwt-validation-failed", &e.to_string());
            return Ok(None);
        }
    };

    let keypair = get_signing_keypair(&issuer.id)?;
    main_attribute!(
        "auth.signing_keypair.loaded" = true,
        "auth.signing_keypair.issuer_id" = issuer.id.clone(),
    );

    let Some(qualifier) = request.payload().connect_opts.nkey.clone() else {
        return Err(anyhow::anyhow!(
            "connect_opts.nkey is required, missing entity permission qualifier"
        ));
    };

    let qualifier = base64::engine::general_purpose::STANDARD
        .decode(&qualifier)
        .map_err(|e| anyhow::anyhow!("failed to decode entity permission qualifier: {}", e))?;

    let qualifier = EntityPermissionQualifier::serializer().from_bytes(&qualifier, Drop)?;

    let claims = create_user_claims(&jwt, &request.payload().user_nkey, &issuer, qualifier)?;
    main_attribute!("auth.user_claims.created" = true);

    let encoded = claims.encode(&keypair).map_err(|e| {
        record_error("auth-callout-user-claims-failed", &e.to_string());
        e
    })?;
    main_attribute!("auth.response.jwt.size" = encoded.len() as i64);

    Ok(Some(encoded))
}

#[tracing::instrument]
fn load_issuer_configs() -> Result<Vec<IssuerConfig>> {
    let config_str = std::env::var("ISSUERS").map_err(|_| {
        record_error(
            "auth-callout-issuer-config-load-failed",
            "ISSUERS not found in environment",
        );
        anyhow!("ISSUERS not found in environment")
    })?;

    let configs: Vec<IssuerConfig> = serde_json::from_str(&config_str).map_err(|e| {
        record_error("auth-callout-issuer-config-load-failed", &e.to_string());
        anyhow!("Failed to parse auth config: {}", e)
    })?;
    attribute!("auth.issuer_config.count" = configs.len() as i64);
    main_attribute!("auth.issuer_config.count" = configs.len() as i64);
    Ok(configs)
}

#[tracing::instrument]
fn validate_user_jwt<'a>(
    raw_jwt: &str,
    configs: &'a Vec<IssuerConfig>,
    request: &Claims<AuthRequest>,
) -> Result<(
    jose::jwt::Claims<UntypedAdditionalProperties>,
    &'a IssuerConfig,
)> {
    attribute!(
        "auth.jwt.raw.size" = raw_jwt.len() as i64,
        "auth.jwt.issuer_config.candidate.count" = configs.len() as i64,
    );
    match jwt::validate_jwt(raw_jwt, configs) {
        Ok(result) => Ok(result),
        Err(e) => {
            let username = request
                .payload()
                .connect_opts
                .user
                .clone()
                .unwrap_or_else(|| "Unknown".to_string());
            main_attribute!(
                "auth.jwt.validation.success" = false,
                "auth.request.connect.user" = username.clone(),
            );
            Err(anyhow!("Invalid JWT for {}: {}", username, e))
        }
    }
}

#[tracing::instrument]
fn get_signing_keypair(issuer_id: &str) -> Result<KeyPair> {
    let signing_keys_json = std::env::var("NATS_SIGNING_KEYS").map_err(|_| {
        record_error(
            "auth-callout-signing-keypair-failed",
            "NATS_SIGNING_KEYS not found in environment",
        );
        anyhow!("NATS_SIGNING_KEYS not found in environment")
    })?;

    let signing_keys: HashMap<String, String> =
        serde_json::from_str(&signing_keys_json).map_err(|e| {
            record_error("auth-callout-signing-keypair-failed", &e.to_string());
            e
        })?;
    attribute!("auth.signing_keypair.config.count" = signing_keys.len() as i64);

    let seed = signing_keys.get(issuer_id).ok_or_else(|| {
        let message = format!("No seed found for issuer {}", issuer_id);
        record_error("auth-callout-signing-keypair-failed", &message);
        anyhow!(message)
    })?;

    KeyPair::from_seed(seed).map_err(|e| {
        record_error("auth-callout-signing-keypair-failed", &e.to_string());
        anyhow!("Failed to create keypair: {}", e)
    })
}

#[tracing::instrument(skip(jwt, qualifier))]
fn create_user_claims(
    jwt: &jose::jwt::Claims<UntypedAdditionalProperties>,
    user_nkey: &str,
    issuer: &IssuerConfig,
    qualifier: EntityPermissionQualifier,
) -> Result<Claims<User>> {
    let name = jwt
        .additional
        .get("name")
        .cloned()
        .map(|s| s.to_string())
        .unwrap_or_else(|| "Unkown".to_string());

    let mut claims = User::new_claims(name, user_nkey.to_string());
    claims.payload_mut().issuer_account = Some(issuer.nats_account_key.clone());
    main_attribute!(
        "auth.user_claims.user_nkey" = user_nkey.to_string(),
        "auth.user_claims.issuer.id" = issuer.id.clone(),
    );

    match &qualifier {
        EntityPermissionQualifier::Unknown(_) => {
            main_attribute!("auth.user_claims.qualifier.type" = "unknown");
        }
        EntityPermissionQualifier::User(organization_id) => {
            main_attribute!("auth.user_claims.qualifier.type" = "user");
            if let Some(organization_id) = &organization_id.organization_id {
                main_attribute!(
                    "auth.user_claims.qualifier.organization_id" = organization_id.clone()
                );
            }
        }
        EntityPermissionQualifier::Service(_) => {
            main_attribute!("auth.user_claims.qualifier.type" = "service");
        }
    }

    let response = request_permissions(jwt, issuer.id.as_str(), qualifier)?;
    main_attribute!(
        "auth.permissions.tags.count" = response.tags.len() as i64,
        "auth.permissions.publish.allow.count" = response.permissions.publish.allow.len() as i64,
        "auth.permissions.publish.deny.count" = response.permissions.publish.deny.len() as i64,
        "auth.permissions.subscribe.allow.count" =
            response.permissions.subscribe.allow.len() as i64,
        "auth.permissions.subscribe.deny.count" = response.permissions.subscribe.deny.len() as i64,
    );

    if let Some(max_messages) = response
        .permissions
        .response
        .as_ref()
        .and_then(|r| r.max_messages)
    {
        main_attribute!("auth.permissions.response.max_messages" = max_messages as i64);
    }

    if let Some(ttl) = response
        .permissions
        .response
        .as_ref()
        .and_then(|r| r.ttl.clone())
    {
        main_attribute!("auth.permissions.response.ttl_ms" = ttl.milliseconds as i64);
    }

    let nats_permissions = convert_permissions(response.permissions);
    claims.payload_mut().permissions.permissions = nats_permissions;
    main_attribute!("auth.permissions.converted" = true);

    if !response.tags.is_empty() {
        main_attribute!("auth.permissions.tags.attached" = true);
        claims.payload_mut().generic_fields.tags = Some(response.tags);
    }

    Ok(claims)
}

#[tracing::instrument(skip(jwt, qualifier))]
fn request_permissions(
    jwt: &jose::jwt::Claims<UntypedAdditionalProperties>,
    issuer_id: &str,
    qualifier: EntityPermissionQualifier,
) -> Result<GetEntityPermissionResponse> {
    let subject = format!("auth.permissions.{}", issuer_id);

    let jwt_bytes = serde_json::to_vec(jwt).map_err(|e| {
        record_error("auth-callout-permissions-request-failed", &e.to_string());
        e
    })?;
    attribute!("auth.permissions.request.jwt_claims.size" = jwt_bytes.len() as i64);

    let request = GetEntityPermissionRequest {
        qualifier,
        jwt_claims: jwt_bytes,
        ..Default::default()
    };

    let body = GetEntityPermissionRequest::serializer().to_bytes(&request);
    attribute!(
        "auth.permissions.request.timeout_ms" = PERMISSIONS_REQUEST_TIMEOUT_MS as i64,
        "auth.permissions.request.body.size" = body.len() as i64,
    );
    main_attribute!(
        "auth.permissions.subject" = subject.clone(),
        "auth.permissions.request.body.size" = body.len() as i64,
    );

    let response = consumer::request(subject.as_str(), &body, PERMISSIONS_REQUEST_TIMEOUT_MS)
        .map_err(|e| {
            record_error("auth-callout-permissions-request-failed", &e);
            anyhow!(e)
        })?;
    attribute!("auth.permissions.response.body.size" = response.body.len() as i64);
    main_attribute!("auth.permissions.response.body.size" = response.body.len() as i64);

    let permission_response = GetEntityPermissionResponse::serializer()
        .from_bytes(&response.body[..], UnrecognizedValues::Drop)
        .map_err(|e| {
            record_error("auth-callout-permissions-decode-failed", &e.to_string());
            e
        })?;
    main_attribute!("auth.permissions.response.decode.success" = true);

    Ok(permission_response)
}

fn convert_permissions(permissions: Permissions) -> NatsPermissions {
    use nats_jwt_rs::types::{
        Permission as NatsPermission, ResponsePermission as NatsResponsePermission,
    };
    use std::time::Duration;

    let publish = NatsPermission {
        allow: permissions.publish.allow,
        deny: permissions.publish.deny,
    };

    let subscribe = NatsPermission {
        allow: permissions.subscribe.allow,
        deny: permissions.subscribe.deny,
    };

    let resp = permissions.response.map(|r| NatsResponsePermission {
        max_messages: r.max_messages.map(|m| m as i64).unwrap_or(1),
        ttl: r
            .ttl
            .as_ref()
            .map(|d| Duration::from_millis(d.milliseconds as u64))
            .unwrap_or_default(),
    });

    NatsPermissions {
        publish,
        subscribe,
        resp,
    }
}

fn decode_auth_request(body: &[u8]) -> Result<Claims<AuthRequest>> {
    attribute!("auth.request.body.size" = body.len() as i64);
    if !body.starts_with(b"eyJ0") {
        main_attribute!("auth.request.decode.success" = false);
        return Err(anyhow!(
            "bad request: encryption mismatch: payload is encrypted"
        ));
    }

    let jwt = std::str::from_utf8(body)?;
    attribute!("auth.request.jwt.size" = jwt.len() as i64);

    let claims: Claims<FixedAuthRequest> = Claims::decode(jwt)?;
    let claims: Claims<AuthRequest> = Claims {
        aud: claims.aud,
        exp: claims.exp,
        iat: claims.iat,
        id: claims.id,
        iss: claims.iss,
        jti: claims.jti,
        name: claims.name,
        nats: claims.nats.into(),
        nbf: claims.nbf,
        sub: claims.sub,
    };

    validate_auth_request_claims(&claims)?;
    main_attribute!("auth.request.decode.success" = true);

    Ok(claims)
}

#[derive(Debug, Serialize, Deserialize, Default, Clone)]
pub struct FixedClientTLS {
    version: String,
    cipher: String,
    // In the nats-jwt-rs this is not optional and thus breaks. Because it won't be added if there are any verified chains.
    certs: Option<Vec<String>>,
    verified_chains: Option<Vec<Vec<String>>>,
}

/// In nats-jwt-rs the client tls has non optional cert and verified chains fields. The problem is that the server will only send either one of them.
/// So when it doesn't include the certs, then it throws an error.
/// Since we don't care about the certs, we just parse them without it and put them as none.
#[derive(Debug, Serialize, Deserialize, Clone)]
#[serde(rename_all = "snake_case")]
pub struct FixedAuthRequest {
    #[serde(rename = "server_id")]
    pub server: ServerID,
    pub user_nkey: String,
    pub client_info: ClientInfo,
    pub connect_opts: ConnectOpts,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub request_nonce: Option<String>,

    #[serde(flatten)]
    pub generic_fields: GenericFields,
}

impl Claim for FixedAuthRequest {
    fn validate() {}
}

impl Into<AuthRequest> for FixedAuthRequest {
    fn into(self) -> AuthRequest {
        AuthRequest {
            server: self.server,
            user_nkey: self.user_nkey,
            client_info: self.client_info,
            connect_opts: self.connect_opts,
            client_tls: None,
            request_nonce: self.request_nonce,
            generic_fields: self.generic_fields,
        }
    }
}

fn validate_auth_request_claims(claims: &Claims<AuthRequest>) -> Result<()> {
    if !claims.iss.starts_with('N') {
        let message = format!("bad request: expected server: {}", claims.iss);
        main_attribute!("auth.request.claims.valid" = false,);
        return Err(anyhow!(message));
    }

    if claims.iss != claims.payload().server.id {
        let message = format!(
            "bad request: issuers don't match: {} != {}",
            claims.iss,
            claims.payload().server.id
        );
        main_attribute!("auth.request.claims.valid" = false,);
        return Err(anyhow!(message));
    }

    let Some(audience) = &claims.aud else {
        main_attribute!("auth.request.claims.valid" = false,);
        return Err(anyhow!("bad request: missing audience"));
    };

    if *audience != *EXPECTED_AUDIENCE {
        let message = format!("bad request: unexpected audience: {}", EXPECTED_AUDIENCE);
        main_attribute!(
            "auth.request.claims.valid" = false,
            "auth.request.audience" = audience.clone(),
        );
        return Err(anyhow!(message));
    }

    main_attribute!(
        "auth.request.claims.valid" = true,
        "auth.request.audience" = audience.clone(),
    );
    Ok(())
}
