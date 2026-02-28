//! Tests for updating organization member roles.
//!
//! Subject: `typewriter.in.user.<user_id>.organization.<org_id>.members.update`
//! Request: `UpdateMemberRolesRequest` with `user_id: String`, `role_ids: Vec<String>`
//! Response: `UpdateMemberRolesResponse` with `member: OrganizationMember` or error
//!
//! Note: Non-assignable roles are preserved, assignable roles are replaced.

use anyhow::Result;

use backend_tests::proto::typewriter::api::v1::{self, update_member_roles_response};
use backend_tests::{
    MemberBuilder, OrganizationBuilder, RoleBuilder, TestNatsClient, UserBuilder, get_fixtures,
};

/// Helper to create the NATS subject for updating member roles.
fn update_member_subject(user_id: &str, org_id: &str) -> String {
    format!(
        "typewriter.in.user.{}.organization.{}.members.update",
        user_id, org_id
    )
}

/// Test updating a member to have a different role.
#[tokio::test]
async fn test_update_member_different_role() -> Result<()> {
    let fixtures = get_fixtures().await;

    // Create test data
    let org = OrganizationBuilder::new("update_member_diff_org")
        .create(&fixtures.infra.db)
        .await?;

    let initial_role = RoleBuilder::new("update_initial_role", &org)
        .create(&fixtures.infra.db)
        .await?;

    let new_role = RoleBuilder::new("update_new_role", &org)
        .create(&fixtures.infra.db)
        .await?;

    let admin_user = UserBuilder::new("Update Admin User")
        .email("update.admin@example.com")
        .create(&fixtures.infra.db)
        .await?;

    let target_user = UserBuilder::new("Update Target User")
        .email("update.target@example.com")
        .create(&fixtures.infra.db)
        .await?;

    // Create admin membership
    MemberBuilder::new(&admin_user, &org)
        .with_role(&initial_role)
        .create(&fixtures.infra.db)
        .await?;

    // Create target user membership with initial role
    MemberBuilder::new(&target_user, &org)
        .with_role(&initial_role)
        .create(&fixtures.infra.db)
        .await?;

    // Export database state before the update for debugging
    backend_tests::export_db_state(
        &fixtures.infra.surrealdb_http_url,
        "/tmp/test_update_member_state.surql",
    )
    .await?;

    let nats = TestNatsClient::new(fixtures.infra.nats_client());
    let subject = update_member_subject(&admin_user.id, &org.id);

    let response: v1::UpdateMemberRolesResponse = nats
        .request(
            &subject,
            &v1::UpdateMemberRolesRequest {
                user_id: target_user.id.clone(),
                role_ids: vec![new_role.id.clone()],
            },
        )
        .await?;

    match response.result {
        Some(update_member_roles_response::Result::Member(member)) => {
            assert_eq!(member.name, Some("Update Target User".to_string()));
            assert_eq!(member.roles.len(), 1, "Expected exactly one role");
            assert_eq!(
                member.roles[0].name,
                Some("update_new_role".to_string()),
                "Role should be updated to new role"
            );
        }
        Some(update_member_roles_response::Result::Error(err)) => {
            panic!("Unexpected error: {} - {}", err.code, err.message);
        }
        None => panic!("Expected result in response"),
    }

    Ok(())
}

/// Test updating a member to have multiple roles.
#[tokio::test]
async fn test_update_member_multiple_roles() -> Result<()> {
    let fixtures = get_fixtures().await;

    // Create test data
    let org = OrganizationBuilder::new("update_member_multi_org")
        .create(&fixtures.infra.db)
        .await?;

    let role1 = RoleBuilder::new("update_multi_role1", &org)
        .create(&fixtures.infra.db)
        .await?;

    let role2 = RoleBuilder::new("update_multi_role2", &org)
        .create(&fixtures.infra.db)
        .await?;

    let role3 = RoleBuilder::new("update_multi_role3", &org)
        .create(&fixtures.infra.db)
        .await?;

    let admin_user = UserBuilder::new("Update Multi Admin User")
        .email("update.multi.admin@example.com")
        .create(&fixtures.infra.db)
        .await?;

    let target_user = UserBuilder::new("Update Multi Target User")
        .email("update.multi.target@example.com")
        .create(&fixtures.infra.db)
        .await?;

    // Create memberships
    MemberBuilder::new(&admin_user, &org)
        .with_role(&role1)
        .create(&fixtures.infra.db)
        .await?;

    MemberBuilder::new(&target_user, &org)
        .with_role(&role1)
        .create(&fixtures.infra.db)
        .await?;

    let nats = TestNatsClient::new(fixtures.infra.nats_client());
    let subject = update_member_subject(&admin_user.id, &org.id);

    let response: v1::UpdateMemberRolesResponse = nats
        .request(
            &subject,
            &v1::UpdateMemberRolesRequest {
                user_id: target_user.id.clone(),
                role_ids: vec![role1.id.clone(), role2.id.clone(), role3.id.clone()],
            },
        )
        .await?;

    match response.result {
        Some(update_member_roles_response::Result::Member(member)) => {
            assert_eq!(member.roles.len(), 3, "Expected three roles");

            let role_names: Vec<String> =
                member.roles.iter().filter_map(|r| r.name.clone()).collect();
            assert!(
                role_names.contains(&"update_multi_role1".to_string()),
                "Should have role1"
            );
            assert!(
                role_names.contains(&"update_multi_role2".to_string()),
                "Should have role2"
            );
            assert!(
                role_names.contains(&"update_multi_role3".to_string()),
                "Should have role3"
            );
        }
        Some(update_member_roles_response::Result::Error(err)) => {
            panic!("Unexpected error: {} - {}", err.code, err.message);
        }
        None => panic!("Expected result in response"),
    }

    Ok(())
}

/// Test that non-assignable roles are preserved when updating.
#[tokio::test]
async fn test_update_member_preserve_non_assignable_roles() -> Result<()> {
    let fixtures = get_fixtures().await;

    // Create test data
    let org = OrganizationBuilder::new("update_preserve_na_org")
        .create(&fixtures.infra.db)
        .await?;

    // Create a non-assignable role (like "owner" or system role)
    let non_assignable_role = RoleBuilder::new("update_na_owner", &org)
        .not_assignable()
        .priority(100)
        .create(&fixtures.infra.db)
        .await?;

    let assignable_role1 = RoleBuilder::new("update_na_role1", &org)
        .create(&fixtures.infra.db)
        .await?;

    let assignable_role2 = RoleBuilder::new("update_na_role2", &org)
        .create(&fixtures.infra.db)
        .await?;

    let admin_user = UserBuilder::new("Preserve NA Admin User")
        .email("preserve.na.admin@example.com")
        .create(&fixtures.infra.db)
        .await?;

    let target_user = UserBuilder::new("Preserve NA Target User")
        .email("preserve.na.target@example.com")
        .create(&fixtures.infra.db)
        .await?;

    // Create admin membership
    MemberBuilder::new(&admin_user, &org)
        .with_role(&assignable_role1)
        .create(&fixtures.infra.db)
        .await?;

    // Create target membership with both non-assignable and assignable roles
    MemberBuilder::new(&target_user, &org)
        .with_roles(&[&non_assignable_role, &assignable_role1])
        .create(&fixtures.infra.db)
        .await?;

    let nats = TestNatsClient::new(fixtures.infra.nats_client());
    let subject = update_member_subject(&admin_user.id, &org.id);

    // Update to a different assignable role (should preserve non-assignable)
    let response: v1::UpdateMemberRolesResponse = nats
        .request(
            &subject,
            &v1::UpdateMemberRolesRequest {
                user_id: target_user.id.clone(),
                role_ids: vec![assignable_role2.id.clone()],
            },
        )
        .await?;

    match response.result {
        Some(update_member_roles_response::Result::Member(member)) => {
            assert_eq!(
                member.roles.len(),
                2,
                "Expected two roles (preserved + new)"
            );

            let role_names: Vec<String> =
                member.roles.iter().filter_map(|r| r.name.clone()).collect();
            assert!(
                role_names.contains(&"update_na_owner".to_string()),
                "Non-assignable role should be preserved"
            );
            assert!(
                role_names.contains(&"update_na_role2".to_string()),
                "New assignable role should be added"
            );
            assert!(
                !role_names.contains(&"update_na_role1".to_string()),
                "Old assignable role should be removed"
            );
        }
        Some(update_member_roles_response::Result::Error(err)) => {
            panic!("Unexpected error: {} - {}", err.code, err.message);
        }
        None => panic!("Expected result in response"),
    }

    Ok(())
}

/// Test error when member is not found.
#[tokio::test]
async fn test_update_member_not_found() -> Result<()> {
    let fixtures = get_fixtures().await;

    // Create test data
    let org = OrganizationBuilder::new("update_not_found_org")
        .create(&fixtures.infra.db)
        .await?;

    let role = RoleBuilder::new("update_not_found_role", &org)
        .create(&fixtures.infra.db)
        .await?;

    let user = UserBuilder::new("Update Not Found User")
        .email("update.notfound@example.com")
        .create(&fixtures.infra.db)
        .await?;

    MemberBuilder::new(&user, &org)
        .with_role(&role)
        .create(&fixtures.infra.db)
        .await?;

    // Use a non-existent user ID
    let fake_user_id = "00000000-0000-0000-0000-000000000000";

    let nats = TestNatsClient::new(fixtures.infra.nats_client());
    let subject = update_member_subject(&user.id, &org.id);

    let response: v1::UpdateMemberRolesResponse = nats
        .request(
            &subject,
            &v1::UpdateMemberRolesRequest {
                user_id: fake_user_id.to_string(),
                role_ids: vec![role.id.clone()],
            },
        )
        .await?;

    // Verify error response
    match response.result {
        Some(update_member_roles_response::Result::Error(err)) => {
            // Should return a not found error
            assert!(
                err.message.to_lowercase().contains("not found")
                    || err.message.to_lowercase().contains("member"),
                "Error message should indicate member not found: {}",
                err.message
            );
        }
        Some(update_member_roles_response::Result::Member(_)) => {
            panic!("Expected error but got success");
        }
        None => panic!("Expected result in response"),
    }

    Ok(())
}

/// Test error when role is not found.
#[tokio::test]
async fn test_update_member_role_not_found() -> Result<()> {
    let fixtures = get_fixtures().await;

    // Create test data
    let org = OrganizationBuilder::new("update_role_not_found_org")
        .create(&fixtures.infra.db)
        .await?;

    let role = RoleBuilder::new("update_rnf_role", &org)
        .create(&fixtures.infra.db)
        .await?;

    let admin_user = UserBuilder::new("Update RNF Admin User")
        .email("update.rnf.admin@example.com")
        .create(&fixtures.infra.db)
        .await?;

    let target_user = UserBuilder::new("Update RNF Target User")
        .email("update.rnf.target@example.com")
        .create(&fixtures.infra.db)
        .await?;

    MemberBuilder::new(&admin_user, &org)
        .with_role(&role)
        .create(&fixtures.infra.db)
        .await?;

    MemberBuilder::new(&target_user, &org)
        .with_role(&role)
        .create(&fixtures.infra.db)
        .await?;

    // Use a non-existent role ID
    let fake_role_id = "00000000-0000-0000-0000-000000000001";

    let nats = TestNatsClient::new(fixtures.infra.nats_client());
    let subject = update_member_subject(&admin_user.id, &org.id);

    let response: v1::UpdateMemberRolesResponse = nats
        .request(
            &subject,
            &v1::UpdateMemberRolesRequest {
                user_id: target_user.id.clone(),
                role_ids: vec![fake_role_id.to_string()],
            },
        )
        .await?;

    // Verify error response
    match response.result {
        Some(update_member_roles_response::Result::Error(err)) => {
            assert!(
                err.message.to_lowercase().contains("not found")
                    || err.message.to_lowercase().contains("role"),
                "Error message should indicate role not found: {}",
                err.message
            );
        }
        Some(update_member_roles_response::Result::Member(_)) => {
            panic!("Expected error but got success");
        }
        None => panic!("Expected result in response"),
    }

    Ok(())
}

/// Test error when trying to remove all roles (must have at least one).
#[tokio::test]
async fn test_update_member_empty_roles_error() -> Result<()> {
    let fixtures = get_fixtures().await;

    // Create test data
    let org = OrganizationBuilder::new("update_empty_roles_org")
        .create(&fixtures.infra.db)
        .await?;

    let role = RoleBuilder::new("update_empty_role", &org)
        .create(&fixtures.infra.db)
        .await?;

    let admin_user = UserBuilder::new("Update Empty Admin User")
        .email("update.empty.admin@example.com")
        .create(&fixtures.infra.db)
        .await?;

    let target_user = UserBuilder::new("Update Empty Target User")
        .email("update.empty.target@example.com")
        .create(&fixtures.infra.db)
        .await?;

    MemberBuilder::new(&admin_user, &org)
        .with_role(&role)
        .create(&fixtures.infra.db)
        .await?;

    MemberBuilder::new(&target_user, &org)
        .with_role(&role)
        .create(&fixtures.infra.db)
        .await?;

    let nats = TestNatsClient::new(fixtures.infra.nats_client());
    let subject = update_member_subject(&admin_user.id, &org.id);

    // Send request with empty role_ids
    let response: v1::UpdateMemberRolesResponse = nats
        .request(
            &subject,
            &v1::UpdateMemberRolesRequest {
                user_id: target_user.id.clone(),
                role_ids: vec![], // Empty roles
            },
        )
        .await?;

    // Verify error response
    match response.result {
        Some(update_member_roles_response::Result::Error(err)) => {
            assert!(
                err.message.to_lowercase().contains("role")
                    || err.message.to_lowercase().contains("empty")
                    || err.message.to_lowercase().contains("at least"),
                "Error message should indicate at least one role is required: {}",
                err.message
            );
        }
        Some(update_member_roles_response::Result::Member(_)) => {
            panic!("Expected error but got success");
        }
        None => panic!("Expected result in response"),
    }

    Ok(())
}

/// Test malicious input: invalid UUIDs in role_ids.
#[tokio::test]
async fn test_update_member_invalid_role_uuid() -> Result<()> {
    let fixtures = get_fixtures().await;

    // Create test data
    let org = OrganizationBuilder::new("update_invalid_uuid_org")
        .create(&fixtures.infra.db)
        .await?;

    let role = RoleBuilder::new("update_inv_uuid_role", &org)
        .create(&fixtures.infra.db)
        .await?;

    let admin_user = UserBuilder::new("Update Invalid UUID Admin")
        .email("update.invuuid.admin@example.com")
        .create(&fixtures.infra.db)
        .await?;

    let target_user = UserBuilder::new("Update Invalid UUID Target")
        .email("update.invuuid.target@example.com")
        .create(&fixtures.infra.db)
        .await?;

    MemberBuilder::new(&admin_user, &org)
        .with_role(&role)
        .create(&fixtures.infra.db)
        .await?;

    MemberBuilder::new(&target_user, &org)
        .with_role(&role)
        .create(&fixtures.infra.db)
        .await?;

    // Test various invalid UUID formats
    let invalid_uuids = vec![
        "not-a-uuid",
        "12345",
        "",
        "'; DROP TABLE roles; --",
        "<script>alert('xss')</script>",
        "../../../../etc/passwd",
    ];

    let nats = TestNatsClient::new(fixtures.infra.nats_client());
    let subject = update_member_subject(&admin_user.id, &org.id);

    for invalid_uuid in invalid_uuids {
        let response: v1::UpdateMemberRolesResponse = nats
            .request(
                &subject,
                &v1::UpdateMemberRolesRequest {
                    user_id: target_user.id.clone(),
                    role_ids: vec![invalid_uuid.to_string()],
                },
            )
            .await?;

        // Should return an error, not crash
        match response.result {
            Some(update_member_roles_response::Result::Error(_err)) => {
                // Expected - invalid UUID should result in error
            }
            Some(update_member_roles_response::Result::Member(_)) => {
                panic!(
                    "Expected error for invalid UUID '{}' but got success",
                    invalid_uuid
                );
            }
            None => {
                // Also acceptable - no result could indicate handled error
            }
        }
    }

    Ok(())
}

/// Test malicious input: invalid user_id format.
#[tokio::test]
async fn test_update_member_invalid_user_id() -> Result<()> {
    let fixtures = get_fixtures().await;

    // Create test data
    let org = OrganizationBuilder::new("update_inv_member_id_org")
        .create(&fixtures.infra.db)
        .await?;

    let role = RoleBuilder::new("update_inv_mid_role", &org)
        .create(&fixtures.infra.db)
        .await?;

    let user = UserBuilder::new("Update Invalid MID User")
        .email("update.invmid@example.com")
        .create(&fixtures.infra.db)
        .await?;

    MemberBuilder::new(&user, &org)
        .with_role(&role)
        .create(&fixtures.infra.db)
        .await?;

    // Test various invalid user_id formats
    let invalid_user_ids = vec![
        "not-a-valid-id",
        "'; DROP TABLE member_of; --",
        "<script>alert('xss')</script>",
        "../../../../etc/passwd",
        "",
    ];

    let nats = TestNatsClient::new(fixtures.infra.nats_client());
    let subject = update_member_subject(&user.id, &org.id);

    for invalid_id in invalid_user_ids {
        let response: v1::UpdateMemberRolesResponse = nats
            .request(
                &subject,
                &v1::UpdateMemberRolesRequest {
                    user_id: invalid_id.to_string(),
                    role_ids: vec![role.id.clone()],
                },
            )
            .await?;

        // Should return an error, not crash
        match response.result {
            Some(update_member_roles_response::Result::Error(_err)) => {
                // Expected - invalid user ID should result in error
            }
            Some(update_member_roles_response::Result::Member(_)) => {
                panic!(
                    "Expected error for invalid user_id '{}' but got success",
                    invalid_id
                );
            }
            None => {
                // Also acceptable - no result could indicate handled error
            }
        }
    }

    Ok(())
}
