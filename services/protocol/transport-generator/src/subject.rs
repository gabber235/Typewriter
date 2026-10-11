use std::collections::BTreeSet;

use serde::{Deserialize, Serialize};

use crate::manifest::ScopeKind;

#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum Parameter {
    Organization,
    Realm,
    Service,
    User,
    TransferId,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
#[serde(rename_all = "snake_case", tag = "kind", content = "value")]
pub enum Token {
    Literal(String),
    Parameter(Parameter),
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(try_from = "String", into = "String")]
pub struct SubjectTemplate(Vec<Token>);

impl TryFrom<String> for SubjectTemplate {
    type Error = String;

    fn try_from(value: String) -> Result<Self, Self::Error> {
        let mut seen = BTreeSet::new();
        let tokens = value
            .split('.')
            .map(|part| {
                let parameter = match part {
                    "{organization}" => Some(Parameter::Organization),
                    "{realm}" => Some(Parameter::Realm),
                    "{service}" => Some(Parameter::Service),
                    "{user}" => Some(Parameter::User),
                    "{transfer_id}" => Some(Parameter::TransferId),
                    _ => None,
                };
                if let Some(parameter) = parameter {
                    if !seen.insert(parameter) {
                        return Err(format!("repeated subject parameter {part}"));
                    }
                    return Ok(Token::Parameter(parameter));
                }
                if part.is_empty()
                    || part
                        .chars()
                        .any(|character| character.is_whitespace() || "*>{}".contains(character))
                {
                    return Err(format!("invalid subject token {part:?}"));
                }
                Ok(Token::Literal(part.to_owned()))
            })
            .collect::<Result<Vec<_>, _>>()?;
        Ok(Self(tokens))
    }
}

impl From<SubjectTemplate> for String {
    fn from(value: SubjectTemplate) -> Self {
        value.to_string()
    }
}

impl std::fmt::Display for SubjectTemplate {
    fn fmt(&self, output: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        for (index, token) in self.0.iter().enumerate() {
            if index > 0 {
                output.write_str(".")?;
            }
            match token {
                Token::Literal(literal) => output.write_str(literal)?,
                Token::Parameter(parameter) => write!(
                    output,
                    "{{{}}}",
                    match parameter {
                        Parameter::Organization => "organization",
                        Parameter::Realm => "realm",
                        Parameter::Service => "service",
                        Parameter::User => "user",
                        Parameter::TransferId => "transfer_id",
                    }
                )?,
            }
        }
        Ok(())
    }
}

impl SubjectTemplate {
    pub fn tokens(&self) -> &[Token] {
        &self.0
    }

    pub fn validate_scope(&self, scope: ScopeKind, transfer: bool) -> Result<(), String> {
        let allowed = scope_parameters(scope);
        for (index, token) in self.0.iter().enumerate() {
            let Token::Parameter(parameter) = token else {
                continue;
            };
            if *parameter == Parameter::TransferId {
                if !transfer || index + 1 != self.0.len() {
                    return Err(
                        "transfer_id is valid only as the final bounded update token".to_owned(),
                    );
                }
            } else if !allowed.contains(parameter) {
                return Err(format!(
                    "subject parameter {parameter:?} is absent from {scope:?}"
                ));
            }
        }
        if transfer && !matches!(self.0.last(), Some(Token::Parameter(Parameter::TransferId))) {
            return Err("bounded updates must end in transfer_id".to_owned());
        }
        Ok(())
    }

    pub fn validate_request_scope(&self, scope: ScopeKind) -> Result<(), String> {
        self.validate_scope(scope, false)?;
        for parameter in scope_parameters(scope) {
            if !self.0.contains(&Token::Parameter(*parameter)) {
                return Err(format!(
                    "request subject is missing required {parameter:?} parameter for {scope:?}"
                ));
            }
        }
        Ok(())
    }
}

fn scope_parameters(scope: ScopeKind) -> &'static [Parameter] {
    match scope {
        ScopeKind::Realm => &[Parameter::Organization, Parameter::Realm],
        ScopeKind::Service => &[Parameter::Service],
        ScopeKind::BoundService => &[Parameter::Service, Parameter::Organization],
        ScopeKind::OrganizationActor => &[Parameter::Organization, Parameter::User],
        ScopeKind::Organization => &[Parameter::Organization],
        ScopeKind::User => &[Parameter::User],
        ScopeKind::Native | ScopeKind::InternalComponent => &[],
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn rejects_all_broker_wildcards() {
        for subject in ["cloud.to.>", "cloud.to.*", "cloud.to.{unknown}"] {
            assert!(SubjectTemplate::try_from(subject.to_owned()).is_err());
        }
    }

    #[test]
    fn admits_only_final_bounded_transfer_parameter() {
        let subject = SubjectTemplate::try_from(
            "service.from.{realm}.organization.{organization}.updates.{transfer_id}".to_owned(),
        )
        .unwrap();
        subject.validate_scope(ScopeKind::Realm, true).unwrap();
        assert!(subject.validate_scope(ScopeKind::Realm, false).is_err());
    }

    #[test]
    fn permits_projection_endpoints_with_a_scope_subset() {
        let subject =
            SubjectTemplate::try_from("service.to.{realm}.editor.authoring.state.query".to_owned())
                .unwrap();
        subject.validate_scope(ScopeKind::Realm, false).unwrap();
    }

    #[test]
    fn rejects_missing_request_capture() {
        let subject = SubjectTemplate::try_from(
            "cloud.to.organization.{organization}.members.watch".to_owned(),
        )
        .unwrap();
        assert!(
            subject
                .validate_request_scope(ScopeKind::OrganizationActor)
                .is_err()
        );
    }

    #[test]
    fn rejects_empty_and_embedded_parameter_tokens() {
        for subject in [
            "cloud..user.{user}",
            "cloud.to.user-{user}.watch",
            "cloud.to.{user}.watch.",
        ] {
            assert!(SubjectTemplate::try_from(subject.to_owned()).is_err());
        }
    }
}
