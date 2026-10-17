//! Owns durable binding reads and temporary registration lease issuance.
//!
//! Binding reads are pure. Lease issuance has its own transaction and changes registration only
//! while the service is unbound. Heartbeat and shutdown own liveness independently.

use otel_wasi::ResultWithSlug;
use serde::Deserialize;
use wasmcloud_utils::{
    database::{RecordId, read_query, transaction_query},
    skir::base::service::v1::status::{
        EnsureRegistrationLeaseRequest, EnsureRegistrationLeaseResponse,
        EnsureRegistrationLeaseResponse_AlreadyBound, QueryServiceBindingRequest,
        QueryServiceBindingResponse, QueryServiceBindingResponse_Binding,
        QueryServiceBindingResponse_ServiceNotFoundError, RegistrationLease, ServiceBinding,
        ServiceBinding_Bound,
    },
    skir_domain_result,
    skir_utils::RecordIdKeyIdentity,
    skir_variant,
    transport_routes::ServiceScope,
    wasmcloud::messaging::types::NatsMessage,
};

use crate::utils;
use wasmcloud_utils::database::organization::OrganizationRecord;

#[derive(Debug, Deserialize)]
struct BindingQueryResult {
    organization: Option<OrganizationRecord>,
}

#[derive(Debug, Deserialize)]
struct LeaseQueryResult {
    organization: Option<OrganizationRecord>,
    token: Option<String>,
    expires_at: Option<wasmcloud_utils::database::Datetime>,
}

#[tracing::instrument(skip_all)]
pub async fn handle_binding(
    _msg: NatsMessage,
    scope: ServiceScope,
    _request: QueryServiceBindingRequest,
) -> Result<QueryServiceBindingResponse, otel_wasi::Error> {
    otel_wasi::main_attribute!("service.id" = scope.service.to_string());
    let service_id = RecordId::new("service", scope.service.as_str());
    let result = read_query!(
        "SELECT IF organization THEN { id: organization.id, name: organization.name } ELSE NONE END AS organization FROM $service_id FETCH organization"
    )
    .bind("service_id", service_id)
    .execute()
    .await
    .error_with_slug("service-binding-query-failed")?
    .parse::<Vec<BindingQueryResult>>()
    .error_with_slug("service-binding-result-parse-failed")?;
    let Some(result) = result.into_iter().next() else {
        return Ok(skir_variant!(
            QueryServiceBindingResponse::ServiceNotFoundError {}
        ));
    };
    let binding = match result.organization {
        Some(organization) => skir_variant!(ServiceBinding::Bound {
            organization_id: organization.id.key.raw_identity()?.to_owned(),
            organization_name: Some(organization.name),
        }),
        None => ServiceBinding::Unbound,
    };
    Ok(skir_variant!(QueryServiceBindingResponse::Binding {
        binding
    }))
}

#[tracing::instrument(skip_all)]
pub async fn handle_lease(
    _msg: NatsMessage,
    scope: ServiceScope,
    _request: EnsureRegistrationLeaseRequest,
) -> Result<EnsureRegistrationLeaseResponse, otel_wasi::Error> {
    otel_wasi::main_attribute!("service.id" = scope.service.to_string());
    let service_id = RecordId::new("service", scope.service.as_str());
    let result = transaction_query!(
        LeaseQueryResult,
        r#"
        BEGIN TRANSACTION;
        LET $services = SELECT
            IF organization THEN { id: organization.id, name: organization.name } ELSE NONE END AS organization,
            registration.token AS existing_token,
            registration.expires_at AS existing_expires_at
        FROM $service_id
        FETCH organization;
        IF array::is_empty($services) {
            THROW 'service-not-found-error'
        };
        LET $service = array::first($services);
        LET $registration_token = IF $service.existing_token != NONE AND $service.existing_expires_at > time::now() {
            $service.existing_token
        } ELSE {
            $new_token
        };
        IF $service.organization = NONE AND ($service.existing_token = NONE OR $service.existing_expires_at <= time::now() + 2m) {
            UPDATE ONLY $service_id SET registration = {
                token: $registration_token,
                expires_at: time::now() + 2m30s
            }
        };
        LET $result = array::first(SELECT
            IF organization THEN { id: organization.id, name: organization.name } ELSE NONE END AS organization,
            registration.token AS token,
            registration.expires_at AS expires_at
        FROM $service_id
        FETCH organization);
        RETURN $result;
        COMMIT TRANSACTION;
        "#,
    )
    .bind("service_id", service_id)
    .bind("new_token", utils::generate_registration_token())
    .execute()
    .await
    .error_with_slug("registration-lease-query-failed")?
    .decode()
    .error_with_slug("registration-lease-result-parse-failed")?;
    let result = skir_domain_result!(EnsureRegistrationLeaseResponse, result);
    if let Some(organization) = result.organization {
        return Ok(EnsureRegistrationLeaseResponse::AlreadyBound(Box::new(
            EnsureRegistrationLeaseResponse_AlreadyBound {
                organization_id: organization.id.key.raw_identity()?.to_owned(),
                organization_name: Some(organization.name),
                _unrecognized: None,
            },
        )));
    }
    let token = result.token.ok_or_else(|| {
        otel_wasi::Error::new(
            "registration-lease-result-incomplete",
            "unbound service has no registration token",
        )
    })?;
    let expires_at = result.expires_at.ok_or_else(|| {
        otel_wasi::Error::new(
            "registration-lease-result-incomplete",
            "unbound service has no registration expiry",
        )
    })?;
    Ok(EnsureRegistrationLeaseResponse::Issued(Box::new(
        RegistrationLease {
            token,
            expires_at: expires_at.into(),
            _unrecognized: None,
        },
    )))
}
