use crate::config::IssuerConfig;
use jose::{
    Jwt, UntypedAdditionalProperties,
    format::{Compact, DecodeFormat},
    header::HeaderValue,
    jwk::JwkVerifier,
    jws::Unverified,
    jwt::Claims,
    policy::{Checkable, StandardPolicy},
};
use otel_wasi::{ResultWithSlug, attribute, main_attribute, wasi_error};
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

/// TODO: remove when https://github.com/minkan-chat/jose/pull/144 is merged
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct Jwks {
    pub keys: Vec<jose::Jwk>,
}

pub fn validate_jwt<'t, 'c>(
    token: &'t str,
    configs: &'c Vec<IssuerConfig>,
) -> Result<Option<(Claims<UntypedAdditionalProperties>, &'c IssuerConfig)>, otel_wasi::Error> {
    attribute!("auth.jwt.raw.size" = token.len() as i64);

    let Some(unverified) = decode_jwt(token) else {
        return Ok(None);
    };

    let Some(key_id) = extract_key_id(&unverified) else {
        return Ok(None);
    };
    main_attribute!("auth.jwt.key_id" = key_id.to_string());

    let Some(issuer_url) = extract_issuer(&unverified) else {
        return Ok(None);
    };
    main_attribute!("auth.jwt.issuer" = issuer_url.clone());

    let Some(issuer_config) = find_issuer_config(configs, &issuer_url) else {
        return Ok(None);
    };
    main_attribute!(
        "auth.jwt.issuer_config.id" = issuer_config.id.clone(),
        "auth.jwks.request.host" = url::Url::parse(&issuer_config.jwks_url)
            .ok()
            .and_then(|url| url.host_str().map(ToString::to_string))
            .unwrap_or_default(),
    );

    let jwks = fetch_jwks(&issuer_config.jwks_url)?;

    let Some(jwk) = find_matching_jwk(jwks, key_id) else {
        return Ok(None);
    };

    let Some(verified_jwt) = verify_jwt_signature(unverified, jwk) else {
        return Ok(None);
    };

    if validate_jwt_claims(verified_jwt.payload()).is_none() {
        return Ok(None);
    }
    main_attribute!("auth.jwt.claims.valid" = true);

    Ok(Some((verified_jwt.payload().clone(), issuer_config)))
}

fn decode_jwt(token: &str) -> Option<Unverified<Jwt<UntypedAdditionalProperties>>> {
    let compact = Compact::from_str(token).ok()?;
    let result = Jwt::decode(compact).ok();
    if result.is_none() {
        main_attribute!("auth.jwt.decode.success" = false);
    }
    result
}

fn extract_key_id(unverified: &Unverified<Jwt<UntypedAdditionalProperties>>) -> Option<&str> {
    let key_identifier = unverified.expose_unverified_header().key_identifier()?;

    let kid = match key_identifier {
        HeaderValue::Protected(s) => s,
        HeaderValue::Unprotected(s) => s,
    };
    attribute!("auth.jwt.key_id" = kid.to_string());
    Some(kid)
}

fn extract_issuer(unverified: &Unverified<Jwt<UntypedAdditionalProperties>>) -> Option<String> {
    let issuer = unverified.expose_unverified_payload().issuer.clone()?;
    attribute!("auth.jwt.issuer" = issuer.clone());
    Some(issuer)
}

fn find_issuer_config<'c>(
    configs: &'c Vec<IssuerConfig>,
    issuer_url: &str,
) -> Option<&'c IssuerConfig> {
    configs.iter().find(|i| i.issuer_url == issuer_url)
}

fn fetch_jwks(jwks_url: &str) -> Result<Jwks, otel_wasi::Error> {
    let url = url::Url::parse(jwks_url).error_with_slug("auth-callout-jwks-url-parse-failed")?;

    main_attribute!(
        "auth.jwks.request.scheme" = url.scheme().to_string(),
        "auth.jwks.request.host" = url.host_str().unwrap_or_default().to_string(),
        "auth.jwks.request.path" = url.path().to_string(),
    );

    let request = create_jwks_request(&url)?;
    let response = send_jwks_request(request)?;
    parse_jwks_response(response)
}

fn create_jwks_request(
    url: &url::Url,
) -> Result<outgoing_handler::OutgoingRequest, otel_wasi::Error> {
    let request = outgoing_handler::OutgoingRequest::new(Fields::new());

    request.set_method(&Method::Get).map_err(|_| {
        wasi_error!(
            "auth-callout-jwks-request-method-failed",
            "failed to set method"
        )
    })?;

    let scheme = match url.scheme() {
        "http" => Scheme::Http,
        "https" => Scheme::Https,
        other => {
            return Err(wasi_error!(
                "auth-callout-jwks-request-scheme-failed",
                "unsupported scheme: {}",
                other
            ));
        }
    };

    request.set_scheme(Some(&scheme)).map_err(|_| {
        wasi_error!(
            "auth-callout-jwks-request-scheme-failed",
            "failed to set scheme"
        )
    })?;

    request.set_path_with_query(Some(url.path())).map_err(|_| {
        wasi_error!(
            "auth-callout-jwks-request-path-failed",
            "failed to set path"
        )
    })?;

    request
        .set_authority(Some(url.host_str().unwrap()))
        .map_err(|_| {
            wasi_error!(
                "auth-callout-jwks-request-authority-failed",
                "failed to set authority"
            )
        })?;

    attribute!("auth.jwks.request.constructed" = true);
    Ok(request)
}

fn send_jwks_request(
    request: outgoing_handler::OutgoingRequest,
) -> Result<wasmcloud_component::wasi::http::types::IncomingResponse, otel_wasi::Error> {
    let response = outgoing_handler::handle(request, None)
        .error_with_slug("auth-callout-jwks-request-send-failed")?;

    response.subscribe().block();

    let incoming = response
        .get()
        .ok_or_else(|| wasi_error!("auth-callout-jwks-request-send-failed", "response missing"))?
        .map_err(|_| {
            wasi_error!(
                "auth-callout-jwks-request-send-failed",
                "response requested more than once"
            )
        })?
        .map_err(|e| {
            wasi_error!(
                "auth-callout-jwks-request-send-failed",
                "response failed: {}",
                e
            )
        })?;

    main_attribute!("auth.jwks.response.status_code" = incoming.status() as i64);
    Ok(incoming)
}

fn parse_jwks_response(
    response: wasmcloud_component::wasi::http::types::IncomingResponse,
) -> Result<Jwks, otel_wasi::Error> {
    if response.status() != 200 {
        main_attribute!("auth.jwks.response.status_code" = response.status() as i64);
        return Err(wasi_error!(
            "auth-callout-jwks-response-status-failed",
            "JWKS request failed with status code {}",
            response.status()
        ));
    }

    let body = response.consume().map_err(|_| {
        wasi_error!(
            "auth-callout-jwks-response-body-failed",
            "failed to consume response body"
        )
    })?;

    let mut buf = vec![];
    let mut stream = body.stream().map_err(|_| {
        wasi_error!(
            "auth-callout-jwks-response-stream-failed",
            "failed to get response stream"
        )
    })?;

    stream
        .read_to_end(&mut buf)
        .error_with_slug("auth-callout-jwks-response-read-failed")?;

    let jwks: Jwks =
        serde_json::from_slice(&buf).error_with_slug("auth-callout-jwks-response-parse-failed")?;

    main_attribute!("auth.jwks.keys.count" = jwks.keys.len() as i64);
    Ok(jwks)
}

fn find_matching_jwk(jwks: Jwks, key_id: &str) -> Option<jose::Jwk> {
    let jwk = jwks.keys.into_iter().find(|k| k.key_id() == Some(key_id));
    if jwk.is_some() {
        main_attribute!("auth.jwks.key.match" = true);
    } else {
        main_attribute!("auth.jwks.key.match" = false);
    }
    jwk
}

fn verify_jwt_signature(
    unverified: Unverified<Jwt<UntypedAdditionalProperties>>,
    jwk: jose::Jwk,
) -> Option<jose::jws::Verified<Jwt<UntypedAdditionalProperties>>> {
    let policy = StandardPolicy::new();

    let checked = match jwk.check(policy) {
        Ok(c) => c,
        Err(_) => {
            main_attribute!("auth.jwt.signature.valid" = false);
            return None;
        }
    };

    let mut verifier: JwkVerifier = match checked.try_into() {
        Ok(v) => v,
        Err(_) => {
            main_attribute!("auth.jwt.signature.valid" = false);
            return None;
        }
    };

    let verified = match unverified.verify(&mut verifier) {
        Ok(v) => v,
        Err(_) => {
            main_attribute!("auth.jwt.signature.valid" = false);
            return None;
        }
    };

    main_attribute!("auth.jwt.signature.valid" = true);
    Some(verified)
}

fn validate_jwt_claims(claims: &Claims<UntypedAdditionalProperties>) -> Option<()> {
    let current_time = SystemTime::now();

    if let Some(issued_at) = claims.issued_at {
        let issued_at = UNIX_EPOCH + std::time::Duration::from_secs(issued_at);
        if issued_at > current_time {
            main_attribute!(
                "auth.jwt.claims.valid" = false,
                "auth.jwt.claims.iat.future" = true,
            );
            return None;
        }
    }

    if let Some(expiration) = claims.expiration {
        let expiration = UNIX_EPOCH + std::time::Duration::from_secs(expiration);
        if expiration < current_time {
            main_attribute!(
                "auth.jwt.claims.valid" = false,
                "auth.jwt.claims.expired" = true,
            );
            return None;
        }
    }

    main_attribute!("auth.jwt.claims.valid" = true);
    Some(())
}
