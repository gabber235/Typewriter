use typewriter_component_test::{
    organization::{approve_join_requests, found, join_code_request},
    prelude::*,
};
use wasmcloud_utils::{
    skir::base::organization::v1::{
        join_codes::{
            GenerateOrganizationJoinCodeRequest_Expiration, GenerateOrganizationJoinCodeResponse,
            OrganizationJoinCodesChange, OrganizationJoinCodesChanged,
        },
        join_request::{
            ApproveOrganizationJoinRequestsResponse, OrganizationJoinRequestsChange,
            OrganizationJoinRequestsChanged, UserJoinRequestsChange, UserJoinRequestsChanged,
        },
        member::{
            OrganizationMembersChange, OrganizationMembersChanged, WatchOrganizationMembersRequest,
            WatchOrganizationMembersResponse,
        },
        organization::{UserOrganizationsChange, UserOrganizationsChanged},
        user::{
            SubmitUserJoinRequestRequest, SubmitUserJoinRequestResponse,
            WatchUserOrganizationsRequest, WatchUserOrganizationsResponse,
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

#[component_test(ManualMembership)]
async fn manual_request_and_approval_are_visible_from_both_components(
    context: &mut TestContext<ManualMembership>,
) -> TestResult {
    let acme = found(context, ada(), "acme").await?;
    Seed::new().user(grace()).apply(context).await?;
    let generated: GenerateOrganizationJoinCodeResponse = context
        .arrange(
            from_member(ada(), &acme, "members.join_codes.generate"),
            &join_code_request(
                true,
                GenerateOrganizationJoinCodeRequest_Expiration::Never,
                Vec::new(),
            ),
        )
        .await?;
    let GenerateOrganizationJoinCodeResponse::Success(generated) = generated else {
        anyhow::bail!("generating Acme's join code failed: {generated:?}");
    };
    let code = generated.code.code;
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

    let approval =
        approve_join_requests(context, ada(), &acme, vec![request], vec![writer]).await?;
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
