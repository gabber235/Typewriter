use otel_wasi::WasiError;
use wasmcloud_utils::skir::base::{
    kernel::v1::record_id::{RecordId, RecordIdKey},
    organization::v1::{member::UpdateOrganizationMemberRolesResponse, user::*},
    service::v1::status::*,
};
use wasmcloud_utils::{
    SkirDomainResult, SkirDomainResultExt, SkirResponse, SkirResponseOutcome, skir_domain_result,
    validate_record_ids,
};

#[test]
fn maps_default_domain_error_slug() {
    let parsed: Result<(), String> = Err("service-not-found-error".to_string());

    let response = parsed
        .into_skir_domain_result::<GetServiceStatusResponse>()
        .expect("known slug should map");

    assert!(matches!(
        response,
        SkirDomainResult::Response(GetServiceStatusResponse::ServiceNotFoundError(_))
    ));
}

#[test]
fn unknown_domain_error_slug_is_internal_error() {
    let parsed: Result<(), String> = Err("typo-error".to_string());

    let error = parsed
        .into_skir_domain_result::<GetServiceStatusResponse>()
        .expect_err("unknown slug should fail");

    assert_eq!(error.slug(), "skir-domain-error-unknown");
}

#[test]
fn macro_override_constructs_payloadful_domain_error() {
    let code = RecordId {
        table: "join_code".to_string(),
        key: RecordIdKey::String("invite".to_string()),
        _unrecognized: None,
    };

    let response = code_not_found_response(Err("code-not-found-error".to_string()), code.clone())
        .expect("known override slug should return response");

    match response {
        SubmitUserJoinRequestResponse::CodeNotFoundError(payload) => {
            assert_eq!(payload.code, code);
        }
        other => panic!("unexpected response: {other:?}"),
    }
}

#[test]
fn invalid_record_id_has_standard_payload_and_metadata() {
    let response = validate_user_id(record_id("service")).expect("validation returns a response");

    let UpdateOrganizationMemberRolesResponse::InvalidRecordIdError(error) = &response else {
        panic!("unexpected response: {response:?}");
    };
    assert_eq!(error.expected_table, "user");
    assert_eq!(error.given_tables, ["service"]);
    assert_eq!(response.outcome(), SkirResponseOutcome::DomainError);
    assert_eq!(response.variant_slug(), "invalid-record-id-error");
    assert_eq!(
        response.variant_message(),
        "Expected record IDs from table 'user', but received tables: 'service'."
    );
}

#[test]
fn invalid_record_id_list_payload_is_sorted_and_deduplicated() {
    let user_ids = vec![
        record_id("user"),
        record_id("zebra"),
        record_id("service"),
        record_id("zebra"),
    ];
    let response = validate_user_ids(user_ids.clone()).expect("validation returns a response");
    let slice_response =
        validate_user_id_slice(&user_ids).expect("slice validation returns a response");

    let UpdateOrganizationMemberRolesResponse::InvalidRecordIdError(error) = &response else {
        panic!("unexpected response: {response:?}");
    };
    assert_eq!(error.expected_table, "user");
    assert_eq!(error.given_tables, ["service", "zebra"]);
    assert_eq!(slice_response, response);
}

fn record_id(table: &str) -> RecordId {
    RecordId {
        table: table.to_owned(),
        key: RecordIdKey::String("id".to_owned()),
        _unrecognized: None,
    }
}

fn validate_user_id(
    user_id: RecordId,
) -> Result<UpdateOrganizationMemberRolesResponse, otel_wasi::Error> {
    validate_record_ids!(UpdateOrganizationMemberRolesResponse, user_id, "user");
    Ok(UpdateOrganizationMemberRolesResponse::Success(
        Default::default(),
    ))
}

fn validate_user_ids(
    user_ids: Vec<RecordId>,
) -> Result<UpdateOrganizationMemberRolesResponse, otel_wasi::Error> {
    validate_record_ids!(UpdateOrganizationMemberRolesResponse, user_ids, "user");
    Ok(UpdateOrganizationMemberRolesResponse::Success(
        Default::default(),
    ))
}

fn validate_user_id_slice(
    user_ids: &[RecordId],
) -> Result<UpdateOrganizationMemberRolesResponse, otel_wasi::Error> {
    validate_record_ids!(UpdateOrganizationMemberRolesResponse, user_ids, "user");
    Ok(UpdateOrganizationMemberRolesResponse::Success(
        Default::default(),
    ))
}

fn code_not_found_response(
    parsed: Result<(), String>,
    code: RecordId,
) -> Result<SubmitUserJoinRequestResponse, otel_wasi::Error> {
    skir_domain_result!(
        SubmitUserJoinRequestResponse,
        parsed,
        "code-not-found-error" => { code: code.clone() },
    );

    Ok(SubmitUserJoinRequestResponse::InternalError(
        Default::default(),
    ))
}
