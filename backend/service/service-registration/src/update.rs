//! Applies organization owned service metadata changes.
//!
//! Metadata update is separate from registration binding because it operates on an already bound
//! service, uses organization authorization, and has compare and set revision semantics. Binding
//! changes ownership and visibility. Update changes the service projection while preserving that
//! ownership. Unbinding removes ownership and clears the lease.
//!
//! The database transaction owns the revision check, name validation, and write. It returns the
//! canonical updated record or the canonical current
//! record for a revision conflict. Validation and not found outcomes perform no write and publish
//! nothing. The watch update is published only after commit, because a message cannot participate
//! in the database rollback boundary.

use otel_wasi::ResultWithSlug;
use serde::Deserialize;
use wasmcloud_utils::{
    database::{RecordId, service::ServiceRecord, transaction_query},
    publication::{CommittedChange, PublicationEffect, PublicationExecutor, TransientFact},
    skir::base::service::v1::{
        organization::{
            OrganizationServicesChanged, ServiceUpdateValidationError,
            UpdateOrganizationServiceRequest, UpdateOrganizationServiceResponse,
            UpdateOrganizationServiceResponse_ConflictError,
            UpdateOrganizationServiceResponse_ServiceNotFoundError,
        },
        service::Service,
    },
    skir_variant,
    wasmcloud::messaging::types::NatsMessage,
};

#[derive(Debug, Deserialize)]
#[serde(tag = "outcome", rename_all = "kebab-case")]
enum ServiceUpdateOutcome {
    Updated { service: ServiceRecord },
    ConflictError { actual: ServiceRecord },
    ServiceNotFoundError,
    NameInvalid,
}

impl ServiceUpdateOutcome {
    fn as_str(&self) -> &'static str {
        match self {
            Self::Updated { .. } => "updated",
            Self::ConflictError { .. } => "conflict-error",
            Self::ServiceNotFoundError => "service-not-found-error",
            Self::NameInvalid => "name-invalid",
        }
    }
}

/// Updates the name of a service owned by the addressed organization.
///
/// The expected revision makes concurrent edits explicit. Success returns the committed service;
/// a conflict returns the current service and the caller's expected revision, allowing the caller
/// to reconcile against canonical state. Invalid names and services outside the organization
/// map to their contract responses without a metadata publication.
/// After a successful commit, the organization service watch receives the updated projection. A
/// publication failure occurs after durable mutation and is therefore not rolled back.
#[tracing::instrument(skip(_msg, request))]
pub async fn handle_update(
    _msg: NatsMessage,
    scope: wasmcloud_utils::transport_routes::OrganizationActorScope,
    request: UpdateOrganizationServiceRequest,
) -> Result<UpdateOrganizationServiceResponse, otel_wasi::Error> {
    let actor_id = scope.user.as_str();
    let org_id = scope.organization.as_str();
    wasmcloud_utils::validate_record_ids!(
        UpdateOrganizationServiceResponse,
        request.service_id,
        "service"
    );
    otel_wasi::main_attribute!(
        "actor.id" = actor_id.to_string(),
        "organization.id" = org_id.to_string(),
        "service.id" = request.service_id.to_string(),
        "service.expected_revision" = request.expected_revision,
    );

    let service_id = RecordId::from(&request.service_id);
    let organization_id = RecordId::new("organization", org_id);
    let result = transaction_query!(
        ServiceUpdateOutcome,
        r#"
        BEGIN TRANSACTION;

        RETURN {
            LET $services = SELECT * FROM $service_id WHERE organization = $organization_id;

            IF array::is_empty($services) {
                RETURN { outcome: 'service-not-found-error' }
            };

            LET $current = array::first($services);
            IF $current.revision != $expected_revision {
                RETURN { outcome: 'conflict-error', actual: $current }
            };

            IF !fn::is_id($name) {
                RETURN { outcome: 'name-invalid' }
            };

            LET $updated = UPDATE ONLY $current.id SET
                name = $name,
                revision = $current.revision + 1
                RETURN AFTER;

            LET $result = { outcome: 'updated', service: $updated };
            RETURN $result;
        };

        COMMIT TRANSACTION;
        "#,
    )
    .bind("service_id", service_id)
    .bind("organization_id", organization_id)
    .bind("expected_revision", request.expected_revision)
    .bind("name", request.name)
    .execute()
    .await
    .error_with_slug("service-update-query-failed")?
    .decode()
    .error_with_slug("service-update-result-parse-failed")?;

    let result = wasmcloud_utils::skir_domain_result!(UpdateOrganizationServiceResponse, result);
    otel_wasi::main_attribute!("service.outcome" = result.as_str());
    let service = match result {
        ServiceUpdateOutcome::Updated { service } => Service::try_from(service)?,
        ServiceUpdateOutcome::ConflictError { actual } => {
            return Ok(skir_variant!(
                UpdateOrganizationServiceResponse::ConflictError {
                    expected_revision: request.expected_revision,
                    actual: Service::try_from(actual)?,
                }
            ));
        }
        ServiceUpdateOutcome::ServiceNotFoundError => {
            return Ok(skir_variant!(
                UpdateOrganizationServiceResponse::ServiceNotFoundError
            ));
        }
        ServiceUpdateOutcome::NameInvalid => {
            return Ok(validation_error(ServiceUpdateValidationError::NameInvalid));
        }
    };

    CommittedChange::new(
        UpdateOrganizationServiceResponse::Success(Box::new(service.clone())),
        [PublicationEffect::CapturedTransient(
            TransientFact::Services {
                organization: org_id.to_owned(),
                event: OrganizationServicesChanged::Update(Box::new(service)),
            },
        )],
    )
    .publish_with(&PublicationExecutor {
        refresher: wasmcloud_utils::publication::CapturedOnly,
    })
    .await
}

fn validation_error(error: ServiceUpdateValidationError) -> UpdateOrganizationServiceResponse {
    UpdateOrganizationServiceResponse::ValidationError(Box::new(error))
}
