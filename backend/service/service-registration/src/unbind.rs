//! Ends an organization's service registration relationship.
//!
//! Unbinding is separate from status and binding because it is an authenticated organization
//! command over an existing ownership edge. It removes the organization association and any
//! registration lease in one transaction. The service identity and related topology records remain
//! intact, so a later registration starts with a newly issued or observed lease rather than
//! reviving the old one.
//!
//! The transaction owns the ownership check, mutation, and mutation receipt. `recall` returns the
//! prior result for a retry with the same request bytes; `commit` stores the result with the
//! mutation. A service outside the addressed organization has the canonical
//! `ServiceNotFoundError` response and produces no publication. Successful unbinding publishes
//! fresh topology and service snapshots after commit. These publications are intentionally outside
//! the transaction and may fail after the database state is already durable.

use otel_wasi::ResultWithSlug;
use wasmcloud_utils::{
    database::{RecordId, transaction_query},
    publication::{CommittedChange, ProjectionRefresh, PublicationEffect, PublicationExecutor},
    skir::base::service::v1::registration::{
        UnbindServiceRequest, UnbindServiceResponse, UnbindServiceResponse_InvalidOperationIdError,
        UnbindServiceResponse_OperationIdentityReusedError,
        UnbindServiceResponse_ServiceNotFoundError, UnbindServiceResponse_Success,
    },
    skir_variant,
    wasmcloud::messaging::types::NatsMessage,
};

/// Removes the addressed organization's binding from a service.
///
/// Success clears both `organization` and `registration`, then publishes the two organization
/// projections affected by that visibility and ownership change. The response is canonical for
/// the committed command and carries no service payload because the binding has ended. Missing or
/// differently owned services return `ServiceNotFoundError` without changing state.
#[tracing::instrument(skip(msg, request))]
pub async fn handle_unbind(
    msg: NatsMessage,
    scope: wasmcloud_utils::transport_routes::OrganizationActorScope,
    request: UnbindServiceRequest,
) -> Result<UnbindServiceResponse, otel_wasi::Error> {
    let actor_id = scope.user.as_str();
    let org_id = scope.organization.as_str();
    if request.operation_id.is_empty() {
        return Ok(wasmcloud_utils::skir_variant!(
            UnbindServiceResponse::InvalidOperationIdError
        ));
    }
    let receipt = wasmcloud_utils::database::mutation::MutationReceipt::new(
        actor_id,
        org_id,
        "UnbindService",
        &request.operation_id,
        msg.body,
    );
    otel_wasi::main_attribute!(
        "actor.id" = actor_id.to_string(),
        "organization.id" = org_id.to_string(),
        "service.id" = request.service_id.clone()
    );
    let service_id = RecordId::new("service", request.service_id.as_str());
    let organization_id = RecordId::new("organization", org_id);

    let result = receipt
        .bind(
            transaction_query!(
                Option<bool>,
                r#"
        BEGIN TRANSACTION;
        RETURN {
            LET $previous = fn::mutation::recall($receipt, $request_bytes);
            IF $previous != NONE { RETURN $previous.value };
            LET $result = {
RETURN {
            LET $services = SELECT * FROM $service_id
                WHERE organization = $organization_id;
            IF array::is_empty($services) {
                RETURN NONE
            };
            UPDATE ONLY $service_id SET
                organization = NONE,
                registration = NONE;
            RETURN true;
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
            .bind("service_id", service_id)
            .bind("organization_id", organization_id),
        )
        .execute()
        .await
        .error_with_slug("service-unbind-query-failed")?
        .decode()
        .error_with_slug("service-unbind-result-parse-failed")?;
    let result = wasmcloud_utils::skir_domain_result!(UnbindServiceResponse, result,
        "operation-identity-reused-error" => {});

    let Some(true) = result else {
        otel_wasi::main_attribute!("service.outcome" = "not_found");
        return Ok(skir_variant!(UnbindServiceResponse::ServiceNotFoundError));
    };

    otel_wasi::main_attribute!("service.outcome" = "unbound");
    CommittedChange::new(
        skir_variant!(UnbindServiceResponse::Success),
        [
            PublicationEffect::Refresh(ProjectionRefresh::Topology {
                organization: org_id.to_owned(),
            }),
            PublicationEffect::Refresh(ProjectionRefresh::Services {
                organization: org_id.to_owned(),
            }),
        ],
    )
    .publish_with(&PublicationExecutor {
        refresher: crate::publication::ServiceProjectionRefresher,
    })
    .await
}
