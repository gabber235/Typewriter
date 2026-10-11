use component_test::{TestContext, TestResult, component_test};
use json_matcher::assert_jm;
use wasmcloud_utils::skir::base::service::v1::status::{
    EnsureRegistrationLeaseRequest, EnsureRegistrationLeaseResponse, QueryServiceBindingRequest,
    QueryServiceBindingResponse, ServiceBinding,
};

use super::{ServiceRegistration, database, request};

#[component_test(ServiceRegistration)]
async fn unmatched_route_is_rejected(context: &mut TestContext<ServiceRegistration>) -> TestResult {
    let database = database(context)?;
    let before = database.query_json("SELECT * FROM service").await?;
    let messaging = context.messaging()?;
    messaging
        .publish(
            "typewriter.from.service.unmatched.execution.unknown",
            Vec::new(),
        )
        .await?;
    messaging.wait_idle().await?;
    let span = context
        .wait_for_span("handle-message", std::time::Duration::from_secs(2))
        .await?;
    assert!(span.attributes.iter().any(|attribute| {
        attribute.key.as_str() == "exception.slug"
            && attribute.value.to_string() == "dispatch-action-unknown"
    }));
    assert_eq!(database.query_json("SELECT * FROM service").await?, before);
    Ok(())
}

async fn query_binding(
    context: &TestContext<ServiceRegistration>,
    service_id: &str,
) -> anyhow::Result<QueryServiceBindingResponse> {
    request(
        context,
        &format!("typewriter.from.service.{service_id}.binding.query"),
        &QueryServiceBindingRequest::default(),
        QueryServiceBindingRequest::serializer(),
        QueryServiceBindingResponse::serializer(),
    )
    .await
}

async fn ensure_lease(
    context: &TestContext<ServiceRegistration>,
    service_id: &str,
) -> anyhow::Result<EnsureRegistrationLeaseResponse> {
    request(
        context,
        &format!("typewriter.from.service.{service_id}.registration.ensure"),
        &EnsureRegistrationLeaseRequest::default(),
        EnsureRegistrationLeaseRequest::serializer(),
        EnsureRegistrationLeaseResponse::serializer(),
    )
    .await
}

#[component_test(ServiceRegistration)]
async fn unknown_service_returns_not_found(
    context: &mut TestContext<ServiceRegistration>,
) -> TestResult {
    let response = query_binding(context, "missing").await?;

    assert!(matches!(
        response,
        QueryServiceBindingResponse::ServiceNotFoundError(_)
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
            "CREATE service:unbound SET name = 'unbound', role = { type: 'host', version: '1.0.0' }",
        )
        .execute()
        .await?;

    let response = ensure_lease(context, "unbound").await?;

    let EnsureRegistrationLeaseResponse::Issued(lease) = response else {
        anyhow::bail!("expected issued registration lease");
    };
    let token = lease.token;
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
async fn expiring_registration_token_is_reused_and_lease_is_renewed(
    context: &mut TestContext<ServiceRegistration>,
) -> TestResult {
    let database = database(context)?;
    database
        .seed(
            "CREATE service:unbound SET name = 'unbound', role = { type: 'host', version: '1.0.0' }, registration = { token: 'ABCDEFGHIJ', expires_at: time::now() + 1m }",
        )
        .execute()
        .await?;

    let response = ensure_lease(context, "unbound").await?;

    let EnsureRegistrationLeaseResponse::Issued(lease) = response else {
        anyhow::bail!("expected issued registration lease");
    };
    assert_eq!(lease.token, "ABCDEFGHIJ");
    assert_jm!(
        database
            .query_json(
                "SELECT VALUE registration.expires_at > time::now() + 2m FROM ONLY service:unbound",
            )
            .await?,
        true
    );
    Ok(())
}

#[component_test(ServiceRegistration)]
async fn healthy_registration_lease_is_not_rewritten(
    context: &mut TestContext<ServiceRegistration>,
) -> TestResult {
    let database = database(context)?;
    database
        .seed(
            "CREATE service:unbound SET name = 'unbound', role = { type: 'host', version: '1.0.0' }, registration = { token: 'ABCDEFGHIJ', expires_at: time::now() + 3m }",
        )
        .execute()
        .await?;
    let before = database
        .query_json("SELECT VALUE registration.expires_at FROM ONLY service:unbound")
        .await?;

    let response = ensure_lease(context, "unbound").await?;

    let EnsureRegistrationLeaseResponse::Issued(lease) = response else {
        anyhow::bail!("expected issued registration lease");
    };
    assert_eq!(lease.token, "ABCDEFGHIJ");
    let after = database
        .query_json("SELECT VALUE registration.expires_at FROM ONLY service:unbound")
        .await?;
    assert_eq!(after, before);
    Ok(())
}

#[component_test(ServiceRegistration)]
async fn repeated_binding_reads_leave_registration_unchanged(
    context: &mut TestContext<ServiceRegistration>,
) -> TestResult {
    let database = database(context)?;
    database
        .seed(
            "CREATE service:unbound SET name = 'unbound', role = { type: 'host', version: '1.0.0' }, registration = { token: 'ABCDEFGHIJ', expires_at: time::now() + 3m }",
        )
        .execute()
        .await?;
    let before = database
        .query_json("SELECT VALUE registration FROM ONLY service:unbound")
        .await?;

    for _ in 0..2 {
        let QueryServiceBindingResponse::Binding(binding) =
            query_binding(context, "unbound").await?
        else {
            anyhow::bail!("expected binding response");
        };
        assert!(matches!(binding.binding, ServiceBinding::Unbound));
    }

    let after = database
        .query_json("SELECT VALUE registration FROM ONLY service:unbound")
        .await?;
    assert_eq!(after, before);
    Ok(())
}

#[component_test(ServiceRegistration)]
async fn bound_service_returns_organization_without_registration_token(
    context: &mut TestContext<ServiceRegistration>,
) -> TestResult {
    let database = database(context)?;
    database
        .seed(
            "CREATE user:actor SET name = 'actor'; CREATE organization:test_org SET name = 'test_org', founder = user:actor; CREATE service:bound SET name = 'bound', role = { type: 'host', version: '1.0.0' }, organization = organization:test_org",
        )
        .execute()
        .await?;

    let response = query_binding(context, "bound").await?;

    let QueryServiceBindingResponse::Binding(binding) = response else {
        anyhow::bail!("expected binding response");
    };
    let ServiceBinding::Bound(binding) = binding.binding else {
        anyhow::bail!("expected bound service response");
    };
    assert_eq!(binding.organization_id, "test_org");
    assert_eq!(binding.organization_name.as_deref(), Some("test_org"));
    let EnsureRegistrationLeaseResponse::AlreadyBound(already_bound) =
        ensure_lease(context, "bound").await?
    else {
        anyhow::bail!("expected already bound response");
    };
    assert_eq!(already_bound.organization_id, "test_org");
    assert_jm!(
        database
            .query_json("SELECT VALUE registration FROM ONLY service:bound")
            .await?,
        null
    );
    Ok(())
}
