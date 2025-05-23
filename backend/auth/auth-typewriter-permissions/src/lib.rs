wit_bindgen::generate!({
    with: {
        "wasmcloud:messaging/consumer@0.2.0": wasmcloud_utils::wasmcloud::messaging::consumer,
        "wasmcloud:messaging/handler@0.2.0": wasmcloud_utils::wasmcloud::messaging::handler,
    },
    generate_all,
});

use std::time::Duration;

use anyhow::Result;
use nats_jwt_rs::types::{Permission, Permissions, ResponsePermission};
use serde::{Deserialize, Serialize};
use wasmcloud_component::debug;
use wasmcloud_utils::wasmcloud::messaging::{handler::Guest, reply, types};

struct TypewriterPermissions;
wasmcloud_utils::export!(TypewriterPermissions);

#[derive(Debug, Serialize, Deserialize, Clone)]
#[serde(tag = "kind")]
pub enum LogtoClaims {
    #[serde(rename = "user")]
    User {
        name: String,
        email: Option<String>,
        phone: Option<String>,
        avatar: Option<String>,
    },
}
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct PermissionRequest {
    organization_id: Option<String>,
    jwt: jose::jwt::Claims<LogtoClaims>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct PermissionResponse {
    permissions: Permissions,
    tags: Vec<String>,
}

impl Guest for TypewriterPermissions {
    fn handle_message(msg: types::BrokerMessage) -> Result<(), String> {
        let request: PermissionRequest =
            serde_cbor::from_slice(&msg.body).map_err(|e| e.to_string())?;

        let claims: jose::jwt::Claims<LogtoClaims> = request.jwt;
        let organization_id = request.organization_id;

        let (permissions, tags) = match claims.additional {
            LogtoClaims::User { .. } => {
                handle_user(claims, organization_id).map_err(|e| e.to_string())?
            }
        };

        let repsponse = PermissionResponse { permissions, tags };
        let response = serde_cbor::to_vec(&repsponse).map_err(|e| e.to_string())?;

        reply(msg, response)?;
        Ok(())
    }
}

#[derive(Debug, Serialize, Deserialize, Clone)]
struct User {
    name: String,
    email: Option<String>,
    phone: Option<String>,
    avatar: Option<String>,
}

fn handle_user(
    claims: jose::jwt::Claims<LogtoClaims>,
    organization_id: Option<String>,
) -> Result<(Permissions, Vec<String>)> {
    let user_id = claims
        .subject
        .ok_or(anyhow::anyhow!("No subject in claims"))?;

    let LogtoClaims::User {
        name,
        email,
        phone,
        avatar,
    } = claims.additional;

    debug!("handling user request for user {}", name);

    let results = surrealdb_component::query(
        "
        UPSERT type::thing('user',$uid) SET
            name = $name,
            email = $email,
            phone = $phone,
            avatar = $avatar,
            last_login = time::now();
        ",
    )
    .bind("uid", &user_id)
    .bind("name", &name)
    .bind("email", &email)
    .bind("phone", &phone)
    .bind("avatar", &avatar)
    .execute()
    .map_err(|e| anyhow::anyhow!(e))?;

    debug!("finished handling user request for user {}", name);

    let r = results.take::<Option<User>>(0);
    if let Err(e) = r {
        debug!("error inserting user: {}", e);
        return Err(anyhow::anyhow!(e));
    }
    // .map_err(|e| anyhow::anyhow!(e))?;

    debug!("made sure no errors occurred");

    let mut allow_publish = vec![];
    let mut allow_subscribe = vec![];

    // ########### PERMISSIONS ###########
    {
        allow_subscribe.push(format!("_INBOX.{}.>", &user_id));

        allow_publish.push(format!("user.{}.organization.list", user_id));
    }
    // ######### END PERMISSIONS #########

    let permissions = Permissions {
        publish: Permission {
            allow: allow_publish,
            deny: vec![],
        },
        subscribe: Permission {
            allow: allow_subscribe,
            deny: vec![],
        },
        resp: Some(ResponsePermission {
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
