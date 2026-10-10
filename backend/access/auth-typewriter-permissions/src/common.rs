//! Shared claim shapes and policy construction for the permission routes.
//!
//! These shapes are intentionally limited to claims needed for authorization and presentation.
//! They are not proof of identity. The auth callout establishes that the claims came from a
//! trusted issuer before this crate uses them, while database and service state establish local
//! authorization facts.

use serde::{Deserialize, Serialize};
use wasmcloud_utils::skir::base::access::v1::permission::{
    Permission, Permissions, ResponsePermission,
};

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

/// Profile fields projected from claims that were admitted by the authentication boundary.
pub struct TrustedUserProfile {
    pub name: String,
    pub email: Option<String>,
    pub avatar_url: Option<String>,
}

impl AuthentikClaims {
    /// Project durable profile values while preserving the established provider fallback order.
    pub fn user_profile(&self) -> TrustedUserProfile {
        TrustedUserProfile {
            name: self
                .name
                .clone()
                .or_else(|| self.discord.as_ref().map(|value| value.username.clone()))
                .unwrap_or_else(|| "Unknown".to_owned()),
            email: self
                .email
                .clone()
                .or_else(|| self.discord.as_ref().and_then(|value| value.email.clone())),
            avatar_url: self.avatar_url.clone().or_else(|| {
                self.discord
                    .as_ref()
                    .and_then(|value| value.avatar_url.clone())
            }),
        }
    }
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
pub fn build_permissions(
    allow_publish: Vec<String>,
    allow_subscribe: Vec<String>,
    response: Option<ResponsePermission>,
) -> Permissions {
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
        response,
        _unrecognized: None,
    }
}
