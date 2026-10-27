//! Fuzzes JWT decoding and verification with tokens derived from signed seeds.
//!
//! Each input picks a seed token (valid, expired, foreign issuer or audience, unknown key id, an
//! untrusted key under the trusted key id, `alg: none`, HMAC) and either mutates its characters,
//! splices segments from several seeds, or replaces it with raw text. Validation must never panic,
//! never fail harder than "no identity" while the JWKS is available, and return an identity only
//! for a token whose signed header and claims are exactly those of the valid seed. Iterations are
//! bounded so the target runs in the normal test run; bolero prints `BOLERO_RANDOM_SEED` for any
//! failure, and the shrunk input becomes an example test below.

use std::time::{Duration, UNIX_EPOCH};

use base64::{Engine as _, engine::general_purpose::URL_SAFE_NO_PAD};
use jose::{
    JsonWebKey, Jwt,
    jwk::JwkSigner,
    jws::{IntoPayload, PayloadData, PayloadKind},
    policy::{Checkable, StandardPolicy},
};

use super::{Jwks, SystemTime, ValidationClock, validate_jwt_with};
use crate::config::{IssuerConfig, parse_issuer_configs};

const ISSUER: &str = "https://issuer.example/";
const NOW: u64 = 1_000_000;

const TRUSTED_KEY: &str = r#"{
    "kty": "OKP", "kid": "fixture-key", "crv": "Ed25519", "alg": "EdDSA",
    "x": "etkJX1EBhliHzBaimUQb0h2JhJKQ3G0beRVR3ssiedY",
    "d": "629kbTnU3Pgfkoq7zG9qe5LPuMi1PdaLcNo87nUya1I"
}"#;

const PUBLIC_KEY: &str = r#"{
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

struct FixedClock;

impl ValidationClock for FixedClock {
    fn now(&self) -> SystemTime {
        UNIX_EPOCH + Duration::from_secs(NOW)
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
fn reheadered(valid: &str, header: &serde_json::Value) -> String {
    let mut segments = valid.split('.');
    let _header = segments.next();
    let rest: Vec<&str> = segments.collect();
    format!(
        "{}.{}",
        URL_SAFE_NO_PAD.encode(header.to_string()),
        rest.join(".")
    )
}

struct Seeds {
    valid: String,
    all: Vec<String>,
}

fn seeds() -> Seeds {
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

fn issuers() -> Vec<IssuerConfig> {
    let config = serde_json::json!([{
        "id": "panel",
        "issuer_url": ISSUER,
        "jwks_url": "https://keys.example/jwks",
        "audiences": ["panel"],
        "require_expiration": true,
        "clock_skew_seconds": 0,
        "nats_account_key": "account"
    }]);
    parse_issuer_configs(&config.to_string()).expect("the issuer config is valid")
}

fn jwks() -> Jwks {
    Jwks {
        keys: vec![serde_json::from_str(PUBLIC_KEY).expect("the public key parses")],
    }
}

/// The token an input describes: its first byte picks how, the rest drives the change.
fn token(seeds: &[String], input: &[u8]) -> String {
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
fn check(token: &str, seeds: &Seeds, issuers: &[IssuerConfig]) {
    let _main_span = otel_wasi::enter_main_span(tracing::info_span!("jwt_fuzz"));
    let outcome = validate_jwt_with(token, issuers, &FixedClock, |_| Ok(jwks()));
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

#[test]
fn only_the_validly_signed_token_yields_an_identity() {
    let seeds = seeds();
    let issuers = issuers();
    bolero::check!()
        .with_iterations(2_000)
        .with_max_len(64)
        .for_each(|input: &[u8]| check(&token(&seeds.all, input), &seeds, &issuers));
}

#[test]
fn every_seed_reaches_its_intended_outcome() {
    let seeds = seeds();
    let issuers = issuers();
    let _main_span = otel_wasi::enter_main_span(tracing::info_span!("jwt_seeds"));
    let identities: Vec<bool> = seeds
        .all
        .iter()
        .map(|token| {
            validate_jwt_with(token, &issuers, &FixedClock, |_| Ok(jwks()))
                .expect("the JWKS is available")
                .is_some()
        })
        .collect();
    let mut expected = vec![false; seeds.all.len()];
    expected[0] = true;
    assert_eq!(identities, expected);
}

/// Found by the fuzz target: jose 0.0.2 deserializes an unrecognized `alg` by alternating between
/// its signing and encryption algorithm types forever, so this header overflowed the stack.
#[test]
fn a_token_with_an_unknown_algorithm_yields_no_identity() {
    let seeds = seeds();
    let header = serde_json::json!({ "kid": "fixture-key", "alg": "EdE3A" });
    check(&reheadered(&seeds.valid, &header), &seeds, &issuers());
}

/// The same recursion through a key embedded in the header, which validation never trusts.
#[test]
fn a_token_embedding_a_key_yields_no_identity() {
    let seeds = seeds();
    let header = serde_json::json!({
        "kid": "fixture-key",
        "alg": "EdDSA",
        "jwk": { "kty": "OKP", "crv": "Ed25519", "alg": "EdE3A", "x": "AA" }
    });
    check(&reheadered(&seeds.valid, &header), &seeds, &issuers());
}
