use std::time::Duration;

use json_matcher::{JsonMatcher, assert_jm, create_json_matcher};
use typewriter_component_test::{SkirHttpResponse, prelude::*};
use wasmcloud_utils::{
    skir::base::service::v1::{
        identity::{IssueServiceIdentityRequest, IssueServiceIdentityResponse},
        service::{ServiceRole, ServiceRole_Custom, ServiceRole_Host},
    },
    skir_variant,
};

use super::{Authentik, ServiceIdentity};

type Context = TestContext<ServiceIdentity>;

fn host_role() -> ServiceRole {
    skir_variant!(ServiceRole::Host {
        version: "1.0.0".into(),
    })
}

fn custom_role(name: &str) -> ServiceRole {
    skir_variant!(ServiceRole::Custom {
        name: name.into(),
        version: "1.0.0".into(),
    })
}

fn expect_account_creation(context: &Context, user_uid: &str, user_pk: i64) -> TestResult {
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

async fn issue(
    context: &Context,
    role: ServiceRole,
) -> anyhow::Result<SkirHttpResponse<IssueServiceIdentityResponse>> {
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

async fn services(context: &Context) -> anyhow::Result<serde_json::Value> {
    context
        .database()?
        .query_json("SELECT id, role FROM service")
        .await
}

/// A role the identity policy refuses before any account exists.
#[derive(Debug)]
enum RefusedRole {
    /// A role variant this component does not know.
    Unknown,
    /// A version that is not semantic.
    InvalidVersion,
    /// A custom role whose name is not a snake case identifier.
    InvalidCustomName,
    /// A custom role named like a built in role.
    BuiltinCustomName,
}

/// A refused role is rejected for its own reason, provisions no account and stores nothing.
///
/// The fixture registers no identity provider expectation, so provisioning an account fails the
/// case.
#[component_test(ServiceIdentity)]
#[case::unknown_role(RefusedRole::Unknown)]
#[case::invalid_version(RefusedRole::InvalidVersion)]
#[case::invalid_custom_name(RefusedRole::InvalidCustomName)]
#[case::builtin_custom_name(RefusedRole::BuiltinCustomName)]
async fn refused_role_is_rejected_without_an_account(
    context: &mut Context,
    refused: RefusedRole,
) -> TestResult {
    let role = match refused {
        RefusedRole::Unknown => ServiceRole::Unknown(None),
        RefusedRole::InvalidVersion => skir_variant!(ServiceRole::Host {
            version: "latest".into(),
        }),
        RefusedRole::InvalidCustomName => custom_role("Not An Id"),
        RefusedRole::BuiltinCustomName => custom_role("host"),
    };

    let response = issue(context, role).await?;

    let rejected_for_its_reason = matches!(
        (&refused, &response.body),
        (
            RefusedRole::Unknown,
            IssueServiceIdentityResponse::UnknownRoleError(_)
        ) | (
            RefusedRole::InvalidVersion,
            IssueServiceIdentityResponse::RoleVersionInvalidError(_)
        ) | (
            RefusedRole::InvalidCustomName,
            IssueServiceIdentityResponse::CustomRoleNameInvalidError(_)
        ) | (
            RefusedRole::BuiltinCustomName,
            IssueServiceIdentityResponse::BuiltinRoleNameForbiddenError(_)
        )
    );
    assert!(
        rejected_for_its_reason,
        "{refused:?} was not rejected for its reason: {:?}",
        response.body
    );
    assert_eq!(response.status, http::StatusCode::BAD_REQUEST);
    assert_jm!(services(context).await?, []);
    Ok(())
}

#[component_test(ServiceIdentity)]
async fn host_identity_persists_credentials_and_role(context: &mut Context) -> TestResult {
    expect_account_creation(context, "fixture-service-uid", 314)?;

    let response = issue(context, host_role()).await?;

    assert_eq!(response.status, http::StatusCode::OK);
    let IssueServiceIdentityResponse::Success(success) = response.body else {
        anyhow::bail!("expected an issued identity, received {:?}", response.body);
    };
    assert_eq!(success.service_id, "fixture-service-uid");
    assert_eq!(success.username, "fixture-user");
    assert_eq!(success.token, "issued-token");
    assert_jm!(services(context).await?, [{
        "id": "service:`fixture-service-uid`",
        "role": { "type": "host", "version": "1.0.0" }
    }]);
    Ok(())
}

#[component_test(ServiceIdentity)]
async fn unavailable_provider_returns_service_unavailable_without_persistence(
    context: &mut Context,
) -> TestResult {
    context
        .http_mock::<Authentik>()?
        .expect()
        .post()
        .path_query("/api/v3/core/users/service_account/")
        .status(http::StatusCode::SERVICE_UNAVAILABLE)
        .register()?;

    let response = issue(context, host_role()).await?;

    assert_eq!(response.status, http::StatusCode::SERVICE_UNAVAILABLE);
    assert!(
        matches!(
            response.body,
            IssueServiceIdentityResponse::IdentityProviderUnavailableError(_)
        ),
        "{:?}",
        response.body
    );
    assert_jm!(services(context).await?, []);
    Ok(())
}

#[component_test(ServiceIdentity)]
async fn rejected_provider_response_returns_internal_error_without_persistence(
    context: &mut Context,
) -> TestResult {
    context
        .http_mock::<Authentik>()?
        .expect()
        .post()
        .path_query("/api/v3/core/users/service_account/")
        .status(http::StatusCode::BAD_REQUEST)
        .response_json(&serde_json::json!({
            "non_field_errors": ["Unable to create user"]
        }))?
        .register()?;

    let response = tokio::time::timeout(Duration::from_secs(2), issue(context, host_role()))
        .await
        .map_err(|_| {
            anyhow::anyhow!("identity response timed out after rejected provider response")
        })??;

    assert_eq!(response.status, http::StatusCode::INTERNAL_SERVER_ERROR);
    assert!(
        matches!(
            response.body,
            IssueServiceIdentityResponse::InternalError(_)
        ),
        "{:?}",
        response.body
    );
    assert_jm!(services(context).await?, []);
    Ok(())
}

#[component_test(ServiceIdentity)]
async fn persistence_failure_deletes_provisioned_account(context: &mut Context) -> TestResult {
    Seed::new()
        .service("duplicate_uid")
        .apply(&context.database()?)
        .await?;
    expect_account_creation(context, "duplicate_uid", 314)?;
    context
        .http_mock::<Authentik>()?
        .expect()
        .method(http::Method::DELETE)
        .path_query("/api/v3/core/users/314/")
        .status(http::StatusCode::NO_CONTENT)
        .register()?;

    let response = issue(context, host_role()).await?;

    assert_eq!(response.status, http::StatusCode::INTERNAL_SERVER_ERROR);
    assert!(
        matches!(
            response.body,
            IssueServiceIdentityResponse::InternalError(_)
        ),
        "{:?}",
        response.body
    );
    assert_jm!(
        context.database()?.query_json("SELECT id FROM service").await?,
        [{ "id": "service:duplicate_uid" }]
    );
    Ok(())
}
