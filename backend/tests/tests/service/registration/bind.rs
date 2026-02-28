//! Integration tests for the service registration bind handler.

use anyhow::Result;
use backend_tests::proto::typewriter::api::v1::{
    BindServiceRequest, BindServiceResponse, bind_service_response,
};
use backend_tests::{
    OrganizationBuilder, ServiceBuilder, TestNatsClient, UserBuilder, get_fixtures,
};

/// Helper to bind a service.
async fn bind_service(
    nats: &TestNatsClient<'_>,
    user_id: &str,
    org_id: &str,
    token: &str,
) -> Result<BindServiceResponse> {
    let subject = format!(
        "typewriter.in.user.{}.organization.{}.services.bind",
        user_id, org_id
    );
    let request = BindServiceRequest {
        registration_token: token.to_string(),
    };
    nats.request(&subject, &request).await
}

#[tokio::test]
async fn test_bind_service_with_valid_token() -> Result<()> {
    let fixtures = get_fixtures().await;
    let nats = TestNatsClient::new(fixtures.infra.nats_client());

    let user = UserBuilder::new("bind_user")
        .create(&fixtures.infra.db)
        .await?;
    let org = OrganizationBuilder::new("bind_org")
        .create(&fixtures.infra.db)
        .await?;

    let service = ServiceBuilder::new("bind_test_service")
        .service_type("engine")
        .registration_token("ABCD123456")
        .create(&fixtures.infra.db)
        .await?;

    let response = bind_service(&nats, &user.id, &org.id, "ABCD123456").await?;

    match &response.result {
        Some(bind_service_response::Result::Service(bound)) => {
            assert_eq!(bound.service_id, service.id);
            assert_eq!(bound.service_name, Some("bind_test_service".to_string()));
            assert!(!bound.service_types.is_empty());
        }
        Some(bind_service_response::Result::Error(err)) => {
            panic!("Unexpected error: {} - {}", err.code, err.message);
        }
        None => panic!("Empty response"),
    }

    Ok(())
}

#[tokio::test]
async fn test_bind_service_with_expired_token_fails() -> Result<()> {
    let fixtures = get_fixtures().await;
    let nats = TestNatsClient::new(fixtures.infra.nats_client());

    let user = UserBuilder::new("bind_expired_user")
        .create(&fixtures.infra.db)
        .await?;
    let org = OrganizationBuilder::new("bind_expired_org")
        .create(&fixtures.infra.db)
        .await?;

    let _service = ServiceBuilder::new("bind_expired_service")
        .service_type("engine")
        .registration_token_expired("EXPIRED123")
        .create(&fixtures.infra.db)
        .await?;

    let response = bind_service(&nats, &user.id, &org.id, "EXPIRED123").await?;

    match &response.result {
        Some(bind_service_response::Result::Error(err)) => {
            assert_eq!(err.code, 400, "Expected 400 error for expired token");
            assert!(
                err.message.to_lowercase().contains("invalid")
                    || err.message.to_lowercase().contains("expired"),
                "Error should mention invalid or expired token"
            );
        }
        Some(bind_service_response::Result::Service(_)) => {
            panic!("Expected error for expired token, got success");
        }
        None => panic!("Empty response"),
    }

    Ok(())
}

#[tokio::test]
async fn test_bind_service_with_invalid_token_fails() -> Result<()> {
    let fixtures = get_fixtures().await;
    let nats = TestNatsClient::new(fixtures.infra.nats_client());

    let user = UserBuilder::new("bind_invalid_user")
        .create(&fixtures.infra.db)
        .await?;
    let org = OrganizationBuilder::new("bind_invalid_org")
        .create(&fixtures.infra.db)
        .await?;

    let response = bind_service(&nats, &user.id, &org.id, "INVALIDTOKEN").await?;

    match &response.result {
        Some(bind_service_response::Result::Error(err)) => {
            assert_eq!(err.code, 400, "Expected 400 error for invalid token");
        }
        Some(bind_service_response::Result::Service(_)) => {
            panic!("Expected error for invalid token, got success");
        }
        None => panic!("Empty response"),
    }

    Ok(())
}

#[tokio::test]
async fn test_bind_clears_registration_sets_organization() -> Result<()> {
    let fixtures = get_fixtures().await;
    let nats = TestNatsClient::new(fixtures.infra.nats_client());

    let user = UserBuilder::new("bind_verify_user")
        .create(&fixtures.infra.db)
        .await?;
    let org = OrganizationBuilder::new("bind_verify_org")
        .create(&fixtures.infra.db)
        .await?;

    let service = ServiceBuilder::new("bind_verify_service")
        .service_type("engine")
        .registration_token("VERIFY1234")
        .create(&fixtures.infra.db)
        .await?;

    let response = bind_service(&nats, &user.id, &org.id, "VERIFY1234").await?;

    match &response.result {
        Some(bind_service_response::Result::Service(_)) => {}
        _ => panic!("Expected successful bind"),
    }

    #[derive(Debug, serde::Deserialize)]
    struct ServiceCheck {
        organization: Option<surrealdb::sql::Thing>,
        registration: Option<serde_json::Value>,
    }

    let check: Option<ServiceCheck> = fixtures
        .infra
        .db
        .select(("service", service.id.as_str()))
        .await?;

    let check = check.expect("Service should exist");
    assert!(
        check.registration.is_none(),
        "Registration should be cleared after bind"
    );
    assert!(
        check.organization.is_some(),
        "Organization should be set after bind"
    );

    Ok(())
}
