//! Integration tests for the service shutdown handler.

use anyhow::Result;
use backend_tests::proto::typewriter::api::v1::{ServiceHeartbeatRequest, ServiceShutdownRequest};
use backend_tests::{get_fixtures, OrganizationBuilder, ServiceBuilder, TestNatsClient};
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

#[tokio::test]
async fn test_shutdown_sets_status_to_offline() -> Result<()> {
    let fixtures = get_fixtures().await;
    let nats = TestNatsClient::new(fixtures.infra.nats_client());

    let org = OrganizationBuilder::new("shutdown_org")
        .create(&fixtures.infra.db)
        .await?;

    let service = ServiceBuilder::new("shutdown_service")
        .service_type("engine")
        .organization(&org)
        .create(&fixtures.infra.db)
        .await?;

    // First send a heartbeat to set the service online
    let heartbeat_subject = format!("typewriter.in.service.{}.heartbeat", service.id);
    nats.publish(&heartbeat_subject, &ServiceHeartbeatRequest {})
        .await?;

    let db = fixtures.infra.db.clone();
    let service_id = service.id.clone();
    that_async(20, Duration::from_millis(50), || {
        let db = db.clone();
        let service_id = service_id.clone();
        async move {
            let state = get_state(&db, &service_id).await;
            assert!(
                state.is_some_and(|s| s.status.as_deref() == Some("ONLINE")),
                "service should be ONLINE after heartbeat"
            );
        }
    })
    .await;

    // Now send shutdown
    let shutdown_subject = format!("typewriter.in.service.{}.shutdown", service.id);
    nats.publish(&shutdown_subject, &ServiceShutdownRequest {})
        .await?;

    let db = fixtures.infra.db.clone();
    let service_id = service.id.clone();
    that_async(20, Duration::from_millis(50), || {
        let db = db.clone();
        let service_id = service_id.clone();
        async move {
            let state = get_state(&db, &service_id).await;
            assert!(state.is_some(), "state should be set after shutdown");
            assert_eq!(
                state.unwrap().status.as_deref(),
                Some("OFFLINE"),
                "status should be OFFLINE after shutdown"
            );
        }
    })
    .await;

    Ok(())
}

#[tokio::test]
async fn test_shutdown_updates_last_seen() -> Result<()> {
    let fixtures = get_fixtures().await;
    let nats = TestNatsClient::new(fixtures.infra.nats_client());

    let org = OrganizationBuilder::new("shutdown_lastseen_org")
        .create(&fixtures.infra.db)
        .await?;

    let service = ServiceBuilder::new("shutdown_lastseen_service")
        .service_type("realm")
        .organization(&org)
        .create(&fixtures.infra.db)
        .await?;

    let before_shutdown = chrono::Utc::now();

    let shutdown_subject = format!("typewriter.in.service.{}.shutdown", service.id);
    nats.publish(&shutdown_subject, &ServiceShutdownRequest {})
        .await?;

    let db = fixtures.infra.db.clone();
    let service_id = service.id.clone();
    that_async(20, Duration::from_millis(50), || {
        let db = db.clone();
        let service_id = service_id.clone();
        async move {
            let state = get_state(&db, &service_id).await;
            assert!(state.is_some(), "state should be set after shutdown");
        }
    })
    .await;

    let after_shutdown = chrono::Utc::now();

    let state = get_state(&fixtures.infra.db, &service.id)
        .await
        .expect("state should be set");

    assert_eq!(
        state.status.as_deref(),
        Some("OFFLINE"),
        "status should be OFFLINE"
    );

    let last_seen = state.last_seen.expect("last_seen should be set");
    let last_seen_time = last_seen.0;
    assert!(
        last_seen_time >= before_shutdown && last_seen_time <= after_shutdown,
        "last_seen ({:?}) should be between {:?} and {:?}",
        last_seen_time,
        before_shutdown,
        after_shutdown
    );

    Ok(())
}

#[tokio::test]
async fn test_shutdown_can_be_followed_by_heartbeat() -> Result<()> {
    let fixtures = get_fixtures().await;
    let nats = TestNatsClient::new(fixtures.infra.nats_client());

    let org = OrganizationBuilder::new("shutdown_recovery_org")
        .create(&fixtures.infra.db)
        .await?;

    let service = ServiceBuilder::new("shutdown_recovery_service")
        .service_type("engine")
        .organization(&org)
        .create(&fixtures.infra.db)
        .await?;

    // Send shutdown first
    let shutdown_subject = format!("typewriter.in.service.{}.shutdown", service.id);
    nats.publish(&shutdown_subject, &ServiceShutdownRequest {})
        .await?;

    let db = fixtures.infra.db.clone();
    let service_id = service.id.clone();
    that_async(20, Duration::from_millis(50), || {
        let db = db.clone();
        let service_id = service_id.clone();
        async move {
            let state = get_state(&db, &service_id).await;
            assert!(
                state.is_some_and(|s| s.status.as_deref() == Some("OFFLINE")),
                "service should be OFFLINE after shutdown"
            );
        }
    })
    .await;

    // Now send heartbeat - simulating service restart
    let heartbeat_subject = format!("typewriter.in.service.{}.heartbeat", service.id);
    nats.publish(&heartbeat_subject, &ServiceHeartbeatRequest {})
        .await?;

    let db = fixtures.infra.db.clone();
    let service_id = service.id.clone();
    that_async(20, Duration::from_millis(50), || {
        let db = db.clone();
        let service_id = service_id.clone();
        async move {
            let state = get_state(&db, &service_id).await;
            assert!(state.is_some(), "state should be set after heartbeat");
            assert_eq!(
                state.unwrap().status.as_deref(),
                Some("ONLINE"),
                "status should be ONLINE after heartbeat following shutdown"
            );
        }
    })
    .await;

    Ok(())
}
