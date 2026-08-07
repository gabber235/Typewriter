use std::time::Duration;

use component_test::{
    FixtureBuilder, FixtureSpec, TestContext, TestResult, component_fixture, component_test,
};
use json_matcher::assert_jm;
use typewriter_component_test::prelude::{
    DatabaseHandle, SchemaPreset, SkirMessagingExt, TypewriterFixtureBuilderExt,
    database_record_key, skir_record_id,
};
use wasmcloud_utils::{
    skir::base::organization::v1::{
        join_codes::WatchOrganizationJoinCodesResponse,
        join_request::WatchOrganizationJoinRequestsResponse,
        member::WatchOrganizationMembersResponse,
        organization::{CreateOrganizationRequest, CreateOrganizationResponse},
        user::*,
    },
    skir_client::UnrecognizedValues,
};

#[component_fixture(
    id = "user-organization",
    primary(package = "user-organization", target = "user_organization"),
    affected_paths(
        "backend/organization/user-organization/",
        "backend/database/schema/organization/"
    )
)]
pub struct UserOrganization;

impl FixtureSpec for UserOrganization {
    fn configure(builder: FixtureBuilder<Self>) -> FixtureBuilder<Self> {
        builder
            .messaging_subscription("typewriter.from.user.*.organization.>")
            .otel()
            .typewriter_database(SchemaPreset::Organization)
    }
}

#[component_test(UserOrganization)]
async fn create_organization_sets_up_roles_membership_and_notification(
    context: &mut TestContext<UserOrganization>,
) -> TestResult {
    let database = context
        .extension::<DatabaseHandle>()
        .ok_or_else(|| anyhow::anyhow!("database handle missing"))?;
    database
        .execute("CREATE user:alice SET name = 'alice'")
        .await?;

    context
        .messaging_mock()?
        .expect_publish("typewriter.to.user.alice.organization.watch")
        .body_matches(|body| {
            matches!(
                WatchUserOrganizationsResponse::serializer().from_bytes(
                    body,
                    UnrecognizedValues::Drop,
                ),
                Ok(WatchUserOrganizationsResponse::Add(organization))
                    if organization.name == "alpha"
                        && organization.logo_url == "https://example.com/alpha.png"
            )
        });

    let request = CreateOrganizationRequest {
        name: "alpha".to_string(),
        logo_url: Some("https://example.com/alpha.png".to_string()),
        _unrecognized: None,
    };
    let response = context
        .messaging()?
        .request_skir(
            "typewriter.from.user.alice.organization.create",
            &request,
            CreateOrganizationRequest::serializer(),
            CreateOrganizationResponse::serializer(),
            Duration::from_secs(2),
            UnrecognizedValues::Drop,
        )
        .await?;

    let organization = match response {
        CreateOrganizationResponse::Success(organization) => organization,
        response => anyhow::bail!("unexpected create organization response: {response:?}"),
    };
    assert_eq!(organization.name, "alpha");
    let state = database
        .seed(
            r#"
            RETURN {
                role_names: array::sort(
                    SELECT VALUE name
                    FROM organization_role
                    WHERE organization = $organization
                ),
                founder_roles: array::sort(
                    SELECT VALUE roles.name
                    FROM member_of
                    WHERE in = user:alice
                        AND out = $organization
                )[0]
            }
            "#,
        )
        .bind(
            "organization",
            surrealdb_types::RecordId::from(organization.organization_id),
        )?
        .query_json()
        .await?;
    assert_jm!(state, {
        "role_names": ["founder", "writer"],
        "founder_roles": ["founder"]
    });
    Ok(())
}

#[component_test(UserOrganization)]
async fn manual_join_consumes_single_use_code_and_publishes_both_views(
    context: &mut TestContext<UserOrganization>,
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

    context
        .messaging_mock()?
        .expect_publish("typewriter.to.user.applicant.organization.join_requests.watch")
        .body_matches(|body| {
            matches!(
                WatchUserJoinRequestsResponse::serializer().from_bytes(
                    body,
                    UnrecognizedValues::Drop,
                ),
                Ok(WatchUserJoinRequestsResponse::Add(request))
                    if request.organization_name == "alpha"
                        && request.organization_id.key.to_string() == "alpha"
            )
        });
    context
        .messaging_mock()?
        .expect_publish("typewriter.to.organization.alpha.members.join_requests.watch")
        .body_matches(|body| {
            matches!(
                WatchOrganizationJoinRequestsResponse::serializer().from_bytes(
                    body,
                    UnrecognizedValues::Drop,
                ),
                Ok(WatchOrganizationJoinRequestsResponse::Add(request))
                    if request.user_id.key.to_string() == "applicant"
                        && request.user_name.as_deref() == Some("applicant")
            )
        });
    context
        .messaging_mock()?
        .expect_publish("typewriter.to.organization.alpha.members.join_codes.watch")
        .body_matches(|body| {
            matches!(
                WatchOrganizationJoinCodesResponse::serializer().from_bytes(
                    body,
                    UnrecognizedValues::Drop,
                ),
                Ok(WatchOrganizationJoinCodesResponse::Remove(code))
                    if code.key.to_string() == "invite"
            )
        });

    let request = SubmitUserJoinRequestRequest {
        code: skir_record_id("organization_join_code", "invite"),
        _unrecognized: None,
    };
    let response = context
        .messaging()?
        .request_skir(
            "typewriter.from.user.applicant.organization.join_requests.request",
            &request,
            SubmitUserJoinRequestRequest::serializer(),
            SubmitUserJoinRequestResponse::serializer(),
            Duration::from_secs(2),
            UnrecognizedValues::Drop,
        )
        .await?;

    assert!(
        matches!(response, SubmitUserJoinRequestResponse::RequestMade(request) if request.organization_name == "alpha")
    );
    let state = database
        .query_json(
            "RETURN { codes: count(SELECT id FROM organization_join_code), requests: count(SELECT id FROM request_to_join WHERE in = user:applicant AND out = organization:alpha) }",
        )
        .await?;
    assert_jm!(state, { "codes": 0, "requests": 1 });
    Ok(())
}

#[component_test(UserOrganization)]
async fn failed_single_use_join_rolls_back_code_deletion(
    context: &mut TestContext<UserOrganization>,
) -> TestResult {
    let database = context
        .extension::<DatabaseHandle>()
        .ok_or_else(|| anyhow::anyhow!("database handle missing"))?;
    database
        .execute(
            r#"
            CREATE user:founder SET name = 'founder';
            CREATE organization:alpha SET name = 'alpha', founder = user:founder;
            CREATE organization_join_code:invite SET
                organization = organization:alpha,
                single_use = true,
                auto_accept_roles = [],
                expires_at = time::now() + 1h;
            "#,
        )
        .await?;

    let request = SubmitUserJoinRequestRequest {
        code: skir_record_id("organization_join_code", "invite"),
        _unrecognized: None,
    };
    let response = context
        .messaging()?
        .request_skir(
            "typewriter.from.user.founder.organization.join_requests.request",
            &request,
            SubmitUserJoinRequestRequest::serializer(),
            SubmitUserJoinRequestResponse::serializer(),
            Duration::from_secs(2),
            UnrecognizedValues::Drop,
        )
        .await?;

    assert!(matches!(
        response,
        SubmitUserJoinRequestResponse::AlreadyMemberError(_)
    ));
    let codes = database
        .query_json("RETURN count(SELECT id FROM organization_join_code:invite)")
        .await?;
    assert_jm!(codes, 1);
    Ok(())
}

#[component_test(UserOrganization)]
async fn watch_returns_only_requested_user_organizations(
    context: &mut TestContext<UserOrganization>,
) -> TestResult {
    let database = context
        .extension::<DatabaseHandle>()
        .ok_or_else(|| anyhow::anyhow!("database handle missing"))?;
    database
        .execute(
            r#"
        CREATE user:alice SET name = 'alice';
        CREATE user:bob SET name = 'bob';
        CREATE organization:alpha SET name = 'alpha', founder = user:alice;
        CREATE organization:beta SET name = 'beta', founder = user:bob;
    "#,
        )
        .await?;
    let response = context
        .messaging()?
        .request_skir(
            "typewriter.from.user.alice.organization.watch",
            &WatchUserOrganizationsRequest::default(),
            WatchUserOrganizationsRequest::serializer(),
            WatchUserOrganizationsResponse::serializer(),
            Duration::from_secs(2),
            UnrecognizedValues::Drop,
        )
        .await?;
    let WatchUserOrganizationsResponse::List(organizations) = response else {
        anyhow::bail!("expected organization list")
    };
    assert_eq!(
        organizations
            .iter()
            .map(|organization| organization.name.as_str())
            .collect::<Vec<_>>(),
        ["alpha"]
    );
    Ok(())
}

#[component_test(UserOrganization)]
async fn automatic_join_creates_membership_and_consumes_code(
    context: &mut TestContext<UserOrganization>,
) -> TestResult {
    let database = context
        .extension::<DatabaseHandle>()
        .ok_or_else(|| anyhow::anyhow!("database handle missing"))?;
    database.execute(r#"
        CREATE user:founder SET name = 'founder';
        CREATE user:applicant SET name = 'applicant';
        CREATE organization:alpha SET name = 'alpha', founder = user:founder;
        LET $writer = SELECT VALUE id FROM ONLY organization_role WHERE organization = organization:alpha AND name = 'writer';
        CREATE organization_join_code:automatic SET organization = organization:alpha, single_use = true, auto_accept_roles = [$writer], expires_at = time::now() + 1h;
    "#).await?;
    context
        .messaging_mock()?
        .expect_publish("typewriter.to.user.applicant.organization.watch");
    context.messaging_mock()?.expect_publish("typewriter.to.organization.alpha.members.watch").body_matches(|body| {
        matches!(WatchOrganizationMembersResponse::serializer().from_bytes(body, UnrecognizedValues::Drop), Ok(WatchOrganizationMembersResponse::Add(member)) if member.user_id.key.to_string() == "applicant")
    });
    context
        .messaging_mock()?
        .expect_publish("typewriter.to.organization.alpha.members.join_codes.watch");
    let request = SubmitUserJoinRequestRequest {
        code: skir_record_id("organization_join_code", "automatic"),
        _unrecognized: None,
    };
    let response = context
        .messaging()?
        .request_skir(
            "typewriter.from.user.applicant.organization.join_requests.request",
            &request,
            SubmitUserJoinRequestRequest::serializer(),
            SubmitUserJoinRequestResponse::serializer(),
            Duration::from_secs(2),
            UnrecognizedValues::Drop,
        )
        .await?;
    assert!(
        matches!(response, SubmitUserJoinRequestResponse::AutoAccepted(member) if member.organization_name == "alpha" && member.roles.iter().any(|role| role.name == "writer"))
    );
    let state = database.query_json("RETURN { members: count(SELECT id FROM member_of WHERE in = user:applicant AND out = organization:alpha), codes: count(SELECT id FROM organization_join_code:automatic) }").await?;
    assert_jm!(state, { "members": 1, "codes": 0 });
    Ok(())
}

#[component_test(UserOrganization)]
async fn cancel_request_deletes_and_notifies_both_views(
    context: &mut TestContext<UserOrganization>,
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
        RELATE ONLY user:applicant->request_to_join->organization:alpha;
    "#,
        )
        .await?;
    let id = database
        .query_json("SELECT VALUE id FROM request_to_join WHERE in = user:applicant")
        .await?;
    let key = database_record_key(&id, "request_to_join")?;
    context
        .messaging_mock()?
        .expect_publish("typewriter.to.user.applicant.organization.join_requests.watch");
    context
        .messaging_mock()?
        .expect_publish("typewriter.to.organization.alpha.members.join_requests.watch");
    let request = CancelUserJoinRequestRequest {
        request_id: skir_record_id("request_to_join", &key),
        _unrecognized: None,
    };
    let response = context
        .messaging()?
        .request_skir(
            "typewriter.from.user.applicant.organization.join_requests.cancel",
            &request,
            CancelUserJoinRequestRequest::serializer(),
            CancelUserJoinRequestResponse::serializer(),
            Duration::from_secs(2),
            UnrecognizedValues::Drop,
        )
        .await?;
    assert!(matches!(
        response,
        CancelUserJoinRequestResponse::Success(_)
    ));
    assert_jm!(
        database
            .query_json("SELECT id FROM request_to_join WHERE in = user:applicant")
            .await?,
        []
    );
    Ok(())
}
