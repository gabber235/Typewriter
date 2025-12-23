use std::collections::HashMap;

use chrono::{Duration, Utc};
use prost::Message;
use surrealdb_component::query;
use typewriter::api::v1::join_code_expiration::Expiration;
use wasmcloud_component::{debug, info, trace};
use wasmcloud_utils::{
    extract_param, extract_params, internal_error_fn,
    wasmcloud::messaging::{reply, types::BrokerMessage},
};

use crate::{
    refresh,
    typewriter::{self, api::v1::JoinCodeExpiration},
    JoinCodeRecord,
};

pub fn handle_list(msg: BrokerMessage, params: HashMap<String, String>) -> Result<(), String> {
    debug!("handle_list (join_codes) invoked");
    let org_id = extract_param!(params, org_id);

    let _request = typewriter::api::v1::ListJoinCodesRequest::decode(&msg.body[..])
        .map_err(|e| format!("failed to decode request: {}", e))?;
    trace!("Decoded ListJoinCodesRequest");

    let result = query(
        r#"
        SELECT * FROM join_code
        WHERE organization = type::thing('organization', $org_id)
          AND (expires_at IS NONE OR expires_at > time::now())
        ORDER BY created_at DESC
        "#,
    )
    .bind("org_id", org_id)
    .execute()
    .map_err(|e| format!("failed to query join codes: {}", e))?;
    trace!("Query executed successfully");

    let join_codes_data: Vec<JoinCodeRecord> = result
        .take(0)
        .map_err(|e| format!("failed to take result: {}", e))?;
    trace!("Fetched join codes data: {:?}", join_codes_data);

    let join_codes: Vec<typewriter::models::v1::JoinCode> = join_codes_data
        .into_iter()
        .map(|record| record.into())
        .collect();
    trace!("Converted to JoinCode structs: {:?}", join_codes);

    let response = typewriter::api::v1::ListJoinCodesResponse {
        result: Some(
            typewriter::api::v1::list_join_codes_response::Result::JoinCodes(
                typewriter::api::v1::ListJoinCodes { join_codes },
            ),
        ),
    };
    trace!("Prepared ListJoinCodesResponse");

    reply(msg, response.encode_to_vec())
}

pub fn handle_generate(msg: BrokerMessage, params: HashMap<String, String>) -> Result<(), String> {
    debug!("handle_generate (join_codes) invoked");
    let (org_id, user_id) = extract_params!(params, org_id, user_id);

    let request = typewriter::api::v1::GenerateJoinCodeRequest::decode(&msg.body[..])
        .map_err(|e| format!("failed to decode request: {}", e))?;
    trace!("Decoded GenerateJoinCodeRequest: {:?}", request);

    let single_use = request.single_use;

    let expires_at = match request.expiration {
        Some(JoinCodeExpiration {
            expiration: Some(Expiration::Never(true)),
        }) => None,
        Some(JoinCodeExpiration {
            expiration: Some(Expiration::DurationSeconds(duration)),
        }) => Some(Utc::now() + Duration::seconds(duration)),
        _ => Some(Utc::now() + Duration::days(7)),
    };

    let auto_accept_role_ids: Vec<String> = request
        .auto_accept
        .map(|config| config.role_ids)
        .unwrap_or_default();

    let result = query(
        r#"
        BEGIN TRANSACTION;

        LET $org = type::thing('organization', $org_id);

        LET $auto_accept_roles = SELECT VALUE id FROM $auto_accept_role_ids.map(|$id| type::thing('role', $id)) WHERE organization = $org AND assignable == true;

        CREATE join_code SET
            organization = $org,
            created_by = type::thing('user', $user_id),
            single_use = $single_use,
            expires_at = <option<datetime>>$expires_at,
            auto_accept_roles = $auto_accept_roles
        RETURN AFTER;

        COMMIT TRANSACTION;
        "#,
    )
    .bind("org_id", org_id)
    .bind("user_id", user_id)
    .bind("single_use", single_use)
    .bind("expires_at", expires_at)
    .bind("auto_accept_role_ids", auto_accept_role_ids)
    .execute()
    .map_err(|e| format!("failed to create join code: {}", e))?;
    trace!("Create executed successfully");

    let join_code_record: Option<JoinCodeRecord> = result
        .take(2)
        .map_err(|e| format!("failed to parse result: {}", e))?;

    let join_code_record = join_code_record.ok_or("failed to create join code")?;
    trace!("Created join code record: {:?}", join_code_record);

    let join_code = join_code_record.into();

    let response = typewriter::api::v1::GenerateJoinCodeResponse {
        result: Some(typewriter::api::v1::generate_join_code_response::Result::JoinCode(join_code)),
    };
    trace!("Prepared GenerateJoinCodeResponse");

    reply(msg, response.encode_to_vec())?;

    refresh::refresh_organization_members_join_codes_list(org_id, params.get("user_id"))?;
    Ok(())
}

pub fn handle_revoke(msg: BrokerMessage, params: HashMap<String, String>) -> Result<(), String> {
    debug!("handle_revoke (join_codes) invoked");
    let org_id = extract_param!(params, org_id);

    let request = typewriter::api::v1::RevokeJoinCodeRequest::decode(&msg.body[..])
        .map_err(|e| format!("failed to decode request: {}", e))?;
    trace!("Decoded RevokeJoinCodeRequest: {:?}", request);

    let code_id = request.code_id;

    info!("Revoking join code '{}'", code_id);

    query("DELETE type::thing('join_code', $code_id)")
        .bind("code_id", &code_id)
        .execute()
        .map_err(|e| format!("failed to revoke join code: {}", e))?;
    trace!("Delete executed successfully");

    let response = typewriter::api::v1::RevokeJoinCodeResponse {
        result: Some(typewriter::api::v1::revoke_join_code_response::Result::Success(true)),
    };
    trace!("Prepared RevokeJoinCodeResponse");

    reply(msg, response.encode_to_vec())?;

    refresh::refresh_organization_members_join_codes_list(org_id, params.get("user_id"))?;
    Ok(())
}

internal_error_fn!(
    internal_error_generate,
    typewriter::api::v1::GenerateJoinCodeResponse,
    generate_join_code_response,
    "Internal Server Error when generating join code"
);

internal_error_fn!(
    internal_error_list,
    typewriter::api::v1::ListJoinCodesResponse,
    list_join_codes_response,
    "Internal Server Error when listing join codes"
);

internal_error_fn!(
    internal_error_revoke,
    typewriter::api::v1::RevokeJoinCodeResponse,
    revoke_join_code_response,
    "Internal Server Error when revoking join code"
);
