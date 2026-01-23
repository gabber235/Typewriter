//! Integration tests for the service heartbeat handler.

use anyhow::Result;
use backend_tests::proto::typewriter::api::v1::{
    list_organization_services_response, ListOrganizationServicesResponse, ServiceHeartbeatRequest,
};
use backend_tests::{get_fixtures, OrganizationBuilder, ServiceBuilder, TestNatsClient};
use futures::StreamExt;
use prost::Message;
use repeated_assert::that_async;
use std::time::Duration;
use surrealdb::sql::Datetime;
use surrealdb::Surreal;

#[derive(Debug, Clone, serde::Deserialize)]
struct ServiceState {
    status: Option<String>,
    last_seen: Option<Datetime>,
}

#[derive(Debug, Clone, serde::Deserialize)]
struct ServiceStateCheck {
    state: Option<ServiceState>,
}

async fn get_state(
    db: &Surreal<surrealdb::engine::any::Any>,
    service_id: &str,
) -> Option<ServiceState> {
    let check: Option<ServiceStateCheck> = db.select(("service", service_id)).await.ok().flatten();
    check.and_then(|c| c.state)
}

async fn get_last_seen(
    db: &Surreal<surrealdb::engine::any::Any>,
    service_id: &str,
) -> Option<Datetime> {
    get_state(db, service_id).await.and_then(|s| s.last_seen)
}

#[allow(dead_code)]
async fn get_status(
    db: &Surreal<surrealdb::engine::any::Any>,
    service_id: &str,
) -> Option<String> {
    get_state(db, service_id).await.and_then(|s| s.status)
}

#[tokio::test]
async fn test_heartbeat_updates_last_seen_timestamp() -> Result<()> {
    let fixtures = get_fixtures().await;
    let nats = TestNatsClient::new(fixtures.infra.nats_client());

    let org = OrganizationBuilder::new("heartbeat_org")
        .create(&fixtures.infra.db)
        .await?;

    let service = ServiceBuilder::new("heartbeat_service")
        .service_type("engine")
        .organization(&org)
        .create(&fixtures.infra.db)
        .await?;

    let before = get_state(&fixtures.infra.db, &service.id).await;
    assert!(
        before.is_none(),
        "state should be None before heartbeat"
    );

    let subject = format!("typewriter.in.service.{}.heartbeat", service.id);
    let request = ServiceHeartbeatRequest {};
    nats.publish(&subject, &request).await?;

    let db = fixtures.infra.db.clone();
    let service_id = service.id.clone();
    that_async(20, Duration::from_millis(50), || {
        let db = db.clone();
        let service_id = service_id.clone();
        async move {
            let state = get_state(&db, &service_id).await;
            assert!(state.is_some(), "state should be set after heartbeat");
            let state = state.unwrap();
            assert_eq!(
                state.status.as_deref(),
                Some("ONLINE"),
                "status should be ONLINE after heartbeat"
            );
            assert!(
                state.last_seen.is_some(),
                "last_seen should be set after heartbeat"
            );
        }
    })
    .await;

    Ok(())
}

#[tokio::test]
async fn test_heartbeat_updates_last_seen_to_recent_time() -> Result<()> {
    let fixtures = get_fixtures().await;
    let nats = TestNatsClient::new(fixtures.infra.nats_client());

    let org = OrganizationBuilder::new("heartbeat_recent_org")
        .create(&fixtures.infra.db)
        .await?;

    let service = ServiceBuilder::new("heartbeat_recent_service")
        .service_type("realm")
        .organization(&org)
        .create(&fixtures.infra.db)
        .await?;

    let before_heartbeat = chrono::Utc::now();

    let subject = format!("typewriter.in.service.{}.heartbeat", service.id);
    let request = ServiceHeartbeatRequest {};
    nats.publish(&subject, &request).await?;

    let db = fixtures.infra.db.clone();
    let service_id = service.id.clone();
    that_async(20, Duration::from_millis(50), || {
        let db = db.clone();
        let service_id = service_id.clone();
        async move {
            let state = get_state(&db, &service_id).await;
            assert!(state.is_some(), "state should be set");
        }
    })
    .await;

    let after_heartbeat = chrono::Utc::now();

    let state = get_state(&fixtures.infra.db, &service.id)
        .await
        .expect("state should be set");

    assert_eq!(
        state.status.as_deref(),
        Some("ONLINE"),
        "status should be ONLINE"
    );

    let last_seen = state.last_seen.expect("last_seen should be set");
    let last_seen_time = last_seen.0;
    assert!(
        last_seen_time >= before_heartbeat && last_seen_time <= after_heartbeat,
        "last_seen ({:?}) should be between {:?} and {:?}",
        last_seen_time,
        before_heartbeat,
        after_heartbeat
    );

    Ok(())
}

#[tokio::test]
async fn test_multiple_heartbeats_update_last_seen() -> Result<()> {
    let fixtures = get_fixtures().await;
    let nats = TestNatsClient::new(fixtures.infra.nats_client());

    let org = OrganizationBuilder::new("heartbeat_multi_org")
        .create(&fixtures.infra.db)
        .await?;

    let service = ServiceBuilder::new("heartbeat_multi_service")
        .service_type("engine")
        .organization(&org)
        .create(&fixtures.infra.db)
        .await?;

    let subject = format!("typewriter.in.service.{}.heartbeat", service.id);
    let request = ServiceHeartbeatRequest {};

    nats.publish(&subject, &request).await?;

    let db = fixtures.infra.db.clone();
    let service_id = service.id.clone();
    that_async(20, Duration::from_millis(50), || {
        let db = db.clone();
        let service_id = service_id.clone();
        async move {
            let state = get_state(&db, &service_id).await;
            assert!(state.is_some(), "first state should be set");
        }
    })
    .await;

    let first_state = get_state(&fixtures.infra.db, &service.id)
        .await
        .expect("first state should exist");
    let first_last_seen = first_state.last_seen.expect("first last_seen should exist");

    nats.publish(&subject, &request).await?;

    let db = fixtures.infra.db.clone();
    let service_id = service.id.clone();
    let first_ts = first_last_seen.0;
    that_async(20, Duration::from_millis(50), || {
        let db = db.clone();
        let service_id = service_id.clone();
        async move {
            let state = get_state(&db, &service_id).await;
            let ts = state.and_then(|s| s.last_seen).map(|ls| ls.0);
            assert!(
                ts.is_some_and(|t| t >= first_ts),
                "second last_seen should be >= first"
            );
        }
    })
    .await;

    Ok(())
}

#[tokio::test]
async fn test_heartbeat_triggers_services_list_refresh() -> Result<()> {
    let fixtures = get_fixtures().await;
    let nats = TestNatsClient::new(fixtures.infra.nats_client());

    let org = OrganizationBuilder::new("heartbeat_refresh_org")
        .create(&fixtures.infra.db)
        .await?;

    let service = ServiceBuilder::new("heartbeat_refresh_service")
        .service_type("engine")
        .organization(&org)
        .create(&fixtures.infra.db)
        .await?;

    let refresh_subject = format!("typewriter.out.organization.{}.services.list", org.id);
    let mut subscription = fixtures.infra.nats_client().subscribe(refresh_subject).await?;

    let subject = format!("typewriter.in.service.{}.heartbeat", service.id);
    let request = ServiceHeartbeatRequest {};
    nats.publish(&subject, &request).await?;

    let received = tokio::time::timeout(Duration::from_secs(2), subscription.next()).await;

    assert!(
        received.is_ok(),
        "Should receive services list refresh notification after heartbeat"
    );

    let message = received.unwrap();
    assert!(message.is_some(), "Message should not be None");

    let msg = message.unwrap();
    let response = ListOrganizationServicesResponse::decode(msg.payload.as_ref())?;

    match &response.result {
        Some(list_organization_services_response::Result::Services(list)) => {
            assert!(
                list.services.iter().any(|s| s.id == service.id),
                "Refresh should include the service that sent the heartbeat"
            );
        }
        Some(list_organization_services_response::Result::Error(err)) => {
            panic!("Expected services list, got error: {:?}", err);
        }
        None => {
            panic!("Expected services list result, got None");
        }
    }

    Ok(())
}
