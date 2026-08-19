use std::collections::HashMap;

use otel_wasi::ResultWithSlug;
use serde::Deserialize;
use wasmcloud_utils::{
    database::{RecordId, TransactionOutcome, service::ServiceRecord, transaction_query},
    decode_skir, extract_params,
    skir::base::service::v1::{
        organization::{
            ServiceUpdateValidationError, UpdateOrganizationServiceRequest,
            UpdateOrganizationServiceResponse, UpdateOrganizationServiceResponse_ConflictError,
            WatchOrganizationServicesResponse,
        },
        service::Service,
    },
    wasmcloud::messaging::types::BrokerMessage,
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

#[tracing::instrument(skip(msg, params))]
pub async fn handle_update(
    msg: BrokerMessage,
    params: HashMap<String, String>,
) -> Result<UpdateOrganizationServiceResponse, otel_wasi::Error> {
    let (actor_id, org_id) = extract_params!(params, user_id, org_id)?;
    let request = decode_skir!(UpdateOrganizationServiceRequest, &msg.body)?;
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

            RETURN { outcome: 'updated', service: $updated };
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

    let result = match result {
        TransactionOutcome::Committed(result) => result,
        TransactionOutcome::Rejected(error) => wasmcloud_utils::skir_domain_result!(
            UpdateOrganizationServiceResponse,
            TransactionOutcome::Rejected(error)
        ),
    };
    otel_wasi::main_attribute!("service.outcome" = result.as_str());
    let service = match result {
        ServiceUpdateOutcome::Updated { service } => Service::try_from(service)?,
        ServiceUpdateOutcome::ConflictError { actual } => {
            return Ok(UpdateOrganizationServiceResponse::ConflictError(Box::new(
                UpdateOrganizationServiceResponse_ConflictError {
                    expected_revision: request.expected_revision,
                    actual: Service::try_from(actual)?,
                    _unrecognized: None,
                },
            )));
        }
        ServiceUpdateOutcome::ServiceNotFoundError => {
            return Ok(UpdateOrganizationServiceResponse::ServiceNotFoundError(
                Box::default(),
            ));
        }
        ServiceUpdateOutcome::NameInvalid => {
            return Ok(validation_error(ServiceUpdateValidationError::NameInvalid));
        }
    };

    wasmcloud_utils::skir_subjects::organization_services(org_id)
        .publish(WatchOrganizationServicesResponse::Update(Box::new(
            service.clone(),
        )))
        .await?;

    Ok(UpdateOrganizationServiceResponse::Success(Box::new(
        service,
    )))
}

fn validation_error(error: ServiceUpdateValidationError) -> UpdateOrganizationServiceResponse {
    UpdateOrganizationServiceResponse::ValidationError(Box::new(error))
}
