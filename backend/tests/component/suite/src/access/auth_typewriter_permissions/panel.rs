use base64::{Engine as _, engine::general_purpose::URL_SAFE_NO_PAD};
use component_test::{TestContext, TestResult, component_test};
use json_matcher::assert_jm;
use typewriter_component_test::prelude::{DatabaseHandle, skir_record_id};
use wasmcloud_utils::skir::base::{
    access::v1::permission::{
        EntityPermissionQualifier, EntityPermissionQualifier_User, GetEntityPermissionRequest,
    },
    kernel::v1::record_id::RecordId,
};

use super::{AuthTypewriterPermissions, request_permissions};

fn claims(user_id: &str) -> Vec<u8> {
    serde_json::to_vec(&serde_json::json!({
        "sub": user_id,
        "name": "Panel User",
        "email": "panel@example.test",
        "avatar_url": "https://example.test/avatar.png"
    }))
    .expect("claims are valid JSON")
}

fn organization_id() -> RecordId {
    skir_record_id("organization", "writers")
}

fn consumer_name(organization: Option<&str>, projection: &str) -> String {
    let identity = serde_json::to_vec(&(
        "panel_user",
        organization,
        "0123456789abcdef0123456789abcdef",
        projection,
    ))
    .expect("consumer identity is valid JSON");
    format!("TW_{}", URL_SAFE_NO_PAD.encode(identity))
}

fn assert_consumer_grant(
    publish: &[String],
    organization: Option<&str>,
    projection: &str,
    filter: &str,
) {
    let consumer = consumer_name(organization, projection);
    for subject in [
        "$JS.API.STREAM.INFO.TYPEWRITER_MEMBERSHIP".to_owned(),
        format!("$JS.API.CONSUMER.CREATE.TYPEWRITER_MEMBERSHIP.{consumer}.{filter}"),
        format!("$JS.API.CONSUMER.INFO.TYPEWRITER_MEMBERSHIP.{consumer}"),
        format!("$JS.API.CONSUMER.MSG.NEXT.TYPEWRITER_MEMBERSHIP.{consumer}"),
        format!("$JS.API.CONSUMER.DELETE.TYPEWRITER_MEMBERSHIP.{consumer}"),
    ] {
        assert!(publish.contains(&subject));
    }
}

fn request(user_id: &str, organization_id: Option<RecordId>) -> GetEntityPermissionRequest {
    GetEntityPermissionRequest {
        qualifier: EntityPermissionQualifier::User(Box::new(EntityPermissionQualifier_User {
            organization_id,
            connection_session: "0123456789abcdef0123456789abcdef".into(),
            _unrecognized: None,
        })),
        jwt_claims: claims(user_id),
        _unrecognized: None,
    }
}

#[component_test(AuthTypewriterPermissions)]
async fn panel_login_upserts_user_and_grants_personal_permissions(
    context: &mut TestContext<AuthTypewriterPermissions>,
) -> TestResult {
    let response = request_permissions(
        context,
        "auth.permissions.typewriter-panel",
        &request("panel_user", None),
    )
    .await?;

    assert_eq!(response.tags, ["user:panel_user"]);
    assert!(
        response
            .permissions
            .publish
            .allow
            .contains(&"cloud.to.user.panel_user.organization.create".into())
    );
    assert!(
        response
            .permissions
            .subscribe
            .allow
            .contains(&"_INBOX.panel_user.0123456789abcdef0123456789abcdef.*".into())
    );
    assert!(
        response
            .permissions
            .publish
            .allow
            .contains(&"$SYS.REQ.USER.INFO".into())
    );
    assert_consumer_grant(
        &response.permissions.publish.allow,
        None,
        "user_organizations_changed",
        "cloud.from.user.panel_user.organizations.changed",
    );
    assert_consumer_grant(
        &response.permissions.publish.allow,
        None,
        "user_join_requests_changed",
        "cloud.from.user.panel_user.join_requests.changed",
    );
    assert!(
        response
            .permissions
            .publish
            .allow
            .iter()
            .chain(&response.permissions.subscribe.allow)
            .all(|subject| !subject.contains('>'))
    );
    let database = context
        .extension::<DatabaseHandle>()
        .ok_or_else(|| anyhow::anyhow!("database handle missing"))?;
    let user = database
        .query_json("SELECT name, email, avatar_url FROM ONLY user:panel_user")
        .await?;
    assert_jm!(user, {
        "name": "Panel User",
        "email": "panel@example.test",
        "avatar_url": "https://example.test/avatar.png"
    });
    Ok(())
}

#[component_test(AuthTypewriterPermissions)]
async fn nonmember_cannot_gain_organization_permissions_or_tag(
    context: &mut TestContext<AuthTypewriterPermissions>,
) -> TestResult {
    let database = context
        .extension::<DatabaseHandle>()
        .ok_or_else(|| anyhow::anyhow!("database handle missing"))?;
    database
        .seed(
            "CREATE user:founder SET name = 'Founder'; CREATE organization:writers SET name = 'writers', founder = user:founder;",
        )
        .execute()
        .await?;

    let response = request_permissions(
        context,
        "auth.permissions.typewriter-panel",
        &request("panel_user", Some(organization_id())),
    )
    .await?;

    assert_eq!(response.tags, ["user:panel_user"]);
    assert!(response.permissions.publish.allow.iter().all(|subject| {
        !subject.contains(".organization.writers.")
            && !subject.starts_with("cloud.to.organization.writers.")
    }));
    assert!(
        response
            .permissions
            .subscribe
            .allow
            .iter()
            .all(|subject| !subject.contains(".organization.writers."))
    );
    Ok(())
}

#[component_test(AuthTypewriterPermissions)]
async fn member_receives_all_organization_capabilities(
    context: &mut TestContext<AuthTypewriterPermissions>,
) -> TestResult {
    let database = context
        .extension::<DatabaseHandle>()
        .ok_or_else(|| anyhow::anyhow!("database handle missing"))?;
    database
        .seed(
            "CREATE user:panel_user SET name = 'Existing User'; CREATE user:other_founder SET name = 'Other Founder'; CREATE organization:writers SET name = 'writers', founder = user:panel_user; CREATE organization:other SET name = 'other', founder = user:other_founder; CREATE service:writers_host_service SET name = 'writers_host_service', role = { type: 'host', version: '1.0.0' }, organization = organization:writers; CREATE service_host:writers_host SET service_id = service:writers_host_service, entrypoint = 'PAPER', can_host_realm = true, supported_engines = [{ engine_id: 'paper' }]; CREATE realm_instance:quests SET owner_host_id = service_host:writers_host, target_engine = { engine_id: 'paper', version_constraint: '^1' }; CREATE service:other_host_service SET name = 'other_host_service', role = { type: 'host', version: '1.0.0' }, organization = organization:other; CREATE service_host:other_host SET service_id = service:other_host_service, entrypoint = 'PAPER', can_host_realm = true, supported_engines = [{ engine_id: 'paper' }]; CREATE realm_instance:other_realm SET owner_host_id = service_host:other_host, target_engine = { engine_id: 'paper', version_constraint: '^1' };",
        )
        .execute()
        .await?;

    let response = request_permissions(
        context,
        "auth.permissions.typewriter-panel",
        &request("panel_user", Some(organization_id())),
    )
    .await?;

    assert_eq!(response.tags, ["user:panel_user", "organization:writers"]);
    let publish = &response.permissions.publish.allow;
    assert_consumer_grant(
        publish,
        Some("writers"),
        "organization_members_changed",
        "cloud.from.organization.writers.members.changed",
    );
    assert_consumer_grant(
        publish,
        Some("writers"),
        "organization_join_requests_changed",
        "cloud.from.organization.writers.join_requests.changed",
    );
    assert_consumer_grant(
        publish,
        Some("writers"),
        "organization_join_codes_changed",
        "cloud.from.organization.writers.join_codes.changed",
    );
    for required in [
        "cloud.to.user.panel_user.organization.writers.roles.watch",
        "cloud.to.user.panel_user.organization.writers.members.update",
        "cloud.to.user.panel_user.organization.writers.members.remove",
        "cloud.to.user.panel_user.organization.writers.services.bind",
        "cloud.to.user.panel_user.organization.writers.topology.watch",
        "cloud.to.user.panel_user.organization.writers.topology.configure",
        "service.to.quests.organization.writers.realm.editor.catalog.fetch",
        "service.to.quests.organization.writers.realm.editor.catalog.invalidate",
        "service.to.quests.organization.writers.realm.editor.presentation.search",
        "service.to.quests.organization.writers.realm.editor.presentation.search.cancel",
        "service.to.quests.organization.writers.realm.editor.capability.computation.invoke",
        "service.to.quests.organization.writers.realm.editor.capability.command.invoke",
        "service.to.quests.organization.writers.realm.editor.creation.prepare",
        "service.to.quests.organization.writers.realm.shared.catalog.fetch",
        "service.to.quests.organization.writers.realm.shared.publish",
        "service.to.quests.organization.writers.realm.shared.blob.read",
        "service.to.quests.organization.writers.realm.editor.authoring.state.query",
        "service.to.quests.organization.writers.realm.editor.authoring.edit.commit",
        "service.to.quests.organization.writers.realm.editor.authoring.type.preview",
        "service.to.quests.organization.writers.realm.editor.authoring.type.commit",
        "service.to.quests.organization.writers.realm.editor.authoring.search",
        "service.to.quests.organization.writers.realm.editor.authoring.publish",
        "service.to.quests.organization.writers.realm.editor.authoring.publication.watch",
        "service.to.quests.organization.writers.realm.editor.authoring.compiled.status.query",
        "service.to.quests.organization.writers.realm.editor.authoring.compiled.query",
        "typewriter.presence.organization.writers.user.panel_user",
    ] {
        assert!(
            publish.iter().any(|subject| subject == required),
            "missing generated publish grant {required}; actual grants: {publish:?}"
        );
    }
    assert!(
        publish.iter().all(|subject| subject
            != "service.to.quests.organization.writers.realm.editor.elements.fetch")
    );
    for obsolete in [
        "compiled.content.watch",
        "editor.authoring.compiled.watch",
        "editor.authoring.content.search",
        "editor.authoring.resources.resolve",
        "editor.authoring.selector.suggest",
        "editor.authoring.snapshot.get",
        "editor.authoring.snapshot.query",
    ] {
        assert!(publish.iter().all(|subject| !subject.ends_with(obsolete)));
    }
    let subscribe = &response.permissions.subscribe.allow;
    for required in [
        "cloud.from.organization.writers.services.watch",
        "cloud.from.organization.writers.topology.watch",
        "service.from.quests.organization.writers.realm.editor.catalog.invalidate",
        "service.from.quests.organization.writers.realm.editor.catalog.fetch.*",
        "service.from.quests.organization.writers.realm.editor.presentation.search",
        "service.from.quests.organization.writers.realm.editor.authoring.changed",
        "service.from.quests.organization.writers.realm.editor.authoring.state.query.*",
        "service.from.quests.organization.writers.realm.editor.authoring.compiled.changed",
        "service.from.quests.organization.writers.realm.editor.authoring.compiled.query.*",
        "service.from.quests.organization.writers.realm.editor.authoring.publication.watch",
        "typewriter.presence.organization.writers.user.*",
    ] {
        assert!(
            subscribe.iter().any(|subject| subject == required),
            "missing generated subscribe grant {required}; actual grants: {subscribe:?}"
        );
    }
    for obsolete in [
        "compiled.content.watch",
        "editor.authoring.compiled.activated",
        "editor.authoring.compiled.watch",
        "editor.authoring.snapshot.query.*",
    ] {
        assert!(subscribe.iter().all(|subject| !subject.ends_with(obsolete)));
    }
    assert!(
        publish
            .iter()
            .chain(subscribe)
            .all(|subject| !subject.contains("other_realm")
                && !subject.contains("organization.other"))
    );
    Ok(())
}

#[component_test(AuthTypewriterPermissions)]
async fn punctuation_in_record_keys_remains_raw_in_generated_grants(
    context: &mut TestContext<AuthTypewriterPermissions>,
) -> TestResult {
    let database = context
        .extension::<DatabaseHandle>()
        .ok_or_else(|| anyhow::anyhow!("database handle missing"))?;
    database
        .seed(
            "CREATE user:panel_user SET name = 'Existing User'; CREATE organization:`writers-world` SET name = 'writers_world', founder = user:panel_user; CREATE service:writers_host_service SET name = 'writers_host_service', role = { type: 'host', version: '1.0.0' }, organization = organization:`writers-world`; CREATE service_host:writers_host SET service_id = service:writers_host_service, entrypoint = 'PAPER', can_host_realm = true, supported_engines = [{ engine_id: 'paper' }]; CREATE realm_instance:`quest-world` SET owner_host_id = service_host:writers_host, target_engine = { engine_id: 'paper', version_constraint: '^1' };",
        )
        .execute()
        .await?;

    let response = request_permissions(
        context,
        "auth.permissions.typewriter-panel",
        &request(
            "panel_user",
            Some(skir_record_id("organization", "writers-world")),
        ),
    )
    .await?;

    assert_eq!(
        response.tags,
        ["user:panel_user", "organization:writers-world"]
    );
    assert!(response.permissions.publish.allow.contains(
        &"service.to.quest-world.organization.writers-world.realm.editor.catalog.fetch".into()
    ));
    assert!(response.permissions.subscribe.allow.contains(
        &"service.from.quest-world.organization.writers-world.realm.editor.catalog.fetch.*".into()
    ));
    assert!(
        response
            .permissions
            .publish
            .allow
            .iter()
            .chain(&response.permissions.subscribe.allow)
            .all(|subject| !subject.contains('`'))
    );
    Ok(())
}
