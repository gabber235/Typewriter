use component_test::{TestContext, TestResult, component_test};
use json_matcher::assert_jm;
use wasmcloud_utils::skir::base::service::v1::status::{
    GetServiceStatusRequest, GetServiceStatusResponse, ServiceBinding,
};

use super::{ServiceRegistration, database, request};

async fn get_status(
    context: &TestContext<ServiceRegistration>,
    service_id: &str,
) -> anyhow::Result<GetServiceStatusResponse> {
    request(
        context,
        &format!("typewriter.from.service.{service_id}.status"),
        &GetServiceStatusRequest::default(),
        GetServiceStatusRequest::serializer(),
        GetServiceStatusResponse::serializer(),
    )
    .await
}

#[component_test(ServiceRegistration)]
async fn unknown_service_returns_not_found(
    context: &mut TestContext<ServiceRegistration>,
) -> TestResult {
    let response = get_status(context, "missing").await?;

    assert!(matches!(
        response,
        GetServiceStatusResponse::ServiceNotFoundError(_)
    ));
    Ok(())
}

#[component_test(ServiceRegistration)]
async fn unbound_service_receives_persisted_registration_token(
    context: &mut TestContext<ServiceRegistration>,
) -> TestResult {
    let database = database(context)?;
    database
        .seed(
            "CREATE service:unbound SET name = 'unbound', roles = [{ type: 'engine', version: '1' }]",
        )
        .execute()
        .await?;

    let response = get_status(context, "unbound").await?;

    let GetServiceStatusResponse::Status(status) = response else {
        anyhow::bail!("expected service status response");
    };
    let ServiceBinding::Unbound(binding) = status.binding else {
        anyhow::bail!("expected unbound service response");
    };
    let token = binding
        .registration_token
        .ok_or_else(|| anyhow::anyhow!("registration token missing"))?;
    assert_eq!(token.len(), 10);
    assert!(
        token
            .chars()
            .all(|character| character.is_ascii_uppercase() || character.is_ascii_digit())
    );
    let stored = database
        .query_json("SELECT registration.token AS token, registration.expires_at AS expires_at FROM ONLY service:unbound")
        .await?;
    assert_eq!(
        stored.get("token").and_then(serde_json::Value::as_str),
        Some(token.as_str())
    );
    assert!(
        stored
            .get("expires_at")
            .is_some_and(|value| !value.is_null())
    );
    Ok(())
}

#[component_test(ServiceRegistration)]
async fn unexpired_registration_token_is_reused(
    context: &mut TestContext<ServiceRegistration>,
) -> TestResult {
    let database = database(context)?;
    database
        .seed(
            "CREATE service:unbound SET name = 'unbound', roles = [{ type: 'engine', version: '1' }], registration = { token: 'ABCDEFGHIJ', expires_at: time::now() + 1m }",
        )
        .execute()
        .await?;

    let response = get_status(context, "unbound").await?;

    let GetServiceStatusResponse::Status(status) = response else {
        anyhow::bail!("expected service status response");
    };
    let ServiceBinding::Unbound(binding) = status.binding else {
        anyhow::bail!("expected unbound service response");
    };
    assert_eq!(binding.registration_token.as_deref(), Some("ABCDEFGHIJ"));
    Ok(())
}

#[component_test(ServiceRegistration)]
async fn bound_service_returns_organization_without_registration_token(
    context: &mut TestContext<ServiceRegistration>,
) -> TestResult {
    let database = database(context)?;
    database
        .seed(
            "CREATE user:actor SET name = 'actor'; CREATE organization:test_org SET name = 'test_org', founder = user:actor; CREATE service:bound SET name = 'bound', roles = [{ type: 'engine', version: '1' }], organization = organization:test_org",
        )
        .execute()
        .await?;

    let response = get_status(context, "bound").await?;

    let GetServiceStatusResponse::Status(status) = response else {
        anyhow::bail!("expected service status response");
    };
    let ServiceBinding::Bound(binding) = status.binding else {
        anyhow::bail!("expected bound service response");
    };
    assert_eq!(binding.organization_id, "test_org");
    assert_eq!(binding.organization_name.as_deref(), Some("test_org"));
    assert_jm!(
        database
            .query_json("SELECT VALUE registration FROM ONLY service:bound")
            .await?,
        null
    );
    Ok(())
}
