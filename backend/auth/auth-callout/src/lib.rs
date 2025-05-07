wit_bindgen::generate!({ generate_all });

use std::collections::HashMap;

use anyhow::{anyhow, Result};
use config::IssuerConfig;
use exports::wasmcloud::messaging::handler::Guest;
use nats_jwt_rs::{
    authorization::{AuthRequest, AuthResponse},
    user::User,
    Claims,
};
use nkeys::KeyPair;
use wasi::config::runtime;
use wasmcloud::messaging::*;
use wasmcloud::secrets::*;
use wasmcloud_component::{debug, info, warn};

pub mod config;
pub mod issuers;
pub mod jwt;

struct AuthCallout;

const EXPECTED_AUDIENCE: &str = "nats-authorization-request";

impl Guest for AuthCallout {
    fn handle_message(msg: types::BrokerMessage) -> Result<(), String> {
        let keypair = match get_nats_issuer_keypair() {
            Ok(kp) => kp,
            Err(e) => {
                info!("Failed to get keypair: {}", e);
                return Err(e);
            }
        };

        let request = match decode_auth_request(&msg.body) {
            Ok(req) => req,
            Err(e) => {
                info!("Bad request: {}", e);
                return Err(e.to_string());
            }
        };

        let user_nkey = request.payload().user_nkey.clone();
        let server_id = request.payload().server.id.clone();

        let mut response = create_auth_response(user_nkey, server_id);

        match process_user_jwt(&request) {
            Ok(Some(jwt)) => {
                response.payload_mut().jwt = jwt;
            }
            Ok(None) => {
                response.payload_mut().error = "user not authorized".to_string();
            }
            Err(e) => {
                info!("JWT processing error: {}", e);
                return Err(e.to_string());
            }
        };

        let data = response.encode(&keypair).map_err(|e| e.to_string())?;
        reply(msg, data)?;
        Ok(())
    }
}

fn get_nats_issuer_keypair() -> Result<KeyPair, String> {
    let seed = store::get("nats-issuer-seed").map_err(|e| e.to_string())?;
    let seed = match reveal::reveal(&seed) {
        store::SecretValue::String(s) => s,
        store::SecretValue::Bytes(b) => String::from_utf8(b).map_err(|e| e.to_string())?,
    };

    KeyPair::from_seed(&seed).map_err(|e| e.to_string())
}

fn create_auth_response(user_nkey: String, server_id: String) -> Claims<AuthResponse> {
    let mut response = AuthResponse::generic_claim(user_nkey);
    response.aud = Some(server_id);
    response
}

fn reply(reply_to: types::BrokerMessage, data: impl Into<Vec<u8>>) -> Result<(), String> {
    if let Some(reply_to) = reply_to.reply_to {
        consumer::publish(&types::BrokerMessage {
            subject: reply_to,
            reply_to: None,
            body: data.into(),
        })
    } else {
        warn!("No reply_to field in message, ignoring message");
        Ok(())
    }
}

fn process_user_jwt(request: &Claims<AuthRequest>) -> Result<Option<String>, anyhow::Error> {
    // As the jwt is used for the sentinel, we abuse the password field to get the user's JWT
    let Some(raw_jwt) = request.payload().connect_opts.pass.clone() else {
        return Ok(None);
    };

    let configs = load_issuer_configs()?;

    let (jwt, issuer) = match validate_user_jwt(&raw_jwt, &configs, request) {
        Ok(result) => result,
        Err(_) => return Ok(None),
    };

    let keypair = get_signing_keypair(&issuer.id)?;

    let claims = create_user_claims(&jwt, &request.payload().user_nkey, &issuer)?;

    Ok(Some(claims.encode(&keypair)?))
}

fn load_issuer_configs() -> Result<Vec<IssuerConfig>> {
    let config_str = runtime::get("issuers")
        .map_err(|e| anyhow!("Failed to get issuers config: {}", e))?
        .ok_or_else(|| anyhow!("Issuers config not found"))?;

    serde_json::from_str(&config_str).map_err(|e| anyhow!("Failed to parse auth config: {}", e))
}

fn validate_user_jwt<'a>(
    raw_jwt: &str,
    configs: &'a Vec<IssuerConfig>,
    request: &Claims<AuthRequest>,
) -> Result<(jose::jwt::Claims<jwt::LogtoClaims>, &'a IssuerConfig)> {
    match jwt::validate_jwt(raw_jwt, configs) {
        Ok(result) => Ok(result),
        Err(e) => {
            let username = request
                .payload()
                .connect_opts
                .user
                .clone()
                .unwrap_or("Unknown".to_string());
            debug!("Invalid JWT for {}: {}", username, e);
            return Err(anyhow!("Invalid JWT for {}: {}", username, e));
        }
    }
}

fn get_signing_keypair(issuer_id: &str) -> Result<KeyPair> {
    let signing_keys = store::get("nats-signing-keys")?;
    let signing_keys: HashMap<String, String> = match reveal::reveal(&signing_keys) {
        store::SecretValue::String(s) => serde_json::from_str(&s)?,
        store::SecretValue::Bytes(b) => serde_json::from_slice(&b)?,
    };

    let seed = signing_keys
        .get(issuer_id)
        .ok_or_else(|| anyhow!("No seed found for issuer"))?;

    KeyPair::from_seed(seed).map_err(|e| anyhow!("Failed to create keypair: {}", e))
}

fn create_user_claims(
    jwt: &jose::jwt::Claims<jwt::LogtoClaims>,
    user_nkey: &str,
    issuer: &IssuerConfig,
) -> Result<Claims<User>> {
    let name = jwt
        .additional
        .username
        .clone()
        .or(jwt.additional.name.clone())
        .or(jwt.subject.clone())
        .unwrap_or("Unkown".to_string());

    let mut claims = User::new_claims(name, user_nkey.to_string());
    claims.payload_mut().issuer_account = Some(issuer.nats_account_key.clone());

    match issuer.id.as_str() {
        "typewriter" => issuers::typewriter::issue(&mut claims, &jwt),
        _ => {
            return Err(anyhow!("Unsupported issuer: {}", issuer.id));
        }
    }

    Ok(claims)
}

fn decode_auth_request(body: &[u8]) -> Result<Claims<AuthRequest>> {
    // Check if the payload is a JWT (starts with eyJ0) or encrypted
    if !body.starts_with(b"eyJ0") {
        return Err(anyhow!(
            "bad request: encryption mismatch: payload is encrypted"
        ));
    }

    let jwt = std::str::from_utf8(body)?;
    let claims: Claims<AuthRequest> = Claims::decode(jwt)?;

    validate_auth_request_claims(&claims)?;

    Ok(claims)
}

fn validate_auth_request_claims(claims: &Claims<AuthRequest>) -> Result<()> {
    // Validate issuer format
    if !claims.iss.starts_with("N") {
        return Err(anyhow!("bad request: expected server: {}", claims.iss));
    }

    // Validate issuer consistency
    if claims.iss != claims.payload().server.id {
        return Err(anyhow!(
            "bad request: issuers don't match: {} != {}",
            claims.iss,
            claims.payload().server.id
        ));
    }

    // Validate audience
    let Some(audience) = &claims.aud else {
        return Err(anyhow!("bad request: missing audience"));
    };

    if *audience != *EXPECTED_AUDIENCE {
        return Err(anyhow!(
            "bad request: unexpected audience: {}",
            EXPECTED_AUDIENCE
        ));
    }

    Ok(())
}

export!(AuthCallout);
