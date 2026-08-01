use std::time::Duration;

use component_test::{
    FixtureBuilder, FixtureSpec, TestContext, TestResult, component_fixture, component_test,
};
use typewriter_component_test::prelude::{
    DatabaseHandle, SchemaPreset, SkirMessagingExt, TypewriterFixtureBuilderExt,
    database_record_key, skir_record_id,
};
use wasmcloud_utils::{
    skir::base::organization::v1::{
        join_request::{
            ApproveOrganizationJoinRequestRequest, ApproveOrganizationJoinRequestResponse,
        },
        member::{WatchOrganizationMembersRequest, WatchOrganizationMembersResponse},
        user::{
            SubmitUserJoinRequestRequest, SubmitUserJoinRequestResponse,
            WatchUserOrganizationsRequest, WatchUserOrganizationsResponse,
        },
    },
    skir_client::UnrecognizedValues,
};

mod service_onboarding;

#[component_fixture(
    id = "workflow-manual-membership",
    primary(package = "user-organization", target = "user_organization"),
    dependency(package = "organization-members", target = "organization_members"),
    affected_paths(
        "backend/organization/user-organization/",
        "backend/organization/organization-members/",
        "backend/database/schema/organization/"
    )
)]
pub struct ManualMembership;

impl FixtureSpec for ManualMembership {
    fn configure(builder: FixtureBuilder<Self>) -> FixtureBuilder<Self> {
        builder
            .messaging()
            .primary(|component| component.subscription("typewriter.from.user.*.organization.>"))
            .dependency("organization-members", |component| {
                component.subscription("typewriter.from.user.*.organization.*.members.>")
            })
            .otel()
            .typewriter_database(SchemaPreset::Full)
    }
}

#[component_test(ManualMembership)]
async fn manual_request_and_approval_are_visible_from_both_components(
    context: &mut TestContext<ManualMembership>,
) -> TestResult {
    let database = context
        .extension::<DatabaseHandle>()
        .ok_or_else(|| anyhow::anyhow!("database handle missing"))?;
    database
        .execute(
            r#"
            CREATE user:founder SET name = 'founder';
            CREATE user:applicant SET name = 'applicant';
            CREATE organization:alpha SET name = 'alpha', founder = user:founder;
            CREATE organization_join_code:invite SET
                organization = organization:alpha,
                single_use = true,
                auto_accept_roles = [],
                expires_at = time::now() + 1h;
            "#,
        )
        .await?;

    let mock = context.messaging_mock()?;
    mock.expect_publish("typewriter.to.user.applicant.organization.join_requests.watch");
    mock.expect_publish("typewriter.to.organization.alpha.members.join_requests.watch");
    mock.expect_publish("typewriter.to.organization.alpha.members.join_codes.watch");
    mock.expect_publish("typewriter.to.user.applicant.organization.join_requests.watch");
    mock.expect_publish("typewriter.to.organization.alpha.members.join_requests.watch");
    mock.expect_publish("typewriter.to.organization.alpha.members.watch");
    mock.expect_publish("typewriter.to.user.applicant.organization.watch");

    let join_response = context
        .messaging()?
        .request_skir(
            "typewriter.from.user.applicant.organization.join_requests.request",
            &SubmitUserJoinRequestRequest {
                code: skir_record_id("organization_join_code", "invite"),
                _unrecognized: None,
            },
            SubmitUserJoinRequestRequest::serializer(),
            SubmitUserJoinRequestResponse::serializer(),
            Duration::from_secs(2),
            UnrecognizedValues::Drop,
        )
        .await?;
    assert!(matches!(
        join_response,
        SubmitUserJoinRequestResponse::RequestMade(_)
    ));

    let request_key = database_record_key(
        &database
            .query_json(
                "SELECT VALUE id FROM request_to_join WHERE in = user:applicant AND out = organization:alpha",
            )
            .await?,
        "request_to_join",
    )?;
    let writer_key = database_record_key(
        &database
            .query_json(
                "SELECT VALUE id FROM organization_role WHERE organization = organization:alpha AND name = 'writer'",
            )
            .await?,
        "organization_role",
    )?;
    let approval = context
        .messaging()?
        .request_skir(
            "typewriter.from.user.founder.organization.alpha.members.join_requests.approve",
            &ApproveOrganizationJoinRequestRequest {
                request_id: skir_record_id("request_to_join", &request_key),
                role_ids: vec![skir_record_id("organization_role", &writer_key)],
                _unrecognized: None,
            },
            ApproveOrganizationJoinRequestRequest::serializer(),
            ApproveOrganizationJoinRequestResponse::serializer(),
            Duration::from_secs(2),
            UnrecognizedValues::Drop,
        )
        .await?;
    assert!(matches!(
        approval,
        ApproveOrganizationJoinRequestResponse::Success(_)
    ));

    let user_view = context
        .messaging()?
        .request_skir(
            "typewriter.from.user.applicant.organization.watch",
            &WatchUserOrganizationsRequest::default(),
            WatchUserOrganizationsRequest::serializer(),
            WatchUserOrganizationsResponse::serializer(),
            Duration::from_secs(2),
            UnrecognizedValues::Drop,
        )
        .await?;
    assert!(matches!(
        user_view,
        WatchUserOrganizationsResponse::List(organizations)
            if organizations.len() == 1 && organizations[0].name == "alpha"
    ));

    let organization_view = context
        .messaging()?
        .request_skir(
            "typewriter.from.user.founder.organization.alpha.members.watch",
            &WatchOrganizationMembersRequest::default(),
            WatchOrganizationMembersRequest::serializer(),
            WatchOrganizationMembersResponse::serializer(),
            Duration::from_secs(2),
            UnrecognizedValues::Drop,
        )
        .await?;
    assert!(matches!(
        organization_view,
        WatchOrganizationMembersResponse::List(members)
            if members.iter().any(|member| member.user_id.key.to_string() == "applicant")
    ));
    Ok(())
}
