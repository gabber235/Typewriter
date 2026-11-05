//! Fuzzes JWT decoding and verification with tokens derived from signed seeds.
//!
//! Each input picks a seed token (valid, expired, foreign issuer or audience, unknown key id, an
//! untrusted key under the trusted key id, `alg: none`, HMAC) and either mutates its characters,
//! splices segments from several seeds, or replaces it with raw text. Validation must never panic,
//! never fail harder than "no identity" while the JWKS is available, and return an identity only
//! for a token whose signed header and claims are exactly those of the valid seed. The seed and
//! case count are fixed so every run checks the same inputs; a shrunk failure becomes an example
//! test below.

use proptest::prelude::*;
use proptest::test_runner::{Config, RngSeed};

use super::validate_jwt_with;
use crate::test_support::{
    FixedClock, NOW, PUBLIC_KEY, check, identity_with, issuers, jwks, jwks_document, reheadered,
    seeds, token,
};

proptest! {
    #![proptest_config(Config {
        cases: 2_000,
        rng_seed: RngSeed::Fixed(0x6a77_745f_6675_7a7a),
        failure_persistence: None,
        ..Config::default()
    })]

    #[test]
    fn only_the_validly_signed_token_yields_an_identity(
        input in proptest::collection::vec(any::<u8>(), 0..=64),
    ) {
        let seeds = seeds();
        check(&token(&seeds.all, &input), &seeds, &issuers());
    }
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
            validate_jwt_with(token, &issuers, &FixedClock(NOW), |_| Ok(jwks()))
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

/// A key nobody can parse into an algorithm: jose 0.0.2 recursed on its `alg` until the stack
/// overflowed.
const UNKNOWN_ALGORITHM_KEY: &str = r#"{
    "kty": "OKP", "kid": "fixture-key", "crv": "Ed25519", "alg": "EdE3A",
    "x": "etkJX1EBhliHzBaimUQb0h2JhJKQ3G0beRVR3ssiedY"
}"#;

/// Authentik publishes each key with its certificate (`providers/oauth2/views/jwks.py`).
const KEY_WITH_CERTIFICATE: &str = r#"{
    "kty": "OKP", "kid": "fixture-key", "crv": "Ed25519", "alg": "EdDSA", "use": "sig",
    "x": "etkJX1EBhliHzBaimUQb0h2JhJKQ3G0beRVR3ssiedY",
    "x5c": ["AAECAwQ="],
    "x5t": "CJV2UCQq6OLdqP9jIUVaE9PlMno",
    "x5t#S256": "47DEQpj8HBSa-_TImW-5JCeuQeRkm5NMpJWZG3hSuFU"
}"#;

#[test]
fn a_key_published_with_its_certificate_verifies_tokens() {
    assert!(identity_with(&jwks_document(&[KEY_WITH_CERTIFICATE])));
}

#[test]
fn a_jwks_with_one_bad_key_still_verifies_tokens_signed_by_its_good_key() {
    assert!(identity_with(&jwks_document(&[
        UNKNOWN_ALGORITHM_KEY,
        PUBLIC_KEY
    ])));
}

#[test]
fn a_jwks_with_only_bad_keys_yields_no_identity() {
    let without_algorithm = r#"{
        "kty": "OKP", "kid": "fixture-key", "crv": "Ed25519",
        "x": "etkJX1EBhliHzBaimUQb0h2JhJKQ3G0beRVR3ssiedY"
    }"#;
    assert!(!identity_with(&jwks_document(&[
        UNKNOWN_ALGORITHM_KEY,
        without_algorithm
    ])));
}
