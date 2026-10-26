use crate::organization::organization_members::approve;
use typewriter_component_test::prelude::*;
use wasmcloud_utils::{
    skir::base::{
        kernel::v1::record_id::RecordId,
        organization::v1::{
            join_codes::{
                GenerateOrganizationJoinCodeRequest,
                GenerateOrganizationJoinCodeRequest_Expiration,
                GenerateOrganizationJoinCodeResponse, OrganizationJoinCodesChange,
                OrganizationJoinCodesChanged,
            },
            join_request::{
                ApproveOrganizationJoinRequestsResponse, OrganizationJoinRequestsChange,
                OrganizationJoinRequestsChanged, UserJoinRequestsChange, UserJoinRequestsChanged,
            },
            member::{
                OrganizationMembersChange, OrganizationMembersChanged,
                WatchOrganizationMembersRequest, WatchOrganizationMembersResponse,
            },
            organization::{
                CreateOrganizationRequest, CreateOrganizationResponse, UserOrganizationsChange,
                UserOrganizationsChanged,
            },
            user::{
                SubmitUserJoinRequestRequest, SubmitUserJoinRequestResponse,
                WatchUserOrganizationsRequest, WatchUserOrganizationsResponse,
            },
        },
    },
    transport_routes::{organization_members, user_organization},
};

mod service_onboarding;

#[component_fixture(
    id = "workflow-manual-membership",
    primary(package = "user-organization", target = "user_organization"),
    dependency(package = "organization-members", target = "organization_members")
)]
pub struct ManualMembership;

impl FixtureSpec for ManualMembership {
    fn configure(builder: FixtureBuilder<Self>) -> FixtureBuilder<Self> {
        builder
            .messaging()
            .primary(|component| component.subscriptions(user_organization::SUBSCRIPTIONS))
            .dependency("organization-members", |component| {
                component.subscriptions(organization_members::SUBSCRIPTIONS)
            })
            .typewriter_streams()
            .otel()
            .typewriter_database(SchemaPreset::Full)
    }
}

type Context = TestContext<ManualMembership>;

/// Ada founds Acme through user-organization and has organization-members generate a single use
/// join code that needs approval; returns the organization and the code.
async fn acme_with_code(context: &Context) -> anyhow::Result<(Organization, RecordId)> {
    Seed::new()
        .user(ada())
        .user(grace())
        .apply(&context.database()?)
        .await?;
    let founded: CreateOrganizationResponse = context
        .arrange(
            from_user(ada(), "organization.create"),
            &CreateOrganizationRequest {
                name: "acme".into(),
                ..Default::default()
            },
        )
        .await?;
    let CreateOrganizationResponse::Success(founded) = founded else {
        anyhow::bail!("founding Acme failed: {founded:?}");
    };
    let acme = Organization::from_id(&founded.organization.organization_id);
    let generated: GenerateOrganizationJoinCodeResponse = context
        .arrange(
            from_member(ada(), &acme, "members.join_codes.generate"),
            &GenerateOrganizationJoinCodeRequest {
                single_use: true,
                expiration: GenerateOrganizationJoinCodeRequest_Expiration::Never,
                ..Default::default()
            },
        )
        .await?;
    let GenerateOrganizationJoinCodeResponse::Success(generated) = generated else {
        anyhow::bail!("generating Acme's join code failed: {generated:?}");
    };
    Ok((acme, generated.code.code))
}

#[component_test(ManualMembership)]
async fn manual_request_and_approval_are_visible_from_both_components(
    context: &mut Context,
) -> TestResult {
    let (acme, code) = acme_with_code(context).await?;
    let organization = acme.key.clone();
    context.expect_publish(
        to_user(grace(), "join_requests.changed"),
        move |event: &UserJoinRequestsChanged| {
            matches!(event.changes.as_slice(), [UserJoinRequestsChange::Add(request)]
                if request.organization_id.key.to_string() == organization)
        },
    )?;
    context.expect_publish(
        to_organization(&acme, "join_requests.changed"),
        |event: &OrganizationJoinRequestsChanged| {
            matches!(event.changes.as_slice(), [OrganizationJoinRequestsChange::Add(request)]
                if request.user_id.key.to_string() == grace().subject)
        },
    )?;
    let used = code.clone();
    context.expect_publish(
        to_organization(&acme, "join_codes.changed"),
        move |event: &OrganizationJoinCodesChanged| {
            matches!(event.changes.as_slice(), [OrganizationJoinCodesChange::Remove(code)]
                if **code == used)
        },
    )?;

    let submitted: SubmitUserJoinRequestResponse = context
        .request(
            from_user(grace(), "organization.join_requests.request"),
            &SubmitUserJoinRequestRequest {
                code,
                ..Default::default()
            },
        )
        .await?;
    assert!(
        matches!(submitted, SubmitUserJoinRequestResponse::RequestMade(_)),
        "{submitted:?}"
    );
    context.messaging()?.wait_idle().await?;

    let database = context.database()?;
    let request = database.join_request(grace(), &acme).await?;
    let writer = database.role(&acme, "writer").await?;
    let approved = request.clone();
    context.expect_publish(
        to_user(grace(), "join_requests.changed"),
        move |event: &UserJoinRequestsChanged| {
            matches!(event.changes.as_slice(), [UserJoinRequestsChange::Remove(id)]
                if **id == approved)
        },
    )?;
    let approved = request.clone();
    context.expect_publish(
        to_organization(&acme, "join_requests.changed"),
        move |event: &OrganizationJoinRequestsChanged| {
            matches!(event.changes.as_slice(), [OrganizationJoinRequestsChange::Remove(id)]
                if **id == approved)
        },
    )?;
    context.expect_publish(
        to_organization(&acme, "members.changed"),
        |event: &OrganizationMembersChanged| {
            matches!(event.changes.as_slice(), [OrganizationMembersChange::Add(member)]
                if member.user_id.key.to_string() == grace().subject
                    && member.roles.iter().any(|role| role.name == "writer"))
        },
    )?;
    context.expect_publish(
        to_user(grace(), "organizations.changed"),
        |event: &UserOrganizationsChanged| {
            matches!(event.changes.as_slice(), [UserOrganizationsChange::Add(organization)]
                if organization.name == "acme")
        },
    )?;

    let approval = approve(context, &acme, request, writer).await?;
    assert!(
        matches!(
            approval,
            ApproveOrganizationJoinRequestsResponse::Success(_)
        ),
        "{approval:?}"
    );
    context.messaging()?.wait_idle().await?;

    let user_view: WatchUserOrganizationsResponse = context
        .request(
            from_user(grace(), "organization.watch"),
            &WatchUserOrganizationsRequest::default(),
        )
        .await?;
    assert!(
        matches!(&user_view, WatchUserOrganizationsResponse::Snapshot(snapshot)
            if matches!(snapshot.values.as_slice(), [organization] if organization.name == "acme")),
        "{user_view:?}"
    );
    let organization_view: WatchOrganizationMembersResponse = context
        .request(
            from_member(ada(), &acme, "members.watch"),
            &WatchOrganizationMembersRequest::default(),
        )
        .await?;
    assert!(
        matches!(&organization_view, WatchOrganizationMembersResponse::Snapshot(snapshot)
            if snapshot.values.iter().any(|member| member.user_id.key.to_string() == grace().subject
                && member.roles.iter().any(|role| role.name == "writer"))),
        "{organization_view:?}"
    );
    Ok(())
}
