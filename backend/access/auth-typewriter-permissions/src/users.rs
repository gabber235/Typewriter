//! Authorization policy for panel users.
//!
//! The auth callout supplies authenticated claims and an optional organization qualifier. This
//! route persists current profile data, grants baseline user subjects, and grants organization
//! subjects only after checking the user's membership against the database. The qualifier selects
//! which organization is evaluated, but it is never trusted as proof of membership. Database
//! failures and missing user identity fail the request rather than producing partial policy.

use otel_wasi::{ResultWithSlug, main_attribute, wasi_error};
use wasmcloud_utils::database::{
    RecordId as DatabaseRecordId, TransactionOutcome, read_query, transaction_query,
};
use wasmcloud_utils::skir::base::{
    access::v1::permission::{EntityPermissionQualifier, Permissions},
    kernel::v1::record_id::RecordId,
};
use wasmcloud_utils::skir_utils::RecordIdKeyIdentity;
use wasmcloud_utils::transport_routes::{
    GrantScope, GrantSet, MembershipProjection, OrganizationActorRole, OrganizationActorScope,
    RealmRole, RealmScope, SubjectToken, UserRole, UserScope,
};

use crate::{
    common::{AuthentikClaims, TrustedUserProfile, User, build_permissions},
    membership_consumers::{ConnectionSession, MembershipConsumerScope},
};

#[derive(serde::Deserialize)]
struct AdmittedRealmRecords {
    realms: Vec<DatabaseRecordId>,
}

/// Derive NATS policy and tags for one authenticated panel user.
///
/// Organization policy is conditional on a current membership edge. The returned tags describe
/// the identity and any verified organization context; the auth callout attaches them to the
/// signed NATS user claim.
#[tracing::instrument]
pub async fn handle_panel_user(
    claims: jose::jwt::Claims<AuthentikClaims>,
    qualifier: EntityPermissionQualifier,
) -> Result<(Permissions, Vec<String>), otel_wasi::Error> {
    let user_id = claims
        .subject
        .ok_or_else(|| wasi_error!("permissions-panel-no-subject", "No subject in claims"))?;

    let additional = claims.additional;
    let TrustedUserProfile {
        name,
        email,
        avatar_url,
    } = additional.user_profile();

    let user_qualifier = match qualifier {
        EntityPermissionQualifier::User(user) => user,
        _ => {
            return Err(wasi_error!(
                "permissions-panel-qualifier-invalid",
                "user qualifier required"
            ));
        }
    };
    let organization_id = user_qualifier.organization_id;
    let connection_session =
        ConnectionSession::try_from(user_qualifier.connection_session.as_str())?;
    let actor = SubjectToken::try_from(user_id.as_str())?;

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

    upsert_user(&user_id, &name, &email, &avatar_url).await?;

    let mut grants = GrantSet::default();
    let mut tags = vec![format!("user:{user_id}")];

    UserScope {
        user: actor.clone(),
    }
    .grant(UserRole::AuthenticatedUser, &mut grants);
    grants
        .subscribe
        .insert(format!("_INBOX.{actor}.{}.*", connection_session.as_str()));
    grants.publish.insert("$SYS.REQ.USER.INFO".to_owned());
    let user_consumers = MembershipConsumerScope::user(&actor, &connection_session);
    for projection in [
        MembershipProjection::UserOrganizationsChanged,
        MembershipProjection::UserJoinRequestsChanged,
    ] {
        user_consumers.grant(projection, &mut grants)?;
    }
    main_attribute!("auth.permissions.category.organizations" = true);

    if let Some(ref org_id) = organization_id {
        if is_member_of_organization(&user_id, org_id).await? {
            let organization_record = DatabaseRecordId::from(org_id);
            let organization_identity = organization_record.key.raw_identity()?;
            tags.push(format!(
                "{}:{organization_identity}",
                organization_record.table
            ));
            main_attribute!("auth.permissions.organization_access" = "allowed");
            let organization = SubjectToken::try_from(organization_identity)?;
            OrganizationActorScope {
                user: actor.clone(),
                organization: organization.clone(),
            }
            .grant(OrganizationActorRole::OrganizationMember, &mut grants);
            let consumers = MembershipConsumerScope::organization_member(
                &actor,
                &organization,
                &connection_session,
            );
            for projection in [
                MembershipProjection::OrganizationMembersChanged,
                MembershipProjection::OrganizationJoinRequestsChanged,
                MembershipProjection::OrganizationJoinCodesChanged,
            ] {
                consumers.grant(projection, &mut grants)?;
            }
            for realm in admitted_panel_realms(&organization_record).await? {
                realm.grant(RealmRole::OrganizationMember, &mut grants);
            }
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

    let permissions = build_permissions(
        grants.publish.into_iter().collect(),
        grants.subscribe.into_iter().collect(),
        None,
    );

    main_attribute!(
        "auth.permissions.publish.allow.count" = permissions.publish.allow.len() as i64,
        "auth.permissions.subscribe.allow.count" = permissions.subscribe.allow.len() as i64,
    );

    Ok((permissions, tags))
}

async fn admitted_panel_realms(
    organization: &DatabaseRecordId,
) -> Result<Vec<RealmScope>, otel_wasi::Error> {
    let records = read_query!(
        "RETURN { realms: (SELECT VALUE id FROM realm_instance WHERE owner_host_id.service_id.organization = $organization ORDER BY id) };"
    )
    .bind("organization", organization)
    .execute()
    .await
    .error_with_slug("permissions-realm-scope-query-failed")?
    .parse::<AdmittedRealmRecords>()
    .error_with_slug("permissions-realm-scope-parse-failed")?;
    let organization = SubjectToken::try_from(organization.key.raw_identity()?)?;
    records
        .realms
        .into_iter()
        .map(|record| {
            if record.table != "realm_instance" {
                return Err(wasi_error!(
                    "permissions-realm-scope-invalid-table",
                    "invalid Realm table"
                ));
            }
            let realm = SubjectToken::try_from(record.key.raw_identity()?)?;
            Ok(RealmScope {
                organization: organization.clone(),
                realm,
            })
        })
        .collect()
}

/// Persist the latest trusted profile projection without making it an authorization decision.
///
/// The user record supports later application behavior. Organization authorization remains the
/// separate membership query below, so a successful upsert alone grants no organization scope.
#[tracing::instrument]
async fn upsert_user(
    user_id: &str,
    name: &str,
    email: &Option<String>,
    avatar_url: &Option<String>,
) -> Result<(), otel_wasi::Error> {
    let user_id = DatabaseRecordId::new("user", user_id);
    let outcome = transaction_query!(
        Option<User>,
        "
            BEGIN TRANSACTION;

            LET $user = UPSERT $user_id SET
                name = $name,
                email = $email,
                avatar_url = $avatar_url,
                last_login = time::now();

            RETURN $user[0];

            COMMIT TRANSACTION;
            ",
    )
    .bind("user_id", user_id)
    .bind("name", name)
    .bind("email", email)
    .bind("avatar_url", avatar_url)
    .execute()
    .await
    .error_with_slug("user-db-upsert-failed")?
    .decode()
    .error_with_slug("user-db-upsert-failed")?;
    if let TransactionOutcome::Rejected(error) = outcome {
        return Err(otel_wasi::Error::new(
            "user-db-upsert-failed",
            error.message(),
        ));
    }
    Ok(())
}

/// Verify the qualifier's organization against the user's authoritative membership edge.
///
/// This check is the policy gate for organization subjects. A false result is a normal denial;
/// database failure is an authentication failure because the route cannot safely resolve scope.
#[tracing::instrument]
async fn is_member_of_organization(
    user_id: &str,
    org_id: &RecordId,
) -> Result<bool, otel_wasi::Error> {
    let user_id = DatabaseRecordId::new("user", user_id);
    read_query!(
        "
        RETURN count(
            SELECT * FROM member_of
            WHERE in = $user_id AND out = $org_id
        ) > 0
        ",
    )
    .bind("user_id", user_id)
    .bind("org_id", DatabaseRecordId::from(org_id))
    .execute()
    .await
    .error_with_slug("organization-permissions-failed")?
    .parse::<bool>()
    .error_with_slug("organization-permissions-failed")
}
