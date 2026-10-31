mod support;

use support::{MemberUpdateOutcome, member_update_response as map_outcome, record_id};
use wasmcloud_utils::skir::base::organization::v1::member::*;

#[test]
fn returns_success_value() {
    let member = OrganizationMember::default();
    let response = map_outcome(
        MemberUpdateOutcome::Updated {
            member: member.clone(),
        },
        record_id("user", "member"),
    )
    .expect("success outcome should map");

    assert_eq!(
        response,
        UpdateOrganizationMemberRolesResponse::Success(Box::new(
            UpdateOrganizationMemberRolesResponse_Success {
                members: vec![member],
                ..Default::default()
            },
        ))
    );
}

#[test]
fn maps_database_payload_to_error_variant() {
    let missing = record_id("organization_role", "missing");
    let response = map_outcome(
        MemberUpdateOutcome::RolesNotFoundError {
            role_ids: vec![missing.clone()],
        },
        record_id("user", "member"),
    )
    .expect("payloadful error outcome should map");

    let UpdateOrganizationMemberRolesResponse::RolesNotFoundError(error) = response else {
        panic!("expected roles not found response")
    };
    assert_eq!(error.role_ids, [missing]);
}

#[test]
fn maps_request_payload_to_error_variant() {
    let user_id = record_id("user", "missing");
    let response = map_outcome(MemberUpdateOutcome::UserNotFoundError, user_id.clone())
        .expect("request payload error outcome should map");

    let UpdateOrganizationMemberRolesResponse::UserNotFoundError(error) = response else {
        panic!("expected user not found response")
    };
    assert_eq!(error.user_ids, [user_id]);
}

#[test]
fn maps_payloadless_error_variant() {
    let response = map_outcome(
        MemberUpdateOutcome::FounderRoleRequiredError,
        record_id("user", "member"),
    )
    .expect("payloadless error outcome should map");

    assert!(matches!(
        response,
        UpdateOrganizationMemberRolesResponse::FounderRoleRequiredError(_)
    ));
}
