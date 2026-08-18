use crate::validate_roles;
use otel_wasi::{ResultWithSlug, main_attribute, wasi_error};
use std::collections::HashMap;
use wasmcloud_utils::{
    database::{
        DatabaseDuration, RecordId, TransactionOutcome, organization::JoinCodeRecord, read_query,
        transaction_query,
    },
    decode_skir, extract_params,
    skir::base::organization::v1::join_codes::*,
    skir_utils::{IntoSkirRecordIds, IntoSurrealRecordIds},
    skir_variant,
    wasmcloud::messaging::types::BrokerMessage,
};

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

    let organization_id = RecordId::new("organization", org_id);
    let rows = read_query!(
        r#"
            SELECT
                id,
                created_at,
                expires_at,
                single_use,
                auto_accept_roles
            FROM organization_join_code
            WHERE organization = $org_id
                AND (expires_at IS NONE OR expires_at IS NULL OR expires_at > time::now())
                ORDER BY created_at DESC
        "#,
    )
    .bind("org_id", organization_id)
    .execute()
    .await
    .error_with_slug("join-code-watch-query-failed")?
    .take::<Vec<JoinCodeRecord>>()
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
    wasmcloud_utils::validate_record_ids!(
        GenerateOrganizationJoinCodeResponse,
        req.auto_accept.role_ids,
        "organization_role"
    );
    main_attribute!(
        "actor.id" = actor_id.to_string(),
        "organization.id" = org_id.to_string()
    );
    let organization_id = RecordId::new("organization", org_id);
    let actor_id = RecordId::new("user", actor_id);

    let expiration = match &req.expiration {
        GenerateOrganizationJoinCodeRequest_Expiration::Never => None,
        GenerateOrganizationJoinCodeRequest_Expiration::Duration(d) if d.milliseconds > 0 => {
            Some(DatabaseDuration(format!("{}ms", d.milliseconds)))
        }
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
        &organization_id,
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

    let result = transaction_query!(
        JoinCodeRecord,
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
            expires_at = IF $duration = NONE OR $duration = NULL { NULL } ELSE { time::now() + $duration };

        RETURN SELECT id, created_at, expires_at, single_use, auto_accept_roles FROM ONLY $code;
        COMMIT TRANSACTION;
        "#,
    )
    .bind("org", organization_id)
    .bind("actor", actor_id)
    .bind("single_use", req.single_use)
    .bind("roles", roles)
    .bind("duration", expiration)
    .execute()
    .await
    .error_with_slug("join-code-generate-query-failed")?
    .decode()
    .error_with_slug("join-code-generate-result-parse-failed")?;

    if let TransactionOutcome::Rejected(error) = &result {
        main_attribute!("join_code.outcome" = error.message().to_owned());
    }

    let row = wasmcloud_utils::skir_domain_result!(GenerateOrganizationJoinCodeResponse, result,
        "roles-not-found-error" => { role_ids: role_ids.as_slice().into_skir_record_ids() },
        "roles-not-assignable-error" => { role_ids: role_ids.as_slice().into_skir_record_ids() }
    );

    let code: JoinCode = row.into();
    wasmcloud_utils::skir_subjects::organization_join_codes(org_id)
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
    wasmcloud_utils::validate_record_ids!(
        RevokeOrganizationJoinCodeResponse,
        req.code_id,
        "organization_join_code"
    );
    let code = req.code_id.clone();
    main_attribute!(
        "actor.id" = actor_id.to_string(),
        "organization.id" = org_id.to_string(),
        "join_code.id" = code.key.to_string()
    );
    let code_id = RecordId::from(&code);
    let organization_id = RecordId::new("organization", org_id);

    let deleted = transaction_query!(
        Option<JoinCodeRecord>,
        r#"
        BEGIN TRANSACTION;

        LET $deleted = DELETE $code
        WHERE organization = $org
            AND (expires_at IS NONE OR expires_at IS NULL OR expires_at > time::now())
        RETURN BEFORE;

        RETURN $deleted[0];

        COMMIT TRANSACTION;
        "#,
    )
    .bind("code", code_id)
    .bind("org", organization_id)
    .execute()
    .await
    .error_with_slug("join-code-revoke-query-failed")?
    .decode()
    .error_with_slug("join-code-revoke-result-parse-failed")?;
    let deleted = wasmcloud_utils::skir_domain_result!(RevokeOrganizationJoinCodeResponse, deleted);

    if deleted.is_none() {
        main_attribute!("join_code.outcome" = "code_not_found");
        return Ok(skir_variant!(
            RevokeOrganizationJoinCodeResponse::CodeNotFoundError { code_id: code }
        ));
    }

    wasmcloud_utils::skir_subjects::organization_join_codes(org_id)
        .publish(WatchOrganizationJoinCodesResponse::Remove(Box::new(code)))
        .await?;

    main_attribute!("join_code.outcome" = "revoked");
    Ok(skir_variant!(RevokeOrganizationJoinCodeResponse::Success))
}
