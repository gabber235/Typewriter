wit_bindgen::generate!({
    with: {
        "wasmcloud:messaging/consumer@0.2.0": wasmcloud_utils::wasmcloud::messaging::consumer,
        "wasmcloud:messaging/handler@0.2.0": wasmcloud_utils::wasmcloud::messaging::handler,
    },
    generate_all,
});

use std::time::Duration;

use anyhow::Result;
use nats_jwt_rs::types::{
    Permission as NatsPermission, Permissions as NatsPermissions,
    ResponsePermission as NatsResponsePermission,
};
use prost::Message;
use serde::{Deserialize, Serialize};
use wasmcloud_component::debug;
use wasmcloud_utils::wasmcloud::messaging::{handler::Guest, reply, types};

mod typewriter {
    pub mod models {
        pub mod v1 {
            include!("generated/typewriter.models.v1.rs");
        }
    }
    pub mod api {
        pub mod v1 {
            include!("generated/typewriter.api.v1.rs");
        }
    }
}

struct TypewriterPermissions;
wasmcloud_utils::export!(TypewriterPermissions);

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

impl Guest for TypewriterPermissions {
    fn handle_message(msg: types::BrokerMessage) -> Result<(), String> {
        let request = typewriter::api::v1::PermissionRequest::decode(&msg.body[..])
            .map_err(|e| format!("failed to decode request: {}", e))?;

        let claims: jose::jwt::Claims<AuthentikClaims> =
            serde_json::from_slice(&request.jwt_claims).map_err(|e| e.to_string())?;

        let organization_id = request.organization_id;

        let (nats_permissions, tags) =
            handle_user(claims, organization_id).map_err(|e| e.to_string())?;

        let proto_permissions = (&nats_permissions).into();

        let response = typewriter::api::v1::PermissionResponse {
            permissions: Some(proto_permissions),
            tags,
        };
        let response_bytes = response.encode_to_vec();

        reply(msg, response_bytes)?;
        Ok(())
    }
}

#[derive(Debug, Serialize, Deserialize, Clone)]
struct User {
    name: String,
    email: Option<String>,
    avatar: Option<String>,
    avatar_url: Option<String>,
}

fn handle_user(
    claims: jose::jwt::Claims<AuthentikClaims>,
    organization_id: Option<String>,
) -> Result<(NatsPermissions, Vec<String>)> {
    let user_id = claims
        .subject
        .ok_or(anyhow::anyhow!("No subject in claims"))?;

    let additional = claims.additional;

    let name = additional
        .name
        .or_else(|| additional.discord.as_ref().map(|d| d.username.clone()))
        .unwrap_or_else(|| "Unknown".to_string());

    let email = additional
        .email
        .or_else(|| additional.discord.as_ref().and_then(|d| d.email.clone()));

    let avatar = additional.avatar;

    let avatar_url = additional.avatar_url.or_else(|| {
        additional
            .discord
            .as_ref()
            .and_then(|d| d.avatar_url.clone())
    });

    debug!("handling user request for user {}", name);

    let results = surrealdb_component::query(
        "
        UPSERT type::thing('user',$uid) SET
            name = $name,
            email = $email,
            avatar = $avatar,
            avatar_url = $avatar_url,
            last_login = time::now();
        ",
    )
    .bind("uid", &user_id)
    .bind("name", &name)
    .bind("email", &email)
    .bind("avatar", &avatar)
    .bind("avatar_url", &avatar_url)
    .execute()
    .map_err(|e| anyhow::anyhow!(e))?;

    debug!("finished handling user request for user {}", name);

    let r = results.take::<Option<User>>(0);
    if let Err(e) = r {
        debug!("error inserting user: {}", e);
        return Err(anyhow::anyhow!(e));
    }

    debug!("made sure no errors occurred");

    let mut allow_publish = vec![];
    let mut allow_subscribe = vec![];

    // ########### PERMISSIONS ###########
    {
        allow_subscribe.push(format!("_INBOX.{}.>", &user_id));

        allow_publish.push(format!("user.{}.organization.list", user_id));
    }
    // ######### END PERMISSIONS #########

    let permissions = NatsPermissions {
        publish: NatsPermission {
            allow: allow_publish,
            deny: vec![],
        },
        subscribe: NatsPermission {
            allow: allow_subscribe,
            deny: vec![],
        },
        resp: Some(NatsResponsePermission {
            max_messages: 1,
            ttl: Duration::from_secs(60),
        }),
    };
    let mut tags = vec![];

    if let Some(organization_id) = organization_id {
        tags.push(format!("org:{}", organization_id));
    }

    debug!("finished handling permissions request for user {}", name);

    Ok((permissions, tags))
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
                max_messages: r.max_messages as i32,
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
