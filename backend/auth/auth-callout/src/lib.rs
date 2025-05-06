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
        let seed = store::get("nats-issuer-seed").map_err(|e| e.to_string())?;
        let seed = match reveal::reveal(&seed) {
            store::SecretValue::String(s) => s,
            store::SecretValue::Bytes(b) => String::from_utf8(b).map_err(|e| e.to_string())?,
        };
        let keypair = match KeyPair::from_seed(&seed) {
            Ok(kp) => kp,
            Err(e) => {
                info!("bad request: {}", e.to_string());
                return Err(e.to_string());
            }
        };
        let request = match decode(&msg.body) {
            Ok(claims) => claims,
            Err(e) => {
                info!("bad request: {}", e.to_string());
                return Err(e.to_string());
            }
        };
        let mut response = AuthResponse::generic_claim(request.payload().user_nkey.clone());
        response.aud = Some(request.payload().server.id.clone());
        // response.payload_mut().issuer_account = Some(keypair.public_key().clone());
        let jwt = match user_jwt(&request) {
            Ok(Some(jwt)) => jwt,
            Ok(None) => {
                response.payload_mut().error = "user not authorized".to_string();
                let data = response.encode(&keypair).map_err(|e| e.to_string())?;
                reply(msg, data)?;
                return Ok(());
            }
            Err(e) => {
                info!("bad request: {}", e.to_string());
                return Err(e.to_string());
            }
        };

        response.payload_mut().jwt = jwt;

        let data = response.encode(&keypair).map_err(|e| e.to_string())?;
        reply(msg, data)?;
        Ok(())
    }
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

fn user_jwt(request: &Claims<AuthRequest>) -> Result<Option<String>> {
    let user_nkey = request.payload().user_nkey.clone();

    // As the jwt is used for the sentinel, we abuse the password field to get the user's JWT
    let Some(raw_jwt) = request.payload().connect_opts.pass.clone() else {
        return Ok(None);
    };

    let config_str = runtime::get("issuers")
        .map_err(|e| anyhow!("Failed to get issuers config: {}", e))?
        .ok_or_else(|| anyhow!("Issuers config not found"))?;

    let configs: Vec<IssuerConfig> = serde_json::from_str(&config_str)
        .map_err(|e| anyhow!("Failed to parse auth config: {}", e))?;

    let (jwt, issuer) = match jwt::validate_jwt(&raw_jwt, &configs) {
        Ok(result) => result,
        Err(e) => {
            let username = request
                .payload()
                .connect_opts
                .user
                .clone()
                .unwrap_or("Unknown".to_string());
            debug!("Invalid JWT for {}: {}", username, e);
            return Ok(None);
        }
    };

    let signing_keys = store::get("nats-signing-keys")?;
    let signing_keys: HashMap<String, String> = match reveal::reveal(&signing_keys) {
        store::SecretValue::String(s) => serde_json::from_str(&s)?,
        store::SecretValue::Bytes(b) => serde_json::from_slice(&b)?,
    };
    let seed = signing_keys
        .get(&issuer.id)
        .ok_or_else(|| anyhow!("No seed found for issuer"))?;
    let keypair = match KeyPair::from_seed(&seed) {
        Ok(kp) => kp,
        Err(e) => {
            info!("bad request: {}", e.to_string());
            return Err(anyhow!("Failed to create keypair: {}", e));
        }
    };

    let name = jwt
        .additional
        .username
        .clone()
        .or(jwt.additional.name.clone())
        .or(jwt.subject.clone())
        .unwrap_or("Unkown".to_string());

    let mut claims = User::new_claims(name, user_nkey);
    claims.payload_mut().issuer_account = Some(issuer.nats_account_key.clone());

    match issuer.id.as_str() {
        "typewriter" => issuers::typewriter::issue(&mut claims, &jwt),
        _ => {
            return Err(anyhow!("Unsupported issuer: {}", issuer.id));
        }
    }

    Ok(Some(claims.encode(&keypair)?))
}

fn decode(body: &[u8]) -> Result<Claims<AuthRequest>> {
    // Check if it starts with eyJ0, if so, it's a JWT, if not it is encrypted
    let is_jwt = body.starts_with(b"eyJ0");
    if !is_jwt {
        // Currently encryption is not supported
        // If we ever want to, we look https://github.com/synadia-io/callout.go/blob/0aaab9ce2f2e8525ff52a4af8e9db7cacb1e2309/authservice.go#L327
        return Err(anyhow::anyhow!(
            "bad request: encryption mismatch: payload is encrypted"
        ));
    }

    let jwt = std::str::from_utf8(body)?;
    let claims: Claims<AuthRequest> = Claims::decode(jwt)?;

    if !claims.iss.starts_with("N") {
        return Err(anyhow::anyhow!(
            "bad request: expected server: {}",
            claims.iss
        ));
    }

    if claims.iss != claims.payload().server.id {
        return Err(anyhow::anyhow!(
            "bad request: issuers don't match: {} != {}",
            claims.iss,
            claims.payload().server.id
        ));
    }

    let Some(audience) = &claims.aud else {
        return Err(anyhow::anyhow!("bad request: missing audience"));
    };
    if *audience != *EXPECTED_AUDIENCE {
        return Err(anyhow::anyhow!(
            "bad request: unexpected audience: {}",
            EXPECTED_AUDIENCE
        ));
    }

    Ok(claims)
}

export!(AuthCallout);
