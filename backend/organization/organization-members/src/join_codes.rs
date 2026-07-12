use crate::validate_roles;
use otel_wasi::{ResultWithSlug, main_attribute, wasi_error};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use surrealdb_component_sdk::{Datetime, query};
use wasmcloud_utils::{
    decode_skir, extract_params,
    skir::base::organization::v1::join_codes::*,
    skir_utils::{IntoSkirRecordIds, IntoSurrealRecordIds},
    skir_variant,
    wasmcloud::messaging::types::BrokerMessage,
};

#[derive(Debug, Serialize, Deserialize)]
struct JoinCodeRecord {
    id: surrealdb_component_sdk::RecordId,
    created_at: Datetime,
    expires_at: Option<Datetime>,
    single_use: bool,
    auto_accept_roles: Vec<surrealdb_component_sdk::RecordId>,
}

impl From<JoinCodeRecord> for JoinCode {
    fn from(v: JoinCodeRecord) -> Self {
        Self {
            code: v.id.into(),
            created_at: v.created_at.into(),
            expires_at: v.expires_at.map(Into::into),
            single_use: v.single_use,
            auto_accept: JoinCode_AutoAccept {
                role_ids: v.auto_accept_roles.into_skir_record_ids(),
                _unrecognized: None,
            },
            _unrecognized: None,
        }
    }
}

#[tracing::instrument(skip(msg, params))]
pub async fn handle_watch(
    msg: BrokerMessage,
    params: HashMap<String, String>,
) -> Result<WatchOrganizationJoinCodesResponse, otel_wasi::Error> {
    let (actor_id, org_id) = extract_params!(params, user_id, org_id)?;
    main_attribute!(
        "actor.id" = actor_id.to_string(),
        "organization.id" = org_id.to_string()
    );
    let _ = decode_skir!(WatchOrganizationJoinCodesRequest, &msg.body)?;

    let rows = query(
        r#"
            SELECT
                id,
                created_at,
                expires_at,
                single_use,
                auto_accept_roles
            FROM organization_join_code
            WHERE organization = type::thing('organization', $org_id)
                AND (expires_at IS NONE OR expires_at > time::now())
                ORDER BY created_at DESC
        "#,
    )
    .bind("org_id", org_id)
    .execute()
    .await
    .error_with_slug("join-code-watch-query-failed")?
    .take::<Vec<JoinCodeRecord>>(0)
    .error_with_slug("join-code-watch-result-parse-failed")?;

    main_attribute!(
        "join_code.outcome" = "listed",
        "join_code.result_count" = rows.len() as i64
    );

    Ok(WatchOrganizationJoinCodesResponse::List(
        rows.into_iter().map(Into::into).collect(),
    ))
}

#[tracing::instrument(skip(msg, params))]
pub async fn handle_generate(
    msg: BrokerMessage,
    params: HashMap<String, String>,
) -> Result<GenerateOrganizationJoinCodeResponse, otel_wasi::Error> {
    let (actor_id, org_id) = extract_params!(params, user_id, org_id)?;
    let req = decode_skir!(GenerateOrganizationJoinCodeRequest, &msg.body)?;
    main_attribute!(
        "actor.id" = actor_id.to_string(),
        "organization.id" = org_id.to_string()
    );

    let expiration = match &req.expiration {
        GenerateOrganizationJoinCodeRequest_Expiration::Never => None,
        GenerateOrganizationJoinCodeRequest_Expiration::Duration(d) if d.milliseconds > 0 => Some(
            surrealdb_component_sdk::Duration(format!("{}ms", d.milliseconds)),
        ),
        GenerateOrganizationJoinCodeRequest_Expiration::Duration(d) => {
            main_attribute!("join_code.outcome" = "invalid_expiration");
            return Ok(skir_variant!(
                GenerateOrganizationJoinCodeResponse::InvalidExpirationError {
                    duration: (**d).clone()
                }
            ));
        }
        GenerateOrganizationJoinCodeRequest_Expiration::Unknown(_) => {
            return Err(wasi_error!(
                "join-code-generate-expiration-invalid",
                "unknown expiration variant",
            ));
        }
    };

    let role_ids = req
        .auto_accept
        .role_ids
        .as_slice()
        .into_surreal_record_ids();

    let validation = validate_roles(
        &org_id,
        &role_ids,
        &[],
        "join-code-generate-role-validation-query-failed",
        "join-code-generate-role-validation-result-parse-failed",
    )
    .await?;

    if !validation.missing.is_empty() {
        main_attribute!("join_code.outcome" = "roles-not-found-error");
        return Ok(skir_variant!(
            GenerateOrganizationJoinCodeResponse::RolesNotFoundError {
                role_ids: validation.missing.into_skir_record_ids()
            }
        ));
    }

    if !validation.unassignable.is_empty() {
        main_attribute!("join_code.outcome" = "roles-not-assignable-error");
        return Ok(skir_variant!(
            GenerateOrganizationJoinCodeResponse::RolesNotAssignableError {
                role_ids: validation.unassignable.into_skir_record_ids()
            }
        ));
    }

    let roles = role_ids.clone();

    let result = query(
        r#"
        BEGIN TRANSACTION;

        LET $valid = SELECT * FROM $roles WHERE organization=$org;

        IF array::len($valid) != array::len(array::distinct($roles)) {
            THROW 'roles-not-found-error'
        };

        IF array::any($valid,|$r|!$r.assignable) {
            THROW 'roles-not-assignable-error'
        };

        LET $code = CREATE ONLY organization_join_code SET
            organization = $org,
            created_by = $actor,
            single_use = $single_use,
            auto_accept_roles = $roles,
            expires_at = IF $duration = NONE { NONE } ELSE { time::now() + $duration };

        RETURN SELECT id, created_at, expires_at, single_use, auto_accept_roles FROM ONLY $code;
        COMMIT TRANSACTION;
        "#,
    )
    .bind(
        "org",
        surrealdb_component_sdk::RecordId::new("organization", org_id),
    )
    .bind(
        "actor",
        surrealdb_component_sdk::RecordId::new("user", actor_id),
    )
    .bind("single_use", req.single_use)
    .bind("roles", roles)
    .bind("duration", expiration)
    .execute()
    .await
    .error_with_slug("join-code-generate-query-failed")?
    .parse_result::<JoinCodeRecord>(0)
    .error_with_slug("join-code-generate-result-parse-failed")?;

    if let Err(slug) = &result {
        main_attribute!("join_code.outcome" = slug.clone());
    }

    let row = wasmcloud_utils::skir_domain_result!(GenerateOrganizationJoinCodeResponse, result,
        "roles-not-found-error" => { role_ids: role_ids.as_slice().into_skir_record_ids() },
        "roles-not-assignable-error" => { role_ids: role_ids.as_slice().into_skir_record_ids() }
    );

    let code: JoinCode = row.into();
    wasmcloud_utils::skir_subjects::organization_join_codes(&org_id)
        .publish(WatchOrganizationJoinCodesResponse::Add(Box::new(
            code.clone(),
        )))
        .await?;

    main_attribute!(
        "join_code.outcome" = "generated",
        "join_code.id" = code.code.key.to_string()
    );

    Ok(GenerateOrganizationJoinCodeResponse::Success(Box::new(
        code,
    )))
}

#[tracing::instrument(skip(msg, params))]
pub async fn handle_revoke(
    msg: BrokerMessage,
    params: HashMap<String, String>,
) -> Result<RevokeOrganizationJoinCodeResponse, otel_wasi::Error> {
    let (actor_id, org_id) = extract_params!(params, user_id, org_id)?;
    let req = decode_skir!(RevokeOrganizationJoinCodeRequest, &msg.body)?;
    let code = req.code_id.clone();
    main_attribute!(
        "actor.id" = actor_id.to_string(),
        "organization.id" = org_id.to_string(),
        "join_code.id" = code.key.to_string()
    );

    let deleted = query(
        "DELETE $code WHERE organization = $org AND (expires_at IS NONE OR expires_at>time::now()) RETURN BEFORE"
    )
    .bind("code", surrealdb_component_sdk::RecordId::from(&code))
    .bind("org", surrealdb_component_sdk::RecordId::new("organization", org_id))
    .execute()
    .await
    .error_with_slug("join-code-revoke-query-failed")?
    .take::<Option<JoinCodeRecord>>(0)
    .error_with_slug("join-code-revoke-result-parse-failed")?;

    if deleted.is_none() {
        main_attribute!("join_code.outcome" = "code_not_found");
        return Ok(skir_variant!(
            RevokeOrganizationJoinCodeResponse::CodeNotFoundError { code_id: code }
        ));
    }

    wasmcloud_utils::skir_subjects::organization_join_codes(&org_id)
        .publish(WatchOrganizationJoinCodesResponse::Remove(Box::new(code)))
        .await?;

    main_attribute!("join_code.outcome" = "revoked");
    Ok(skir_variant!(RevokeOrganizationJoinCodeResponse::Success))
}
