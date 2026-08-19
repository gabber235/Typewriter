use crate::config::IssuerConfig;
use jose::{
    JoseHeader, JsonWebSignature, UntypedAdditionalProperties,
    format::{Compact, DecodeFormat},
    header::HeaderValue,
    jwa::{JsonWebAlgorithm, JsonWebSigningAlgorithm},
    jwk::JwkVerifier,
    jws::{FromRawPayload, PayloadData, Unverified},
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
use url::Position;
use wasmcloud_component::wasi::http::{
    outgoing_handler,
    types::{Fields, Method, Scheme},
};

/// TODO: remove when https://github.com/minkan-chat/jose/pull/144 is merged
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct Jwks {
    pub keys: Vec<jose::Jwk>,
}

type FlexibleJwt = JsonWebSignature<Compact, FlexibleClaims>;

#[derive(Debug, Clone, Deserialize)]
struct FlexibleClaims {
    #[serde(rename = "iss")]
    issuer: Option<String>,
    #[serde(rename = "sub")]
    subject: Option<String>,
    #[serde(rename = "aud")]
    audience: Option<AudienceClaim>,
    #[serde(rename = "exp")]
    expiration: Option<u64>,
    #[serde(rename = "nbf")]
    not_before: Option<u64>,
    #[serde(rename = "iat")]
    issued_at: Option<u64>,
    #[serde(rename = "jti")]
    jwt_id: Option<String>,
    #[serde(flatten)]
    additional: UntypedAdditionalProperties,
}

#[derive(Debug, Clone, Deserialize)]
#[serde(untagged)]
enum AudienceClaim {
    One(String),
    Many(Vec<String>),
}

impl AudienceClaim {
    fn matching<'a>(&'a self, configured: &std::collections::HashSet<String>) -> Option<&'a str> {
        match self {
            Self::One(audience) => configured.contains(audience).then_some(audience.as_str()),
            Self::Many(audiences) => audiences
                .iter()
                .find(|audience| configured.contains(*audience))
                .map(String::as_str),
        }
    }
}

impl FromRawPayload for FlexibleClaims {
    type Context = ();
    type Error = serde_json::Error;

    fn from_attached(_: &Self::Context, payload: PayloadData) -> Result<Self, Self::Error> {
        match payload {
            PayloadData::Standard(data) => serde_json::from_slice(&data.decode()),
        }
    }

    fn from_detached<F, T>(
        _: &Self::Context,
        _: &JoseHeader<F, T>,
    ) -> Result<(Self, PayloadData), Self::Error> {
        Err(<serde_json::Error as serde::de::Error>::custom(
            "detached JWT payloads are unsupported",
        ))
    }

    fn from_detached_many<F, T>(
        _: &Self::Context,
        _: &[JoseHeader<F, T>],
    ) -> Result<(Self, PayloadData), Self::Error> {
        Err(<serde_json::Error as serde::de::Error>::custom(
            "detached JWT payloads are unsupported",
        ))
    }
}

impl FlexibleClaims {
    fn into_standard(self, audience: String) -> Claims<UntypedAdditionalProperties> {
        Claims {
            issuer: self.issuer,
            subject: self.subject,
            audience: Some(audience),
            expiration: self.expiration,
            not_before: self.not_before,
            issued_at: self.issued_at,
            jwt_id: self.jwt_id,
            additional: self.additional,
        }
    }
}

pub trait ValidationClock {
    fn now(&self) -> SystemTime;
}

pub struct SystemValidationClock;

impl ValidationClock for SystemValidationClock {
    fn now(&self) -> SystemTime {
        SystemTime::now()
    }
}

pub fn validate_jwt<'c>(
    token: &str,
    configs: &'c [IssuerConfig],
    clock: &impl ValidationClock,
) -> Result<Option<(Claims<UntypedAdditionalProperties>, &'c IssuerConfig)>, otel_wasi::Error> {
    attribute!("auth.jwt.raw.size" = token.len() as i64);

    let Some(unverified) = decode_jwt(token) else {
        return Ok(None);
    };

    let Some(key_id) = extract_key_id(&unverified) else {
        return Ok(None);
    };
    main_attribute!("auth.jwt.key_id" = key_id.to_string());

    let Some(algorithm) = extract_supported_algorithm(&unverified) else {
        return Ok(None);
    };

    let Some(issuer_url) = extract_issuer(&unverified) else {
        return Ok(None);
    };
    main_attribute!("auth.jwt.issuer" = issuer_url.clone());

    let Some(issuer_config) = find_issuer_config(configs, &issuer_url) else {
        return Ok(None);
    };
    main_attribute!(
        "auth.jwt.issuer_config.id" = issuer_config.id.clone(),
        "auth.jwks.request.host" = issuer_config
            .jwks_url
            .host_str()
            .unwrap_or_default()
            .to_string(),
    );

    let jwks = fetch_jwks(&issuer_config.jwks_url)?;

    let Some(jwk) = find_matching_jwk(jwks, key_id, algorithm) else {
        return Ok(None);
    };

    let Some(verified_jwt) = verify_jwt_signature(unverified, jwk) else {
        return Ok(None);
    };

    let Some(audience) = validate_jwt_claims(verified_jwt.payload(), issuer_config, clock) else {
        return Ok(None);
    };
    main_attribute!("auth.jwt.claims.valid" = true);

    Ok(Some((
        verified_jwt.payload().clone().into_standard(audience),
        issuer_config,
    )))
}

fn extract_supported_algorithm(
    unverified: &Unverified<FlexibleJwt>,
) -> Option<&JsonWebSigningAlgorithm> {
    let HeaderValue::Protected(algorithm) = unverified.expose_unverified_header().algorithm()
    else {
        main_attribute!("auth.jwt.algorithm.valid" = false);
        return None;
    };

    if !is_supported_asymmetric_algorithm(algorithm) {
        main_attribute!("auth.jwt.algorithm.valid" = false);
        return None;
    }

    main_attribute!("auth.jwt.algorithm.valid" = true);
    Some(algorithm)
}

fn is_supported_asymmetric_algorithm(algorithm: &JsonWebSigningAlgorithm) -> bool {
    matches!(
        algorithm,
        JsonWebSigningAlgorithm::Rsa(_)
            | JsonWebSigningAlgorithm::EcDSA(_)
            | JsonWebSigningAlgorithm::EdDSA
    )
}

fn decode_jwt(token: &str) -> Option<Unverified<FlexibleJwt>> {
    let compact = Compact::from_str(token).ok()?;
    let result = FlexibleJwt::decode(compact).ok();
    if result.is_none() {
        main_attribute!("auth.jwt.decode.success" = false);
    }
    result
}

fn extract_key_id(unverified: &Unverified<FlexibleJwt>) -> Option<&str> {
    let key_identifier = unverified.expose_unverified_header().key_identifier()?;

    let kid = match key_identifier {
        HeaderValue::Protected(s) => s,
        HeaderValue::Unprotected(s) => s,
    };
    attribute!("auth.jwt.key_id" = kid.to_string());
    Some(kid)
}

fn extract_issuer(unverified: &Unverified<FlexibleJwt>) -> Option<String> {
    let issuer = unverified.expose_unverified_payload().issuer.clone()?;
    attribute!("auth.jwt.issuer" = issuer.clone());
    Some(issuer)
}

fn find_issuer_config<'c>(
    configs: &'c [IssuerConfig],
    issuer_url: &str,
) -> Option<&'c IssuerConfig> {
    configs
        .iter()
        .find(|issuer| issuer.issuer_url.as_str() == issuer_url)
}

fn fetch_jwks(url: &url::Url) -> Result<Jwks, otel_wasi::Error> {
    main_attribute!(
        "auth.jwks.request.scheme" = url.scheme().to_string(),
        "auth.jwks.request.host" = url.host_str().unwrap_or_default().to_string(),
        "auth.jwks.request.path" = url.path().to_string(),
    );

    let request = create_jwks_request(url)?;
    let response = send_jwks_request(request)?;
    parse_jwks_response(response)
}

fn create_jwks_request(
    url: &url::Url,
) -> Result<outgoing_handler::OutgoingRequest, otel_wasi::Error> {
    let headers = Fields::new();
    for (name, value) in wasmcloud_utils::http::propagation_headers() {
        headers.set(&name, &[value]).map_err(|_| {
            wasi_error!(
                "auth-callout-jwks-request-trace-context-failed",
                "failed to set trace context header"
            )
        })?;
    }
    let request = outgoing_handler::OutgoingRequest::new(headers);

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

    let path_with_query = &url[Position::BeforePath..Position::AfterQuery];
    request
        .set_path_with_query(Some(path_with_query))
        .map_err(|_| {
            wasi_error!(
                "auth-callout-jwks-request-path-failed",
                "failed to set path"
            )
        })?;

    let authority = &url[Position::BeforeHost..Position::AfterPort];
    request.set_authority(Some(authority)).map_err(|_| {
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

fn find_matching_jwk(
    jwks: Jwks,
    key_id: &str,
    algorithm: &JsonWebSigningAlgorithm,
) -> Option<jose::Jwk> {
    let jwk = matching_jwk(jwks, key_id, algorithm);
    if jwk.is_some() {
        main_attribute!("auth.jwks.key.match" = true);
    } else {
        main_attribute!("auth.jwks.key.match" = false);
    }
    jwk
}

fn matching_jwk(
    jwks: Jwks,
    key_id: &str,
    algorithm: &JsonWebSigningAlgorithm,
) -> Option<jose::Jwk> {
    jwks.keys.into_iter().find(|key| {
        key.key_id() == Some(key_id)
            && matches!(
                key.algorithm(),
                Some(JsonWebAlgorithm::Signing(key_algorithm)) if key_algorithm == algorithm
            )
    })
}

fn verify_jwt_signature(
    unverified: Unverified<FlexibleJwt>,
    jwk: jose::Jwk,
) -> Option<jose::jws::Verified<FlexibleJwt>> {
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

fn validate_jwt_claims(
    claims: &FlexibleClaims,
    issuer: &IssuerConfig,
    clock: &impl ValidationClock,
) -> Option<String> {
    match check_jwt_claims(claims, issuer, clock) {
        Ok(audience) => {
            main_attribute!("auth.jwt.claims.valid" = true);
            Some(audience)
        }
        Err(ClaimValidationFailure::IssuedInFuture) => {
            main_attribute!(
                "auth.jwt.claims.valid" = false,
                "auth.jwt.claims.iat.future" = true,
            );
            None
        }
        Err(ClaimValidationFailure::Expired) => {
            main_attribute!(
                "auth.jwt.claims.valid" = false,
                "auth.jwt.claims.expired" = true,
            );
            None
        }
        Err(_) => {
            main_attribute!("auth.jwt.claims.valid" = false);
            None
        }
    }
}

#[derive(Debug, PartialEq, Eq)]
enum ClaimValidationFailure {
    Issuer,
    Audience,
    Clock,
    IssuedInFuture,
    NotYetValid,
    ExpirationRequired,
    Expired,
}

fn check_jwt_claims(
    claims: &FlexibleClaims,
    issuer: &IssuerConfig,
    clock: &impl ValidationClock,
) -> Result<String, ClaimValidationFailure> {
    if claims.issuer.as_deref() != Some(issuer.issuer_url.as_str()) {
        return Err(ClaimValidationFailure::Issuer);
    }

    let Some(audiences) = claims.audience.as_ref() else {
        return Err(ClaimValidationFailure::Audience);
    };
    let audience = audiences
        .matching(&issuer.audiences)
        .ok_or(ClaimValidationFailure::Audience)?;

    let current_time = clock
        .now()
        .duration_since(UNIX_EPOCH)
        .map_err(|_| ClaimValidationFailure::Clock)?
        .as_secs();
    let skew = issuer.clock_skew.as_secs();
    let latest_acceptable_future = current_time.saturating_add(skew);

    if let Some(issued_at) = claims.issued_at
        && issued_at > latest_acceptable_future
    {
        return Err(ClaimValidationFailure::IssuedInFuture);
    }

    if let Some(not_before) = claims.not_before
        && not_before > latest_acceptable_future
    {
        return Err(ClaimValidationFailure::NotYetValid);
    }

    match claims.expiration {
        None if issuer.require_expiration => {
            return Err(ClaimValidationFailure::ExpirationRequired);
        }
        Some(expiration) if current_time >= expiration.saturating_add(skew) => {
            return Err(ClaimValidationFailure::Expired);
        }
        _ => {}
    }

    Ok(audience.to_string())
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::config::parse_issuer_configs;
    use jose::jwa::{Hmac, RsaSigning, RsassaPkcs1V1_5};
    use std::time::Duration;

    struct FixedClock(u64);

    impl ValidationClock for FixedClock {
        fn now(&self) -> SystemTime {
            UNIX_EPOCH + Duration::from_secs(self.0)
        }
    }

    fn issuer(require_expiration: bool, skew: u64) -> IssuerConfig {
        let config = serde_json::json!([{
            "id": "panel",
            "issuer_url": "https://issuer.example/",
            "jwks_url": "https://keys.example:8443/jwks?tenant=panel",
            "audiences": ["panel", "shared"],
            "require_expiration": require_expiration,
            "clock_skew_seconds": skew,
            "nats_account_key": "account"
        }]);
        parse_issuer_configs(&config.to_string())
            .expect("issuer config is valid")
            .remove(0)
    }

    fn claims() -> FlexibleClaims {
        serde_json::from_value(serde_json::json!({
            "iss": "https://issuer.example/",
            "aud": "panel",
            "exp": 1_100,
            "nbf": 900,
            "iat": 900
        }))
        .expect("claims are valid")
    }

    #[test]
    fn accepts_claims_with_an_allowed_audience() {
        assert!(check_jwt_claims(&claims(), &issuer(true, 0), &FixedClock(1_000)).is_ok());
    }

    #[test]
    fn rejects_nonexact_issuer_and_unconfigured_audience() {
        let config = issuer(true, 0);
        let mut wrong_issuer = claims();
        wrong_issuer.issuer = Some("https://issuer.example".into());
        let mut wrong_audience = claims();
        wrong_audience.audience = Some(AudienceClaim::One("other".into()));

        assert!(check_jwt_claims(&wrong_issuer, &config, &FixedClock(1_000)).is_err());
        assert!(check_jwt_claims(&wrong_audience, &config, &FixedClock(1_000)).is_err());
    }

    #[test]
    fn accepts_one_matching_audience_from_an_array() {
        let config = issuer(true, 0);
        let mut claims = claims();
        claims.audience = Some(AudienceClaim::Many(vec!["other".into(), "shared".into()]));

        assert_eq!(
            check_jwt_claims(&claims, &config, &FixedClock(1_000)),
            Ok("shared".into())
        );

        claims.audience = Some(AudienceClaim::Many(vec!["first".into(), "second".into()]));
        assert_eq!(
            check_jwt_claims(&claims, &config, &FixedClock(1_000)),
            Err(ClaimValidationFailure::Audience)
        );
    }

    #[test]
    fn enforces_required_expiration_at_the_boundary() {
        let config = issuer(true, 0);
        let mut missing = claims();
        missing.expiration = None;
        let mut expires_now = claims();
        expires_now.expiration = Some(1_000);

        assert!(check_jwt_claims(&missing, &config, &FixedClock(1_000)).is_err());
        assert!(check_jwt_claims(&expires_now, &config, &FixedClock(1_000)).is_err());
    }

    #[test]
    fn applies_clock_skew_to_temporal_claims() {
        let config = issuer(true, 30);
        let mut within_skew = claims();
        within_skew.expiration = Some(971);
        within_skew.not_before = Some(1_030);
        within_skew.issued_at = Some(1_030);
        let mut beyond_skew = within_skew.clone();
        beyond_skew.issued_at = Some(1_031);

        assert!(check_jwt_claims(&within_skew, &config, &FixedClock(1_000)).is_ok());
        assert!(check_jwt_claims(&beyond_skew, &config, &FixedClock(1_000)).is_err());

        beyond_skew.issued_at = Some(1_000);
        beyond_skew.not_before = Some(1_031);
        assert!(check_jwt_claims(&beyond_skew, &config, &FixedClock(1_000)).is_err());

        beyond_skew.not_before = Some(1_000);
        beyond_skew.expiration = Some(970);
        assert!(check_jwt_claims(&beyond_skew, &config, &FixedClock(1_000)).is_err());
    }

    #[test]
    fn optional_expiration_policy_still_rejects_present_expired_claims() {
        let config = issuer(false, 0);
        let mut claims = claims();
        claims.expiration = None;
        assert!(check_jwt_claims(&claims, &config, &FixedClock(1_000)).is_ok());

        claims.expiration = Some(999);
        assert!(check_jwt_claims(&claims, &config, &FixedClock(1_000)).is_err());
    }

    #[test]
    fn selected_jwk_must_declare_the_exact_algorithm() {
        let without_algorithm: jose::Jwk = serde_json::from_value(serde_json::json!({
            "kty": "RSA",
            "kid": "key",
            "n": "sXchDaQebHnPiGvyDOAT4saGEUetSyo8XzcEKrckcCw5vFo4gP3pD7oF78CNJqQh5N2r9Qkzr2wY3KjXJfJv7w",
            "e": "AQAB"
        }))
        .expect("JWK parses");
        let mismatched: jose::Jwk = serde_json::from_value(serde_json::json!({
            "kty": "RSA",
            "kid": "key",
            "alg": "RS512",
            "n": "sXchDaQebHnPiGvyDOAT4saGEUetSyo8XzcEKrckcCw5vFo4gP3pD7oF78CNJqQh5N2r9Qkzr2wY3KjXJfJv7w",
            "e": "AQAB"
        }))
        .expect("JWK parses");
        let algorithm =
            JsonWebSigningAlgorithm::Rsa(RsaSigning::RsPkcs1V1_5(RsassaPkcs1V1_5::Rs256));

        assert!(
            matching_jwk(
                Jwks {
                    keys: vec![without_algorithm]
                },
                "key",
                &algorithm
            )
            .is_none()
        );
        assert!(
            matching_jwk(
                Jwks {
                    keys: vec![mismatched]
                },
                "key",
                &algorithm
            )
            .is_none()
        );
    }

    #[test]
    fn rejects_unsupported_signing_algorithms() {
        assert!(!is_supported_asymmetric_algorithm(
            &JsonWebSigningAlgorithm::None
        ));
        assert!(!is_supported_asymmetric_algorithm(
            &JsonWebSigningAlgorithm::Hmac(Hmac::Hs256)
        ));
        assert!(!is_supported_asymmetric_algorithm(
            &JsonWebSigningAlgorithm::Other("custom".into())
        ));
        assert!(is_supported_asymmetric_algorithm(
            &JsonWebSigningAlgorithm::EdDSA
        ));
    }
}
