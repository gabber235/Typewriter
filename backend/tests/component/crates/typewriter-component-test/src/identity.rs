//! Service identity: the identity provider Authentik as the identity component reaches it, the
//! roles a service asks for, and the request that issues a service its identity.

use anyhow::Result;
use component_test::TestContext;
use json_matcher::{JsonMatcher as _, create_json_matcher};
use wasmcloud_utils::{
    skir::base::service::v1::{
        identity::{IssueServiceIdentityRequest, IssueServiceIdentityResponse},
        service::{ServiceRole, ServiceRole_Custom, ServiceRole_Host},
    },
    skir_variant,
};

use crate::{SkirHttpExt, SkirHttpResponse};

/// The identity provider. A fixture names its outgoing HTTP with `outgoing_http::<Authentik>`
/// and hands the component the token `fixture-token`.
pub struct Authentik;

/// Authentik is asked once, with the fixture's token, for a service account that never expires
/// and joins no group, and creates it as `user_uid` with the primary key `user_pk`.
pub fn expect_account_creation<F>(
    context: &TestContext<F>,
    user_uid: &str,
    user_pk: i64,
) -> Result<()> {
    context
        .http_mock::<Authentik>()?
        .expect()
        .post()
        .path_query("/api/v3/core/users/service_account/")
        .header(
            http::header::AUTHORIZATION,
            http::HeaderValue::from_static("Bearer fixture-token"),
        )
        .body_matches(|body| {
            let Ok(json) = serde_json::from_slice::<serde_json::Value>(body) else {
                return false;
            };
            create_json_matcher!({
                "create_group": false,
                "expiring": false
            })
            .allow_unexpected_keys()
            .json_matches(&json)
            .is_empty()
        })
        .response_json(&serde_json::json!({
            "username": "fixture-user",
            "token": "issued-token",
            "user_uid": user_uid,
            "user_pk": user_pk
        }))?
        .register()?;
    Ok(())
}

/// The host role at version `1.0.0`.
pub fn host_role() -> ServiceRole {
    skir_variant!(ServiceRole::Host {
        version: "1.0.0".into(),
    })
}

/// The custom role `name` at version `1.0.0`.
pub fn custom_role(name: &str) -> ServiceRole {
    skir_variant!(ServiceRole::Custom {
        name: name.into(),
        version: "1.0.0".into(),
    })
}

/// A new service asks the identity component for an identity with `role`.
pub async fn issue_identity<F>(
    context: &TestContext<F>,
    role: ServiceRole,
) -> Result<SkirHttpResponse<IssueServiceIdentityResponse>> {
    context
        .http()?
        .skir_post(
            "/service/identity/issue",
            &IssueServiceIdentityRequest {
                role,
                ..Default::default()
            },
        )
        .await
}

/// A role the identity policy refuses before any account exists.
#[derive(Debug)]
pub enum RefusedRole {
    /// A role variant the component does not know.
    Unknown,
    /// A version that is not semantic.
    InvalidVersion,
    /// A custom role whose name is not a snake case identifier.
    InvalidCustomName,
    /// A custom role named like a built in role.
    BuiltinCustomName,
}
