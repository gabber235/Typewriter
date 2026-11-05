use json_matcher::assert_jm;
use typewriter_component_test::{
    JoinCode, Organization,
    organization::{
        InvalidMemberUpdate, UnavailableRole, approve_join_requests, expect_join_request_removed,
        join_code_request, role_names, update_member_roles,
    },
    prelude::*,
};
use wasmcloud_utils::skir::base::{
    kernel::v1::duration::Duration as SkirDuration,
    organization::v1::{join_codes::*, join_request::*, member::*, organization::*},
};

/// The names of the roles `$user` holds in Acme.
const ROLES: &str = "SELECT VALUE roles.name FROM ONLY member_of WHERE in = $user AND out = organization:acme FETCH roles";
/// The number of pending join requests.
const PENDING_REQUESTS: &str = "RETURN count(SELECT id FROM request_to_join)";

#[component_fixture(
    id = "organization-members",
    primary(package = "organization-members", target = "organization_members")
)]
pub struct OrganizationMembers;

impl FixtureSpec for OrganizationMembers {
    fn configure(builder: FixtureBuilder<Self>) -> FixtureBuilder<Self> {
        builder
            .messaging_subscriptions(
                wasmcloud_utils::transport_routes::organization_members::SUBSCRIPTIONS,
            )
            .typewriter_streams()
            .otel()
            .typewriter_database(SchemaPreset::Organization)
    }
}

#[component_test(OrganizationMembers)]
async fn generate_join_code_persists_and_publishes(
    context: &mut TestContext<OrganizationMembers>,
) -> TestResult {
    let acme = acme();
    seed_organization(context, &acme, ada(), &[(grace(), &["writer"])]).await?;
    let writer = context.database()?.role(&acme, "writer").await?;
    let expected = writer.clone();
    context.expect_publish(
        to_organization(&acme, "join_codes.changed"),
        move |event: &OrganizationJoinCodesChanged| {
            matches!(event.changes.as_slice(), [OrganizationJoinCodesChange::Add(code)]
                if !code.single_use
                    && code.expires_at.is_none()
                    && code.auto_accept.role_ids == [expected.clone()])
        },
    )?;

    let reply: GenerateOrganizationJoinCodeResponse = context
        .request(
            from_member(ada(), &acme, "members.join_codes.generate"),
            &join_code_request(
                false,
                GenerateOrganizationJoinCodeRequest_Expiration::Never,
                vec![writer],
            ),
        )
        .await?;

    let GenerateOrganizationJoinCodeResponse::Success(generated) = reply else {
        anyhow::bail!("expected join code success, received {reply:?}")
    };
    assert!(!generated.code.single_use);
    assert!(generated.code.expires_at.is_none());
    assert_jm!(
        context
            .database()?
            .query_json("RETURN { count: count(SELECT id FROM organization_join_code), never: (SELECT VALUE expires_at IS NONE OR expires_at IS NULL FROM ONLY organization_join_code) }")
            .await?,
        { "count": 1, "never": true }
    );
    Ok(())
}

#[component_test(OrganizationMembers)]
async fn generate_join_code_rejects_invalid_expiration_without_state(
    context: &mut TestContext<OrganizationMembers>,
) -> TestResult {
    let acme = acme();
    seed_organization(context, &acme, ada(), &[(grace(), &["writer"])]).await?;

    let reply: GenerateOrganizationJoinCodeResponse = context
        .request(
            from_member(ada(), &acme, "members.join_codes.generate"),
            &join_code_request(
                true,
                GenerateOrganizationJoinCodeRequest_Expiration::Duration(Box::new(SkirDuration {
                    milliseconds: 0,
                    ..Default::default()
                })),
                Vec::new(),
            ),
        )
        .await?;

    assert!(
        matches!(
            reply,
            GenerateOrganizationJoinCodeResponse::InvalidExpirationError(_)
        ),
        "{reply:?}"
    );
    assert_jm!(
        context
            .database()?
            .query_json("RETURN count(SELECT id FROM organization_join_code)")
            .await?,
        0
    );
    Ok(())
}

/// A join code may only hand out roles that exist and that members may be given.
#[component_test(OrganizationMembers)]
#[case::missing_role(UnavailableRole::Missing)]
#[case::protected_role(UnavailableRole::Protected)]
async fn join_code_refuses_roles_it_cannot_hand_out(
    context: &mut TestContext<OrganizationMembers>,
    unavailable: UnavailableRole,
) -> TestResult {
    let acme = acme();
    seed_organization(context, &acme, ada(), &[(grace(), &["writer"])]).await?;
    let role = match unavailable {
        UnavailableRole::Missing => skir_record_id("organization_role", "missing"),
        UnavailableRole::Protected => context.database()?.role(&acme, "founder").await?,
    };

    let reply: GenerateOrganizationJoinCodeResponse = context
        .request(
            from_member(ada(), &acme, "members.join_codes.generate"),
            &join_code_request(
                true,
                GenerateOrganizationJoinCodeRequest_Expiration::Never,
                vec![role.clone()],
            ),
        )
        .await?;

    let refused = match (&unavailable, &reply) {
        (
            UnavailableRole::Missing,
            GenerateOrganizationJoinCodeResponse::RolesNotFoundError(error),
        ) => &error.role_ids,
        (
            UnavailableRole::Protected,
            GenerateOrganizationJoinCodeResponse::RolesNotAssignableError(error),
        ) => &error.role_ids,
        _ => anyhow::bail!("{unavailable:?} role was not refused for its reason: {reply:?}"),
    };
    assert_eq!(refused, &[role]);
    assert_jm!(
        context
            .database()?
            .query_json("RETURN count(SELECT id FROM organization_join_code)")
            .await?,
        0
    );
    Ok(())
}

#[component_test(OrganizationMembers)]
async fn revoke_join_code_deletes_and_notifies(
    context: &mut TestContext<OrganizationMembers>,
) -> TestResult {
    let acme = acme();
    seed_organization(context, &acme, ada(), &[(grace(), &["writer"])]).await?;
    let reply: GenerateOrganizationJoinCodeResponse = context
        .arrange(
            from_member(ada(), &acme, "members.join_codes.generate"),
            &join_code_request(
                false,
                GenerateOrganizationJoinCodeRequest_Expiration::Never,
                Vec::new(),
            ),
        )
        .await?;
    let GenerateOrganizationJoinCodeResponse::Success(generated) = reply else {
        anyhow::bail!("expected join code success, received {reply:?}")
    };
    let code = generated.code.code.clone();
    let removed = code.clone();
    context.expect_publish(
        to_organization(&acme, "join_codes.changed"),
        move |event: &OrganizationJoinCodesChanged| {
            matches!(event.changes.as_slice(), [OrganizationJoinCodesChange::Remove(id)] if **id == removed)
        },
    )?;

    let reply: RevokeOrganizationJoinCodeResponse = context
        .request(
            from_member(ada(), &acme, "members.join_codes.revoke"),
            &RevokeOrganizationJoinCodeRequest {
                code_id: code,
                ..Default::default()
            },
        )
        .await?;

    assert!(
        matches!(reply, RevokeOrganizationJoinCodeResponse::Success(_)),
        "{reply:?}"
    );
    assert_jm!(
        context
            .database()?
            .query_json("RETURN count(SELECT id FROM organization_join_code)")
            .await?,
        0
    );
    Ok(())
}

#[component_test(OrganizationMembers)]
async fn revoking_an_unknown_code_is_refused(
    context: &mut TestContext<OrganizationMembers>,
) -> TestResult {
    let acme = acme();
    seed_organization(context, &acme, ada(), &[(grace(), &["writer"])]).await?;
    let unknown = skir_record_id("organization_join_code", "unknown");

    let reply: RevokeOrganizationJoinCodeResponse = context
        .request(
            from_member(ada(), &acme, "members.join_codes.revoke"),
            &RevokeOrganizationJoinCodeRequest {
                code_id: unknown.clone(),
                ..Default::default()
            },
        )
        .await?;

    assert!(
        matches!(&reply, RevokeOrganizationJoinCodeResponse::CodeNotFoundError(error) if error.code_id == unknown),
        "{reply:?}"
    );
    context.expect_no_publish(to_organization(&acme, "join_codes.changed"))?;
    Ok(())
}

#[component_test(OrganizationMembers)]
async fn join_code_watch_lists_only_this_organizations_codes(
    context: &mut TestContext<OrganizationMembers>,
) -> TestResult {
    let acme = acme();
    seed_organization(context, &acme, ada(), &[(grace(), &["writer"])]).await?;
    let globex = Organization::new("globex");
    Seed::new()
        .organization(&globex, grace())
        .join_code(&acme, JoinCode::new("acme_code"))
        .join_code(&globex, JoinCode::new("globex_code"))
        .apply(context)
        .await?;

    let reply: WatchOrganizationJoinCodesResponse = context
        .request(
            from_member(ada(), &acme, "members.join_codes.watch"),
            &WatchOrganizationJoinCodesRequest::default(),
        )
        .await?;

    let WatchOrganizationJoinCodesResponse::Snapshot(snapshot) = reply else {
        anyhow::bail!("expected join code list, received {reply:?}")
    };
    assert_eq!(
        snapshot
            .values
            .iter()
            .map(|code| code.code.key.to_string())
            .collect::<Vec<_>>(),
        ["acme_code"]
    );
    Ok(())
}

#[component_test(OrganizationMembers)]
async fn member_update_keeps_protected_founder_role(
    context: &mut TestContext<OrganizationMembers>,
) -> TestResult {
    let acme = acme();
    seed_organization(context, &acme, ada(), &[(grace(), &["writer"])]).await?;
    let writer = context.database()?.role(&acme, "writer").await?;
    let founder = ada().id();
    context.expect_publish(
        to_organization(&acme, "members.changed"),
        move |event: &OrganizationMembersChanged| {
            matches!(event.changes.as_slice(), [OrganizationMembersChange::Update(member)]
                if member.user_id == founder && role_names(&member.roles) == ["founder", "writer"])
        },
    )?;

    let reply = update_member_roles(context, ada(), &acme, vec![ada().id()], vec![writer]).await?;

    let UpdateOrganizationMemberRolesResponse::Success(updated) = reply else {
        anyhow::bail!("expected member update success, received {reply:?}")
    };
    assert_eq!(role_names(&updated.members[0].roles), ["founder", "writer"]);
    Ok(())
}

/// Each invalid member update is refused for its own reason and changes no member.
#[component_test(OrganizationMembers)]
#[case::missing_role(InvalidMemberUpdate::MissingRole)]
#[case::protected_role(InvalidMemberUpdate::ProtectedRole)]
#[case::missing_user(InvalidMemberUpdate::MissingUser)]
async fn an_invalid_member_update_is_refused_without_changes(
    context: &mut TestContext<OrganizationMembers>,
    invalid: InvalidMemberUpdate,
) -> TestResult {
    let acme = acme();
    seed_organization(context, &acme, ada(), &[(grace(), &["writer"])]).await?;
    let database = context.database()?;
    let writer = database.role(&acme, "writer").await?;
    let founder = database.role(&acme, "founder").await?;
    let missing_role = skir_record_id("organization_role", "missing");
    let missing_user = skir_record_id("user", "missing");

    let (users, roles) = match invalid {
        InvalidMemberUpdate::MissingRole => {
            (vec![grace().id()], vec![writer, missing_role.clone()])
        }
        InvalidMemberUpdate::ProtectedRole => (vec![grace().id()], vec![founder.clone()]),
        InvalidMemberUpdate::MissingUser => (vec![missing_user.clone()], vec![writer]),
    };
    let reply = update_member_roles(context, ada(), &acme, users, roles).await?;

    match (&invalid, &reply) {
        (
            InvalidMemberUpdate::MissingRole,
            UpdateOrganizationMemberRolesResponse::RolesNotFoundError(error),
        ) => {
            assert_eq!(error.role_ids, [missing_role]);
        }
        (
            InvalidMemberUpdate::ProtectedRole,
            UpdateOrganizationMemberRolesResponse::RolesNotAssignableError(error),
        ) => assert_eq!(error.role_ids, [founder]),
        (
            InvalidMemberUpdate::MissingUser,
            UpdateOrganizationMemberRolesResponse::UserNotFoundError(error),
        ) => {
            assert_eq!(error.user_ids, [missing_user]);
        }
        _ => anyhow::bail!("{invalid:?} was not refused for its reason: {reply:?}"),
    }
    assert_jm!(
        context
            .database()?
            .read(ROLES, &[("user", grace().id())])
            .await?,
        ["writer"]
    );
    Ok(())
}

#[component_test(OrganizationMembers)]
async fn an_invalid_member_in_a_batch_leaves_every_member_unchanged(
    context: &mut TestContext<OrganizationMembers>,
) -> TestResult {
    let acme = acme();
    seed_organization(context, &acme, ada(), &[(grace(), &["writer"])]).await?;
    let writer = context.database()?.role(&acme, "writer").await?;

    let reply = update_member_roles(
        context,
        ada(),
        &acme,
        vec![ada().id(), skir_record_id("user", "missing"), grace().id()],
        vec![writer],
    )
    .await?;

    assert!(
        matches!(
            reply,
            UpdateOrganizationMemberRolesResponse::UserNotFoundError(_)
        ),
        "{reply:?}"
    );
    assert_jm!(
        context
            .database()?
            .read(ROLES, &[("user", grace().id())])
            .await?,
        ["writer"]
    );
    assert_jm!(
        context
            .database()?
            .read(ROLES, &[("user", ada().id())])
            .await?,
        ["founder"]
    );
    Ok(())
}

#[component_test(OrganizationMembers)]
async fn founder_cannot_be_removed(context: &mut TestContext<OrganizationMembers>) -> TestResult {
    let acme = acme();
    seed_organization(context, &acme, ada(), &[(grace(), &["writer"])]).await?;

    let reply: RemoveOrganizationMemberResponse = context
        .request(
            from_member(ada(), &acme, "members.remove"),
            &RemoveOrganizationMemberRequest {
                user_id: ada().id(),
                ..Default::default()
            },
        )
        .await?;

    assert!(
        matches!(
            reply,
            RemoveOrganizationMemberResponse::FounderCannotBeRemovedError(_)
        ),
        "{reply:?}"
    );
    assert_jm!(
        context
            .database()?
            .read(ROLES, &[("user", ada().id())])
            .await?,
        ["founder"]
    );
    Ok(())
}

#[component_test(OrganizationMembers)]
async fn removing_a_member_ends_the_membership_and_tells_both_views(
    context: &mut TestContext<OrganizationMembers>,
) -> TestResult {
    let acme = acme();
    seed_organization(context, &acme, ada(), &[(grace(), &["writer"])]).await?;
    let removed = grace().id();
    context.expect_publish(
        to_organization(&acme, "members.changed"),
        move |event: &OrganizationMembersChanged| {
            matches!(event.changes.as_slice(), [OrganizationMembersChange::Remove(id)] if **id == removed)
        },
    )?;
    let removed = acme.id();
    context.expect_publish(
        to_user(grace(), "organizations.changed"),
        move |event: &UserOrganizationsChanged| {
            matches!(event.changes.as_slice(), [UserOrganizationsChange::Remove(id)] if **id == removed)
        },
    )?;

    let reply: RemoveOrganizationMemberResponse = context
        .request(
            from_member(ada(), &acme, "members.remove"),
            &RemoveOrganizationMemberRequest {
                user_id: grace().id(),
                ..Default::default()
            },
        )
        .await?;

    assert!(
        matches!(reply, RemoveOrganizationMemberResponse::Success(_)),
        "{reply:?}"
    );
    assert_jm!(
        context
            .database()?
            .query_json("RETURN count(SELECT id FROM member_of WHERE in = user:user_grace)")
            .await?,
        0
    );
    Ok(())
}

#[component_test(OrganizationMembers)]
async fn removing_someone_who_is_not_a_member_is_refused(
    context: &mut TestContext<OrganizationMembers>,
) -> TestResult {
    let acme = acme();
    seed_organization(context, &acme, ada(), &[(grace(), &["writer"])]).await?;
    let hedy = StackUser::new("hedy");
    Seed::new().user(&hedy).apply(context).await?;

    let reply: RemoveOrganizationMemberResponse = context
        .request(
            from_member(ada(), &acme, "members.remove"),
            &RemoveOrganizationMemberRequest {
                user_id: hedy.id(),
                ..Default::default()
            },
        )
        .await?;

    assert!(
        matches!(&reply, RemoveOrganizationMemberResponse::UserNotMemberError(error) if error.user_id == hedy.id()),
        "{reply:?}"
    );
    context.expect_no_publish(to_organization(&acme, "members.changed"))?;
    Ok(())
}

#[component_test(OrganizationMembers)]
async fn approval_makes_the_applicant_a_member_and_tells_both_views(
    context: &mut TestContext<OrganizationMembers>,
) -> TestResult {
    let acme = acme();
    seed_organization(context, &acme, ada(), &[]).await?;
    let request = seed_join_request(context, grace(), &acme).await?;
    let writer = context.database()?.role(&acme, "writer").await?;
    expect_join_request_removed(context, &acme, grace(), &request)?;
    let applicant = grace().id();
    context.expect_publish(
        to_organization(&acme, "members.changed"),
        move |event: &OrganizationMembersChanged| {
            matches!(event.changes.as_slice(), [OrganizationMembersChange::Add(member)]
                if member.user_id == applicant && role_names(&member.roles) == ["writer"])
        },
    )?;
    let joined = acme.id();
    context.expect_publish(
        to_user(grace(), "organizations.changed"),
        move |event: &UserOrganizationsChanged| {
            matches!(event.changes.as_slice(), [UserOrganizationsChange::Add(organization)]
                if organization.organization_id == joined)
        },
    )?;

    let reply = approve_join_requests(context, ada(), &acme, vec![request], vec![writer]).await?;

    assert!(
        matches!(&reply, ApproveOrganizationJoinRequestsResponse::Success(success)
            if success.approvals.len() == 1 && success.approvals[0].member.user_id == grace().id()),
        "{reply:?}"
    );
    assert_jm!(
        context
            .database()?
            .read(ROLES, &[("user", grace().id())])
            .await?,
        ["writer"]
    );
    assert_jm!(context.database()?.query_json(PENDING_REQUESTS).await?, 0);
    Ok(())
}

#[component_test(OrganizationMembers)]
async fn approve_existing_member_rolls_back_request_deletion(
    context: &mut TestContext<OrganizationMembers>,
) -> TestResult {
    let acme = acme();
    seed_organization(context, &acme, ada(), &[(grace(), &["writer"])]).await?;
    let database = context.database()?;
    let request = seed_join_request(context, grace(), &acme).await?;
    let writer = database.role(&acme, "writer").await?;

    let reply = approve_join_requests(context, ada(), &acme, vec![request], vec![writer]).await?;

    assert!(
        matches!(
            reply,
            ApproveOrganizationJoinRequestsResponse::UserAlreadyMemberError(_)
        ),
        "{reply:?}"
    );
    assert_jm!(context.database()?.query_json(PENDING_REQUESTS).await?, 1);
    Ok(())
}

#[component_test(OrganizationMembers)]
async fn approval_uses_current_role_policy_inside_transaction(
    context: &mut TestContext<OrganizationMembers>,
) -> TestResult {
    let acme = acme();
    seed_organization(context, &acme, ada(), &[]).await?;
    let request = seed_join_request(context, grace(), &acme).await?;
    let database = context.database()?;
    let writer = database.role(&acme, "writer").await?;
    Seed::new()
        .unassignable(&acme, "writer")
        .apply(context)
        .await?;

    let reply =
        approve_join_requests(context, ada(), &acme, vec![request], vec![writer.clone()]).await?;

    let ApproveOrganizationJoinRequestsResponse::RolesNotAssignableError(error) = reply else {
        anyhow::bail!("expected current role policy error, received {reply:?}")
    };
    assert_eq!(error.role_ids, [writer]);
    assert_jm!(context.database()?.query_json(PENDING_REQUESTS).await?, 1);
    assert_jm!(
        database
            .query_json("RETURN count(SELECT id FROM member_of WHERE in = user:user_grace)")
            .await?,
        0
    );
    Ok(())
}

#[component_test(OrganizationMembers)]
async fn decline_request_deletes_and_notifies_both_views(
    context: &mut TestContext<OrganizationMembers>,
) -> TestResult {
    let acme = acme();
    seed_organization(context, &acme, ada(), &[]).await?;
    let request = seed_join_request(context, grace(), &acme).await?;
    expect_join_request_removed(context, &acme, grace(), &request)?;

    let reply: DeclineOrganizationJoinRequestResponse = context
        .request(
            from_member(ada(), &acme, "members.join_requests.decline"),
            &DeclineOrganizationJoinRequestRequest {
                request_id: request,
                ..Default::default()
            },
        )
        .await?;

    assert!(
        matches!(reply, DeclineOrganizationJoinRequestResponse::Success(_)),
        "{reply:?}"
    );
    assert_jm!(context.database()?.query_json(PENDING_REQUESTS).await?, 0);
    Ok(())
}

#[component_test(OrganizationMembers)]
async fn declining_an_unknown_request_is_refused(
    context: &mut TestContext<OrganizationMembers>,
) -> TestResult {
    let acme = acme();
    seed_organization(context, &acme, ada(), &[(grace(), &["writer"])]).await?;
    let unknown = skir_record_id("request_to_join", "unknown");

    let reply: DeclineOrganizationJoinRequestResponse = context
        .request(
            from_member(ada(), &acme, "members.join_requests.decline"),
            &DeclineOrganizationJoinRequestRequest {
                request_id: unknown.clone(),
                ..Default::default()
            },
        )
        .await?;

    assert!(
        matches!(&reply, DeclineOrganizationJoinRequestResponse::RequestNotFoundError(error) if error.request_id == unknown),
        "{reply:?}"
    );
    context.expect_no_publish(to_organization(&acme, "join_requests.changed"))?;
    Ok(())
}

#[component_test(OrganizationMembers)]
async fn join_request_watch_lists_only_this_organizations_requests(
    context: &mut TestContext<OrganizationMembers>,
) -> TestResult {
    let acme = acme();
    seed_organization(context, &acme, ada(), &[]).await?;
    let request = seed_join_request(context, grace(), &acme).await?;
    let globex = Organization::new("globex");
    let hedy = StackUser::new("hedy");
    Seed::new()
        .organization(&globex, &hedy)
        .join_request(grace(), &globex)
        .apply(context)
        .await?;

    let reply: WatchOrganizationJoinRequestsResponse = context
        .request(
            from_member(ada(), &acme, "members.join_requests.watch"),
            &WatchOrganizationJoinRequestsRequest::default(),
        )
        .await?;

    let WatchOrganizationJoinRequestsResponse::Snapshot(snapshot) = reply else {
        anyhow::bail!("expected join request list, received {reply:?}")
    };
    assert_eq!(
        snapshot
            .values
            .iter()
            .map(|value| &value.request_id)
            .collect::<Vec<_>>(),
        [&request]
    );
    Ok(())
}
