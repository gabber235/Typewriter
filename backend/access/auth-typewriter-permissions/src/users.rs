use otel_wasi::{ResultWithSlug, main_attribute, wasi_error};
use wasmcloud_utils::skir::base::{
    access::v1::permission::{EntityPermissionQualifier, Permissions},
    kernel::v1::record_id::RecordId,
};

use crate::common::{AuthentikClaims, User, build_permissions};

/// Handle permission request for panel users
#[tracing::instrument]
pub async fn handle_panel_user(
    claims: jose::jwt::Claims<AuthentikClaims>,
    qualifier: EntityPermissionQualifier,
) -> Result<(Permissions, Vec<String>), otel_wasi::Error> {
    let user_id = claims
        .subject
        .ok_or_else(|| wasi_error!("permissions-panel-no-subject", "No subject in claims"))?;

    let additional = claims.additional;
    let (name, email, avatar, avatar_url) = extract_user_details(&additional);

    // Extract organization_id from the qualifier (user-supplied, not trusted for routing)
    let organization_id = match &qualifier {
        EntityPermissionQualifier::User(user) => user.organization_id.clone(),
        _ => None,
    };

    main_attribute!(
        "auth.entity.id" = user_id.clone(),
        "auth.entity.type" = "user",
        "auth.entity.name" = name.clone(),
    );
    if let Some(ref org_id) = organization_id {
        main_attribute!("auth.entity.organization_id" = org_id);
    }
    if let Some(ref discord) = additional.discord {
        main_attribute!("auth.entity.discord_id" = discord.id.clone());
    }

    upsert_user(&user_id, &name, &email, &avatar, &avatar_url).await?;

    let mut allow_publish = vec![];
    let mut allow_subscribe = vec![];

    // ########### PERMISSIONS ###########
    {
        allow_subscribe.push(format!("_INBOX.{}.>", &user_id));
        allow_publish.push(format!("_INBOX.>"));

        add_user_organizations_permissions(&user_id, &mut allow_publish, &mut allow_subscribe);
        main_attribute!("auth.permissions.category.organizations" = true);

        if let Some(ref org_id) = organization_id {
            let is_member = is_member_of_organization(&user_id, org_id).await?;
            if is_member {
                main_attribute!("auth.permissions.organization_access" = "allowed");
                let org_id = &org_id.key.to_string();
                add_organization_roles_permissions(
                    &user_id,
                    org_id,
                    &mut allow_publish,
                    &mut allow_subscribe,
                );
                add_organization_members_permissions(
                    &user_id,
                    org_id,
                    &mut allow_publish,
                    &mut allow_subscribe,
                );
                add_organization_services_permissions(
                    &user_id,
                    org_id,
                    &mut allow_publish,
                    &mut allow_subscribe,
                );
                add_organization_realm_permissions(
                    org_id,
                    &mut allow_publish,
                    &mut allow_subscribe,
                );
                main_attribute!(
                    "auth.permissions.category.roles" = true,
                    "auth.permissions.category.members" = true,
                    "auth.permissions.category.services" = true,
                    "auth.permissions.category.realm" = true,
                );
            } else {
                main_attribute!("auth.permissions.organization_access" = "denied");
            }
        }
    }
    // ######### END PERMISSIONS #########

    let permissions = build_permissions(allow_publish, allow_subscribe);

    main_attribute!(
        "auth.permissions.publish.allow.count" = permissions.publish.allow.len() as i64,
        "auth.permissions.subscribe.allow.count" = permissions.subscribe.allow.len() as i64,
    );

    let mut tags = vec![];
    if let Some(ref organization_id) = organization_id {
        tags.push(format!("org:{}", organization_id));
    }
    tags.push(format!("user:{}", user_id));

    Ok((permissions, tags))
}

fn extract_user_details(
    claims: &AuthentikClaims,
) -> (String, Option<String>, Option<String>, Option<String>) {
    let name = claims
        .name
        .clone()
        .or_else(|| claims.discord.as_ref().map(|d| d.username.clone()))
        .unwrap_or_else(|| "Unknown".to_string());

    let email = claims
        .email
        .clone()
        .or_else(|| claims.discord.as_ref().and_then(|d| d.email.clone()));

    let avatar = claims.avatar.clone();

    let avatar_url = claims
        .avatar_url
        .clone()
        .or_else(|| claims.discord.as_ref().and_then(|d| d.avatar_url.clone()));

    (name, email, avatar, avatar_url)
}

/// Upsert user into the database.
#[tracing::instrument]
async fn upsert_user(
    user_id: &str,
    name: &str,
    email: &Option<String>,
    avatar: &Option<String>,
    avatar_url: &Option<String>,
) -> Result<(), otel_wasi::Error> {
    surrealdb_component_sdk::query(
        "
            UPSERT type::thing('user',$uid) SET
                name = $name,
                email = $email,
                avatar = $avatar,
                avatar_url = $avatar_url,
                last_login = time::now();
            ",
    )
    .bind("uid", &user_id)
    .bind("name", &name)
    .bind("email", &email)
    .bind("avatar", &avatar)
    .bind("avatar_url", &avatar_url)
    .execute()
    .await
    .error_with_slug("user-db-upsert-failed")?
    .take::<Option<User>>(0)
    .error_with_slug("user-db-upsert-failed")?;
    Ok(())
}

/// Checks if the user is a member of the organization.
#[tracing::instrument]
async fn is_member_of_organization(
    user_id: &str,
    org_id: &RecordId,
) -> Result<bool, otel_wasi::Error> {
    surrealdb_component_sdk::query(
        "
        RETURN count(
            SELECT * FROM member_of
            WHERE in = $type::thing('user', $user_id) AND out = $type::thing('organization', $org_id)
        ) > 0
        ",
    )
    .bind("user_id", &user_id)
    .bind("org_id", surrealdb_component_sdk::RecordId::from(org_id))
    .execute()
    .await
    .error_with_slug("organization-permissions-failed")?
    .parse::<bool>(0)
    .error_with_slug("organization-permissions-failed")
}

/// Adds permissions for user/organizations component
fn add_user_organizations_permissions(
    user_id: &str,
    allow_publish: &mut Vec<String>,
    allow_subscribe: &mut Vec<String>,
) {
    allow_publish.push(format!("cloud.out.user.{}.organization.watch", user_id));
    allow_subscribe.push(format!("cloud.in.user.{}.organization.watch", user_id));
    allow_publish.push(format!("cloud.out.user.{}.organization.create", user_id));
    allow_publish.push(format!(
        "cloud.out.user.{}.organization.join_requests.watch",
        user_id
    ));
    allow_subscribe.push(format!(
        "cloud.in.user.{}.organization.join_requests.watch",
        user_id
    ));
    allow_publish.push(format!(
        "cloud.out.user.{}.organization.join_requests.request",
        user_id
    ));
    allow_publish.push(format!(
        "cloud.out.user.{}.organization.join_requests.cancel",
        user_id
    ));
}

/// Adds permissions for organization/roles component
fn add_organization_roles_permissions(
    user_id: &str,
    org_id: &str,
    allow_publish: &mut Vec<String>,
    allow_subscribe: &mut Vec<String>,
) {
    allow_publish.push(format!(
        "cloud.out.user.{}.organization.{}.roles.watch",
        user_id, org_id
    ));
    allow_subscribe.push(format!("cloud.in.organization.{}.roles.watch", org_id));
}

/// Adds permissions for organization/members component
fn add_organization_members_permissions(
    user_id: &str,
    org_id: &str,
    allow_publish: &mut Vec<String>,
    allow_subscribe: &mut Vec<String>,
) {
    allow_publish.push(format!(
        "cloud.out.user.{}.organization.{}.members.watch",
        user_id, org_id
    ));
    allow_subscribe.push(format!("cloud.in.organization.{}.members.watch", org_id));
    allow_publish.push(format!(
        "cloud.out.user.{}.organization.{}.members.update",
        user_id, org_id
    ));
    allow_publish.push(format!(
        "cloud.out.user.{}.organization.{}.members.remove",
        user_id, org_id
    ));
    allow_publish.push(format!(
        "cloud.out.user.{}.organization.{}.members.join_requests.watch",
        user_id, org_id
    ));
    allow_subscribe.push(format!(
        "cloud.in.organization.{}.members.join_requests.watch",
        org_id
    ));
    allow_publish.push(format!(
        "cloud.out.user.{}.organization.{}.members.join_requests.approve",
        user_id, org_id
    ));
    allow_publish.push(format!(
        "cloud.out.user.{}.organization.{}.members.join_requests.decline",
        user_id, org_id
    ));
    allow_publish.push(format!(
        "cloud.out.user.{}.organization.{}.members.join_codes.watch",
        user_id, org_id
    ));
    allow_subscribe.push(format!(
        "cloud.in.organization.{}.members.join_codes.watch",
        org_id
    ));
    allow_publish.push(format!(
        "cloud.out.user.{}.organization.{}.members.join_codes.generate",
        user_id, org_id
    ));
    allow_publish.push(format!(
        "cloud.out.user.{}.organization.{}.members.join_codes.revoke",
        user_id, org_id
    ));
}

/// Adds permissions for organization/services component
fn add_organization_services_permissions(
    user_id: &str,
    org_id: &str,
    allow_publish: &mut Vec<String>,
    allow_subscribe: &mut Vec<String>,
) {
    allow_publish.push(format!(
        "cloud.out.user.{}.organization.{}.services.list",
        user_id, org_id
    ));
    allow_subscribe.push(format!("cloud.in.organization.{}.services.list", org_id));
    allow_publish.push(format!(
        "cloud.out.user.{}.organization.{}.services.bind",
        user_id, org_id
    ));
    allow_publish.push(format!(
        "cloud.out.user.{}.organization.{}.services.update",
        user_id, org_id
    ));
    allow_publish.push(format!(
        "cloud.out.user.{}.organization.{}.services.unbind",
        user_id, org_id
    ));
}

/// Adds permissions for organization/realm component
fn add_organization_realm_permissions(
    org_id: &str,
    allow_publish: &mut Vec<String>,
    allow_subscribe: &mut Vec<String>,
) {
    allow_publish.push(format!("cloud.out.organization.{}.realm.list", org_id));
    allow_subscribe.push(format!("cloud.in.organization.{}.realm.list", org_id));
    allow_publish.push(format!("cloud.out.organization.{}.realm.create", org_id));
    allow_publish.push(format!("cloud.out.organization.{}.realm.delete", org_id));
    allow_publish.push(format!("cloud.out.organization.{}.realm.update", org_id));
}

#[cfg(test)]
mod tests {
    use super::add_organization_members_permissions;
    use rstest::rstest;

    #[rstest]
    #[case::simple_ids("user-1", "org-1")]
    #[case::uuid_ids(
        "550e8400-e29b-41d4-a716-446655440000",
        "123e4567-e89b-12d3-a456-426614174000"
    )]
    #[case::distinct_ids("member-alpha", "organization-beta")]
    fn organization_member_permissions_match_current_api(
        #[case] user_id: &str,
        #[case] org_id: &str,
    ) {
        let mut publish = Vec::new();
        let mut subscribe = Vec::new();
        add_organization_members_permissions(user_id, org_id, &mut publish, &mut subscribe);

        let publish_prefix = format!("cloud.out.user.{user_id}.organization.{org_id}.members");
        assert_eq!(
            publish,
            [
                format!("{publish_prefix}.watch"),
                format!("{publish_prefix}.update"),
                format!("{publish_prefix}.remove"),
                format!("{publish_prefix}.join_requests.watch"),
                format!("{publish_prefix}.join_requests.approve"),
                format!("{publish_prefix}.join_requests.decline"),
                format!("{publish_prefix}.join_codes.watch"),
                format!("{publish_prefix}.join_codes.generate"),
                format!("{publish_prefix}.join_codes.revoke"),
            ]
        );
        let subscribe_prefix = format!("cloud.in.organization.{org_id}.members");
        assert_eq!(
            subscribe,
            [
                format!("{subscribe_prefix}.watch"),
                format!("{subscribe_prefix}.join_requests.watch"),
                format!("{subscribe_prefix}.join_codes.watch"),
            ]
        );
        assert!(publish.iter().all(|subject| !subject.ends_with(".list")));
        assert!(publish.iter().all(|subject| !subject.ends_with(".invite")));
        assert!(
            publish
                .iter()
                .all(|subject| !subject.ends_with(".role.assign"))
        );
        assert!(publish.iter().all(|subject| !subject.ends_with(".reject")));
    }
}
