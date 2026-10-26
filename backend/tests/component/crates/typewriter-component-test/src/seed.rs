//! State written straight into a fixture's database.
//!
//! A case creates the state its component owns through the component's own requests. A [`Seed`]
//! holds the rest: records another component or the identity provider creates, and states no
//! request can produce, such as an expired join code. Each piece is one method, and pieces
//! combine freely:
//!
//! ```rust,ignore
//! Seed::new()
//!     .organization(acme(), ada())
//!     .join_code(acme(), JoinCode::new("invite").expired())
//!     .apply(&context.database()?)
//!     .await?;
//! ```

use std::{borrow::Borrow, time::Duration};

use anyhow::Result;
use surrealdb::types::{RecordId, SurrealValue, Value};

use crate::{DatabaseHandle, Organization, StackUser};

/// Database state for one case, applied in one query.
#[derive(Default)]
#[must_use = "a seed does nothing until it is applied"]
pub struct Seed {
    statements: Vec<String>,
    bindings: Vec<(String, Value)>,
}

impl Seed {
    pub fn new() -> Self {
        Self::default()
    }

    /// A person the identity provider knows; signing in creates them in production.
    pub fn user(mut self, user: &StackUser) -> Self {
        let id = self.bind(RecordId::from(user.id()));
        let name = self.bind(user.username.clone());
        self.statements
            .push(format!("UPSERT {id} SET name = {name};"));
        self
    }

    /// An organization founded by `founder`. The database gives it its built in roles and makes
    /// the founder a member. Its name is the key with every character a name may not hold
    /// replaced by `_`, so a key with punctuation still gets a valid name.
    pub fn organization(self, organization: &Organization, founder: &StackUser) -> Self {
        let mut seed = self.user(founder);
        let id = seed.bind(RecordId::from(organization.id()));
        let name = seed.bind(
            organization
                .key
                .chars()
                .map(|character| match character {
                    'a'..='z' | '0'..='9' | '_' => character,
                    _ => '_',
                })
                .collect::<String>(),
        );
        let founder = seed.bind(RecordId::from(founder.id()));
        seed.statements.push(format!(
            "CREATE {id} SET name = {name}, founder = {founder};"
        ));
        seed
    }

    /// A member of `organization` holding the named roles.
    pub fn member(self, organization: &Organization, user: &StackUser, roles: &[&str]) -> Self {
        let mut seed = self.user(user);
        let user = seed.bind(RecordId::from(user.id()));
        let organization = seed.bind(RecordId::from(organization.id()));
        let roles = seed.roles(&organization, roles);
        seed.statements.push(format!(
            "RELATE {user}->member_of->{organization} SET roles = {roles};"
        ));
        seed
    }

    /// A custom role of `organization`.
    pub fn role(mut self, organization: &Organization, name: &str, priority: i64) -> Self {
        let organization = self.bind(RecordId::from(organization.id()));
        let name = self.bind(name.to_owned());
        let priority = self.bind(priority);
        self.statements.push(format!(
            "CREATE organization_role SET organization = {organization}, name = {name}, priority = {priority};"
        ));
        self
    }

    /// Takes the named role out of what members may be given; no request changes this.
    pub fn unassignable(mut self, organization: &Organization, role: &str) -> Self {
        let organization = self.bind(RecordId::from(organization.id()));
        let role = self.bind(role.to_owned());
        self.statements.push(format!(
            "UPDATE organization_role SET assignable = false WHERE organization = {organization} AND name = {role};"
        ));
        self
    }

    /// A join code of `organization`.
    pub fn join_code(mut self, organization: &Organization, code: JoinCode) -> Self {
        let id = self.bind(RecordId::new("organization_join_code", code.key));
        let organization = self.bind(RecordId::from(organization.id()));
        let single_use = self.bind(code.single_use);
        let roles = self.roles(&organization, &code.auto_accept);
        let expires_at = code.expiry.expression();
        self.statements.push(format!(
            "CREATE {id} SET organization = {organization}, single_use = {single_use}, auto_accept_roles = {roles}, expires_at = {expires_at};"
        ));
        self
    }

    /// A pending request of `user` to join `organization`.
    pub fn join_request(self, user: &StackUser, organization: &Organization) -> Self {
        let mut seed = self.user(user);
        let user = seed.bind(RecordId::from(user.id()));
        let organization = seed.bind(RecordId::from(organization.id()));
        seed.statements
            .push(format!("RELATE {user}->request_to_join->{organization};"));
        seed
    }

    /// An unbound service with the host role, named by its key, as the identity component issues
    /// it.
    pub fn service(mut self, key: &str) -> Self {
        let id = self.bind(RecordId::new("service", key));
        let name = self.bind(key.to_owned());
        self.statements.push(format!(
            "CREATE {id} SET name = {name}, role = {{ type: 'host', version: '1.0.0' }};"
        ));
        self
    }

    /// A service with the host role that already belongs to `organization`.
    pub fn organization_service(mut self, organization: &Organization, key: &str) -> Self {
        let id = self.bind(RecordId::new("service", key));
        let name = self.bind(key.to_owned());
        let organization = self.bind(RecordId::from(organization.id()));
        self.statements.push(format!(
            "CREATE {id} SET name = {name}, role = {{ type: 'host', version: '1.0.0' }}, organization = {organization};"
        ));
        self
    }

    /// A registration lease of the unbound service `key` that expires after `expires_in`.
    pub fn registration_lease(mut self, key: &str, token: &str, expires_in: Duration) -> Self {
        let id = self.bind(RecordId::new("service", key));
        let token = self.bind(token.to_owned());
        let seconds = expires_in.as_secs();
        self.statements.push(format!(
            "UPDATE {id} SET registration = {{ token: {token}, expires_at: time::now() + {seconds}s }};"
        ));
        self
    }

    /// The service `key` was seen online just now.
    pub fn service_online(mut self, key: &str) -> Self {
        let id = self.bind(RecordId::new("service", key));
        self.statements.push(format!(
            "UPDATE {id} SET state = {{ status: 'online', last_seen: time::now() }};"
        ));
        self
    }

    /// Any other state, as SurrealQL.
    pub fn statement(mut self, sql: impl Into<String>) -> Self {
        self.statements.push(sql.into());
        self
    }

    /// Writes the seed into `database`, such as the handle `context.database()?` returns.
    pub async fn apply(self, database: &impl Borrow<DatabaseHandle>) -> Result<()> {
        database
            .borrow()
            .run(&self.statements.join("\n"), self.bindings)
            .await
    }

    fn bind(&mut self, value: impl SurrealValue) -> String {
        let name = format!("seed_{}", self.bindings.len());
        self.bindings.push((name.clone(), value.into_value()));
        format!("${name}")
    }

    fn roles(&mut self, organization: &str, roles: &[&str]) -> String {
        let names = self.bind(
            roles
                .iter()
                .map(|role| (*role).to_owned())
                .collect::<Vec<_>>(),
        );
        format!(
            "(SELECT VALUE id FROM organization_role WHERE organization = {organization} AND name IN {names})"
        )
    }
}

/// A join code, which never expires and may be used again unless a modifier says otherwise.
pub struct JoinCode {
    key: String,
    single_use: bool,
    auto_accept: Vec<&'static str>,
    expiry: Expiry,
}

enum Expiry {
    Never,
    InOneHour,
    Expired,
}

impl Expiry {
    fn expression(&self) -> &'static str {
        match self {
            Self::Never => "NONE",
            Self::InOneHour => "time::now() + 1h",
            Self::Expired => "time::now() - 1m",
        }
    }
}

impl JoinCode {
    pub fn new(key: impl Into<String>) -> Self {
        Self {
            key: key.into(),
            single_use: false,
            auto_accept: Vec::new(),
            expiry: Expiry::Never,
        }
    }

    /// The code is consumed by its first use.
    pub fn single_use(mut self) -> Self {
        self.single_use = true;
        self
    }

    /// Whoever uses the code joins at once with the named roles.
    pub fn auto_accept(mut self, roles: &[&'static str]) -> Self {
        self.auto_accept = roles.to_vec();
        self
    }

    /// The code expires within the hour.
    pub fn expiring(mut self) -> Self {
        self.expiry = Expiry::InOneHour;
        self
    }

    /// The code has already expired. Generating a code only accepts a future expiry, so only the
    /// database holds an expired one.
    pub fn expired(mut self) -> Self {
        self.expiry = Expiry::Expired;
        self
    }
}
