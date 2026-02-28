//! Integration tests for the user/organizations CREATE endpoint.
//!
//! Tests the organization creation flow including:
//! - Happy path creation with valid data
//! - Verification that creator becomes a member
//! - Verification that founder and writer roles are created
//! - Validation of name format
//! - Validation of icon_url format
//! - Rejection of malicious input (XSS, injection attempts)

use backend_tests::proto::typewriter::api::v1::{
    CreateOrganizationRequest, CreateOrganizationResponse, ListMembersRequest, ListMembersResponse,
    ListRolesRequest, ListRolesResponse, create_organization_response, list_members_response,
    list_roles_response,
};
use backend_tests::{TestNatsClient, UserBuilder, get_fixtures};

/// Helper to send a create organization request for a given user.
async fn create_organization(
    client: &TestNatsClient<'_>,
    user_id: &str,
    name: &str,
    icon_url: &str,
) -> CreateOrganizationResponse {
    let subject = format!("typewriter.in.user.{}.organization.create", user_id);
    let request = CreateOrganizationRequest {
        name: name.to_string(),
        icon_url: Some(icon_url.to_string()),
    };
    client
        .request::<_, CreateOrganizationResponse>(&subject, &request)
        .await
        .expect("Failed to send create organization request")
}

/// Helper to list members for a given organization.
async fn list_members(
    client: &TestNatsClient<'_>,
    user_id: &str,
    organization_id: &str,
) -> ListMembersResponse {
    let subject = format!(
        "typewriter.in.user.{}.organization.{}.members.list",
        user_id, organization_id
    );
    let request = ListMembersRequest {};
    client
        .request::<_, ListMembersResponse>(&subject, &request)
        .await
        .expect("Failed to send list members request")
}

/// Helper to list roles for a given organization.
async fn list_roles(
    client: &TestNatsClient<'_>,
    user_id: &str,
    organization_id: &str,
) -> ListRolesResponse {
    let subject = format!(
        "typewriter.in.user.{}.organization.{}.roles.list",
        user_id, organization_id
    );
    let request = ListRolesRequest {};
    client
        .request::<_, ListRolesResponse>(&subject, &request)
        .await
        .expect("Failed to send list roles request")
}

/// Helper to assert that the response contains an error with a specific code.
fn assert_error_response(response: &CreateOrganizationResponse, expected_code: Option<u32>) {
    match &response.result {
        Some(create_organization_response::Result::Error(error)) => {
            if let Some(code) = expected_code {
                assert_eq!(
                    error.code, code,
                    "Expected error code {} but got {}: {}",
                    code, error.code, error.message
                );
            }
        }
        Some(create_organization_response::Result::Organization(org)) => {
            panic!(
                "Expected error response but got organization: {:?}",
                org.name
            );
        }
        None => {
            panic!("Expected error response but got empty result");
        }
    }
}

/// Helper to assert that the response contains a successful organization.
fn assert_success_response(
    response: &CreateOrganizationResponse,
) -> &backend_tests::proto::typewriter::models::v1::OrganizationData {
    match &response.result {
        Some(create_organization_response::Result::Organization(org)) => org,
        Some(create_organization_response::Result::Error(error)) => {
            panic!(
                "Expected success response but got error: code={}, message={}",
                error.code, error.message
            );
        }
        None => {
            panic!("Expected success response but got empty result");
        }
    }
}

// =============================================================================
// HAPPY PATH TESTS
// =============================================================================

/// Test: Create organization with valid name and icon_url.
///
/// This test verifies that a user can successfully create an organization
/// with a valid name and icon URL, and that the response contains the
/// created organization data.
#[tokio::test]
async fn test_create_organization_happy_path() {
    let fixtures = get_fixtures().await;
    let client = TestNatsClient::new(fixtures.infra.nats_client());

    // Create a test user
    let user = UserBuilder::new("test_create_happy_path_user")
        .email("happy@example.com")
        .create(&fixtures.infra.db)
        .await
        .expect("Failed to create test user");

    // Create an organization with valid data
    let org_name = "test_happy_org";
    let icon_url = "https://example.com/icon.png";

    let response = create_organization(&client, &user.id, org_name, icon_url).await;

    let org = assert_success_response(&response);

    assert_eq!(
        org.name,
        Some(org_name.to_string()),
        "Organization name should match"
    );
    assert_eq!(
        org.icon_url,
        Some(icon_url.to_string()),
        "Icon URL should match"
    );
    assert!(
        !org.organization_id.is_empty(),
        "Organization ID should not be empty"
    );
    assert!(org.created_at.is_some(), "Created timestamp should be set");
}

/// Test: Create organization with underscores in name.
///
/// Verifies that organization names with underscores are accepted
/// as long as they follow the pattern.
#[tokio::test]
async fn test_create_organization_with_underscores() {
    let fixtures = get_fixtures().await;
    let client = TestNatsClient::new(fixtures.infra.nats_client());

    let user = UserBuilder::new("test_underscore_user")
        .create(&fixtures.infra.db)
        .await
        .expect("Failed to create test user");

    let org_name = "my_cool_org";
    let icon_url = "https://example.com/underscore-icon.png";

    let response = create_organization(&client, &user.id, org_name, icon_url).await;

    let org = assert_success_response(&response);
    assert_eq!(
        org.name,
        Some(org_name.to_string()),
        "Organization name with underscores should be accepted"
    );
}

/// Test: Create organization with numbers in name.
///
/// Verifies that organization names with numbers are accepted.
#[tokio::test]
async fn test_create_organization_with_numbers() {
    let fixtures = get_fixtures().await;
    let client = TestNatsClient::new(fixtures.infra.nats_client());

    let user = UserBuilder::new("test_numbers_user")
        .create(&fixtures.infra.db)
        .await
        .expect("Failed to create test user");

    let org_name = "org123";
    let icon_url = "https://example.com/numbers-icon.png";

    let response = create_organization(&client, &user.id, org_name, icon_url).await;

    let org = assert_success_response(&response);
    assert_eq!(
        org.name,
        Some(org_name.to_string()),
        "Organization name with numbers should be accepted"
    );
}

// =============================================================================
// MEMBERSHIP VERIFICATION TESTS
// =============================================================================

/// Test: Verify creator becomes a member after creation.
///
/// After creating an organization, the creator should automatically
/// become a member of that organization with the founder role.
#[tokio::test]
async fn test_creator_becomes_member() {
    let fixtures = get_fixtures().await;
    let client = TestNatsClient::new(fixtures.infra.nats_client());

    let user = UserBuilder::new("test_membership_user")
        .email("member@example.com")
        .create(&fixtures.infra.db)
        .await
        .expect("Failed to create test user");

    let org_name = "test_membership_org";
    let icon_url = "https://example.com/membership-icon.png";

    let create_response = create_organization(&client, &user.id, org_name, icon_url).await;
    let org = assert_success_response(&create_response);

    // List members to verify the creator is a member
    let members_response = list_members(&client, &user.id, &org.organization_id).await;

    match &members_response.result {
        Some(list_members_response::Result::Members(members_list)) => {
            assert_eq!(
                members_list.members.len(),
                1,
                "Should have exactly one member (the creator)"
            );

            let member = &members_list.members[0];
            assert_eq!(member.name, user.name, "Member name should match user name");
        }
        Some(list_members_response::Result::Error(error)) => {
            panic!("Failed to list members: {}", error.message);
        }
        None => {
            panic!("Empty response when listing members");
        }
    }
}

// =============================================================================
// ROLE VERIFICATION TESTS
// =============================================================================

/// Test: Verify founder and writer roles are created.
///
/// When an organization is created, it should automatically have
/// two roles: 'founder' (non-assignable, non-deletable) and 'writer'
/// (default role, assignable, non-deletable).
#[tokio::test]
async fn test_founder_and_writer_roles_created() {
    let fixtures = get_fixtures().await;
    let client = TestNatsClient::new(fixtures.infra.nats_client());

    let user = UserBuilder::new("test_roles_user")
        .create(&fixtures.infra.db)
        .await
        .expect("Failed to create test user");

    let org_name = "test_roles_org";
    let icon_url = "https://example.com/roles-icon.png";

    let create_response = create_organization(&client, &user.id, org_name, icon_url).await;
    let org = assert_success_response(&create_response);

    // List roles to verify founder and writer roles exist
    let roles_response = list_roles(&client, &user.id, &org.organization_id).await;

    match &roles_response.result {
        Some(list_roles_response::Result::Roles(roles_list)) => {
            assert_eq!(
                roles_list.roles.len(),
                2,
                "Should have exactly two roles (founder and writer)"
            );

            let role_names: Vec<String> = roles_list
                .roles
                .iter()
                .filter_map(|r| r.name.clone())
                .collect();
            assert!(
                role_names.contains(&"founder".to_string()),
                "Should have 'founder' role, got: {:?}",
                role_names
            );
            assert!(
                role_names.contains(&"writer".to_string()),
                "Should have 'writer' role, got: {:?}",
                role_names
            );

            // Verify founder role properties
            let founder_role = roles_list
                .roles
                .iter()
                .find(|r| r.name == Some("founder".to_string()))
                .unwrap();
            assert!(
                !founder_role.assignable.unwrap_or_default(),
                "Founder role should not be assignable"
            );
            assert!(
                !founder_role.deletable.unwrap_or_default(),
                "Founder role should not be deletable"
            );

            // Verify writer role properties
            let writer_role = roles_list
                .roles
                .iter()
                .find(|r| r.name == Some("writer".to_string()))
                .unwrap();
            assert!(
                writer_role.assignable.unwrap_or_default(),
                "Writer role should be assignable"
            );
            assert!(
                !writer_role.deletable.unwrap_or_default(),
                "Writer role should not be deletable"
            );
            assert!(
                writer_role.default_role.unwrap_or_default(),
                "Writer role should be the default role"
            );
        }
        Some(list_roles_response::Result::Error(error)) => {
            panic!("Failed to list roles: {}", error.message);
        }
        None => {
            panic!("Empty response when listing roles");
        }
    }
}

/// Test: Verify creator has founder role.
///
/// The creator of an organization should be assigned the founder role.
#[tokio::test]
async fn test_creator_has_founder_role() {
    let fixtures = get_fixtures().await;
    let client = TestNatsClient::new(fixtures.infra.nats_client());

    let user = UserBuilder::new("test_founder_role_user")
        .create(&fixtures.infra.db)
        .await
        .expect("Failed to create test user");

    let org_name = "test_founder_role_org";
    let icon_url = "https://example.com/founder-icon.png";

    let create_response = create_organization(&client, &user.id, org_name, icon_url).await;
    let org = assert_success_response(&create_response);

    // List members to verify the creator has the founder role
    let members_response = list_members(&client, &user.id, &org.organization_id).await;

    match &members_response.result {
        Some(list_members_response::Result::Members(members_list)) => {
            assert!(
                !members_list.members.is_empty(),
                "Should have at least one member"
            );

            let member = &members_list.members[0];
            let role_names: Vec<String> =
                member.roles.iter().filter_map(|r| r.name.clone()).collect();

            assert!(
                role_names.contains(&"founder".to_string()),
                "Creator should have 'founder' role, got: {:?}",
                role_names
            );
        }
        Some(list_members_response::Result::Error(error)) => {
            panic!("Failed to list members: {}", error.message);
        }
        None => {
            panic!("Empty response when listing members");
        }
    }
}

// =============================================================================
// NAME VALIDATION TESTS
// =============================================================================

/// Test: Empty name should be rejected.
///
/// Organization names cannot be empty.
#[tokio::test]
async fn test_create_organization_empty_name() {
    let fixtures = get_fixtures().await;
    let client = TestNatsClient::new(fixtures.infra.nats_client());

    let user = UserBuilder::new("test_empty_name_user")
        .create(&fixtures.infra.db)
        .await
        .expect("Failed to create test user");

    let response = create_organization(&client, &user.id, "", "https://example.com/icon.png").await;

    assert_error_response(&response, None);
}

/// Test: Name with uppercase letters should be rejected.
///
/// Organization names must be lowercase only (pattern: ^[a-z0-9][a-z0-9_]{1,}[a-z0-9]$).
#[tokio::test]
async fn test_create_organization_uppercase_name() {
    let fixtures = get_fixtures().await;
    let client = TestNatsClient::new(fixtures.infra.nats_client());

    let user = UserBuilder::new("test_uppercase_name_user")
        .create(&fixtures.infra.db)
        .await
        .expect("Failed to create test user");

    let response =
        create_organization(&client, &user.id, "MyOrg", "https://example.com/icon.png").await;

    assert_error_response(&response, None);
}

/// Test: Name with special characters should be rejected.
///
/// Organization names can only contain lowercase letters, numbers, and underscores.
#[tokio::test]
async fn test_create_organization_special_chars_name() {
    let fixtures = get_fixtures().await;
    let client = TestNatsClient::new(fixtures.infra.nats_client());

    let user = UserBuilder::new("test_special_chars_user")
        .create(&fixtures.infra.db)
        .await
        .expect("Failed to create test user");

    // Test various special characters
    let invalid_names = [
        "org-name", // hyphen not allowed
        "org.name", // dot not allowed
        "org@name", // at sign not allowed
        "org name", // space not allowed
        "org!name", // exclamation not allowed
        "org#name", // hash not allowed
        "org$name", // dollar not allowed
    ];

    for name in invalid_names {
        let response =
            create_organization(&client, &user.id, name, "https://example.com/icon.png").await;
        assert_error_response(&response, None);
    }
}

/// Test: Name too short should be rejected.
///
/// Organization names must be at least 3 characters (pattern requires start + 2+ middle + end).
#[tokio::test]
async fn test_create_organization_name_too_short() {
    let fixtures = get_fixtures().await;
    let client = TestNatsClient::new(fixtures.infra.nats_client());

    let user = UserBuilder::new("test_short_name_user")
        .create(&fixtures.infra.db)
        .await
        .expect("Failed to create test user");

    // Test names that are too short
    let short_names = ["a", "ab"];

    for name in short_names {
        let response =
            create_organization(&client, &user.id, name, "https://example.com/icon.png").await;
        assert_error_response(&response, None);
    }
}

/// Test: Name starting with underscore should be rejected.
///
/// Organization names must start with a letter or number.
#[tokio::test]
async fn test_create_organization_name_starts_with_underscore() {
    let fixtures = get_fixtures().await;
    let client = TestNatsClient::new(fixtures.infra.nats_client());

    let user = UserBuilder::new("test_underscore_start_user")
        .create(&fixtures.infra.db)
        .await
        .expect("Failed to create test user");

    let response =
        create_organization(&client, &user.id, "_myorg", "https://example.com/icon.png").await;

    assert_error_response(&response, None);
}

/// Test: Name ending with underscore should be rejected.
///
/// Organization names must end with a letter or number.
#[tokio::test]
async fn test_create_organization_name_ends_with_underscore() {
    let fixtures = get_fixtures().await;
    let client = TestNatsClient::new(fixtures.infra.nats_client());

    let user = UserBuilder::new("test_underscore_end_user")
        .create(&fixtures.infra.db)
        .await
        .expect("Failed to create test user");

    let response =
        create_organization(&client, &user.id, "myorg_", "https://example.com/icon.png").await;

    assert_error_response(&response, None);
}

// =============================================================================
// ICON URL VALIDATION TESTS
// =============================================================================

/// Test: Empty icon_url should be rejected.
///
/// The icon_url must be a valid URL.
#[tokio::test]
async fn test_create_organization_empty_icon_url() {
    let fixtures = get_fixtures().await;
    let client = TestNatsClient::new(fixtures.infra.nats_client());

    let user = UserBuilder::new("test_empty_icon_user")
        .create(&fixtures.infra.db)
        .await
        .expect("Failed to create test user");

    let response = create_organization(&client, &user.id, "valid_org", "").await;

    assert_error_response(&response, None);
}

/// Test: Invalid icon_url format should be rejected.
///
/// The icon_url must be a valid URL format.
#[tokio::test]
async fn test_create_organization_invalid_icon_url() {
    let fixtures = get_fixtures().await;
    let client = TestNatsClient::new(fixtures.infra.nats_client());

    let user = UserBuilder::new("test_invalid_icon_user")
        .create(&fixtures.infra.db)
        .await
        .expect("Failed to create test user");

    let invalid_urls = [
        "not-a-url",
        "just text",
        "ftp://invalid", // might be invalid depending on validation
        "/path/to/file",
    ];

    for url in invalid_urls {
        let response = create_organization(&client, &user.id, "valid_org_url", url).await;
        assert_error_response(&response, None);
    }
}

// =============================================================================
// MALICIOUS INPUT TESTS (XSS)
// =============================================================================

/// Test: XSS attempt in name should be rejected.
///
/// Script tags and other XSS payloads in the organization name should be
/// rejected by the validation pattern (uppercase, special chars not allowed).
#[tokio::test]
async fn test_create_organization_xss_in_name() {
    let fixtures = get_fixtures().await;
    let client = TestNatsClient::new(fixtures.infra.nats_client());

    let user = UserBuilder::new("test_xss_name_user")
        .create(&fixtures.infra.db)
        .await
        .expect("Failed to create test user");

    let xss_payloads = [
        "<script>alert(1)</script>",
        "<img src=x onerror=alert(1)>",
        "javascript:alert(1)",
        "<svg onload=alert(1)>",
        "'\"><script>alert(1)</script>",
    ];

    for payload in xss_payloads {
        let response =
            create_organization(&client, &user.id, payload, "https://example.com/icon.png").await;
        assert_error_response(&response, None);
    }
}

/// Test: XSS attempt in icon_url should be rejected.
///
/// Script tags and javascript: URLs in icon_url should be rejected.
#[tokio::test]
async fn test_create_organization_xss_in_icon_url() {
    let fixtures = get_fixtures().await;
    let client = TestNatsClient::new(fixtures.infra.nats_client());

    let user = UserBuilder::new("test_xss_icon_user")
        .create(&fixtures.infra.db)
        .await
        .expect("Failed to create test user");

    let xss_payloads = [
        "javascript:alert(1)",
        "data:text/html,<script>alert(1)</script>",
        "javascript:alert(document.cookie)",
    ];

    for payload in xss_payloads {
        let response = create_organization(&client, &user.id, "valid_xss_org", payload).await;
        assert_error_response(&response, None);
    }
}

// =============================================================================
// MALICIOUS INPUT TESTS (SQL/SURREALDB INJECTION)
// =============================================================================

/// Test: SQL/SurrealDB injection attempt in name should be rejected.
///
/// Injection attempts in the organization name should be rejected by the
/// validation pattern (special characters not allowed).
#[tokio::test]
async fn test_create_organization_sql_injection_in_name() {
    let fixtures = get_fixtures().await;
    let client = TestNatsClient::new(fixtures.infra.nats_client());

    let user = UserBuilder::new("test_sql_injection_user")
        .create(&fixtures.infra.db)
        .await
        .expect("Failed to create test user");

    let injection_payloads = [
        "'; DROP TABLE organization; --",
        "' OR '1'='1",
        "'; DELETE FROM user; --",
        "1; SELECT * FROM user",
        "test' UNION SELECT * FROM user --",
        "test'); DROP TABLE organization; --",
    ];

    for payload in injection_payloads {
        let response =
            create_organization(&client, &user.id, payload, "https://example.com/icon.png").await;
        assert_error_response(&response, None);
    }
}

/// Test: SurrealDB-specific injection attempt in name.
///
/// SurrealDB-specific syntax in the organization name should be rejected.
#[tokio::test]
async fn test_create_organization_surrealdb_injection_in_name() {
    let fixtures = get_fixtures().await;
    let client = TestNatsClient::new(fixtures.infra.nats_client());

    let user = UserBuilder::new("test_surreal_injection_user")
        .create(&fixtures.infra.db)
        .await
        .expect("Failed to create test user");

    let injection_payloads = [
        "test; INFO FOR DB;",
        "test; REMOVE TABLE organization;",
        "test; CREATE user SET admin = true;",
        "test`; SELECT * FROM user; --",
        "$input.name; DROP TABLE organization;",
    ];

    for payload in injection_payloads {
        let response =
            create_organization(&client, &user.id, payload, "https://example.com/icon.png").await;
        assert_error_response(&response, None);
    }
}

/// Test: Injection attempt in icon_url.
///
/// While icon_url validation is primarily URL format, we should still
/// verify that malicious payloads don't cause issues.
#[tokio::test]
async fn test_create_organization_injection_in_icon_url() {
    let fixtures = get_fixtures().await;
    let client = TestNatsClient::new(fixtures.infra.nats_client());

    let user = UserBuilder::new("test_icon_injection_user")
        .create(&fixtures.infra.db)
        .await
        .expect("Failed to create test user");

    // These might be valid URLs but contain injection attempts
    let injection_payloads = [
        "https://example.com/icon.png'; DROP TABLE organization; --",
        "https://example.com/icon.png?q='; DELETE FROM user; --",
    ];

    for payload in injection_payloads {
        let response = create_organization(&client, &user.id, "valid_injection_org", payload).await;
        // These should either be rejected as invalid URLs or safely stored
        // The key is that no injection should occur
        match &response.result {
            Some(create_organization_response::Result::Organization(org)) => {
                // If accepted, the URL should be stored exactly as provided (escaped properly)
                assert!(
                    !org.icon_url.clone().is_none_or(|s| s.is_empty()),
                    "Icon URL should not be empty if organization was created"
                );
            }
            Some(create_organization_response::Result::Error(_)) => {
                // Expected - invalid URL format rejected
            }
            None => {
                panic!("Empty response");
            }
        }
    }
}

// =============================================================================
// EDGE CASE TESTS
// =============================================================================

/// Test: Organization name at minimum valid length (3 chars).
///
/// The pattern ^[a-z0-9][a-z0-9_]{1,}[a-z0-9]$ requires at least 3 characters.
#[tokio::test]
async fn test_create_organization_minimum_valid_length() {
    let fixtures = get_fixtures().await;
    let client = TestNatsClient::new(fixtures.infra.nats_client());

    let user = UserBuilder::new("test_min_length_user")
        .create(&fixtures.infra.db)
        .await
        .expect("Failed to create test user");

    let org_name = "abc"; // Minimum valid: start(a) + middle(b) + end(c)
    let icon_url = "https://example.com/min-icon.png";

    let response = create_organization(&client, &user.id, org_name, icon_url).await;

    let org = assert_success_response(&response);
    assert_eq!(
        org.name,
        Some(org_name.to_string()),
        "Minimum length name should be accepted"
    );
}

/// Test: Organization name with only numbers.
///
/// All-numeric names should be valid if they meet the length requirement.
#[tokio::test]
async fn test_create_organization_numeric_name() {
    let fixtures = get_fixtures().await;
    let client = TestNatsClient::new(fixtures.infra.nats_client());

    let user = UserBuilder::new("test_numeric_name_user")
        .create(&fixtures.infra.db)
        .await
        .expect("Failed to create test user");

    let org_name = "123";
    let icon_url = "https://example.com/numeric-icon.png";

    let response = create_organization(&client, &user.id, org_name, icon_url).await;

    let org = assert_success_response(&response);
    assert_eq!(
        org.name,
        Some(org_name.to_string()),
        "All-numeric name should be accepted"
    );
}

/// Test: Organization name with mixed underscores.
///
/// Multiple underscores in the middle should be valid.
#[tokio::test]
async fn test_create_organization_multiple_underscores() {
    let fixtures = get_fixtures().await;
    let client = TestNatsClient::new(fixtures.infra.nats_client());

    let user = UserBuilder::new("test_multi_underscore_user")
        .create(&fixtures.infra.db)
        .await
        .expect("Failed to create test user");

    let org_name = "my__test__org";
    let icon_url = "https://example.com/underscore-icon.png";

    let response = create_organization(&client, &user.id, org_name, icon_url).await;

    let org = assert_success_response(&response);
    assert_eq!(
        org.name,
        Some(org_name.to_string()),
        "Name with multiple underscores should be accepted"
    );
}

/// Test: Valid HTTPS icon URL.
///
/// Standard HTTPS URLs should be accepted.
#[tokio::test]
async fn test_create_organization_https_icon_url() {
    let fixtures = get_fixtures().await;
    let client = TestNatsClient::new(fixtures.infra.nats_client());

    let user = UserBuilder::new("test_https_icon_user")
        .create(&fixtures.infra.db)
        .await
        .expect("Failed to create test user");

    let org_name = "https_test_org";
    let icon_url = "https://cdn.example.com/icons/org-icon.png?v=1";

    let response = create_organization(&client, &user.id, org_name, icon_url).await;

    let org = assert_success_response(&response);
    assert_eq!(
        org.icon_url,
        Some(icon_url.to_string()),
        "HTTPS URL should be accepted"
    );
}

/// Test: Valid HTTP icon URL.
///
/// HTTP URLs should also be valid (though not recommended in production).
#[tokio::test]
async fn test_create_organization_http_icon_url() {
    let fixtures = get_fixtures().await;
    let client = TestNatsClient::new(fixtures.infra.nats_client());

    let user = UserBuilder::new("test_http_icon_user")
        .create(&fixtures.infra.db)
        .await
        .expect("Failed to create test user");

    let org_name = "http_test_org";
    let icon_url = "http://example.com/icon.png";

    let response = create_organization(&client, &user.id, org_name, icon_url).await;

    let org = assert_success_response(&response);
    assert_eq!(
        org.icon_url,
        Some(icon_url.to_string()),
        "HTTP URL should be accepted"
    );
}
