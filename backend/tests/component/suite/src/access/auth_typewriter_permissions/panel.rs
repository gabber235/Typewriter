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

fn request(user_id: &str, organization_id: Option<RecordId>) -> GetEntityPermissionRequest {
    GetEntityPermissionRequest {
        qualifier: EntityPermissionQualifier::User(Box::new(EntityPermissionQualifier_User {
            organization_id,
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
            .contains(&"_INBOX.panel_user.>".into())
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
            "CREATE user:panel_user SET name = 'Existing User'; CREATE organization:writers SET name = 'writers', founder = user:panel_user;",
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
    for required in [
        "cloud.to.user.panel_user.organization.writers.roles.watch",
        "cloud.to.user.panel_user.organization.writers.members.update",
        "cloud.to.user.panel_user.organization.writers.members.remove",
        "cloud.to.user.panel_user.organization.writers.services.bind",
        "cloud.to.organization.writers.realm.create",
        "service.to.*.organization.writers.realm.book.create",
        "service.to.*.organization.writers.realm.pages.chapters",
        "service.to.*.organization.writers.realm.tag.resize",
    ] {
        assert!(publish.iter().any(|subject| subject == required));
    }
    let subscribe = &response.permissions.subscribe.allow;
    for required in [
        "cloud.from.organization.writers.roles.watch",
        "cloud.from.organization.writers.members.watch",
        "cloud.from.organization.writers.services.watch",
        "cloud.from.organization.writers.realm.list",
        "service.from.*.organization.writers.realm.book.resource.watch",
        "service.from.*.organization.writers.realm.page.watch",
        "service.from.*.organization.writers.realm.tag.resource.watch",
    ] {
        assert!(subscribe.iter().any(|subject| subject == required));
    }
    Ok(())
}
