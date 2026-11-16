//! Organization membership reads and mutations.
//!
//! Membership state is owned by the organization database projection. Role updates replace each
//! selected member's assignable roles with that member's own selection while preserving protected
//! roles. Removal
//! of a selection enforces the founder invariant. Successful mutations increment the organization member
//! sequence and publish the affected organization and user facts after the database transaction
//! succeeds.

use otel_wasi::ResultWithSlug;
use serde::{Deserialize, Serialize};
use wasmcloud_utils::database::organization::projections::OrganizationMemberProjection;
use wasmcloud_utils::{
    database::{RecordId, transaction_query},
    publication::{
        CapturedOnly, CommittedChange, MembershipFact, PublicationEffect, PublicationExecutor,
    },
    skir::base::organization::v1::member::*,
    skir::base::organization::v1::organization::{
        UserOrganizationsChange, UserOrganizationsChanged,
    },
    skir_transaction_outcome,
    skir_utils::{IntoSkirRecordIds, IntoSurrealRecordIds, RecordIdKeyIdentity},
    skir_variant,
};

/// One removed member and the sequence of their organization list after the removal.
#[derive(Debug, Deserialize)]
struct RemovedMemberRecord {
    user: RecordId,
    organizations_sequence: i64,
}

#[derive(Debug, Deserialize)]
#[serde(tag = "outcome", rename_all = "kebab-case")]
enum MemberRemovalOutcome {
    Removed {
        removed: Vec<RemovedMemberRecord>,
        members_sequence: i64,
    },
    UserNotMemberError {
        user_ids: Vec<RecordId>,
    },
    FounderCannotBeRemovedError {
        user_ids: Vec<RecordId>,
    },
    InvalidSelectionError,
}

impl MemberRemovalOutcome {
    fn as_str(&self) -> &'static str {
        match self {
            Self::Removed { .. } => "removed",
            Self::UserNotMemberError { .. } => "user-not-member-error",
            Self::FounderCannotBeRemovedError { .. } => "founder-cannot-be-removed-error",
            Self::InvalidSelectionError => "invalid-selection-error",
        }
    }
}

/// The response and publications of a committed removal: one organization member change removing
/// every member, and one organization list change for each removed user.
fn removal_change(
    organization: RecordId,
    removed: Vec<RemovedMemberRecord>,
    members_sequence: i64,
) -> Result<CommittedChange<RemoveOrganizationMembersResponse>, otel_wasi::Error> {
    let member_event = OrganizationMembersChanged {
        sequence: members_sequence,
        changes: removed
            .iter()
            .map(|member| OrganizationMembersChange::Remove(Box::new(member.user.clone().into())))
            .collect(),
        ..Default::default()
    };
    let mut effects = vec![PublicationEffect::CapturedMembership(
        MembershipFact::Members {
            organization: organization.key.raw_identity()?.to_owned(),
            event: member_event.clone(),
        },
    )];
    for member in removed {
        effects.push(PublicationEffect::CapturedMembership(
            MembershipFact::UserOrganizations {
                user: member.user.key.raw_identity()?.to_owned(),
                event: UserOrganizationsChanged {
                    sequence: member.organizations_sequence,
                    changes: vec![UserOrganizationsChange::Remove(Box::new(
                        organization.clone().into(),
                    ))],
                    ..Default::default()
                },
            },
        ));
    }
    Ok(CommittedChange::new(
        skir_variant!(RemoveOrganizationMembersResponse::Success {
            event: member_event,
        }),
        effects,
    ))
}

/// One member's requested assignable roles, as the database function reads it.
#[derive(Debug, Serialize)]
struct RoleAssignmentRecord {
    user: RecordId,
    roles: Vec<RecordId>,
}

#[derive(Debug, Deserialize)]
#[serde(tag = "outcome", rename_all = "kebab-case")]
enum MemberUpdateOutcome {
    Updated {
        members: Vec<OrganizationMemberProjection>,
        sequence: i64,
    },
    UserNotFoundError {
        user_ids: Vec<RecordId>,
    },
    RolesNotFoundError {
        role_ids: Vec<RecordId>,
    },
    RolesNotAssignableError {
        user_ids: Vec<RecordId>,
        role_ids: Vec<RecordId>,
    },
    RolesRequiredError {
        user_ids: Vec<RecordId>,
    },
    InvalidSelectionError,
    FounderRoleRequiredError,
}

impl MemberUpdateOutcome {
    fn as_str(&self) -> &'static str {
        match self {
            Self::Updated { .. } => "updated",
            Self::UserNotFoundError { .. } => "user-not-found-error",
            Self::RolesNotFoundError { .. } => "roles-not-found-error",
            Self::RolesNotAssignableError { .. } => "roles-not-assignable-error",
            Self::RolesRequiredError { .. } => "roles-required-error",
            Self::InvalidSelectionError => "invalid-selection-error",
            Self::FounderRoleRequiredError => "founder-role-required-error",
        }
    }
}

/// Returns the current organization membership snapshot.
///
/// The snapshot sequence is read with the member values, so a consumer can use it as its recovery
/// point for the organization member change stream. The request body is decoded to reject malformed
/// watch requests before the database read.
#[tracing::instrument(skip_all)]
pub async fn handle_watch(
    scope: wasmcloud_utils::transport::OrganizationActorScope,
    _request: WatchOrganizationMembersRequest,
) -> Result<WatchOrganizationMembersResponse, otel_wasi::Error> {
    let actor_id = scope.user.as_str();
    let org_id = scope.organization.as_str();
    otel_wasi::main_attribute!(
        "actor.id" = actor_id.to_string(),
        "organization.id" = org_id.to_string()
    );
    wasmcloud_utils::database::organization::snapshots::members(RecordId::new(
        "organization",
        org_id,
    ))
    .await
}

/// Applies each requested member's own role selection as one database transaction.
///
/// The database function rejects an empty or duplicated selection, unknown users or roles,
/// protected roles, roleless results, and a result that would leave the organization without a
/// founder.
/// The returned event describes the full updated member values and is published after commit.
#[tracing::instrument(skip_all)]
pub async fn handle_update(
    scope: wasmcloud_utils::transport::OrganizationActorScope,
    request: UpdateOrganizationMemberRolesRequest,
) -> Result<UpdateOrganizationMemberRolesResponse, otel_wasi::Error> {
    let actor_id = scope.user.as_str();
    let org_id = scope.organization.as_str();
    for assignment in &request.assignments {
        wasmcloud_utils::validate_record_ids!(
            UpdateOrganizationMemberRolesResponse,
            assignment.user_id,
            "user"
        );
        wasmcloud_utils::validate_record_ids!(
            UpdateOrganizationMemberRolesResponse,
            assignment.role_ids,
            "organization_role"
        );
    }
    otel_wasi::main_attribute!(
        "actor.id" = actor_id.to_string(),
        "organization.id" = org_id.to_string(),
        "member.result_count" = request.assignments.len() as i64
    );
    let organization_id = RecordId::new("organization", org_id);
    let assignments: Vec<RoleAssignmentRecord> = request
        .assignments
        .iter()
        .map(|assignment| RoleAssignmentRecord {
            user: RecordId::from(&assignment.user_id),
            roles: assignment.role_ids.as_slice().into_surreal_record_ids(),
        })
        .collect();

    let result = transaction_query!(
        MemberUpdateOutcome,
        r#"
        BEGIN TRANSACTION;

        RETURN fn::organization::members::update_roles($org, $assignments);

        COMMIT TRANSACTION;
        "#,
    )
    .bind("org", organization_id)
    .bind("assignments", assignments)
    .execute()
    .await
    .error_with_slug("member-update-query-failed")?
    .decode()
    .error_with_slug("member-update-result-parse-failed")?;

    let result =
        wasmcloud_utils::skir_domain_result!(UpdateOrganizationMemberRolesResponse, result);
    otel_wasi::main_attribute!("member.outcome" = result.as_str());
    let members = skir_transaction_outcome!(
        UpdateOrganizationMemberRolesResponse,
        result,
        success MemberUpdateOutcome::Updated { members, sequence } => (members, sequence),
        errors {
            MemberUpdateOutcome::UserNotFoundError { user_ids } => {
                user_ids: user_ids.into_skir_record_ids()
            },
            MemberUpdateOutcome::RolesNotFoundError { role_ids } => {
                role_ids: role_ids.into_skir_record_ids()
            },
            MemberUpdateOutcome::RolesNotAssignableError { user_ids, role_ids } => {
                user_ids: user_ids.into_skir_record_ids(),
                role_ids: role_ids.into_skir_record_ids()
            },
            MemberUpdateOutcome::RolesRequiredError { user_ids } => { user_ids: user_ids.into_skir_record_ids() },
            MemberUpdateOutcome::InvalidSelectionError => {},
            MemberUpdateOutcome::FounderRoleRequiredError => {},
        }
    );

    let (members, sequence) = members;
    let members: Vec<OrganizationMember> = members.into_iter().map(Into::into).collect();
    let event = OrganizationMembersChanged {
        sequence,
        changes: members
            .iter()
            .cloned()
            .map(|member| OrganizationMembersChange::Update(Box::new(member)))
            .collect(),
        ..Default::default()
    };
    otel_wasi::main_attribute!("member.outcome" = "updated");
    CommittedChange::new(
        skir_variant!(UpdateOrganizationMemberRolesResponse::Success {
            members,
            event: event.clone(),
        }),
        [PublicationEffect::CapturedMembership(
            MembershipFact::Members {
                organization: org_id.to_owned(),
                event,
            },
        )],
    )
    .publish_with(&PublicationExecutor {
        refresher: CapturedOnly,
    })
    .await
}

/// Removes every selected member in one transaction when doing so preserves the founder invariant.
///
/// The transaction rejects the complete selection when it is empty or repeats a user, when a user
/// is not a member, or when it holds the original founder or every remaining founder role holder.
/// A successful removal advances the organization member sequence once and each removed user's
/// organization sequence, then publishes every change.
#[tracing::instrument(skip_all)]
pub async fn handle_remove(
    scope: wasmcloud_utils::transport::OrganizationActorScope,
    request: RemoveOrganizationMembersRequest,
) -> Result<RemoveOrganizationMembersResponse, otel_wasi::Error> {
    let actor_id = scope.user.as_str();
    let org_id = scope.organization.as_str();
    wasmcloud_utils::validate_record_ids!(
        RemoveOrganizationMembersResponse,
        request.user_ids,
        "user"
    );
    otel_wasi::main_attribute!(
        "actor.id" = actor_id.to_string(),
        "organization.id" = org_id.to_string(),
        "member.result_count" = request.user_ids.len() as i64
    );
    let user_ids = request.user_ids.as_slice().into_surreal_record_ids();
    let organization_id = RecordId::new("organization", org_id);

    let result = transaction_query!(
        MemberRemovalOutcome,
        r#"
        BEGIN TRANSACTION;
        RETURN {
            IF array::is_empty($users) OR array::len(array::distinct($users)) != array::len($users) {
                RETURN { outcome: 'invalid-selection-error' }
            };

            LET $members = SELECT * FROM member_of WHERE in IN $users AND out = $org;
            LET $missing = array::complement($users, $members.in);
            IF array::len($missing) > 0 {
                RETURN { outcome: 'user-not-member-error', user_ids: $missing }
            };

            IF $org.founder IN $users {
                RETURN { outcome: 'founder-cannot-be-removed-error', user_ids: [$org.founder] }
            };

            LET $founders = $members.filter(|$member| fn::organization::roles::has_named_role($member.roles, 'founder'));
            LET $other_founders = SELECT VALUE id FROM member_of
                WHERE out = $org
                    AND in NOT IN $users
                    AND fn::organization::roles::has_named_role(roles, 'founder');
            IF array::len($founders) > 0 AND array::is_empty($other_founders) {
                RETURN { outcome: 'founder-cannot-be-removed-error', user_ids: $founders.in }
            };

            FOR $member IN $members {
                DELETE $member.id;
                UPDATE ONLY $member.in SET organizations_sequence += 1;
            };

            LET $members_sequence = UPDATE ONLY $org SET members_sequence += 1
                RETURN VALUE members_sequence;

            RETURN {
                outcome: 'removed',
                removed: (SELECT id AS user, organizations_sequence FROM $users),
                members_sequence: $members_sequence
            };
        };
        COMMIT TRANSACTION;
        "#,
    )
    .bind("users", user_ids)
    .bind("org", organization_id.clone())
    .execute()
    .await
    .error_with_slug("member-remove-query-failed")?
    .decode()
    .error_with_slug("member-remove-result-parse-failed")?;

    let result = wasmcloud_utils::skir_domain_result!(RemoveOrganizationMembersResponse, result);
    otel_wasi::main_attribute!("member.outcome" = result.as_str());
    let (removed, members_sequence) = skir_transaction_outcome!(
        RemoveOrganizationMembersResponse,
        result,
        success MemberRemovalOutcome::Removed { removed, members_sequence } => (removed, members_sequence),
        errors {
            MemberRemovalOutcome::UserNotMemberError { user_ids } => {
                user_ids: user_ids.into_skir_record_ids()
            },
            MemberRemovalOutcome::FounderCannotBeRemovedError { user_ids } => {
                user_ids: user_ids.into_skir_record_ids()
            },
            MemberRemovalOutcome::InvalidSelectionError => {},
        }
    );

    removal_change(organization_id, removed, members_sequence)?
        .publish_with(&PublicationExecutor {
            refresher: CapturedOnly,
        })
        .await
}
