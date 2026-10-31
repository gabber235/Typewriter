//! Shared support for the integration tests: record ids, the responses the Skir validation and
//! transaction macros build inside a handler, transaction outcome shapes, and the backend's component manifests.

#![allow(
    dead_code,
    reason = "every integration test crate compiles this module and uses a part of it"
)]

use std::path::{Path, PathBuf};

use serde::Deserialize;
use wasmcloud_utils::skir::base::{
    kernel::v1::record_id::{RecordId, RecordIdKey},
    organization::v1::member::*,
};
use wasmcloud_utils::skir_utils::RecordIdTableInput;
use wasmcloud_utils::{skir_transaction_outcome, validate_record_ids};

/// A Skir record id of `table` with a string `key`.
pub fn record_id(table: &str, key: &str) -> RecordId {
    RecordId {
        table: table.to_owned(),
        key: RecordIdKey::String(key.to_owned()),
        _unrecognized: None,
    }
}

/// The member roles response a handler returns after validating that `ids` are users.
pub fn validate_users<T: RecordIdTableInput + ?Sized>(
    ids: &T,
) -> Result<UpdateOrganizationMemberRolesResponse, otel_wasi::Error> {
    validate_record_ids!(UpdateOrganizationMemberRolesResponse, *ids, "user");
    Ok(UpdateOrganizationMemberRolesResponse::Success(
        Default::default(),
    ))
}

/// The outcomes a member roles transaction reports, in the shape generated responses map.
#[allow(
    clippy::large_enum_variant,
    reason = "The test mirrors transaction outcome shapes used by generated response types"
)]
pub enum MemberUpdateOutcome {
    Updated { member: OrganizationMember },
    UserNotFoundError,
    RolesNotFoundError { role_ids: Vec<RecordId> },
    FounderRoleRequiredError,
}

/// The member roles response a handler returns for a transaction `outcome` about `user_id`.
pub fn member_update_response(
    outcome: MemberUpdateOutcome,
    user_id: RecordId,
) -> Result<UpdateOrganizationMemberRolesResponse, otel_wasi::Error> {
    let member = skir_transaction_outcome!(
        UpdateOrganizationMemberRolesResponse,
        outcome,
        success MemberUpdateOutcome::Updated { member } => member,
        errors {
            MemberUpdateOutcome::UserNotFoundError => {
                user_ids: vec![user_id]
            },
            MemberUpdateOutcome::RolesNotFoundError { role_ids } => {
                role_ids
            },
            MemberUpdateOutcome::FounderRoleRequiredError => {},
        }
    );

    Ok(UpdateOrganizationMemberRolesResponse::Success(Box::new(
        UpdateOrganizationMemberRolesResponse_Success {
            members: vec![member],
            ..Default::default()
        },
    )))
}

/// A transaction outcome without fields.
#[derive(Deserialize)]
pub struct EmptyOutcome;

/// Every `Cargo.toml` of the application components under the backend areas `areas`.
pub fn component_manifests(areas: &[&str]) -> Vec<PathBuf> {
    let backend = Path::new(env!("CARGO_MANIFEST_DIR"))
        .parent()
        .expect("wasmcloud utils is inside the backend directory");
    let mut manifests = Vec::new();
    for area in areas {
        collect_manifests(&backend.join(area), &mut manifests);
    }
    manifests
}

fn collect_manifests(directory: &Path, manifests: &mut Vec<PathBuf>) {
    for entry in std::fs::read_dir(directory).expect("application directory must be readable") {
        let path = entry.expect("directory entry must be readable").path();
        if path.is_dir() {
            collect_manifests(&path, manifests);
        } else if path.file_name().is_some_and(|name| name == "Cargo.toml") {
            manifests.push(path);
        }
    }
}
