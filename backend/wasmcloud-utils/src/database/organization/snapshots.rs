//! Current organization read snapshots used by watch responses and recovery publication.
//!
//! Each snapshot reads current database state and its sequence together. Conversion and
//! publication remain caller responsibilities after the read succeeds.

use otel_wasi::ResultWithSlug;
use serde::Deserialize;

use super::{
    JoinCodeRecord, OrganizationRecord,
    projections::{JoinRequestProjection, OrganizationMemberProjection},
};
use crate::{
    database::{RecordId, read_query},
    skir::base::organization::v1::{
        join_codes::{OrganizationJoinCodesSnapshot, WatchOrganizationJoinCodesResponse},
        join_request::{
            OrganizationJoinRequestsSnapshot, UserJoinRequestsSnapshot,
            WatchOrganizationJoinRequestsResponse,
        },
        member::{OrganizationMembersSnapshot, WatchOrganizationMembersResponse},
        organization::UserOrganizationsSnapshot,
        user::{WatchUserJoinRequestsResponse, WatchUserOrganizationsResponse},
    },
};

/// Database shape shared by snapshots that expose a sequence and current values.
#[derive(Deserialize)]
struct SnapshotRow<T> {
    sequence: i64,
    values: Vec<T>,
}

/// Reads the current organization members and their sequence for a watch snapshot.
///
/// The sequence belongs to the current read model. It is not evidence that a later publication
/// succeeded.
pub async fn members(
    organization: RecordId,
) -> Result<WatchOrganizationMembersResponse, otel_wasi::Error> {
    let snapshot = read_query!(
        r#"
        RETURN {
            sequence: (SELECT VALUE members_sequence FROM ONLY $organization),
            values: (SELECT in.id AS user_id, in.name AS name, in.email AS email,
                in.avatar_url AS avatar_url, roles.* AS roles, joined_at
                FROM member_of WHERE out = $organization FETCH roles)
        }
    "#
    )
    .bind("organization", organization)
    .execute()
    .await
    .error_with_slug("member-snapshot-query-failed")?
    .parse::<SnapshotRow<OrganizationMemberProjection>>()
    .error_with_slug("member-snapshot-parse-failed")?;
    Ok(WatchOrganizationMembersResponse::Snapshot(Box::new(
        OrganizationMembersSnapshot {
            sequence: snapshot.sequence,
            values: snapshot.values.into_iter().map(Into::into).collect(),
            ..Default::default()
        },
    )))
}

/// Reads the current organizations visible to a user and their sequence.
pub async fn organizations(
    user: RecordId,
) -> Result<WatchUserOrganizationsResponse, otel_wasi::Error> {
    let snapshot = read_query!(
        "RETURN {
            sequence: (SELECT VALUE organizations_sequence FROM ONLY $user),
            values: (SELECT VALUE ->member_of->organization.* FROM ONLY $user)
        }"
    )
    .bind("user", user)
    .execute()
    .await
    .error_with_slug("organization-snapshot-query-failed")?
    .parse::<SnapshotRow<OrganizationRecord>>()
    .error_with_slug("organization-snapshot-parse-failed")?;
    Ok(WatchUserOrganizationsResponse::Snapshot(Box::new(
        UserOrganizationsSnapshot {
            sequence: snapshot.sequence,
            values: snapshot.values.into_iter().map(Into::into).collect(),
            ..Default::default()
        },
    )))
}

/// Reads unexpired join requests for an organization and their sequence.
pub async fn join_requests(
    organization: RecordId,
) -> Result<WatchOrganizationJoinRequestsResponse, otel_wasi::Error> {
    let snapshot = read_query!(
        r#"
        RETURN {
            sequence: (SELECT VALUE join_requests_sequence FROM ONLY $organization),
            values: (SELECT id, in.* AS user, out.* AS organization, requested_at, expires_at
                FROM request_to_join WHERE out = $organization AND expires_at > time::now())
        }
    "#
    )
    .bind("organization", organization)
    .execute()
    .await
    .error_with_slug("organization-join-request-snapshot-query-failed")?
    .parse::<SnapshotRow<JoinRequestProjection>>()
    .error_with_slug("organization-join-request-snapshot-parse-failed")?;
    Ok(WatchOrganizationJoinRequestsResponse::Snapshot(Box::new(
        OrganizationJoinRequestsSnapshot {
            sequence: snapshot.sequence,
            values: snapshot.values.into_iter().map(Into::into).collect(),
            ..Default::default()
        },
    )))
}

/// Reads unexpired join requests for a user and their sequence.
pub async fn user_join_requests(
    user: RecordId,
) -> Result<WatchUserJoinRequestsResponse, otel_wasi::Error> {
    let snapshot = read_query!(
        r#"
        RETURN {
            sequence: (SELECT VALUE join_requests_sequence FROM ONLY $user),
            values: (SELECT id, in.* AS user, out.* AS organization, requested_at, expires_at
                FROM request_to_join WHERE in = $user AND expires_at > time::now())
        }
    "#
    )
    .bind("user", user)
    .execute()
    .await
    .error_with_slug("user-join-request-snapshot-query-failed")?
    .parse::<SnapshotRow<JoinRequestProjection>>()
    .error_with_slug("user-join-request-snapshot-parse-failed")?;
    Ok(WatchUserJoinRequestsResponse::Snapshot(Box::new(
        UserJoinRequestsSnapshot {
            sequence: snapshot.sequence,
            values: snapshot.values.into_iter().map(Into::into).collect(),
            ..Default::default()
        },
    )))
}

/// Reads current unexpired join codes for an organization and their sequence.
pub async fn join_codes(
    organization: RecordId,
) -> Result<WatchOrganizationJoinCodesResponse, otel_wasi::Error> {
    let snapshot = read_query!(
        r#"
        RETURN {
            sequence: (SELECT VALUE join_codes_sequence FROM ONLY $organization),
            values: (SELECT id, created_at, expires_at, single_use, auto_accept_roles
                FROM organization_join_code WHERE organization = $organization
                    AND (expires_at IS NONE OR expires_at IS NULL OR expires_at > time::now())
                ORDER BY created_at DESC)
        }
    "#
    )
    .bind("organization", organization)
    .execute()
    .await
    .error_with_slug("join-code-snapshot-query-failed")?
    .parse::<SnapshotRow<JoinCodeRecord>>()
    .error_with_slug("join-code-snapshot-parse-failed")?;
    Ok(WatchOrganizationJoinCodesResponse::Snapshot(Box::new(
        OrganizationJoinCodesSnapshot {
            sequence: snapshot.sequence,
            values: snapshot.values.into_iter().map(Into::into).collect(),
            ..Default::default()
        },
    )))
}
