//! Organization invitation code reads and lifecycle mutations.
//!
//! Codes are organization owned admission records. Watch snapshots expose only active codes and
//! the organization code sequence. Generation validates every automatic role before creation and
//! revocation removes only an existing, still active code. Successful mutations advance the code
//! sequence and publish the resulting change after commit.

use otel_wasi::{ResultWithSlug, main_attribute, wasi_error};
use serde::Deserialize;
use wasmcloud_utils::{
    database::{DatabaseDuration, RecordId, organization::JoinCodeRecord, transaction_query},
    skir::base::organization::v1::join_codes::*,
    skir_transaction_outcome,
    skir_utils::{IntoSkirRecordIds, IntoSurrealRecordIds},
    skir_variant,
    wasmcloud::messaging::types::NatsMessage,
};

#[derive(Debug, Deserialize)]
#[serde(tag = "outcome", rename_all = "kebab-case")]
enum JoinCodeGenerationOutcome {
    Created { code: JoinCodeRecord, sequence: i64 },
    RolesNotFoundError { role_ids: Vec<RecordId> },
    RolesNotAssignableError { role_ids: Vec<RecordId> },
}

impl JoinCodeGenerationOutcome {
    fn as_str(&self) -> &'static str {
        match self {
            Self::Created { .. } => "created",
            Self::RolesNotFoundError { .. } => "roles-not-found-error",
            Self::RolesNotAssignableError { .. } => "roles-not-assignable-error",
        }
    }
}

/// Returns the current active invitation codes for an organization.
///
/// The snapshot sequence is read with the values and is the recovery point for the organization
/// code change stream. Expired codes are excluded by the database snapshot query.
#[tracing::instrument(skip_all)]
pub async fn handle_watch(
    _msg: NatsMessage,
    scope: wasmcloud_utils::transport_routes::OrganizationActorScope,
    _request: WatchOrganizationJoinCodesRequest,
) -> Result<WatchOrganizationJoinCodesResponse, otel_wasi::Error> {
    let actor_id = scope.user.as_str();
    let org_id = scope.organization.as_str();
    main_attribute!(
        "actor.id" = actor_id.to_string(),
        "organization.id" = org_id.to_string()
    );

    wasmcloud_utils::database::organization::snapshots::join_codes(RecordId::new(
        "organization",
        org_id,
    ))
    .await
}

/// Creates an organization invitation code with an optional expiration and automatic roles.
///
/// A positive duration is stored as the database expiration interval. Zero and negative durations
/// are rejected before any state change. The transaction rejects unknown or protected roles,
/// creates the code and advances its sequence, then publishes the addition after commit.
#[tracing::instrument(skip_all)]
pub async fn handle_generate(
    _msg: NatsMessage,
    scope: wasmcloud_utils::transport_routes::OrganizationActorScope,
    req: GenerateOrganizationJoinCodeRequest,
) -> Result<GenerateOrganizationJoinCodeResponse, otel_wasi::Error> {
    let actor_id = scope.user.as_str();
    let org_id = scope.organization.as_str();
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

    let result = transaction_query!(
        JoinCodeGenerationOutcome,
        r#"
        BEGIN TRANSACTION;
        RETURN {
            LET $requested = SELECT * FROM $roles WHERE organization = $org;
            LET $missing = array::complement(array::distinct($roles), $requested.id);

            IF array::len($missing) > 0 {
                RETURN { outcome: 'roles-not-found-error', role_ids: $missing }
            };

            LET $unassignable = SELECT VALUE id FROM $requested WHERE !assignable;
            IF array::len($unassignable) > 0 {
                RETURN { outcome: 'roles-not-assignable-error', role_ids: $unassignable }
            };

            LET $code = CREATE ONLY organization_join_code SET
                organization = $org,
                created_by = $actor,
                single_use = $single_use,
                auto_accept_roles = $roles,
                expires_at = IF $duration = NONE OR $duration = NULL { NULL } ELSE { time::now() + $duration };

            LET $sequence = UPDATE ONLY $org SET join_codes_sequence += 1
                RETURN VALUE join_codes_sequence;

            RETURN {
                outcome: 'created',
                code: (SELECT id, created_at, expires_at, single_use, auto_accept_roles FROM ONLY $code),
                sequence: $sequence
            };
        };
        COMMIT TRANSACTION;
        "#,
    )
    .bind("org", organization_id)
    .bind("actor", actor_id)
    .bind("single_use", req.single_use)
    .bind("roles", role_ids)
    .bind("duration", expiration)
    .execute()
    .await
    .error_with_slug("join-code-generate-query-failed")?
    .decode()
    .error_with_slug("join-code-generate-result-parse-failed")?;

    let result = wasmcloud_utils::skir_domain_result!(GenerateOrganizationJoinCodeResponse, result);
    main_attribute!("join_code.outcome" = result.as_str());
    let row = skir_transaction_outcome!(
        GenerateOrganizationJoinCodeResponse,
        result,
        success JoinCodeGenerationOutcome::Created { code, sequence } => (code, sequence),
        errors {
            JoinCodeGenerationOutcome::RolesNotFoundError { role_ids } => {
                role_ids: role_ids.into_skir_record_ids()
            },
            JoinCodeGenerationOutcome::RolesNotAssignableError { role_ids } => {
                role_ids: role_ids.into_skir_record_ids()
            },
        }
    );

    let (code, sequence) = row;
    let code: JoinCode = code.into();
    let event = OrganizationJoinCodesChanged {
        sequence,
        changes: vec![OrganizationJoinCodesChange::Add(Box::new(code.clone()))],
        ..Default::default()
    };
    wasmcloud_utils::transport_routes::OrganizationJoinCodesWatchRoute::delivery(
        &wasmcloud_utils::transport_routes::OrganizationScope::try_from(org_id)?,
    )
    .persist(event.clone())
    .await?;

    main_attribute!(
        "join_code.outcome" = "generated",
        "join_code.id" = code.code.key.to_string()
    );

    Ok(skir_variant!(
        GenerateOrganizationJoinCodeResponse::Success { code, event }
    ))
}

/// Revokes an active invitation code and publishes its removal.
///
/// Expired, missing, or already revoked codes return a not found response without advancing the
/// organization code sequence.
#[tracing::instrument(skip_all)]
pub async fn handle_revoke(
    _msg: NatsMessage,
    scope: wasmcloud_utils::transport_routes::OrganizationActorScope,
    req: RevokeOrganizationJoinCodeRequest,
) -> Result<RevokeOrganizationJoinCodeResponse, otel_wasi::Error> {
    let actor_id = scope.user.as_str();
    let org_id = scope.organization.as_str();
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

    #[derive(Deserialize)]
    struct RevokedJoinCode {
        sequence: i64,
    }

    let deleted = transaction_query!(
        Option<RevokedJoinCode>,
        r#"
        BEGIN TRANSACTION;
        RETURN {
            LET $deleted = DELETE $code
                WHERE organization = $org
                AND (expires_at IS NONE OR expires_at IS NULL OR expires_at > time::now())
            RETURN BEFORE;

            IF array::len($deleted) = 0 { RETURN NONE };
            LET $sequence = UPDATE ONLY $org SET join_codes_sequence += 1
                RETURN VALUE join_codes_sequence;
            RETURN { sequence: $sequence };
        };
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

    let deleted = deleted.expect("checked above");
    let event = OrganizationJoinCodesChanged {
        sequence: deleted.sequence,
        changes: vec![OrganizationJoinCodesChange::Remove(Box::new(code.clone()))],
        ..Default::default()
    };
    wasmcloud_utils::transport_routes::OrganizationJoinCodesWatchRoute::delivery(
        &wasmcloud_utils::transport_routes::OrganizationScope::try_from(org_id)?,
    )
    .persist(event.clone())
    .await?;

    main_attribute!("join_code.outcome" = "revoked");
    Ok(skir_variant!(RevokeOrganizationJoinCodeResponse::Success {
        event
    }))
}
