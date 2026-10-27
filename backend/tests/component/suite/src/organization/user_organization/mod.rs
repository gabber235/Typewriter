use json_matcher::assert_jm;
use typewriter_component_test::prelude::{JoinCode, Organization, *};
use wasmcloud_utils::skir::base::organization::v1::{
    join_codes::*, join_request::*, member::*, organization::*, user::*,
};

#[component_fixture(
    id = "user-organization",
    primary(package = "user-organization", target = "user_organization")
)]
pub struct UserOrganization;

impl FixtureSpec for UserOrganization {
    fn configure(builder: FixtureBuilder<Self>) -> FixtureBuilder<Self> {
        builder
            .messaging_subscriptions(
                wasmcloud_utils::transport_routes::user_organization::SUBSCRIPTIONS,
            )
            .typewriter_streams()
            .otel()
            .typewriter_database(SchemaPreset::Organization)
    }
}

type Context = TestContext<UserOrganization>;

/// `founder` founds an organization through the component, as the panel does.
async fn found(context: &Context, founder: &StackUser, name: &str) -> anyhow::Result<Organization> {
    Seed::new()
        .user(founder)
        .apply(&context.database()?)
        .await?;
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

/// Ada founds Acme, which gets a join code that the component cannot create itself, and Grace
/// signs in so she can use it.
async fn acme_with_code(context: &Context, code: JoinCode) -> anyhow::Result<Organization> {
    let acme = found(context, ada(), "acme").await?;
    Seed::new()
        .user(grace())
        .join_code(&acme, code)
        .apply(&context.database()?)
        .await?;
    Ok(acme)
}

fn code(key: &str) -> wasmcloud_utils::skir::base::kernel::v1::record_id::RecordId {
    skir_record_id("organization_join_code", key)
}

async fn submit(
    context: &Context,
    user: &StackUser,
    key: &str,
) -> anyhow::Result<SubmitUserJoinRequestResponse> {
    context
        .request(
            from_user(user, "organization.join_requests.request"),
            &SubmitUserJoinRequestRequest {
                code: code(key),
                ..Default::default()
            },
        )
        .await
}

/// Grace's organization list and Acme's member list both learn that she joined as a writer.
fn expect_grace_joins_as_writer(context: &Context, acme: &Organization) -> anyhow::Result<()> {
    context.expect_publish(
        to_user(grace(), "organizations.changed"),
        |event: &UserOrganizationsChanged| {
            matches!(event.changes.as_slice(), [UserOrganizationsChange::Add(organization)] if organization.name == "acme")
        },
    )?;
    context.expect_publish(
        to_organization(acme, "members.changed"),
        |event: &OrganizationMembersChanged| {
            matches!(event.changes.as_slice(), [OrganizationMembersChange::Add(member)]
                if member.user_id.key.to_string() == grace().subject
                    && member.roles.iter().any(|role| role.name == "writer"))
        },
    )?;
    Ok(())
}

/// Counts the requests and memberships `user` holds.
async fn standing(context: &Context, user: &StackUser) -> anyhow::Result<serde_json::Value> {
    context
        .database()?
        .seed("RETURN { requests: count(SELECT id FROM request_to_join WHERE in = $user), members: count(SELECT id FROM member_of WHERE in = $user) }")
        .bind("user", surrealdb_types::RecordId::from(user.id()))?
        .query_json()
        .await
}

#[component_test(UserOrganization)]
async fn creating_an_organization_makes_the_founder_its_only_founder(
    context: &mut Context,
) -> TestResult {
    Seed::new().user(ada()).apply(&context.database()?).await?;
    context.expect_publish(
        to_user(ada(), "organizations.changed"),
        |event: &UserOrganizationsChanged| {
            matches!(event.changes.as_slice(), [UserOrganizationsChange::Add(organization)]
                if organization.name == "acme"
                    && organization.logo_url == "https://example.com/acme.png")
        },
    )?;

    let reply: CreateOrganizationResponse = context
        .request(
            from_user(ada(), "organization.create"),
            &CreateOrganizationRequest {
                name: "acme".to_owned(),
                logo_url: Some("https://example.com/acme.png".to_owned()),
                ..Default::default()
            },
        )
        .await?;

    let CreateOrganizationResponse::Success(success) = reply else {
        anyhow::bail!("unexpected create organization reply: {reply:?}")
    };
    assert_eq!(success.organization.name, "acme");
    let state = context
        .database()?
        .seed(
            "RETURN {
                role_names: array::sort(SELECT VALUE name FROM organization_role WHERE organization = $organization),
                founder_roles: array::sort(SELECT VALUE roles.name FROM member_of WHERE in = $founder AND out = $organization)[0]
            }",
        )
        .bind(
            "organization",
            surrealdb_types::RecordId::from(success.organization.organization_id.clone()),
        )?
        .bind("founder", surrealdb_types::RecordId::from(ada().id()))?
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
    context: &mut Context,
) -> TestResult {
    let acme = acme_with_code(context, JoinCode::new("invite").single_use().expiring()).await?;
    let key = acme.key.clone();
    context.expect_publish(
        to_user(grace(), "join_requests.changed"),
        move |event: &UserJoinRequestsChanged| {
            matches!(event.changes.as_slice(), [UserJoinRequestsChange::Add(request)]
                if request.organization_name == "acme"
                    && request.organization_id.key.to_string() == key)
        },
    )?;
    context.expect_publish(
        to_organization(&acme, "join_requests.changed"),
        |event: &OrganizationJoinRequestsChanged| {
            matches!(event.changes.as_slice(), [OrganizationJoinRequestsChange::Add(request)]
                if request.user_id.key.to_string() == grace().subject
                    && request.user_name.as_deref() == Some("grace"))
        },
    )?;
    context.expect_publish(
        to_organization(&acme, "join_codes.changed"),
        |event: &OrganizationJoinCodesChanged| {
            matches!(event.changes.as_slice(), [OrganizationJoinCodesChange::Remove(code)]
                if code.key.to_string() == "invite")
        },
    )?;

    let reply = submit(context, grace(), "invite").await?;

    assert!(
        matches!(&reply, SubmitUserJoinRequestResponse::RequestMade(made) if made.request.organization_name == "acme"),
        "{reply:?}"
    );
    assert_jm!(standing(context, grace()).await?, { "requests": 1, "members": 0 });
    assert_jm!(
        context
            .database()?
            .query_json("RETURN count(SELECT id FROM organization_join_code)")
            .await?,
        0
    );
    Ok(())
}

#[component_test(UserOrganization)]
async fn expired_join_code_is_refused(context: &mut Context) -> TestResult {
    acme_with_code(context, JoinCode::new("old").expired()).await?;

    let reply = submit(context, grace(), "old").await?;

    assert!(
        matches!(&reply, SubmitUserJoinRequestResponse::CodeNotFoundError(error) if error.code == code("old")),
        "{reply:?}"
    );
    assert_jm!(standing(context, grace()).await?, { "requests": 0, "members": 0 });
    Ok(())
}

#[component_test(UserOrganization)]
async fn a_used_single_use_code_is_refused_to_the_next_person(context: &mut Context) -> TestResult {
    acme_with_code(context, JoinCode::new("invite").single_use().expiring()).await?;
    let hedy = StackUser::new("hedy");
    Seed::new().user(&hedy).apply(&context.database()?).await?;
    let first: SubmitUserJoinRequestResponse = context
        .arrange(
            from_user(grace(), "organization.join_requests.request"),
            &SubmitUserJoinRequestRequest {
                code: code("invite"),
                ..Default::default()
            },
        )
        .await?;
    assert!(
        matches!(first, SubmitUserJoinRequestResponse::RequestMade(_)),
        "{first:?}"
    );

    let reply = submit(context, &hedy, "invite").await?;

    assert!(
        matches!(&reply, SubmitUserJoinRequestResponse::CodeNotFoundError(error) if error.code == code("invite")),
        "{reply:?}"
    );
    assert_jm!(standing(context, &hedy).await?, { "requests": 0, "members": 0 });
    Ok(())
}

#[component_test(UserOrganization)]
async fn joining_again_after_an_automatic_join_is_refused(context: &mut Context) -> TestResult {
    acme_with_code(
        context,
        JoinCode::new("automatic")
            .auto_accept(&["writer"])
            .expiring(),
    )
    .await?;
    let first: SubmitUserJoinRequestResponse = context
        .arrange(
            from_user(grace(), "organization.join_requests.request"),
            &SubmitUserJoinRequestRequest {
                code: code("automatic"),
                ..Default::default()
            },
        )
        .await?;
    assert!(
        matches!(first, SubmitUserJoinRequestResponse::AutoAccepted(_)),
        "{first:?}"
    );

    let reply = submit(context, grace(), "automatic").await?;

    assert!(
        matches!(reply, SubmitUserJoinRequestResponse::AlreadyMemberError(_)),
        "{reply:?}"
    );
    assert_jm!(standing(context, grace()).await?, { "requests": 0, "members": 1 });
    Ok(())
}

/// The component's join transaction, raced directly against the database, so the transaction's
/// own guarantee is checked apart from the component's conflict retry.
const JOIN_SUBMISSION: &str = include_str!(concat!(
    env!("CARGO_MANIFEST_DIR"),
    "/../../../organization/user-organization/src/join_submission_transaction.surql"
));
const JOIN_SUBMISSION_OUTCOME: usize = wasmcloud_utils::transaction_outcome_index_file!(
    "../../../organization/user-organization/src/join_submission_transaction.surql"
);

/// `user` submits the code `key` through the component's own join transaction.
async fn join_transaction(
    context: &Context,
    user: &StackUser,
    key: &str,
) -> anyhow::Result<serde_json::Value> {
    context
        .database()?
        .seed(JOIN_SUBMISSION)
        .bind("user", surrealdb_types::RecordId::from(user.id()))?
        .bind("code", surrealdb_types::RecordId::from(code(key)))?
        .transaction_json(JOIN_SUBMISSION_OUTCOME)
        .await
}

fn kinds(outcomes: &[serde_json::Value]) -> Vec<&str> {
    let mut kinds = outcomes
        .iter()
        .map(|outcome| outcome["kind"].as_str().unwrap_or("missing"))
        .collect::<Vec<_>>();
    kinds.sort_unstable();
    kinds
}

#[component_test(UserOrganization)]
async fn a_single_use_code_admits_one_of_two_people_racing_for_it(
    context: &mut Context,
) -> TestResult {
    acme_with_code(context, JoinCode::new("invite").single_use().expiring()).await?;
    let hedy = StackUser::new("hedy");
    Seed::new().user(&hedy).apply(&context.database()?).await?;

    let (first, second) = tokio::join!(
        join_transaction(context, grace(), "invite"),
        join_transaction(context, &hedy, "invite"),
    );

    let outcomes = [first?, second?];
    assert_eq!(
        kinds(&outcomes),
        ["code_not_found_error", "request_made"],
        "{outcomes:?}"
    );
    assert_jm!(
        context
            .database()?
            .query_json("RETURN { codes: count(SELECT id FROM organization_join_code), requests: count(SELECT id FROM request_to_join), members: count(SELECT id FROM member_of WHERE in IN [user:user_grace, user:user_hedy]) }")
            .await?,
        { "codes": 0, "requests": 1, "members": 0 }
    );
    Ok(())
}

#[component_test(UserOrganization)]
async fn one_person_joining_twice_at_once_becomes_one_member(context: &mut Context) -> TestResult {
    acme_with_code(
        context,
        JoinCode::new("automatic")
            .auto_accept(&["writer"])
            .expiring(),
    )
    .await?;

    let (first, second) = tokio::join!(
        join_transaction(context, grace(), "automatic"),
        join_transaction(context, grace(), "automatic"),
    );

    let outcomes = [first?, second?];
    assert_eq!(
        kinds(&outcomes),
        ["already_member_error", "auto_accepted"],
        "{outcomes:?}"
    );
    assert_jm!(standing(context, grace()).await?, { "requests": 0, "members": 1 });
    assert_jm!(
        context
            .database()?
            .query_json("RETURN count(SELECT id FROM organization_join_code)")
            .await?,
        1
    );
    Ok(())
}

#[component_test(UserOrganization)]
async fn two_people_racing_for_a_single_use_code_both_get_an_answer(
    context: &mut Context,
) -> TestResult {
    let acme = acme_with_code(context, JoinCode::new("invite").single_use().expiring()).await?;
    let hedy = StackUser::new("hedy");
    Seed::new().user(&hedy).apply(&context.database()?).await?;
    // Whoever wins tells both request views and removes the code; the loser publishes nothing.
    let mock = context.messaging_mock()?;
    mock.expect_persisted_publish("typewriter.to.user.*.join_requests.changed");
    mock.expect_persisted_publish(to_organization(&acme, "join_requests.changed"));
    mock.expect_persisted_publish(to_organization(&acme, "join_codes.changed"));

    let (first, second) = tokio::join!(
        submit(context, grace(), "invite"),
        submit(context, &hedy, "invite"),
    );

    let replies = [first?, second?];
    let made = replies
        .iter()
        .filter(|reply| matches!(reply, SubmitUserJoinRequestResponse::RequestMade(_)))
        .count();
    let refused = replies
        .iter()
        .filter(|reply| matches!(reply, SubmitUserJoinRequestResponse::CodeNotFoundError(_)))
        .count();
    assert_eq!((made, refused), (1, 1), "{replies:?}");
    assert_jm!(
        context
            .database()?
            .query_json("RETURN { codes: count(SELECT id FROM organization_join_code), requests: count(SELECT id FROM request_to_join), members: count(SELECT id FROM member_of WHERE in IN [user:user_grace, user:user_hedy]) }")
            .await?,
        { "codes": 0, "requests": 1, "members": 0 }
    );
    Ok(())
}

#[component_test(UserOrganization)]
async fn joining_twice_at_once_answers_both_and_makes_one_member(
    context: &mut Context,
) -> TestResult {
    let acme = acme_with_code(
        context,
        JoinCode::new("automatic")
            .auto_accept(&["writer"])
            .expiring(),
    )
    .await?;
    expect_grace_joins_as_writer(context, &acme)?;

    let (first, second) = tokio::join!(
        submit(context, grace(), "automatic"),
        submit(context, grace(), "automatic"),
    );

    let replies = [first?, second?];
    let accepted = replies
        .iter()
        .filter(|reply| matches!(reply, SubmitUserJoinRequestResponse::AutoAccepted(_)))
        .count();
    let refused = replies
        .iter()
        .filter(|reply| matches!(reply, SubmitUserJoinRequestResponse::AlreadyMemberError(_)))
        .count();
    assert_eq!((accepted, refused), (1, 1), "{replies:?}");
    assert_jm!(standing(context, grace()).await?, { "requests": 0, "members": 1 });
    Ok(())
}

#[component_test(UserOrganization)]
async fn a_member_using_a_single_use_code_keeps_it_unused(context: &mut Context) -> TestResult {
    acme_with_code(context, JoinCode::new("invite").single_use().expiring()).await?;

    let reply = submit(context, ada(), "invite").await?;

    assert!(
        matches!(reply, SubmitUserJoinRequestResponse::AlreadyMemberError(_)),
        "{reply:?}"
    );
    assert_jm!(
        context
            .database()?
            .query_json("RETURN count(SELECT id FROM organization_join_code)")
            .await?,
        1
    );
    Ok(())
}

#[component_test(UserOrganization)]
async fn a_role_an_automatic_code_hands_out_stays_assignable(context: &mut Context) -> TestResult {
    let acme = acme_with_code(
        context,
        JoinCode::new("automatic")
            .auto_accept(&["writer"])
            .expiring(),
    )
    .await?;

    expect_grace_joins_as_writer(context, &acme)?;
    let refused = Seed::new()
        .unassignable(&acme, "writer")
        .apply(&context.database()?)
        .await;
    let reply = submit(context, grace(), "automatic").await?;

    let error = refused.expect_err("a join code role cannot become unassignable");
    assert!(
        format!("{error:#}").contains("Cannot make a join-code role unassignable"),
        "{error:#}"
    );
    assert!(
        matches!(reply, SubmitUserJoinRequestResponse::AutoAccepted(_)),
        "{reply:?}"
    );
    assert_jm!(
        context
            .database()?
            .seed(
                "SELECT VALUE roles.name FROM ONLY member_of WHERE in = $user LIMIT 1 FETCH roles"
            )
            .bind("user", surrealdb_types::RecordId::from(grace().id()))?
            .query_json()
            .await?,
        ["writer"]
    );
    Ok(())
}

#[component_test(UserOrganization)]
async fn a_second_request_to_the_same_organization_is_refused(context: &mut Context) -> TestResult {
    let acme = acme_with_code(context, JoinCode::new("invite").expiring()).await?;
    Seed::new()
        .join_request(grace(), &acme)
        .apply(&context.database()?)
        .await?;

    let reply = submit(context, grace(), "invite").await?;

    assert!(
        matches!(
            reply,
            SubmitUserJoinRequestResponse::PendingRequestExistsError(_)
        ),
        "{reply:?}"
    );
    assert_jm!(standing(context, grace()).await?, { "requests": 1, "members": 0 });
    Ok(())
}

#[component_test(UserOrganization)]
async fn a_person_with_five_pending_requests_cannot_make_a_sixth(
    context: &mut Context,
) -> TestResult {
    acme_with_code(context, JoinCode::new("invite").expiring()).await?;
    let pending = (1..=5).fold(Seed::new(), |seed, index| {
        let organization = Organization::new(format!("pending_{index}"));
        seed.organization(&organization, ada())
            .join_request(grace(), &organization)
    });
    pending.apply(&context.database()?).await?;

    let reply = submit(context, grace(), "invite").await?;

    assert!(
        matches!(
            reply,
            SubmitUserJoinRequestResponse::MaxPendingRequestsError(_)
        ),
        "{reply:?}"
    );
    assert_jm!(standing(context, grace()).await?, { "requests": 5, "members": 0 });
    Ok(())
}

#[component_test(UserOrganization)]
async fn automatic_join_creates_membership_and_consumes_code(context: &mut Context) -> TestResult {
    let acme = acme_with_code(
        context,
        JoinCode::new("automatic")
            .single_use()
            .auto_accept(&["writer"])
            .expiring(),
    )
    .await?;
    expect_grace_joins_as_writer(context, &acme)?;
    context.expect_publish(
        to_organization(&acme, "join_codes.changed"),
        |event: &OrganizationJoinCodesChanged| {
            matches!(event.changes.as_slice(), [OrganizationJoinCodesChange::Remove(code)]
                if code.key.to_string() == "automatic")
        },
    )?;

    let reply = submit(context, grace(), "automatic").await?;

    assert!(
        matches!(&reply, SubmitUserJoinRequestResponse::AutoAccepted(accepted)
            if accepted.member.organization_name == "acme"
                && accepted.member.roles.iter().any(|role| role.name == "writer")),
        "{reply:?}"
    );
    assert_jm!(standing(context, grace()).await?, { "requests": 0, "members": 1 });
    assert_jm!(
        context
            .database()?
            .query_json("RETURN count(SELECT id FROM organization_join_code)")
            .await?,
        0
    );
    Ok(())
}

#[component_test(UserOrganization)]
async fn watch_lists_only_the_callers_organizations(context: &mut Context) -> TestResult {
    found(context, ada(), "acme").await?;
    found(context, grace(), "globex").await?;

    let reply: WatchUserOrganizationsResponse = context
        .request(
            from_user(ada(), "organization.watch"),
            &WatchUserOrganizationsRequest::default(),
        )
        .await?;

    let WatchUserOrganizationsResponse::Snapshot(snapshot) = reply else {
        anyhow::bail!("expected organization list, received {reply:?}")
    };
    assert_eq!(
        snapshot
            .values
            .iter()
            .map(|organization| organization.name.as_str())
            .collect::<Vec<_>>(),
        ["acme"]
    );
    // An organization without a logo still carries the field the panel requires.
    assert_eq!(snapshot.values[0].logo_url, "");
    Ok(())
}

#[component_test(UserOrganization)]
async fn join_request_watch_lists_only_the_callers_requests(context: &mut Context) -> TestResult {
    let acme = found(context, ada(), "acme").await?;
    let hedy = StackUser::new("hedy");
    Seed::new()
        .join_request(grace(), &acme)
        .join_request(&hedy, &acme)
        .apply(&context.database()?)
        .await?;

    let reply: WatchUserJoinRequestsResponse = context
        .request(
            from_user(grace(), "organization.join_requests.watch"),
            &WatchUserJoinRequestsRequest::default(),
        )
        .await?;

    let WatchUserJoinRequestsResponse::Snapshot(snapshot) = reply else {
        anyhow::bail!("expected join request list, received {reply:?}")
    };
    let request = context.database()?.join_request(grace(), &acme).await?;
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

#[component_test(UserOrganization)]
async fn cancel_request_deletes_and_notifies_both_views(context: &mut Context) -> TestResult {
    let acme = acme_with_code(context, JoinCode::new("invite").expiring()).await?;
    let SubmitUserJoinRequestResponse::RequestMade(made) = context
        .arrange(
            from_user(grace(), "organization.join_requests.request"),
            &SubmitUserJoinRequestRequest {
                code: code("invite"),
                ..Default::default()
            },
        )
        .await?
    else {
        anyhow::bail!("grace could not request to join")
    };
    let request = made.request.request_id;
    let removed = request.clone();
    context.expect_publish(
        to_user(grace(), "join_requests.changed"),
        move |event: &UserJoinRequestsChanged| {
            matches!(event.changes.as_slice(), [UserJoinRequestsChange::Remove(id)] if **id == removed)
        },
    )?;
    let removed = request.clone();
    context.expect_publish(
        to_organization(&acme, "join_requests.changed"),
        move |event: &OrganizationJoinRequestsChanged| {
            matches!(event.changes.as_slice(), [OrganizationJoinRequestsChange::Remove(id)] if **id == removed)
        },
    )?;

    let reply: CancelUserJoinRequestResponse = context
        .request(
            from_user(grace(), "organization.join_requests.cancel"),
            &CancelUserJoinRequestRequest {
                request_id: request,
                ..Default::default()
            },
        )
        .await?;

    assert!(
        matches!(reply, CancelUserJoinRequestResponse::Success(_)),
        "{reply:?}"
    );
    assert_jm!(standing(context, grace()).await?, { "requests": 0, "members": 0 });
    Ok(())
}

#[component_test(UserOrganization)]
async fn cancelling_someone_elses_request_is_refused(context: &mut Context) -> TestResult {
    let acme = found(context, ada(), "acme").await?;
    let hedy = StackUser::new("hedy");
    Seed::new()
        .user(grace())
        .join_request(&hedy, &acme)
        .apply(&context.database()?)
        .await?;
    let request = context.database()?.join_request(&hedy, &acme).await?;

    let reply: CancelUserJoinRequestResponse = context
        .request(
            from_user(grace(), "organization.join_requests.cancel"),
            &CancelUserJoinRequestRequest {
                request_id: request.clone(),
                ..Default::default()
            },
        )
        .await?;

    assert!(
        matches!(&reply, CancelUserJoinRequestResponse::RequestNotFoundError(error) if error.request_id == request),
        "{reply:?}"
    );
    assert_jm!(standing(context, &hedy).await?, { "requests": 1, "members": 0 });
    Ok(())
}
