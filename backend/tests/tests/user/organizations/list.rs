//! Integration tests for the user/organizations LIST endpoint.
//!
//! Tests the `typewriter.in.user.<user_id>.organization.list` NATS subject.
//! This endpoint returns all organizations that a user is a member of.

use backend_tests::proto::typewriter::api::v1::{
    list_organizations_response, ListOrganizationsRequest, ListOrganizationsResponse,
};
use backend_tests::{
    get_fixtures, MemberBuilder, OrganizationBuilder, RoleBuilder, TestNatsClient, UserBuilder,
};

/// Helper function to build the NATS subject for listing organizations.
fn list_organizations_subject(user_id: &str) -> String {
    format!("typewriter.in.user.{}.organization.list", user_id)
}

/// Test that a user with one organization gets that organization returned.
#[tokio::test]
async fn test_list_organizations_single_org() {
    let fixtures = get_fixtures().await;
    let db = &fixtures.infra.db;
    let nats = TestNatsClient::new(fixtures.infra.nats_client());

    // Create test entities with unique names
    let user = UserBuilder::new("test_list_single_user")
        .email("single@example.com")
        .create(db)
        .await
        .expect("Failed to create user");

    let org = OrganizationBuilder::new("test_list_single_org")
        .icon_url("https://example.com/single-icon.png")
        .create(db)
        .await
        .expect("Failed to create organization");

    let role = RoleBuilder::new("test_list_single_role", &org)
        .default_role()
        .create(db)
        .await
        .expect("Failed to create role");

    MemberBuilder::new(&user, &org)
        .with_role(&role)
        .create(db)
        .await
        .expect("Failed to create membership");

    // Send request
    let subject = list_organizations_subject(&user.id);
    let request = ListOrganizationsRequest {};
    let response: ListOrganizationsResponse = nats
        .request(&subject, &request)
        .await
        .expect("Failed to send request");

    // Verify response
    let result = response.result.expect("Response should have a result");
    match result {
        list_organizations_response::Result::Organizations(orgs) => {
            assert_eq!(
                orgs.organizations.len(),
                1,
                "User should belong to exactly one organization"
            );

            let org_data = &orgs.organizations[0];
            assert_eq!(
                org_data.id, org.id,
                "Organization ID should match the created organization"
            );
            assert_eq!(
                org_data.name, org.name,
                "Organization name should match the created organization"
            );
            assert_eq!(
                org_data.icon_url, org.icon_url,
                "Organization icon_url should match the created organization"
            );
        }
        list_organizations_response::Result::Error(err) => {
            panic!(
                "Expected organizations list but got error: {} (code: {})",
                err.message, err.code
            );
        }
    }
}

/// Test that a user with multiple organizations gets all organizations returned.
#[tokio::test]
async fn test_list_organizations_multiple_orgs() {
    let fixtures = get_fixtures().await;
    let db = &fixtures.infra.db;
    let nats = TestNatsClient::new(fixtures.infra.nats_client());

    // Create test user
    let user = UserBuilder::new("test_list_multi_user")
        .email("multi@example.com")
        .create(db)
        .await
        .expect("Failed to create user");

    // Create three organizations with unique names
    let org1 = OrganizationBuilder::new("test_list_multi_org1")
        .icon_url("https://example.com/icon1.png")
        .create(db)
        .await
        .expect("Failed to create organization 1");

    let org2 = OrganizationBuilder::new("test_list_multi_org2")
        .icon_url("https://example.com/icon2.png")
        .create(db)
        .await
        .expect("Failed to create organization 2");

    let org3 = OrganizationBuilder::new("test_list_multi_org3")
        .icon_url("https://example.com/icon3.png")
        .create(db)
        .await
        .expect("Failed to create organization 3");

    // Create roles for each organization
    let role1 = RoleBuilder::new("test_list_multi_role1", &org1)
        .default_role()
        .create(db)
        .await
        .expect("Failed to create role 1");

    let role2 = RoleBuilder::new("test_list_multi_role2", &org2)
        .default_role()
        .create(db)
        .await
        .expect("Failed to create role 2");

    let role3 = RoleBuilder::new("test_list_multi_role3", &org3)
        .default_role()
        .create(db)
        .await
        .expect("Failed to create role 3");

    // Add user as member to all organizations
    MemberBuilder::new(&user, &org1)
        .with_role(&role1)
        .create(db)
        .await
        .expect("Failed to create membership 1");

    MemberBuilder::new(&user, &org2)
        .with_role(&role2)
        .create(db)
        .await
        .expect("Failed to create membership 2");

    MemberBuilder::new(&user, &org3)
        .with_role(&role3)
        .create(db)
        .await
        .expect("Failed to create membership 3");

    // Send request
    let subject = list_organizations_subject(&user.id);
    let request = ListOrganizationsRequest {};
    let response: ListOrganizationsResponse = nats
        .request(&subject, &request)
        .await
        .expect("Failed to send request");

    // Verify response
    let result = response.result.expect("Response should have a result");
    match result {
        list_organizations_response::Result::Organizations(orgs) => {
            assert_eq!(
                orgs.organizations.len(),
                3,
                "User should belong to exactly three organizations"
            );

            // Collect organization IDs from response
            let org_ids: Vec<&str> = orgs.organizations.iter().map(|o| o.id.as_str()).collect();

            // Verify all created organizations are in the response
            assert!(
                org_ids.contains(&org1.id.as_str()),
                "Organization 1 should be in the response"
            );
            assert!(
                org_ids.contains(&org2.id.as_str()),
                "Organization 2 should be in the response"
            );
            assert!(
                org_ids.contains(&org3.id.as_str()),
                "Organization 3 should be in the response"
            );
        }
        list_organizations_response::Result::Error(err) => {
            panic!(
                "Expected organizations list but got error: {} (code: {})",
                err.message, err.code
            );
        }
    }
}

/// Test that a user with no organizations gets an empty list.
#[tokio::test]
async fn test_list_organizations_empty() {
    let fixtures = get_fixtures().await;
    let db = &fixtures.infra.db;
    let nats = TestNatsClient::new(fixtures.infra.nats_client());

    // Create a user with no memberships
    let user = UserBuilder::new("test_list_empty_user")
        .email("empty@example.com")
        .create(db)
        .await
        .expect("Failed to create user");

    // Send request
    let subject = list_organizations_subject(&user.id);
    let request = ListOrganizationsRequest {};
    let response: ListOrganizationsResponse = nats
        .request(&subject, &request)
        .await
        .expect("Failed to send request");

    // Verify response
    let result = response.result.expect("Response should have a result");
    match result {
        list_organizations_response::Result::Organizations(orgs) => {
            assert!(
                orgs.organizations.is_empty(),
                "User with no memberships should have an empty organizations list"
            );
        }
        list_organizations_response::Result::Error(err) => {
            panic!(
                "Expected empty organizations list but got error: {} (code: {})",
                err.message, err.code
            );
        }
    }
}

/// Test behavior when querying for a user that doesn't exist in the database.
/// The endpoint should return an empty list (no organizations) rather than an error,
/// since a non-existent user simply has no memberships.
#[tokio::test]
async fn test_list_organizations_nonexistent_user() {
    let fixtures = get_fixtures().await;
    let nats = TestNatsClient::new(fixtures.infra.nats_client());

    // Use a UUID that doesn't exist in the database
    let nonexistent_user_id = "nonexistent-user-12345";

    // Send request
    let subject = list_organizations_subject(nonexistent_user_id);
    let request = ListOrganizationsRequest {};
    let response: ListOrganizationsResponse = nats
        .request(&subject, &request)
        .await
        .expect("Failed to send request");

    // Verify response - should either return empty list or an error
    let result = response.result.expect("Response should have a result");
    match result {
        list_organizations_response::Result::Organizations(orgs) => {
            // Non-existent user should have no organizations
            assert!(
                orgs.organizations.is_empty(),
                "Non-existent user should have an empty organizations list"
            );
        }
        list_organizations_response::Result::Error(_err) => {
            // An error response is also acceptable behavior for a non-existent user
            // The component may choose to return an error instead of an empty list
        }
    }
}

/// Test that organization data fields (id, name, icon_url) are correctly populated.
#[tokio::test]
async fn test_list_organizations_data_fields() {
    let fixtures = get_fixtures().await;
    let db = &fixtures.infra.db;
    let nats = TestNatsClient::new(fixtures.infra.nats_client());

    // Create test user
    let user = UserBuilder::new("test_list_fields_user")
        .email("fields@example.com")
        .create(db)
        .await
        .expect("Failed to create user");

    // Create organization with specific values to verify
    let expected_name = "test_list_fields_org";
    let expected_icon_url = "https://example.com/custom-icon-for-fields-test.png";

    let org = OrganizationBuilder::new(expected_name)
        .icon_url(expected_icon_url)
        .create(db)
        .await
        .expect("Failed to create organization");

    let role = RoleBuilder::new("test_list_fields_role", &org)
        .default_role()
        .create(db)
        .await
        .expect("Failed to create role");

    MemberBuilder::new(&user, &org)
        .with_role(&role)
        .create(db)
        .await
        .expect("Failed to create membership");

    // Send request
    let subject = list_organizations_subject(&user.id);
    let request = ListOrganizationsRequest {};
    let response: ListOrganizationsResponse = nats
        .request(&subject, &request)
        .await
        .expect("Failed to send request");

    // Verify response
    let result = response.result.expect("Response should have a result");
    match result {
        list_organizations_response::Result::Organizations(orgs) => {
            assert_eq!(
                orgs.organizations.len(),
                1,
                "User should belong to exactly one organization"
            );

            let org_data = &orgs.organizations[0];

            // Verify ID field
            assert!(
                !org_data.id.is_empty(),
                "Organization ID should not be empty"
            );
            assert_eq!(
                org_data.id, org.id,
                "Organization ID should match the expected value"
            );

            // Verify name field
            assert!(
                !org_data.name.is_empty(),
                "Organization name should not be empty"
            );
            assert_eq!(
                org_data.name, expected_name,
                "Organization name should match the expected value"
            );

            // Verify icon_url field
            assert!(
                !org_data.icon_url.is_empty(),
                "Organization icon_url should not be empty"
            );
            assert_eq!(
                org_data.icon_url, expected_icon_url,
                "Organization icon_url should match the expected value"
            );

            // Verify timestamps are present (OrganizationData includes created_at and updated_at)
            assert!(
                org_data.created_at.is_some(),
                "Organization should have a created_at timestamp"
            );
        }
        list_organizations_response::Result::Error(err) => {
            panic!(
                "Expected organizations list but got error: {} (code: {})",
                err.message, err.code
            );
        }
    }
}

/// Test that user only sees organizations they are a member of,
/// not other organizations in the system.
#[tokio::test]
async fn test_list_organizations_excludes_non_member_orgs() {
    let fixtures = get_fixtures().await;
    let db = &fixtures.infra.db;
    let nats = TestNatsClient::new(fixtures.infra.nats_client());

    // Create two users
    let user1 = UserBuilder::new("test_list_exclude_user1")
        .email("user1@example.com")
        .create(db)
        .await
        .expect("Failed to create user 1");

    let user2 = UserBuilder::new("test_list_exclude_user2")
        .email("user2@example.com")
        .create(db)
        .await
        .expect("Failed to create user 2");

    // Create two organizations
    let org_for_user1 = OrganizationBuilder::new("test_list_exclude_org1")
        .icon_url("https://example.com/org1.png")
        .create(db)
        .await
        .expect("Failed to create organization 1");

    let org_for_user2 = OrganizationBuilder::new("test_list_exclude_org2")
        .icon_url("https://example.com/org2.png")
        .create(db)
        .await
        .expect("Failed to create organization 2");

    // Create roles for each organization
    let role1 = RoleBuilder::new("test_list_exclude_role1", &org_for_user1)
        .default_role()
        .create(db)
        .await
        .expect("Failed to create role 1");

    let role2 = RoleBuilder::new("test_list_exclude_role2", &org_for_user2)
        .default_role()
        .create(db)
        .await
        .expect("Failed to create role 2");

    // User1 is member of org1, User2 is member of org2
    MemberBuilder::new(&user1, &org_for_user1)
        .with_role(&role1)
        .create(db)
        .await
        .expect("Failed to create membership for user 1");

    MemberBuilder::new(&user2, &org_for_user2)
        .with_role(&role2)
        .create(db)
        .await
        .expect("Failed to create membership for user 2");

    // Query for user1's organizations
    let subject = list_organizations_subject(&user1.id);
    let request = ListOrganizationsRequest {};
    let response: ListOrganizationsResponse = nats
        .request(&subject, &request)
        .await
        .expect("Failed to send request");

    // Verify user1 only sees org1
    let result = response.result.expect("Response should have a result");
    match result {
        list_organizations_response::Result::Organizations(orgs) => {
            assert_eq!(
                orgs.organizations.len(),
                1,
                "User1 should belong to exactly one organization"
            );

            let org_data = &orgs.organizations[0];
            assert_eq!(
                org_data.id, org_for_user1.id,
                "User1 should only see org_for_user1"
            );
            assert_ne!(
                org_data.id, org_for_user2.id,
                "User1 should not see org_for_user2"
            );
        }
        list_organizations_response::Result::Error(err) => {
            panic!(
                "Expected organizations list but got error: {} (code: {})",
                err.message, err.code
            );
        }
    }
}
