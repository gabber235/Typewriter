//! Completes the operator mediated half of service registration.
//!
//! A service first receives a temporary registration lease through `handle_lease`. Binding is
//! separate because it is an organization scoped operator action: the caller presents that lease,
//! the transaction verifies its expiry and organization ownership, then atomically replaces the
//! lease with the durable organization binding. Metadata updates and unbinding have different
//! authorization and consistency rules, so they remain separate operations.
//!
//! The transaction owns the service mutation. Publications happen only after it succeeds. They refresh
//! the organization service view and notify the registrar, but they do not become part of the
//! database transaction.

use otel_wasi::ResultWithSlug;
use serde::Deserialize;
use wasmcloud_utils::{
    database::{RecordId, transaction_query},
    publication::{CommittedChange, ProjectionRefresh, PublicationEffect, PublicationExecutor},
    skir::base::service::v1::registration::{
        BindServiceRequest, BindServiceResponse, BindServiceResponse_Success,
    },
    skir_domain_result,
    skir_utils::RecordIdKeyIdentity,
    skir_variant,
    wasmcloud::messaging::types::NatsMessage,
};

use wasmcloud_utils::database::service::ServiceRecord;

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
#[tracing::instrument(skip(_msg, request))]
pub async fn handle_bind(
    _msg: NatsMessage,
    scope: wasmcloud_utils::transport_routes::OrganizationActorScope,
    request: BindServiceRequest,
) -> Result<BindServiceResponse, otel_wasi::Error> {
    let actor_id = scope.user.as_str();
    let org_id = scope.organization.as_str();
    otel_wasi::main_attribute!(
        "actor.id" = actor_id.to_string(),
        "organization.id" = org_id.to_string()
    );
    let organization_id = RecordId::new("organization", org_id);

    let response = transaction_query!(
        BindResult,
        r#"
        BEGIN TRANSACTION;
        RETURN {
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
        COMMIT TRANSACTION;
        "#,
    )
    .bind("registration_token", request.registration_token)
    .bind("organization_id", organization_id)
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
    let result = skir_domain_result!(BindServiceResponse, result);

    let service_id = result.service.id.key.raw_identity()?.to_owned();
    let service_name = result.service.name.clone();
    let role = result.service.role.clone().try_into()?;

    otel_wasi::main_attribute!(
        "service.id" = service_id.clone(),
        "service.outcome" = "bound"
    );
    CommittedChange::new(
        skir_variant!(BindServiceResponse::Success {
            service_id,
            service_name: Some(service_name),
            service_role: role,
        }),
        [
            PublicationEffect::Refresh(ProjectionRefresh::Services {
                organization: org_id.to_owned(),
            }),
            PublicationEffect::Refresh(ProjectionRefresh::ServiceBinding {
                service: result.service.id,
            }),
        ],
    )
    .publish_with(&PublicationExecutor {
        refresher: crate::publication::ServiceProjectionRefresher,
    })
    .await
}
