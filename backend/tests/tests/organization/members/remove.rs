//! Tests for removing organization members.

use backend_tests::proto::typewriter::api::v1::{
    ListMembersRequest, ListMembersResponse, RemoveMemberRequest, RemoveMemberResponse,
    list_members_response, remove_member_response,
};
use backend_tests::{
    MemberBuilder, OrganizationBuilder, RoleBuilder, TestNatsClient, UserBuilder, get_fixtures,
};

/// Test successfully removing a member from an organization.
#[tokio::test]
async fn test_remove_member_success() {
    let fixtures = get_fixtures().await;
    let db = &fixtures.infra.db;
    let nats = fixtures.infra.nats_client();
    let client = TestNatsClient::new(nats);

    // Create test data
    let org = OrganizationBuilder::new("remove_member_success_org")
        .create(db)
        .await
        .expect("Failed to create organization");

    let role = RoleBuilder::new("remove_success_role", &org)
        .create(db)
        .await
        .expect("Failed to create role");

    let admin_user = UserBuilder::new("Remove Success Admin")
        .email("remove.success.admin@example.com")
        .create(db)
        .await
        .expect("Failed to create admin user");

    let target_user = UserBuilder::new("Remove Success Target")
        .email("remove.success.target@example.com")
        .create(db)
        .await
        .expect("Failed to create target user");

    // Create memberships
    MemberBuilder::new(&admin_user, &org)
        .with_role(&role)
        .create(db)
        .await
        .expect("Failed to create admin membership");

    MemberBuilder::new(&target_user, &org)
        .with_role(&role)
        .create(db)
        .await
        .expect("Failed to create target membership");

    let subject = format!(
        "typewriter.in.user.{}.organization.{}.members.remove",
        admin_user.id, org.id
    );
    let response: RemoveMemberResponse = client
        .request(
            &subject,
            &RemoveMemberRequest {
                user_id: target_user.id.clone(),
            },
        )
        .await
        .expect("Failed to send request");

    // Verify success response
    match response.result {
        Some(remove_member_response::Result::Success(success)) => {
            assert!(success, "Remove operation should return success=true");
        }
        Some(remove_member_response::Result::Error(err)) => {
            panic!("Unexpected error: {} - {}", err.code, err.message);
        }
        None => panic!("Expected result in response"),
    }
}

/// Test that removed member no longer appears in the member list.
#[tokio::test]
async fn test_removed_member_not_in_list() {
    let fixtures = get_fixtures().await;
    let db = &fixtures.infra.db;
    let nats = fixtures.infra.nats_client();
    let client = TestNatsClient::new(nats);

    // Create test data
    let org = OrganizationBuilder::new("remove_verify_list_org")
        .create(db)
        .await
        .expect("Failed to create organization");

    let role = RoleBuilder::new("remove_verify_role", &org)
        .create(db)
        .await
        .expect("Failed to create role");

    let admin_user = UserBuilder::new("Remove Verify Admin")
        .email("remove.verify.admin@example.com")
        .create(db)
        .await
        .expect("Failed to create admin user");

    let target_user = UserBuilder::new("Remove Verify Target")
        .email("remove.verify.target@example.com")
        .create(db)
        .await
        .expect("Failed to create target user");

    let remaining_user = UserBuilder::new("Remove Verify Remaining")
        .email("remove.verify.remaining@example.com")
        .create(db)
        .await
        .expect("Failed to create remaining user");

    // Create memberships for all three users
    MemberBuilder::new(&admin_user, &org)
        .with_role(&role)
        .create(db)
        .await
        .expect("Failed to create admin membership");

    MemberBuilder::new(&target_user, &org)
        .with_role(&role)
        .create(db)
        .await
        .expect("Failed to create target membership");

    MemberBuilder::new(&remaining_user, &org)
        .with_role(&role)
        .create(db)
        .await
        .expect("Failed to create remaining membership");

    // Verify member exists in list before removal
    let list_subject = format!(
        "typewriter.in.user.{}.organization.{}.members.list",
        admin_user.id, org.id
    );
    let list_response: ListMembersResponse = client
        .request(&list_subject, &ListMembersRequest {})
        .await
        .expect("Failed to list members");

    match &list_response.result {
        Some(list_members_response::Result::Members(list)) => {
            assert_eq!(
                list.members.len(),
                3,
                "Expected three members before removal"
            );
            assert!(
                list.members
                    .iter()
                    .any(|m| m.name == Some("Remove Verify Target".to_string())),
                "Target should be in member list before removal"
            );
        }
        _ => panic!("Expected members list"),
    }

    // Remove the target member
    let remove_subject = format!(
        "typewriter.in.user.{}.organization.{}.members.remove",
        admin_user.id, org.id
    );
    let remove_response: RemoveMemberResponse = client
        .request(
            &remove_subject,
            &RemoveMemberRequest {
                user_id: target_user.id.clone(),
            },
        )
        .await
        .expect("Failed to send remove request");

    // Verify removal was successful
    match remove_response.result {
        Some(remove_member_response::Result::Success(success)) => {
            assert!(success, "Remove should succeed");
        }
        Some(remove_member_response::Result::Error(err)) => {
            panic!("Remove failed: {} - {}", err.code, err.message);
        }
        None => panic!("Expected result in response"),
    }

    // Verify member no longer appears in list
    let final_list_response: ListMembersResponse = client
        .request(&list_subject, &ListMembersRequest {})
        .await
        .expect("Failed to list members after removal");

    match final_list_response.result {
        Some(list_members_response::Result::Members(list)) => {
            assert_eq!(list.members.len(), 2, "Expected two members after removal");

            // Verify target is not in the list
            assert!(
                !list
                    .members
                    .iter()
                    .any(|m| m.name == Some("Remove Verify Target".to_string())),
                "Removed member should not appear in list"
            );

            // Verify other members are still present
            assert!(
                list.members
                    .iter()
                    .any(|m| m.name == Some("Remove Verify Admin".to_string())),
                "Admin should still be in list"
            );
            assert!(
                list.members
                    .iter()
                    .any(|m| m.name == Some("Remove Verify Remaining".to_string())),
                "Remaining member should still be in list"
            );
        }
        Some(list_members_response::Result::Error(err)) => {
            panic!("List failed: {} - {}", err.code, err.message);
        }
        None => panic!("Expected result in response"),
    }
}

/// Test error when trying to remove a member that doesn't exist.
#[tokio::test]
async fn test_remove_member_not_found() {
    let fixtures = get_fixtures().await;
    let db = &fixtures.infra.db;
    let nats = fixtures.infra.nats_client();
    let client = TestNatsClient::new(nats);

    // Create test data
    let org = OrganizationBuilder::new("remove_not_found_org")
        .create(db)
        .await
        .expect("Failed to create organization");

    let role = RoleBuilder::new("remove_nf_role", &org)
        .create(db)
        .await
        .expect("Failed to create role");

    let user = UserBuilder::new("Remove Not Found User")
        .email("remove.notfound@example.com")
        .create(db)
        .await
        .expect("Failed to create user");

    MemberBuilder::new(&user, &org)
        .with_role(&role)
        .create(db)
        .await
        .expect("Failed to create membership");

    // Use a non-existent user ID
    let fake_user_id = "00000000-0000-0000-0000-000000000000";

    let subject = format!(
        "typewriter.in.user.{}.organization.{}.members.remove",
        user.id, org.id
    );
    let response: RemoveMemberResponse = client
        .request(
            &subject,
            &RemoveMemberRequest {
                user_id: fake_user_id.to_string(),
            },
        )
        .await
        .expect("Failed to send request");

    // Trying to remove a non-existent user should return an error
    match response.result {
        Some(remove_member_response::Result::Error(err)) => {
            assert_eq!(err.code, 404, "Should return 404 for non-existent user");
            assert!(
                err.message.contains("User not found"),
                "Error message should indicate user not found, got: {}",
                err.message
            );
        }
        Some(remove_member_response::Result::Success(_)) => {
            panic!("Expected error for non-existent user, got success");
        }
        None => panic!("Expected result in response"),
    }
}

/// Test malicious input: invalid user_id formats.
#[tokio::test]
async fn test_remove_member_invalid_user_id() {
    let fixtures = get_fixtures().await;
    let db = &fixtures.infra.db;
    let nats = fixtures.infra.nats_client();
    let client = TestNatsClient::new(nats);

    // Create test data
    let org = OrganizationBuilder::new("remove_invalid_id_org")
        .create(db)
        .await
        .expect("Failed to create organization");

    let role = RoleBuilder::new("remove_inv_id_role", &org)
        .create(db)
        .await
        .expect("Failed to create role");

    let user = UserBuilder::new("Remove Invalid ID User")
        .email("remove.invalidid@example.com")
        .create(db)
        .await
        .expect("Failed to create user");

    MemberBuilder::new(&user, &org)
        .with_role(&role)
        .create(db)
        .await
        .expect("Failed to create membership");

    // Test various invalid user_id formats
    let invalid_user_ids = vec![
        "not-a-valid-id",
        "12345",
        "'; DROP TABLE member_of; --",
        "<script>alert('xss')</script>",
        "../../../../etc/passwd",
        "",
        "member_of:fake",
        "../../../",
        "null",
        "undefined",
    ];

    for invalid_id in invalid_user_ids {
        let subject = format!(
            "typewriter.in.user.{}.organization.{}.members.remove",
            user.id, org.id
        );
        let response: RemoveMemberResponse = client
            .request(
                &subject,
                &RemoveMemberRequest {
                    user_id: invalid_id.to_string(),
                },
            )
            .await
            .expect("Failed to send request");

        // Should return an error or handle gracefully, not crash
        match response.result {
            Some(remove_member_response::Result::Error(_err)) => {
                // Expected - invalid user ID should result in error
            }
            Some(remove_member_response::Result::Success(success)) => {
                // If it returns success=false, that's also acceptable for "not found"
                assert!(
                    !success,
                    "Should not return success=true for invalid user_id '{}'",
                    invalid_id
                );
            }
            None => {
                // Also acceptable - no result could indicate handled error
            }
        }
    }
}

/// Test removing multiple members sequentially.
#[tokio::test]
async fn test_remove_multiple_members() {
    let fixtures = get_fixtures().await;
    let db = &fixtures.infra.db;
    let nats = fixtures.infra.nats_client();
    let client = TestNatsClient::new(nats);

    // Create test data
    let org = OrganizationBuilder::new("remove_multi_members_org")
        .create(db)
        .await
        .expect("Failed to create organization");

    let role = RoleBuilder::new("remove_multi_role", &org)
        .create(db)
        .await
        .expect("Failed to create role");

    let admin_user = UserBuilder::new("Remove Multi Admin")
        .email("remove.multi.admin@example.com")
        .create(db)
        .await
        .expect("Failed to create admin user");

    let user1 = UserBuilder::new("Remove Multi User1")
        .email("remove.multi.user1@example.com")
        .create(db)
        .await
        .expect("Failed to create user1");

    let user2 = UserBuilder::new("Remove Multi User2")
        .email("remove.multi.user2@example.com")
        .create(db)
        .await
        .expect("Failed to create user2");

    let user3 = UserBuilder::new("Remove Multi User3")
        .email("remove.multi.user3@example.com")
        .create(db)
        .await
        .expect("Failed to create user3");

    // Create memberships
    MemberBuilder::new(&admin_user, &org)
        .with_role(&role)
        .create(db)
        .await
        .expect("Failed to create admin membership");

    MemberBuilder::new(&user1, &org)
        .with_role(&role)
        .create(db)
        .await
        .expect("Failed to create user1 membership");

    MemberBuilder::new(&user2, &org)
        .with_role(&role)
        .create(db)
        .await
        .expect("Failed to create user2 membership");

    MemberBuilder::new(&user3, &org)
        .with_role(&role)
        .create(db)
        .await
        .expect("Failed to create user3 membership");

    let remove_subject = format!(
        "typewriter.in.user.{}.organization.{}.members.remove",
        admin_user.id, org.id
    );
    let list_subject = format!(
        "typewriter.in.user.{}.organization.{}.members.list",
        admin_user.id, org.id
    );

    // Remove first member
    let response1: RemoveMemberResponse = client
        .request(
            &remove_subject,
            &RemoveMemberRequest {
                user_id: user1.id.clone(),
            },
        )
        .await
        .expect("Failed to remove first member");

    match response1.result {
        Some(remove_member_response::Result::Success(s)) => assert!(s),
        _ => panic!("First removal should succeed"),
    }

    // Verify count after first removal
    let list1: ListMembersResponse = client
        .request(&list_subject, &ListMembersRequest {})
        .await
        .expect("Failed to list after first removal");

    match list1.result {
        Some(list_members_response::Result::Members(list)) => {
            assert_eq!(
                list.members.len(),
                3,
                "Expected 3 members after first removal"
            );
        }
        _ => panic!("Expected members list"),
    }

    // Remove second member
    let response2: RemoveMemberResponse = client
        .request(
            &remove_subject,
            &RemoveMemberRequest {
                user_id: user2.id.clone(),
            },
        )
        .await
        .expect("Failed to remove second member");

    match response2.result {
        Some(remove_member_response::Result::Success(s)) => assert!(s),
        _ => panic!("Second removal should succeed"),
    }

    // Verify count after second removal
    let list2: ListMembersResponse = client
        .request(&list_subject, &ListMembersRequest {})
        .await
        .expect("Failed to list after second removal");

    match list2.result {
        Some(list_members_response::Result::Members(list)) => {
            assert_eq!(
                list.members.len(),
                2,
                "Expected 2 members after second removal"
            );

            // Verify remaining members
            let names: Vec<String> = list.members.iter().filter_map(|m| m.name.clone()).collect();
            assert!(names.contains(&"Remove Multi Admin".to_string()));
            assert!(names.contains(&"Remove Multi User3".to_string()));
            assert!(!names.contains(&"Remove Multi User1".to_string()));
            assert!(!names.contains(&"Remove Multi User2".to_string()));
        }
        _ => panic!("Expected members list"),
    }
}
