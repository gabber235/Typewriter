//! Panel grants checked against subjects and consumer names written out by hand. These are a
//! deliberate oracle independent of the transport generator, so a generator change that alters a
//! grant fails here instead of updating the expectation with it.

use super::AuthTypewriterPermissions;
use json_matcher::assert_jm;
use typewriter_component_test::{
    access::{
        PANEL_POLICY, SESSION, assert_consumer_grant, member_grants, permits, request_permissions,
        sign_in,
    },
    prelude::*,
};
use wasmcloud_utils::skir::base::access::v1::permission::GetEntityPermissionResponse;

#[component_test(AuthTypewriterPermissions)]
async fn panel_login_stores_the_profile_and_a_later_login_updates_it(
    context: &mut TestContext<AuthTypewriterPermissions>,
) -> TestResult {
    request_permissions(
        context,
        PANEL_POLICY,
        &sign_in(ada().token(), "Ada Byron", None),
    )
    .await?;
    request_permissions(
        context,
        PANEL_POLICY,
        &sign_in(ada().token(), "Ada Lovelace", None),
    )
    .await?;

    assert_jm!(
        context
            .database()?
            .read("SELECT name, email, avatar_url FROM ONLY $user", &[("user", ada().id())])
            .await?,
        {
            "name": "Ada Lovelace",
            "email": "panel@example.test",
            "avatar_url": "https://example.test/avatar.png"
        }
    );
    Ok(())
}

#[component_test(AuthTypewriterPermissions)]
async fn panel_login_grants_personal_subjects_only(
    context: &mut TestContext<AuthTypewriterPermissions>,
) -> TestResult {
    let grant = request_permissions(
        context,
        PANEL_POLICY,
        &sign_in(ada().token(), "Ada Lovelace", None),
    )
    .await?;

    assert_eq!(grant.tags, ["user:user_ada"]);
    let permissions = &grant.permissions;
    assert!(permits(
        &permissions.publish,
        "cloud.to.user.user_ada.organization.create"
    ));
    assert!(permits(
        &permissions.subscribe,
        &format!("_INBOX.user_ada.{SESSION}.reply")
    ));
    assert_consumer_grant(
        &permissions.publish.allow,
        ada(),
        None,
        "user_organizations_changed",
        "cloud.from.user.user_ada.organizations.changed",
    );
    assert_consumer_grant(
        &permissions.publish.allow,
        ada(),
        None,
        "user_join_requests_changed",
        "cloud.from.user.user_ada.join_requests.changed",
    );
    for foreign in [
        "cloud.to.user.user_grace.organization.create",
        "cloud.to.user.user_ada.organization.acme.members.update",
        "$SYS.REQ.USER.AUTH",
    ] {
        assert!(
            !permits(&permissions.publish, foreign),
            "{foreign} is granted"
        );
    }
    assert!(!permits(
        &permissions.subscribe,
        &format!("_INBOX.user_grace.{SESSION}.reply")
    ));
    assert!(
        permissions
            .publish
            .allow
            .iter()
            .chain(&permissions.subscribe.allow)
            .all(|subject| !subject.contains('>'))
    );
    // Replies to the panel stream without credit, so a panel connection never answers a message:
    // a response permission would let it publish once to any reply subject it names.
    assert!(permissions.response.is_none());
    Ok(())
}

#[component_test(AuthTypewriterPermissions)]
async fn a_subject_with_nats_separators_is_refused(
    context: &mut TestContext<AuthTypewriterPermissions>,
) -> TestResult {
    let reply: GetEntityPermissionResponse = context
        .request(PANEL_POLICY, &sign_in("user_ada.>", "Ada Lovelace", None))
        .await?;

    assert!(
        matches!(reply, GetEntityPermissionResponse::InternalError(_)),
        "{reply:?}"
    );
    assert_jm!(
        context
            .database()?
            .query_json("RETURN count(SELECT id FROM user)")
            .await?,
        0
    );
    Ok(())
}

#[component_test(AuthTypewriterPermissions)]
async fn nonmember_cannot_gain_organization_permissions_or_tag(
    context: &mut TestContext<AuthTypewriterPermissions>,
) -> TestResult {
    seed_organization(context, &acme(), ada(), &[]).await?;

    let grant = request_permissions(
        context,
        PANEL_POLICY,
        &sign_in(grace().token(), "Grace Hopper", Some(acme().id())),
    )
    .await?;

    assert_eq!(grant.tags, ["user:user_grace"]);
    assert!(!permits(
        &grant.permissions.publish,
        "cloud.to.user.user_grace.organization.acme.members.watch"
    ));
    assert!(!permits(
        &grant.permissions.publish,
        "service.to.quests.organization.acme.realm.editor.catalog.fetch"
    ));
    assert!(
        grant
            .permissions
            .subscribe
            .allow
            .iter()
            .all(|subject| !subject.contains(".organization.acme."))
    );
    Ok(())
}

#[component_test(AuthTypewriterPermissions)]
async fn member_reaches_every_route_of_its_organization_and_nothing_of_another(
    context: &mut TestContext<AuthTypewriterPermissions>,
) -> TestResult {
    seed_organization(context, &acme(), ada(), &[]).await?;

    let permissions = member_grants(context, ada(), &acme()).await?;

    let realm = "service.to.quests.organization.acme.realm";
    for subject in [
        "cloud.to.user.user_ada.organization.acme.roles.watch".to_owned(),
        "cloud.to.user.user_ada.organization.acme.members.update".to_owned(),
        "cloud.to.user.user_ada.organization.acme.members.remove".to_owned(),
        "cloud.to.user.user_ada.organization.acme.services.bind".to_owned(),
        "cloud.to.user.user_ada.organization.acme.topology.watch".to_owned(),
        "cloud.to.user.user_ada.organization.acme.topology.configure".to_owned(),
        format!("{realm}.editor.catalog.fetch"),
        format!("{realm}.editor.presentation.search"),
        format!("{realm}.editor.capability.command.invoke"),
        format!("{realm}.editor.creation.prepare"),
        format!("{realm}.editor.authoring.state.query"),
        format!("{realm}.editor.authoring.edit.commit"),
        format!("{realm}.editor.authoring.publish"),
        format!("{realm}.editor.authoring.compiled.query"),
        format!("{realm}.shared.blob.fetch"),
        format!("{realm}.shared.blob.store"),
        "typewriter.presence.organization.acme.user.user_ada".to_owned(),
    ] {
        assert!(
            permits(&permissions.publish, &subject),
            "a member cannot publish {subject}"
        );
    }
    for subject in [
        "cloud.from.organization.acme.services.watch",
        "cloud.from.organization.acme.topology.watch",
        "service.from.quests.organization.acme.realm.editor.catalog.invalidate",
        "service.from.quests.organization.acme.realm.editor.authoring.changed",
        "typewriter.presence.organization.acme.user.user_grace",
    ] {
        assert!(
            permits(&permissions.subscribe, subject),
            "a member cannot subscribe {subject}"
        );
    }
    assert_consumer_grant(
        &permissions.publish.allow,
        ada(),
        Some("acme"),
        "organization_members_changed",
        "cloud.from.organization.acme.members.changed",
    );
    for foreign in [
        "cloud.to.user.user_ada.organization.globex.members.update",
        "service.to.quests.organization.globex.realm.editor.catalog.fetch",
        "typewriter.presence.organization.globex.user.user_ada",
    ] {
        assert!(
            !permits(&permissions.publish, foreign),
            "{foreign} is granted"
        );
    }
    assert!(!permits(
        &permissions.subscribe,
        "service.from.quests.organization.globex.realm.editor.catalog.invalidate"
    ));
    Ok(())
}

#[component_test(AuthTypewriterPermissions)]
async fn member_reaches_every_realm_of_its_organization_only(
    context: &mut TestContext<AuthTypewriterPermissions>,
) -> TestResult {
    seed_organization(context, &acme(), ada(), &[]).await?;

    let permissions = member_grants(context, ada(), &acme()).await?;

    // A realm created after connect is reachable without a new connection: no realm is enumerated.
    for realm in ["quests", "realm_created_later"] {
        assert!(permits(
            &permissions.publish,
            &format!("service.to.{realm}.organization.acme.realm.editor.catalog.fetch")
        ));
    }
    let realm_grants = permissions
        .publish
        .allow
        .iter()
        .chain(&permissions.subscribe.allow)
        .filter(|subject| subject.starts_with("service."));
    for subject in realm_grants {
        assert!(
            subject.starts_with("service.to.*.organization.acme.realm.")
                || subject.starts_with("service.from.*.organization.acme.realm."),
            "realm grant outside the organization: {subject}"
        );
    }
    Ok(())
}

#[component_test(AuthTypewriterPermissions)]
async fn punctuation_in_record_keys_remains_raw_in_generated_grants(
    context: &mut TestContext<AuthTypewriterPermissions>,
) -> TestResult {
    let world = Organization::new("writers-world");
    seed_organization(context, &world, ada(), &[]).await?;

    let grant = request_permissions(
        context,
        PANEL_POLICY,
        &sign_in(ada().token(), "Ada Lovelace", Some(world.id())),
    )
    .await?;

    assert_eq!(grant.tags, ["user:user_ada", "organization:writers-world"]);
    assert!(permits(
        &grant.permissions.publish,
        "service.to.quests.organization.writers-world.realm.editor.catalog.fetch"
    ));
    assert!(
        grant
            .permissions
            .publish
            .allow
            .iter()
            .chain(&grant.permissions.subscribe.allow)
            .all(|subject| !subject.contains('`'))
    );
    Ok(())
}
