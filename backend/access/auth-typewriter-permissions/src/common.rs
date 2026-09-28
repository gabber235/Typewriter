//! Shared claim shapes and policy construction for the permission routes.
//!
//! These shapes are intentionally limited to claims needed for authorization and presentation.
//! They are not proof of identity. The auth callout establishes that the claims came from a
//! trusted issuer before this crate uses them, while database and service state establish local
//! authorization facts.

use serde::{Deserialize, Serialize};
use wasmcloud_utils::skir::base::access::v1::permission::{Permission, Permissions};

/// Realm request routes exposed by the current service contract.
pub const REALM_REQUEST_SUFFIXES: &[&str] = &[
    "compiled.content.watch",
    "editor.capability.command.invoke",
    "editor.capability.computation.invoke",
    "editor.catalog.fetch",
    "editor.catalog.invalidate",
    "editor.presentation.search",
    "editor.presentation.search.cancel",
    "editor.typed.value.initialize",
    "editor.authoring.batch.apply",
    "editor.authoring.batch.preview",
    "editor.authoring.compiled.status.query",
    "editor.authoring.compiled.watch",
    "editor.authoring.graph.query",
    "editor.authoring.graph.search",
    "shared.blob.begin",
    "shared.blob.complete",
    "shared.blob.metadata",
    "shared.blob.read",
    "shared.blob.write",
    "shared.catalog.fetch",
    "shared.publish",
];

/// Realm event routes published by the current service contract.
pub const REALM_EVENT_SUFFIXES: &[&str] = &[
    "compiled.content.watch",
    "editor.catalog.invalidate",
    "editor.presentation.search",
    "editor.authoring.changed",
    "editor.authoring.compiled.activated",
    "editor.authoring.compiled.changed",
];

/// Realm requests issued by services attached to a Realm.
pub const SHARED_REQUEST_SUFFIXES: &[&str] = &[
    "shared.blob.begin",
    "shared.blob.complete",
    "shared.blob.metadata",
    "shared.blob.read",
    "shared.blob.write",
    "shared.catalog.fetch",
    "shared.publish",
];

#[derive(Debug, Serialize, Deserialize, Clone)]
/// Optional identity provider data used to enrich a durable Typewriter user record.
pub struct DiscordData {
    pub id: String,
    pub username: String,
    pub discriminator: Option<String>,
    pub email: Option<String>,
    pub avatar: Option<String>,
    pub avatar_url: Option<String>,
    #[serde(default)]
    pub roles: Vec<String>,
}

#[derive(Debug, Serialize, Deserialize, Clone, Default)]
/// Claims consumed when deriving policy for a panel user.
///
/// The claims identify the external principal and provide profile data. They do not authorize
/// organization access without the membership check performed by the user policy route.
pub struct AuthentikClaims {
    pub name: Option<String>,
    pub preferred_username: Option<String>,
    pub email: Option<String>,
    #[serde(default)]
    pub email_verified: bool,
    #[serde(default)]
    pub groups: Vec<String>,
    pub discord: Option<DiscordData>,
    pub avatar: Option<String>,
    pub avatar_url: Option<String>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
/// Durable user fields written when a panel identity authenticates.
pub struct User {
    pub name: String,
    pub email: Option<String>,
    pub avatar: Option<String>,
    pub avatar_url: Option<String>,
}

/// Build policy output with explicit allow lists and no implicit deny rules.
///
/// NATS receives this value only after the route has derived all subject scopes. The auth callout
/// converts it to NATS permissions, so this helper must not be treated as an identity check.
pub fn build_permissions(allow_publish: Vec<String>, allow_subscribe: Vec<String>) -> Permissions {
    Permissions {
        publish: Permission {
            allow: allow_publish,
            deny: vec![],
            _unrecognized: None,
        },
        subscribe: Permission {
            allow: allow_subscribe,
            deny: vec![],
            _unrecognized: None,
        },
        response: None,
        _unrecognized: None,
    }
}
