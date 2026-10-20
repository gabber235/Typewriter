//! Validated subject tokens and the route scopes rebuilt from them.
//!
//! A scope holds the identities a route subject captures. Component dispatchers rebuild it from
//! the tokens of a received subject, and outbound routes render their subject from it.

use otel_wasi::Error;

/// One identity token of a NATS subject, such as a user, organization, realm or service id.
///
/// A token is never empty and never contains whitespace, the `.` separator, the `*` and `>`
/// wildcards or template braces, so placing it in a subject cannot widen or split that subject.
#[derive(Clone, Debug, PartialEq, Eq, PartialOrd, Ord)]
pub struct SubjectToken(String);

impl SubjectToken {
    pub fn as_str(&self) -> &str {
        &self.0
    }
}

impl TryFrom<&str> for SubjectToken {
    type Error = Error;

    /// Fails with `transport-invalid-token` when the value cannot be one subject token.
    fn try_from(value: &str) -> Result<Self, Self::Error> {
        if value.is_empty()
            || value
                .chars()
                .any(|character| character.is_whitespace() || ".*>{}".contains(character))
        {
            return Err(Error::new(
                "transport-invalid-token",
                "Invalid subject identity",
            ));
        }
        Ok(Self(value.to_owned()))
    }
}

impl std::fmt::Display for SubjectToken {
    fn fmt(&self, output: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        output.write_str(self.as_str())
    }
}

/// The organization and realm of a realm route.
#[derive(Clone, Debug)]
pub struct RealmScope {
    pub organization: SubjectToken,
    pub realm: SubjectToken,
}

impl RealmScope {
    /// Rebuilds the scope from the captured subject tokens.
    pub fn from_tokens(organization: &str, realm: &str) -> Result<Self, Error> {
        Ok(Self {
            organization: SubjectToken::try_from(organization)?,
            realm: SubjectToken::try_from(realm)?,
        })
    }
}

/// The registered service of a service route.
#[derive(Clone, Debug)]
pub struct ServiceScope {
    pub service: SubjectToken,
}

impl ServiceScope {
    /// Rebuilds the scope from the captured subject token.
    pub fn from_tokens(service: &str) -> Result<Self, Error> {
        Ok(Self {
            service: SubjectToken::try_from(service)?,
        })
    }
}

impl TryFrom<&str> for ServiceScope {
    type Error = Error;

    fn try_from(service: &str) -> Result<Self, Self::Error> {
        Self::from_tokens(service)
    }
}

/// The acting user within one organization, for routes a member calls about that organization.
#[derive(Clone, Debug)]
pub struct OrganizationActorScope {
    pub user: SubjectToken,
    pub organization: SubjectToken,
}

impl OrganizationActorScope {
    /// Rebuilds the scope from the captured subject tokens.
    pub fn from_tokens(user: &str, organization: &str) -> Result<Self, Error> {
        Ok(Self {
            user: SubjectToken::try_from(user)?,
            organization: SubjectToken::try_from(organization)?,
        })
    }
}

/// One organization, for updates every member of that organization receives.
#[derive(Clone, Debug)]
pub struct OrganizationScope {
    pub organization: SubjectToken,
}

impl OrganizationScope {
    /// Rebuilds the scope from the captured subject token.
    pub fn from_tokens(organization: &str) -> Result<Self, Error> {
        Ok(Self {
            organization: SubjectToken::try_from(organization)?,
        })
    }
}

impl TryFrom<&str> for OrganizationScope {
    type Error = Error;

    fn try_from(organization: &str) -> Result<Self, Self::Error> {
        Self::from_tokens(organization)
    }
}

/// One authenticated user, for routes about that user's own state.
#[derive(Clone, Debug)]
pub struct UserScope {
    pub user: SubjectToken,
}

impl UserScope {
    /// Rebuilds the scope from the captured subject token.
    pub fn from_tokens(user: &str) -> Result<Self, Error> {
        Ok(Self {
            user: SubjectToken::try_from(user)?,
        })
    }
}

impl TryFrom<&str> for UserScope {
    type Error = Error;

    fn try_from(user: &str) -> Result<Self, Self::Error> {
        Self::from_tokens(user)
    }
}

/// The scope of a route between two backend components, whose subject captures no identity.
#[derive(Clone, Copy, Debug)]
pub struct InternalComponentScope;

impl InternalComponentScope {
    /// Builds the scope; it has no tokens to validate.
    pub fn from_tokens() -> Result<Self, Error> {
        Ok(Self)
    }
}

#[cfg(test)]
mod tests {
    use otel_wasi::WasiError as _;

    use super::*;

    #[test]
    fn subject_tokens_reject_separators_wildcards_and_whitespace() {
        assert_eq!(
            SubjectToken::try_from("writers").unwrap().as_str(),
            "writers"
        );
        for invalid in ["", "a.b", "*", ">", "a b", "{user}", "tab\t"] {
            let error = SubjectToken::try_from(invalid).unwrap_err();
            assert_eq!(error.slug(), "transport-invalid-token", "{invalid:?}");
        }
    }

    #[test]
    fn scopes_rebuild_from_tokens_in_field_order() {
        let actor = OrganizationActorScope::from_tokens("ada", "writers").unwrap();
        assert_eq!(
            (actor.user.as_str(), actor.organization.as_str()),
            ("ada", "writers")
        );
        let realm = RealmScope::from_tokens("writers", "quests").unwrap();
        assert_eq!(
            (realm.organization.as_str(), realm.realm.as_str()),
            ("writers", "quests")
        );
        assert_eq!(ServiceScope::try_from("s1").unwrap().service.as_str(), "s1");
        assert!(UserScope::from_tokens("a.b").is_err());
        assert!(OrganizationActorScope::from_tokens("ada", "*").is_err());
        assert!(InternalComponentScope::from_tokens().is_ok());
    }
}
