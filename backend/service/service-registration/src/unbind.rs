//! Ends an organization's service registration relationships.
//!
//! Unbinding is separate from status and binding because it is an authenticated organization
//! command over existing ownership edges. A request is a batch of services that unbinds all or
//! nothing: it removes each organization association and registration lease in one transaction.
//! The service identities and related topology records remain intact, so a later registration
//! starts with a newly issued or observed lease rather than reviving the old one.
//!
//! The transaction checks every item's ownership before writing, so a batch naming a service
//! outside the addressed organization changes nothing, lists each such service with the
//! canonical not found reason, and produces no publication. A service named twice refuses the
//! batch before the database is read. Successful unbinding publishes fresh topology and service
//! snapshots after commit. These publications are intentionally outside the transaction and may
//! fail after the database state is already durable.

use otel_wasi::ResultWithSlug;
use serde::Serialize;
use wasmcloud_utils::{
    database::{RecordId, transaction_query},
    publication::{CommittedChange, ProjectionRefresh, PublicationEffect, PublicationExecutor},
    skir::base::service::v1::registration::{
        RefusedServiceUnbind, ServiceUnbindRefusal, ServiceUnbindRefusal_DuplicateError,
        ServiceUnbindRefusal_ServiceNotFoundError, UnbindServicesRequest, UnbindServicesResponse,
        UnbindServicesResponse_Success,
    },
    skir_variant,
};

/// One unbinding as the transaction reads it; `index` is its position in the request.
#[derive(Debug, Serialize)]
struct UnbindInput {
    index: usize,
    service: RecordId,
}

/// Removes the addressed organization's binding from every requested service, or from none.
///
/// Success clears both `organization` and `registration` of each service, then publishes the two
/// organization projections affected by that visibility and ownership change. The response
/// carries no service payload because the bindings have ended. Missing or differently owned
/// services refuse the whole batch without changing state.
#[tracing::instrument(skip(request))]
pub async fn handle_unbind(
    scope: wasmcloud_utils::transport::OrganizationActorScope,
    request: UnbindServicesRequest,
) -> Result<UnbindServicesResponse, otel_wasi::Error> {
    let actor_id = scope.user.as_str();
    let org_id = scope.organization.as_str();
    otel_wasi::main_attribute!(
        "actor.id" = actor_id.to_string(),
        "organization.id" = org_id.to_string(),
        "service.batch_size" = request.service_ids.len() as i64,
    );
    let service_ids = request.service_ids;
    let repeated = (0..service_ids.len())
        .filter(|index| crate::utils::repeats_earlier(&service_ids, *index))
        .map(|index| refused(service_ids[index].clone(), duplicate()))
        .collect::<Vec<_>>();
    if !repeated.is_empty() {
        otel_wasi::main_attribute!("service.outcome" = "repeated");
        return Ok(UnbindServicesResponse::RefusedError(repeated));
    }

    let inputs = service_ids
        .iter()
        .enumerate()
        .map(|(index, service)| UnbindInput {
            index,
            service: RecordId::new("service", service.as_str()),
        })
        .collect::<Vec<_>>();
    let organization_id = RecordId::new("organization", org_id);
    let missing = transaction_query!(
        Vec<usize>,
        r#"
        BEGIN TRANSACTION;
        RETURN {
            LET $missing = $services.filter(|$item| array::is_empty(
                SELECT id FROM $item.service WHERE organization = $organization_id
            )).map(|$item| $item.index);
            IF !array::is_empty($missing) {
                RETURN $missing
            };
            FOR $item IN $services {
                UPDATE ONLY $item.service SET
                    organization = NONE,
                    registration = NONE;
            };
            RETURN [];
        };
        COMMIT TRANSACTION;
        "#,
    )
    .bind("services", inputs)
    .bind("organization_id", organization_id)
    .execute()
    .await
    .error_with_slug("service-unbind-query-failed")?
    .decode()
    .error_with_slug("service-unbind-result-parse-failed")?;
    let missing = wasmcloud_utils::skir_domain_result!(UnbindServicesResponse, missing);

    if !missing.is_empty() {
        otel_wasi::main_attribute!("service.outcome" = "not_found");
        let refusals = missing
            .into_iter()
            .map(|index| {
                let service_id = service_ids.get(index).cloned().ok_or_else(|| {
                    otel_wasi::Error::new(
                        "service-unbind-refusal-index-invalid",
                        format!("refusal names item {index} of {}", service_ids.len()),
                    )
                })?;
                Ok(refused(
                    service_id,
                    skir_variant!(ServiceUnbindRefusal::ServiceNotFoundError),
                ))
            })
            .collect::<Result<Vec<_>, otel_wasi::Error>>()?;
        return Ok(UnbindServicesResponse::RefusedError(refusals));
    }

    otel_wasi::main_attribute!("service.outcome" = "unbound");
    CommittedChange::new(
        skir_variant!(UnbindServicesResponse::Success),
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

fn duplicate() -> ServiceUnbindRefusal {
    skir_variant!(ServiceUnbindRefusal::DuplicateError)
}

fn refused(service_id: String, reason: ServiceUnbindRefusal) -> RefusedServiceUnbind {
    RefusedServiceUnbind {
        service_id,
        reason,
        _unrecognized: None,
    }
}
