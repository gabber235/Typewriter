use std::time::Duration;

use json_matcher::assert_jm;
use typewriter_component_test::{
    identity::{
        Authentik, RefusedRole, custom_role, expect_account_creation, host_role, issue_identity,
    },
    prelude::*,
};
use wasmcloud_utils::{
    skir::base::service::v1::{
        identity::IssueServiceIdentityResponse,
        service::{ServiceRole, ServiceRole_Host},
    },
    skir_variant,
};

use super::ServiceIdentity;

/// The services the identity component stored.
const SERVICES: &str = "SELECT id, role FROM service";

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
    context: &mut TestContext<ServiceIdentity>,
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

    let response = issue_identity(context, role).await?;

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
    assert_jm!(context.database()?.query_json(SERVICES).await?, []);
    Ok(())
}

#[component_test(ServiceIdentity)]
async fn host_identity_persists_credentials_and_role(
    context: &mut TestContext<ServiceIdentity>,
) -> TestResult {
    expect_account_creation(context, "fixture-service-uid", 314)?;

    let response = issue_identity(context, host_role()).await?;

    assert_eq!(response.status, http::StatusCode::OK);
    let IssueServiceIdentityResponse::Success(success) = response.body else {
        anyhow::bail!("expected an issued identity, received {:?}", response.body);
    };
    assert_eq!(success.service_id, "fixture-service-uid");
    assert_eq!(success.username, "fixture-user");
    assert_eq!(success.token, "issued-token");
    assert_jm!(context.database()?.query_json(SERVICES).await?, [{
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

    let response = issue_identity(context, host_role()).await?;

    assert_eq!(response.status, http::StatusCode::SERVICE_UNAVAILABLE);
    assert!(
        matches!(
            response.body,
            IssueServiceIdentityResponse::IdentityProviderUnavailableError(_)
        ),
        "{:?}",
        response.body
    );
    assert_jm!(context.database()?.query_json(SERVICES).await?, []);
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

    let response =
        tokio::time::timeout(Duration::from_secs(2), issue_identity(context, host_role()))
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
    assert_jm!(context.database()?.query_json(SERVICES).await?, []);
    Ok(())
}

#[component_test(ServiceIdentity)]
async fn persistence_failure_deletes_provisioned_account(
    context: &mut TestContext<ServiceIdentity>,
) -> TestResult {
    Seed::new().service("duplicate_uid").apply(context).await?;
    expect_account_creation(context, "duplicate_uid", 314)?;
    context
        .http_mock::<Authentik>()?
        .expect()
        .method(http::Method::DELETE)
        .path_query("/api/v3/core/users/314/")
        .status(http::StatusCode::NO_CONTENT)
        .register()?;

    let response = issue_identity(context, host_role()).await?;

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
