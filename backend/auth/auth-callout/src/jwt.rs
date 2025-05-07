use crate::config::IssuerConfig;
use anyhow::{anyhow, Result};
use jose::{
    format::{Compact, DecodeFormat},
    header::HeaderValue,
    jwk::JwkVerifier,
    jws::Unverified,
    jwt::Claims,
    policy::{Checkable, StandardPolicy},
    Jwt,
};
use serde::{Deserialize, Serialize};
use std::{
    io::Read,
    str::FromStr,
    time::{SystemTime, UNIX_EPOCH},
};
use wasmcloud_component::wasi::http::{
    outgoing_handler,
    types::{Fields, Method, Scheme},
};

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct LogtoClaims {
    pub name: Option<String>,
    pub picture: Option<String>,
    pub updated_at: Option<i64>,
    pub username: Option<String>,
    pub created_at: Option<i64>,
    pub at_hash: Option<String>,
}

/// TODO: remove when https://github.com/minkan-chat/jose/pull/144 is merged
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct Jwks {
    pub keys: Vec<jose::Jwk>,
}

pub fn validate_jwt<'t, 'c>(
    token: &'t str,
    configs: &'c Vec<IssuerConfig>,
) -> Result<(Claims<LogtoClaims>, &'c IssuerConfig)> {
    let unverified = decode_jwt(token)?;

    let key_id = extract_key_id(&unverified)?;
    let issuer_url = extract_issuer(&unverified)?;

    let issuer_config = find_issuer_config(configs, &issuer_url)?;

    let jwks = fetch_jwks(&issuer_config.jwks_url)?;
    let jwk = find_matching_jwk(jwks, key_id)?;

    let verified_jwt = verify_jwt_signature(unverified, jwk)?;
    validate_jwt_claims(&verified_jwt.payload())?;

    Ok((verified_jwt.payload().clone(), issuer_config))
}

fn decode_jwt(token: &str) -> Result<Unverified<Jwt<LogtoClaims>>> {
    Ok(Jwt::decode(Compact::from_str(token)?)?)
}

fn extract_key_id(unverified: &Unverified<Jwt<LogtoClaims>>) -> Result<&str> {
    let key_identifier = unverified
        .expose_unverified_header()
        .key_identifier()
        .ok_or_else(|| anyhow!("Missing key identifier in JWT header"))?;

    match key_identifier {
        HeaderValue::Protected(s) => Ok(s),
        HeaderValue::Unprotected(s) => Ok(s),
    }
}

fn extract_issuer(unverified: &Unverified<Jwt<LogtoClaims>>) -> Result<String> {
    unverified
        .expose_unverified_payload()
        .issuer
        .clone()
        .ok_or_else(|| anyhow!("Missing issuer in JWT"))
}

fn find_issuer_config<'c>(
    configs: &'c Vec<IssuerConfig>,
    issuer_url: &str,
) -> Result<&'c IssuerConfig> {
    configs
        .iter()
        .find(|i| i.issuer_url == issuer_url)
        .ok_or_else(|| anyhow!("Issuer not found in configuration"))
}

fn fetch_jwks(jwks_url: &str) -> Result<Jwks> {
    let url = url::Url::parse(jwks_url).map_err(|e| anyhow!("Failed to parse URL: {}", e))?;

    let request = create_jwks_request(&url)?;
    let response = send_jwks_request(request)?;
    parse_jwks_response(response)
}

fn create_jwks_request(url: &url::Url) -> Result<outgoing_handler::OutgoingRequest> {
    let request = outgoing_handler::OutgoingRequest::new(Fields::new());

    request
        .set_method(&Method::Get)
        .map_err(|_| anyhow!("Failed to set JWKS request method"))?;

    let scheme = match url.scheme() {
        "http" => Scheme::Http,
        "https" => Scheme::Https,
        _ => {
            return Err(anyhow!(
                "Unsupported scheme for JWKS request: {}",
                url.scheme()
            ))
        }
    };

    request
        .set_scheme(Some(&scheme))
        .map_err(|_| anyhow!("Failed to set scheme for JWKS request: {}", url.scheme()))?;

    request
        .set_path_with_query(Some(url.path()))
        .map_err(|_| anyhow!("Failed to set JWKS request path"))?;

    request
        .set_authority(Some(url.host_str().unwrap()))
        .map_err(|_| anyhow!("Failed to set authority for JWKS request"))?;

    Ok(request)
}

fn send_jwks_request(
    request: outgoing_handler::OutgoingRequest,
) -> Result<wasmcloud_component::wasi::http::types::IncomingResponse> {
    let response = outgoing_handler::handle(request, None)?;
    // TODO: with wasi preview 3 we should be able to make this a proper async call
    response.subscribe().block();

    response
        .get()
        .ok_or_else(|| anyhow!("JWKS request response missing"))?
        .map_err(|_| anyhow!("JWKS request response requested more than once"))?
        .map_err(|e| anyhow!("JWKS request response failed: {}", e))
}

// TODO: Update when https://github.com/minkan-chat/jose/pull/144
fn parse_jwks_response(
    response: wasmcloud_component::wasi::http::types::IncomingResponse,
) -> Result<Jwks> {
    if response.status() != 200 {
        return Err(anyhow!(
            "JWKS request failed with status code {}",
            response.status()
        ));
    }

    let body = response
        .consume()
        .map_err(|_| anyhow!("Failed to read JWKS response body"))?;

    let mut buf = vec![];
    let mut stream = body
        .stream()
        .map_err(|_| anyhow!("failed to get JWKS request response stream"))?;

    stream
        .read_to_end(&mut buf)
        .map_err(|_| anyhow!("failed to read value from JWKS request response stream"))?;

    Ok(serde_json::from_slice(&buf)?)
}

fn find_matching_jwk(jwks: Jwks, key_id: &str) -> Result<jose::Jwk> {
    jwks.keys
        .into_iter()
        .find(|k| k.key_id() == Some(key_id))
        .ok_or_else(|| anyhow!("Failed to find JWK with kid {} in JWKS response", key_id))
}

fn verify_jwt_signature(
    unverified: Unverified<Jwt<LogtoClaims>>,
    jwk: jose::Jwk,
) -> Result<jose::jws::Verified<Jwt<LogtoClaims>>> {
    let policy = StandardPolicy::new();
    let mut verifier: JwkVerifier = jwk
        .check(policy)
        .map_err(|e| anyhow!("Failed to check JWK: {}", e.1))?
        .try_into()?;

    Ok(unverified.verify(&mut verifier)?)
}

fn validate_jwt_claims(claims: &Claims<LogtoClaims>) -> Result<()> {
    let current_time = SystemTime::now();

    if let Some(issued_at) = claims.issued_at {
        let issued_at = UNIX_EPOCH + std::time::Duration::from_secs(issued_at);
        if issued_at > current_time {
            return Err(anyhow!("JWT issued in the future"));
        }
    }

    if let Some(expiration) = claims.expiration {
        let expiration = UNIX_EPOCH + std::time::Duration::from_secs(expiration);
        if expiration < current_time {
            return Err(anyhow!("JWT expired"));
        }
    }

    Ok(())
}
