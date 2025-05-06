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
    types::{Fields, Method},
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
    let unverified: Unverified<Jwt<LogtoClaims>> = Jwt::decode(Compact::from_str(token)?)?;

    let key_identifier = unverified
        .expose_unverified_header()
        .key_identifier()
        .ok_or_else(|| anyhow!("Missing key identifier in JWT header"))?;

    let kid = match key_identifier {
        HeaderValue::Protected(s) => s,
        HeaderValue::Unprotected(s) => s,
    };

    let issuer = unverified
        .expose_unverified_payload()
        .issuer
        .clone()
        .ok_or_else(|| anyhow!("Missing issuer in JWT"))?;

    let issuer = configs
        .iter()
        .find(|i| i.issuer_url == issuer)
        .ok_or_else(|| anyhow!("Issuer not found in configuration"))?;

    let url = &issuer.jwks_url;
    let url = url::Url::parse(url).map_err(|e| anyhow!("Failed to parse URL: {}", e))?;
    let request = outgoing_handler::OutgoingRequest::new(Fields::new());

    request
        .set_method(&Method::Get)
        .map_err(|_| anyhow!("Failed to set JWKS request method"))?;

    let scheme = match url.scheme() {
        "http" => wasmcloud_component::wasi::http::types::Scheme::Http,
        "https" => wasmcloud_component::wasi::http::types::Scheme::Https,
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
        .set_authority(Some(&url.host_str().unwrap()))
        .map_err(|_| anyhow!("Failed to set authority for JWKS request"))?;

    let response = outgoing_handler::handle(request, None)?;
    // TODO: with wasi preview 3 we should be able to make this a proper async call
    response.subscribe().block();

    let response = response
        .get()
        .ok_or_else(|| anyhow!("JWKS request response missing"))?
        .map_err(|_| anyhow!("JWKS request response requested more than once"))?
        .map_err(|e| anyhow!("JWKS request response failed: {}", e))?;

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

    // TODO: Update when https://github.com/minkan-chat/jose/pull/144
    let jwks: Jwks = serde_json::from_slice(&buf)?;
    let jwk = jwks
        .keys
        .into_iter()
        .find(|k| k.key_id() == Some(kid))
        .ok_or_else(|| anyhow!("Failed to find JWK with kid {} in JWKS response", kid))?;

    let policy = StandardPolicy::new();
    let mut verifier: JwkVerifier = jwk
        .check(policy)
        .map_err(|e| anyhow!("Failed to check JWK: {}", e.1))?
        .try_into()?;

    let verified = unverified.verify(&mut verifier)?;

    // Validate the JWT manually because jose doesn't have a validator yet
    let claims = verified.payload();
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

    Ok((verified.payload().clone(), issuer))
}
