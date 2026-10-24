//! Hand written transport runtime shared by the generated routes and the components using them.
//!
//! The generated `transport_routes` module declares one type per manifest route, the role grants
//! of each scope and one dispatcher per backend component. Everything route independent lives
//! here: subject tokens and scopes, grant sets, the route contracts, payload framing, and the serving
//! of matched messages.

mod frame;
mod grant;
mod route;
mod serve;
mod subject;
#[cfg(test)]
pub(crate) mod test_support;

#[cfg(test)]
mod dispatch_test;

pub use frame::{
    BUSY, CHUNK_HEADER, CREDIT_HEADER, FAILURE_HEADER, INCOMPLETE, INTERRUPTED, LIMIT_HEADER,
    PAYLOAD_HEADER, PayloadFrame, PayloadPlan, REJECTED, ReplyPacing, SHA256_HEADER, SIZE_HEADER,
    TOO_LARGE, credit, interrupted_frame, plan_reply, unusable_reply_slug,
};
pub(crate) use frame::{FrameSink, send_reply_frames};
pub use grant::GrantSet;
pub use route::{
    EventDelivery, EventRoute, OutboundEventRoute, OutboundRequestRoute, PersistentEventRoute,
    RequestRoute, TransientEventRoute, request_route,
};
pub use serve::{serve_event, serve_request, unmatched};
pub use subject::{
    InternalComponentScope, OrganizationActorScope, OrganizationScope, RealmScope, ServiceScope,
    SubjectToken, UserScope,
};

/// Validated connection discriminator shared by inbox names and persistent consumer identities.
///
/// The panel chooses one per NATS connection: 32 lowercase hexadecimal characters. It separates
/// reconnects and concurrent connections of one actor. It is not an identity credential and does
/// not establish the actor's permissions.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct ConnectionSession(String);

impl ConnectionSession {
    pub fn as_str(&self) -> &str {
        &self.0
    }
}

impl TryFrom<&str> for ConnectionSession {
    type Error = otel_wasi::Error;

    fn try_from(value: &str) -> Result<Self, Self::Error> {
        if value.len() != 32
            || !value
                .bytes()
                .all(|character| character.is_ascii_digit() || (b'a'..=b'f').contains(&character))
        {
            return Err(otel_wasi::Error::new(
                "transport-connection-session-invalid",
                "connection session must be 32 lowercase hexadecimal characters",
            ));
        }
        Ok(Self(value.to_owned()))
    }
}

#[cfg(test)]
mod tests {
    use base64::{Engine as _, engine::general_purpose::URL_SAFE_NO_PAD};

    use super::*;
    use crate::transport_routes::consumer_name;

    #[test]
    fn validates_connection_session_shape() {
        assert!(ConnectionSession::try_from("0123456789abcdef0123456789abcdef").is_ok());
        assert!(ConnectionSession::try_from("0123456789ABCDEF0123456789ABCDEF").is_err());
        assert!(ConnectionSession::try_from("short").is_err());
    }

    #[test]
    fn consumer_name_encodes_the_compact_json_identity() {
        let actor = SubjectToken::try_from("actor").unwrap();
        let organization = SubjectToken::try_from("writers").unwrap();
        let session = ConnectionSession::try_from("0123456789abcdef0123456789abcdef").unwrap();
        let expected = |identity: &[u8]| format!("TW_{}", URL_SAFE_NO_PAD.encode(identity));
        assert_eq!(
            consumer_name(&actor, None, &session, "user_organizations_changed"),
            expected(
                br#"["actor",null,"0123456789abcdef0123456789abcdef","user_organizations_changed"]"#
            )
        );
        assert_eq!(
            consumer_name(&actor, Some(&organization), &session, "organization_members_changed"),
            expected(
                br#"["actor","writers","0123456789abcdef0123456789abcdef","organization_members_changed"]"#
            )
        );
    }
}
