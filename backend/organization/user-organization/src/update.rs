//! Renames organizations and changes their icons.
//!
//! A request is a batch of updates that applies all or nothing. Items that are malformed on their
//! face (record identifiers from another table, the same organization twice) refuse the batch
//! before the database is read. The transaction then checks every item first and writes only when
//! no item is refused, so a refused batch changes nothing and lists each refused item.
//!
//! Any member may update an organization; who may change what is a separate design. An
//! organization the caller is not a member of is refused as not found, so the reply does not say
//! whether it exists. Every member's organization list sequence advances once per batch and each
//! member receives one change listing every updated organization they belong to. The changes are
//! persisted only after commit, because a message cannot take part in the database rollback.

use otel_wasi::ResultWithSlug;
use serde::{Deserialize, Serialize};
use wasmcloud_utils::{
    database::{RecordId, TransactionOutcome, organization::OrganizationRecord, transaction_query},
    publication::{
        CapturedOnly, CommittedChange, MembershipFact, PublicationEffect, PublicationExecutor,
    },
    skir::base::{
        kernel::v1::errors::InvalidRecordIdError,
        organization::v1::organization::{
            Organization, OrganizationUpdate, OrganizationUpdateRefusal,
            OrganizationUpdateRefusal_DuplicateError,
            OrganizationUpdateRefusal_LogoUrlInvalidError,
            OrganizationUpdateRefusal_NameInvalidError, OrganizationUpdateRefusal_NameTakenError,
            OrganizationUpdateRefusal_OrganizationNotFoundError, RefusedOrganizationUpdate,
            UpdateOrganizationsRequest, UpdateOrganizationsResponse,
            UpdateOrganizationsResponse_Success, UserOrganizationsChange, UserOrganizationsChanged,
        },
    },
    skir_utils::{RecordIdKeyIdentity, RecordIdTableInput},
    skir_variant,
};

/// One update as the transaction reads it; `index` is its position in the request. An absent
/// field is left out so the transaction reads it as NONE and keeps the stored value.
#[derive(Debug, Serialize)]
struct UpdateInput {
    index: usize,
    organization: RecordId,
    #[serde(skip_serializing_if = "Option::is_none")]
    name: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    logo_url: Option<String>,
}

#[derive(Debug, Deserialize)]
#[serde(tag = "outcome", rename_all = "kebab-case")]
enum UpdateBatchOutcome {
    /// Every item was applied; `organizations` holds them in request order.
    Updated {
        organizations: Vec<OrganizationRecord>,
        members: Vec<UpdatedMember>,
    },
    /// Nothing was written.
    Refused { items: Vec<RefusedUpdateRecord> },
}

/// A member of at least one updated organization, with their advanced organization list sequence.
#[derive(Debug, Deserialize)]
struct UpdatedMember {
    user: RecordId,
    sequence: i64,
    organizations: Vec<RecordId>,
}

#[derive(Debug, Deserialize)]
struct RefusedUpdateRecord {
    index: usize,
    reason: UpdateRefusalReason,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "kebab-case")]
enum UpdateRefusalReason {
    OrganizationNotFound,
    NameInvalid,
    NameTaken,
    LogoUrlInvalid,
}

/// Applies every update the caller may make, or none.
///
/// Success returns the resulting organizations in request order with the caller's own
/// organization list change, and persists the matching change for every other member. A refusal
/// returns every refused item with its reason and publishes nothing. A publication failure occurs
/// after the durable change and is therefore not rolled back.
#[tracing::instrument(skip_all)]
pub async fn handle_update(
    scope: wasmcloud_utils::transport::UserScope,
    request: UpdateOrganizationsRequest,
) -> Result<UpdateOrganizationsResponse, otel_wasi::Error> {
    let user_key = scope.user.as_str();
    otel_wasi::main_attribute!(
        "user.id" = user_key.to_string(),
        "organization.batch_size" = request.updates.len() as i64,
    );
    let updates = request.updates;
    let malformed = malformed_updates(&updates);
    if !malformed.is_empty() {
        otel_wasi::main_attribute!("organization.outcome" = "malformed");
        return Ok(UpdateOrganizationsResponse::RefusedError(malformed));
    }

    let result = update_in_transaction(&updates, user_key).await?;
    let result = wasmcloud_utils::skir_domain_result!(UpdateOrganizationsResponse, result);
    let (organizations, members) = match result {
        UpdateBatchOutcome::Updated {
            organizations,
            members,
        } => (organizations, members),
        UpdateBatchOutcome::Refused { items } => {
            otel_wasi::main_attribute!("organization.outcome" = "refused");
            return Ok(UpdateOrganizationsResponse::RefusedError(
                items
                    .into_iter()
                    .map(|item| refused_update(&updates, item))
                    .collect::<Result<Vec<_>, _>>()?,
            ));
        }
    };
    otel_wasi::main_attribute!("organization.outcome" = "updated");

    let organizations = organizations
        .into_iter()
        .map(Organization::from)
        .collect::<Vec<_>>();
    let mut caller_event = None;
    let mut effects = Vec::with_capacity(members.len());
    for member in members {
        let user = member.user.key.raw_identity()?.to_owned();
        let event = UserOrganizationsChanged {
            sequence: member.sequence,
            changes: organizations
                .iter()
                .filter(|organization| {
                    member
                        .organizations
                        .iter()
                        .any(|id| RecordId::from(&organization.organization_id) == *id)
                })
                .cloned()
                .map(|organization| UserOrganizationsChange::Update(Box::new(organization)))
                .collect(),
            ..Default::default()
        };
        if user == user_key {
            caller_event = Some(event.clone());
        }
        effects.push(PublicationEffect::CapturedMembership(
            MembershipFact::UserOrganizations { user, event },
        ));
    }
    let event = caller_event.ok_or_else(|| {
        otel_wasi::Error::new(
            "organization-update-caller-missing",
            "the caller is not among the members of the updated organizations",
        )
    })?;
    CommittedChange::new(
        UpdateOrganizationsResponse::Success(Box::new(UpdateOrganizationsResponse_Success {
            organizations,
            event,
            _unrecognized: None,
        })),
        effects,
    )
    .publish_with(&PublicationExecutor {
        refresher: CapturedOnly,
    })
    .await
}

/// Checks every update against the stored organizations and writes them only when none is
/// refused, then advances each affected member's organization list sequence once.
async fn update_in_transaction(
    updates: &[OrganizationUpdate],
    user_key: &str,
) -> Result<TransactionOutcome<UpdateBatchOutcome>, otel_wasi::Error> {
    let inputs = updates
        .iter()
        .enumerate()
        .map(|(index, update)| UpdateInput {
            index,
            organization: RecordId::from(&update.organization_id),
            name: update.name.clone(),
            logo_url: update.logo_url.clone(),
        })
        .collect::<Vec<_>>();
    transaction_query!(
        UpdateBatchOutcome,
        r#"
        BEGIN TRANSACTION;

        RETURN {
            LET $checked = $updates.map(|$update| {
                LET $current = array::first(SELECT * FROM $update.organization);
                IF $current = NONE OR array::is_empty(
                    SELECT id FROM member_of WHERE in = $user AND out = $update.organization
                ) {
                    RETURN { index: $update.index, reason: 'organization-not-found' }
                };
                IF $update.name != NONE AND !fn::is_id($update.name) {
                    RETURN { index: $update.index, reason: 'name-invalid' }
                };
                IF $update.name != NONE AND (
                    !array::is_empty(
                        SELECT id FROM organization
                            WHERE name = $update.name AND id != $update.organization
                    )
                    OR !array::is_empty($updates.filter(|$earlier|
                        $earlier.index < $update.index AND $earlier.name = $update.name
                    ))
                ) {
                    RETURN { index: $update.index, reason: 'name-taken' }
                };
                IF $update.logo_url != NONE AND !fn::is_http_url($update.logo_url) {
                    RETURN { index: $update.index, reason: 'logo-url-invalid' }
                };
                RETURN {
                    index: $update.index,
                    organization: $update.organization,
                    name: $update.name ?? $current.name,
                    logo_url: $update.logo_url ?? $current.logo_url,
                };
            });

            LET $refused = $checked.filter(|$item| $item.reason != NONE);
            IF !array::is_empty($refused) {
                RETURN { outcome: 'refused', items: $refused }
            };

            FOR $item IN $checked {
                UPDATE ONLY $item.organization SET
                    name = $item.name,
                    logo_url = $item.logo_url;
            };

            LET $targets = $checked.map(|$item| $item.organization);
            LET $users = array::distinct(SELECT VALUE in FROM member_of WHERE out IN $targets);
            FOR $member IN $users {
                UPDATE ONLY $member SET organizations_sequence += 1;
            };

            RETURN {
                outcome: 'updated',
                organizations: $targets.map(|$organization| SELECT * FROM ONLY $organization),
                members: $users.map(|$member| {
                    user: $member,
                    sequence: (SELECT VALUE organizations_sequence FROM ONLY $member),
                    organizations: SELECT VALUE out FROM member_of
                        WHERE in = $member AND out IN $targets,
                }),
            };
        };

        COMMIT TRANSACTION;
        "#,
    )
    .bind("updates", inputs)
    .bind("user", RecordId::new("user", user_key))
    .execute()
    .await
    .error_with_slug("organization-update-query-failed")?
    .decode()
    .error_with_slug("organization-update-result-parse-failed")
}

/// Items refused before the database is read: record identifiers from another table and
/// organizations named more than once.
fn malformed_updates(updates: &[OrganizationUpdate]) -> Vec<RefusedOrganizationUpdate> {
    updates
        .iter()
        .enumerate()
        .filter_map(|(index, update)| {
            let given_tables = update.organization_id.invalid_tables("organization");
            let reason = if !given_tables.is_empty() {
                OrganizationUpdateRefusal::InvalidRecordIdError(Box::new(InvalidRecordIdError {
                    expected_table: "organization".to_owned(),
                    given_tables,
                    _unrecognized: None,
                }))
            } else if updates[..index]
                .iter()
                .any(|earlier| earlier.organization_id == update.organization_id)
            {
                skir_variant!(OrganizationUpdateRefusal::DuplicateError)
            } else {
                return None;
            };
            Some(RefusedOrganizationUpdate {
                organization_id: update.organization_id.clone(),
                reason,
                _unrecognized: None,
            })
        })
        .collect()
}

fn refused_update(
    updates: &[OrganizationUpdate],
    item: RefusedUpdateRecord,
) -> Result<RefusedOrganizationUpdate, otel_wasi::Error> {
    let update = updates.get(item.index).ok_or_else(|| {
        otel_wasi::Error::new(
            "organization-update-refusal-index-invalid",
            format!("refusal names item {} of {}", item.index, updates.len()),
        )
    })?;
    let reason = match item.reason {
        UpdateRefusalReason::OrganizationNotFound => {
            skir_variant!(OrganizationUpdateRefusal::OrganizationNotFoundError)
        }
        UpdateRefusalReason::NameInvalid => {
            skir_variant!(OrganizationUpdateRefusal::NameInvalidError)
        }
        UpdateRefusalReason::NameTaken => {
            skir_variant!(OrganizationUpdateRefusal::NameTakenError)
        }
        UpdateRefusalReason::LogoUrlInvalid => {
            skir_variant!(OrganizationUpdateRefusal::LogoUrlInvalidError)
        }
    };
    Ok(RefusedOrganizationUpdate {
        organization_id: update.organization_id.clone(),
        reason,
        _unrecognized: None,
    })
}
