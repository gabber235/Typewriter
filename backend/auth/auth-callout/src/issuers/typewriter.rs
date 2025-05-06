use nats_jwt_rs::{
    types::{Permission, Permissions},
    user::User,
    Claims,
};

use crate::jwt::LogtoClaims;

pub fn issue(claims: &mut Claims<User>, _jwt: &jose::jwt::Claims<LogtoClaims>) {
    claims.payload_mut().permissions.permissions = Permissions {
        publish: Permission {
            allow: vec![],
            deny: vec![],
        },
        subscribe: Permission {
            allow: vec![],
            deny: vec![],
        },
        resp: None,
    };
    claims.payload_mut().generic_fields.tags = Some(vec!["typewriter".to_string()]);
}
