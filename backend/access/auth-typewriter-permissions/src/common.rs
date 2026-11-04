//! Shared claim shapes and policy construction for the permission routes.
//!
//! These shapes are intentionally limited to claims needed for authorization and presentation.
//! They are not proof of identity. The auth callout establishes that the claims came from a
//! trusted issuer before this crate uses them, while database and service state establish local
//! authorization facts.

use serde::{Deserialize, Serialize};
use wasmcloud_utils::skir::base::{
    access::v1::permission::{Permission, Permissions, ResponsePermission},
    kernel::v1::duration::Duration,
};
use wasmcloud_utils::transport_routes::REPLY_TTL_MS;

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
    ///
    /// Authentik sends an account's unset profile fields as empty strings, and an empty value
    /// means the provider has nothing, so the next source is asked and the record holds none.
    pub fn user_profile(&self) -> TrustedUserProfile {
        let discord = self.discord.as_ref();
        TrustedUserProfile {
            name: provided(&self.name)
                .or_else(|| discord.and_then(|value| provided_str(&value.username)))
                .unwrap_or_else(|| "Unknown".to_owned()),
            email: provided(&self.email)
                .or_else(|| discord.and_then(|value| provided(&value.email))),
            avatar_url: provided(&self.avatar_url)
                .or_else(|| discord.and_then(|value| provided(&value.avatar_url))),
        }
    }
}

fn provided(value: &Option<String>) -> Option<String> {
    value.as_deref().and_then(provided_str)
}

fn provided_str(value: &str) -> Option<String> {
    (!value.is_empty()).then(|| value.to_owned())
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

/// Lets a connection answer each request it receives within [`REPLY_TTL_MS`] with up to
/// `max_messages` messages.
///
/// A service sends every frame of its largest reply to the requester's inbox and grants credits
/// to framed requests and replies ([`SERVICE_RESPONSE_LIMIT`]); callers map an absent generated
/// limit to no response permission. Panel connections never get one: see
/// [`crate::users::panel_permissions`].
///
/// [`SERVICE_RESPONSE_LIMIT`]: wasmcloud_utils::transport_routes::SERVICE_RESPONSE_LIMIT
pub(crate) fn response_permission(max_messages: u32) -> ResponsePermission {
    ResponsePermission {
        max_messages: Some(max_messages as i32),
        ttl: Some(Duration {
            milliseconds: REPLY_TTL_MS,
            _unrecognized: None,
        }),
        _unrecognized: None,
    }
}
