use anyhow::Result;
use nats_jwt_rs::types::Permissions as NatsPermissions;
use wasmcloud_component::debug;

use crate::common::{build_nats_permissions, AuthentikClaims, User};

/// Handle permission request for panel users
pub fn handle_panel_user(
    claims: jose::jwt::Claims<AuthentikClaims>,
    organization_id: Option<String>,
) -> Result<(NatsPermissions, Vec<String>)> {
    let user_id = claims
        .subject
        .ok_or(anyhow::anyhow!("No subject in claims"))?;

    let additional = claims.additional;

    let name = additional
        .name
        .or_else(|| additional.discord.as_ref().map(|d| d.username.clone()))
        .unwrap_or_else(|| "Unknown".to_string());

    let email = additional
        .email
        .or_else(|| additional.discord.as_ref().and_then(|d| d.email.clone()));

    let avatar = additional.avatar;

    let avatar_url = additional.avatar_url.or_else(|| {
        additional
            .discord
            .as_ref()
            .and_then(|d| d.avatar_url.clone())
    });

    debug!("handling user request for user {}", name);

    let results = surrealdb_component::query(
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
    .map_err(|e| anyhow::anyhow!(e))?;

    debug!("finished handling user request for user {}", name);

    let r = results.take::<Option<User>>(0);
    if let Err(e) = r {
        debug!("error inserting user: {}", e);
        return Err(anyhow::anyhow!(e));
    }

    debug!("made sure no errors occurred");

    let mut allow_publish = vec![];
    let mut allow_subscribe = vec![];

    // ########### PERMISSIONS ###########
    {
        allow_subscribe.push(format!("_INBOX.{}.>", &user_id));

        add_user_organizations_permissions(&user_id, &mut allow_publish, &mut allow_subscribe);

        if let Some(ref org_id) = organization_id {
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
        }
    }
    // ######### END PERMISSIONS #########

    let permissions = build_nats_permissions(allow_publish, allow_subscribe);
    let mut tags = vec![];

    if let Some(organization_id) = organization_id {
        tags.push(format!("org:{}", organization_id));
    }

    debug!("finished handling permissions request for user {}", name);

    Ok((permissions, tags))
}

/// Adds permissions for the user/organizations component
fn add_user_organizations_permissions(
    user_id: &str,
    allow_publish: &mut Vec<String>,
    allow_subscribe: &mut Vec<String>,
) {
    allow_publish.push(format!("cloud.out.user.{}.organization.list", user_id));
    allow_subscribe.push(format!("cloud.in.user.{}.organization.list", user_id));

    allow_publish.push(format!("cloud.out.user.{}.organization.create", user_id));
    allow_publish.push(format!(
        "cloud.out.user.{}.organization.join_requests.list",
        user_id
    ));
    allow_subscribe.push(format!(
        "cloud.in.user.{}.organization.join_requests.list",
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

/// Adds permissions for the organization/roles component
fn add_organization_roles_permissions(
    user_id: &str,
    org_id: &str,
    allow_publish: &mut Vec<String>,
    allow_subscribe: &mut Vec<String>,
) {
    allow_publish.push(format!(
        "cloud.out.user.{}.organization.{}.roles.list",
        user_id, org_id
    ));
    allow_subscribe.push(format!("cloud.in.organization.{}.roles.list", org_id));
}

/// Adds permissions for the organization/members component
fn add_organization_members_permissions(
    user_id: &str,
    org_id: &str,
    allow_publish: &mut Vec<String>,
    allow_subscribe: &mut Vec<String>,
) {
    allow_publish.push(format!(
        "cloud.out.user.{}.organization.{}.members.list",
        user_id, org_id
    ));
    allow_subscribe.push(format!("cloud.in.organization.{}.members.list", org_id));

    allow_publish.push(format!(
        "cloud.out.user.{}.organization.{}.members.update",
        user_id, org_id
    ));
    allow_publish.push(format!(
        "cloud.out.user.{}.organization.{}.members.remove",
        user_id, org_id
    ));
    allow_publish.push(format!(
        "cloud.out.user.{}.organization.{}.members.join_requests.list",
        user_id, org_id
    ));
    allow_subscribe.push(format!(
        "cloud.in.organization.{}.members.join_requests.list",
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
        "cloud.out.user.{}.organization.{}.members.join_codes.generate",
        user_id, org_id
    ));
    allow_publish.push(format!(
        "cloud.out.user.{}.organization.{}.members.join_codes.list",
        user_id, org_id
    ));
    allow_subscribe.push(format!(
        "cloud.in.organization.{}.members.join_codes.list",
        org_id
    ));

    allow_publish.push(format!(
        "cloud.out.user.{}.organization.{}.members.join_codes.revoke",
        user_id, org_id
    ));
}
