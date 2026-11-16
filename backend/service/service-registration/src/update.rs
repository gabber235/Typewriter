//! Applies organization owned service metadata changes.
//!
//! Metadata update is separate from registration binding because it operates on already bound
//! services, uses organization authorization, and has compare and set revision semantics. Binding
//! changes ownership and visibility. Update changes the service projection while preserving that
//! ownership. Unbinding removes ownership and clears the lease.
//!
//! A request is a batch of renames that applies all or nothing. Items that are malformed on
//! their face (record identifiers from another table, the same service twice) refuse the batch
//! before the database is read. The database transaction then checks every item against the
//! stored services first and writes only when no item is refused, so a refused batch changes
//! nothing and lists each refused item. A stale item whose name is already stored, as when a
//! resend follows a send that landed, counts as accepted without writing and is published
//! again, so a resend delivers a change whose first publish failed. The watch updates are
//! published only after commit, because a message cannot participate in the database rollback
//! boundary.

use otel_wasi::ResultWithSlug;
use serde::{Deserialize, Serialize};
use wasmcloud_utils::{
    database::{RecordId, TransactionOutcome, service::ServiceRecord, transaction_query},
    publication::{CommittedChange, PublicationEffect, PublicationExecutor, TransientFact},
    skir::base::{
        kernel::v1::errors::InvalidRecordIdError,
        service::v1::{
            organization::{
                OrganizationServicesChanged, RefusedServiceRename, ServiceRename,
                ServiceRenameRefusal, ServiceRenameRefusal_ConflictError,
                ServiceRenameRefusal_DuplicateError, ServiceRenameRefusal_ServiceNotFoundError,
                ServiceUpdateValidationError, UpdateOrganizationServicesRequest,
                UpdateOrganizationServicesResponse,
            },
            service::Service,
        },
    },
    skir_utils::RecordIdTableInput,
    skir_variant,
};

/// One rename as the transaction reads it; `index` is its position in the request.
#[derive(Debug, Serialize)]
struct RenameInput {
    index: usize,
    service: RecordId,
    expected_revision: i64,
    name: String,
}

#[derive(Debug, Deserialize)]
#[serde(tag = "outcome", rename_all = "kebab-case")]
enum RenameBatchOutcome {
    /// Every item was accepted; `services` holds the stored services in request order.
    Updated { services: Vec<ServiceRecord> },
    /// Nothing was written.
    Refused { items: Vec<RefusedRenameRecord> },
}

#[derive(Debug, Deserialize)]
#[serde(tag = "outcome", rename_all = "kebab-case")]
enum RefusedRenameRecord {
    ConflictError {
        index: usize,
        actual: Box<ServiceRecord>,
    },
    ServiceNotFoundError {
        index: usize,
    },
    NameInvalid {
        index: usize,
    },
}

/// Renames services owned by the addressed organization as one all or nothing batch.
///
/// Each item's expected revision makes concurrent edits explicit. Success returns every
/// resulting service in request order and publishes each one; a refusal returns every refused
/// item with its reason, a conflict carrying the current service so the caller can reconcile,
/// and publishes nothing. A publication failure occurs after durable mutation and is therefore
/// not rolled back.
#[tracing::instrument(skip(request))]
pub async fn handle_update(
    scope: wasmcloud_utils::transport::OrganizationActorScope,
    request: UpdateOrganizationServicesRequest,
) -> Result<UpdateOrganizationServicesResponse, otel_wasi::Error> {
    let actor_id = scope.user.as_str();
    let org_id = scope.organization.as_str();
    otel_wasi::main_attribute!(
        "actor.id" = actor_id.to_string(),
        "organization.id" = org_id.to_string(),
        "service.batch_size" = request.renames.len() as i64,
    );

    let renames = request.renames;
    let malformed = malformed_renames(&renames);
    if !malformed.is_empty() {
        otel_wasi::main_attribute!("service.outcome" = "malformed");
        return Ok(UpdateOrganizationServicesResponse::RefusedError(malformed));
    }

    let result = rename_in_transaction(&renames, org_id).await?;
    let result = wasmcloud_utils::skir_domain_result!(UpdateOrganizationServicesResponse, result);
    let services = match result {
        RenameBatchOutcome::Updated { services } => services
            .into_iter()
            .map(Service::try_from)
            .collect::<Result<Vec<_>, _>>()?,
        RenameBatchOutcome::Refused { items } => {
            otel_wasi::main_attribute!("service.outcome" = "refused");
            return Ok(UpdateOrganizationServicesResponse::RefusedError(
                items
                    .into_iter()
                    .map(|item| refused_rename(&renames, item))
                    .collect::<Result<Vec<_>, _>>()?,
            ));
        }
    };
    otel_wasi::main_attribute!("service.outcome" = "updated");

    let effects = services
        .iter()
        .map(|service| {
            PublicationEffect::CapturedTransient(TransientFact::Services {
                organization: org_id.to_owned(),
                event: OrganizationServicesChanged::Update(Box::new(service.clone())),
            })
        })
        .collect::<Vec<_>>();
    CommittedChange::new(
        UpdateOrganizationServicesResponse::Success(services),
        effects,
    )
    .publish_with(&PublicationExecutor {
        refresher: wasmcloud_utils::publication::CapturedOnly,
    })
    .await
}

/// Checks every rename against the stored services and writes them only when none is refused.
async fn rename_in_transaction(
    renames: &[ServiceRename],
    org_id: &str,
) -> Result<TransactionOutcome<RenameBatchOutcome>, otel_wasi::Error> {
    let inputs = renames
        .iter()
        .enumerate()
        .map(|(index, rename)| RenameInput {
            index,
            service: RecordId::from(&rename.service_id),
            expected_revision: rename.expected_revision,
            name: rename.name.clone(),
        })
        .collect::<Vec<_>>();
    let organization_id = RecordId::new("organization", org_id);
    transaction_query!(
        RenameBatchOutcome,
        r#"
        BEGIN TRANSACTION;

        RETURN {
            LET $checked = $renames.map(|$rename| {
                LET $current = array::first(
                    SELECT * FROM $rename.service WHERE organization = $organization_id
                );
                IF $current = NONE {
                    RETURN { outcome: 'service-not-found-error', index: $rename.index }
                };
                IF $current.revision != $rename.expected_revision {
                    -- A rename to the stored name, as when its first send landed, is
                    -- accepted with the stored service and changes nothing.
                    IF $current.name = $rename.name {
                        RETURN { outcome: 'unchanged', index: $rename.index, service: $current }
                    };
                    RETURN { outcome: 'conflict-error', index: $rename.index, actual: $current }
                };
                IF !fn::is_id($rename.name) {
                    RETURN { outcome: 'name-invalid', index: $rename.index }
                };
                RETURN {
                    outcome: 'accepted',
                    index: $rename.index,
                    service: $current,
                    name: $rename.name,
                };
            });

            LET $refused = $checked.filter(|$item| $item.outcome NOT IN ['accepted', 'unchanged']);
            IF !array::is_empty($refused) {
                RETURN { outcome: 'refused', items: $refused }
            };

            FOR $item IN $checked {
                IF $item.outcome = 'accepted' {
                    UPDATE ONLY $item.service.id SET
                        name = $item.name,
                        revision = $item.service.revision + 1;
                };
            };

            LET $result = {
                outcome: 'updated',
                services: $checked.map(|$item| SELECT * FROM ONLY $item.service.id),
            };
            RETURN $result;
        };

        COMMIT TRANSACTION;
        "#,
    )
    .bind("renames", inputs)
    .bind("organization_id", organization_id)
    .execute()
    .await
    .error_with_slug("service-update-query-failed")?
    .decode()
    .error_with_slug("service-update-result-parse-failed")
}

/// Items refused before the database is read: record identifiers from another table and
/// services named more than once.
fn malformed_renames(renames: &[ServiceRename]) -> Vec<RefusedServiceRename> {
    let targets = renames
        .iter()
        .map(|rename| &rename.service_id)
        .collect::<Vec<_>>();
    renames
        .iter()
        .enumerate()
        .filter_map(|(index, rename)| {
            let given_tables = rename.service_id.invalid_tables("service");
            let reason = if !given_tables.is_empty() {
                ServiceRenameRefusal::InvalidRecordIdError(Box::new(InvalidRecordIdError {
                    expected_table: "service".to_owned(),
                    given_tables,
                    _unrecognized: None,
                }))
            } else if crate::utils::repeats_earlier(&targets, index) {
                skir_variant!(ServiceRenameRefusal::DuplicateError)
            } else {
                return None;
            };
            Some(RefusedServiceRename {
                service_id: rename.service_id.clone(),
                reason,
                _unrecognized: None,
            })
        })
        .collect()
}

fn refused_rename(
    renames: &[ServiceRename],
    item: RefusedRenameRecord,
) -> Result<RefusedServiceRename, otel_wasi::Error> {
    let index = match &item {
        RefusedRenameRecord::ConflictError { index, .. }
        | RefusedRenameRecord::ServiceNotFoundError { index }
        | RefusedRenameRecord::NameInvalid { index } => *index,
    };
    let rename = renames.get(index).ok_or_else(|| {
        otel_wasi::Error::new(
            "service-update-refusal-index-invalid",
            format!("refusal names item {index} of {}", renames.len()),
        )
    })?;
    let reason = match item {
        RefusedRenameRecord::ConflictError { actual, .. } => {
            skir_variant!(ServiceRenameRefusal::ConflictError {
                expected_revision: rename.expected_revision,
                actual: Service::try_from(*actual)?,
            })
        }
        RefusedRenameRecord::ServiceNotFoundError { .. } => {
            skir_variant!(ServiceRenameRefusal::ServiceNotFoundError)
        }
        RefusedRenameRecord::NameInvalid { .. } => ServiceRenameRefusal::ValidationError(Box::new(
            ServiceUpdateValidationError::NameInvalid,
        )),
    };
    Ok(RefusedServiceRename {
        service_id: rename.service_id.clone(),
        reason,
        _unrecognized: None,
    })
}
