use std::time::Duration;

use component_test::{TestContext, TestResult, component_test};
use json_matcher::{JsonMatcher, assert_jm, create_json_matcher};
use typewriter_component_test::prelude::{DatabaseHandle, SkirHttpExt};
use wasmcloud_utils::{
    skir::base::service::v1::{
        identity::{IssueServiceIdentityRequest, IssueServiceIdentityResponse},
        service::{ServiceRole, ServiceRole_Custom, ServiceRole_Host},
    },
    skir_variant,
};

use super::{Authentik, ServiceIdentity};

fn host_role() -> ServiceRole {
    skir_variant!(ServiceRole::Host {
        version: "1.0.0".into(),
    })
}

fn request(role: ServiceRole) -> IssueServiceIdentityRequest {
    IssueServiceIdentityRequest {
        role,
        _unrecognized: None,
    }
}

fn expect_account_creation(
    context: &TestContext<ServiceIdentity>,
    user_uid: &str,
    user_pk: i64,
) -> TestResult {
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
    context: &TestContext<ServiceIdentity>,
    request: &IssueServiceIdentityRequest,
) -> anyhow::Result<typewriter_component_test::SkirHttpResponse<IssueServiceIdentityResponse>> {
    context
        .http()?
        .skir_post(
            "/service/identity/issue",
            request,
            IssueServiceIdentityRequest::serializer(),
            IssueServiceIdentityResponse::serializer(),
        )
        .await
}

#[component_test(ServiceIdentity)]
async fn built_in_custom_role_name_is_rejected(
    context: &mut TestContext<ServiceIdentity>,
) -> TestResult {
    let response = issue(
        context,
        &request(ServiceRole::Custom(Box::new(ServiceRole_Custom {
            name: "host".into(),
            version: "1.0.0".into(),
            _unrecognized: None,
        }))),
    )
    .await?;

    assert_eq!(response.status, http::StatusCode::BAD_REQUEST);
    assert!(matches!(
        response.body,
        IssueServiceIdentityResponse::BuiltinRoleNameForbiddenError(_)
    ));
    Ok(())
}

#[component_test(ServiceIdentity)]
async fn host_identity_persists_credentials_and_role(
    context: &mut TestContext<ServiceIdentity>,
) -> TestResult {
    expect_account_creation(context, "fixture-service-uid", 314)?;

    let response = issue(context, &request(host_role())).await?;

    assert_eq!(response.status, http::StatusCode::OK);
    let IssueServiceIdentityResponse::Success(success) = response.body else {
        anyhow::bail!("expected successful identity response");
    };
    assert_eq!(success.service_id, "fixture-service-uid");
    assert_eq!(success.username, "fixture-user");
    assert_eq!(success.token, "issued-token");

    let database = context
        .extension::<DatabaseHandle>()
        .ok_or_else(|| anyhow::anyhow!("database handle missing"))?;
    let services = database.query_json("SELECT id, role FROM service").await?;
    assert_jm!(services, [{
        "id": "service:`fixture-service-uid`",
        "role": { "type": "host", "version": "1.0.0" }
    }]);
    Ok(())
}

#[component_test(ServiceIdentity)]
async fn unavailable_provider_returns_service_unavailable_without_persistence(
    context: &mut TestContext<ServiceIdentity>,
) -> TestResult {
    context
        .http_mock::<Authentik>()?
        .expect()
        .post()
        .path_query("/api/v3/core/users/service_account/")
        .status(http::StatusCode::SERVICE_UNAVAILABLE)
        .register()?;

    let response = issue(context, &request(host_role())).await?;

    assert_eq!(response.status, http::StatusCode::SERVICE_UNAVAILABLE);
    assert!(matches!(
        response.body,
        IssueServiceIdentityResponse::IdentityProviderUnavailableError(_)
    ));
    let database = context
        .extension::<DatabaseHandle>()
        .ok_or_else(|| anyhow::anyhow!("database handle missing"))?;
    assert_jm!(database.query_json("SELECT * FROM service").await?, []);
    Ok(())
}

#[component_test(ServiceIdentity)]
async fn rejected_provider_response_returns_internal_error_without_persistence(
    context: &mut TestContext<ServiceIdentity>,
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

    let response = tokio::time::timeout(
        Duration::from_secs(2),
        issue(context, &request(host_role())),
    )
    .await
    .map_err(|_| {
        anyhow::anyhow!("identity response timed out after rejected provider response")
    })??;

    assert_eq!(response.status, http::StatusCode::INTERNAL_SERVER_ERROR);
    assert!(matches!(
        response.body,
        IssueServiceIdentityResponse::InternalError(_)
    ));
    let database = context
        .extension::<DatabaseHandle>()
        .ok_or_else(|| anyhow::anyhow!("database handle missing"))?;
    assert_jm!(database.query_json("SELECT * FROM service").await?, []);
    Ok(())
}

#[component_test(ServiceIdentity)]
async fn persistence_failure_deletes_provisioned_account(
    context: &mut TestContext<ServiceIdentity>,
) -> TestResult {
    let database = context
        .extension::<DatabaseHandle>()
        .ok_or_else(|| anyhow::anyhow!("database handle missing"))?;
    database
        .seed(
            "CREATE service:duplicate_uid SET name = 'existing', role = { type: 'host', version: '1.0.0' }",
        )
        .execute()
        .await?;
    expect_account_creation(context, "duplicate_uid", 314)?;
    context
        .http_mock::<Authentik>()?
        .expect()
        .method(http::Method::DELETE)
        .path_query("/api/v3/core/users/314/")
        .status(http::StatusCode::NO_CONTENT)
        .register()?;

    let response = issue(context, &request(host_role())).await?;

    assert_eq!(response.status, http::StatusCode::INTERNAL_SERVER_ERROR);
    assert!(matches!(
        response.body,
        IssueServiceIdentityResponse::InternalError(_)
    ));
    let services = database.query_json("SELECT id FROM service").await?;
    assert_jm!(services, [{ "id": "service:duplicate_uid" }]);
    Ok(())
}
