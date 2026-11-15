//! Deletes organizations.
//!
//! A request is a batch of deletions that applies all or nothing. Items that are malformed on
//! their face (record identifiers from another table, the same organization twice) refuse the
//! batch before the database is read. The transaction then checks every item first and deletes
//! only when no item is refused.
//!
//! Only the founder recorded on the organization may delete it. An organization the caller is not
//! a member of is refused as not found, so the reply does not say whether it exists. The schema
//! decides what goes with an organization: its memberships and pending join requests, which are
//! edges on it, and its join codes and roles, which cascade. Its services stay and are unbound,
//! together with their hosts and realms, which reference the service and not the organization.
//!
//! Every former member receives the removal on their organization list, and every person with a
//! pending request receives the removal of that request on their join request list. Those
//! changes are persisted only after commit, because a message cannot take part in the database
//! rollback.

use otel_wasi::ResultWithSlug;
use serde::{Deserialize, Serialize};
use wasmcloud_utils::{
    database::{RecordId, TransactionOutcome, transaction_query},
    publication::{
        CapturedOnly, CommittedChange, MembershipFact, PublicationEffect, PublicationExecutor,
    },
    skir::base::{
        kernel::v1::errors::InvalidRecordIdError,
        kernel::v1::record_id::RecordId as SkirRecordId,
        organization::v1::{
            join_request::{UserJoinRequestsChange, UserJoinRequestsChanged},
            organization::{
                DeleteOrganizationsRequest, DeleteOrganizationsResponse,
                DeleteOrganizationsResponse_Success, OrganizationDeleteRefusal,
                OrganizationDeleteRefusal_DuplicateError,
                OrganizationDeleteRefusal_FounderRequiredError,
                OrganizationDeleteRefusal_OrganizationNotFoundError, RefusedOrganizationDelete,
                UserOrganizationsChange, UserOrganizationsChanged,
            },
        },
    },
    skir_utils::{RecordIdKeyIdentity, RecordIdTableInput},
    skir_variant,
};

/// One deletion as the transaction reads it; `index` is its position in the request.
#[derive(Debug, Serialize)]
struct DeleteInput {
    index: usize,
    organization: RecordId,
}

#[derive(Debug, Deserialize)]
#[serde(tag = "outcome", rename_all = "kebab-case")]
enum DeleteBatchOutcome {
    /// Every organization was deleted.
    Deleted {
        members: Vec<FormerMember>,
        applicants: Vec<FormerApplicant>,
    },
    /// Nothing was deleted.
    Refused { items: Vec<RefusedDeleteRecord> },
}

/// A member of at least one deleted organization, with their advanced organization list sequence.
#[derive(Debug, Deserialize)]
struct FormerMember {
    user: RecordId,
    sequence: i64,
    organizations: Vec<RecordId>,
}

/// A person whose pending requests went with a deleted organization, with their advanced join
/// request list sequence.
#[derive(Debug, Deserialize)]
struct FormerApplicant {
    user: RecordId,
    sequence: i64,
    requests: Vec<RecordId>,
}

#[derive(Debug, Deserialize)]
struct RefusedDeleteRecord {
    index: usize,
    reason: DeleteRefusalReason,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "kebab-case")]
enum DeleteRefusalReason {
    OrganizationNotFound,
    FounderRequired,
}

/// Deletes every requested organization the caller founded, or none.
///
/// Success returns the caller's own organization list change and persists the matching changes
/// for every other former member and applicant. A refusal returns every refused item with its
/// reason and publishes nothing. A publication failure occurs after the durable deletion and is
/// therefore not rolled back.
#[tracing::instrument(skip_all)]
pub async fn handle_delete(
    scope: wasmcloud_utils::transport::UserScope,
    request: DeleteOrganizationsRequest,
) -> Result<DeleteOrganizationsResponse, otel_wasi::Error> {
    let user_key = scope.user.as_str();
    otel_wasi::main_attribute!(
        "user.id" = user_key.to_string(),
        "organization.batch_size" = request.organization_ids.len() as i64,
    );
    let organization_ids = request.organization_ids;
    let malformed = malformed_deletions(&organization_ids);
    if !malformed.is_empty() {
        otel_wasi::main_attribute!("organization.outcome" = "malformed");
        return Ok(DeleteOrganizationsResponse::RefusedError(malformed));
    }

    let result = delete_in_transaction(&organization_ids, user_key).await?;
    let result = wasmcloud_utils::skir_domain_result!(DeleteOrganizationsResponse, result);
    let (members, applicants) = match result {
        DeleteBatchOutcome::Deleted {
            members,
            applicants,
        } => (members, applicants),
        DeleteBatchOutcome::Refused { items } => {
            otel_wasi::main_attribute!("organization.outcome" = "refused");
            return Ok(DeleteOrganizationsResponse::RefusedError(
                items
                    .into_iter()
                    .map(|item| refused_deletion(&organization_ids, item))
                    .collect::<Result<Vec<_>, _>>()?,
            ));
        }
    };
    otel_wasi::main_attribute!("organization.outcome" = "deleted");

    let mut caller_event = None;
    let mut effects = Vec::with_capacity(members.len() + applicants.len());
    for member in members {
        let user = member.user.key.raw_identity()?.to_owned();
        let event = UserOrganizationsChanged {
            sequence: member.sequence,
            changes: member
                .organizations
                .into_iter()
                .map(|organization| {
                    UserOrganizationsChange::Remove(Box::new(SkirRecordId::from(organization)))
                })
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
    for applicant in applicants {
        effects.push(PublicationEffect::CapturedMembership(
            MembershipFact::UserJoinRequests {
                user: applicant.user.key.raw_identity()?.to_owned(),
                event: UserJoinRequestsChanged {
                    sequence: applicant.sequence,
                    changes: applicant
                        .requests
                        .into_iter()
                        .map(|request| {
                            UserJoinRequestsChange::Remove(Box::new(SkirRecordId::from(request)))
                        })
                        .collect(),
                    ..Default::default()
                },
            },
        ));
    }
    let event = caller_event.ok_or_else(|| {
        otel_wasi::Error::new(
            "organization-delete-caller-missing",
            "the caller is not among the members of the deleted organizations",
        )
    })?;
    CommittedChange::new(
        DeleteOrganizationsResponse::Success(Box::new(DeleteOrganizationsResponse_Success {
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

/// Checks every deletion and deletes only when none is refused, advancing each former member's
/// organization list sequence and each applicant's join request list sequence once.
async fn delete_in_transaction(
    organization_ids: &[SkirRecordId],
    user_key: &str,
) -> Result<TransactionOutcome<DeleteBatchOutcome>, otel_wasi::Error> {
    let inputs = organization_ids
        .iter()
        .enumerate()
        .map(|(index, organization)| DeleteInput {
            index,
            organization: RecordId::from(organization),
        })
        .collect::<Vec<_>>();
    transaction_query!(
        DeleteBatchOutcome,
        r#"
        BEGIN TRANSACTION;

        RETURN {
            LET $refused = $deletions.map(|$deletion| {
                LET $current = array::first(SELECT id, founder FROM $deletion.organization);
                IF $current = NONE OR array::is_empty(
                    SELECT id FROM member_of WHERE in = $user AND out = $deletion.organization
                ) {
                    RETURN { index: $deletion.index, reason: 'organization-not-found' }
                };
                IF $current.founder != $user {
                    RETURN { index: $deletion.index, reason: 'founder-required' }
                };
                RETURN NONE;
            }).filter(|$item| $item != NONE);
            IF !array::is_empty($refused) {
                RETURN { outcome: 'refused', items: $refused }
            };

            LET $targets = $deletions.map(|$deletion| $deletion.organization);
            LET $memberships = SELECT in AS user, out AS organization FROM member_of
                WHERE out IN $targets;
            LET $requests = SELECT id, in AS user FROM request_to_join WHERE out IN $targets;
            LET $members = array::distinct($memberships.user);
            LET $applicants = array::distinct($requests.user);

            FOR $organization IN $targets {
                DELETE $organization;
            };
            FOR $member IN $members {
                UPDATE ONLY $member SET organizations_sequence += 1;
            };
            FOR $applicant IN $applicants {
                UPDATE ONLY $applicant SET join_requests_sequence += 1;
            };

            RETURN {
                outcome: 'deleted',
                members: $members.map(|$member| {
                    user: $member,
                    sequence: (SELECT VALUE organizations_sequence FROM ONLY $member),
                    organizations: $memberships
                        .filter(|$membership| $membership.user = $member)
                        .map(|$membership| $membership.organization),
                }),
                applicants: $applicants.map(|$applicant| {
                    user: $applicant,
                    sequence: (SELECT VALUE join_requests_sequence FROM ONLY $applicant),
                    requests: $requests
                        .filter(|$request| $request.user = $applicant)
                        .map(|$request| $request.id),
                }),
            };
        };

        COMMIT TRANSACTION;
        "#,
    )
    .bind("deletions", inputs)
    .bind("user", RecordId::new("user", user_key))
    .execute()
    .await
    .error_with_slug("organization-delete-query-failed")?
    .decode()
    .error_with_slug("organization-delete-result-parse-failed")
}

/// Items refused before the database is read: record identifiers from another table and
/// organizations named more than once.
fn malformed_deletions(organization_ids: &[SkirRecordId]) -> Vec<RefusedOrganizationDelete> {
    organization_ids
        .iter()
        .enumerate()
        .filter_map(|(index, organization_id)| {
            let given_tables = organization_id.invalid_tables("organization");
            let reason = if !given_tables.is_empty() {
                OrganizationDeleteRefusal::InvalidRecordIdError(Box::new(InvalidRecordIdError {
                    expected_table: "organization".to_owned(),
                    given_tables,
                    _unrecognized: None,
                }))
            } else if organization_ids[..index].contains(organization_id) {
                skir_variant!(OrganizationDeleteRefusal::DuplicateError)
            } else {
                return None;
            };
            Some(RefusedOrganizationDelete {
                organization_id: organization_id.clone(),
                reason,
                _unrecognized: None,
            })
        })
        .collect()
}

fn refused_deletion(
    organization_ids: &[SkirRecordId],
    item: RefusedDeleteRecord,
) -> Result<RefusedOrganizationDelete, otel_wasi::Error> {
    let organization_id = organization_ids.get(item.index).ok_or_else(|| {
        otel_wasi::Error::new(
            "organization-delete-refusal-index-invalid",
            format!(
                "refusal names item {} of {}",
                item.index,
                organization_ids.len()
            ),
        )
    })?;
    let reason = match item.reason {
        DeleteRefusalReason::OrganizationNotFound => {
            skir_variant!(OrganizationDeleteRefusal::OrganizationNotFoundError)
        }
        DeleteRefusalReason::FounderRequired => {
            skir_variant!(OrganizationDeleteRefusal::FounderRequiredError)
        }
    };
    Ok(RefusedOrganizationDelete {
        organization_id: organization_id.clone(),
        reason,
        _unrecognized: None,
    })
}
