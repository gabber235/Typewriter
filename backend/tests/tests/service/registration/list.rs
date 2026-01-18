//! Integration tests for the service registration list handler.

use anyhow::Result;
use backend_tests::proto::typewriter::api::v1::{
    list_organization_services_response, ListOrganizationServicesRequest,
    ListOrganizationServicesResponse,
};
use backend_tests::{
    get_fixtures, OrganizationBuilder, ServiceBuilder, TestNatsClient, UserBuilder,
};

/// Helper to list organization services.
async fn list_services(
    nats: &TestNatsClient<'_>,
    user_id: &str,
    org_id: &str,
) -> Result<ListOrganizationServicesResponse> {
    let subject = format!(
        "typewriter.in.user.{}.organization.{}.services.list",
        user_id, org_id
    );
    let request = ListOrganizationServicesRequest {};
    nats.request(&subject, &request).await
}

#[tokio::test]
async fn test_list_returns_all_org_services() -> Result<()> {
    let fixtures = get_fixtures().await;
    let nats = TestNatsClient::new(fixtures.infra.nats_client());

    let user = UserBuilder::new("list_all_user").create(&fixtures.infra.db).await?;
    let org = OrganizationBuilder::new("list_all_org")
        .create(&fixtures.infra.db)
        .await?;

    for i in 0..3 {
        ServiceBuilder::new(format!("list_all_service_{}", i))
            .service_type("engine")
            .organization(&org)
            .create(&fixtures.infra.db)
            .await?;
    }

    let response = list_services(&nats, &user.id, &org.id).await?;

    match &response.result {
        Some(list_organization_services_response::Result::Services(list)) => {
            assert_eq!(list.services.len(), 3, "Should return 3 services");
        }
        Some(list_organization_services_response::Result::Error(err)) => {
            panic!("Unexpected error: {} - {}", err.code, err.message);
        }
        None => panic!("Empty response"),
    }

    Ok(())
}

#[tokio::test]
async fn test_list_empty_org_returns_empty_list() -> Result<()> {
    let fixtures = get_fixtures().await;
    let nats = TestNatsClient::new(fixtures.infra.nats_client());

    let user = UserBuilder::new("list_empty_user")
        .create(&fixtures.infra.db)
        .await?;
    let org = OrganizationBuilder::new("list_empty_org")
        .create(&fixtures.infra.db)
        .await?;

    let response = list_services(&nats, &user.id, &org.id).await?;

    match &response.result {
        Some(list_organization_services_response::Result::Services(list)) => {
            assert!(list.services.is_empty(), "Should return empty list");
        }
        Some(list_organization_services_response::Result::Error(err)) => {
            panic!("Unexpected error: {} - {}", err.code, err.message);
        }
        None => panic!("Empty response"),
    }

    Ok(())
}

#[tokio::test]
async fn test_list_only_returns_org_services() -> Result<()> {
    let fixtures = get_fixtures().await;
    let nats = TestNatsClient::new(fixtures.infra.nats_client());

    let user = UserBuilder::new("list_filter_user")
        .create(&fixtures.infra.db)
        .await?;
    let org1 = OrganizationBuilder::new("list_filter_org1")
        .create(&fixtures.infra.db)
        .await?;
    let org2 = OrganizationBuilder::new("list_filter_org2")
        .create(&fixtures.infra.db)
        .await?;

    for i in 0..2 {
        ServiceBuilder::new(format!("list_filter_org1_service_{}", i))
            .service_type("engine")
            .organization(&org1)
            .create(&fixtures.infra.db)
            .await?;
    }

    for i in 0..3 {
        ServiceBuilder::new(format!("list_filter_org2_service_{}", i))
            .service_type("realm")
            .organization(&org2)
            .create(&fixtures.infra.db)
            .await?;
    }

    let response1 = list_services(&nats, &user.id, &org1.id).await?;
    let response2 = list_services(&nats, &user.id, &org2.id).await?;

    match &response1.result {
        Some(list_organization_services_response::Result::Services(list)) => {
            assert_eq!(list.services.len(), 2, "Org1 should have 2 services");
            for service in &list.services {
                assert!(
                    service.name.contains("org1"),
                    "Service should belong to org1"
                );
            }
        }
        _ => panic!("Expected services for org1"),
    }

    match &response2.result {
        Some(list_organization_services_response::Result::Services(list)) => {
            assert_eq!(list.services.len(), 3, "Org2 should have 3 services");
            for service in &list.services {
                assert!(
                    service.name.contains("org2"),
                    "Service should belong to org2"
                );
            }
        }
        _ => panic!("Expected services for org2"),
    }

    Ok(())
}
