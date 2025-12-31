wit_bindgen::generate!({
    with: {
        "wasmcloud:messaging/consumer@0.2.0": wasmcloud_utils::wasmcloud::messaging::consumer,
        "wasmcloud:messaging/handler@0.2.0": wasmcloud_utils::wasmcloud::messaging::handler,
    },
    generate_all,
});

use std::collections::HashMap;

use anyhow::{anyhow, Result};
use config::IssuerConfig;
use jose::UntypedAdditionalProperties;
use nats_jwt_rs::{
    authorization::{AuthRequest, AuthResponse, ClientInfo, ConnectOpts, ServerID},
    types::{GenericFields, Permissions as NatsPermissions},
    user::User,
    Claim, Claims,
};
use nkeys::KeyPair;
use prost::Message;
use serde::{Deserialize, Serialize};
use wasmcloud_component::{debug, error, info, trace};
use wasmcloud_utils::wasmcloud::messaging::{consumer, handler::Guest, reply, types};

mod typewriter {
    pub mod models {
        pub mod v1 {
            include!("generated/typewriter.models.v1.rs");
        }
    }
    pub mod api {
        pub mod v1 {
            include!("generated/typewriter.api.v1.rs");
        }
    }
}

pub mod config;
pub mod jwt;

struct AuthCallout;
wasmcloud_utils::export!(AuthCallout);

const EXPECTED_AUDIENCE: &str = "nats-authorization-request";

impl Guest for AuthCallout {
    fn handle_message(msg: types::BrokerMessage) -> Result<(), String> {
        trace!(
            "handle_message: received message on subject {}",
            msg.subject
        );

        let keypair = match get_nats_issuer_keypair() {
            Ok(kp) => {
                debug!("Successfully retrieved NATS issuer keypair");
                kp
            }
            Err(e) => {
                error!("Failed to get keypair: {}", e);
                return Err(e);
            }
        };

        let request = match decode_auth_request(&msg.body) {
            Ok(req) => {
                debug!("Decoded auth request for user {}", req.payload().user_nkey);
                req
            }
            Err(e) => {
                error!("Bad request: {}", e);
                return Err(e.to_string());
            }
        };

        let user_nkey = request.payload().user_nkey.clone();
        let server_id = request.payload().server.id.clone();

        let mut response = create_auth_response(user_nkey.clone(), server_id.clone());
        debug!(
            "Created auth response skeleton for user_nkey={}, server_id={}",
            user_nkey, server_id
        );

        match process_user_jwt(&request) {
            Ok(Some(jwt)) => {
                debug!("User JWT processed successfully, attaching to response");
                response.payload_mut().jwt = jwt;
            }
            Ok(None) => {
                debug!("User not authorized (no JWT returned)");
                response.payload_mut().error = "user not authorized".to_string();
            }
            Err(e) => {
                error!("JWT processing error: {}", e);
                return Err(e.to_string());
            }
        };

        let data = response.encode(&keypair).map_err(|e| e.to_string())?;
        trace!("Encoded response, size {} bytes, replying", data.len());
        reply(msg, data)?;
        debug!("Reply sent successfully");
        Ok(())
    }
}

fn get_nats_issuer_keypair() -> Result<KeyPair, String> {
    trace!("get_nats_issuer_keypair: reading NATS_ISSUER_SEED env var");
    let seed = std::env::var("NATS_ISSUER_SEED")
        .map_err(|_| "NATS_ISSUER_SEED not found in environment".to_string())?;

    KeyPair::from_seed(&seed).map_err(|e| e.to_string())
}

fn create_auth_response(user_nkey: String, server_id: String) -> Claims<AuthResponse> {
    trace!(
        "create_auth_response: building response for user_nkey={}, server_id={}",
        user_nkey,
        server_id
    );
    let mut response = AuthResponse::generic_claim(user_nkey);
    response.aud = Some(server_id);
    response
}

fn process_user_jwt(request: &Claims<AuthRequest>) -> Result<Option<String>, anyhow::Error> {
    trace!("process_user_jwt: entering");
    let Some(raw_jwt) = request.payload().connect_opts.pass.clone() else {
        debug!("No password JWT present in request; returning None");
        return Ok(None);
    };
    debug!("Found raw JWT in request, length {}", raw_jwt.len());

    let configs = load_issuer_configs()?;
    debug!("Loaded {} issuer configs", configs.len());

    let (jwt, issuer) = match validate_user_jwt(&raw_jwt, &configs, request) {
        Ok(result) => {
            debug!("JWT validated successfully for issuer {}", result.1.id);
            result
        }
        Err(e) => {
            error!("JWT validation failed: {}", e);
            return Ok(None);
        }
    };

    let keypair = get_signing_keypair(&issuer.id)?;
    debug!(
        "Obtained signing keypair for issuer {}: {}",
        issuer.id,
        keypair.public_key()
    );

    let claims = create_user_claims(
        &jwt,
        &request.payload().user_nkey,
        &issuer,
        &request.payload().connect_opts.nkey,
    )?;
    debug!(
        "Created user claims for user_nkey={}",
        request.payload().user_nkey
    );

    let encoded = claims.encode(&keypair)?;
    debug!("Encoded user claims, length {}", encoded.len());

    Ok(Some(encoded))
}

fn load_issuer_configs() -> Result<Vec<IssuerConfig>> {
    trace!("load_issuer_configs: reading ISSUERS env var");
    let config_str =
        std::env::var("ISSUERS").map_err(|_| anyhow!("ISSUERS not found in environment"))?;

    let configs: Vec<IssuerConfig> = serde_json::from_str(&config_str)
        .map_err(|e| anyhow!("Failed to parse auth config: {}", e))?;
    debug!("Parsed {} issuer configurations", configs.len());
    Ok(configs)
}

fn validate_user_jwt<'a>(
    raw_jwt: &str,
    configs: &'a Vec<IssuerConfig>,
    request: &Claims<AuthRequest>,
) -> Result<(
    jose::jwt::Claims<UntypedAdditionalProperties>,
    &'a IssuerConfig,
)> {
    trace!("validate_user_jwt: validating JWT");
    match jwt::validate_jwt(raw_jwt, configs) {
        Ok(result) => {
            debug!("JWT validation succeeded");
            Ok(result)
        }
        Err(e) => {
            let username = request
                .payload()
                .connect_opts
                .user
                .clone()
                .unwrap_or_else(|| "Unknown".to_string());
            error!("Invalid JWT for {}: {}", username, e);
            Err(anyhow!("Invalid JWT for {}: {}", username, e))
        }
    }
}

fn get_signing_keypair(issuer_id: &str) -> Result<KeyPair> {
    trace!(
        "get_signing_keypair: retrieving signing key for issuer {}",
        issuer_id
    );
    let signing_keys_json = std::env::var("NATS_SIGNING_KEYS")
        .map_err(|_| anyhow!("NATS_SIGNING_KEYS not found in environment"))?;

    let signing_keys: HashMap<String, String> = serde_json::from_str(&signing_keys_json)?;
    debug!("Parsed signing keys JSON, {} entries", signing_keys.len());

    let seed = signing_keys
        .get(issuer_id)
        .ok_or_else(|| anyhow!("No seed found for issuer {}", issuer_id))?;

    KeyPair::from_seed(seed).map_err(|e| anyhow!("Failed to create keypair: {}", e))
}

fn create_user_claims(
    jwt: &jose::jwt::Claims<UntypedAdditionalProperties>,
    user_nkey: &str,
    issuer: &IssuerConfig,
    organization_id: &Option<String>,
) -> Result<Claims<User>> {
    trace!(
        "create_user_claims: building claims for user_nkey {}",
        user_nkey
    );
    let name = jwt
        .additional
        .get("name")
        .cloned()
        .map(|s| s.to_string())
        .unwrap_or_else(|| "Unkown".to_string());

    let mut claims = User::new_claims(name, user_nkey.to_string());
    claims.payload_mut().issuer_account = Some(issuer.nats_account_key.clone());
    debug!("Set issuer_account to {}", issuer.nats_account_key);

    let response = request_permissions(&jwt, issuer.id.as_str(), organization_id)?;
    debug!(
        "Received permission response, tags count {}",
        response.tags.len()
    );

    let nats_permissions = response
        .permissions
        .as_ref()
        .ok_or_else(|| anyhow!("Missing permissions in response"))?
        .into();
    claims.payload_mut().permissions.permissions = nats_permissions;
    debug!("Converted permissions to NATS format");

    if !response.tags.is_empty() {
        claims.payload_mut().generic_fields.tags = Some(response.tags);
        debug!("Attached tags to generic fields");
    }

    Ok(claims)
}

fn request_permissions(
    jwt: &jose::jwt::Claims<UntypedAdditionalProperties>,
    issuer_id: &str,
    organization_id: &Option<String>,
) -> Result<typewriter::api::v1::PermissionResponse> {
    trace!(
        "request_permissions: sending request to subject auth.permissions.{}",
        issuer_id
    );
    let subject = format!("auth.permissions.{}", issuer_id);

    let jwt_bytes = serde_json::to_vec(jwt)?;
    debug!("Serialized JWT claims to {} bytes", jwt_bytes.len());

    let request = typewriter::api::v1::PermissionRequest {
        organization_id: organization_id.clone(),
        jwt_claims: jwt_bytes,
    };

    let body = request.encode_to_vec();
    debug!("Encoded PermissionRequest, {} bytes", body.len());

    let response = consumer::request(subject.as_str(), &body, 1000).map_err(|e| anyhow!(e))?;
    debug!(
        "Received response from consumer, {} bytes",
        response.body.len()
    );

    let permission_response = typewriter::api::v1::PermissionResponse::decode(&response.body[..])?;
    debug!("Decoded PermissionResponse successfully");

    Ok(permission_response)
}

impl From<&typewriter::models::v1::Permissions> for NatsPermissions {
    fn from(proto_permissions: &typewriter::models::v1::Permissions) -> Self {
        trace!("Converting proto Permissions to NatsPermissions");
        use nats_jwt_rs::types::{
            Permission as NatsPermission, ResponsePermission as NatsResponsePermission,
        };
        use std::time::Duration;

        let publish = NatsPermission {
            allow: proto_permissions
                .publish
                .as_ref()
                .map(|p| p.allow.clone())
                .unwrap_or_default(),
            deny: proto_permissions
                .publish
                .as_ref()
                .map(|p| p.deny.clone())
                .unwrap_or_default(),
        };

        let subscribe = NatsPermission {
            allow: proto_permissions
                .subscribe
                .as_ref()
                .map(|p| p.allow.clone())
                .unwrap_or_default(),
            deny: proto_permissions
                .subscribe
                .as_ref()
                .map(|p| p.deny.clone())
                .unwrap_or_default(),
        };

        let resp = proto_permissions
            .resp
            .as_ref()
            .map(|r| NatsResponsePermission {
                max_messages: r.max_messages as i64,
                ttl: r
                    .ttl
                    .as_ref()
                    .map(|d| Duration::from_secs(d.seconds as u64 + d.nanos as u64 / 1_000_000_000))
                    .unwrap_or_default(),
            });

        NatsPermissions {
            publish,
            subscribe,
            resp,
        }
    }
}

fn decode_auth_request(body: &[u8]) -> Result<Claims<AuthRequest>> {
    trace!("decode_auth_request: validating payload prefix");
    if !body.starts_with(b"eyJ0") {
        return Err(anyhow!(
            "bad request: encryption mismatch: payload is encrypted"
        ));
    }

    let jwt = std::str::from_utf8(body)?;
    debug!("Decoded JWT string, length {}", jwt.len());

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
    debug!("Decoded Claims<FixedAuthRequest> successfully");

    validate_auth_request_claims(&claims)?;
    debug!("Auth request claims validated");

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
    trace!("validate_auth_request_claims: starting validation");
    if !claims.iss.starts_with('N') {
        return Err(anyhow!("bad request: expected server: {}", claims.iss));
    }

    if claims.iss != claims.payload().server.id {
        return Err(anyhow!(
            "bad request: issuers don't match: {} != {}",
            claims.iss,
            claims.payload().server.id
        ));
    }

    let Some(audience) = &claims.aud else {
        return Err(anyhow!("bad request: missing audience"));
    };

    if *audience != *EXPECTED_AUDIENCE {
        return Err(anyhow!(
            "bad request: unexpected audience: {}",
            EXPECTED_AUDIENCE
        ));
    }

    debug!("Auth request claims passed all checks");
    Ok(())
}
