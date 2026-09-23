//! Completes the operator mediated half of service registration.
//!
//! A service first receives a temporary registration lease through `handle_status`. Binding is
//! separate because it is an organization scoped operator action: the caller presents that lease,
//! the transaction verifies its expiry and organization ownership, then atomically replaces the
//! lease with the durable organization binding. Metadata updates and unbinding have different
//! authorization and consistency rules, so they remain separate operations.
//!
//! The transaction owns both the service mutation and its mutation receipt. `recall` makes a
//! retried `operation_id` return the stored result, while `commit` records the request bytes with
//! the committed result. Publications happen only after the transaction succeeds. They refresh
//! the organization service view and notify the registrar, but they do not become part of the
//! database transaction.

use std::collections::HashMap;

use otel_wasi::ResultWithSlug;
use serde::Deserialize;
use wasmcloud_utils::{
    database::{RecordId, read_query, transaction_query},
    decode_skir, extract_params,
    skir::base::service::v1::registration::{
        BindServiceRequest, BindServiceResponse, BindServiceResponse_InvalidOperationIdError,
        BindServiceResponse_OperationIdentityReusedError, BindServiceResponse_Success,
        ServiceBoundNotification,
    },
    skir_domain_result, skir_variant,
    wasmcloud::messaging::types::NatsMessage,
};

use wasmcloud_utils::database::{organization::OrganizationRecord, service::ServiceRecord};

#[derive(Debug, Deserialize)]
struct BindResult {
    service: ServiceRecord,
}

/// Binds the service identified by a valid registration token to the addressed organization.
///
/// Invalid or expired tokens and missing organizations leave the lease untouched. A successful
/// response is the canonical service returned by the binding transaction. After commit, this
/// handler publishes the organization snapshot and a service bound notification. Those effects
/// are deliberately outside the transaction, so a publication failure can report an error after
/// the binding itself is durable and a later snapshot can converge the view.
#[tracing::instrument(skip(msg, params))]
pub async fn handle_bind(
    msg: NatsMessage,
    params: HashMap<String, String>,
) -> Result<BindServiceResponse, otel_wasi::Error> {
    let (actor_id, org_id) = extract_params!(params, user_id, org_id)?;
    otel_wasi::main_attribute!(
        "actor.id" = actor_id.to_string(),
        "organization.id" = org_id.to_string()
    );
    let request = decode_skir!(BindServiceRequest, &msg.body)?;
    if request.operation_id.is_empty() {
        return Ok(wasmcloud_utils::skir_variant!(
            BindServiceResponse::InvalidOperationIdError
        ));
    }
    let receipt = wasmcloud_utils::database::mutation::receipt_id(
        actor_id,
        org_id,
        "BindService",
        &request.operation_id,
    );
    let organization_id = RecordId::new("organization", org_id);

    let response = transaction_query!(
        BindResult,
        r#"
        BEGIN TRANSACTION;
        RETURN {
            LET $previous = fn::mutation::recall($receipt, $request_bytes);
            IF $previous != NONE { RETURN $previous.value };
            LET $result = {
LET $services = SELECT * FROM service
            WHERE registration.token = $registration_token
                AND registration.expires_at > time::now();

        IF array::is_empty($services) {
            THROW 'invalid-registration-token-error'
        };

        LET $organizations = SELECT id, name FROM $organization_id;
        IF array::is_empty($organizations) {
            THROW 'organization-not-found-error'
        };

        LET $organization = array::first($organizations);
        LET $updated = UPDATE ONLY $services[0].id SET
            organization = $organization.id,
            registration = NONE
        RETURN AFTER;

        RETURN {
            service: $updated,
        };
            };
            IF $result != NONE {
                LET $stored = fn::mutation::commit($receipt, $request_bytes, { value: $result });
                RETURN $stored.value;
            };
            RETURN $result;
        };
        COMMIT TRANSACTION;
        "#,
    )
    .bind("registration_token", request.registration_token)
    .bind("organization_id", organization_id)
    .bind("receipt", receipt)
    .bind("request_bytes", msg.body.clone())
    .execute()
    .await
    .error_with_slug("service-bind-query-failed")?;
    otel_wasi::main_attribute!(
        "db.query.attempts" = response.attempts().get() as i64,
        "db.query.retries" = response.attempts().get().saturating_sub(1) as i64,
    );
    let result = response
        .decode()
        .error_with_slug("service-bind-result-parse-failed")?;
    let result = skir_domain_result!(BindServiceResponse, result,
        "operation-identity-reused-error" => {});

    let service_id = result.service.id.key.to_string();
    let service_name = result.service.name.clone();
    let role = result.service.role.clone().try_into()?;

    // The database commit is authoritative. Publications are recovery friendly projections and
    // must not be performed inside the transaction because messaging cannot roll back the bind.
    wasmcloud_utils::skir_subjects::organization_services(org_id)
        .publish(crate::watch::snapshot(org_id).await?)
        .await?;

    let organization = read_query!("SELECT VALUE organization.* FROM ONLY $service")
        .bind("service", result.service.id)
        .execute()
        .await
        .error_with_slug("service-binding-snapshot-query-failed")?
        .parse::<Option<OrganizationRecord>>()
        .error_with_slug("service-binding-snapshot-parse-failed")?;
    if let Some(organization) = organization {
        wasmcloud_utils::skir_subjects::service_bound(&service_id)
            .publish(ServiceBoundNotification {
                organization_id: organization.id.key.to_string(),
                organization_name: Some(organization.name),
                _unrecognized: None,
            })
            .await?;
    }

    otel_wasi::main_attribute!(
        "service.id" = service_id.clone(),
        "service.outcome" = "bound"
    );
    Ok(skir_variant!(BindServiceResponse::Success {
        service_id,
        service_name: Some(service_name),
        service_role: role,
    }))
}
