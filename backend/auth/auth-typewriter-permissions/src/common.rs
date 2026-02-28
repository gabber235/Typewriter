use nats_jwt_rs::types::{Permission as NatsPermission, Permissions as NatsPermissions};
use serde::{Deserialize, Serialize};

use crate::typewriter;

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

/// Build a permission response from NATS permissions and tags
pub fn build_permission_response(
    nats_permissions: NatsPermissions,
    tags: Vec<String>,
) -> typewriter::api::v1::PermissionResponse {
    let proto_permissions = (&nats_permissions).into();
    typewriter::api::v1::PermissionResponse {
        permissions: Some(proto_permissions),
        tags,
    }
}

/// Build default NATS permissions structure with response limits
pub fn build_nats_permissions(
    allow_publish: Vec<String>,
    allow_subscribe: Vec<String>,
) -> NatsPermissions {
    NatsPermissions {
        publish: NatsPermission {
            allow: allow_publish,
            deny: vec![],
        },
        subscribe: NatsPermission {
            allow: allow_subscribe,
            deny: vec![],
        },
        resp: None,
    }
}

impl From<&NatsPermissions> for typewriter::models::v1::Permissions {
    fn from(nats_permissions: &NatsPermissions) -> Self {
        use prost_types::Duration;

        let publish = Some(typewriter::models::v1::Permission {
            allow: nats_permissions.publish.allow.clone(),
            deny: nats_permissions.publish.deny.clone(),
        });

        let subscribe = Some(typewriter::models::v1::Permission {
            allow: nats_permissions.subscribe.allow.clone(),
            deny: nats_permissions.subscribe.deny.clone(),
        });

        let resp = nats_permissions.resp.as_ref().map(|r| {
            let total_seconds = r.ttl.as_secs();
            let nanos = r.ttl.subsec_nanos();

            typewriter::models::v1::ResponsePermission {
                max_messages: Some(r.max_messages as i32),
                ttl: Some(Duration {
                    seconds: total_seconds as i64,
                    nanos: nanos as i32,
                }),
            }
        });

        typewriter::models::v1::Permissions {
            publish,
            subscribe,
            resp,
        }
    }
}
