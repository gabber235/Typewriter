use base64::{Engine as _, engine::general_purpose::URL_SAFE_NO_PAD};
use wasmcloud_utils::transport_routes::{GrantSet, MembershipProjection, SubjectToken};

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
                "permissions-connection-session-invalid",
                "connection session must be 32 lowercase hexadecimal characters",
            ));
        }
        Ok(Self(value.to_owned()))
    }
}

pub struct MembershipConsumerScope<'a> {
    actor: &'a SubjectToken,
    organization: Option<&'a SubjectToken>,
    session: &'a ConnectionSession,
}

impl<'a> MembershipConsumerScope<'a> {
    pub fn user(actor: &'a SubjectToken, session: &'a ConnectionSession) -> Self {
        Self {
            actor,
            organization: None,
            session,
        }
    }

    pub fn organization_member(
        actor: &'a SubjectToken,
        organization: &'a SubjectToken,
        session: &'a ConnectionSession,
    ) -> Self {
        Self {
            actor,
            organization: Some(organization),
            session,
        }
    }

    pub fn consumer_name(
        &self,
        projection: MembershipProjection,
    ) -> Result<String, otel_wasi::Error> {
        let bytes = serde_json::to_vec(&(
            self.actor.as_str(),
            self.organization.map(SubjectToken::as_str),
            self.session.as_str(),
            projection.id(),
        ))
        .map_err(|_| {
            otel_wasi::Error::new(
                "permissions-consumer-name-encoding-failed",
                "consumer identity encoding failed",
            )
        })?;
        Ok(format!("TW_{}", URL_SAFE_NO_PAD.encode(bytes)))
    }

    pub fn grant(
        &self,
        projection: MembershipProjection,
        grants: &mut GrantSet,
    ) -> Result<(), otel_wasi::Error> {
        let filter = projection.event_subject(self.actor, self.organization)?;
        let name = self.consumer_name(projection)?;
        let stream = projection.stream();
        grants.publish.extend([
            format!("$JS.API.STREAM.INFO.{stream}"),
            format!("$JS.API.CONSUMER.CREATE.{stream}.{name}.{filter}"),
            format!("$JS.API.CONSUMER.INFO.{stream}.{name}"),
            format!("$JS.API.CONSUMER.MSG.NEXT.{stream}.{name}"),
            format!("$JS.API.CONSUMER.DELETE.{stream}.{name}"),
        ]);
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn validates_connection_session_shape() {
        assert!(ConnectionSession::try_from("0123456789abcdef0123456789abcdef").is_ok());
        assert!(ConnectionSession::try_from("0123456789ABCDEF0123456789ABCDEF").is_err());
        assert!(ConnectionSession::try_from("short").is_err());
    }

    #[test]
    fn consumer_name_matches_compact_json_encoding() {
        let actor = SubjectToken::try_from("actor").unwrap();
        let session = ConnectionSession::try_from("0123456789abcdef0123456789abcdef").unwrap();
        let scope = MembershipConsumerScope::user(&actor, &session);
        let expected = URL_SAFE_NO_PAD.encode(
            br#"["actor",null,"0123456789abcdef0123456789abcdef","user_organizations_changed"]"#,
        );
        assert_eq!(
            scope
                .consumer_name(MembershipProjection::UserOrganizationsChanged)
                .unwrap(),
            format!("TW_{expected}")
        );
    }
}
