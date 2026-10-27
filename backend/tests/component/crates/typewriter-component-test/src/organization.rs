//! Organizations and their members: the requests people make through the organization
//! components, the join transaction raced directly, and the expectations on the membership events
//! both views receive.

use anyhow::Result;
use component_test::TestContext;
use wasmcloud_utils::skir::base::{
    kernel::v1::record_id::RecordId,
    organization::v1::{
        join_codes::{
            GenerateOrganizationJoinCodeRequest, GenerateOrganizationJoinCodeRequest_AutoAccept,
            GenerateOrganizationJoinCodeRequest_Expiration,
        },
        join_request::{
            ApproveOrganizationJoinRequestsRequest, ApproveOrganizationJoinRequestsResponse,
            OrganizationJoinRequestsChange, OrganizationJoinRequestsChanged,
            UserJoinRequestsChange, UserJoinRequestsChanged,
        },
        member::{
            OrganizationMembersChange, OrganizationMembersChanged,
            UpdateOrganizationMemberRolesRequest, UpdateOrganizationMemberRolesResponse,
        },
        organization::{
            CreateOrganizationRequest, CreateOrganizationResponse, UserOrganizationsChange,
            UserOrganizationsChanged,
        },
        role::OrganizationRole,
        user::{SubmitUserJoinRequestRequest, SubmitUserJoinRequestResponse},
    },
};

use crate::{
    Organization, Seed, StackUser, TypewriterContext, skir_record_id,
    topology::{from_member, from_user, to_organization, to_user},
};

/// The component's join transaction, raced directly against the database, so the transaction's
/// own guarantee is checked apart from the component's conflict retry.
const JOIN_SUBMISSION: &str = include_str!(concat!(
    env!("CARGO_MANIFEST_DIR"),
    "/../../../../organization/user-organization/src/join_submission_transaction.surql"
));

const JOIN_SUBMISSION_OUTCOME: usize = wasmcloud_utils::transaction_outcome_index_file!(
    "../../../../organization/user-organization/src/join_submission_transaction.surql"
);

/// `founder` signs in and founds the organization `name` through the component, as the panel
/// does.
pub async fn found<F>(
    context: &TestContext<F>,
    founder: &StackUser,
    name: &str,
) -> Result<Organization> {
    Seed::new().user(founder).apply(context).await?;
    let reply: CreateOrganizationResponse = context
        .arrange(
            from_user(founder, "organization.create"),
            &CreateOrganizationRequest {
                name: name.to_owned(),
                ..Default::default()
            },
        )
        .await?;
    match reply {
        CreateOrganizationResponse::Success(success) => {
            Ok(Organization::from_id(&success.organization.organization_id))
        }
        reply => anyhow::bail!("founding {name} failed: {reply:?}"),
    }
}

/// The record of the join code `key`.
pub fn join_code_id(key: &str) -> RecordId {
    skir_record_id("organization_join_code", key)
}

/// A request for a join code that is consumed by its first use when `single_use`, expires as
/// `expiration` says, and admits at once with `roles` when any are given.
pub fn join_code_request(
    single_use: bool,
    expiration: GenerateOrganizationJoinCodeRequest_Expiration,
    roles: Vec<RecordId>,
) -> GenerateOrganizationJoinCodeRequest {
    GenerateOrganizationJoinCodeRequest {
        single_use,
        expiration,
        auto_accept: GenerateOrganizationJoinCodeRequest_AutoAccept {
            role_ids: roles,
            ..Default::default()
        },
        ..Default::default()
    }
}

/// `user` asks to join with the join code `key`.
pub async fn submit_join_request<F>(
    context: &TestContext<F>,
    user: &StackUser,
    key: &str,
) -> Result<SubmitUserJoinRequestResponse> {
    context
        .request(
            from_user(user, "organization.join_requests.request"),
            &SubmitUserJoinRequestRequest {
                code: join_code_id(key),
                ..Default::default()
            },
        )
        .await
}

/// `user` submits the join code `key` through the component's own join transaction, straight
/// to the database, and receives the kind of the transaction's outcome, such as `request_made`.
pub async fn join_transaction<F>(
    context: &TestContext<F>,
    user: &StackUser,
    key: &str,
) -> Result<String> {
    let outcome = context
        .database()?
        .seed(JOIN_SUBMISSION)
        .bind("user", surrealdb::types::RecordId::from(user.id()))?
        .bind("code", surrealdb::types::RecordId::from(join_code_id(key)))?
        .transaction_json(JOIN_SUBMISSION_OUTCOME)
        .await?;
    match outcome["kind"].as_str() {
        Some(kind) => Ok(kind.to_owned()),
        None => anyhow::bail!("the join transaction answered without a kind: {outcome}"),
    }
}

/// `member` approves `requests` of `organization`, handing out `roles`.
pub async fn approve_join_requests<F>(
    context: &TestContext<F>,
    member: &StackUser,
    organization: &Organization,
    requests: Vec<RecordId>,
    roles: Vec<RecordId>,
) -> Result<ApproveOrganizationJoinRequestsResponse> {
    context
        .request(
            from_member(member, organization, "members.join_requests.approve"),
            &ApproveOrganizationJoinRequestsRequest {
                request_ids: requests,
                role_ids: roles,
                ..Default::default()
            },
        )
        .await
}

/// `member` gives the members `users` of `organization` the roles `roles`.
pub async fn update_member_roles<F>(
    context: &TestContext<F>,
    member: &StackUser,
    organization: &Organization,
    users: Vec<RecordId>,
    roles: Vec<RecordId>,
) -> Result<UpdateOrganizationMemberRolesResponse> {
    context
        .request(
            from_member(member, organization, "members.update"),
            &UpdateOrganizationMemberRolesRequest {
                user_ids: users,
                role_ids: roles,
                ..Default::default()
            },
        )
        .await
}

/// The names of `roles`, sorted, so a role list compares without its order.
pub fn role_names(roles: &[OrganizationRole]) -> Vec<&str> {
    let mut names = roles
        .iter()
        .map(|role| role.name.as_str())
        .collect::<Vec<_>>();
    names.sort_unstable();
    names
}

/// Expects both views of `applicant`'s request `request` to `organization` to learn that it is
/// gone.
pub fn expect_join_request_removed<F>(
    context: &TestContext<F>,
    organization: &Organization,
    applicant: &StackUser,
    request: &RecordId,
) -> Result<()> {
    let removed = request.clone();
    context.expect_publish(
        to_organization(organization, "join_requests.changed"),
        move |event: &OrganizationJoinRequestsChanged| {
            matches!(event.changes.as_slice(), [OrganizationJoinRequestsChange::Remove(id)] if **id == removed)
        },
    )?;
    let removed = request.clone();
    context.expect_publish(
        to_user(applicant, "join_requests.changed"),
        move |event: &UserJoinRequestsChanged| {
            matches!(event.changes.as_slice(), [UserJoinRequestsChange::Remove(id)] if **id == removed)
        },
    )?;
    Ok(())
}

/// Expects `user`'s organization list and the member list of `organization` both to learn that
/// `user` joined it holding `role`.
pub fn expect_joined<F>(
    context: &TestContext<F>,
    organization: &Organization,
    user: &StackUser,
    role: &'static str,
) -> Result<()> {
    let joined = organization.id();
    context.expect_publish(
        to_user(user, "organizations.changed"),
        move |event: &UserOrganizationsChanged| {
            matches!(event.changes.as_slice(), [UserOrganizationsChange::Add(organization)]
                if organization.organization_id == joined)
        },
    )?;
    let member = user.id();
    context.expect_publish(
        to_organization(organization, "members.changed"),
        move |event: &OrganizationMembersChanged| {
            matches!(event.changes.as_slice(), [OrganizationMembersChange::Add(added)]
                if added.user_id == member && added.roles.iter().any(|held| held.name == role))
        },
    )?;
    Ok(())
}

/// A role a join code cannot hand out.
#[derive(Debug)]
pub enum UnavailableRole {
    /// No such role exists.
    Missing,
    /// The role exists, but no member may be given it.
    Protected,
}

/// One invalid part of a member update.
#[derive(Debug)]
pub enum InvalidMemberUpdate {
    /// One of the roles does not exist.
    MissingRole,
    /// One of the roles may not be given.
    ProtectedRole,
    /// One of the users does not exist.
    MissingUser,
}
