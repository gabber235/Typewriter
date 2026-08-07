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
    skir::base::{
        kernel::v1::duration::Duration as SkirDuration,
        organization::v1::{join_codes::*, join_request::*, member::*},
    },
    skir_client::UnrecognizedValues,
};

#[component_fixture(
    id = "organization-members",
    primary(package = "organization-members", target = "organization_members"),
    affected_paths(
        "backend/organization/organization-members/",
        "backend/database/schema/organization/"
    )
)]
pub struct OrganizationMembers;

impl FixtureSpec for OrganizationMembers {
    fn configure(builder: FixtureBuilder<Self>) -> FixtureBuilder<Self> {
        builder
            .messaging_subscription("typewriter.from.user.*.organization.*.members.>")
            .otel()
            .typewriter_database(SchemaPreset::Organization)
    }
}

async fn seed_organization(database: &DatabaseHandle) -> anyhow::Result<()> {
    database
        .execute(
            r#"
            CREATE user:founder SET name = 'founder';
            CREATE user:member SET name = 'member';
            CREATE user:applicant SET name = 'applicant';
            CREATE organization:alpha SET name = 'alpha', founder = user:founder;
            LET $writer = SELECT VALUE id FROM ONLY organization_role
                WHERE organization = organization:alpha AND name = 'writer';
            RELATE user:member->member_of->organization:alpha SET roles = [$writer];
            "#,
        )
        .await?;
    Ok(())
}

async fn role_key(database: &DatabaseHandle, name: &str) -> anyhow::Result<String> {
    let value = database
        .seed(
            "SELECT VALUE id FROM organization_role WHERE organization = organization:alpha AND name = $name",
        )
        .bind("name", name)?
        .query_json()
        .await?;
    database_record_key(&value, "organization_role")
}

#[component_test(OrganizationMembers)]
async fn generate_join_code_persists_and_publishes(
    context: &mut TestContext<OrganizationMembers>,
) -> TestResult {
    let database = context
        .extension::<DatabaseHandle>()
        .ok_or_else(|| anyhow::anyhow!("database handle missing"))?;
    seed_organization(&database).await?;
    let writer_id = database
        .query_json(
            "SELECT VALUE id FROM organization_role WHERE organization = organization:alpha AND name = 'writer'",
        )
        .await?;
    let writer_key = database_record_key(&writer_id, "organization_role")?;
    let expected_writer_key = writer_key.clone();

    context
        .messaging_mock()?
        .expect_publish("typewriter.to.organization.alpha.members.join_codes.watch")
        .body_matches(move |body| {
            matches!(
                WatchOrganizationJoinCodesResponse::serializer().from_bytes(
                    body,
                    UnrecognizedValues::Drop,
                ),
                Ok(WatchOrganizationJoinCodesResponse::Add(code))
                    if !code.single_use
                        && code.expires_at.is_none()
                        && code.auto_accept.role_ids.len() == 1
                        && code.auto_accept.role_ids[0].key.to_string() == expected_writer_key
            )
        });

    let request = GenerateOrganizationJoinCodeRequest {
        single_use: false,
        expiration: GenerateOrganizationJoinCodeRequest_Expiration::Never,
        auto_accept: GenerateOrganizationJoinCodeRequest_AutoAccept {
            role_ids: vec![skir_record_id("organization_role", &writer_key)],
            _unrecognized: None,
        },
        _unrecognized: None,
    };
    let response = context
        .messaging()?
        .request_skir(
            "typewriter.from.user.founder.organization.alpha.members.join_codes.generate",
            &request,
            GenerateOrganizationJoinCodeRequest::serializer(),
            GenerateOrganizationJoinCodeResponse::serializer(),
            Duration::from_secs(2),
            UnrecognizedValues::Drop,
        )
        .await?;

    assert!(
        matches!(response, GenerateOrganizationJoinCodeResponse::Success(code) if !code.single_use && code.expires_at.is_none())
    );
    let codes = database
        .query_json("RETURN count(SELECT id FROM organization_join_code)")
        .await?;
    assert_jm!(codes, 1);
    Ok(())
}

#[component_test(OrganizationMembers)]
async fn generate_join_code_rejects_invalid_expiration_without_state(
    context: &mut TestContext<OrganizationMembers>,
) -> TestResult {
    let database = context
        .extension::<DatabaseHandle>()
        .ok_or_else(|| anyhow::anyhow!("database handle missing"))?;
    seed_organization(&database).await?;
    let request = GenerateOrganizationJoinCodeRequest {
        single_use: true,
        expiration: GenerateOrganizationJoinCodeRequest_Expiration::Duration(Box::new(
            SkirDuration {
                milliseconds: 0,
                _unrecognized: None,
            },
        )),
        auto_accept: GenerateOrganizationJoinCodeRequest_AutoAccept::default(),
        _unrecognized: None,
    };

    let response = context
        .messaging()?
        .request_skir(
            "typewriter.from.user.founder.organization.alpha.members.join_codes.generate",
            &request,
            GenerateOrganizationJoinCodeRequest::serializer(),
            GenerateOrganizationJoinCodeResponse::serializer(),
            Duration::from_secs(2),
            UnrecognizedValues::Drop,
        )
        .await?;

    assert!(matches!(
        response,
        GenerateOrganizationJoinCodeResponse::InvalidExpirationError(_)
    ));
    let codes = database
        .query_json("SELECT id FROM organization_join_code")
        .await?;
    assert_jm!(codes, []);
    Ok(())
}

#[component_test(OrganizationMembers)]
async fn member_update_keeps_protected_founder_role(
    context: &mut TestContext<OrganizationMembers>,
) -> TestResult {
    let database = context
        .extension::<DatabaseHandle>()
        .ok_or_else(|| anyhow::anyhow!("database handle missing"))?;
    seed_organization(&database).await?;
    let writer_id = database
        .query_json(
            "SELECT VALUE id FROM organization_role WHERE organization = organization:alpha AND name = 'writer'",
        )
        .await?;
    let writer_key = database_record_key(&writer_id, "organization_role")?;

    context
        .messaging_mock()?
        .expect_publish("typewriter.to.organization.alpha.members.watch")
        .body_matches(|body| {
            let Ok(WatchOrganizationMembersResponse::Update(member)) =
                WatchOrganizationMembersResponse::serializer()
                    .from_bytes(body, UnrecognizedValues::Drop)
            else {
                return false;
            };
            let mut names = member
                .roles
                .iter()
                .map(|role| role.name.as_str())
                .collect::<Vec<_>>();
            names.sort_unstable();
            member.user_id.key.to_string() == "founder" && names == ["founder", "writer"]
        });

    let request = UpdateOrganizationMemberRolesRequest {
        user_id: skir_record_id("user", "founder"),
        role_ids: vec![skir_record_id("organization_role", &writer_key)],
        _unrecognized: None,
    };
    let response = context
        .messaging()?
        .request_skir(
            "typewriter.from.user.founder.organization.alpha.members.update",
            &request,
            UpdateOrganizationMemberRolesRequest::serializer(),
            UpdateOrganizationMemberRolesResponse::serializer(),
            Duration::from_secs(2),
            UnrecognizedValues::Drop,
        )
        .await?;

    let UpdateOrganizationMemberRolesResponse::Success(member) = response else {
        anyhow::bail!("expected member update success, received {response:?}")
    };
    let mut names = member
        .roles
        .iter()
        .map(|role| role.name.as_str())
        .collect::<Vec<_>>();
    names.sort_unstable();
    assert_eq!(names, ["founder", "writer"]);
    Ok(())
}

#[component_test(OrganizationMembers)]
async fn member_update_returns_precise_validation_errors_without_state_changes(
    context: &mut TestContext<OrganizationMembers>,
) -> TestResult {
    let database = context
        .extension::<DatabaseHandle>()
        .ok_or_else(|| anyhow::anyhow!("database handle missing"))?;
    seed_organization(&database).await?;
    let writer = role_key(&database, "writer").await?;
    let founder = role_key(&database, "founder").await?;

    let response = context
        .messaging()?
        .request_skir(
            "typewriter.from.user.founder.organization.alpha.members.update",
            &UpdateOrganizationMemberRolesRequest {
                user_id: skir_record_id("user", "member"),
                role_ids: vec![
                    skir_record_id("organization_role", &writer),
                    skir_record_id("organization_role", "missing"),
                ],
                _unrecognized: None,
            },
            UpdateOrganizationMemberRolesRequest::serializer(),
            UpdateOrganizationMemberRolesResponse::serializer(),
            Duration::from_secs(2),
            UnrecognizedValues::Drop,
        )
        .await?;
    let UpdateOrganizationMemberRolesResponse::RolesNotFoundError(error) = response else {
        anyhow::bail!("expected missing role error, received {response:?}")
    };
    assert_eq!(error.role_ids.len(), 1);
    assert_eq!(error.role_ids[0].key.to_string(), "missing");

    let response = context
        .messaging()?
        .request_skir(
            "typewriter.from.user.founder.organization.alpha.members.update",
            &UpdateOrganizationMemberRolesRequest {
                user_id: skir_record_id("user", "member"),
                role_ids: vec![skir_record_id("organization_role", &founder)],
                _unrecognized: None,
            },
            UpdateOrganizationMemberRolesRequest::serializer(),
            UpdateOrganizationMemberRolesResponse::serializer(),
            Duration::from_secs(2),
            UnrecognizedValues::Drop,
        )
        .await?;
    let UpdateOrganizationMemberRolesResponse::RolesNotAssignableError(error) = response else {
        anyhow::bail!("expected protected role error, received {response:?}")
    };
    assert_eq!(error.role_ids.len(), 1);
    assert_eq!(error.role_ids[0].key.to_string(), founder);

    let response = context
        .messaging()?
        .request_skir(
            "typewriter.from.user.founder.organization.alpha.members.update",
            &UpdateOrganizationMemberRolesRequest {
                user_id: skir_record_id("user", "missing"),
                role_ids: vec![skir_record_id("organization_role", &writer)],
                _unrecognized: None,
            },
            UpdateOrganizationMemberRolesRequest::serializer(),
            UpdateOrganizationMemberRolesResponse::serializer(),
            Duration::from_secs(2),
            UnrecognizedValues::Drop,
        )
        .await?;
    assert!(matches!(
        response,
        UpdateOrganizationMemberRolesResponse::UserNotFoundError(_)
    ));
    assert_jm!(
        database
            .query_json(
                "SELECT VALUE roles.name FROM ONLY member_of WHERE in = user:member AND out = organization:alpha FETCH roles"
            )
            .await?,
        ["writer"]
    );
    Ok(())
}

#[component_test(OrganizationMembers)]
async fn join_code_rejects_missing_and_protected_roles(
    context: &mut TestContext<OrganizationMembers>,
) -> TestResult {
    let database = context
        .extension::<DatabaseHandle>()
        .ok_or_else(|| anyhow::anyhow!("database handle missing"))?;
    seed_organization(&database).await?;
    let founder = role_key(&database, "founder").await?;

    for (role, expected_assignable) in [("missing".to_string(), false), (founder, true)] {
        let request = GenerateOrganizationJoinCodeRequest {
            single_use: true,
            expiration: GenerateOrganizationJoinCodeRequest_Expiration::Never,
            auto_accept: GenerateOrganizationJoinCodeRequest_AutoAccept {
                role_ids: vec![skir_record_id("organization_role", &role)],
                _unrecognized: None,
            },
            _unrecognized: None,
        };
        let response = context
            .messaging()?
            .request_skir(
                "typewriter.from.user.founder.organization.alpha.members.join_codes.generate",
                &request,
                GenerateOrganizationJoinCodeRequest::serializer(),
                GenerateOrganizationJoinCodeResponse::serializer(),
                Duration::from_secs(2),
                UnrecognizedValues::Drop,
            )
            .await?;
        assert!(if expected_assignable {
            matches!(
                response,
                GenerateOrganizationJoinCodeResponse::RolesNotAssignableError(_)
            )
        } else {
            matches!(
                response,
                GenerateOrganizationJoinCodeResponse::RolesNotFoundError(_)
            )
        });
    }
    assert_jm!(
        database
            .query_json("SELECT id FROM organization_join_code")
            .await?,
        []
    );
    Ok(())
}

#[component_test(OrganizationMembers)]
async fn revoke_join_code_deletes_and_notifies(
    context: &mut TestContext<OrganizationMembers>,
) -> TestResult {
    let database = context
        .extension::<DatabaseHandle>()
        .ok_or_else(|| anyhow::anyhow!("database handle missing"))?;
    seed_organization(&database).await?;
    database.execute("CREATE organization_join_code:invite SET organization = organization:alpha, single_use = false, auto_accept_roles = [], expires_at = NONE").await?;
    context.messaging_mock()?.expect_publish("typewriter.to.organization.alpha.members.join_codes.watch").body_matches(|body| {
        matches!(WatchOrganizationJoinCodesResponse::serializer().from_bytes(body, UnrecognizedValues::Drop), Ok(WatchOrganizationJoinCodesResponse::Remove(code)) if code.key.to_string() == "invite")
    });
    let request = RevokeOrganizationJoinCodeRequest {
        code_id: skir_record_id("organization_join_code", "invite"),
        _unrecognized: None,
    };
    let response = context
        .messaging()?
        .request_skir(
            "typewriter.from.user.founder.organization.alpha.members.join_codes.revoke",
            &request,
            RevokeOrganizationJoinCodeRequest::serializer(),
            RevokeOrganizationJoinCodeResponse::serializer(),
            Duration::from_secs(2),
            UnrecognizedValues::Drop,
        )
        .await?;
    assert!(matches!(
        response,
        RevokeOrganizationJoinCodeResponse::Success(_)
    ));
    assert_jm!(
        database
            .query_json("SELECT id FROM organization_join_code:invite")
            .await?,
        []
    );
    Ok(())
}

#[component_test(OrganizationMembers)]
async fn founder_cannot_be_removed(context: &mut TestContext<OrganizationMembers>) -> TestResult {
    let database = context
        .extension::<DatabaseHandle>()
        .ok_or_else(|| anyhow::anyhow!("database handle missing"))?;
    seed_organization(&database).await?;
    let request = RemoveOrganizationMemberRequest {
        user_id: skir_record_id("user", "founder"),
        _unrecognized: None,
    };
    let response = context
        .messaging()?
        .request_skir(
            "typewriter.from.user.founder.organization.alpha.members.remove",
            &request,
            RemoveOrganizationMemberRequest::serializer(),
            RemoveOrganizationMemberResponse::serializer(),
            Duration::from_secs(2),
            UnrecognizedValues::Drop,
        )
        .await?;
    assert!(matches!(
        response,
        RemoveOrganizationMemberResponse::FounderCannotBeRemovedError(_)
    ));
    assert_jm!(
        database
            .query_json(
                "RETURN count(SELECT id FROM member_of WHERE in = user:founder AND out = organization:alpha)"
            )
            .await?,
        1
    );
    Ok(())
}

#[component_test(OrganizationMembers)]
async fn approve_request_atomically_creates_member_and_removes_request(
    context: &mut TestContext<OrganizationMembers>,
) -> TestResult {
    let database = context
        .extension::<DatabaseHandle>()
        .ok_or_else(|| anyhow::anyhow!("database handle missing"))?;
    seed_organization(&database).await?;
    database
        .execute("RELATE ONLY user:applicant->request_to_join->organization:alpha")
        .await?;
    let request_id = database
        .query_json("SELECT VALUE id FROM request_to_join WHERE in = user:applicant")
        .await?;
    let request_key = database_record_key(&request_id, "request_to_join")?;
    let writer = role_key(&database, "writer").await?;
    for subject in [
        "typewriter.to.organization.alpha.members.join_requests.watch",
        "typewriter.to.user.applicant.organization.join_requests.watch",
        "typewriter.to.organization.alpha.members.watch",
        "typewriter.to.user.applicant.organization.watch",
    ] {
        context.messaging_mock()?.expect_publish(subject);
    }
    let request = ApproveOrganizationJoinRequestRequest {
        request_id: skir_record_id("request_to_join", &request_key),
        role_ids: vec![skir_record_id("organization_role", &writer)],
        _unrecognized: None,
    };
    let response = context
        .messaging()?
        .request_skir(
            "typewriter.from.user.founder.organization.alpha.members.join_requests.approve",
            &request,
            ApproveOrganizationJoinRequestRequest::serializer(),
            ApproveOrganizationJoinRequestResponse::serializer(),
            Duration::from_secs(2),
            UnrecognizedValues::Drop,
        )
        .await?;
    assert!(
        matches!(response, ApproveOrganizationJoinRequestResponse::Success(member) if member.user_id.key.to_string() == "applicant")
    );
    let state = database.query_json("RETURN { members: count(SELECT id FROM member_of WHERE in = user:applicant AND out = organization:alpha), requests: count(SELECT id FROM request_to_join WHERE in = user:applicant) }").await?;
    assert_jm!(state, { "members": 1, "requests": 0 });
    Ok(())
}

#[component_test(OrganizationMembers)]
async fn approve_existing_member_rolls_back_request_deletion(
    context: &mut TestContext<OrganizationMembers>,
) -> TestResult {
    let database = context
        .extension::<DatabaseHandle>()
        .ok_or_else(|| anyhow::anyhow!("database handle missing"))?;
    seed_organization(&database).await?;
    database
        .execute("RELATE ONLY user:member->request_to_join->organization:alpha")
        .await?;
    let request_id = database
        .query_json("SELECT VALUE id FROM request_to_join WHERE in = user:member")
        .await?;
    let request_key = database_record_key(&request_id, "request_to_join")?;
    let writer = role_key(&database, "writer").await?;
    let request = ApproveOrganizationJoinRequestRequest {
        request_id: skir_record_id("request_to_join", &request_key),
        role_ids: vec![skir_record_id("organization_role", &writer)],
        _unrecognized: None,
    };
    let response = context
        .messaging()?
        .request_skir(
            "typewriter.from.user.founder.organization.alpha.members.join_requests.approve",
            &request,
            ApproveOrganizationJoinRequestRequest::serializer(),
            ApproveOrganizationJoinRequestResponse::serializer(),
            Duration::from_secs(2),
            UnrecognizedValues::Drop,
        )
        .await?;
    assert!(matches!(
        response,
        ApproveOrganizationJoinRequestResponse::UserAlreadyMemberError(_)
    ));
    assert_jm!(
        database
            .query_json("RETURN count(SELECT id FROM request_to_join WHERE in = user:member)")
            .await?,
        1
    );
    Ok(())
}

#[component_test(OrganizationMembers)]
async fn decline_request_deletes_and_notifies_both_views(
    context: &mut TestContext<OrganizationMembers>,
) -> TestResult {
    let database = context
        .extension::<DatabaseHandle>()
        .ok_or_else(|| anyhow::anyhow!("database handle missing"))?;
    seed_organization(&database).await?;
    database
        .execute("RELATE ONLY user:applicant->request_to_join->organization:alpha")
        .await?;
    let request_id = database
        .query_json("SELECT VALUE id FROM request_to_join WHERE in = user:applicant")
        .await?;
    let request_key = database_record_key(&request_id, "request_to_join")?;
    context
        .messaging_mock()?
        .expect_publish("typewriter.to.organization.alpha.members.join_requests.watch");
    context
        .messaging_mock()?
        .expect_publish("typewriter.to.user.applicant.organization.join_requests.watch");
    let request = DeclineOrganizationJoinRequestRequest {
        request_id: skir_record_id("request_to_join", &request_key),
        _unrecognized: None,
    };
    let response = context
        .messaging()?
        .request_skir(
            "typewriter.from.user.founder.organization.alpha.members.join_requests.decline",
            &request,
            DeclineOrganizationJoinRequestRequest::serializer(),
            DeclineOrganizationJoinRequestResponse::serializer(),
            Duration::from_secs(2),
            UnrecognizedValues::Drop,
        )
        .await?;
    assert!(matches!(
        response,
        DeclineOrganizationJoinRequestResponse::Success(_)
    ));
    assert_jm!(
        database
            .query_json("SELECT id FROM request_to_join WHERE in = user:applicant")
            .await?,
        []
    );
    Ok(())
}
