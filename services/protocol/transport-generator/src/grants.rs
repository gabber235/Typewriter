use crate::{
    manifest::{Channel, Direction, Role, Side},
    resolved::{ResolvedFlow, ResolvedRoute},
    subject::SubjectTemplate,
};
use std::collections::BTreeSet;

pub struct GrantSpec<'a> {
    pub role: Role,
    pub direction: Direction,
    pub endpoint: &'a SubjectTemplate,
    pub transfer_token: bool,
    pub wildcard_parameters: BTreeSet<crate::subject::Parameter>,
}

impl ResolvedRoute {
    pub fn grants(&self) -> Result<Vec<GrantSpec<'_>>, String> {
        self.grants
            .iter()
            .map(|grant| {
                if let (ResolvedFlow::Event { addresses, .. }, Channel::Event) =
                    (&self.flow, grant.channel)
                {
                    let endpoint = addresses.get(&grant.side).ok_or_else(|| {
                        format!("missing {:?} endpoint in {}", grant.side, self.name)
                    })?;
                    return Ok(GrantSpec {
                        role: grant.role,
                        direction: grant.direction,
                        endpoint: &endpoint.subject,
                        transfer_token: false,
                        wildcard_parameters: if grant.direction == Direction::Subscribe {
                            endpoint.subscription_wildcards.clone()
                        } else {
                            BTreeSet::new()
                        },
                    });
                }
                let (addresses, transfer_token) = match (&self.flow, grant.channel) {
                    (ResolvedFlow::Unary { requests, .. }, Channel::Request)
                    | (ResolvedFlow::Watch { requests, .. }, Channel::Request)
                    | (ResolvedFlow::BoundedWatch { requests, .. }, Channel::Request)
                    | (ResolvedFlow::Scatter { requests, .. }, Channel::Request) => {
                        (requests, false)
                    }
                    (ResolvedFlow::Watch { updates, .. }, Channel::Updates) => {
                        (&updates.addresses, false)
                    }
                    (ResolvedFlow::BoundedWatch { updates, .. }, Channel::Updates) => {
                        (updates, true)
                    }
                    _ => return Err(format!("invalid grant channel in {}", self.name)),
                };
                let endpoint = addresses
                    .get(&grant.side)
                    .ok_or_else(|| format!("missing {:?} endpoint in {}", grant.side, self.name))?;
                endpoint.validate_scope(self.scope, transfer_token)?;
                Ok(GrantSpec {
                    role: grant.role,
                    direction: grant.direction,
                    endpoint,
                    transfer_token,
                    wildcard_parameters: BTreeSet::new(),
                })
            })
            .collect()
    }
}

impl Side {
    pub fn is_runtime_side(self) -> bool {
        matches!(self, Self::Backend | Self::BackendInternal)
    }
}
