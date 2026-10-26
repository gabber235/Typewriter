//! The generated `SkirResponse` implementations classify every method response by its Skir
//! variant names, including methods served outside the transport routes.

use wasmcloud_utils::skir::base::{
    editor::v1::catalog::{CatalogFetchResult, PrepareValueResult},
    service::v1::{
        identity::IssueServiceIdentityResponse,
        organization::{
            UpdateOrganizationServiceResponse, UpdateOrganizationServiceResponse_ConflictError,
        },
        service::Service,
        status::QueryServiceBindingResponse,
    },
};
use wasmcloud_utils::{SkirResponse, SkirResponseOutcome};

#[test]
fn variant_names_decide_outcomes_and_slugs() {
    let binding = QueryServiceBindingResponse::Binding(Box::default());
    assert_eq!(binding.outcome(), SkirResponseOutcome::Success);
    assert_eq!(binding.variant_slug(), "binding");

    let missing = QueryServiceBindingResponse::ServiceNotFoundError(Box::default());
    assert_eq!(missing.outcome(), SkirResponseOutcome::DomainError);
    assert_eq!(missing.variant_slug(), "service-not-found-error");

    let failed = QueryServiceBindingResponse::internal_error();
    assert_eq!(failed.outcome(), SkirResponseOutcome::InternalError);
    assert_eq!(failed.variant_slug(), "internal-error");

    let unknown = QueryServiceBindingResponse::default();
    assert_eq!(unknown.outcome(), SkirResponseOutcome::InternalError);
    assert_eq!(unknown.variant_slug(), "unknown");
}

#[test]
fn messages_never_include_payload_values() {
    let conflict = |actual_name: &str| {
        UpdateOrganizationServiceResponse::ConflictError(Box::new(
            UpdateOrganizationServiceResponse_ConflictError {
                expected_revision: 3,
                actual: Service {
                    name: actual_name.to_owned(),
                    ..Default::default()
                },
                ..Default::default()
            },
        ))
        .variant_message()
    };

    let message = conflict("secret-service-name");
    assert!(!message.contains("secret-service-name"));
    assert_eq!(message, conflict(""));
}

#[test]
fn an_undocumented_variant_is_described_by_its_slug() {
    let undocumented = CatalogFetchResult::GenerationChangedError(Box::default());
    assert_eq!(undocumented.variant_message(), "generation-changed-error");
}

#[test]
fn domain_errors_are_built_from_their_slugs_with_default_payloads() {
    assert!(matches!(
        QueryServiceBindingResponse::domain_error_from_slug("service-not-found-error"),
        Some(QueryServiceBindingResponse::ServiceNotFoundError(_))
    ));
    assert!(QueryServiceBindingResponse::domain_error_from_slug("binding").is_none());
    assert!(QueryServiceBindingResponse::domain_error_from_slug("internal-error").is_none());
    assert!(matches!(
        PrepareValueResult::domain_error_from_slug("unavailable-error"),
        Some(PrepareValueResult::UnavailableError(_))
    ));
}

#[test]
fn responses_of_methods_outside_the_routes_classify_outcomes() {
    let issued = IssueServiceIdentityResponse::Success(Box::default());
    assert_eq!(issued.outcome(), SkirResponseOutcome::Success);

    let identity =
        IssueServiceIdentityResponse::domain_error_from_slug("unknown-role-error").unwrap();
    assert_eq!(identity.outcome(), SkirResponseOutcome::DomainError);
    assert_eq!(
        IssueServiceIdentityResponse::internal_error().outcome(),
        SkirResponseOutcome::InternalError
    );
}
