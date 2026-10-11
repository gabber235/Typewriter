//! Organization membership reads and mutations.
//!
//! Membership state is owned by the organization database projection. Role updates replace the
//! assignable role selection for every selected member while preserving protected roles. Removal
//! enforces the founder invariant. Successful mutations increment the organization member
//! sequence and publish the affected organization and user facts after the database transaction
//! succeeds.

use otel_wasi::ResultWithSlug;
use serde::Deserialize;
use wasmcloud_utils::database::organization::projections::OrganizationMemberProjection;
use wasmcloud_utils::{
    database::{RecordId, TransactionOutcome, transaction_query},
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
    wasmcloud::messaging::types::NatsMessage,
};

#[derive(Debug, Deserialize)]
struct RemovedMemberRecord {
    members_sequence: i64,
    organizations_sequence: i64,
}

impl RemovedMemberRecord {
    fn into_committed_change(
        self,
        organization: RecordId,
        user: RecordId,
    ) -> Result<CommittedChange<RemoveOrganizationMemberResponse>, otel_wasi::Error> {
        let user_id = user.clone().into();
        let member_event = OrganizationMembersChanged {
            sequence: self.members_sequence,
            changes: vec![OrganizationMembersChange::Remove(Box::new(user_id))],
            ..Default::default()
        };
        let organization_id = organization.clone().into();
        let organization_event = UserOrganizationsChanged {
            sequence: self.organizations_sequence,
            changes: vec![UserOrganizationsChange::Remove(Box::new(organization_id))],
            ..Default::default()
        };
        Ok(CommittedChange::new(
            skir_variant!(RemoveOrganizationMemberResponse::Success {
                event: member_event.clone(),
            }),
            [
                PublicationEffect::CapturedMembership(MembershipFact::Members {
                    organization: organization.key.raw_identity()?.to_owned(),
                    event: member_event,
                }),
                PublicationEffect::CapturedMembership(MembershipFact::UserOrganizations {
                    user: user.key.raw_identity()?.to_owned(),
                    event: organization_event,
                }),
            ],
        ))
    }
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
    _msg: NatsMessage,
    scope: wasmcloud_utils::transport_routes::OrganizationActorScope,
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

/// Applies one role selection to all requested members as one database transaction.
///
/// The database function rejects an empty or duplicated selection, unknown users or roles,
/// protected roles, roleless results, and a result that would leave the organization without a
/// founder.
/// The returned event describes the full updated member values and is published after commit.
#[tracing::instrument(skip_all)]
pub async fn handle_update(
    _msg: NatsMessage,
    scope: wasmcloud_utils::transport_routes::OrganizationActorScope,
    request: UpdateOrganizationMemberRolesRequest,
) -> Result<UpdateOrganizationMemberRolesResponse, otel_wasi::Error> {
    let actor_id = scope.user.as_str();
    let org_id = scope.organization.as_str();
    wasmcloud_utils::validate_record_ids!(
        UpdateOrganizationMemberRolesResponse,
        request.user_ids,
        "user"
    );
    wasmcloud_utils::validate_record_ids!(
        UpdateOrganizationMemberRolesResponse,
        request.role_ids,
        "organization_role"
    );
    let user_ids = request.user_ids.clone();
    let role_ids = request.role_ids.clone();
    otel_wasi::main_attribute!(
        "actor.id" = actor_id.to_string(),
        "organization.id" = org_id.to_string(),
        "member.result_count" = user_ids.len() as i64,
        "role.result_count" = role_ids.len() as i64
    );
    let user_record_ids = user_ids.as_slice().into_surreal_record_ids();
    let organization_id = RecordId::new("organization", org_id);
    let role_record_ids = role_ids.as_slice().into_surreal_record_ids();

    let result = transaction_query!(
        MemberUpdateOutcome,
        r#"
        BEGIN TRANSACTION;

        RETURN fn::organization::members::update_roles($org, $users, $roles);

        COMMIT TRANSACTION;
        "#,
    )
    .bind("users", user_record_ids)
    .bind("org", organization_id)
    .bind("roles", role_record_ids)
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

/// Removes one member when doing so preserves the organization founder invariant.
///
/// The database transaction returns a domain error when the user is not a member or is the
/// protected founder. A successful removal advances both the
/// organization member sequence and the user's organization sequence, then publishes both changes.
#[tracing::instrument(skip_all)]
pub async fn handle_remove(
    _msg: NatsMessage,
    scope: wasmcloud_utils::transport_routes::OrganizationActorScope,
    request: RemoveOrganizationMemberRequest,
) -> Result<RemoveOrganizationMemberResponse, otel_wasi::Error> {
    let actor_id = scope.user.as_str();
    let org_id = scope.organization.as_str();
    wasmcloud_utils::validate_record_ids!(
        RemoveOrganizationMemberResponse,
        request.user_id,
        "user"
    );
    let user_id = request.user_id.clone();
    otel_wasi::main_attribute!(
        "actor.id" = actor_id.to_string(),
        "organization.id" = org_id.to_string(),
        "user.id" = user_id.key.to_string()
    );
    let user_record_id = RecordId::from(&user_id);
    let organization_id = RecordId::new("organization", org_id);

    let result = transaction_query!(
        RemovedMemberRecord,
        r#"
        BEGIN TRANSACTION;
        RETURN {
            LET $founder = $org.founder;
            IF $founder = $user {
                THROW 'founder-cannot-be-removed-error'
            };

            LET $member = SELECT * FROM member_of WHERE in = $user AND out = $org;

            IF array::len($member) = 0 {
                THROW 'user-not-member-error'
            };

            LET $is_founder = fn::organization::roles::has_named_role($member[0].roles, 'founder');
            LET $other_founders = SELECT * FROM member_of WHERE out = $org AND id != $member[0].id AND fn::organization::roles::has_named_role(roles, 'founder');

            IF $is_founder AND array::len($other_founders) = 0 {
                THROW 'founder-cannot-be-removed-error'
            };

            DELETE $member[0].id;

            LET $members_sequence = UPDATE ONLY $org SET members_sequence += 1
                RETURN VALUE members_sequence;
            LET $organizations_sequence = UPDATE ONLY $user SET organizations_sequence += 1
                RETURN VALUE organizations_sequence;

            RETURN {
                members_sequence: $members_sequence,
                organizations_sequence: $organizations_sequence
            };
        };
        COMMIT TRANSACTION;
        "#,
    )
    .bind("user", user_record_id.clone())
    .bind("org", organization_id.clone())
    .execute()
    .await
    .error_with_slug("member-remove-query-failed")?
    .decode()
    .error_with_slug("member-remove-result-parse-failed")?;

    if let TransactionOutcome::Rejected(error) = &result {
        otel_wasi::main_attribute!("member.outcome" = error.message().to_owned());
    }
    let deleted = wasmcloud_utils::skir_domain_result!(RemoveOrganizationMemberResponse, result,
        "user-not-member-error" => { user_id: user_id.clone() },
        "founder-cannot-be-removed-error" => { user_id: user_id.clone() }
    );

    otel_wasi::main_attribute!("member.outcome" = "removed");
    deleted
        .into_committed_change(organization_id, user_record_id)?
        .publish_with(&PublicationExecutor {
            refresher: CapturedOnly,
        })
        .await
}
