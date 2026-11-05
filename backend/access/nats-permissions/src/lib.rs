//! The NATS user permissions the broker enforces for a permission service grant.
//!
//! `auth-callout` signs these permissions into every user JWT it issues, and the component tests
//! grant their broker users the same permissions, so a test user holds exactly what the callout
//! would grant. A plain library rather than part of the `auth-callout` component, so native
//! builds reuse it without linking the component's exports.

use std::time::Duration;

use nats_jwt_rs::types::{
    Permission as NatsPermission, Permissions as NatsPermissions,
    ResponsePermission as NatsResponsePermission,
};
use wasmcloud_utils::skir::base::access::v1::permission::Permissions;

/// The NATS permissions the broker enforces for a permission reply.
pub fn convert_permissions(permissions: Permissions) -> NatsPermissions {
    let publish = NatsPermission {
        allow: permissions.publish.allow,
        deny: permissions.publish.deny,
    };

    let subscribe = NatsPermission {
        allow: permissions.subscribe.allow,
        deny: permissions.subscribe.deny,
    };

    // A grant without a reply limit allows one reply; without a TTL, NATS's zero means no expiry.
    let resp = permissions.response.map(|r| NatsResponsePermission {
        max_messages: r.max_messages.map_or(1, |m| m as i64),
        ttl: r.ttl.as_ref().map_or(Duration::ZERO, |d| {
            Duration::from_millis(d.milliseconds as u64)
        }),
    });

    NatsPermissions {
        publish,
        subscribe,
        resp,
    }
}
