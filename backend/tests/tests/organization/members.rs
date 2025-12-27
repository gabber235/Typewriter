//! Integration tests for organization members functionality.

use anyhow::Result;

use backend_tests::{
    get_fixtures, MemberBuilder, OrganizationBuilder, RoleBuilder, TestNatsClient, UserBuilder,
};
use backend_tests::proto::api_v1;

/// Test listing organization members.
///
/// This test verifies that:
/// 1. A user can be added as a member of an organization
/// 2. The list members endpoint returns the member correctly
/// 3. Member roles are included in the response
#[tokio::test]
async fn test_list_organization_members() -> Result<()> {
    // Get shared fixtures (components already built and deployed)
    let fixtures = get_fixtures().await;

    // Create test user
    let user = UserBuilder::new("testuser")
        .email("testuser@example.com")
        .create(&fixtures.infra.db)
        .await?;

    // Create test organization
    let org = OrganizationBuilder::new("testorg")
        .icon_url("https://example.com/icon.png")
        .create(&fixtures.infra.db)
        .await?;

    // Create a role for the organization
    let role = RoleBuilder::new("admin", &org)
        .create(&fixtures.infra.db)
        .await?;

    // Add user as member of the organization
    MemberBuilder::new(&user, &org)
        .with_role(&role)
        .create(&fixtures.infra.db)
        .await?;

    // Send list members request via NATS
    let nats = TestNatsClient::new(fixtures.host.nats_client());

    // Subject pattern: typewriter.in.user.<user_id>.organization.<org_id>.members.list
    let subject = format!(
        "typewriter.in.user.{}.organization.{}.members.list",
        user.id, org.id
    );

    let response: api_v1::ListMembersResponse = nats
        .request(&subject, &api_v1::ListMembersRequest {})
        .await?;

    // Verify response
    match response.result {
        Some(api_v1::list_members_response::Result::Members(list)) => {
            assert_eq!(list.members.len(), 1, "Expected 1 member");
            let member = &list.members[0];

            // OrganizationMember has user info flattened (name, email, etc.)
            assert_eq!(member.name, "testuser", "Member name should match");

            // Verify roles
            assert!(!member.roles.is_empty(), "Member should have at least one role");
            assert!(
                member.roles.iter().any(|r| r.name == "admin"),
                "Member should have admin role"
            );
        }
        Some(api_v1::list_members_response::Result::Error(e)) => {
            panic!("Expected members list, got error: {:?}", e);
        }
        None => {
            panic!("Expected members list, got no result");
        }
    }

    Ok(())
}

/// Test updating member roles.
#[tokio::test]
async fn test_update_member_roles() -> Result<()> {
    // Get shared fixtures
    let fixtures = get_fixtures().await;

    // Create test data
    let user = UserBuilder::new("roleuser")
        .email("roleuser@example.com")
        .create(&fixtures.infra.db)
        .await?;

    let org = OrganizationBuilder::new("roleorg")
        .create(&fixtures.infra.db)
        .await?;

    let admin_role = RoleBuilder::new("admin", &org)
        .not_assignable() // Admin role cannot be assigned by others
        .create(&fixtures.infra.db)
        .await?;

    let editor_role = RoleBuilder::new("editor", &org)
        .create(&fixtures.infra.db) // Default is assignable=true
        .await?;

    // Add user with admin role
    MemberBuilder::new(&user, &org)
        .with_role(&admin_role)
        .create(&fixtures.infra.db)
        .await?;

    // Update to add editor role
    let nats = TestNatsClient::new(fixtures.host.nats_client());
    let subject = format!(
        "typewriter.in.user.{}.organization.{}.members.update",
        user.id, org.id
    );

    let request = api_v1::UpdateMemberRolesRequest {
        member_id: user.id.clone(),
        role_ids: vec![editor_role.id.clone()],
    };

    let response: api_v1::UpdateMemberRolesResponse = nats.request(&subject, &request).await?;

    // Verify response
    match response.result {
        Some(api_v1::update_member_roles_response::Result::Member(member)) => {
            // Should have both admin (non-assignable, kept) and editor (assignable, added)
            assert!(
                member.roles.iter().any(|r| r.name == "editor"),
                "Member should have editor role after update"
            );
        }
        Some(api_v1::update_member_roles_response::Result::Error(e)) => {
            panic!("Expected updated member, got error: {:?}", e);
        }
        None => {
            panic!("Expected updated member, got no result");
        }
    }

    Ok(())
}

/// Test removing a member from an organization.
#[tokio::test]
async fn test_remove_member() -> Result<()> {
    // Get shared fixtures
    let fixtures = get_fixtures().await;

    // Create test data
    let owner = UserBuilder::new("orgowner")
        .email("owner@example.com")
        .create(&fixtures.infra.db)
        .await?;

    let member_user = UserBuilder::new("membertoremove")
        .email("member@example.com")
        .create(&fixtures.infra.db)
        .await?;

    let org = OrganizationBuilder::new("removeorg")
        .create(&fixtures.infra.db)
        .await?;

    let owner_role = RoleBuilder::new("owner", &org)
        .create(&fixtures.infra.db)
        .await?;

    let member_role = RoleBuilder::new("member", &org)
        .create(&fixtures.infra.db) // Default is assignable=true
        .await?;

    // Add owner
    MemberBuilder::new(&owner, &org)
        .with_role(&owner_role)
        .create(&fixtures.infra.db)
        .await?;

    // Add member to be removed
    MemberBuilder::new(&member_user, &org)
        .with_role(&member_role)
        .create(&fixtures.infra.db)
        .await?;

    // Remove the member
    let nats = TestNatsClient::new(fixtures.host.nats_client());
    let subject = format!(
        "typewriter.in.user.{}.organization.{}.members.remove",
        owner.id, org.id
    );

    let request = api_v1::RemoveMemberRequest {
        member_id: member_user.id.clone(),
    };

    let response: api_v1::RemoveMemberResponse = nats.request(&subject, &request).await?;

    // Verify removal succeeded
    match response.result {
        Some(api_v1::remove_member_response::Result::Success(success)) => {
            assert!(success, "Remove should return success=true");
        }
        Some(api_v1::remove_member_response::Result::Error(e)) => {
            panic!("Expected success, got error: {:?}", e);
        }
        None => {
            panic!("Expected success, got no result");
        }
    }

    // Verify member is no longer listed
    let list_subject = format!(
        "typewriter.in.user.{}.organization.{}.members.list",
        owner.id, org.id
    );
    let list_response: api_v1::ListMembersResponse = nats
        .request(&list_subject, &api_v1::ListMembersRequest {})
        .await?;

    match list_response.result {
        Some(api_v1::list_members_response::Result::Members(list)) => {
            assert_eq!(
                list.members.len(),
                1,
                "Should only have owner left after removal"
            );
            let remaining = &list.members[0];
            assert_eq!(
                remaining.name, "orgowner",
                "Remaining member should be the owner"
            );
        }
        _ => panic!("Expected members list"),
    }

    Ok(())
}
