use std::collections::HashMap;

use otel_wasi::ResultWithSlug;
use serde::Deserialize;
use wasmcloud_utils::{
    database::{
        RecordId as DatabaseRecordId, read_query, transaction_query, transaction_query_file,
    },
    decode_skir, extract_param,
    skir::base::{
        kernel::v1::record_id::RecordId,
        organization::v1::{
            join_codes::*, join_request::*, member::*, role::OrganizationRole, user::*,
        },
    },
    skir_domain_result, skir_variant,
    wasmcloud::messaging::types::BrokerMessage,
};

use wasmcloud_utils::database::organization::{
    OrganizationRecord,
    projections::{JoinRequestProjection, OrganizationMemberProjection},
};

#[derive(Debug, Deserialize)]
#[serde(tag = "kind", rename_all = "snake_case")]
enum JoinSubmissionOutcome {
    CodeNotFoundError,
    AlreadyMemberError,
    NoAssignableRolesError,
    MaxPendingRequestsError,
    PendingRequestExistsError,
    RequestMade {
        request: JoinRequestProjection,
        single_use: bool,
    },
    AutoAccepted {
        organization: OrganizationRecord,
        member: OrganizationMemberProjection,
        single_use: bool,
    },
}

#[tracing::instrument(skip(msg, params))]
pub async fn handle_watch(
    msg: BrokerMessage,
    params: HashMap<String, String>,
) -> Result<WatchUserJoinRequestsResponse, otel_wasi::Error> {
    let user_id = extract_param!(params, user_id)?;
    otel_wasi::main_attribute!("user.id" = user_id.to_string());
    let _request = decode_skir!(WatchUserJoinRequestsRequest, &msg.body)?;

    let user_id = DatabaseRecordId::new("user", user_id);
    let join_requests = read_query!(
        r#"
        SELECT
            id,
            in.* as user,
            out.* as organization,
            requested_at,
            expires_at
        FROM request_to_join
        WHERE in = $user_id
          AND expires_at > time::now()
        "#,
    )
    .bind("user_id", user_id)
    .execute()
    .await
    .error_with_slug("join-request-watch-query-failed")?
    .take::<Vec<JoinRequestProjection>>()
    .error_with_slug("join-request-watch-result-parse-failed")?
    .into_iter()
    .map(UserJoinRequest::from)
    .collect::<Vec<_>>();

    otel_wasi::main_attribute!(
        "join_request.result_count" = join_requests.len() as i64,
        "join_request.outcome" = "listed"
    );
    Ok(WatchUserJoinRequestsResponse::List(join_requests))
}

#[tracing::instrument(skip(msg, params))]
pub async fn handle_request(
    msg: BrokerMessage,
    params: HashMap<String, String>,
) -> Result<SubmitUserJoinRequestResponse, otel_wasi::Error> {
    let user_id = extract_param!(params, user_id)?;
    otel_wasi::main_attribute!("user.id" = user_id.to_string());
    let user_key = user_id;
    let user_id = DatabaseRecordId::new("user", user_key);
    let request = decode_skir!(SubmitUserJoinRequestRequest, &msg.body)?;
    wasmcloud_utils::validate_record_ids!(
        SubmitUserJoinRequestResponse,
        request.code,
        "organization_join_code"
    );

    let code = request.code;
    let result = transaction_query_file!(
        JoinSubmissionOutcome,
        "src/join_submission_transaction.surql",
    )
    .bind("user", user_id)
    .bind("code", DatabaseRecordId::from(&code))
    .execute()
    .await
    .error_with_slug("join-request-query-failed")?
    .decode()
    .error_with_slug("join-request-result-parse-failed")?;

    let outcome = skir_domain_result!(SubmitUserJoinRequestResponse, result);
    match outcome {
        JoinSubmissionOutcome::CodeNotFoundError => {
            otel_wasi::main_attribute!("join_request.outcome" = "code_not_found");
            Ok(skir_variant!(
                SubmitUserJoinRequestResponse::CodeNotFoundError { code }
            ))
        }
        JoinSubmissionOutcome::AlreadyMemberError => {
            otel_wasi::main_attribute!("join_request.outcome" = "already_member_error");
            Ok(skir_variant!(
                SubmitUserJoinRequestResponse::AlreadyMemberError
            ))
        }
        JoinSubmissionOutcome::NoAssignableRolesError => {
            otel_wasi::main_attribute!("join_request.outcome" = "no_assignable_roles_error");
            Ok(skir_variant!(
                SubmitUserJoinRequestResponse::NoAssignableRolesError
            ))
        }
        JoinSubmissionOutcome::MaxPendingRequestsError => {
            otel_wasi::main_attribute!("join_request.outcome" = "max_pending_requests_error");
            Ok(skir_variant!(
                SubmitUserJoinRequestResponse::MaxPendingRequestsError
            ))
        }
        JoinSubmissionOutcome::PendingRequestExistsError => {
            otel_wasi::main_attribute!("join_request.outcome" = "pending_request_exists_error");
            Ok(skir_variant!(
                SubmitUserJoinRequestResponse::PendingRequestExistsError
            ))
        }
        JoinSubmissionOutcome::RequestMade {
            request,
            single_use,
        } => {
            let organization_id = request.organization.id.key.to_string();
            wasmcloud_utils::skir_subjects::user_join_requests(user_key)
                .publish(WatchUserJoinRequestsResponse::Add(Box::new(
                    request.clone().into(),
                )))
                .await?;
            wasmcloud_utils::skir_subjects::organization_join_requests(&organization_id)
                .publish(WatchOrganizationJoinRequestsResponse::Add(Box::new(
                    request.clone().into(),
                )))
                .await?;
            publish_consumed_code(&organization_id, &code, single_use).await?;

            otel_wasi::main_attribute!("join_request.outcome" = "request_made");
            Ok(SubmitUserJoinRequestResponse::RequestMade(Box::new(
                request.into(),
            )))
        }
        JoinSubmissionOutcome::AutoAccepted {
            organization,
            member,
            single_use,
        } => {
            let organization_id = organization.id.key.to_string();
            let roles = member
                .roles
                .iter()
                .cloned()
                .map(OrganizationRole::from)
                .collect();
            wasmcloud_utils::skir_subjects::user_organizations(user_key)
                .publish(WatchUserOrganizationsResponse::Add(Box::new(
                    organization.clone().into(),
                )))
                .await?;
            wasmcloud_utils::skir_subjects::organization_members(&organization_id)
                .publish(WatchOrganizationMembersResponse::Add(Box::new(
                    member.into(),
                )))
                .await?;
            publish_consumed_code(&organization_id, &code, single_use).await?;

            otel_wasi::main_attribute!("join_request.outcome" = "auto_accepted");
            Ok(SubmitUserJoinRequestResponse::AutoAccepted(Box::new(
                AutoAcceptedMember {
                    organization_id: organization.id.into(),
                    organization_name: organization.name,
                    organization_logo_url: organization.logo_url,
                    roles,
                    _unrecognized: None,
                },
            )))
        }
    }
}

async fn publish_consumed_code(
    organization_id: &str,
    code: &RecordId,
    single_use: bool,
) -> Result<(), otel_wasi::Error> {
    if single_use {
        wasmcloud_utils::skir_subjects::organization_join_codes(organization_id)
            .publish(WatchOrganizationJoinCodesResponse::Remove(
                code.clone().into(),
            ))
            .await?;
    }
    Ok(())
}

#[tracing::instrument(skip(msg, params))]
pub async fn handle_cancel(
    msg: BrokerMessage,
    params: HashMap<String, String>,
) -> Result<CancelUserJoinRequestResponse, otel_wasi::Error> {
    let user_id = extract_param!(params, user_id)?;
    otel_wasi::main_attribute!("user.id" = user_id.to_string());
    let user_key = user_id;
    let user_id = DatabaseRecordId::new("user", user_id);
    let request = decode_skir!(CancelUserJoinRequestRequest, &msg.body)?;
    wasmcloud_utils::validate_record_ids!(
        CancelUserJoinRequestResponse,
        request.request_id,
        "request_to_join"
    );

    let request_id = request.request_id;

    let join_request = transaction_query!(
        Option<JoinRequestProjection>,
        r#"
            BEGIN TRANSACTION;

            LET $request = SELECT id, in.* as user, out.* as organization, requested_at, expires_at FROM $request
            WHERE in = $user_id;

            DELETE $request.id;

            RETURN $request[0];
            COMMIT TRANSACTION;
            "#,
    )
    .bind(
        "request",
        DatabaseRecordId::from(&request_id),
    )
    .bind("user_id", user_id)
    .execute()
    .await
    .error_with_slug("join-request-cancel-query-failed")?
    .decode()
    .error_with_slug("join-request-cancel-result-parse-failed")?;
    let join_request = skir_domain_result!(CancelUserJoinRequestResponse, join_request);

    let Some(join_request) = join_request else {
        otel_wasi::main_attribute!("join_request.outcome" = "request_not_found");
        return Ok(skir_variant!(
            CancelUserJoinRequestResponse::RequestNotFoundError { request_id }
        ));
    };

    wasmcloud_utils::skir_subjects::user_join_requests(user_key)
        .publish(WatchUserJoinRequestsResponse::Remove(Box::new(
            join_request.id.clone().into(),
        )))
        .await?;

    wasmcloud_utils::skir_subjects::organization_join_requests(
        join_request.organization.id.key.to_string(),
    )
    .publish(WatchOrganizationJoinRequestsResponse::Remove(Box::new(
        join_request.id.into(),
    )))
    .await?;

    otel_wasi::main_attribute!(
        "organization.id" = join_request.organization.id.key.to_string(),
        "join_request.outcome" = "cancelled"
    );
    Ok(skir_variant!(CancelUserJoinRequestResponse::Success))
}
