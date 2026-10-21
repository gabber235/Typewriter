//! The generated `SkirResponse` implementations classify every method response by its Skir
//! variant names, including methods served outside the transport routes.

use wasmcloud_utils::skir::base::{
    access::v1::permission::GetEntityPermissionResponse,
    editor::v1::catalog::{CatalogFetchResult, PrepareValueResult},
    service::v1::{
        identity::IssueServiceIdentityResponse,
        organization::{
            UpdateOrganizationServiceResponse, UpdateOrganizationServiceResponse_ConflictError,
        },
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
fn messages_come_from_variant_docs_never_from_payloads() {
    let missing = QueryServiceBindingResponse::ServiceNotFoundError(Box::default());
    assert_eq!(missing.variant_message(), "Service not found.");

    // The conflict payload carries the current service; only the doc comment is reported.
    let conflict = UpdateOrganizationServiceResponse::ConflictError(Box::new(
        UpdateOrganizationServiceResponse_ConflictError {
            expected_revision: 3,
            ..Default::default()
        },
    ));
    assert_eq!(conflict.variant_message(), "Service changed elsewhere.");

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
fn methods_outside_the_routes_and_former_struct_responses_are_covered() {
    let identity =
        IssueServiceIdentityResponse::domain_error_from_slug("unknown-role-error").unwrap();
    assert_eq!(identity.outcome(), SkirResponseOutcome::DomainError);
    assert_eq!(identity.variant_message(), "Unknown role.");

    let granted = GetEntityPermissionResponse::Granted(Box::default());
    assert_eq!(granted.outcome(), SkirResponseOutcome::Success);
    assert_eq!(
        GetEntityPermissionResponse::internal_error().outcome(),
        SkirResponseOutcome::InternalError
    );
}
