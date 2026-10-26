use std::time::Duration;

use json_matcher::assert_jm;
use typewriter_component_test::prelude::*;
use wasmcloud_utils::skir::base::service::v1::status::{
    EnsureRegistrationLeaseRequest, EnsureRegistrationLeaseResponse, QueryServiceBindingRequest,
    QueryServiceBindingResponse, ServiceBinding,
};

use super::{Context, ServiceRegistration, from_service};

/// A lease within the two minutes in which the component renews it.
const EXPIRING: Duration = Duration::from_secs(60);
/// A lease beyond the renewal window.
const HEALTHY: Duration = Duration::from_secs(180);

async fn query_binding(
    context: &Context,
    key: &str,
) -> anyhow::Result<QueryServiceBindingResponse> {
    context
        .request(
            from_service(key, "binding.query"),
            &QueryServiceBindingRequest::default(),
        )
        .await
}

async fn ensure_lease(
    context: &Context,
    key: &str,
) -> anyhow::Result<EnsureRegistrationLeaseResponse> {
    context
        .request(
            from_service(key, "registration.ensure"),
            &EnsureRegistrationLeaseRequest::default(),
        )
        .await
}

/// The unbound service `lobby` with a lease far from expiry; returns its registration.
async fn lobby_with_healthy_lease(context: &Context) -> anyhow::Result<serde_json::Value> {
    let database = context.database()?;
    Seed::new()
        .service("lobby")
        .registration_lease("lobby", "ABCDEFGHIJ", HEALTHY)
        .apply(&database)
        .await?;
    registration(&database).await
}

async fn registration(database: &DatabaseHandle) -> anyhow::Result<serde_json::Value> {
    database
        .query_json("SELECT VALUE registration FROM ONLY service:lobby")
        .await
}

#[component_test(ServiceRegistration)]
async fn unknown_service_returns_not_found(context: &mut Context) -> TestResult {
    let reply = query_binding(context, "missing").await?;

    assert!(
        matches!(reply, QueryServiceBindingResponse::ServiceNotFoundError(_)),
        "{reply:?}"
    );
    Ok(())
}

#[component_test(ServiceRegistration)]
async fn unbound_service_receives_persisted_registration_token(
    context: &mut Context,
) -> TestResult {
    let database = context.database()?;
    Seed::new().service("lobby").apply(&database).await?;

    let reply = ensure_lease(context, "lobby").await?;

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
    context: &mut Context,
) -> TestResult {
    let database = context.database()?;
    Seed::new()
        .service("lobby")
        .registration_lease("lobby", "ABCDEFGHIJ", EXPIRING)
        .apply(&database)
        .await?;

    let reply = ensure_lease(context, "lobby").await?;

    let EnsureRegistrationLeaseResponse::Issued(lease) = reply else {
        anyhow::bail!("expected an issued registration lease, received {reply:?}");
    };
    assert_eq!(lease.token, "ABCDEFGHIJ");
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
async fn healthy_registration_lease_is_not_rewritten(context: &mut Context) -> TestResult {
    let database = context.database()?;
    let before = lobby_with_healthy_lease(context).await?;

    let reply = ensure_lease(context, "lobby").await?;

    let EnsureRegistrationLeaseResponse::Issued(lease) = reply else {
        anyhow::bail!("expected an issued registration lease, received {reply:?}");
    };
    assert_eq!(lease.token, "ABCDEFGHIJ");
    assert_eq!(registration(&database).await?, before);
    Ok(())
}

#[component_test(ServiceRegistration)]
async fn repeated_binding_reads_leave_registration_unchanged(context: &mut Context) -> TestResult {
    let database = context.database()?;
    let before = lobby_with_healthy_lease(context).await?;

    for _ in 0..2 {
        let reply = query_binding(context, "lobby").await?;
        assert!(
            matches!(&reply, QueryServiceBindingResponse::Binding(binding)
                if matches!(binding.binding, ServiceBinding::Unbound)),
            "{reply:?}"
        );
    }

    assert_eq!(registration(&database).await?, before);
    Ok(())
}

#[component_test(ServiceRegistration)]
async fn bound_service_returns_organization_without_registration_token(
    context: &mut Context,
) -> TestResult {
    let database = context.database()?;
    Seed::new()
        .organization(&acme(), ada())
        .organization_service(&acme(), "lobby")
        .apply(&database)
        .await?;

    let reply = query_binding(context, "lobby").await?;

    let QueryServiceBindingResponse::Binding(binding) = reply else {
        anyhow::bail!("expected a binding, received {reply:?}");
    };
    let ServiceBinding::Bound(bound) = binding.binding else {
        anyhow::bail!("expected a bound service, received {:?}", binding.binding);
    };
    assert_eq!(bound.organization_id, "acme");
    assert_eq!(bound.organization_name.as_deref(), Some("acme"));
    let reply = ensure_lease(context, "lobby").await?;
    let EnsureRegistrationLeaseResponse::AlreadyBound(already_bound) = reply else {
        anyhow::bail!("expected an already bound reply, received {reply:?}");
    };
    assert_eq!(already_bound.organization_id, "acme");
    assert_jm!(
        database
            .query_json("SELECT VALUE registration FROM ONLY service:lobby")
            .await?,
        null
    );
    Ok(())
}
