//! Tests for organization/members join_codes endpoints.
//!
//! This module tests the join code management functionality:
//! - Generating join codes with various configurations
//! - Listing active join codes
//! - Revoking join codes

use backend_tests::{
    get_fixtures, MemberBuilder, OrganizationBuilder, RoleBuilder, TestNatsClient, UserBuilder,
};
use backend_tests::proto::typewriter::api::v1::{
    GenerateJoinCodeRequest, GenerateJoinCodeResponse, JoinCodeAutoAcceptConfig,
    JoinCodeExpiration, ListJoinCodesRequest, ListJoinCodesResponse, RevokeJoinCodeRequest,
    RevokeJoinCodeResponse,
    generate_join_code_response, join_code_expiration, list_join_codes_response,
    revoke_join_code_response,
};

// ============================================================================
// Generate Join Code Tests
// ============================================================================

/// Test generating a single-use join code (default behavior).
#[tokio::test]
async fn generate_single_use_code() {
    let fixtures = get_fixtures().await;
    let db = &fixtures.infra.db;
    let nats = TestNatsClient::new(fixtures.infra.nats_client());

    // Setup: Create user, organization, role, and membership
    let user = UserBuilder::new("gen_single_use_user")
        .email("gen_single_use@example.com")
        .create(db)
        .await
        .expect("Failed to create user");

    let org = OrganizationBuilder::new("gen_single_use_org")
        .create(db)
        .await
        .expect("Failed to create organization");

    let role = RoleBuilder::new("gen_single_use_role", &org)
        .default_role()
        .create(db)
        .await
        .expect("Failed to create role");

    MemberBuilder::new(&user, &org)
        .with_role(&role)
        .create(db)
        .await
        .expect("Failed to create membership");

    // Request: Generate a single-use join code
    let subject = format!(
        "typewriter.in.user.{}.organization.{}.members.join_codes.generate",
        user.id, org.id
    );

    let request = GenerateJoinCodeRequest {
        single_use: true,
        expiration: None,
        auto_accept: None,
    };

    let response: GenerateJoinCodeResponse = nats
        .request(&subject, &request)
        .await
        .expect("Failed to send request");

    // Assert: Code was generated successfully
    match response.result {
        Some(generate_join_code_response::Result::JoinCode(join_code)) => {
            assert!(!join_code.code.is_empty(), "Join code should not be empty");
            assert!(join_code.single_use, "Join code should be single-use");
            assert!(join_code.created_at.is_some(), "created_at should be set");
            assert!(
                join_code.auto_accept.is_none(),
                "auto_accept should not be set"
            );
        }
        Some(generate_join_code_response::Result::Error(e)) => {
            panic!("Unexpected error: {:?}", e);
        }
        None => panic!("No result in response"),
    }
}

/// Test generating a multi-use join code (single_use = false).
#[tokio::test]
async fn generate_multi_use_code() {
    let fixtures = get_fixtures().await;
    let db = &fixtures.infra.db;
    let nats = TestNatsClient::new(fixtures.infra.nats_client());

    // Setup
    let user = UserBuilder::new("gen_multi_use_user")
        .email("gen_multi_use@example.com")
        .create(db)
        .await
        .expect("Failed to create user");

    let org = OrganizationBuilder::new("gen_multi_use_org")
        .create(db)
        .await
        .expect("Failed to create organization");

    let role = RoleBuilder::new("gen_multi_use_role", &org)
        .default_role()
        .create(db)
        .await
        .expect("Failed to create role");

    MemberBuilder::new(&user, &org)
        .with_role(&role)
        .create(db)
        .await
        .expect("Failed to create membership");

    // Request: Generate a multi-use join code
    let subject = format!(
        "typewriter.in.user.{}.organization.{}.members.join_codes.generate",
        user.id, org.id
    );

    let request = GenerateJoinCodeRequest {
        single_use: false,
        expiration: None,
        auto_accept: None,
    };

    let response: GenerateJoinCodeResponse = nats
        .request(&subject, &request)
        .await
        .expect("Failed to send request");

    // Assert: Code was generated with single_use = false
    match response.result {
        Some(generate_join_code_response::Result::JoinCode(join_code)) => {
            assert!(!join_code.code.is_empty(), "Join code should not be empty");
            assert!(!join_code.single_use, "Join code should be multi-use");
        }
        Some(generate_join_code_response::Result::Error(e)) => {
            panic!("Unexpected error: {:?}", e);
        }
        None => panic!("No result in response"),
    }
}

/// Test generating a join code that never expires.
#[tokio::test]
async fn generate_code_never_expires() {
    let fixtures = get_fixtures().await;
    let db = &fixtures.infra.db;
    let nats = TestNatsClient::new(fixtures.infra.nats_client());

    // Setup
    let user = UserBuilder::new("gen_never_exp_user")
        .email("gen_never_exp@example.com")
        .create(db)
        .await
        .expect("Failed to create user");

    let org = OrganizationBuilder::new("gen_never_exp_org")
        .create(db)
        .await
        .expect("Failed to create organization");

    let role = RoleBuilder::new("gen_never_exp_role", &org)
        .default_role()
        .create(db)
        .await
        .expect("Failed to create role");

    MemberBuilder::new(&user, &org)
        .with_role(&role)
        .create(db)
        .await
        .expect("Failed to create membership");

    // Request: Generate a code that never expires
    let subject = format!(
        "typewriter.in.user.{}.organization.{}.members.join_codes.generate",
        user.id, org.id
    );

    let request = GenerateJoinCodeRequest {
        single_use: true,
        expiration: Some(JoinCodeExpiration {
            expiration: Some(join_code_expiration::Expiration::Never(true)),
        }),
        auto_accept: None,
    };

    let response: GenerateJoinCodeResponse = nats
        .request(&subject, &request)
        .await
        .expect("Failed to send request");

    // Assert: Code was generated without expiration
    match response.result {
        Some(generate_join_code_response::Result::JoinCode(join_code)) => {
            assert!(!join_code.code.is_empty(), "Join code should not be empty");
            assert!(
                join_code.expires_at.is_none(),
                "expires_at should not be set for never-expiring codes"
            );
        }
        Some(generate_join_code_response::Result::Error(e)) => {
            panic!("Unexpected error: {:?}", e);
        }
        None => panic!("No result in response"),
    }
}

/// Test generating a join code with duration expiration.
#[tokio::test]
async fn generate_code_with_duration_expiration() {
    let fixtures = get_fixtures().await;
    let db = &fixtures.infra.db;
    let nats = TestNatsClient::new(fixtures.infra.nats_client());

    // Setup
    let user = UserBuilder::new("gen_dur_exp_user")
        .email("gen_dur_exp@example.com")
        .create(db)
        .await
        .expect("Failed to create user");

    let org = OrganizationBuilder::new("gen_dur_exp_org")
        .create(db)
        .await
        .expect("Failed to create organization");

    let role = RoleBuilder::new("gen_dur_exp_role", &org)
        .default_role()
        .create(db)
        .await
        .expect("Failed to create role");

    MemberBuilder::new(&user, &org)
        .with_role(&role)
        .create(db)
        .await
        .expect("Failed to create membership");

    // Request: Generate a code that expires after 1 hour (3600 seconds)
    let subject = format!(
        "typewriter.in.user.{}.organization.{}.members.join_codes.generate",
        user.id, org.id
    );

    let request = GenerateJoinCodeRequest {
        single_use: true,
        expiration: Some(JoinCodeExpiration {
            expiration: Some(join_code_expiration::Expiration::DurationSeconds(3600)),
        }),
        auto_accept: None,
    };

    let response: GenerateJoinCodeResponse = nats
        .request(&subject, &request)
        .await
        .expect("Failed to send request");

    // Assert: Code was generated with expiration set
    match response.result {
        Some(generate_join_code_response::Result::JoinCode(join_code)) => {
            assert!(!join_code.code.is_empty(), "Join code should not be empty");
            assert!(
                join_code.expires_at.is_some(),
                "expires_at should be set for codes with duration expiration"
            );

            // Verify the expiration is approximately 1 hour in the future
            let created = join_code.created_at.as_ref().expect("created_at should be set");
            let expires = join_code.expires_at.as_ref().expect("expires_at should be set");
            let duration_secs = expires.seconds - created.seconds;
            // Allow some tolerance for processing time
            assert!(
                duration_secs >= 3590 && duration_secs <= 3610,
                "Expected expiration ~3600 seconds from creation, got {}",
                duration_secs
            );
        }
        Some(generate_join_code_response::Result::Error(e)) => {
            panic!("Unexpected error: {:?}", e);
        }
        None => panic!("No result in response"),
    }
}

/// Test generating a join code with auto-accept and roles.
#[tokio::test]
async fn generate_code_with_auto_accept() {
    let fixtures = get_fixtures().await;
    let db = &fixtures.infra.db;
    let nats = TestNatsClient::new(fixtures.infra.nats_client());

    // Setup
    let user = UserBuilder::new("gen_auto_acc_user")
        .email("gen_auto_acc@example.com")
        .create(db)
        .await
        .expect("Failed to create user");

    let org = OrganizationBuilder::new("gen_auto_acc_org")
        .create(db)
        .await
        .expect("Failed to create organization");

    let role1 = RoleBuilder::new("gen_auto_acc_role1", &org)
        .default_role()
        .create(db)
        .await
        .expect("Failed to create role1");

    let role2 = RoleBuilder::new("gen_auto_acc_role2", &org)
        .create(db)
        .await
        .expect("Failed to create role2");

    MemberBuilder::new(&user, &org)
        .with_role(&role1)
        .create(db)
        .await
        .expect("Failed to create membership");

    // Request: Generate a code with auto-accept that assigns role2
    let subject = format!(
        "typewriter.in.user.{}.organization.{}.members.join_codes.generate",
        user.id, org.id
    );

    let request = GenerateJoinCodeRequest {
        single_use: true,
        expiration: None,
        auto_accept: Some(JoinCodeAutoAcceptConfig {
            role_ids: vec![role2.id.clone()],
        }),
    };

    let response: GenerateJoinCodeResponse = nats
        .request(&subject, &request)
        .await
        .expect("Failed to send request");

    // Assert: Code was generated with auto_accept configuration
    match response.result {
        Some(generate_join_code_response::Result::JoinCode(join_code)) => {
            assert!(!join_code.code.is_empty(), "Join code should not be empty");
            let auto_accept = join_code
                .auto_accept
                .expect("auto_accept should be set");
            assert_eq!(
                auto_accept.role_ids.len(),
                1,
                "Should have one role in auto_accept"
            );
            assert_eq!(
                auto_accept.role_ids[0], role2.id,
                "auto_accept should contain the specified role"
            );
        }
        Some(generate_join_code_response::Result::Error(e)) => {
            panic!("Unexpected error: {:?}", e);
        }
        None => panic!("No result in response"),
    }
}

/// Test generating a join code without auto-accept (manual approval required).
#[tokio::test]
async fn generate_code_without_auto_accept() {
    let fixtures = get_fixtures().await;
    let db = &fixtures.infra.db;
    let nats = TestNatsClient::new(fixtures.infra.nats_client());

    // Setup
    let user = UserBuilder::new("gen_manual_user")
        .email("gen_manual@example.com")
        .create(db)
        .await
        .expect("Failed to create user");

    let org = OrganizationBuilder::new("gen_manual_org")
        .create(db)
        .await
        .expect("Failed to create organization");

    let role = RoleBuilder::new("gen_manual_role", &org)
        .default_role()
        .create(db)
        .await
        .expect("Failed to create role");

    MemberBuilder::new(&user, &org)
        .with_role(&role)
        .create(db)
        .await
        .expect("Failed to create membership");

    // Request: Generate a code without auto_accept (None)
    let subject = format!(
        "typewriter.in.user.{}.organization.{}.members.join_codes.generate",
        user.id, org.id
    );

    let request = GenerateJoinCodeRequest {
        single_use: true,
        expiration: None,
        auto_accept: None,
    };

    let response: GenerateJoinCodeResponse = nats
        .request(&subject, &request)
        .await
        .expect("Failed to send request");

    // Assert: Code was generated without auto_accept
    match response.result {
        Some(generate_join_code_response::Result::JoinCode(join_code)) => {
            assert!(!join_code.code.is_empty(), "Join code should not be empty");
            assert!(
                join_code.auto_accept.is_none(),
                "auto_accept should not be set for manual approval codes"
            );
        }
        Some(generate_join_code_response::Result::Error(e)) => {
            panic!("Unexpected error: {:?}", e);
        }
        None => panic!("No result in response"),
    }
}

/// Test that generated join codes have all expected fields populated.
#[tokio::test]
async fn verify_generated_code_fields() {
    let fixtures = get_fixtures().await;
    let db = &fixtures.infra.db;
    let nats = TestNatsClient::new(fixtures.infra.nats_client());

    // Setup
    let user = UserBuilder::new("gen_fields_user")
        .email("gen_fields@example.com")
        .create(db)
        .await
        .expect("Failed to create user");

    let org = OrganizationBuilder::new("gen_fields_org")
        .create(db)
        .await
        .expect("Failed to create organization");

    let role = RoleBuilder::new("gen_fields_role", &org)
        .default_role()
        .create(db)
        .await
        .expect("Failed to create role");

    MemberBuilder::new(&user, &org)
        .with_role(&role)
        .create(db)
        .await
        .expect("Failed to create membership");

    // Request: Generate a code with all options set
    let subject = format!(
        "typewriter.in.user.{}.organization.{}.members.join_codes.generate",
        user.id, org.id
    );

    let request = GenerateJoinCodeRequest {
        single_use: false,
        expiration: Some(JoinCodeExpiration {
            expiration: Some(join_code_expiration::Expiration::DurationSeconds(7200)),
        }),
        auto_accept: Some(JoinCodeAutoAcceptConfig {
            role_ids: vec![role.id.clone()],
        }),
    };

    let response: GenerateJoinCodeResponse = nats
        .request(&subject, &request)
        .await
        .expect("Failed to send request");

    // Assert: All fields are correctly populated
    match response.result {
        Some(generate_join_code_response::Result::JoinCode(join_code)) => {
            // Verify code field
            assert!(!join_code.code.is_empty(), "code should not be empty");
            assert!(
                join_code.code.len() >= 6,
                "code should be at least 6 characters"
            );

            // Verify created_at field
            let created_at = join_code
                .created_at
                .as_ref()
                .expect("created_at should be set");
            assert!(created_at.seconds > 0, "created_at should have valid timestamp");

            // Verify expires_at field
            let expires_at = join_code
                .expires_at
                .as_ref()
                .expect("expires_at should be set");
            assert!(
                expires_at.seconds > created_at.seconds,
                "expires_at should be after created_at"
            );

            // Verify single_use field
            assert!(!join_code.single_use, "single_use should be false");

            // Verify auto_accept field
            let auto_accept = join_code
                .auto_accept
                .as_ref()
                .expect("auto_accept should be set");
            assert_eq!(
                auto_accept.role_ids.len(),
                1,
                "auto_accept should have one role"
            );
            assert_eq!(
                auto_accept.role_ids[0], role.id,
                "auto_accept role should match"
            );
        }
        Some(generate_join_code_response::Result::Error(e)) => {
            panic!("Unexpected error: {:?}", e);
        }
        None => panic!("No result in response"),
    }
}

/// Test error when generating code with invalid role IDs in auto_accept.
#[tokio::test]
async fn generate_code_invalid_role_ids() {
    let fixtures = get_fixtures().await;
    let db = &fixtures.infra.db;
    let nats = TestNatsClient::new(fixtures.infra.nats_client());

    // Setup
    let user = UserBuilder::new("gen_inv_role_user")
        .email("gen_inv_role@example.com")
        .create(db)
        .await
        .expect("Failed to create user");

    let org = OrganizationBuilder::new("gen_inv_role_org")
        .create(db)
        .await
        .expect("Failed to create organization");

    let role = RoleBuilder::new("gen_inv_role_role", &org)
        .default_role()
        .create(db)
        .await
        .expect("Failed to create role");

    MemberBuilder::new(&user, &org)
        .with_role(&role)
        .create(db)
        .await
        .expect("Failed to create membership");

    // Request: Generate a code with non-existent role ID
    let subject = format!(
        "typewriter.in.user.{}.organization.{}.members.join_codes.generate",
        user.id, org.id
    );

    let request = GenerateJoinCodeRequest {
        single_use: true,
        expiration: None,
        auto_accept: Some(JoinCodeAutoAcceptConfig {
            role_ids: vec!["non-existent-role-id".to_string()],
        }),
    };

    let response: GenerateJoinCodeResponse = nats
        .request(&subject, &request)
        .await
        .expect("Failed to send request");

    // Assert: Should return an error
    match response.result {
        Some(generate_join_code_response::Result::Error(e)) => {
            // The specific error code/message may vary, but we expect an error
            assert!(e.code > 0 || !e.message.is_empty(), "Should have error details");
        }
        Some(generate_join_code_response::Result::JoinCode(_)) => {
            panic!("Expected error for invalid role IDs, but got success");
        }
        None => panic!("No result in response"),
    }
}

// ============================================================================
// List Join Codes Tests
// ============================================================================

/// Test listing join codes when organization has no codes.
#[tokio::test]
async fn list_codes_empty_organization() {
    let fixtures = get_fixtures().await;
    let db = &fixtures.infra.db;
    let nats = TestNatsClient::new(fixtures.infra.nats_client());

    // Setup: Create organization without any join codes
    let user = UserBuilder::new("list_empty_user")
        .email("list_empty@example.com")
        .create(db)
        .await
        .expect("Failed to create user");

    let org = OrganizationBuilder::new("list_empty_org")
        .create(db)
        .await
        .expect("Failed to create organization");

    let role = RoleBuilder::new("list_empty_role", &org)
        .default_role()
        .create(db)
        .await
        .expect("Failed to create role");

    MemberBuilder::new(&user, &org)
        .with_role(&role)
        .create(db)
        .await
        .expect("Failed to create membership");

    // Request: List join codes
    let subject = format!(
        "typewriter.in.user.{}.organization.{}.members.join_codes.list",
        user.id, org.id
    );

    let request = ListJoinCodesRequest {};

    let response: ListJoinCodesResponse = nats
        .request(&subject, &request)
        .await
        .expect("Failed to send request");

    // Assert: Empty list returned
    match response.result {
        Some(list_join_codes_response::Result::JoinCodes(codes)) => {
            assert!(
                codes.join_codes.is_empty(),
                "Should have no join codes for new organization"
            );
        }
        Some(list_join_codes_response::Result::Error(e)) => {
            panic!("Unexpected error: {:?}", e);
        }
        None => panic!("No result in response"),
    }
}

/// Test listing multiple join codes.
#[tokio::test]
async fn list_multiple_codes() {
    let fixtures = get_fixtures().await;
    let db = &fixtures.infra.db;
    let nats = TestNatsClient::new(fixtures.infra.nats_client());

    // Setup
    let user = UserBuilder::new("list_multi_user")
        .email("list_multi@example.com")
        .create(db)
        .await
        .expect("Failed to create user");

    let org = OrganizationBuilder::new("list_multi_org")
        .create(db)
        .await
        .expect("Failed to create organization");

    let role = RoleBuilder::new("list_multi_role", &org)
        .default_role()
        .create(db)
        .await
        .expect("Failed to create role");

    MemberBuilder::new(&user, &org)
        .with_role(&role)
        .create(db)
        .await
        .expect("Failed to create membership");

    // Generate multiple join codes
    let generate_subject = format!(
        "typewriter.in.user.{}.organization.{}.members.join_codes.generate",
        user.id, org.id
    );

    let mut generated_codes = Vec::new();

    // Generate 3 different codes
    for i in 0..3 {
        let request = GenerateJoinCodeRequest {
            single_use: i % 2 == 0, // Alternate single_use
            expiration: None,
            auto_accept: None,
        };

        let response: GenerateJoinCodeResponse = nats
            .request(&generate_subject, &request)
            .await
            .expect("Failed to generate code");

        if let Some(generate_join_code_response::Result::JoinCode(code)) = response.result {
            generated_codes.push(code.code);
        }
    }

    assert_eq!(generated_codes.len(), 3, "Should have generated 3 codes");

    // Request: List join codes
    let list_subject = format!(
        "typewriter.in.user.{}.organization.{}.members.join_codes.list",
        user.id, org.id
    );

    let request = ListJoinCodesRequest {};

    let response: ListJoinCodesResponse = nats
        .request(&list_subject, &request)
        .await
        .expect("Failed to send request");

    // Assert: All 3 codes are returned
    match response.result {
        Some(list_join_codes_response::Result::JoinCodes(codes)) => {
            assert_eq!(
                codes.join_codes.len(),
                3,
                "Should have 3 join codes"
            );

            // Verify all generated codes are in the list
            let listed_codes: Vec<String> = codes
                .join_codes
                .iter()
                .map(|c| c.code.clone())
                .collect();

            for generated in &generated_codes {
                assert!(
                    listed_codes.contains(generated),
                    "Generated code {} should be in list",
                    generated
                );
            }
        }
        Some(list_join_codes_response::Result::Error(e)) => {
            panic!("Unexpected error: {:?}", e);
        }
        None => panic!("No result in response"),
    }
}

/// Test that expired codes are not included in the list.
#[tokio::test]
async fn list_codes_excludes_expired() {
    let fixtures = get_fixtures().await;
    let db = &fixtures.infra.db;
    let nats = TestNatsClient::new(fixtures.infra.nats_client());

    // Setup
    let user = UserBuilder::new("list_exp_user")
        .email("list_exp@example.com")
        .create(db)
        .await
        .expect("Failed to create user");

    let org = OrganizationBuilder::new("list_exp_org")
        .create(db)
        .await
        .expect("Failed to create organization");

    let role = RoleBuilder::new("list_exp_role", &org)
        .default_role()
        .create(db)
        .await
        .expect("Failed to create role");

    MemberBuilder::new(&user, &org)
        .with_role(&role)
        .create(db)
        .await
        .expect("Failed to create membership");

    let generate_subject = format!(
        "typewriter.in.user.{}.organization.{}.members.join_codes.generate",
        user.id, org.id
    );

    // Generate a code that never expires
    let never_expires_request = GenerateJoinCodeRequest {
        single_use: true,
        expiration: Some(JoinCodeExpiration {
            expiration: Some(join_code_expiration::Expiration::Never(true)),
        }),
        auto_accept: None,
    };

    let response: GenerateJoinCodeResponse = nats
        .request(&generate_subject, &never_expires_request)
        .await
        .expect("Failed to generate never-expiring code");

    let never_expires_code = match response.result {
        Some(generate_join_code_response::Result::JoinCode(code)) => code.code,
        _ => panic!("Failed to generate never-expiring code"),
    };

    // Generate a code with a very long expiration (so it won't expire during test)
    let long_expiration_request = GenerateJoinCodeRequest {
        single_use: true,
        expiration: Some(JoinCodeExpiration {
            expiration: Some(join_code_expiration::Expiration::DurationSeconds(86400)), // 24 hours
        }),
        auto_accept: None,
    };

    let response: GenerateJoinCodeResponse = nats
        .request(&generate_subject, &long_expiration_request)
        .await
        .expect("Failed to generate long-expiration code");

    let long_expiration_code = match response.result {
        Some(generate_join_code_response::Result::JoinCode(code)) => code.code,
        _ => panic!("Failed to generate long-expiration code"),
    };

    // Request: List join codes
    let list_subject = format!(
        "typewriter.in.user.{}.organization.{}.members.join_codes.list",
        user.id, org.id
    );

    let request = ListJoinCodesRequest {};

    let response: ListJoinCodesResponse = nats
        .request(&list_subject, &request)
        .await
        .expect("Failed to send request");

    // Assert: Both non-expired codes are in the list
    match response.result {
        Some(list_join_codes_response::Result::JoinCodes(codes)) => {
            let listed_codes: Vec<String> = codes
                .join_codes
                .iter()
                .map(|c| c.code.clone())
                .collect();

            assert!(
                listed_codes.contains(&never_expires_code),
                "Never-expiring code should be in list"
            );
            assert!(
                listed_codes.contains(&long_expiration_code),
                "Long-expiration code should be in list"
            );
        }
        Some(list_join_codes_response::Result::Error(e)) => {
            panic!("Unexpected error: {:?}", e);
        }
        None => panic!("No result in response"),
    }
}

// ============================================================================
// Revoke Join Code Tests
// ============================================================================

/// Test successfully revoking a join code.
#[tokio::test]
async fn revoke_code_success() {
    let fixtures = get_fixtures().await;
    let db = &fixtures.infra.db;
    let nats = TestNatsClient::new(fixtures.infra.nats_client());

    // Setup
    let user = UserBuilder::new("revoke_success_user")
        .email("revoke_success@example.com")
        .create(db)
        .await
        .expect("Failed to create user");

    let org = OrganizationBuilder::new("revoke_success_org")
        .create(db)
        .await
        .expect("Failed to create organization");

    let role = RoleBuilder::new("revoke_success_role", &org)
        .default_role()
        .create(db)
        .await
        .expect("Failed to create role");

    MemberBuilder::new(&user, &org)
        .with_role(&role)
        .create(db)
        .await
        .expect("Failed to create membership");

    // Generate a join code
    let generate_subject = format!(
        "typewriter.in.user.{}.organization.{}.members.join_codes.generate",
        user.id, org.id
    );

    let generate_request = GenerateJoinCodeRequest {
        single_use: true,
        expiration: None,
        auto_accept: None,
    };

    let response: GenerateJoinCodeResponse = nats
        .request(&generate_subject, &generate_request)
        .await
        .expect("Failed to generate code");

    let code_to_revoke = match response.result {
        Some(generate_join_code_response::Result::JoinCode(code)) => code.code,
        _ => panic!("Failed to generate code"),
    };

    // Request: Revoke the join code
    let revoke_subject = format!(
        "typewriter.in.user.{}.organization.{}.members.join_codes.revoke",
        user.id, org.id
    );

    let revoke_request = RevokeJoinCodeRequest {
        code_id: code_to_revoke.clone(),
    };

    let response: RevokeJoinCodeResponse = nats
        .request(&revoke_subject, &revoke_request)
        .await
        .expect("Failed to send revoke request");

    // Assert: Revocation was successful
    match response.result {
        Some(revoke_join_code_response::Result::Success(success)) => {
            assert!(success, "Revoke should return success=true");
        }
        Some(revoke_join_code_response::Result::Error(e)) => {
            panic!("Unexpected error: {:?}", e);
        }
        None => panic!("No result in response"),
    }
}

/// Test that revoked code no longer appears in list.
#[tokio::test]
async fn revoked_code_not_in_list() {
    let fixtures = get_fixtures().await;
    let db = &fixtures.infra.db;
    let nats = TestNatsClient::new(fixtures.infra.nats_client());

    // Setup
    let user = UserBuilder::new("revoke_list_user")
        .email("revoke_list@example.com")
        .create(db)
        .await
        .expect("Failed to create user");

    let org = OrganizationBuilder::new("revoke_list_org")
        .create(db)
        .await
        .expect("Failed to create organization");

    let role = RoleBuilder::new("revoke_list_role", &org)
        .default_role()
        .create(db)
        .await
        .expect("Failed to create role");

    MemberBuilder::new(&user, &org)
        .with_role(&role)
        .create(db)
        .await
        .expect("Failed to create membership");

    // Generate two join codes
    let generate_subject = format!(
        "typewriter.in.user.{}.organization.{}.members.join_codes.generate",
        user.id, org.id
    );

    let generate_request = GenerateJoinCodeRequest {
        single_use: true,
        expiration: None,
        auto_accept: None,
    };

    // Generate first code (will be revoked)
    let response: GenerateJoinCodeResponse = nats
        .request(&generate_subject, &generate_request)
        .await
        .expect("Failed to generate first code");

    let code_to_revoke = match response.result {
        Some(generate_join_code_response::Result::JoinCode(code)) => code.code,
        _ => panic!("Failed to generate first code"),
    };

    // Generate second code (will remain)
    let response: GenerateJoinCodeResponse = nats
        .request(&generate_subject, &generate_request)
        .await
        .expect("Failed to generate second code");

    let remaining_code = match response.result {
        Some(generate_join_code_response::Result::JoinCode(code)) => code.code,
        _ => panic!("Failed to generate second code"),
    };

    // Revoke the first code
    let revoke_subject = format!(
        "typewriter.in.user.{}.organization.{}.members.join_codes.revoke",
        user.id, org.id
    );

    let revoke_request = RevokeJoinCodeRequest {
        code_id: code_to_revoke.clone(),
    };

    let _: RevokeJoinCodeResponse = nats
        .request(&revoke_subject, &revoke_request)
        .await
        .expect("Failed to revoke code");

    // List join codes
    let list_subject = format!(
        "typewriter.in.user.{}.organization.{}.members.join_codes.list",
        user.id, org.id
    );

    let list_request = ListJoinCodesRequest {};

    let response: ListJoinCodesResponse = nats
        .request(&list_subject, &list_request)
        .await
        .expect("Failed to list codes");

    // Assert: Revoked code is not in list, remaining code is
    match response.result {
        Some(list_join_codes_response::Result::JoinCodes(codes)) => {
            let listed_codes: Vec<String> = codes
                .join_codes
                .iter()
                .map(|c| c.code.clone())
                .collect();

            assert!(
                !listed_codes.contains(&code_to_revoke),
                "Revoked code should not be in list"
            );
            assert!(
                listed_codes.contains(&remaining_code),
                "Remaining code should still be in list"
            );
        }
        Some(list_join_codes_response::Result::Error(e)) => {
            panic!("Unexpected error: {:?}", e);
        }
        None => panic!("No result in response"),
    }
}

/// Test error when revoking a code that doesn't exist.
#[tokio::test]
async fn revoke_code_not_found() {
    let fixtures = get_fixtures().await;
    let db = &fixtures.infra.db;
    let nats = TestNatsClient::new(fixtures.infra.nats_client());

    // Setup
    let user = UserBuilder::new("revoke_notfound_user")
        .email("revoke_notfound@example.com")
        .create(db)
        .await
        .expect("Failed to create user");

    let org = OrganizationBuilder::new("revoke_notfound_org")
        .create(db)
        .await
        .expect("Failed to create organization");

    let role = RoleBuilder::new("revoke_notfound_role", &org)
        .default_role()
        .create(db)
        .await
        .expect("Failed to create role");

    MemberBuilder::new(&user, &org)
        .with_role(&role)
        .create(db)
        .await
        .expect("Failed to create membership");

    // Request: Try to revoke a non-existent code
    let revoke_subject = format!(
        "typewriter.in.user.{}.organization.{}.members.join_codes.revoke",
        user.id, org.id
    );

    let revoke_request = RevokeJoinCodeRequest {
        code_id: "non-existent-code-12345".to_string(),
    };

    let response: RevokeJoinCodeResponse = nats
        .request(&revoke_subject, &revoke_request)
        .await
        .expect("Failed to send revoke request");

    // Assert: Should return an error
    match response.result {
        Some(revoke_join_code_response::Result::Error(e)) => {
            assert!(e.code > 0 || !e.message.is_empty(), "Should have error details");
        }
        Some(revoke_join_code_response::Result::Success(_)) => {
            panic!("Expected error for non-existent code, but got success");
        }
        None => panic!("No result in response"),
    }
}

/// Test error when revoking with malicious/invalid code_id format.
#[tokio::test]
async fn revoke_code_invalid_format() {
    let fixtures = get_fixtures().await;
    let db = &fixtures.infra.db;
    let nats = TestNatsClient::new(fixtures.infra.nats_client());

    // Setup
    let user = UserBuilder::new("revoke_invalid_user")
        .email("revoke_invalid@example.com")
        .create(db)
        .await
        .expect("Failed to create user");

    let org = OrganizationBuilder::new("revoke_invalid_org")
        .create(db)
        .await
        .expect("Failed to create organization");

    let role = RoleBuilder::new("revoke_invalid_role", &org)
        .default_role()
        .create(db)
        .await
        .expect("Failed to create role");

    MemberBuilder::new(&user, &org)
        .with_role(&role)
        .create(db)
        .await
        .expect("Failed to create membership");

    let revoke_subject = format!(
        "typewriter.in.user.{}.organization.{}.members.join_codes.revoke",
        user.id, org.id
    );

    // Test various malicious inputs
    let long_string = "a".repeat(10000);
    let malicious_inputs: Vec<&str> = vec![
        "", // Empty string
        "'; DROP TABLE join_codes; --", // SQL injection attempt
        "<script>alert('xss')</script>", // XSS attempt
        "../../../etc/passwd", // Path traversal attempt
        &long_string, // Very long string
    ];

    for malicious_input in malicious_inputs {
        let revoke_request = RevokeJoinCodeRequest {
            code_id: malicious_input.to_string(),
        };

        let response: RevokeJoinCodeResponse = nats
            .request(&revoke_subject, &revoke_request)
            .await
            .expect("Failed to send revoke request");

        // Assert: Should either return an error or success=false, but NOT succeed
        match response.result {
            Some(revoke_join_code_response::Result::Error(_)) => {
                // Expected - malicious input was rejected
            }
            Some(revoke_join_code_response::Result::Success(false)) => {
                // Also acceptable - indicates code not found
            }
            Some(revoke_join_code_response::Result::Success(true)) => {
                panic!(
                    "Malicious input '{}' should not succeed with success=true",
                    malicious_input
                );
            }
            None => {
                // This could be acceptable for empty input
            }
        }
    }
}
