use std::fmt::Display;

use prost::Message;
use wasmcloud_utils::wasmcloud::messaging::send;

use crate::typewriter::api::v1::{
    ListJoinCodesRequest, ListJoinRequestsRequest, ListMembersRequest, ListOrganizationsRequest,
};

pub fn refresh_user_organization_list(user_id: impl Display) -> Result<(), String> {
    send(
        format!("typewriter.in.user.{}.organization.list", user_id),
        format!("typewriter.out.user.{}.organization.list", user_id),
        ListOrganizationsRequest {}.encode_to_vec(),
    )
}

pub fn refresh_user_organization_join_requests_list(user_id: impl Display) -> Result<(), String> {
    send(
        format!(
            "typewriter.in.user.{}.organization.join_requests.list",
            user_id
        ),
        format!(
            "typewriter.out.user.{}.organization.join_requests.list",
            user_id
        ),
        ListOrganizationsRequest {}.encode_to_vec(),
    )
}

pub fn refresh_organization_members_list(
    org_id: impl Display,
    user_id: Option<impl Display>,
) -> Result<(), String> {
    let user_id = user_id
        .map(|u| u.to_string())
        .unwrap_or_else(|| "x".to_string());
    send(
        format!(
            "typewriter.in.user.{}.organization.{}.members.list",
            user_id, org_id,
        ),
        format!("typewriter.out.organization.{}.members.list", org_id),
        ListMembersRequest {}.encode_to_vec(),
    )
}

pub fn refresh_members_join_requests_list(
    org_id: impl Display,
    user_id: Option<impl Display>,
) -> Result<(), String> {
    let user_id = user_id
        .map(|u| u.to_string())
        .unwrap_or_else(|| "x".to_string());
    send(
        format!(
            "typewriter.in.user.{}.organization.{}.members.join_requests.list",
            user_id, org_id,
        ),
        format!(
            "typewriter.out.organization.{}.members.join_requests.list",
            org_id
        ),
        ListJoinRequestsRequest {}.encode_to_vec(),
    )
}

pub fn refresh_organization_members_join_codes_list(
    org_id: impl Display,
    user_id: Option<impl Display>,
) -> Result<(), String> {
    let user_id = user_id
        .map(|u| u.to_string())
        .unwrap_or_else(|| "x".to_string());
    send(
        format!(
            "typewriter.in.user.{}.organization.{}.members.join_codes.list",
            user_id, org_id,
        ),
        format!(
            "typewriter.out.organization.{}.members.join_codes.list",
            org_id
        ),
        ListJoinCodesRequest {}.encode_to_vec(),
    )
}
