//! Configuration that defines which external identity issuers the NATS callout trusts.
//!
//! Configuration is part of the trust boundary, not application metadata. Each issuer binds an
//! exact issuer URL to its JWKS endpoint, accepted audiences, temporal policy, and NATS account.
//! Invalid or ambiguous configuration stops authentication setup instead of producing a broader
//! trust decision.

use std::{collections::HashSet, time::Duration};

use serde::Deserialize;
use url::Url;

#[derive(Debug)]
/// One complete external issuer trust declaration used during authentication.
pub struct IssuerConfig {
    pub(crate) id: String,
    pub(crate) issuer_url: Url,
    pub(crate) jwks_url: Url,
    pub(crate) audiences: HashSet<String>,
    pub(crate) require_expiration: bool,
    pub(crate) clock_skew: Duration,
    pub(crate) nats_account_key: String,
}

#[derive(Debug, Deserialize)]
struct RawIssuerConfig {
    id: String,
    issuer_url: String,
    jwks_url: String,
    audiences: Vec<String>,
    require_expiration: bool,
    clock_skew_seconds: i64,
    nats_account_key: String,
}

/// Parse and reject issuer configuration before it can influence authentication.
///
/// Duplicate issuer identifiers and duplicate audiences are rejected so selection remains
/// deterministic. URL, scheme, authority, and temporal checks reject unsafe or unusable trust
/// anchors as configuration errors.
pub fn parse_issuer_configs(config: &str) -> Result<Vec<IssuerConfig>, String> {
    let raw_configs: Vec<RawIssuerConfig> =
        serde_json::from_str(config).map_err(|error| error.to_string())?;
    let mut identifiers = HashSet::with_capacity(raw_configs.len());

    raw_configs
        .into_iter()
        .map(|raw| {
            if !identifiers.insert(raw.id.clone()) {
                return Err(format!("duplicate issuer identifier: {}", raw.id));
            }

            IssuerConfig::try_from(raw)
        })
        .collect()
}

impl TryFrom<RawIssuerConfig> for IssuerConfig {
    type Error = String;

    fn try_from(raw: RawIssuerConfig) -> Result<Self, Self::Error> {
        if raw.audiences.is_empty()
            || raw
                .audiences
                .iter()
                .any(|audience| audience.trim().is_empty())
        {
            return Err(format!(
                "issuer {} must configure at least one nonempty audience",
                raw.id
            ));
        }

        let audience_count = raw.audiences.len();
        let audiences: HashSet<_> = raw.audiences.into_iter().collect();
        if audiences.len() != audience_count {
            return Err(format!("issuer {} has duplicate audiences", raw.id));
        }

        let clock_skew_seconds = u64::try_from(raw.clock_skew_seconds)
            .map_err(|_| format!("issuer {} has negative clock_skew_seconds", raw.id))?;

        let issuer_url = Url::parse(&raw.issuer_url)
            .map_err(|error| format!("issuer {} has an invalid issuer_url: {error}", raw.id))?;
        let jwks_url = Url::parse(&raw.jwks_url)
            .map_err(|error| format!("issuer {} has an invalid jwks_url: {error}", raw.id))?;

        if !matches!(jwks_url.scheme(), "http" | "https") {
            return Err(format!(
                "issuer {} has an unsupported jwks_url scheme: {}",
                raw.id,
                jwks_url.scheme()
            ));
        }
        if jwks_url.host().is_none() {
            return Err(format!("issuer {} has no jwks_url authority", raw.id));
        }
        if jwks_url.fragment().is_some() {
            return Err(format!("issuer {} has a jwks_url fragment", raw.id));
        }

        Ok(Self {
            id: raw.id,
            issuer_url,
            jwks_url,
            audiences,
            require_expiration: raw.require_expiration,
            clock_skew: Duration::from_secs(clock_skew_seconds),
            nats_account_key: raw.nats_account_key,
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::test_support::{issuer_json as issuer, parse_issuers as parse};

    #[test]
    fn parses_typed_urls_and_duration() {
        let configs = parse(vec![issuer(serde_json::json!({}))]).expect("config is valid");
        let config = &configs[0];

        assert_eq!(
            config.issuer_url.as_str(),
            "https://issuer.example/application/panel/"
        );
        assert_eq!(
            config.jwks_url.as_str(),
            "https://keys.example:8443/jwks/keys?tenant=panel"
        );
        assert_eq!(config.clock_skew, Duration::from_secs(30));
    }

    #[test]
    fn rejects_duplicate_issuer_identifiers() {
        let error = parse(vec![
            issuer(serde_json::json!({})),
            issuer(serde_json::json!({ "issuer_url": "https://other.example/" })),
        ])
        .expect_err("duplicate identifiers must be rejected");

        assert!(error.contains("duplicate issuer identifier: panel"));
    }

    #[test]
    fn rejects_empty_audience_configuration() {
        let error = parse(vec![issuer(serde_json::json!({ "audiences": [] }))])
            .expect_err("empty audiences must be rejected");

        assert!(error.contains("at least one nonempty audience"));
    }

    #[test]
    fn rejects_negative_clock_skew() {
        let error = parse(vec![issuer(
            serde_json::json!({ "clock_skew_seconds": -1 }),
        )])
        .expect_err("negative skew must be rejected");

        assert!(error.contains("negative clock_skew_seconds"));
    }

    #[test]
    fn rejects_duplicate_audiences() {
        let error = parse(vec![issuer(serde_json::json!({
            "audiences": ["typewriter-panel", "typewriter-panel"]
        }))])
        .expect_err("duplicate audiences must be rejected");

        assert!(error.contains("duplicate audiences"));
    }

    #[test]
    fn rejects_unsupported_jwks_scheme() {
        let error = parse(vec![issuer(
            serde_json::json!({ "jwks_url": "ftp://keys.example/jwks" }),
        )])
        .expect_err("unsupported schemes must be rejected");

        assert!(error.contains("unsupported jwks_url scheme"));
    }

    #[test]
    fn rejects_jwks_fragment() {
        let error = parse(vec![issuer(
            serde_json::json!({ "jwks_url": "https://keys.example/jwks#keys" }),
        )])
        .expect_err("fragments must be rejected");

        assert!(error.contains("jwks_url fragment"));
    }
}
