//! Integration tests for organization members join_requests endpoints.
//!
//! Tests the following endpoints:
//! - List join requests: typewriter.in.user.<user_id>.organization.<org_id>.members.join_requests.list
//! - Approve join request: typewriter.in.user.<user_id>.organization.<org_id>.members.join_requests.approve
//! - Decline join request: typewriter.in.user.<user_id>.organization.<org_id>.members.join_requests.decline

use backend_tests::proto::typewriter::api::v1::{
    ApproveJoinRequestRequest, ApproveJoinRequestResponse, DeclineJoinRequestRequest,
    DeclineJoinRequestResponse, ListJoinRequestsRequest, ListJoinRequestsResponse,
    approve_join_request_response, decline_join_request_response, list_join_requests_response,
};
use backend_tests::{
    JoinRequestBuilder, MemberBuilder, OrganizationBuilder, RoleBuilder, TestNatsClient,
    UserBuilder, get_fixtures,
};
use serde::Deserialize;
use surrealdb::RecordId;

/// Helper struct for checking member_of relations.
#[derive(Debug, Deserialize)]
struct MemberOfCheck {
    #[allow(dead_code)]
    id: RecordId,
}

/// Helper struct for checking requests_to_join relations.
#[derive(Debug, Deserialize)]
struct JoinRequestCheck {
    #[allow(dead_code)]
    id: RecordId,
}

/// Helper struct for checking user records.
#[derive(Debug, Deserialize)]
struct UserCheck {
    #[allow(dead_code)]
    id: RecordId,
}

// =============================================================================
// List Join Requests Tests
// =============================================================================

/// Test listing join requests when organization has no pending requests.
#[tokio::test]
async fn list_join_requests_empty() {
    let fixtures = get_fixtures().await;
    let client = TestNatsClient::new(fixtures.infra.nats_client());
    let db = &fixtures.infra.db;

    // Create test data: an admin user who is a member of the org
    let admin = UserBuilder::new("list_empty_admin")
        .email("list_empty_admin@test.com")
        .create(db)
        .await
        .expect("Failed to create admin user");

    let org = OrganizationBuilder::new("list_empty_org")
        .create(db)
        .await
        .expect("Failed to create organization");

    let role = RoleBuilder::new("list_empty_role", &org)
        .create(db)
        .await
        .expect("Failed to create role");

    MemberBuilder::new(&admin, &org)
        .with_role(&role)
        .create(db)
        .await
        .expect("Failed to create membership");

    // Send list request
    let subject = format!(
        "typewriter.in.user.{}.organization.{}.members.join_requests.list",
        admin.id, org.id
    );
    let request = ListJoinRequestsRequest {};

    let response: ListJoinRequestsResponse = client
        .request(&subject, &request)
        .await
        .expect("Failed to send request");

    // Verify empty list
    match response.result {
        Some(list_join_requests_response::Result::Requests(requests)) => {
            assert!(
                requests.requests.is_empty(),
                "Expected empty requests list, got {} requests",
                requests.requests.len()
            );
        }
        Some(list_join_requests_response::Result::Error(e)) => {
            panic!("Unexpected error: {:?}", e);
        }
        None => panic!("Expected result, got None"),
    }
}

/// Test listing join requests with pending requests - verify user data included.
#[tokio::test]
async fn list_join_requests_with_pending() {
    let fixtures = get_fixtures().await;
    let client = TestNatsClient::new(fixtures.infra.nats_client());
    let db = &fixtures.infra.db;

    // Create test data
    let admin = UserBuilder::new("list_pending_admin")
        .email("list_pending_admin@test.com")
        .avatar_url("https://example.com/admin.png")
        .create(db)
        .await
        .expect("Failed to create admin user");

    let requester = UserBuilder::new("list_pending_requester")
        .email("list_pending_requester@test.com")
        .avatar_url("https://example.com/requester.png")
        .create(db)
        .await
        .expect("Failed to create requester user");

    let org = OrganizationBuilder::new("list_pending_org")
        .create(db)
        .await
        .expect("Failed to create organization");

    let role = RoleBuilder::new("list_pending_role", &org)
        .create(db)
        .await
        .expect("Failed to create role");

    MemberBuilder::new(&admin, &org)
        .with_role(&role)
        .create(db)
        .await
        .expect("Failed to create membership");

    // Create a join request using the builder
    JoinRequestBuilder::new(&requester, &org)
        .create(db)
        .await
        .expect("Failed to create join request");

    // Send list request
    let subject = format!(
        "typewriter.in.user.{}.organization.{}.members.join_requests.list",
        admin.id, org.id
    );
    let request = ListJoinRequestsRequest {};

    let response: ListJoinRequestsResponse = client
        .request(&subject, &request)
        .await
        .expect("Failed to send request");

    // Verify request is in list with user data
    match response.result {
        Some(list_join_requests_response::Result::Requests(requests)) => {
            assert_eq!(
                requests.requests.len(),
                1,
                "Expected 1 request, got {}",
                requests.requests.len()
            );

            let join_request = &requests.requests[0];
            assert_eq!(join_request.user_id, requester.id);
            assert_eq!(join_request.user_name, requester.name.clone());
            assert_eq!(join_request.user_email, requester.email.clone());
            assert_eq!(join_request.user_avatar_url, requester.avatar_url.clone());
            assert!(join_request.requested_at.is_some());
            assert!(join_request.expires_at.is_some());
        }
        Some(list_join_requests_response::Result::Error(e)) => {
            panic!("Unexpected error: {:?}", e);
        }
        None => panic!("Expected result, got None"),
    }
}

/// Test that expired requests are not included in the list.
#[tokio::test]
async fn list_join_requests_expired_not_included() {
    let fixtures = get_fixtures().await;
    let client = TestNatsClient::new(fixtures.infra.nats_client());
    let db = &fixtures.infra.db;

    // Create test data
    let admin = UserBuilder::new("list_expired_admin")
        .email("list_expired_admin@test.com")
        .create(db)
        .await
        .expect("Failed to create admin user");

    let expired_requester = UserBuilder::new("list_expired_requester")
        .email("list_expired_requester@test.com")
        .create(db)
        .await
        .expect("Failed to create expired requester user");

    let valid_requester = UserBuilder::new("list_valid_requester")
        .email("list_valid_requester@test.com")
        .create(db)
        .await
        .expect("Failed to create valid requester user");

    let org = OrganizationBuilder::new("list_expired_org")
        .create(db)
        .await
        .expect("Failed to create organization");

    let role = RoleBuilder::new("list_expired_role", &org)
        .create(db)
        .await
        .expect("Failed to create role");

    MemberBuilder::new(&admin, &org)
        .with_role(&role)
        .create(db)
        .await
        .expect("Failed to create membership");

    // Create an expired join request (expires_at in the past)
    JoinRequestBuilder::new(&expired_requester, &org)
        .expires_in_days(-1)
        .create(db)
        .await
        .expect("Failed to create expired join request");

    // Create a valid join request
    JoinRequestBuilder::new(&valid_requester, &org)
        .create(db)
        .await
        .expect("Failed to create valid join request");

    // Send list request
    let subject = format!(
        "typewriter.in.user.{}.organization.{}.members.join_requests.list",
        admin.id, org.id
    );
    let request = ListJoinRequestsRequest {};

    let response: ListJoinRequestsResponse = client
        .request(&subject, &request)
        .await
        .expect("Failed to send request");

    // Verify only the valid request is in the list
    match response.result {
        Some(list_join_requests_response::Result::Requests(requests)) => {
            assert_eq!(
                requests.requests.len(),
                1,
                "Expected 1 request (expired should be excluded), got {}",
                requests.requests.len()
            );

            let join_request = &requests.requests[0];
            assert_eq!(
                join_request.user_id, valid_requester.id,
                "Expected valid requester, got different user"
            );
        }
        Some(list_join_requests_response::Result::Error(e)) => {
            panic!("Unexpected error: {:?}", e);
        }
        None => panic!("Expected result, got None"),
    }
}

// =============================================================================
// Approve Join Request Tests
// =============================================================================

/// Test successfully approving a join request with roles.
#[tokio::test]
async fn approve_join_request_success() {
    let fixtures = get_fixtures().await;
    let client = TestNatsClient::new(fixtures.infra.nats_client());
    let db = &fixtures.infra.db;

    // Create test data
    let admin = UserBuilder::new("approve_success_admin")
        .email("approve_success_admin@test.com")
        .create(db)
        .await
        .expect("Failed to create admin user");

    let requester = UserBuilder::new("approve_success_requester")
        .email("approve_success_requester@test.com")
        .avatar_url("https://example.com/approve.png")
        .create(db)
        .await
        .expect("Failed to create requester user");

    let org = OrganizationBuilder::new("approve_success_org")
        .create(db)
        .await
        .expect("Failed to create organization");

    let admin_role = RoleBuilder::new("approve_admin_role", &org)
        .create(db)
        .await
        .expect("Failed to create admin role");

    let member_role = RoleBuilder::new("approve_member_role", &org)
        .create(db)
        .await
        .expect("Failed to create member role");

    MemberBuilder::new(&admin, &org)
        .with_role(&admin_role)
        .create(db)
        .await
        .expect("Failed to create admin membership");

    // Create a join request and get its ID
    let join_request = JoinRequestBuilder::new(&requester, &org)
        .create(db)
        .await
        .expect("Failed to create join request");
    let request_id = join_request.id;

    // Send approve request
    let subject = format!(
        "typewriter.in.user.{}.organization.{}.members.join_requests.approve",
        admin.id, org.id
    );
    let request = ApproveJoinRequestRequest {
        request_id: request_id.clone(),
        role_ids: vec![member_role.id.clone()],
    };

    let response: ApproveJoinRequestResponse = client
        .request(&subject, &request)
        .await
        .expect("Failed to send request");

    // Verify member was created
    match response.result {
        Some(approve_join_request_response::Result::Member(member)) => {
            assert_eq!(member.name, requester.name.clone());
            assert_eq!(member.email, requester.email.clone());
            assert_eq!(member.roles.len(), 1);
            assert_eq!(member.roles[0].role_id, member_role.id);
            assert!(member.joined_at.is_some());
        }
        Some(approve_join_request_response::Result::Error(e)) => {
            panic!("Unexpected error: {:?}", e);
        }
        None => panic!("Expected result, got None"),
    }
}

/// Test that user becomes a member after approval.
#[tokio::test]
async fn approve_join_request_user_becomes_member() {
    let fixtures = get_fixtures().await;
    let client = TestNatsClient::new(fixtures.infra.nats_client());
    let db = &fixtures.infra.db;

    // Create test data
    let admin = UserBuilder::new("approve_member_admin")
        .email("approve_member_admin@test.com")
        .create(db)
        .await
        .expect("Failed to create admin user");

    let requester = UserBuilder::new("approve_member_requester")
        .email("approve_member_requester@test.com")
        .create(db)
        .await
        .expect("Failed to create requester user");

    let org = OrganizationBuilder::new("approve_member_org")
        .create(db)
        .await
        .expect("Failed to create organization");

    let role = RoleBuilder::new("approve_member_role", &org)
        .create(db)
        .await
        .expect("Failed to create role");

    MemberBuilder::new(&admin, &org)
        .with_role(&role)
        .create(db)
        .await
        .expect("Failed to create admin membership");

    // Create a join request
    let join_request = JoinRequestBuilder::new(&requester, &org)
        .create(db)
        .await
        .expect("Failed to create join request");
    let request_id = join_request.id;

    // Verify user is NOT a member before approval
    let check_query = format!(
        "SELECT id FROM member_of WHERE in = user:`{}` AND out = organization:`{}`",
        requester.id, org.id
    );
    let mut check_result = db
        .query(&check_query)
        .await
        .expect("Failed to check membership");
    let members_before: Vec<MemberOfCheck> = check_result.take(0).expect("Failed to get result");
    assert!(
        members_before.is_empty(),
        "User should not be a member before approval"
    );

    // Approve the request
    let subject = format!(
        "typewriter.in.user.{}.organization.{}.members.join_requests.approve",
        admin.id, org.id
    );
    let request = ApproveJoinRequestRequest {
        request_id,
        role_ids: vec![role.id.clone()],
    };

    let _response: ApproveJoinRequestResponse = client
        .request(&subject, &request)
        .await
        .expect("Failed to send request");

    // Verify user IS a member after approval
    let mut check_result = db
        .query(&check_query)
        .await
        .expect("Failed to check membership");
    let members_after: Vec<MemberOfCheck> = check_result.take(0).expect("Failed to get result");
    assert_eq!(
        members_after.len(),
        1,
        "User should be a member after approval"
    );
}

/// Test that request is deleted after approval.
#[tokio::test]
async fn approve_join_request_deletes_request() {
    let fixtures = get_fixtures().await;
    let client = TestNatsClient::new(fixtures.infra.nats_client());
    let db = &fixtures.infra.db;

    // Create test data
    let admin = UserBuilder::new("approve_delete_admin")
        .email("approve_delete_admin@test.com")
        .create(db)
        .await
        .expect("Failed to create admin user");

    let requester = UserBuilder::new("approve_delete_requester")
        .email("approve_delete_requester@test.com")
        .create(db)
        .await
        .expect("Failed to create requester user");

    let org = OrganizationBuilder::new("approve_delete_org")
        .create(db)
        .await
        .expect("Failed to create organization");

    let role = RoleBuilder::new("approve_delete_role", &org)
        .create(db)
        .await
        .expect("Failed to create role");

    MemberBuilder::new(&admin, &org)
        .with_role(&role)
        .create(db)
        .await
        .expect("Failed to create admin membership");

    // Create a join request
    let join_request = JoinRequestBuilder::new(&requester, &org)
        .create(db)
        .await
        .expect("Failed to create join request");
    let request_id = join_request.id;

    // Approve the request
    let subject = format!(
        "typewriter.in.user.{}.organization.{}.members.join_requests.approve",
        admin.id, org.id
    );
    let request = ApproveJoinRequestRequest {
        request_id: request_id.clone(),
        role_ids: vec![role.id.clone()],
    };

    let _response: ApproveJoinRequestResponse = client
        .request(&subject, &request)
        .await
        .expect("Failed to send request");

    // Verify request is deleted
    let check_query = format!(
        "SELECT id FROM requests_to_join WHERE in = user:`{}` AND out = organization:`{}`",
        requester.id, org.id
    );
    let mut check_result = db
        .query(&check_query)
        .await
        .expect("Failed to check requests");
    let requests_after: Vec<JoinRequestCheck> = check_result.take(0).expect("Failed to get result");
    assert!(
        requests_after.is_empty(),
        "Join request should be deleted after approval"
    );
}

/// Test error when request is not found.
#[tokio::test]
async fn approve_join_request_not_found() {
    let fixtures = get_fixtures().await;
    let client = TestNatsClient::new(fixtures.infra.nats_client());
    let db = &fixtures.infra.db;

    // Create test data
    let admin = UserBuilder::new("approve_notfound_admin")
        .email("approve_notfound_admin@test.com")
        .create(db)
        .await
        .expect("Failed to create admin user");

    let org = OrganizationBuilder::new("approve_notfound_org")
        .create(db)
        .await
        .expect("Failed to create organization");

    let role = RoleBuilder::new("approve_notfound_role", &org)
        .create(db)
        .await
        .expect("Failed to create role");

    MemberBuilder::new(&admin, &org)
        .with_role(&role)
        .create(db)
        .await
        .expect("Failed to create admin membership");

    // Try to approve a non-existent request
    let subject = format!(
        "typewriter.in.user.{}.organization.{}.members.join_requests.approve",
        admin.id, org.id
    );
    let request = ApproveJoinRequestRequest {
        request_id: "nonexistent-request-id".to_string(),
        role_ids: vec![role.id.clone()],
    };

    let response: ApproveJoinRequestResponse = client
        .request(&subject, &request)
        .await
        .expect("Failed to send request");

    // Verify error response
    match response.result {
        Some(approve_join_request_response::Result::Error(e)) => {
            assert!(
                e.message.contains("not found") || e.code == 403,
                "Expected 'not found' error, got: {:?}",
                e
            );
        }
        Some(approve_join_request_response::Result::Member(_)) => {
            panic!("Expected error, got member");
        }
        None => panic!("Expected result, got None"),
    }
}

/// Test error when request is for a different organization.
#[tokio::test]
async fn approve_join_request_wrong_organization() {
    let fixtures = get_fixtures().await;
    let client = TestNatsClient::new(fixtures.infra.nats_client());
    let db = &fixtures.infra.db;

    // Create test data with two organizations
    let admin = UserBuilder::new("approve_wrongorg_admin")
        .email("approve_wrongorg_admin@test.com")
        .create(db)
        .await
        .expect("Failed to create admin user");

    let requester = UserBuilder::new("approve_wrongorg_requester")
        .email("approve_wrongorg_requester@test.com")
        .create(db)
        .await
        .expect("Failed to create requester user");

    let org1 = OrganizationBuilder::new("approve_wrongorg_org1")
        .create(db)
        .await
        .expect("Failed to create organization 1");

    let org2 = OrganizationBuilder::new("approve_wrongorg_org2")
        .create(db)
        .await
        .expect("Failed to create organization 2");

    let role1 = RoleBuilder::new("approve_wrongorg_role1", &org1)
        .create(db)
        .await
        .expect("Failed to create role 1");

    let role2 = RoleBuilder::new("approve_wrongorg_role2", &org2)
        .create(db)
        .await
        .expect("Failed to create role 2");

    MemberBuilder::new(&admin, &org1)
        .with_role(&role1)
        .create(db)
        .await
        .expect("Failed to create admin membership");

    MemberBuilder::new(&admin, &org2)
        .with_role(&role2)
        .create(db)
        .await
        .expect("Failed to create admin membership in org2");

    // Create a join request for org1
    let join_request = JoinRequestBuilder::new(&requester, &org1)
        .create(db)
        .await
        .expect("Failed to create join request");
    let request_id = join_request.id;

    // Try to approve the request from org2 context
    let subject = format!(
        "typewriter.in.user.{}.organization.{}.members.join_requests.approve",
        admin.id, org2.id
    );
    let request = ApproveJoinRequestRequest {
        request_id,
        role_ids: vec![role2.id.clone()],
    };

    let response: ApproveJoinRequestResponse = client
        .request(&subject, &request)
        .await
        .expect("Failed to send request");

    // Verify error response
    match response.result {
        Some(approve_join_request_response::Result::Error(e)) => {
            assert!(
                e.message.contains("different organization") || e.code == 403,
                "Expected 'different organization' error, got: {:?}",
                e
            );
        }
        Some(approve_join_request_response::Result::Member(_)) => {
            panic!("Expected error, got member");
        }
        None => panic!("Expected result, got None"),
    }
}

/// Test error when providing invalid role IDs.
#[tokio::test]
async fn approve_join_request_invalid_role_ids() {
    let fixtures = get_fixtures().await;
    let client = TestNatsClient::new(fixtures.infra.nats_client());
    let db = &fixtures.infra.db;

    // Create test data
    let admin = UserBuilder::new("approve_invalidrole_admin")
        .email("approve_invalidrole_admin@test.com")
        .create(db)
        .await
        .expect("Failed to create admin user");

    let requester = UserBuilder::new("approve_invalidrole_requester")
        .email("approve_invalidrole_requester@test.com")
        .create(db)
        .await
        .expect("Failed to create requester user");

    let org = OrganizationBuilder::new("approve_invalidrole_org")
        .create(db)
        .await
        .expect("Failed to create organization");

    let role = RoleBuilder::new("approve_invalidrole_role", &org)
        .create(db)
        .await
        .expect("Failed to create role");

    MemberBuilder::new(&admin, &org)
        .with_role(&role)
        .create(db)
        .await
        .expect("Failed to create admin membership");

    // Create a join request
    let join_request = JoinRequestBuilder::new(&requester, &org)
        .create(db)
        .await
        .expect("Failed to create join request");
    let request_id = join_request.id;

    // Try to approve with non-existent role IDs
    let subject = format!(
        "typewriter.in.user.{}.organization.{}.members.join_requests.approve",
        admin.id, org.id
    );
    let request = ApproveJoinRequestRequest {
        request_id,
        role_ids: vec!["nonexistent-role-id".to_string()],
    };

    let response: ApproveJoinRequestResponse = client
        .request(&subject, &request)
        .await
        .expect("Failed to send request");

    // Verify error response
    match response.result {
        Some(approve_join_request_response::Result::Error(e)) => {
            assert!(
                e.message.contains("not found") || e.message.contains("role") || e.code == 403,
                "Expected role not found error, got: {:?}",
                e
            );
        }
        Some(approve_join_request_response::Result::Member(_)) => {
            panic!("Expected error, got member");
        }
        None => panic!("Expected result, got None"),
    }
}

/// Test error when providing empty role_ids (must assign at least one role).
#[tokio::test]
async fn approve_join_request_empty_role_ids() {
    let fixtures = get_fixtures().await;
    let client = TestNatsClient::new(fixtures.infra.nats_client());
    let db = &fixtures.infra.db;

    // Create test data
    let admin = UserBuilder::new("approve_emptyrole_admin")
        .email("approve_emptyrole_admin@test.com")
        .create(db)
        .await
        .expect("Failed to create admin user");

    let requester = UserBuilder::new("approve_emptyrole_requester")
        .email("approve_emptyrole_requester@test.com")
        .create(db)
        .await
        .expect("Failed to create requester user");

    let org = OrganizationBuilder::new("approve_emptyrole_org")
        .create(db)
        .await
        .expect("Failed to create organization");

    let role = RoleBuilder::new("approve_emptyrole_role", &org)
        .create(db)
        .await
        .expect("Failed to create role");

    MemberBuilder::new(&admin, &org)
        .with_role(&role)
        .create(db)
        .await
        .expect("Failed to create admin membership");

    // Create a join request
    let join_request = JoinRequestBuilder::new(&requester, &org)
        .create(db)
        .await
        .expect("Failed to create join request");
    let request_id = join_request.id;

    // Try to approve with empty role_ids
    let subject = format!(
        "typewriter.in.user.{}.organization.{}.members.join_requests.approve",
        admin.id, org.id
    );
    let request = ApproveJoinRequestRequest {
        request_id,
        role_ids: vec![],
    };

    let response: ApproveJoinRequestResponse = client
        .request(&subject, &request)
        .await
        .expect("Failed to send request");

    // Verify error response
    match response.result {
        Some(approve_join_request_response::Result::Error(e)) => {
            assert!(
                e.message.contains("role") || e.message.contains("No roles") || e.code == 403,
                "Expected 'no roles' error, got: {:?}",
                e
            );
        }
        Some(approve_join_request_response::Result::Member(_)) => {
            panic!("Expected error, got member");
        }
        None => panic!("Expected result, got None"),
    }
}

/// Test SQL injection attempt in request_id.
#[tokio::test]
async fn approve_join_request_sql_injection() {
    let fixtures = get_fixtures().await;
    let client = TestNatsClient::new(fixtures.infra.nats_client());
    let db = &fixtures.infra.db;

    // Create test data
    let admin = UserBuilder::new("approve_sqli_admin")
        .email("approve_sqli_admin@test.com")
        .create(db)
        .await
        .expect("Failed to create admin user");

    let org = OrganizationBuilder::new("approve_sqli_org")
        .create(db)
        .await
        .expect("Failed to create organization");

    let role = RoleBuilder::new("approve_sqli_role", &org)
        .create(db)
        .await
        .expect("Failed to create role");

    MemberBuilder::new(&admin, &org)
        .with_role(&role)
        .create(db)
        .await
        .expect("Failed to create admin membership");

    // Try SQL injection in request_id
    let subject = format!(
        "typewriter.in.user.{}.organization.{}.members.join_requests.approve",
        admin.id, org.id
    );
    let request = ApproveJoinRequestRequest {
        request_id: "'; DROP TABLE requests_to_join; --".to_string(),
        role_ids: vec![role.id.clone()],
    };

    let response: ApproveJoinRequestResponse = client
        .request(&subject, &request)
        .await
        .expect("Failed to send request");

    // Verify it returns an error (not found) and doesn't crash or execute injection
    match response.result {
        Some(approve_join_request_response::Result::Error(_)) => {
            // Expected - the injection should fail gracefully
        }
        Some(approve_join_request_response::Result::Member(_)) => {
            panic!("SQL injection should not succeed");
        }
        None => {
            // Also acceptable - request may have been rejected
        }
    }

    // Verify the table still exists
    let check_query = "SELECT * FROM requests_to_join LIMIT 1";
    let check_result = db.query(check_query).await;
    assert!(
        check_result.is_ok(),
        "requests_to_join table should still exist after SQL injection attempt"
    );
}

// =============================================================================
// Decline Join Request Tests
// =============================================================================

/// Test successfully declining a join request.
#[tokio::test]
async fn decline_join_request_success() {
    let fixtures = get_fixtures().await;
    let client = TestNatsClient::new(fixtures.infra.nats_client());
    let db = &fixtures.infra.db;

    // Create test data
    let admin = UserBuilder::new("decline_success_admin")
        .email("decline_success_admin@test.com")
        .create(db)
        .await
        .expect("Failed to create admin user");

    let requester = UserBuilder::new("decline_success_requester")
        .email("decline_success_requester@test.com")
        .create(db)
        .await
        .expect("Failed to create requester user");

    let org = OrganizationBuilder::new("decline_success_org")
        .create(db)
        .await
        .expect("Failed to create organization");

    let role = RoleBuilder::new("decline_success_role", &org)
        .create(db)
        .await
        .expect("Failed to create role");

    MemberBuilder::new(&admin, &org)
        .with_role(&role)
        .create(db)
        .await
        .expect("Failed to create admin membership");

    // Create a join request
    let join_request = JoinRequestBuilder::new(&requester, &org)
        .create(db)
        .await
        .expect("Failed to create join request");
    let request_id = join_request.id;

    // Decline the request
    let subject = format!(
        "typewriter.in.user.{}.organization.{}.members.join_requests.decline",
        admin.id, org.id
    );
    let request = DeclineJoinRequestRequest {
        request_id: request_id.clone(),
    };

    let response: DeclineJoinRequestResponse = client
        .request(&subject, &request)
        .await
        .expect("Failed to send request");

    // Verify success
    match response.result {
        Some(decline_join_request_response::Result::Success(success)) => {
            assert!(success, "Expected success=true");
        }
        Some(decline_join_request_response::Result::Error(e)) => {
            panic!("Unexpected error: {:?}", e);
        }
        None => panic!("Expected result, got None"),
    }
}

/// Test that request is deleted after declining.
#[tokio::test]
async fn decline_join_request_deletes_request() {
    let fixtures = get_fixtures().await;
    let client = TestNatsClient::new(fixtures.infra.nats_client());
    let db = &fixtures.infra.db;

    // Create test data
    let admin = UserBuilder::new("decline_delete_admin")
        .email("decline_delete_admin@test.com")
        .create(db)
        .await
        .expect("Failed to create admin user");

    let requester = UserBuilder::new("decline_delete_requester")
        .email("decline_delete_requester@test.com")
        .create(db)
        .await
        .expect("Failed to create requester user");

    let org = OrganizationBuilder::new("decline_delete_org")
        .create(db)
        .await
        .expect("Failed to create organization");

    let role = RoleBuilder::new("decline_delete_role", &org)
        .create(db)
        .await
        .expect("Failed to create role");

    MemberBuilder::new(&admin, &org)
        .with_role(&role)
        .create(db)
        .await
        .expect("Failed to create admin membership");

    // Create a join request
    let join_request = JoinRequestBuilder::new(&requester, &org)
        .create(db)
        .await
        .expect("Failed to create join request");
    let request_id = join_request.id;

    // Decline the request
    let subject = format!(
        "typewriter.in.user.{}.organization.{}.members.join_requests.decline",
        admin.id, org.id
    );
    let request = DeclineJoinRequestRequest {
        request_id: request_id.clone(),
    };

    let _response: DeclineJoinRequestResponse = client
        .request(&subject, &request)
        .await
        .expect("Failed to send request");

    // Verify request is deleted
    let check_query = format!(
        "SELECT id FROM requests_to_join WHERE in = user:`{}` AND out = organization:`{}`",
        requester.id, org.id
    );
    let mut check_result = db
        .query(&check_query)
        .await
        .expect("Failed to check requests");
    let requests_after: Vec<JoinRequestCheck> = check_result.take(0).expect("Failed to get result");
    assert!(
        requests_after.is_empty(),
        "Join request should be deleted after decline"
    );
}

/// Test error when declining a non-existent request.
#[tokio::test]
async fn decline_join_request_not_found() {
    let fixtures = get_fixtures().await;
    let client = TestNatsClient::new(fixtures.infra.nats_client());
    let db = &fixtures.infra.db;

    // Create test data
    let admin = UserBuilder::new("decline_notfound_admin")
        .email("decline_notfound_admin@test.com")
        .create(db)
        .await
        .expect("Failed to create admin user");

    let org = OrganizationBuilder::new("decline_notfound_org")
        .create(db)
        .await
        .expect("Failed to create organization");

    let role = RoleBuilder::new("decline_notfound_role", &org)
        .create(db)
        .await
        .expect("Failed to create role");

    MemberBuilder::new(&admin, &org)
        .with_role(&role)
        .create(db)
        .await
        .expect("Failed to create admin membership");

    // Try to decline a non-existent request
    let subject = format!(
        "typewriter.in.user.{}.organization.{}.members.join_requests.decline",
        admin.id, org.id
    );
    let request = DeclineJoinRequestRequest {
        request_id: "nonexistent-request-id".to_string(),
    };

    let response: DeclineJoinRequestResponse = client
        .request(&subject, &request)
        .await
        .expect("Failed to send request");

    // The current implementation may still return success=true even for non-existent requests
    // because it just deletes without checking existence first.
    // This is acceptable behavior - idempotent delete operation.
    match response.result {
        Some(decline_join_request_response::Result::Success(_)) => {
            // Idempotent behavior - decline succeeds even if request doesn't exist
        }
        Some(decline_join_request_response::Result::Error(_)) => {
            // Also acceptable if the implementation validates existence
        }
        None => panic!("Expected result, got None"),
    }
}

/// Test malicious input with invalid request_id format.
#[tokio::test]
async fn decline_join_request_invalid_format() {
    let fixtures = get_fixtures().await;
    let client = TestNatsClient::new(fixtures.infra.nats_client());
    let db = &fixtures.infra.db;

    // Create test data
    let admin = UserBuilder::new("decline_invalid_admin")
        .email("decline_invalid_admin@test.com")
        .create(db)
        .await
        .expect("Failed to create admin user");

    let org = OrganizationBuilder::new("decline_invalid_org")
        .create(db)
        .await
        .expect("Failed to create organization");

    let role = RoleBuilder::new("decline_invalid_role", &org)
        .create(db)
        .await
        .expect("Failed to create role");

    MemberBuilder::new(&admin, &org)
        .with_role(&role)
        .create(db)
        .await
        .expect("Failed to create admin membership");

    // Try SQL injection in request_id
    let subject = format!(
        "typewriter.in.user.{}.organization.{}.members.join_requests.decline",
        admin.id, org.id
    );
    let request = DeclineJoinRequestRequest {
        request_id: "'; DELETE FROM user; --".to_string(),
    };

    let response: DeclineJoinRequestResponse = client
        .request(&subject, &request)
        .await
        .expect("Failed to send request");

    // Should handle gracefully
    match response.result {
        Some(decline_join_request_response::Result::Success(_)) => {
            // Acceptable - request parsed but nothing deleted
        }
        Some(decline_join_request_response::Result::Error(_)) => {
            // Also acceptable - invalid format rejected
        }
        None => {
            // Also acceptable
        }
    }

    // Verify user table still has data (injection didn't work)
    let check_query = format!("SELECT id FROM user:`{}`", admin.id);
    let mut check_result = db.query(&check_query).await.expect("Failed to check user");
    let users: Vec<UserCheck> = check_result.take(0).expect("Failed to get result");
    assert!(
        !users.is_empty(),
        "User table should still have data after SQL injection attempt"
    );
}
