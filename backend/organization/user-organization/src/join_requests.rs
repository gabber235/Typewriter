use std::collections::HashMap;

use otel_wasi::ResultWithSlug;
use serde::Deserialize;
use wasmcloud_utils::{
    database::{RecordId as DatabaseRecordId, transaction_query, transaction_query_file},
    decode_skir, extract_param,
    skir::base::organization::v1::{join_request::*, role::OrganizationRole, user::*},
    skir_domain_result, skir_variant,
    wasmcloud::messaging::types::NatsMessage,
};

use wasmcloud_utils::database::organization::{
    OrganizationRecord,
    projections::{JoinRequestProjection, OrganizationMemberProjection},
};

/// Transaction outcomes for submitting a join code.
///
/// The successful variants carry the projection values and sequence numbers produced by the
/// same transaction. The handler uses those values to publish the user view, the organization
/// view, and, for a single use code, the code removal without rereading mutable state.
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
        code_id: DatabaseRecordId,
        user_sequence: i64,
        organization_sequence: i64,
        join_codes_sequence: Option<i64>,
    },
    AutoAccepted {
        organization: OrganizationRecord,
        member: OrganizationMemberProjection,
        single_use: bool,
        code_id: DatabaseRecordId,
        user_sequence: i64,
        organization_sequence: i64,
        join_codes_sequence: Option<i64>,
    },
}

/// Database result from deleting a pending request and advancing both request view sequences.
///
/// The request projection is retained so cancellation can publish the organization view after
/// the edge has been deleted.
#[derive(Debug, Deserialize)]
struct CancelledJoinRequest {
    request: JoinRequestProjection,
    user_sequence: i64,
    organization_sequence: i64,
}

/// Returns the user's current unexpired join requests.
///
/// The snapshot carries the sequence owned by the user request projection. Request creation and
/// cancellation publish later changes on that same user stream.
#[tracing::instrument(skip(msg, params))]
pub async fn handle_watch(
    msg: NatsMessage,
    params: HashMap<String, String>,
) -> Result<WatchUserJoinRequestsResponse, otel_wasi::Error> {
    let user_id = extract_param!(params, user_id)?;
    otel_wasi::main_attribute!("user.id" = user_id.to_string());
    let _request = decode_skir!(WatchUserJoinRequestsRequest, &msg.body)?;

    wasmcloud_utils::database::organization::snapshots::user_join_requests(DatabaseRecordId::new(
        "user", user_id,
    ))
    .await
}

/// Submits a join code for the user in the message subject.
///
/// The transaction rejects expired or invalid admission state, then either creates a pending
/// request or creates membership with the code's assignable roles. It also advances every affected
/// projection sequence and atomically consumes a single use code. Successful outcomes publish the
/// resulting user and organization changes after commit and return the user scoped event.
#[tracing::instrument(skip(msg, params))]
pub async fn handle_request(
    msg: NatsMessage,
    params: HashMap<String, String>,
) -> Result<SubmitUserJoinRequestResponse, otel_wasi::Error> {
    let user_id = extract_param!(params, user_id)?;
    otel_wasi::main_attribute!("user.id" = user_id.to_string());
    let user_key = user_id;
    let user_id = DatabaseRecordId::new("user", user_key);
    let request = decode_skir!(SubmitUserJoinRequestRequest, &msg.body)?;
    if request.operation_id.is_empty() {
        return Ok(wasmcloud_utils::skir_variant!(
            SubmitUserJoinRequestResponse::InvalidOperationIdError
        ));
    }
    let receipt = wasmcloud_utils::database::mutation::receipt_id(
        user_key,
        "join_requests",
        "SubmitUserJoinRequest",
        &request.operation_id,
    );
    let operation_id = request.operation_id.clone();
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
    .bind("receipt", receipt)
    .bind("request_bytes", msg.body.clone())
    .execute()
    .await
    .error_with_slug("join-request-query-failed")?
    .decode()
    .error_with_slug("join-request-result-parse-failed")?;

    let outcome = skir_domain_result!(SubmitUserJoinRequestResponse, result,
        "operation-identity-reused-error" => {});
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
            code_id,
            user_sequence,
            organization_sequence,
            join_codes_sequence,
        } => {
            let organization_id = request.organization.id.key.to_string();
            let user_request: UserJoinRequest = request.clone().into();
            let user_event = UserJoinRequestsChanged {
                sequence: user_sequence,
                operation_id: operation_id.clone(),
                changes: vec![UserJoinRequestsChange::Add(Box::new(user_request.clone()))],
                ..Default::default()
            };
            wasmcloud_utils::skir_subjects::user_join_requests_changed(user_key)
                .persist(user_event.clone())
                .await?;
            let organization_event = OrganizationJoinRequestsChanged {
                sequence: organization_sequence,
                operation_id: operation_id.clone(),
                changes: vec![OrganizationJoinRequestsChange::Add(Box::new(
                    request.clone().into(),
                ))],
                ..Default::default()
            };
            wasmcloud_utils::skir_subjects::organization_join_requests_changed(&organization_id)
                .persist(organization_event)
                .await?;
            publish_consumed_code(
                &organization_id,
                single_use,
                code_id,
                join_codes_sequence,
                &operation_id,
            )
            .await?;

            otel_wasi::main_attribute!("join_request.outcome" = "request_made");
            Ok(skir_variant!(SubmitUserJoinRequestResponse::RequestMade {
                request: user_request,
                event: user_event
            }))
        }
        JoinSubmissionOutcome::AutoAccepted {
            organization,
            member,
            single_use,
            code_id,
            user_sequence,
            organization_sequence,
            join_codes_sequence,
        } => {
            let organization_id = organization.id.key.to_string();
            let roles = member
                .roles
                .iter()
                .cloned()
                .map(OrganizationRole::from)
                .collect();
            let organization_value: wasmcloud_utils::skir::base::organization::v1::organization::Organization =
                organization.clone().into();
            let user_event = wasmcloud_utils::skir::base::organization::v1::organization::UserOrganizationsChanged {
                sequence: user_sequence,
                operation_id: operation_id.clone(),
                changes: vec![wasmcloud_utils::skir::base::organization::v1::organization::UserOrganizationsChange::Add(Box::new(organization_value))],
                ..Default::default()
            };
            wasmcloud_utils::skir_subjects::user_organizations_changed(user_key)
                .persist(user_event.clone())
                .await?;
            let member_value: wasmcloud_utils::skir::base::organization::v1::member::OrganizationMember =
                member.clone().into();
            let member_event = wasmcloud_utils::skir::base::organization::v1::member::OrganizationMembersChanged {
                sequence: organization_sequence,
                operation_id: operation_id.clone(),
                changes: vec![wasmcloud_utils::skir::base::organization::v1::member::OrganizationMembersChange::Add(Box::new(member_value))],
                ..Default::default()
            };
            wasmcloud_utils::skir_subjects::organization_members_changed(&organization_id)
                .persist(member_event)
                .await?;
            publish_consumed_code(
                &organization_id,
                single_use,
                code_id,
                join_codes_sequence,
                &operation_id,
            )
            .await?;

            otel_wasi::main_attribute!("join_request.outcome" = "auto_accepted");
            Ok(skir_variant!(SubmitUserJoinRequestResponse::AutoAccepted {
                member: AutoAcceptedMember {
                    organization_id: organization.id.into(),
                    organization_name: organization.name,
                    organization_logo_url: organization.logo_url,
                    roles,
                    _unrecognized: None,
                },
                event: user_event
            }))
        }
    }
}

/// Persists the removal event for a consumed single use code.
///
/// A sequence is mandatory when the transaction deleted the code. A missing sequence indicates a
/// mismatch between the transaction result and the publication contract, so it fails rather than
/// emitting an unsequenced change.
async fn publish_consumed_code(
    organization_id: &str,
    single_use: bool,
    code_id: DatabaseRecordId,
    sequence: Option<i64>,
    operation_id: &str,
) -> Result<(), otel_wasi::Error> {
    if single_use {
        let event = wasmcloud_utils::skir::base::organization::v1::join_codes::OrganizationJoinCodesChanged {
            sequence: sequence.ok_or_else(|| otel_wasi::Error::new(
                "join-code-sequence-missing",
                "single use code mutation omitted its sequence",
            ))?,
            operation_id: operation_id.to_owned(),
            changes: vec![wasmcloud_utils::skir::base::organization::v1::join_codes::OrganizationJoinCodesChange::Remove(Box::new(code_id.into()))],
            ..Default::default()
        };
        wasmcloud_utils::skir_subjects::organization_join_codes_changed(organization_id)
            .persist(event)
            .await?;
    }
    Ok(())
}

/// Cancels one pending request owned by the user in the message subject.
///
/// The transaction deletes the request and advances both the user and organization request
/// sequences. The handler then persists removal changes to both projections. A missing request is
/// returned as a domain result and produces no change event.
#[tracing::instrument(skip(msg, params))]
pub async fn handle_cancel(
    msg: NatsMessage,
    params: HashMap<String, String>,
) -> Result<CancelUserJoinRequestResponse, otel_wasi::Error> {
    let user_id = extract_param!(params, user_id)?;
    otel_wasi::main_attribute!("user.id" = user_id.to_string());
    let user_key = user_id;
    let user_id = DatabaseRecordId::new("user", user_id);
    let request = decode_skir!(CancelUserJoinRequestRequest, &msg.body)?;
    if request.operation_id.is_empty() {
        return Ok(wasmcloud_utils::skir_variant!(
            CancelUserJoinRequestResponse::InvalidOperationIdError
        ));
    }
    let receipt = wasmcloud_utils::database::mutation::receipt_id(
        user_key,
        "join_requests",
        "CancelUserJoinRequest",
        &request.operation_id,
    );
    wasmcloud_utils::validate_record_ids!(
        CancelUserJoinRequestResponse,
        request.request_id,
        "request_to_join"
    );

    let request_id = request.request_id;

    let join_request = transaction_query!(
        Option<CancelledJoinRequest>,
        r#"
            BEGIN TRANSACTION;
        RETURN {
            LET $previous = fn::mutation::recall($receipt, $request_bytes);
            IF $previous != NONE { RETURN $previous.value };
            LET $result = {
LET $request = SELECT id, in.* as user, out.* as organization, requested_at, expires_at FROM $request
            WHERE in = $user_id;

            IF array::len($request) = 0 { RETURN NONE };
            DELETE $request.id;
            LET $user_sequence = UPDATE ONLY $user_id SET join_requests_sequence += 1
                RETURN VALUE join_requests_sequence;
            LET $organization_sequence = UPDATE ONLY $request[0].organization.id SET join_requests_sequence += 1
                RETURN VALUE join_requests_sequence;

            RETURN {
                request: $request[0],
                user_sequence: $user_sequence,
                organization_sequence: $organization_sequence
            };
            };
            IF $result != NONE {
                LET $stored = fn::mutation::commit($receipt, $request_bytes, { value: $result });
                RETURN $stored.value;
            };
            RETURN $result;
        };
        COMMIT TRANSACTION;
            "#,
    )
    .bind(
        "request",
        DatabaseRecordId::from(&request_id),
    )
    .bind("user_id", user_id)
    .bind("receipt", receipt)
    .bind("request_bytes", msg.body.clone())
    .execute()
    .await
    .error_with_slug("join-request-cancel-query-failed")?
    .decode()
    .error_with_slug("join-request-cancel-result-parse-failed")?;
    let join_request = skir_domain_result!(CancelUserJoinRequestResponse, join_request,
        "operation-identity-reused-error" => {});

    let Some(join_request) = join_request else {
        otel_wasi::main_attribute!("join_request.outcome" = "request_not_found");
        return Ok(skir_variant!(
            CancelUserJoinRequestResponse::RequestNotFoundError { request_id }
        ));
    };

    let event = UserJoinRequestsChanged {
        sequence: join_request.user_sequence,
        operation_id: request.operation_id.clone(),
        changes: vec![UserJoinRequestsChange::Remove(Box::new(request_id.clone()))],
        ..Default::default()
    };
    wasmcloud_utils::skir_subjects::user_join_requests_changed(user_key)
        .persist(event.clone())
        .await?;

    let organization_event = OrganizationJoinRequestsChanged {
        sequence: join_request.organization_sequence,
        operation_id: request.operation_id,
        changes: vec![OrganizationJoinRequestsChange::Remove(Box::new(request_id))],
        ..Default::default()
    };
    wasmcloud_utils::skir_subjects::organization_join_requests_changed(
        join_request.request.organization.id.key.to_string(),
    )
    .persist(organization_event)
    .await?;

    otel_wasi::main_attribute!(
        "organization.id" = join_request.request.organization.id.key.to_string(),
        "join_request.outcome" = "cancelled"
    );
    Ok(skir_variant!(CancelUserJoinRequestResponse::Success {
        event
    }))
}
