wit_bindgen::generate!({ generate_all });

use std::time::Duration;

use anyhow::Result;
use exports::wasmcloud::messaging::handler::Guest;
use nats_jwt_rs::types::{Permission, Permissions, ResponsePermission};
use serde::{Deserialize, Serialize};
use wasmcloud::messaging::*;

struct TypewriterPermissions;

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
    .bind("uid", user_id.clone())
    .bind("name", name)
    .bind("email", email)
    .bind("phone", phone)
    .bind("avatar", avatar)
    .execute()
    .map_err(|e| anyhow::anyhow!(e))?;

    results
        .take::<Option<()>>(0)
        .map_err(|e| anyhow::anyhow!(e))?;

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

    Ok((permissions, tags))
}

fn reply(reply_to: types::BrokerMessage, data: impl Into<Vec<u8>>) -> Result<(), String> {
    if let Some(reply_to) = reply_to.reply_to {
        consumer::publish(&types::BrokerMessage {
            subject: reply_to,
            reply_to: None,
            body: data.into(),
        })
    } else {
        Err("No reply_to field in message, ignoring message".to_string())
    }
}

export!(TypewriterPermissions);
