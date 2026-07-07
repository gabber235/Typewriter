use otel_wasi::WasiError;
use wasmcloud_utils::skir::base::{
    kernel::v1::record_id::{RecordId, RecordIdKey},
    organization::v1::user::*,
    service::v1::status::*,
};
use wasmcloud_utils::{SkirDomainResult, SkirDomainResultExt, skir_domain_result};

#[test]
fn maps_default_domain_error_slug() {
    let parsed: Result<(), String> = Err("service-not-found".to_string());

    let response = parsed
        .into_skir_domain_result::<GetServiceStatusResponse>()
        .expect("known slug should map");

    assert!(matches!(
        response,
        SkirDomainResult::Response(GetServiceStatusResponse::ServiceNotFound(_))
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
