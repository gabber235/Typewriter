use crate::config::IssuerConfig;
use anyhow::{anyhow, Result};
use jose::{
    format::{Compact, DecodeFormat},
    header::HeaderValue,
    jwk::JwkVerifier,
    jws::Unverified,
    jwt::Claims,
    policy::{Checkable, StandardPolicy},
    Jwt, UntypedAdditionalProperties,
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
use wasmcloud_component::{debug, trace};

/// TODO: remove when https://github.com/minkan-chat/jose/pull/144 is merged
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct Jwks {
    pub keys: Vec<jose::Jwk>,
}

pub fn validate_jwt<'t, 'c>(
    token: &'t str,
    configs: &'c Vec<IssuerConfig>,
) -> Result<(Claims<UntypedAdditionalProperties>, &'c IssuerConfig)> {
    trace!("validate_jwt called");
    let unverified = decode_jwt(token)?;
    debug!("JWT decoded successfully");

    let key_id = extract_key_id(&unverified)?;
    debug!("Extracted key_id: {}", key_id);

    let issuer_url = extract_issuer(&unverified)?;
    debug!("Extracted issuer URL: {}", issuer_url);

    let issuer_config = find_issuer_config(configs, &issuer_url)?;
    debug!("Found issuer config for URL: {}", issuer_url);

    let jwks = fetch_jwks(&issuer_config.jwks_url)?;
    debug!("Fetched JWKS with {} keys", jwks.keys.len());

    let jwk = find_matching_jwk(jwks, key_id)?;
    debug!("Found matching JWK for kid {}", key_id);

    let verified_jwt = verify_jwt_signature(unverified, jwk)?;
    debug!("JWT signature verified");

    validate_jwt_claims(&verified_jwt.payload())?;
    trace!("JWT claims validated successfully");

    Ok((verified_jwt.payload().clone(), issuer_config))
}

fn decode_jwt(token: &str) -> Result<Unverified<Jwt<UntypedAdditionalProperties>>> {
    trace!("Decoding JWT token");
    Ok(Jwt::decode(Compact::from_str(token)?)?)
}

fn extract_key_id(unverified: &Unverified<Jwt<UntypedAdditionalProperties>>) -> Result<&str> {
    trace!("Extracting key identifier from JWT header");
    let key_identifier = unverified
        .expose_unverified_header()
        .key_identifier()
        .ok_or_else(|| anyhow!("Missing key identifier in JWT header"))?;

    let kid = match key_identifier {
        HeaderValue::Protected(s) => s,
        HeaderValue::Unprotected(s) => s,
    };
    debug!("Key identifier extracted: {}", kid);
    Ok(kid)
}

fn extract_issuer(unverified: &Unverified<Jwt<UntypedAdditionalProperties>>) -> Result<String> {
    trace!("Extracting issuer from JWT payload");
    let issuer = unverified
        .expose_unverified_payload()
        .issuer
        .clone()
        .ok_or_else(|| anyhow!("Missing issuer in JWT"))?;
    debug!("Issuer extracted: {}", issuer);
    Ok(issuer)
}

fn find_issuer_config<'c>(
    configs: &'c Vec<IssuerConfig>,
    issuer_url: &str,
) -> Result<&'c IssuerConfig> {
    trace!("Searching for issuer config matching URL: {}", issuer_url);
    configs
        .iter()
        .find(|i| i.issuer_url == issuer_url)
        .ok_or_else(|| anyhow!("Issuer not found in configuration"))
}

fn fetch_jwks(jwks_url: &str) -> Result<Jwks> {
    trace!("Fetching JWKS from URL: {}", jwks_url);
    let url = url::Url::parse(jwks_url).map_err(|e| anyhow!("Failed to parse URL: {}", e))?;

    let request = create_jwks_request(&url)?;
    let response = send_jwks_request(request)?;
    let jwks = parse_jwks_response(response)?;
    debug!("JWKS fetched and parsed successfully");
    Ok(jwks)
}

fn create_jwks_request(url: &url::Url) -> Result<outgoing_handler::OutgoingRequest> {
    trace!("Creating JWKS request for URL: {}", url);
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

    debug!("JWKS request constructed");
    Ok(request)
}

fn send_jwks_request(
    request: outgoing_handler::OutgoingRequest,
) -> Result<wasmcloud_component::wasi::http::types::IncomingResponse> {
    trace!("Sending JWKS request");
    let response = outgoing_handler::handle(request, None)?;
    // TODO: with wasi preview 3 we should be able to make this a proper async call
    response.subscribe().block();

    let incoming = response
        .get()
        .ok_or_else(|| anyhow!("JWKS request response missing"))?
        .map_err(|_| anyhow!("JWKS request response requested more than once"))?
        .map_err(|e| anyhow!("JWKS request response failed: {}", e))?;

    debug!("JWKS response received with status {}", incoming.status());
    Ok(incoming)
}

// TODO: Update when https://github.com/minkan-chat/jose/pull/144
fn parse_jwks_response(
    response: wasmcloud_component::wasi::http::types::IncomingResponse,
) -> Result<Jwks> {
    trace!("Parsing JWKS response");
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

    let jwks: Jwks = serde_json::from_slice(&buf)?;
    debug!("JWKS parsed with {} keys", jwks.keys.len());
    Ok(jwks)
}

fn find_matching_jwk(jwks: Jwks, key_id: &str) -> Result<jose::Jwk> {
    trace!("Searching for JWK with kid: {}", key_id);
    let jwk = jwks
        .keys
        .into_iter()
        .find(|k| k.key_id() == Some(key_id))
        .ok_or_else(|| anyhow!("Failed to find JWK with kid {} in JWKS response", key_id))?;
    debug!("Matching JWK found for kid {}", key_id);
    Ok(jwk)
}

fn verify_jwt_signature(
    unverified: Unverified<Jwt<UntypedAdditionalProperties>>,
    jwk: jose::Jwk,
) -> Result<jose::jws::Verified<Jwt<UntypedAdditionalProperties>>> {
    trace!("Verifying JWT signature");
    let policy = StandardPolicy::new();
    let mut verifier: JwkVerifier = jwk
        .check(policy)
        .map_err(|e| anyhow!("Failed to check JWK: {}", e.1))?
        .try_into()?;

    let verified = unverified.verify(&mut verifier)?;
    debug!("JWT signature verification succeeded");
    Ok(verified)
}

fn validate_jwt_claims(claims: &Claims<UntypedAdditionalProperties>) -> Result<()> {
    trace!("Validating JWT claims");
    let current_time = SystemTime::now();

    if let Some(issued_at) = claims.issued_at {
        let issued_at = UNIX_EPOCH + std::time::Duration::from_secs(issued_at);
        if issued_at > current_time {
            debug!("JWT issued_at claim is in the future");
            return Err(anyhow!("JWT issued in the future"));
        }
    }

    if let Some(expiration) = claims.expiration {
        let expiration = UNIX_EPOCH + std::time::Duration::from_secs(expiration);
        if expiration < current_time {
            debug!("JWT expiration claim has passed");
            return Err(anyhow!("JWT expired"));
        }
    }

    debug!("JWT claims are valid");
    Ok(())
}
