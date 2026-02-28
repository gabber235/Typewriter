//! Integration tests for the organization roles LIST endpoint.
//!
//! Subject: `typewriter.in.user.<user_id>.organization.<org_id>.roles.list`
//! Request: `ListRolesRequest` (empty)
//! Response: `ListRolesResponse` with `roles: Vec<Role>` or `error: Error`

use anyhow::Result;

use backend_tests::proto::typewriter::api::v1::{self, list_roles_response};
use backend_tests::{
    MemberBuilder, OrganizationBuilder, RoleBuilder, TestNatsClient, UserBuilder, get_fixtures,
};

/// Helper to create the NATS subject for listing roles.
fn list_roles_subject(user_id: &str, org_id: &str) -> String {
    format!(
        "typewriter.in.user.{}.organization.{}.roles.list",
        user_id, org_id
    )
}

/// Test listing roles for an organization with no roles.
///
/// Verifies that an empty list is returned when the organization has no roles.
#[tokio::test]
async fn test_list_roles_empty_organization() -> Result<()> {
    let fixtures = get_fixtures().await;

    // Create test user
    let user = UserBuilder::new("list_roles_empty_user")
        .email("list_roles_empty@example.com")
        .create(&fixtures.infra.db)
        .await?;

    // Create organization without any roles
    let org = OrganizationBuilder::new("list_roles_empty_org")
        .create(&fixtures.infra.db)
        .await?;

    // We need to make the user a member, but that requires a role.
    // For this test, we'll check if the endpoint works without membership.
    // If it requires membership, this test documents that behavior.

    let nats = TestNatsClient::new(fixtures.infra.nats_client());
    let subject = list_roles_subject(&user.id, &org.id);

    let response: v1::ListRolesResponse = nats.request(&subject, &v1::ListRolesRequest {}).await?;

    match response.result {
        Some(list_roles_response::Result::Roles(list)) => {
            assert!(
                list.roles.is_empty(),
                "Expected empty roles list for organization without roles, got {} roles",
                list.roles.len()
            );
        }
        Some(list_roles_response::Result::Error(e)) => {
            // If endpoint requires membership, this documents that behavior
            panic!(
                "List roles failed with error (may indicate membership required): {:?}",
                e
            );
        }
        None => {
            panic!("Expected roles list or error, got no result");
        }
    }

    Ok(())
}

/// Test listing a single role with all fields verified.
///
/// Verifies that all role fields are correctly returned:
/// - id, name, color, default_role, assignable, deletable
#[tokio::test]
async fn test_list_roles_single_role_all_fields() -> Result<()> {
    let fixtures = get_fixtures().await;

    let user = UserBuilder::new("list_roles_single_user")
        .email("list_roles_single@example.com")
        .create(&fixtures.infra.db)
        .await?;

    let org = OrganizationBuilder::new("list_roles_single_org")
        .create(&fixtures.infra.db)
        .await?;

    // Create a role with specific color
    let test_color: u32 = 0xFF42A5F5; // Blue color in ARGB
    let role = RoleBuilder::new("test_admin_role", &org)
        .color(test_color)
        .priority(10)
        .create(&fixtures.infra.db)
        .await?;

    // Add user as member with this role
    MemberBuilder::new(&user, &org)
        .with_role(&role)
        .create(&fixtures.infra.db)
        .await?;

    let nats = TestNatsClient::new(fixtures.infra.nats_client());
    let subject = list_roles_subject(&user.id, &org.id);

    let response: v1::ListRolesResponse = nats.request(&subject, &v1::ListRolesRequest {}).await?;

    match response.result {
        Some(list_roles_response::Result::Roles(list)) => {
            assert_eq!(
                list.roles.len(),
                1,
                "Expected exactly 1 role, got {}",
                list.roles.len()
            );

            let returned_role = &list.roles[0];

            assert_eq!(
                returned_role.role_id, role.id,
                "Role ID mismatch: expected '{}', got '{}'",
                role.id, returned_role.role_id
            );

            assert_eq!(
                returned_role.name,
                Some("test_admin_role".to_string()),
                "Role name mismatch: expected 'test_admin_role', got '{}'",
                returned_role
                    .name
                    .clone()
                    .unwrap_or("Unknown Role".to_string())
            );

            assert!(
                returned_role.color.is_some(),
                "Expected color to be present"
            );
            let color = returned_role.color.as_ref().unwrap();
            assert_eq!(
                color.value,
                Some(test_color),
                "Color mismatch: expected 0x{:08X}, got {}",
                test_color,
                color
                    .value
                    .map(|v| format!("0x{:08X}", v))
                    .unwrap_or("Unknown Color".to_string())
            );

            // Verify flags (default values from RoleBuilder)
            assert!(
                !returned_role.default_role.unwrap_or_default(),
                "Expected default_role to be false"
            );
            assert!(
                returned_role.assignable.unwrap_or_default(),
                "Expected assignable to be true"
            );
            assert!(
                returned_role.deletable.unwrap_or_default(),
                "Expected deletable to be true"
            );
        }
        Some(list_roles_response::Result::Error(e)) => {
            panic!("Expected roles list, got error: {:?}", e);
        }
        None => {
            panic!("Expected roles list, got no result");
        }
    }

    Ok(())
}

/// Test listing multiple roles.
///
/// Verifies that all roles in an organization are returned.
#[tokio::test]
async fn test_list_roles_multiple_roles() -> Result<()> {
    let fixtures = get_fixtures().await;

    let user = UserBuilder::new("list_roles_multi_user")
        .email("list_roles_multi@example.com")
        .create(&fixtures.infra.db)
        .await?;

    let org = OrganizationBuilder::new("list_roles_multi_org")
        .create(&fixtures.infra.db)
        .await?;

    // Create multiple roles with different priorities
    let admin_role = RoleBuilder::new("multi_admin", &org)
        .priority(100)
        .color(0xFFFF5722) // Orange
        .create(&fixtures.infra.db)
        .await?;

    let editor_role = RoleBuilder::new("multi_editor", &org)
        .priority(50)
        .color(0xFF4CAF50) // Green
        .create(&fixtures.infra.db)
        .await?;

    let viewer_role = RoleBuilder::new("multi_viewer", &org)
        .priority(10)
        .color(0xFF2196F3) // Blue
        .create(&fixtures.infra.db)
        .await?;

    // Add user as member with admin role
    MemberBuilder::new(&user, &org)
        .with_role(&admin_role)
        .create(&fixtures.infra.db)
        .await?;

    let nats = TestNatsClient::new(fixtures.infra.nats_client());
    let subject = list_roles_subject(&user.id, &org.id);

    let response: v1::ListRolesResponse = nats.request(&subject, &v1::ListRolesRequest {}).await?;

    match response.result {
        Some(list_roles_response::Result::Roles(list)) => {
            assert_eq!(
                list.roles.len(),
                3,
                "Expected 3 roles, got {}",
                list.roles.len()
            );

            // Verify all role names are present
            let role_names: Vec<String> =
                list.roles.iter().filter_map(|r| r.name.clone()).collect();
            assert!(
                role_names.contains(&"multi_admin".to_string()),
                "Expected 'multi_admin' role in list, got: {:?}",
                role_names
            );
            assert!(
                role_names.contains(&"multi_editor".to_string()),
                "Expected 'multi_editor' role in list, got: {:?}",
                role_names
            );
            assert!(
                role_names.contains(&"multi_viewer".to_string()),
                "Expected 'multi_viewer' role in list, got: {:?}",
                role_names
            );

            // Verify role IDs are unique
            let role_ids: Vec<&str> = list.roles.iter().map(|r| r.role_id.as_str()).collect();
            let unique_ids: std::collections::HashSet<&str> = role_ids.iter().copied().collect();
            assert_eq!(
                role_ids.len(),
                unique_ids.len(),
                "Role IDs should be unique"
            );
        }
        Some(list_roles_response::Result::Error(e)) => {
            panic!("Expected roles list, got error: {:?}", e);
        }
        None => {
            panic!("Expected roles list, got no result");
        }
    }

    Ok(())
}

/// Test that roles are ordered by priority (highest first).
///
/// Verifies the ordering of roles in the response matches priority ordering.
#[tokio::test]
async fn test_list_roles_ordered_by_priority() -> Result<()> {
    let fixtures = get_fixtures().await;

    let user = UserBuilder::new("list_roles_order_user")
        .email("list_roles_order@example.com")
        .create(&fixtures.infra.db)
        .await?;

    let org = OrganizationBuilder::new("list_roles_order_org")
        .create(&fixtures.infra.db)
        .await?;

    // Create roles in non-priority order to ensure sorting is applied
    let low_priority = RoleBuilder::new("order_low", &org)
        .priority(1)
        .create(&fixtures.infra.db)
        .await?;

    let high_priority = RoleBuilder::new("order_high", &org)
        .priority(100)
        .create(&fixtures.infra.db)
        .await?;

    let mid_priority = RoleBuilder::new("order_mid", &org)
        .priority(50)
        .create(&fixtures.infra.db)
        .await?;

    MemberBuilder::new(&user, &org)
        .with_role(&high_priority)
        .create(&fixtures.infra.db)
        .await?;

    let nats = TestNatsClient::new(fixtures.infra.nats_client());
    let subject = list_roles_subject(&user.id, &org.id);

    let response: v1::ListRolesResponse = nats.request(&subject, &v1::ListRolesRequest {}).await?;

    match response.result {
        Some(list_roles_response::Result::Roles(list)) => {
            assert_eq!(list.roles.len(), 3, "Expected 3 roles");

            // Verify order: highest priority first
            let role_names: Vec<String> =
                list.roles.iter().filter_map(|r| r.name.clone()).collect();
            assert_eq!(
                role_names,
                vec!["order_high", "order_mid", "order_low"]
                    .iter()
                    .map(|s| s.to_string())
                    .collect::<Vec<String>>(),
                "Roles should be ordered by priority (highest first), got: {:?}",
                role_names
            );
        }
        Some(list_roles_response::Result::Error(e)) => {
            panic!("Expected roles list, got error: {:?}", e);
        }
        None => {
            panic!("Expected roles list, got no result");
        }
    }

    Ok(())
}

/// Test default role flag is correctly returned.
///
/// Verifies that a role marked as default has the default_role flag set.
#[tokio::test]
async fn test_list_roles_default_role_flag() -> Result<()> {
    let fixtures = get_fixtures().await;

    let user = UserBuilder::new("list_roles_default_user")
        .email("list_roles_default@example.com")
        .create(&fixtures.infra.db)
        .await?;

    let org = OrganizationBuilder::new("list_roles_default_org")
        .create(&fixtures.infra.db)
        .await?;

    // Create a default role and a non-default role
    let default_role = RoleBuilder::new("flag_default_role", &org)
        .default_role()
        .priority(10)
        .create(&fixtures.infra.db)
        .await?;

    let regular_role = RoleBuilder::new("flag_regular_role", &org)
        .priority(20)
        .create(&fixtures.infra.db)
        .await?;

    MemberBuilder::new(&user, &org)
        .with_role(&regular_role)
        .create(&fixtures.infra.db)
        .await?;

    let nats = TestNatsClient::new(fixtures.infra.nats_client());
    let subject = list_roles_subject(&user.id, &org.id);

    let response: v1::ListRolesResponse = nats.request(&subject, &v1::ListRolesRequest {}).await?;

    match response.result {
        Some(list_roles_response::Result::Roles(list)) => {
            assert_eq!(list.roles.len(), 2, "Expected 2 roles");

            // Find the default role
            let default = list
                .roles
                .iter()
                .find(|r| r.name == Some("flag_default_role".to_string()))
                .expect("Default role should be in list");

            assert!(
                default.default_role.unwrap_or_default(),
                "Role 'flag_default_role' should have default_role=true"
            );

            // Find the regular role
            let regular = list
                .roles
                .iter()
                .find(|r| r.name == Some("flag_regular_role".to_string()))
                .expect("Regular role should be in list");
            assert!(
                !regular.default_role.unwrap_or_default(),
                "Role 'flag_regular_role' should have default_role=false"
            );
        }
        Some(list_roles_response::Result::Error(e)) => {
            panic!("Expected roles list, got error: {:?}", e);
        }
        None => {
            panic!("Expected roles list, got no result");
        }
    }

    Ok(())
}

/// Test non-assignable role flag is correctly returned.
///
/// Verifies that a role marked as non-assignable has the assignable flag set to false.
#[tokio::test]
async fn test_list_roles_non_assignable_flag() -> Result<()> {
    let fixtures = get_fixtures().await;

    let user = UserBuilder::new("list_roles_assign_user")
        .email("list_roles_assign@example.com")
        .create(&fixtures.infra.db)
        .await?;

    let org = OrganizationBuilder::new("list_roles_assign_org")
        .create(&fixtures.infra.db)
        .await?;

    // Create an owner role that cannot be assigned
    let owner_role = RoleBuilder::new("assign_owner", &org)
        .not_assignable()
        .priority(100)
        .create(&fixtures.infra.db)
        .await?;

    // Create a regular assignable role
    let member_role = RoleBuilder::new("assign_member", &org)
        .priority(10)
        .create(&fixtures.infra.db)
        .await?;

    MemberBuilder::new(&user, &org)
        .with_role(&owner_role)
        .create(&fixtures.infra.db)
        .await?;

    let nats = TestNatsClient::new(fixtures.infra.nats_client());
    let subject = list_roles_subject(&user.id, &org.id);

    let response: v1::ListRolesResponse = nats.request(&subject, &v1::ListRolesRequest {}).await?;

    match response.result {
        Some(list_roles_response::Result::Roles(list)) => {
            assert_eq!(list.roles.len(), 2, "Expected 2 roles");

            // Find the owner role
            let owner = list
                .roles
                .iter()
                .find(|r| r.name == Some("assign_owner".to_string()))
                .expect("Owner role should be in list");
            assert!(
                !owner.assignable.unwrap_or_default(),
                "Role 'assign_owner' should have assignable=false"
            );

            // Find the member role
            let member = list
                .roles
                .iter()
                .find(|r| r.name == Some("assign_member".to_string()))
                .expect("Member role should be in list");
            assert!(
                member.assignable.unwrap_or_default(),
                "Role 'assign_member' should have assignable=true"
            );
        }
        Some(list_roles_response::Result::Error(e)) => {
            panic!("Expected roles list, got error: {:?}", e);
        }
        None => {
            panic!("Expected roles list, got no result");
        }
    }

    Ok(())
}

/// Test non-deletable role flag is correctly returned.
///
/// Verifies that a role marked as non-deletable has the deletable flag set to false.
#[tokio::test]
async fn test_list_roles_non_deletable_flag() -> Result<()> {
    let fixtures = get_fixtures().await;

    let user = UserBuilder::new("list_roles_delete_user")
        .email("list_roles_delete@example.com")
        .create(&fixtures.infra.db)
        .await?;

    let org = OrganizationBuilder::new("list_roles_delete_org")
        .create(&fixtures.infra.db)
        .await?;

    // Create a system role that cannot be deleted
    let system_role = RoleBuilder::new("delete_system", &org)
        .not_deletable()
        .priority(100)
        .create(&fixtures.infra.db)
        .await?;

    // Create a regular deletable role
    let custom_role = RoleBuilder::new("delete_custom", &org)
        .priority(10)
        .create(&fixtures.infra.db)
        .await?;

    MemberBuilder::new(&user, &org)
        .with_role(&system_role)
        .create(&fixtures.infra.db)
        .await?;

    let nats = TestNatsClient::new(fixtures.infra.nats_client());
    let subject = list_roles_subject(&user.id, &org.id);

    let response: v1::ListRolesResponse = nats.request(&subject, &v1::ListRolesRequest {}).await?;

    match response.result {
        Some(list_roles_response::Result::Roles(list)) => {
            assert_eq!(list.roles.len(), 2, "Expected 2 roles");

            // Find the system role
            let system = list
                .roles
                .iter()
                .find(|r| r.name == Some("delete_system".to_string()))
                .expect("System role should be in list");
            assert!(
                !system.deletable.unwrap_or_default(),
                "Role 'delete_system' should have deletable=false"
            );

            // Find the custom role
            let custom = list
                .roles
                .iter()
                .find(|r| r.name == Some("delete_custom".to_string()))
                .expect("Custom role should be in list");
            assert!(
                custom.deletable.unwrap_or_default(),
                "Role 'delete_custom' should have deletable=true"
            );
        }
        Some(list_roles_response::Result::Error(e)) => {
            panic!("Expected roles list, got error: {:?}", e);
        }
        None => {
            panic!("Expected roles list, got no result");
        }
    }

    Ok(())
}

/// Test role with all flags configured.
///
/// Verifies a role with non-default configuration for all flags.
#[tokio::test]
async fn test_list_roles_all_flags_configured() -> Result<()> {
    let fixtures = get_fixtures().await;

    let user = UserBuilder::new("list_roles_allflags_user")
        .email("list_roles_allflags@example.com")
        .create(&fixtures.infra.db)
        .await?;

    let org = OrganizationBuilder::new("list_roles_allflags_org")
        .create(&fixtures.infra.db)
        .await?;

    // Create a role with all special flags
    let special_role = RoleBuilder::new("allflags_special", &org)
        .default_role()
        .not_assignable()
        .not_deletable()
        .priority(999)
        .color(0xFFE91E63) // Pink
        .create(&fixtures.infra.db)
        .await?;

    MemberBuilder::new(&user, &org)
        .with_role(&special_role)
        .create(&fixtures.infra.db)
        .await?;

    let nats = TestNatsClient::new(fixtures.infra.nats_client());
    let subject = list_roles_subject(&user.id, &org.id);

    let response: v1::ListRolesResponse = nats.request(&subject, &v1::ListRolesRequest {}).await?;

    match response.result {
        Some(list_roles_response::Result::Roles(list)) => {
            assert_eq!(list.roles.len(), 1, "Expected 1 role");

            let role = &list.roles[0];

            assert_eq!(
                role.name,
                Some("allflags_special".to_string()),
                "Role name mismatch"
            );
            assert!(
                role.default_role.unwrap_or_default(),
                "Expected default_role=true"
            );
            assert!(
                !role.assignable.unwrap_or_default(),
                "Expected assignable=false"
            );
            assert!(
                !role.deletable.unwrap_or_default(),
                "Expected deletable=false"
            );

            // Verify color
            let color = role.color.as_ref().expect("Color should be present");
            assert_eq!(
                color.value,
                Some(0xFFE91E63),
                "Color mismatch: expected 0xFFE91E63, got {}",
                color
                    .value
                    .map(|v| format!("0x{:08X}", v))
                    .unwrap_or("Unkown Color".to_string())
            );
        }
        Some(list_roles_response::Result::Error(e)) => {
            panic!("Expected roles list, got error: {:?}", e);
        }
        None => {
            panic!("Expected roles list, got no result");
        }
    }

    Ok(())
}

/// Test color is returned correctly with various values.
///
/// Verifies that different color values are correctly serialized and returned.
#[tokio::test]
async fn test_list_roles_color_values() -> Result<()> {
    let fixtures = get_fixtures().await;

    let user = UserBuilder::new("list_roles_color_user")
        .email("list_roles_color@example.com")
        .create(&fixtures.infra.db)
        .await?;

    let org = OrganizationBuilder::new("list_roles_color_org")
        .create(&fixtures.infra.db)
        .await?;

    // Test different color values including edge cases
    let red_role = RoleBuilder::new("color_red", &org)
        .color(0xFFFF0000) // Pure red with full alpha
        .priority(30)
        .create(&fixtures.infra.db)
        .await?;

    let transparent_role = RoleBuilder::new("color_transparent", &org)
        .color(0x80FFFFFF) // Semi-transparent white
        .priority(20)
        .create(&fixtures.infra.db)
        .await?;

    let black_role = RoleBuilder::new("color_black", &org)
        .color(0xFF000000) // Pure black with full alpha
        .priority(10)
        .create(&fixtures.infra.db)
        .await?;

    MemberBuilder::new(&user, &org)
        .with_role(&red_role)
        .create(&fixtures.infra.db)
        .await?;

    let nats = TestNatsClient::new(fixtures.infra.nats_client());
    let subject = list_roles_subject(&user.id, &org.id);

    let response: v1::ListRolesResponse = nats.request(&subject, &v1::ListRolesRequest {}).await?;

    match response.result {
        Some(list_roles_response::Result::Roles(list)) => {
            assert_eq!(list.roles.len(), 3, "Expected 3 roles");

            // Verify red color
            let red = list
                .roles
                .iter()
                .find(|r| r.name == Some("color_red".to_string()))
                .expect("Red role should be in list");
            assert_eq!(
                red.color.as_ref().and_then(|c| c.value),
                Some(0xFFFF0000),
                "Red color mismatch"
            );

            // Verify transparent white
            let transparent = list
                .roles
                .iter()
                .find(|r| r.name == Some("color_transparent".to_string()))
                .expect("Transparent role should be in list");
            assert_eq!(
                transparent.color.as_ref().and_then(|c| c.value),
                Some(0x80FFFFFF),
                "Transparent color mismatch"
            );

            // Verify black color
            let black = list
                .roles
                .iter()
                .find(|r| r.name == Some("color_black".to_string()))
                .expect("Black role should be in list");
            assert_eq!(
                black.color.as_ref().and_then(|c| c.value),
                Some(0xFF000000u32),
                "Black color mismatch"
            );
        }
        Some(list_roles_response::Result::Error(e)) => {
            panic!("Expected roles list, got error: {:?}", e);
        }
        None => {
            panic!("Expected roles list, got no result");
        }
    }

    Ok(())
}

/// Test behavior when user is not a member of the organization.
///
/// This test documents the expected behavior when a non-member attempts
/// to list roles. Since listing roles is a read-only operation, it may
/// still succeed depending on the implementation.
#[tokio::test]
async fn test_list_roles_user_not_member() -> Result<()> {
    let fixtures = get_fixtures().await;

    // Create a user who is NOT a member of the organization
    let non_member_user = UserBuilder::new("list_roles_nonmember_user")
        .email("list_roles_nonmember@example.com")
        .create(&fixtures.infra.db)
        .await?;

    // Create organization and add a role (but don't add user as member)
    let org = OrganizationBuilder::new("list_roles_nonmember_org")
        .create(&fixtures.infra.db)
        .await?;

    let _role = RoleBuilder::new("nonmember_test_role", &org)
        .priority(10)
        .create(&fixtures.infra.db)
        .await?;

    let nats = TestNatsClient::new(fixtures.infra.nats_client());
    let subject = list_roles_subject(&non_member_user.id, &org.id);

    let response: v1::ListRolesResponse = nats.request(&subject, &v1::ListRolesRequest {}).await?;

    // Document the actual behavior - may return roles or an error
    match response.result {
        Some(list_roles_response::Result::Roles(list)) => {
            // If roles are returned, verify the role is present
            // This indicates the endpoint allows non-members to list roles
            assert_eq!(
                list.roles.len(),
                1,
                "Expected 1 role when non-member access is allowed"
            );
            assert_eq!(list.roles[0].name, Some("nonmember_test_role".to_string()));
        }
        Some(list_roles_response::Result::Error(e)) => {
            // If error is returned, this documents that membership is required
            // The error should indicate authorization/permission issue
            assert!(
                !e.message.is_empty(),
                "Error message should not be empty when access is denied"
            );
        }
        None => {
            panic!("Expected roles list or error, got no result");
        }
    }

    Ok(())
}

/// Test that roles from different organizations are isolated.
///
/// Verifies that listing roles for one organization does not include
/// roles from other organizations.
#[tokio::test]
async fn test_list_roles_organization_isolation() -> Result<()> {
    let fixtures = get_fixtures().await;

    let user = UserBuilder::new("list_roles_isolation_user")
        .email("list_roles_isolation@example.com")
        .create(&fixtures.infra.db)
        .await?;

    // Create first organization with roles
    let org1 = OrganizationBuilder::new("list_roles_iso_org1")
        .create(&fixtures.infra.db)
        .await?;

    let org1_role = RoleBuilder::new("iso_org1_role", &org1)
        .priority(10)
        .create(&fixtures.infra.db)
        .await?;

    // Create second organization with different roles
    let org2 = OrganizationBuilder::new("list_roles_iso_org2")
        .create(&fixtures.infra.db)
        .await?;

    let _org2_role = RoleBuilder::new("iso_org2_role", &org2)
        .priority(10)
        .create(&fixtures.infra.db)
        .await?;

    // Make user a member of org1 only
    MemberBuilder::new(&user, &org1)
        .with_role(&org1_role)
        .create(&fixtures.infra.db)
        .await?;

    let nats = TestNatsClient::new(fixtures.infra.nats_client());

    // List roles for org1
    let subject = list_roles_subject(&user.id, &org1.id);
    let response: v1::ListRolesResponse = nats.request(&subject, &v1::ListRolesRequest {}).await?;

    match response.result {
        Some(list_roles_response::Result::Roles(list)) => {
            // Should only contain org1's role
            assert_eq!(
                list.roles.len(),
                1,
                "Expected 1 role from org1, got {}",
                list.roles.len()
            );
            assert_eq!(
                list.roles[0].name,
                Some("iso_org1_role".to_string()),
                "Expected org1's role, got '{}'",
                list.roles[0].name.clone().unwrap_or("Unknown".to_string())
            );

            // Verify org2's role is NOT included
            assert!(
                !list
                    .roles
                    .iter()
                    .any(|r| r.name == Some("iso_org2_role".to_string())),
                "Org2's role should NOT be in org1's role list"
            );
        }
        Some(list_roles_response::Result::Error(e)) => {
            panic!("Expected roles list, got error: {:?}", e);
        }
        None => {
            panic!("Expected roles list, got no result");
        }
    }

    Ok(())
}

/// Test with default gray color (RoleBuilder default).
///
/// Verifies that the default color from RoleBuilder is correctly returned.
#[tokio::test]
async fn test_list_roles_default_color() -> Result<()> {
    let fixtures = get_fixtures().await;

    let user = UserBuilder::new("list_roles_defcolor_user")
        .email("list_roles_defcolor@example.com")
        .create(&fixtures.infra.db)
        .await?;

    let org = OrganizationBuilder::new("list_roles_defcolor_org")
        .create(&fixtures.infra.db)
        .await?;

    // Create role without specifying color (uses default 0xFF9E9E9E)
    let role = RoleBuilder::new("defcolor_role", &org)
        .priority(10)
        .create(&fixtures.infra.db)
        .await?;

    MemberBuilder::new(&user, &org)
        .with_role(&role)
        .create(&fixtures.infra.db)
        .await?;

    let nats = TestNatsClient::new(fixtures.infra.nats_client());
    let subject = list_roles_subject(&user.id, &org.id);

    let response: v1::ListRolesResponse = nats.request(&subject, &v1::ListRolesRequest {}).await?;

    match response.result {
        Some(list_roles_response::Result::Roles(list)) => {
            assert_eq!(list.roles.len(), 1, "Expected 1 role");

            let role = &list.roles[0];
            let color = role.color.as_ref().expect("Color should be present");

            // Default gray color from RoleBuilder
            assert_eq!(
                color.value,
                Some(0xFF9E9E9E),
                "Expected default gray color 0xFF9E9E9E, got {:?}",
                color
                    .value
                    .map(|v| format!("0x{:08X}", v))
                    .unwrap_or("None".to_string())
            );
        }
        Some(list_roles_response::Result::Error(e)) => {
            panic!("Expected roles list, got error: {:?}", e);
        }
        None => {
            panic!("Expected roles list, got no result");
        }
    }

    Ok(())
}
