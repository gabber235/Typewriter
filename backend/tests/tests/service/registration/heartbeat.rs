//! Integration tests for the service heartbeat handler.

use anyhow::Result;
use backend_tests::proto::typewriter::api::v1::ServiceHeartbeatRequest;
use backend_tests::{get_fixtures, OrganizationBuilder, ServiceBuilder, TestNatsClient};
use repeated_assert::that_async;
use std::time::Duration;
use surrealdb::sql::Datetime;
use surrealdb::Surreal;

#[derive(Debug, Clone, serde::Deserialize)]
struct LastSeenCheck {
    last_seen: Option<Datetime>,
}

async fn get_last_seen(db: &Surreal<surrealdb::engine::any::Any>, service_id: &str) -> Option<Datetime> {
    let check: Option<LastSeenCheck> = db
        .select(("service", service_id))
        .await
        .ok()
        .flatten();
    check.and_then(|c| c.last_seen)
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

    let before = get_last_seen(&fixtures.infra.db, &service.id).await;
    assert!(
        before.is_none(),
        "last_seen should be None before heartbeat"
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
            let last_seen = get_last_seen(&db, &service_id).await;
            assert!(
                last_seen.is_some(),
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
            let last_seen = get_last_seen(&db, &service_id).await;
            assert!(last_seen.is_some(), "last_seen should be set");
        }
    })
    .await;

    let after_heartbeat = chrono::Utc::now();

    let last_seen = get_last_seen(&fixtures.infra.db, &service.id)
        .await
        .expect("last_seen should be set");

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
            let last_seen = get_last_seen(&db, &service_id).await;
            assert!(last_seen.is_some(), "first last_seen should be set");
        }
    })
    .await;

    let first_last_seen = get_last_seen(&fixtures.infra.db, &service.id)
        .await
        .expect("first last_seen should exist");

    nats.publish(&subject, &request).await?;

    let db = fixtures.infra.db.clone();
    let service_id = service.id.clone();
    let first_ts = first_last_seen.0;
    that_async(20, Duration::from_millis(50), || {
        let db = db.clone();
        let service_id = service_id.clone();
        async move {
            let last_seen = get_last_seen(&db, &service_id).await;
            let ts = last_seen.map(|ls| ls.0);
            assert!(
                ts.is_some_and(|t| t >= first_ts),
                "second last_seen should be >= first"
            );
        }
    })
    .await;

    Ok(())
}
