use std::time::Duration;

use json_matcher::assert_jm;
use typewriter_component_test::{
    prelude::*,
    service::{ensure_registration_lease, seed_organization_services, seed_registration_lease},
};
use wasmcloud_utils::skir::base::service::v1::status::{
    EnsureRegistrationLeaseResponse, QueryServiceBindingRequest, QueryServiceBindingResponse,
    ServiceBinding,
};

use super::ServiceRegistration;

/// The registration token `lobby` already holds.
const TOKEN: &str = "ABCDEFGHIJ";
/// A lease within the two minutes in which the component renews it.
const EXPIRING: Duration = Duration::from_secs(60);
/// A lease beyond the renewal window.
const HEALTHY: Duration = Duration::from_secs(180);
/// The registration lease `lobby` holds.
const REGISTRATION: &str = "SELECT VALUE registration FROM ONLY service:lobby";

#[component_test(ServiceRegistration)]
async fn unknown_service_returns_not_found(
    context: &mut TestContext<ServiceRegistration>,
) -> TestResult {
    let reply: QueryServiceBindingResponse = context
        .request(
            from_service("missing", "binding.query"),
            &QueryServiceBindingRequest::default(),
        )
        .await?;

    assert!(
        matches!(reply, QueryServiceBindingResponse::ServiceNotFoundError(_)),
        "{reply:?}"
    );
    Ok(())
}

#[component_test(ServiceRegistration)]
async fn unbound_service_receives_persisted_registration_token(
    context: &mut TestContext<ServiceRegistration>,
) -> TestResult {
    let database = context.database()?;
    Seed::new().service("lobby").apply(context).await?;

    let reply = ensure_registration_lease(context, "lobby").await?;

    let EnsureRegistrationLeaseResponse::Issued(lease) = reply else {
        anyhow::bail!("expected an issued registration lease, received {reply:?}");
    };
    assert_eq!(lease.token.len(), 10);
    assert!(
        lease
            .token
            .chars()
            .all(|character| character.is_ascii_uppercase() || character.is_ascii_digit()),
        "{}",
        lease.token
    );
    assert_eq!(
        database
            .query_json("SELECT VALUE [registration.token, registration.expires_at > time::now()] FROM ONLY service:lobby")
            .await?,
        serde_json::json!([lease.token, true])
    );
    Ok(())
}

#[component_test(ServiceRegistration)]
async fn expiring_registration_token_is_reused_and_lease_is_renewed(
    context: &mut TestContext<ServiceRegistration>,
) -> TestResult {
    let database = context.database()?;
    seed_registration_lease(context, "lobby", TOKEN, EXPIRING).await?;

    let reply = ensure_registration_lease(context, "lobby").await?;

    let EnsureRegistrationLeaseResponse::Issued(lease) = reply else {
        anyhow::bail!("expected an issued registration lease, received {reply:?}");
    };
    assert_eq!(lease.token, TOKEN);
    assert_jm!(
        database
            .query_json(
                "SELECT VALUE registration.expires_at > time::now() + 2m FROM ONLY service:lobby",
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
    let database = context.database()?;
    seed_registration_lease(context, "lobby", TOKEN, HEALTHY).await?;
    let before = database.query_json(REGISTRATION).await?;

    let reply = ensure_registration_lease(context, "lobby").await?;

    let EnsureRegistrationLeaseResponse::Issued(lease) = reply else {
        anyhow::bail!("expected an issued registration lease, received {reply:?}");
    };
    assert_eq!(lease.token, TOKEN);
    assert_eq!(database.query_json(REGISTRATION).await?, before);
    Ok(())
}

#[component_test(ServiceRegistration)]
async fn repeated_binding_reads_leave_registration_unchanged(
    context: &mut TestContext<ServiceRegistration>,
) -> TestResult {
    let database = context.database()?;
    seed_registration_lease(context, "lobby", TOKEN, HEALTHY).await?;
    let before = database.query_json(REGISTRATION).await?;

    for _ in 0..2 {
        let reply: QueryServiceBindingResponse = context
            .request(
                from_service("lobby", "binding.query"),
                &QueryServiceBindingRequest::default(),
            )
            .await?;
        assert!(
            matches!(&reply, QueryServiceBindingResponse::Binding(binding)
                if matches!(binding.binding, ServiceBinding::Unbound)),
            "{reply:?}"
        );
    }

    assert_eq!(database.query_json(REGISTRATION).await?, before);
    Ok(())
}

#[component_test(ServiceRegistration)]
async fn bound_service_returns_organization_without_registration_token(
    context: &mut TestContext<ServiceRegistration>,
) -> TestResult {
    let database = context.database()?;
    seed_organization_services(context, &acme(), ada(), &["lobby"]).await?;

    let reply: QueryServiceBindingResponse = context
        .request(
            from_service("lobby", "binding.query"),
            &QueryServiceBindingRequest::default(),
        )
        .await?;

    let QueryServiceBindingResponse::Binding(binding) = reply else {
        anyhow::bail!("expected a binding, received {reply:?}");
    };
    let ServiceBinding::Bound(bound) = binding.binding else {
        anyhow::bail!("expected a bound service, received {:?}", binding.binding);
    };
    assert_eq!(bound.organization_id, "acme");
    assert_eq!(bound.organization_name.as_deref(), Some("acme"));
    let reply = ensure_registration_lease(context, "lobby").await?;
    let EnsureRegistrationLeaseResponse::AlreadyBound(already_bound) = reply else {
        anyhow::bail!("expected an already bound reply, received {reply:?}");
    };
    assert_eq!(already_bound.organization_id, "acme");
    assert_jm!(database.query_json(REGISTRATION).await?, null);
    Ok(())
}
