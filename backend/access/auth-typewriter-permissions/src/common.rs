use serde::{Deserialize, Serialize};
use wasmcloud_utils::skir::base::access::v1::permission::{Permission, Permissions};

#[derive(Debug, Serialize, Deserialize, Clone)]
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
pub struct User {
    pub name: String,
    pub email: Option<String>,
    pub avatar: Option<String>,
    pub avatar_url: Option<String>,
}

/// Build skir Permissions directly from allow vectors.
pub fn build_permissions(
    allow_publish: Vec<String>,
    allow_subscribe: Vec<String>,
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
        response: None,
        _unrecognized: None,
    }
}