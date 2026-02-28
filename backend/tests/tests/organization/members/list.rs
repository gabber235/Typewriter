//! Tests for listing organization members.
//!
//! Subject: `typewriter.in.user.<user_id>.organization.<org_id>.members.list`
//! Request: `ListMembersRequest` (empty)
//! Response: `ListMembersResponse` with `members: Vec<OrganizationMember>` or error

use anyhow::Result;

use backend_tests::proto::typewriter::api::v1::{self, list_members_response};
use backend_tests::{
    MemberBuilder, OrganizationBuilder, RoleBuilder, TestNatsClient, UserBuilder, get_fixtures,
};

/// Helper to create the NATS subject for listing members.
fn list_members_subject(user_id: &str, org_id: &str) -> String {
    format!(
        "typewriter.in.user.{}.organization.{}.members.list",
        user_id, org_id
    )
}

/// Test listing members in an organization with a single member.
#[tokio::test]
async fn test_list_members_single_member() -> Result<()> {
    let fixtures = get_fixtures().await;

    // Create test data with unique names
    let org = OrganizationBuilder::new("list_members_single_org")
        .create(&fixtures.infra.db)
        .await?;

    let user = UserBuilder::new("Single Member User")
        .email("single.member@example.com")
        .avatar_url("https://example.com/single-avatar.png")
        .create(&fixtures.infra.db)
        .await?;

    let role = RoleBuilder::new("list_single_role", &org)
        .default_role()
        .create(&fixtures.infra.db)
        .await?;

    MemberBuilder::new(&user, &org)
        .with_role(&role)
        .create(&fixtures.infra.db)
        .await?;

    let nats = TestNatsClient::new(fixtures.infra.nats_client());
    let subject = list_members_subject(&user.id, &org.id);

    let response: v1::ListMembersResponse =
        nats.request(&subject, &v1::ListMembersRequest {}).await?;

    match response.result {
        Some(list_members_response::Result::Members(list)) => {
            assert_eq!(list.members.len(), 1, "Expected exactly one member");

            let member = &list.members[0];
            assert_eq!(member.name, Some("Single Member User".to_string()));
            assert_eq!(member.email, Some("single.member@example.com".to_string()));
            assert_eq!(
                member.avatar_url,
                Some("https://example.com/single-avatar.png".to_string())
            );
            assert_eq!(member.roles.len(), 1, "Expected exactly one role");
            assert_eq!(member.roles[0].name, Some("list_single_role".to_string()));
            assert!(member.joined_at.is_some(), "Expected joined_at to be set");
        }
        Some(list_members_response::Result::Error(err)) => {
            panic!("Unexpected error: {} - {}", err.code, err.message);
        }
        None => panic!("Expected result in response"),
    }

    Ok(())
}

/// Test listing members in an organization with multiple members.
#[tokio::test]
async fn test_list_members_multiple_members() -> Result<()> {
    let fixtures = get_fixtures().await;

    // Create test data
    let org = OrganizationBuilder::new("list_members_multi_org")
        .create(&fixtures.infra.db)
        .await?;

    let admin_role = RoleBuilder::new("list_multi_admin_role", &org)
        .priority(100)
        .create(&fixtures.infra.db)
        .await?;

    let member_role = RoleBuilder::new("list_multi_member_role", &org)
        .default_role()
        .create(&fixtures.infra.db)
        .await?;

    // Create first user (admin)
    let user1 = UserBuilder::new("Multi Admin User")
        .email("multi.admin@example.com")
        .create(&fixtures.infra.db)
        .await?;

    MemberBuilder::new(&user1, &org)
        .with_role(&admin_role)
        .create(&fixtures.infra.db)
        .await?;

    // Create second user (regular member)
    let user2 = UserBuilder::new("Multi Member User")
        .email("multi.member@example.com")
        .create(&fixtures.infra.db)
        .await?;

    MemberBuilder::new(&user2, &org)
        .with_role(&member_role)
        .create(&fixtures.infra.db)
        .await?;

    // Create third user (member with multiple roles)
    let user3 = UserBuilder::new("Multi Roles User")
        .email("multi.roles@example.com")
        .create(&fixtures.infra.db)
        .await?;

    MemberBuilder::new(&user3, &org)
        .with_roles(&[&admin_role, &member_role])
        .create(&fixtures.infra.db)
        .await?;

    let nats = TestNatsClient::new(fixtures.infra.nats_client());
    let subject = list_members_subject(&user1.id, &org.id);

    let response: v1::ListMembersResponse =
        nats.request(&subject, &v1::ListMembersRequest {}).await?;

    match response.result {
        Some(list_members_response::Result::Members(list)) => {
            assert_eq!(list.members.len(), 3, "Expected three members");

            let names: Vec<String> = list.members.iter().filter_map(|m| m.name.clone()).collect();

            assert!(
                names.contains(&"Multi Admin User".to_string()),
                "Expected Multi Admin User"
            );
            assert!(
                names.contains(&"Multi Member User".to_string()),
                "Expected Multi Member User"
            );
            assert!(
                names.contains(&"Multi Roles User".to_string()),
                "Expected Multi Roles User"
            );

            // Find the user with multiple roles and verify
            let multi_role_member = list
                .members
                .iter()
                .find(|m| m.name == Some("Multi Roles User".to_string()))
                .expect("Should find multi-role user");
            assert_eq!(
                multi_role_member.roles.len(),
                2,
                "Expected two roles for multi-role user"
            );
        }
        Some(list_members_response::Result::Error(err)) => {
            panic!("Unexpected error: {} - {}", err.code, err.message);
        }
        None => panic!("Expected result in response"),
    }

    Ok(())
}

/// Test that member data includes all expected fields.
#[tokio::test]
async fn test_list_members_verify_member_data() -> Result<()> {
    let fixtures = get_fixtures().await;

    // Create test data with all fields populated
    let org = OrganizationBuilder::new("list_members_data_org")
        .create(&fixtures.infra.db)
        .await?;

    let user = UserBuilder::new("Data Verification User")
        .email("data.verify@example.com")
        .avatar_url("https://example.com/data-avatar.png")
        .create(&fixtures.infra.db)
        .await?;

    let role = RoleBuilder::new("list_data_role", &org)
        .color(0xFF4287F5) // Blue color
        .default_role()
        .create(&fixtures.infra.db)
        .await?;

    MemberBuilder::new(&user, &org)
        .with_role(&role)
        .create(&fixtures.infra.db)
        .await?;

    let nats = TestNatsClient::new(fixtures.infra.nats_client());
    let subject = list_members_subject(&user.id, &org.id);

    let response: v1::ListMembersResponse =
        nats.request(&subject, &v1::ListMembersRequest {}).await?;

    match response.result {
        Some(list_members_response::Result::Members(list)) => {
            assert_eq!(list.members.len(), 1, "Expected one member");

            let member = &list.members[0];

            assert!(!member.user_id.is_empty(), "Member ID should be set");

            assert_eq!(member.name, Some("Data Verification User".to_string()));
            assert_eq!(member.email, Some("data.verify@example.com".to_string()));
            assert_eq!(
                member.avatar_url,
                Some("https://example.com/data-avatar.png".to_string())
            );

            assert_eq!(member.roles.len(), 1);
            let role = &member.roles[0];
            assert_eq!(role.name, Some("list_data_role".to_string()));
            assert!(
                role.default_role.is_some_and(|b| b),
                "Role should be marked as default"
            );
            assert!(
                role.assignable.is_some_and(|b| b),
                "Role should be assignable by default"
            );
            assert!(
                role.deletable.is_some_and(|b| b),
                "Role should be deletable by default"
            );

            // Verify role color
            assert!(role.color.is_some(), "Role color should be set");
            let color = role.color.as_ref().unwrap();
            assert_eq!(color.value, Some(0xFF4287F5), "Role color should match");

            // Verify joined_at timestamp
            assert!(member.joined_at.is_some(), "joined_at should be set");
            let joined_at = member.joined_at.as_ref().unwrap();
            assert!(
                joined_at.seconds > 0,
                "joined_at seconds should be positive"
            );
        }
        Some(list_members_response::Result::Error(err)) => {
            panic!("Unexpected error: {} - {}", err.code, err.message);
        }
        None => panic!("Expected result in response"),
    }

    Ok(())
}

/// Test listing members when the user has no email/avatar set (optional fields).
#[tokio::test]
async fn test_list_members_optional_fields() -> Result<()> {
    let fixtures = get_fixtures().await;

    // Create test data with minimal user
    let org = OrganizationBuilder::new("list_members_optional_org")
        .create(&fixtures.infra.db)
        .await?;

    // Create user with only name (no email or avatar)
    let user = UserBuilder::new("Optional Fields User")
        .create(&fixtures.infra.db)
        .await?;

    let role = RoleBuilder::new("list_optional_role", &org)
        .create(&fixtures.infra.db)
        .await?;

    MemberBuilder::new(&user, &org)
        .with_role(&role)
        .create(&fixtures.infra.db)
        .await?;

    let nats = TestNatsClient::new(fixtures.infra.nats_client());
    let subject = list_members_subject(&user.id, &org.id);

    let response: v1::ListMembersResponse =
        nats.request(&subject, &v1::ListMembersRequest {}).await?;

    // Verify response handles optional fields gracefully
    match response.result {
        Some(list_members_response::Result::Members(list)) => {
            assert_eq!(list.members.len(), 1, "Expected one member");

            let member = &list.members[0];
            assert_eq!(member.name, Some("Optional Fields User".to_string()));
            assert!(
                member.email.clone().is_none_or(|s| s.is_empty()),
                "Email should be empty when not set"
            );
            assert!(
                member.avatar_url.clone().is_none_or(|s| s.is_empty()),
                "Avatar URL should be empty when not set"
            );
        }
        Some(list_members_response::Result::Error(err)) => {
            panic!("Unexpected error: {} - {}", err.code, err.message);
        }
        None => panic!("Expected result in response"),
    }

    Ok(())
}
