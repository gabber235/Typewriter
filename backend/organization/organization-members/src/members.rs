use crate::validate_roles;
use otel_wasi::ResultWithSlug;
use serde::Deserialize;
use std::collections::HashMap;
use surrealdb_component_sdk::{RecordId, query};
use wasmcloud_utils::database::organization::projections::OrganizationMemberProjection;
use wasmcloud_utils::{
    decode_skir, extract_params,
    skir::base::organization::v1::{member::*, user::WatchUserOrganizationsResponse},
    skir_utils::{IntoSkirRecordIds, IntoSurrealRecordIds},
    skir_variant,
    wasmcloud::messaging::types::BrokerMessage,
};

#[derive(Debug, Deserialize)]
struct RemovedMemberRecord {
    organization_id: RecordId,
}

#[derive(Debug, Deserialize)]
struct CurrentMemberRoles {
    roles: Vec<CurrentRole>,
}

#[derive(Debug, Deserialize)]
struct CurrentRole {
    id: RecordId,
    assignable: bool,
}

#[tracing::instrument(skip(msg, params))]
pub async fn handle_watch(
    msg: BrokerMessage,
    params: HashMap<String, String>,
) -> Result<WatchOrganizationMembersResponse, otel_wasi::Error> {
    let (actor_id, org_id) = extract_params!(params, user_id, org_id)?;
    otel_wasi::main_attribute!(
        "actor.id" = actor_id.to_string(),
        "organization.id" = org_id.to_string()
    );
    let _ = decode_skir!(WatchOrganizationMembersRequest, &msg.body)?;
    let members = query(
        r#"
        SELECT
            in.id AS user_id,
            in.name AS name,
            in.email AS email,
            in.avatar_url AS avatar_url,
            roles.* AS roles,
            joined_at
        FROM member_of
        WHERE out = type::thing('organization', $org_id)
        FETCH roles
        "#,
    )
    .bind("org_id", org_id)
    .execute()
    .await
    .error_with_slug("member-watch-query-failed")?
    .take::<Vec<OrganizationMemberProjection>>(0)
    .error_with_slug("member-watch-result-parse-failed")?
    .into_iter()
    .map(Into::into)
    .collect::<Vec<_>>();

    otel_wasi::main_attribute!(
        "member.outcome" = "listed",
        "member.result_count" = members.len() as i64
    );
    Ok(WatchOrganizationMembersResponse::List(members))
}

#[tracing::instrument(skip(msg, params))]
pub async fn handle_update(
    msg: BrokerMessage,
    params: HashMap<String, String>,
) -> Result<UpdateOrganizationMemberRolesResponse, otel_wasi::Error> {
    let (actor_id, org_id) = extract_params!(params, user_id, org_id)?;
    let request = decode_skir!(UpdateOrganizationMemberRolesRequest, &msg.body)?;
    let user_id = request.user_id.clone();
    let role_ids = request.role_ids.clone();
    otel_wasi::main_attribute!(
        "actor.id" = actor_id.to_string(),
        "organization.id" = org_id.to_string(),
        "user.id" = user_id.key.to_string(),
        "role.result_count" = role_ids.len() as i64
    );

    let current = query(
        r#"
        SELECT roles.* AS roles
        FROM ONLY member_of
        WHERE in = $user
            AND out = $org
        FETCH roles
        "#,
    )
    .bind("user", RecordId::from(&user_id))
    .bind("org", RecordId::new("organization", org_id))
    .execute()
    .await
    .error_with_slug("member-update-validation-member-query-failed")?
    .take::<Option<CurrentMemberRoles>>(0)
    .error_with_slug("member-update-validation-member-result-parse-failed")?;

    let Some(current) = current else {
        otel_wasi::main_attribute!("member.outcome" = "user-not-found-error");
        return Ok(skir_variant!(
            UpdateOrganizationMemberRolesResponse::UserNotFoundError { user_id }
        ));
    };

    let held_protected = current
        .roles
        .into_iter()
        .filter(|role| !role.assignable)
        .map(|role| role.id)
        .collect::<Vec<_>>();

    let db_role_ids = role_ids.as_slice().into_surreal_record_ids();
    let validation = validate_roles(
        &org_id,
        &db_role_ids,
        &held_protected,
        "member-update-role-validation-query-failed",
        "member-update-role-validation-result-parse-failed",
    )
    .await?;

    if !validation.missing.is_empty() {
        otel_wasi::main_attribute!("member.outcome" = "roles-not-found-error");
        return Ok(skir_variant!(
            UpdateOrganizationMemberRolesResponse::RolesNotFoundError {
                role_ids: validation.missing.into_skir_record_ids()
            }
        ));
    }

    if !validation.unassignable.is_empty() {
        otel_wasi::main_attribute!("member.outcome" = "roles-not-assignable-error");
        return Ok(skir_variant!(
            UpdateOrganizationMemberRolesResponse::RolesNotAssignableError {
                role_ids: validation.unassignable.into_skir_record_ids()
            }
        ));
    }

    let db_roles = db_role_ids;
    let result = query(
        r#"
        BEGIN TRANSACTION;

        LET $member = SELECT * FROM member_of WHERE in = $user AND out = $org;

        IF array::len($member) = 0 {
            THROW 'user-not-found-error'
        };

        LET $requested = SELECT * FROM $roles WHERE organization = $org;

        IF array::len($requested) != array::len(array::distinct($roles)) {
            THROW 'roles-not-found-error'
        };

        LET $held_protected = SELECT VALUE id FROM $member[0].roles WHERE !assignable;

        LET $new_unassignable = SELECT VALUE id FROM $requested WHERE !assignable AND id NOT IN $held_protected;

        IF array::len($new_unassignable) > 0 {
            THROW 'roles-not-assignable-error'
        };

        LET $effective = array::distinct(array::union($roles, $held_protected));

        IF array::len($effective) = 0 {
            THROW 'roles-required-error'
        };

        LET $held_founder = fn::organization::roles::has_named_role($member[0].roles, 'founder');
        LET $keeps_founder = fn::organization::roles::has_named_role($effective, 'founder');
        LET $other_founders = SELECT * FROM member_of WHERE out = $org AND id != $member[0].id AND fn::organization::roles::has_named_role(roles, 'founder');

        IF $held_founder AND !$keeps_founder AND array::len($other_founders) = 0 {
            THROW 'founder-role-required-error'
        };

        UPDATE $member[0].id SET roles = $effective;

        RETURN SELECT
            in.id AS user_id,
            in.name AS name,
            in.email AS email,
            in.avatar_url AS avatar_url,
            roles.* AS roles,
            joined_at
        FROM ONLY $member[0].id
        FETCH roles;

        COMMIT TRANSACTION;
        "#,
    )
    .bind("user", RecordId::from(&user_id))
    .bind("org", RecordId::new("organization", org_id))
    .bind("roles", db_roles)
    .execute()
    .await
    .error_with_slug("member-update-query-failed")?
    .parse_result::<OrganizationMemberProjection>(0)
    .error_with_slug("member-update-result-parse-failed")?;

    if let Err(slug) = &result {
        otel_wasi::main_attribute!("member.outcome" = slug.clone());
    }
    let member = wasmcloud_utils::skir_domain_result!(UpdateOrganizationMemberRolesResponse, result,
        "user-not-found-error" => { user_id: user_id.clone() },
        "roles-not-found-error" => { role_ids: role_ids.clone() },
        "roles-not-assignable-error" => { role_ids: role_ids.clone() }
    );

    let member: OrganizationMember = member.into();

    wasmcloud_utils::skir_subjects::organization_members(&org_id)
        .publish(WatchOrganizationMembersResponse::Update(Box::new(
            member.clone(),
        )))
        .await?;

    otel_wasi::main_attribute!("member.outcome" = "updated");
    Ok(UpdateOrganizationMemberRolesResponse::Success(Box::new(
        member,
    )))
}

#[tracing::instrument(skip(msg, params))]
pub async fn handle_remove(
    msg: BrokerMessage,
    params: HashMap<String, String>,
) -> Result<RemoveOrganizationMemberResponse, otel_wasi::Error> {
    let (actor_id, org_id) = extract_params!(params, user_id, org_id)?;
    let request = decode_skir!(RemoveOrganizationMemberRequest, &msg.body)?;
    let user_id = request.user_id.clone();
    otel_wasi::main_attribute!(
        "actor.id" = actor_id.to_string(),
        "organization.id" = org_id.to_string(),
        "user.id" = user_id.key.to_string()
    );

    let result = query(
        r#"
        BEGIN TRANSACTION;

        LET $member = SELECT * FROM member_of WHERE in = $user AND out = $org;

        IF array::len($member) = 0 {
            THROW 'user-not-member-error'
        };

        IF $org.founder = $user {
            THROW 'founder-cannot-be-removed-error'
        };

        LET $is_founder = fn::organization::roles::has_named_role($member[0].roles, 'founder');
        LET $other_founders = SELECT * FROM member_of WHERE out = $org AND id != $member[0].id AND fn::organization::roles::has_named_role(roles, 'founder');

        IF $is_founder AND array::len($other_founders) = 0 {
            THROW 'founder-cannot-be-removed-error'
        };

        DELETE $member[0].id;

        RETURN { organization_id: $org };

        COMMIT TRANSACTION;
        "#,
    )
    .bind("user", RecordId::from(&user_id))
    .bind("org", RecordId::new("organization", org_id))
    .execute()
    .await
    .error_with_slug("member-remove-query-failed")?
    .parse_result::<RemovedMemberRecord>(0)
    .error_with_slug("member-remove-result-parse-failed")?;

    if let Err(slug) = &result {
        otel_wasi::main_attribute!("member.outcome" = slug.clone());
    }
    let deleted = wasmcloud_utils::skir_domain_result!(RemoveOrganizationMemberResponse, result,
        "user-not-member-error" => { user_id: user_id.clone() },
        "founder-cannot-be-removed-error" => { user_id: user_id.clone() }
    );

    wasmcloud_utils::skir_subjects::organization_members(&org_id)
        .publish(WatchOrganizationMembersResponse::Remove(Box::new(
            user_id.clone(),
        )))
        .await?;

    wasmcloud_utils::skir_subjects::user_organizations(user_id.key.to_string())
        .publish(WatchUserOrganizationsResponse::Remove(Box::new(
            deleted.organization_id.into(),
        )))
        .await?;

    otel_wasi::main_attribute!("member.outcome" = "removed");
    Ok(skir_variant!(RemoveOrganizationMemberResponse::Success))
}
