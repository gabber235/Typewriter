//! Fixtures for testing issuer configuration and JWT validation: issuer configs, a fixed clock,
//! claims, signing keys, the seed tokens the JWT properties mutate, and the oracle every
//! validation outcome is checked against.

use std::time::{Duration, SystemTime, UNIX_EPOCH};

use base64::{Engine as _, engine::general_purpose::URL_SAFE_NO_PAD};
use jose::{
    JsonWebKey, Jwt,
    jwk::JwkSigner,
    jws::{IntoPayload, PayloadData, PayloadKind},
    policy::{Checkable, StandardPolicy},
};

use crate::config::{IssuerConfig, parse_issuer_configs};
use crate::jwt::{FlexibleClaims, Jwks, ValidationClock, parse_jwks, validate_jwt_with};

const ISSUER: &str = "https://issuer.example/";
pub(crate) const NOW: u64 = 1_000_000;

const TRUSTED_KEY: &str = r#"{
    "kty": "OKP", "kid": "fixture-key", "crv": "Ed25519", "alg": "EdDSA",
    "x": "etkJX1EBhliHzBaimUQb0h2JhJKQ3G0beRVR3ssiedY",
    "d": "629kbTnU3Pgfkoq7zG9qe5LPuMi1PdaLcNo87nUya1I"
}"#;

pub(crate) const PUBLIC_KEY: &str = r#"{
    "kty": "OKP", "kid": "fixture-key", "crv": "Ed25519", "alg": "EdDSA",
    "x": "etkJX1EBhliHzBaimUQb0h2JhJKQ3G0beRVR3ssiedY"
}"#;

/// The trusted key's material under a key id the JWKS does not list.
const UNKNOWN_KID_KEY: &str = r#"{
    "kty": "OKP", "kid": "retired-key", "crv": "Ed25519", "alg": "EdDSA",
    "x": "etkJX1EBhliHzBaimUQb0h2JhJKQ3G0beRVR3ssiedY",
    "d": "629kbTnU3Pgfkoq7zG9qe5LPuMi1PdaLcNo87nUya1I"
}"#;

/// A key nobody trusts, claiming the trusted key id.
const UNTRUSTED_KEY: &str = r#"{
    "kty": "OKP", "kid": "fixture-key", "crv": "Ed25519", "alg": "EdDSA",
    "x": "bWhARigr_WtUOXVoeIbaq95NrUlERxleVfwLsGv6Uuo",
    "d": "ZuXdCNGeVmHT0zytZHIWGOosOkghXEbD89MBfMkXOUI"
}"#;

/// Characters a mutation writes: the token alphabet and a few that break its structure.
const ALPHABET: &[u8] =
    b"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.=+/ {}\"\\";

/// A clock that always reads the given Unix second.
pub(crate) struct FixedClock(pub(crate) u64);

impl ValidationClock for FixedClock {
    fn now(&self) -> SystemTime {
        UNIX_EPOCH + Duration::from_secs(self.0)
    }
}

struct JsonClaims(serde_json::Value);

impl IntoPayload for JsonClaims {
    type Error = serde_json::Error;

    fn into_payload(self) -> Result<PayloadKind, Self::Error> {
        Ok(PayloadKind::Attached(PayloadData::Standard(
            jose::Base64UrlString::encode(serde_json::to_vec(&self.0)?),
        )))
    }
}

fn claims() -> serde_json::Value {
    serde_json::json!({
        "iss": ISSUER,
        "sub": "ada",
        "aud": "panel",
        "exp": NOW + 300,
        "nbf": NOW - 1,
        "iat": NOW
    })
}

fn signed(key: &str, claims: serde_json::Value) -> String {
    let key: JsonWebKey = serde_json::from_str(key).expect("the fixture key parses");
    let checked = key
        .check(StandardPolicy::default())
        .map_err(|(_, error)| error)
        .expect("the fixture key passes the policy");
    let mut signer: JwkSigner = checked.try_into().expect("the fixture key signs");
    Jwt::builder_jwt()
        .build(JsonClaims(claims))
        .expect("the claims encode")
        .sign(&mut signer)
        .expect("the claims sign")
        .encode()
        .to_string()
}

fn with(overrides: serde_json::Value) -> serde_json::Value {
    let mut claims = claims();
    for (name, value) in overrides.as_object().expect("overrides are an object") {
        claims[name] = value.clone();
    }
    claims
}

/// A token whose header is `header` over the valid claims, keeping the valid signature.
pub(crate) fn reheadered(valid: &str, header: &serde_json::Value) -> String {
    let mut segments = valid.split('.');
    let _header = segments.next();
    let rest: Vec<&str> = segments.collect();
    format!(
        "{}.{}",
        URL_SAFE_NO_PAD.encode(header.to_string()),
        rest.join(".")
    )
}

pub(crate) struct Seeds {
    pub(crate) valid: String,
    pub(crate) all: Vec<String>,
}

pub(crate) fn seeds() -> Seeds {
    let valid = signed(TRUSTED_KEY, claims());
    let all = vec![
        valid.clone(),
        signed(TRUSTED_KEY, with(serde_json::json!({ "exp": NOW - 1 }))),
        signed(
            TRUSTED_KEY,
            with(serde_json::json!({ "iss": "https://other.example/" })),
        ),
        signed(TRUSTED_KEY, with(serde_json::json!({ "aud": "other" }))),
        signed(TRUSTED_KEY, with(serde_json::json!({ "nbf": NOW + 3_600 }))),
        signed(UNKNOWN_KID_KEY, claims()),
        signed(UNTRUSTED_KEY, claims()),
        reheadered(
            &valid,
            &serde_json::json!({ "alg": "none", "kid": "fixture-key" }),
        ),
        reheadered(
            &valid,
            &serde_json::json!({ "alg": "HS256", "kid": "fixture-key" }),
        ),
    ];
    Seeds { valid, all }
}

/// A valid issuer config as JSON, with each field of `overrides` replacing the default.
pub(crate) fn issuer_json(overrides: serde_json::Value) -> serde_json::Value {
    let mut issuer = serde_json::json!({
        "id": "panel",
        "issuer_url": "https://issuer.example/application/panel/",
        "jwks_url": "https://keys.example:8443/jwks/keys?tenant=panel",
        "audiences": ["typewriter-panel"],
        "require_expiration": true,
        "clock_skew_seconds": 30,
        "nats_account_key": "account"
    });
    for (key, value) in overrides.as_object().expect("overrides are an object") {
        issuer[key] = value.clone();
    }
    issuer
}

/// Parses `values` as the issuer config list the service reads.
pub(crate) fn parse_issuers(values: Vec<serde_json::Value>) -> Result<Vec<IssuerConfig>, String> {
    parse_issuer_configs(&serde_json::to_string(&values).expect("config serializes"))
}

/// The issuer the claim tests check against: `https://issuer.example/` for `panel` and `shared`.
pub(crate) fn issuer(require_expiration: bool, skew: u64) -> IssuerConfig {
    parse_issuers(vec![issuer_json(serde_json::json!({
        "issuer_url": "https://issuer.example/",
        "jwks_url": "https://keys.example:8443/jwks?tenant=panel",
        "audiences": ["panel", "shared"],
        "require_expiration": require_expiration,
        "clock_skew_seconds": skew
    }))])
    .expect("issuer config is valid")
    .remove(0)
}

/// Claims from `https://issuer.example/` for `panel`, valid from 900 until 1100.
pub(crate) fn flexible_claims() -> FlexibleClaims {
    serde_json::from_value(serde_json::json!({
        "iss": "https://issuer.example/",
        "aud": "panel",
        "exp": 1_100,
        "nbf": 900,
        "iat": 900
    }))
    .expect("claims are valid")
}

/// The issuers the JWT properties trust: only `ISSUER`, for `panel`, without clock skew.
pub(crate) fn issuers() -> Vec<IssuerConfig> {
    parse_issuers(vec![issuer_json(serde_json::json!({
        "issuer_url": ISSUER,
        "jwks_url": "https://keys.example/jwks",
        "audiences": ["panel"],
        "clock_skew_seconds": 0
    }))])
    .expect("the issuer config is valid")
}

pub(crate) fn jwks() -> Jwks {
    Jwks {
        keys: vec![serde_json::from_str(PUBLIC_KEY).expect("the public key parses")],
    }
}

/// The token an input describes: its first byte picks how, the rest drives the change.
pub(crate) fn token(seeds: &[String], input: &[u8]) -> String {
    let Some((&mode, rest)) = input.split_first() else {
        return String::new();
    };
    let seed = |byte: u8| &seeds[usize::from(byte) % seeds.len()];
    match mode % 3 {
        0 => {
            let (&choice, edits) = rest.split_first().unwrap_or((&0, &[]));
            let mut token = seed(choice).clone().into_bytes();
            for edit in edits.chunks_exact(3) {
                let position = usize::from(u16::from_le_bytes([edit[0], edit[1]]));
                let character = ALPHABET[usize::from(edit[2]) % ALPHABET.len()];
                match token.len() {
                    0 => token.push(character),
                    length if edit[2] & 0x80 != 0 => {
                        token.remove(position % length);
                    }
                    length => token[position % length] = character,
                }
            }
            String::from_utf8_lossy(&token).into_owned()
        }
        1 => {
            // Every seed is a compact token of three segments; missing input bytes pick seed 0.
            let mut picks = rest.iter().copied().chain(std::iter::repeat(0));
            let [header, payload, signature] = [0, 1, 2].map(|index| {
                let byte = picks.next().expect("the picks repeat forever");
                seed(byte)
                    .split('.')
                    .nth(index)
                    .expect("a seed has three segments")
                    .to_owned()
            });
            format!("{header}.{payload}.{signature}")
        }
        _ => String::from_utf8_lossy(rest).into_owned(),
    }
}

/// The decoded header and claims a compact token signs, when it has them.
fn signed_content(token: &str) -> Option<(Vec<u8>, Vec<u8>)> {
    let mut segments = token.split('.');
    let header = URL_SAFE_NO_PAD.decode(segments.next()?).ok()?;
    let payload = URL_SAFE_NO_PAD.decode(segments.next()?).ok()?;
    Some((header, payload))
}

/// Validates `token` and checks the outcome against the oracle.
pub(crate) fn check(token: &str, seeds: &Seeds, issuers: &[IssuerConfig]) {
    let _main_span = otel_wasi::enter_main_span(tracing::info_span!("jwt_fuzz"));
    let outcome = validate_jwt_with(token, issuers, &FixedClock(NOW), |_| Ok(jwks()));
    let identity = outcome.unwrap_or_else(|error| {
        panic!("validation failed harder than no identity for {token:?}: {error:?}")
    });
    if let Some((claims, issuer)) = identity {
        assert_eq!(
            signed_content(token),
            signed_content(&seeds.valid),
            "an identity was issued for a token the trusted key never signed: {token:?}"
        );
        assert_eq!(claims.subject.as_deref(), Some("ada"));
        assert_eq!(issuer.id, "panel");
    }
}

/// A JWKS document listing `keys`, each a JSON Web Key.
pub(crate) fn jwks_document(keys: &[&str]) -> Vec<u8> {
    let keys: Vec<serde_json::Value> = keys
        .iter()
        .map(|key| serde_json::from_str(key).expect("the fixture key is JSON"))
        .collect();
    serde_json::json!({ "keys": keys }).to_string().into_bytes()
}

/// Whether the valid seed token yields an identity when the issuer serves `document` as its JWKS.
pub(crate) fn identity_with(document: &[u8]) -> bool {
    let _main_span = otel_wasi::enter_main_span(tracing::info_span!("jwks_guard"));
    let seeds = seeds();
    validate_jwt_with(&seeds.valid, &issuers(), &FixedClock(NOW), |_| {
        parse_jwks(document)
    })
    .expect("the JWKS parses")
    .is_some()
}
