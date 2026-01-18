//! Integration tests for the service registration status handler.

use anyhow::Result;
use backend_tests::proto::typewriter::api::v1::{
    get_service_status_response, service_status, GetServiceStatusRequest, GetServiceStatusResponse,
};
use backend_tests::{get_fixtures, OrganizationBuilder, ServiceBuilder, TestNatsClient};
use repeated_assert::that_async;
use std::time::Duration;

/// Helper to get service status.
async fn get_status(nats: &TestNatsClient<'_>, service_id: &str) -> Result<GetServiceStatusResponse> {
    let subject = format!("typewriter.in.service.{}.status", service_id);
    let request = GetServiceStatusRequest {};
    nats.request(&subject, &request).await
}

/// Extract the registration token from an unbound status response.
fn extract_token(response: &GetServiceStatusResponse) -> String {
    match &response.result {
        Some(get_service_status_response::Result::Status(status)) => match &status.binding {
            Some(service_status::Binding::Unbound(unbound)) => {
                unbound.registration_token.clone()
            }
            _ => panic!("Expected unbound status"),
        },
        _ => panic!("Expected status response"),
    }
}

#[tokio::test]
async fn test_status_unbound_service_returns_token() -> Result<()> {
    let fixtures = get_fixtures().await;
    let nats = TestNatsClient::new(fixtures.infra.nats_client());

    let service = ServiceBuilder::new("status_unbound_service")
        .service_type("engine")
        .create(&fixtures.infra.db)
        .await?;

    let response = get_status(&nats, &service.id).await?;

    match &response.result {
        Some(get_service_status_response::Result::Status(status)) => {
            match &status.binding {
                Some(service_status::Binding::Unbound(unbound)) => {
                    let token = &unbound.registration_token;
                    assert_eq!(token.len(), 10, "Token should be 10 characters");
                    assert!(
                        token.chars().all(|c| c.is_ascii_uppercase() || c.is_ascii_digit()),
                        "Token should be uppercase alphanumeric"
                    );
                }
                _ => panic!("Expected unbound status, got bound"),
            }
        }
        Some(get_service_status_response::Result::Error(err)) => {
            panic!("Unexpected error: {} - {}", err.code, err.message);
        }
        None => panic!("Empty response"),
    }

    Ok(())
}

#[tokio::test]
async fn test_status_extends_existing_token() -> Result<()> {
    let fixtures = get_fixtures().await;
    let nats = TestNatsClient::new(fixtures.infra.nats_client());

    let service = ServiceBuilder::new("status_extend_token")
        .service_type("engine")
        .create(&fixtures.infra.db)
        .await?;

    let response1 = get_status(&nats, &service.id).await?;
    let token1 = extract_token(&response1);

    // Poll until registration is stored in the database
    let db = fixtures.infra.db.clone();
    let service_id_clone = service.id.clone();
    that_async(20, Duration::from_millis(50), || {
        let db = db.clone();
        let service_id = service_id_clone.clone();
        async move {
            let db_check: Option<serde_json::Value> = db
                .query("SELECT registration FROM type::thing('service', $id)")
                .bind(("id", service_id))
                .await
                .expect("DB query failed")
                .take(0)
                .expect("Failed to take result");
            assert!(db_check.is_some(), "Registration should be stored in DB");
        }
    })
    .await;

    // Verify the registration was stored in the database
    let service_id_clone = service.id.clone();
    let db_check: Option<serde_json::Value> = fixtures.infra.db
        .query("SELECT registration FROM type::thing('service', $id)")
        .bind(("id", service_id_clone))
        .await?
        .take(0)?;
    println!("DB registration after first call: {:?}", db_check);

    let response2 = get_status(&nats, &service.id).await?;
    let token2 = extract_token(&response2);

    assert_eq!(token1, token2, "Token should remain the same when extended");

    Ok(())
}

#[tokio::test]
async fn test_status_bound_service_returns_org_info() -> Result<()> {
    let fixtures = get_fixtures().await;
    let nats = TestNatsClient::new(fixtures.infra.nats_client());

    let org = OrganizationBuilder::new("status_bound_org")
        .create(&fixtures.infra.db)
        .await?;

    let service = ServiceBuilder::new("status_bound_service")
        .service_type("engine")
        .organization(&org)
        .create(&fixtures.infra.db)
        .await?;

    let response = get_status(&nats, &service.id).await?;

    match &response.result {
        Some(get_service_status_response::Result::Status(status)) => {
            match &status.binding {
                Some(service_status::Binding::Bound(bound)) => {
                    assert_eq!(bound.organization_id, org.id);
                    assert_eq!(bound.organization_name, "status_bound_org");
                }
                _ => panic!("Expected bound status, got unbound"),
            }
        }
        Some(get_service_status_response::Result::Error(err)) => {
            panic!("Unexpected error: {} - {}", err.code, err.message);
        }
        None => panic!("Empty response"),
    }

    Ok(())
}

#[tokio::test]
async fn test_status_nonexistent_service_returns_error() -> Result<()> {
    let fixtures = get_fixtures().await;
    let nats = TestNatsClient::new(fixtures.infra.nats_client());

    let response = get_status(&nats, "nonexistent-service-id").await?;

    match &response.result {
        Some(get_service_status_response::Result::Error(err)) => {
            assert_eq!(err.code, 404, "Expected 404 error code");
        }
        Some(get_service_status_response::Result::Status(_)) => {
            panic!("Expected error, got status");
        }
        None => panic!("Empty response"),
    }

    Ok(())
}
