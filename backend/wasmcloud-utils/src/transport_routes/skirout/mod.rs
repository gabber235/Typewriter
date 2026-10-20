#[derive(Clone, Debug, PartialEq, Eq, PartialOrd, Ord)]
pub struct SubjectToken(String);
impl SubjectToken {
    pub fn as_str(&self) -> &str {
        &self.0
    }
}
impl TryFrom<&str> for SubjectToken {
    type Error = crate::otel_wasi::Error;
    fn try_from(value: &str) -> Result<Self, Self::Error> {
        if value.is_empty()
            || value
                .chars()
                .any(|character| character.is_whitespace() || ".*>{}".contains(character))
        {
            return Err(crate::otel_wasi::Error::new(
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
#[derive(Default)]
pub struct GrantSet {
    pub publish: std::collections::BTreeSet<String>,
    pub subscribe: std::collections::BTreeSet<String>,
}
#[derive(Clone, Debug)]
pub struct RealmScope {
    pub organization: SubjectToken,
    pub realm: SubjectToken,
}
#[derive(Clone, Debug)]
pub struct ServiceScope {
    pub service: SubjectToken,
}
#[derive(Clone, Debug)]
pub struct OrganizationActorScope {
    pub user: SubjectToken,
    pub organization: SubjectToken,
}
#[derive(Clone, Debug)]
pub struct OrganizationScope {
    pub organization: SubjectToken,
}
#[derive(Clone, Debug)]
pub struct UserScope {
    pub user: SubjectToken,
}
#[derive(Clone, Copy, Debug)]
pub struct InternalComponentScope;
impl TryFrom<&str> for ServiceScope {
    type Error = crate::otel_wasi::Error;
    fn try_from(value: &str) -> Result<Self, Self::Error> {
        Ok(Self {
            service: SubjectToken::try_from(value)?,
        })
    }
}
impl TryFrom<&str> for OrganizationScope {
    type Error = crate::otel_wasi::Error;
    fn try_from(value: &str) -> Result<Self, Self::Error> {
        Ok(Self {
            organization: SubjectToken::try_from(value)?,
        })
    }
}
impl TryFrom<&str> for UserScope {
    type Error = crate::otel_wasi::Error;
    fn try_from(value: &str) -> Result<Self, Self::Error> {
        Ok(Self {
            user: SubjectToken::try_from(value)?,
        })
    }
}
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum RealmRole {
    RealmCoordinator,
    RealmParticipant,
}
impl RealmScope {
    /// Inserts every subject the role may publish to or subscribe to within this scope.
    pub fn grant(&self, role: RealmRole, grants: &mut GrantSet) {
        let Self {
            organization,
            realm,
        } = self;
        match role {
            RealmRole::RealmCoordinator => {
                grants.subscribe.insert(format!(
                    "service.to.{realm}.organization.{organization}.realm.editor.catalog.fetch"
                ));
                grants.publish.insert(format!(
                    "service.from.{realm}.organization.{organization}.realm.editor.catalog.fetch.*"
                ));
                grants.subscribe.insert(format!(
                    "service.to.{realm}.organization.{organization}.realm.editor.catalog.invalidate"
                ));
                grants
                    .publish
                    .insert(
                        format!(
                            "service.from.{realm}.organization.{organization}.realm.editor.catalog.invalidate"
                        ),
                    );
                grants.subscribe.insert(format!(
                    "service.to.{realm}.organization.{organization}.realm.editor.creation.prepare"
                ));
                grants
                    .subscribe
                    .insert(
                        format!(
                            "service.to.{realm}.organization.{organization}.realm.editor.presentation.search"
                        ),
                    );
                grants
                    .publish
                    .insert(
                        format!(
                            "service.from.{realm}.organization.{organization}.realm.editor.presentation.search"
                        ),
                    );
                grants
                    .subscribe
                    .insert(
                        format!(
                            "service.to.{realm}.organization.{organization}.realm.editor.presentation.search.cancel"
                        ),
                    );
                grants
                    .subscribe
                    .insert(
                        format!(
                            "service.to.{realm}.organization.{organization}.realm.editor.capability.computation.invoke"
                        ),
                    );
                grants
                    .subscribe
                    .insert(
                        format!(
                            "service.to.{realm}.organization.{organization}.realm.editor.capability.command.invoke"
                        ),
                    );
                grants
                    .subscribe
                    .insert(
                        format!(
                            "service.to.{realm}.organization.{organization}.realm.editor.resources.operations.resolve"
                        ),
                    );
                grants
                    .subscribe
                    .insert(
                        format!(
                            "service.to.{realm}.organization.{organization}.realm.editor.resources.drops.resolve"
                        ),
                    );
                grants
                    .subscribe
                    .insert(
                        format!(
                            "service.to.{realm}.organization.{organization}.realm.editor.resources.actions.prepare"
                        ),
                    );
                grants
                    .subscribe
                    .insert(
                        format!(
                            "service.to.{realm}.organization.{organization}.realm.editor.authoring.state.query"
                        ),
                    );
                grants
                    .publish
                    .insert(
                        format!(
                            "service.from.{realm}.organization.{organization}.realm.editor.authoring.state.query.*"
                        ),
                    );
                grants
                    .subscribe
                    .insert(
                        format!(
                            "service.to.{realm}.organization.{organization}.realm.editor.authoring.edit.commit"
                        ),
                    );
                grants
                    .subscribe
                    .insert(
                        format!(
                            "service.to.{realm}.organization.{organization}.realm.editor.authoring.type.preview"
                        ),
                    );
                grants
                    .subscribe
                    .insert(
                        format!(
                            "service.to.{realm}.organization.{organization}.realm.editor.authoring.type.commit"
                        ),
                    );
                grants.subscribe.insert(format!(
                    "service.to.{realm}.organization.{organization}.realm.editor.authoring.search"
                ));
                grants
                    .publish
                    .insert(
                        format!(
                            "service.from.{realm}.organization.{organization}.realm.editor.authoring.changed"
                        ),
                    );
                grants
                    .subscribe
                    .insert(
                        format!(
                            "service.to.{realm}.organization.{organization}.realm.editor.authoring.compiled.query"
                        ),
                    );
                grants
                    .publish
                    .insert(
                        format!(
                            "service.from.{realm}.organization.{organization}.realm.editor.authoring.compiled.query.*"
                        ),
                    );
                grants
                    .publish
                    .insert(
                        format!(
                            "service.from.{realm}.organization.{organization}.realm.editor.authoring.compiled.changed"
                        ),
                    );
                grants
                    .subscribe
                    .insert(
                        format!(
                            "service.to.{realm}.organization.{organization}.realm.editor.authoring.compiled.status.query"
                        ),
                    );
                grants.subscribe.insert(format!(
                    "service.to.{realm}.organization.{organization}.realm.editor.authoring.publish"
                ));
                grants
                    .subscribe
                    .insert(
                        format!(
                            "service.to.{realm}.organization.{organization}.realm.editor.authoring.publication.query"
                        ),
                    );
                grants
                    .publish
                    .insert(
                        format!(
                            "service.from.{realm}.organization.{organization}.realm.editor.authoring.publication.query.*"
                        ),
                    );
                grants
                    .subscribe
                    .insert(
                        format!(
                            "service.to.{realm}.organization.{organization}.realm.editor.authoring.publication.watch"
                        ),
                    );
                grants
                    .publish
                    .insert(
                        format!(
                            "service.from.{realm}.organization.{organization}.realm.editor.authoring.publication.watch"
                        ),
                    );
                grants.subscribe.insert(format!(
                    "service.to.{realm}.organization.{organization}.realm.shared.catalog.fetch"
                ));
                grants.subscribe.insert(format!(
                    "service.to.{realm}.organization.{organization}.realm.shared.publish"
                ));
                grants.subscribe.insert(format!(
                    "service.to.{realm}.organization.{organization}.realm.shared.blob.metadata"
                ));
                grants.subscribe.insert(format!(
                    "service.to.{realm}.organization.{organization}.realm.shared.blob.read"
                ));
                grants.subscribe.insert(format!(
                    "service.to.{realm}.organization.{organization}.realm.shared.blob.begin"
                ));
                grants.subscribe.insert(format!(
                    "service.to.{realm}.organization.{organization}.realm.shared.blob.write"
                ));
                grants.subscribe.insert(format!(
                    "service.to.{realm}.organization.{organization}.realm.shared.blob.complete"
                ));
                grants.publish.insert(format!(
                    "service.from.{realm}.organization.{organization}.realm.rollout.probe"
                ));
                grants.publish.insert(format!(
                    "service.from.{realm}.organization.{organization}.realm.rollout.command"
                ));
                grants.publish.insert(format!(
                    "service.from.{realm}.organization.{organization}.realm.rollout.status"
                ));
                grants.subscribe.insert(format!(
                    "service.to.{realm}.organization.{organization}.realm.rollout.state"
                ));
            }
            RealmRole::RealmParticipant => {
                grants
                    .publish
                    .insert(
                        format!(
                            "service.to.{realm}.organization.{organization}.realm.editor.authoring.compiled.query"
                        ),
                    );
                grants
                    .subscribe
                    .insert(
                        format!(
                            "service.from.{realm}.organization.{organization}.realm.editor.authoring.compiled.query.*"
                        ),
                    );
                grants
                    .subscribe
                    .insert(
                        format!(
                            "service.from.{realm}.organization.{organization}.realm.editor.authoring.compiled.changed"
                        ),
                    );
                grants.publish.insert(format!(
                    "service.to.{realm}.organization.{organization}.realm.shared.catalog.fetch"
                ));
                grants.publish.insert(format!(
                    "service.to.{realm}.organization.{organization}.realm.shared.publish"
                ));
                grants.publish.insert(format!(
                    "service.to.{realm}.organization.{organization}.realm.shared.blob.metadata"
                ));
                grants.publish.insert(format!(
                    "service.to.{realm}.organization.{organization}.realm.shared.blob.read"
                ));
                grants.publish.insert(format!(
                    "service.to.{realm}.organization.{organization}.realm.shared.blob.begin"
                ));
                grants.publish.insert(format!(
                    "service.to.{realm}.organization.{organization}.realm.shared.blob.write"
                ));
                grants.publish.insert(format!(
                    "service.to.{realm}.organization.{organization}.realm.shared.blob.complete"
                ));
                grants.subscribe.insert(format!(
                    "service.from.{realm}.organization.{organization}.realm.rollout.probe"
                ));
                grants.subscribe.insert(format!(
                    "service.from.{realm}.organization.{organization}.realm.rollout.command"
                ));
                grants.subscribe.insert(format!(
                    "service.from.{realm}.organization.{organization}.realm.rollout.status"
                ));
                grants.publish.insert(format!(
                    "service.to.{realm}.organization.{organization}.realm.rollout.state"
                ));
            }
        }
    }
}
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum ServiceRole {
    RegisteredService,
}
impl ServiceScope {
    /// Inserts every subject the role may publish to or subscribe to within this scope.
    pub fn grant(&self, role: ServiceRole, grants: &mut GrantSet) {
        let Self { service } = self;
        match role {
            ServiceRole::RegisteredService => {
                grants
                    .publish
                    .insert(format!("cloud.to.service.{service}.binding.query"));
                grants
                    .subscribe
                    .insert(format!("cloud.from.service.{service}.registration.bound"));
                grants
                    .publish
                    .insert(format!("cloud.to.service.{service}.registration.ensure"));
                grants
                    .publish
                    .insert(format!("cloud.to.service.{service}.messaging.scope"));
                grants
                    .publish
                    .insert(format!("cloud.to.service.{service}.execution.register"));
                grants
                    .publish
                    .insert(format!("cloud.to.service.{service}.execution.watch"));
                grants
                    .subscribe
                    .insert(format!("cloud.from.service.{service}.execution.watch"));
                grants
                    .publish
                    .insert(format!("cloud.to.service.{service}.execution.report"));
                grants
                    .publish
                    .insert(format!("cloud.to.service.{service}.heartbeat"));
                grants
                    .publish
                    .insert(format!("cloud.to.service.{service}.shutdown"));
            }
        }
    }
}
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum OrganizationActorRole {
    OrganizationMember,
}
impl OrganizationActorScope {
    /// Inserts every subject the role may publish to or subscribe to within this scope.
    pub fn grant(
        &self,
        role: OrganizationActorRole,
        session: &crate::transport::ConnectionSession,
        grants: &mut GrantSet,
    ) {
        let Self { user, organization } = self;
        match role {
            OrganizationActorRole::OrganizationMember => {
                let organization_members_changed = consumer_name(
                    user,
                    Some(organization),
                    session,
                    "organization_members_changed",
                );
                let organization_join_requests_changed = consumer_name(
                    user,
                    Some(organization),
                    session,
                    "organization_join_requests_changed",
                );
                let organization_join_codes_changed = consumer_name(
                    user,
                    Some(organization),
                    session,
                    "organization_join_codes_changed",
                );
                grants.publish.insert(format!(
                    "cloud.to.user.{user}.organization.{organization}.members.watch"
                ));
                grants
                    .publish
                    .insert(String::from("$JS.API.STREAM.INFO.TYPEWRITER_MEMBERSHIP"));
                grants
                    .publish
                    .insert(
                        format!(
                            "$JS.API.CONSUMER.CREATE.TYPEWRITER_MEMBERSHIP.{organization_members_changed}.cloud.from.organization.{organization}.members.changed"
                        ),
                    );
                grants.publish.insert(format!(
                    "$JS.API.CONSUMER.INFO.TYPEWRITER_MEMBERSHIP.{organization_members_changed}"
                ));
                grants.publish.insert(format!(
                    "$JS.API.CONSUMER.MSG.NEXT.TYPEWRITER_MEMBERSHIP.{organization_members_changed}"
                ));
                grants.publish.insert(format!(
                    "$JS.API.CONSUMER.DELETE.TYPEWRITER_MEMBERSHIP.{organization_members_changed}"
                ));
                grants.publish.insert(format!(
                    "cloud.to.user.{user}.organization.{organization}.members.update"
                ));
                grants.publish.insert(format!(
                    "cloud.to.user.{user}.organization.{organization}.members.remove"
                ));
                grants.publish.insert(format!(
                    "cloud.to.user.{user}.organization.{organization}.members.join_requests.watch"
                ));
                grants
                    .publish
                    .insert(
                        format!(
                            "$JS.API.CONSUMER.CREATE.TYPEWRITER_MEMBERSHIP.{organization_join_requests_changed}.cloud.from.organization.{organization}.join_requests.changed"
                        ),
                    );
                grants
                    .publish
                    .insert(
                        format!(
                            "$JS.API.CONSUMER.INFO.TYPEWRITER_MEMBERSHIP.{organization_join_requests_changed}"
                        ),
                    );
                grants
                    .publish
                    .insert(
                        format!(
                            "$JS.API.CONSUMER.MSG.NEXT.TYPEWRITER_MEMBERSHIP.{organization_join_requests_changed}"
                        ),
                    );
                grants
                    .publish
                    .insert(
                        format!(
                            "$JS.API.CONSUMER.DELETE.TYPEWRITER_MEMBERSHIP.{organization_join_requests_changed}"
                        ),
                    );
                grants.publish.insert(format!(
                    "cloud.to.user.{user}.organization.{organization}.members.join_requests.approve"
                ));
                grants.publish.insert(format!(
                    "cloud.to.user.{user}.organization.{organization}.members.join_requests.decline"
                ));
                grants.publish.insert(format!(
                    "cloud.to.user.{user}.organization.{organization}.members.join_codes.watch"
                ));
                grants
                    .publish
                    .insert(
                        format!(
                            "$JS.API.CONSUMER.CREATE.TYPEWRITER_MEMBERSHIP.{organization_join_codes_changed}.cloud.from.organization.{organization}.join_codes.changed"
                        ),
                    );
                grants.publish.insert(format!(
                    "$JS.API.CONSUMER.INFO.TYPEWRITER_MEMBERSHIP.{organization_join_codes_changed}"
                ));
                grants
                    .publish
                    .insert(
                        format!(
                            "$JS.API.CONSUMER.MSG.NEXT.TYPEWRITER_MEMBERSHIP.{organization_join_codes_changed}"
                        ),
                    );
                grants
                    .publish
                    .insert(
                        format!(
                            "$JS.API.CONSUMER.DELETE.TYPEWRITER_MEMBERSHIP.{organization_join_codes_changed}"
                        ),
                    );
                grants.publish.insert(format!(
                    "cloud.to.user.{user}.organization.{organization}.members.join_codes.generate"
                ));
                grants.publish.insert(format!(
                    "cloud.to.user.{user}.organization.{organization}.members.join_codes.revoke"
                ));
                grants.publish.insert(format!(
                    "cloud.to.user.{user}.organization.{organization}.roles.watch"
                ));
                grants.publish.insert(format!(
                    "cloud.to.user.{user}.organization.{organization}.services.bind"
                ));
                grants.publish.insert(format!(
                    "cloud.to.user.{user}.organization.{organization}.services.watch"
                ));
                grants.subscribe.insert(format!(
                    "cloud.from.organization.{organization}.services.watch"
                ));
                grants.publish.insert(format!(
                    "cloud.to.user.{user}.organization.{organization}.services.update"
                ));
                grants.publish.insert(format!(
                    "cloud.to.user.{user}.organization.{organization}.services.unbind"
                ));
                grants.publish.insert(format!(
                    "cloud.to.user.{user}.organization.{organization}.topology.configure"
                ));
                grants.publish.insert(format!(
                    "cloud.to.user.{user}.organization.{organization}.topology.watch"
                ));
                grants.subscribe.insert(format!(
                    "cloud.from.organization.{organization}.topology.watch"
                ));
                grants.publish.insert(format!(
                    "service.to.*.organization.{organization}.realm.editor.catalog.fetch"
                ));
                grants.subscribe.insert(format!(
                    "service.from.*.organization.{organization}.realm.editor.catalog.fetch.*"
                ));
                grants.publish.insert(format!(
                    "service.to.*.organization.{organization}.realm.editor.catalog.invalidate"
                ));
                grants.subscribe.insert(format!(
                    "service.from.*.organization.{organization}.realm.editor.catalog.invalidate"
                ));
                grants.publish.insert(format!(
                    "service.to.*.organization.{organization}.realm.editor.creation.prepare"
                ));
                grants.publish.insert(format!(
                    "service.to.*.organization.{organization}.realm.editor.presentation.search"
                ));
                grants.subscribe.insert(format!(
                    "service.from.*.organization.{organization}.realm.editor.presentation.search"
                ));
                grants
                    .publish
                    .insert(
                        format!(
                            "service.to.*.organization.{organization}.realm.editor.presentation.search.cancel"
                        ),
                    );
                grants
                    .publish
                    .insert(
                        format!(
                            "service.to.*.organization.{organization}.realm.editor.capability.computation.invoke"
                        ),
                    );
                grants
                    .publish
                    .insert(
                        format!(
                            "service.to.*.organization.{organization}.realm.editor.capability.command.invoke"
                        ),
                    );
                grants
                    .publish
                    .insert(
                        format!(
                            "service.to.*.organization.{organization}.realm.editor.resources.operations.resolve"
                        ),
                    );
                grants.publish.insert(format!(
                    "service.to.*.organization.{organization}.realm.editor.resources.drops.resolve"
                ));
                grants
                    .publish
                    .insert(
                        format!(
                            "service.to.*.organization.{organization}.realm.editor.resources.actions.prepare"
                        ),
                    );
                grants.publish.insert(format!(
                    "service.to.*.organization.{organization}.realm.editor.authoring.state.query"
                ));
                grants
                    .subscribe
                    .insert(
                        format!(
                            "service.from.*.organization.{organization}.realm.editor.authoring.state.query.*"
                        ),
                    );
                grants.publish.insert(format!(
                    "service.to.*.organization.{organization}.realm.editor.authoring.edit.commit"
                ));
                grants.publish.insert(format!(
                    "service.to.*.organization.{organization}.realm.editor.authoring.type.preview"
                ));
                grants.publish.insert(format!(
                    "service.to.*.organization.{organization}.realm.editor.authoring.type.commit"
                ));
                grants.publish.insert(format!(
                    "service.to.*.organization.{organization}.realm.editor.authoring.search"
                ));
                grants.subscribe.insert(format!(
                    "service.from.*.organization.{organization}.realm.editor.authoring.changed"
                ));
                grants.publish.insert(format!(
                    "service.to.*.organization.{organization}.realm.editor.authoring.compiled.query"
                ));
                grants
                    .subscribe
                    .insert(
                        format!(
                            "service.from.*.organization.{organization}.realm.editor.authoring.compiled.query.*"
                        ),
                    );
                grants
                    .subscribe
                    .insert(
                        format!(
                            "service.from.*.organization.{organization}.realm.editor.authoring.compiled.changed"
                        ),
                    );
                grants
                    .publish
                    .insert(
                        format!(
                            "service.to.*.organization.{organization}.realm.editor.authoring.compiled.status.query"
                        ),
                    );
                grants.publish.insert(format!(
                    "service.to.*.organization.{organization}.realm.editor.authoring.publish"
                ));
                grants
                    .publish
                    .insert(
                        format!(
                            "service.to.*.organization.{organization}.realm.editor.authoring.publication.query"
                        ),
                    );
                grants
                    .subscribe
                    .insert(
                        format!(
                            "service.from.*.organization.{organization}.realm.editor.authoring.publication.query.*"
                        ),
                    );
                grants
                    .publish
                    .insert(
                        format!(
                            "service.to.*.organization.{organization}.realm.editor.authoring.publication.watch"
                        ),
                    );
                grants
                    .subscribe
                    .insert(
                        format!(
                            "service.from.*.organization.{organization}.realm.editor.authoring.publication.watch"
                        ),
                    );
                grants.publish.insert(format!(
                    "service.to.*.organization.{organization}.realm.shared.catalog.fetch"
                ));
                grants.publish.insert(format!(
                    "service.to.*.organization.{organization}.realm.shared.publish"
                ));
                grants.publish.insert(format!(
                    "service.to.*.organization.{organization}.realm.shared.blob.metadata"
                ));
                grants.publish.insert(format!(
                    "service.to.*.organization.{organization}.realm.shared.blob.read"
                ));
                grants.publish.insert(format!(
                    "service.to.*.organization.{organization}.realm.shared.blob.begin"
                ));
                grants.publish.insert(format!(
                    "service.to.*.organization.{organization}.realm.shared.blob.write"
                ));
                grants.publish.insert(format!(
                    "service.to.*.organization.{organization}.realm.shared.blob.complete"
                ));
                grants.publish.insert(format!(
                    "typewriter.presence.organization.{organization}.user.{user}"
                ));
                grants.subscribe.insert(format!(
                    "typewriter.presence.organization.{organization}.user.*"
                ));
            }
        }
    }
}
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum UserRole {
    AuthenticatedUser,
}
impl UserScope {
    /// Inserts every subject the role may publish to or subscribe to within this scope.
    pub fn grant(
        &self,
        role: UserRole,
        session: &crate::transport::ConnectionSession,
        grants: &mut GrantSet,
    ) {
        let Self { user } = self;
        match role {
            UserRole::AuthenticatedUser => {
                let user_organizations_changed =
                    consumer_name(user, None, session, "user_organizations_changed");
                let user_join_requests_changed =
                    consumer_name(user, None, session, "user_join_requests_changed");
                grants
                    .publish
                    .insert(format!("cloud.to.user.{user}.organization.create"));
                grants
                    .publish
                    .insert(format!("cloud.to.user.{user}.organization.watch"));
                grants
                    .publish
                    .insert(String::from("$JS.API.STREAM.INFO.TYPEWRITER_MEMBERSHIP"));
                grants
                    .publish
                    .insert(
                        format!(
                            "$JS.API.CONSUMER.CREATE.TYPEWRITER_MEMBERSHIP.{user_organizations_changed}.cloud.from.user.{user}.organizations.changed"
                        ),
                    );
                grants.publish.insert(format!(
                    "$JS.API.CONSUMER.INFO.TYPEWRITER_MEMBERSHIP.{user_organizations_changed}"
                ));
                grants.publish.insert(format!(
                    "$JS.API.CONSUMER.MSG.NEXT.TYPEWRITER_MEMBERSHIP.{user_organizations_changed}"
                ));
                grants.publish.insert(format!(
                    "$JS.API.CONSUMER.DELETE.TYPEWRITER_MEMBERSHIP.{user_organizations_changed}"
                ));
                grants.publish.insert(format!(
                    "cloud.to.user.{user}.organization.join_requests.watch"
                ));
                grants
                    .publish
                    .insert(
                        format!(
                            "$JS.API.CONSUMER.CREATE.TYPEWRITER_MEMBERSHIP.{user_join_requests_changed}.cloud.from.user.{user}.join_requests.changed"
                        ),
                    );
                grants.publish.insert(format!(
                    "$JS.API.CONSUMER.INFO.TYPEWRITER_MEMBERSHIP.{user_join_requests_changed}"
                ));
                grants.publish.insert(format!(
                    "$JS.API.CONSUMER.MSG.NEXT.TYPEWRITER_MEMBERSHIP.{user_join_requests_changed}"
                ));
                grants.publish.insert(format!(
                    "$JS.API.CONSUMER.DELETE.TYPEWRITER_MEMBERSHIP.{user_join_requests_changed}"
                ));
                grants.publish.insert(format!(
                    "cloud.to.user.{user}.organization.join_requests.request"
                ));
                grants.publish.insert(format!(
                    "cloud.to.user.{user}.organization.join_requests.cancel"
                ));
            }
        }
    }
}
/// Names a connection's persistent projection consumer: `TW_` followed by the unpadded
/// URL safe Base64 of the compact JSON array `[actor, organization, session, projection]`.
/// The panel derives the same name when it opens the consumer.
pub fn consumer_name(
    actor: &SubjectToken,
    organization: Option<&SubjectToken>,
    session: &crate::transport::ConnectionSession,
    projection: &str,
) -> String {
    use base64::Engine as _;
    let identity = serde_json::json!([
        actor.as_str(),
        organization.map(SubjectToken::as_str),
        session.as_str(),
        projection
    ]);
    format!(
        "TW_{}",
        base64::engine::general_purpose::URL_SAFE_NO_PAD.encode(identity.to_string())
    )
}
pub trait RequestRoute {
    type Scope;
    type Request: 'static;
    type Response: 'static;
    type Delivery: RequestResponseDelivery<Self::Response>;
    fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response>;
    fn scope(subject: &str) -> Result<Option<Self::Scope>, crate::otel_wasi::Error>;
}
pub trait OutboundRequestRoute: RequestRoute {
    fn subject(scope: &Self::Scope) -> String;
}
pub trait RequestResponseDelivery<Response> {
    fn reply_result(
        msg: crate::wasmcloud::messaging::types::NatsMessage,
        result: Result<Response, crate::otel_wasi::Error>,
        serializer: crate::skir_client::Serializer<Response>,
    ) -> impl std::future::Future<Output = Result<(), crate::otel_wasi::Error>>;
}
pub struct DomainResponseDelivery;
impl<Response: crate::SkirResponse> RequestResponseDelivery<Response> for DomainResponseDelivery {
    async fn reply_result(
        msg: crate::wasmcloud::messaging::types::NatsMessage,
        result: Result<Response, crate::otel_wasi::Error>,
        _serializer: crate::skir_client::Serializer<Response>,
    ) -> Result<(), crate::otel_wasi::Error> {
        crate::wasmcloud::messaging::reply_handler_result(msg, result).await
    }
}
pub struct PlainResponseDelivery;
impl<Response: 'static> RequestResponseDelivery<Response> for PlainResponseDelivery {
    async fn reply_result(
        msg: crate::wasmcloud::messaging::types::NatsMessage,
        result: Result<Response, crate::otel_wasi::Error>,
        serializer: crate::skir_client::Serializer<Response>,
    ) -> Result<(), crate::otel_wasi::Error> {
        let response = result?;
        let body = serializer.to_bytes(&response);
        crate::wasmcloud::messaging::reply(msg, body).await
    }
}
pub trait EventRoute {
    type Scope;
    type Event: 'static;
    fn serializer() -> crate::skir_client::Serializer<Self::Event>;
    fn scope(subject: &str) -> Result<Option<Self::Scope>, crate::otel_wasi::Error>;
}
pub trait OutboundEventRoute {
    type Scope;
    type Event: 'static;
    fn serializer() -> crate::skir_client::Serializer<Self::Event>;
    fn subject(scope: &Self::Scope) -> String;
}
pub trait PersistentEventRoute: OutboundEventRoute {
    fn stream() -> &'static str;
}
pub trait TransientEventRoute: OutboundEventRoute {}
pub struct EventDelivery<Route: OutboundEventRoute> {
    subject: String,
    route: std::marker::PhantomData<Route>,
}
impl<Route: OutboundEventRoute> EventDelivery<Route> {
    fn new(scope: &Route::Scope) -> Self {
        Self {
            subject: Route::subject(scope),
            route: std::marker::PhantomData,
        }
    }
    pub fn subject(&self) -> &str {
        &self.subject
    }
}
impl<Route: TransientEventRoute> EventDelivery<Route> {
    pub async fn publish(&self, event: Route::Event) -> Result<(), crate::otel_wasi::Error> {
        crate::wasmcloud::messaging::publish(
            self.subject.clone(),
            Route::serializer().to_bytes(&event),
        )
        .await
    }
}
impl<Route: PersistentEventRoute> EventDelivery<Route> {
    pub async fn persist(&self, event: Route::Event) -> Result<(), crate::otel_wasi::Error> {
        let acknowledgement = crate::wasmcloud::messaging::persist(
            self.subject.clone(),
            Route::serializer().to_bytes(&event),
        )
        .await?;
        if acknowledgement.stream_name != Route::stream() {
            return Err(crate::otel_wasi::Error::new(
                "transport-event-wrong-stream",
                format!(
                    "expected {}, got {}",
                    Route::stream(),
                    acknowledgement.stream_name
                ),
            ));
        }
        Ok(())
    }
}
pub async fn dispatch_request<Route, Handler, Work>(
    msg: crate::wasmcloud::messaging::types::NatsMessage,
    handler: Handler,
) -> Option<Result<(), crate::otel_wasi::Error>>
where
    Route: RequestRoute,
    Handler: FnOnce(
        crate::wasmcloud::messaging::types::NatsMessage,
        Route::Scope,
        Route::Request,
    ) -> Work,
    Work: std::future::Future<Output = Result<Route::Response, crate::otel_wasi::Error>>,
{
    let scope = match Route::scope(&msg.subject) {
        Ok(None) => return None,
        Ok(Some(scope)) => Ok(scope),
        Err(error) => Err(error),
    };
    let result = async {
        let scope = scope?;
        let request = Route::method()
            .request_serializer
            .from_bytes(&msg.body, crate::skir_client::UnrecognizedValues::Drop)
            .map_err(|error| crate::otel_wasi::Error::new("transport-decode", error.to_string()))?;
        handler(msg.clone(), scope, request).await
    }
    .await;
    Some(
        Route::Delivery::reply_result(msg, result, Route::method().response_serializer.clone())
            .await,
    )
}
pub async fn request_route<Route: OutboundRequestRoute>(
    scope: &Route::Scope,
    request: &Route::Request,
) -> Result<Route::Response, crate::otel_wasi::Error> {
    let response = crate::wasmcloud::messaging::request(
        Route::subject(scope),
        Route::method().request_serializer.to_bytes(request),
    )
    .await?;
    Route::method()
        .response_serializer
        .from_bytes(&response.body, crate::skir_client::UnrecognizedValues::Drop)
        .map_err(|error| crate::otel_wasi::Error::new("transport-decode", error.to_string()))
}
pub fn unmatched_route(
    msg: &crate::wasmcloud::messaging::types::NatsMessage,
    slug: &'static str,
) -> crate::otel_wasi::Error {
    crate::otel_wasi::Error::new(slug, format!("Unknown subject: {}", msg.subject))
}
pub async fn dispatch_event<Route, Handler, Work>(
    msg: crate::wasmcloud::messaging::types::NatsMessage,
    handler: Handler,
) -> Option<Result<(), crate::otel_wasi::Error>>
where
    Route: EventRoute,
    Handler:
        FnOnce(crate::wasmcloud::messaging::types::NatsMessage, Route::Scope, Route::Event) -> Work,
    Work: std::future::Future<Output = Result<(), crate::otel_wasi::Error>>,
{
    let scope = match Route::scope(&msg.subject) {
        Ok(None) => return None,
        Ok(Some(scope)) => Ok(scope),
        Err(error) => Err(error),
    };
    Some(
        async {
            let scope = scope?;
            let event = Route::serializer()
                .from_bytes(&msg.body, crate::skir_client::UnrecognizedValues::Drop)
                .map_err(|error| {
                    crate::otel_wasi::Error::new("transport-decode", error.to_string())
                })?;
            handler(msg, scope, event).await
        }
        .await,
    )
}
#[macro_export]
macro_rules! dispatch_route {
    ($msg:expr, $route:ty, $handler:path) => {
        if let Some(result) =
            $crate::transport_routes::dispatch_request::<$route, _, _>($msg.clone(), $handler).await
        {
            return result;
        }
    };
}
#[macro_export]
macro_rules! dispatch_event_route {
    ($msg:expr, $route:ty, $handler:path) => {
        if let Some(result) =
            $crate::transport_routes::dispatch_event::<$route, _, _>($msg.clone(), $handler).await
        {
            return result;
        }
    };
}
pub struct UserOrganizationCreateRoute;
impl RequestRoute for UserOrganizationCreateRoute {
    type Scope = UserScope;
    type Request = crate::skirout::base::organization::v1::organization::CreateOrganizationRequest;
    type Response =
        crate::skirout::base::organization::v1::organization::CreateOrganizationResponse;
    type Delivery = DomainResponseDelivery;
    fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response> {
        crate::skirout::base::organization::v1::organization::create_organization_method()
    }
    fn scope(subject: &str) -> Result<Option<Self::Scope>, crate::otel_wasi::Error> {
        let parts: Vec<_> = subject.split('.').collect();
        match parts.as_slice() {
            ["typewriter", "from", "user", user, "organization", "create"] => Ok(Some(UserScope {
                user: SubjectToken::try_from(*user)?,
            })),
            _ => Ok(None),
        }
    }
}
pub struct UserOrganizationsWatchRoute;
impl RequestRoute for UserOrganizationsWatchRoute {
    type Scope = UserScope;
    type Request = crate::skirout::base::organization::v1::user::WatchUserOrganizationsRequest;
    type Response = crate::skirout::base::organization::v1::user::WatchUserOrganizationsResponse;
    type Delivery = DomainResponseDelivery;
    fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response> {
        crate::skirout::base::organization::v1::user::watch_user_organizations_method()
    }
    fn scope(subject: &str) -> Result<Option<Self::Scope>, crate::otel_wasi::Error> {
        let parts: Vec<_> = subject.split('.').collect();
        match parts.as_slice() {
            ["typewriter", "from", "user", user, "organization", "watch"] => Ok(Some(UserScope {
                user: SubjectToken::try_from(*user)?,
            })),
            _ => Ok(None),
        }
    }
}
pub struct UserJoinRequestsWatchRoute;
impl RequestRoute for UserJoinRequestsWatchRoute {
    type Scope = UserScope;
    type Request = crate::skirout::base::organization::v1::user::WatchUserJoinRequestsRequest;
    type Response = crate::skirout::base::organization::v1::user::WatchUserJoinRequestsResponse;
    type Delivery = DomainResponseDelivery;
    fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response> {
        crate::skirout::base::organization::v1::user::watch_user_join_requests_method()
    }
    fn scope(subject: &str) -> Result<Option<Self::Scope>, crate::otel_wasi::Error> {
        let parts: Vec<_> = subject.split('.').collect();
        match parts.as_slice() {
            [
                "typewriter",
                "from",
                "user",
                user,
                "organization",
                "join_requests",
                "watch",
            ] => Ok(Some(UserScope {
                user: SubjectToken::try_from(*user)?,
            })),
            _ => Ok(None),
        }
    }
}
pub struct UserJoinRequestSubmitRoute;
impl RequestRoute for UserJoinRequestSubmitRoute {
    type Scope = UserScope;
    type Request = crate::skirout::base::organization::v1::user::SubmitUserJoinRequestRequest;
    type Response = crate::skirout::base::organization::v1::user::SubmitUserJoinRequestResponse;
    type Delivery = DomainResponseDelivery;
    fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response> {
        crate::skirout::base::organization::v1::user::submit_user_join_request_method()
    }
    fn scope(subject: &str) -> Result<Option<Self::Scope>, crate::otel_wasi::Error> {
        let parts: Vec<_> = subject.split('.').collect();
        match parts.as_slice() {
            [
                "typewriter",
                "from",
                "user",
                user,
                "organization",
                "join_requests",
                "request",
            ] => Ok(Some(UserScope {
                user: SubjectToken::try_from(*user)?,
            })),
            _ => Ok(None),
        }
    }
}
pub struct UserJoinRequestCancelRoute;
impl RequestRoute for UserJoinRequestCancelRoute {
    type Scope = UserScope;
    type Request = crate::skirout::base::organization::v1::user::CancelUserJoinRequestRequest;
    type Response = crate::skirout::base::organization::v1::user::CancelUserJoinRequestResponse;
    type Delivery = DomainResponseDelivery;
    fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response> {
        crate::skirout::base::organization::v1::user::cancel_user_join_request_method()
    }
    fn scope(subject: &str) -> Result<Option<Self::Scope>, crate::otel_wasi::Error> {
        let parts: Vec<_> = subject.split('.').collect();
        match parts.as_slice() {
            [
                "typewriter",
                "from",
                "user",
                user,
                "organization",
                "join_requests",
                "cancel",
            ] => Ok(Some(UserScope {
                user: SubjectToken::try_from(*user)?,
            })),
            _ => Ok(None),
        }
    }
}
pub struct OrganizationMembersWatchRoute;
impl RequestRoute for OrganizationMembersWatchRoute {
    type Scope = OrganizationActorScope;
    type Request = crate::skirout::base::organization::v1::member::WatchOrganizationMembersRequest;
    type Response =
        crate::skirout::base::organization::v1::member::WatchOrganizationMembersResponse;
    type Delivery = DomainResponseDelivery;
    fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response> {
        crate::skirout::base::organization::v1::member::watch_organization_members_method()
    }
    fn scope(subject: &str) -> Result<Option<Self::Scope>, crate::otel_wasi::Error> {
        let parts: Vec<_> = subject.split('.').collect();
        match parts.as_slice() {
            [
                "typewriter",
                "from",
                "user",
                user,
                "organization",
                organization,
                "members",
                "watch",
            ] => Ok(Some(OrganizationActorScope {
                organization: SubjectToken::try_from(*organization)?,
                user: SubjectToken::try_from(*user)?,
            })),
            _ => Ok(None),
        }
    }
}
pub struct OrganizationMembersUpdateRoute;
impl RequestRoute for OrganizationMembersUpdateRoute {
    type Scope = OrganizationActorScope;
    type Request =
        crate::skirout::base::organization::v1::member::UpdateOrganizationMemberRolesRequest;
    type Response =
        crate::skirout::base::organization::v1::member::UpdateOrganizationMemberRolesResponse;
    type Delivery = DomainResponseDelivery;
    fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response> {
        crate::skirout::base::organization::v1::member::update_organization_member_roles_method()
    }
    fn scope(subject: &str) -> Result<Option<Self::Scope>, crate::otel_wasi::Error> {
        let parts: Vec<_> = subject.split('.').collect();
        match parts.as_slice() {
            [
                "typewriter",
                "from",
                "user",
                user,
                "organization",
                organization,
                "members",
                "update",
            ] => Ok(Some(OrganizationActorScope {
                organization: SubjectToken::try_from(*organization)?,
                user: SubjectToken::try_from(*user)?,
            })),
            _ => Ok(None),
        }
    }
}
pub struct OrganizationMemberRemoveRoute;
impl RequestRoute for OrganizationMemberRemoveRoute {
    type Scope = OrganizationActorScope;
    type Request = crate::skirout::base::organization::v1::member::RemoveOrganizationMemberRequest;
    type Response =
        crate::skirout::base::organization::v1::member::RemoveOrganizationMemberResponse;
    type Delivery = DomainResponseDelivery;
    fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response> {
        crate::skirout::base::organization::v1::member::remove_organization_member_method()
    }
    fn scope(subject: &str) -> Result<Option<Self::Scope>, crate::otel_wasi::Error> {
        let parts: Vec<_> = subject.split('.').collect();
        match parts.as_slice() {
            [
                "typewriter",
                "from",
                "user",
                user,
                "organization",
                organization,
                "members",
                "remove",
            ] => Ok(Some(OrganizationActorScope {
                organization: SubjectToken::try_from(*organization)?,
                user: SubjectToken::try_from(*user)?,
            })),
            _ => Ok(None),
        }
    }
}
pub struct OrganizationJoinRequestsWatchRoute;
impl RequestRoute for OrganizationJoinRequestsWatchRoute {
    type Scope = OrganizationActorScope;
    type Request =
        crate::skirout::base::organization::v1::join_request::WatchOrganizationJoinRequestsRequest;
    type Response =
        crate::skirout::base::organization::v1::join_request::WatchOrganizationJoinRequestsResponse;
    type Delivery = DomainResponseDelivery;
    fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response> {
        crate::skirout::base::organization::v1::join_request::watch_organization_join_requests_method()
    }
    fn scope(subject: &str) -> Result<Option<Self::Scope>, crate::otel_wasi::Error> {
        let parts: Vec<_> = subject.split('.').collect();
        match parts.as_slice() {
            [
                "typewriter",
                "from",
                "user",
                user,
                "organization",
                organization,
                "members",
                "join_requests",
                "watch",
            ] => Ok(Some(OrganizationActorScope {
                organization: SubjectToken::try_from(*organization)?,
                user: SubjectToken::try_from(*user)?,
            })),
            _ => Ok(None),
        }
    }
}
pub struct OrganizationJoinRequestsApproveRoute;
impl RequestRoute for OrganizationJoinRequestsApproveRoute {
    type Scope = OrganizationActorScope;
    type Request = crate::skirout::base::organization::v1::join_request::ApproveOrganizationJoinRequestsRequest;
    type Response = crate::skirout::base::organization::v1::join_request::ApproveOrganizationJoinRequestsResponse;
    type Delivery = DomainResponseDelivery;
    fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response> {
        crate::skirout::base::organization::v1::join_request::approve_organization_join_requests_method()
    }
    fn scope(subject: &str) -> Result<Option<Self::Scope>, crate::otel_wasi::Error> {
        let parts: Vec<_> = subject.split('.').collect();
        match parts.as_slice() {
            [
                "typewriter",
                "from",
                "user",
                user,
                "organization",
                organization,
                "members",
                "join_requests",
                "approve",
            ] => Ok(Some(OrganizationActorScope {
                organization: SubjectToken::try_from(*organization)?,
                user: SubjectToken::try_from(*user)?,
            })),
            _ => Ok(None),
        }
    }
}
pub struct OrganizationJoinRequestDeclineRoute;
impl RequestRoute for OrganizationJoinRequestDeclineRoute {
    type Scope = OrganizationActorScope;
    type Request =
        crate::skirout::base::organization::v1::join_request::DeclineOrganizationJoinRequestRequest;
    type Response = crate::skirout::base::organization::v1::join_request::DeclineOrganizationJoinRequestResponse;
    type Delivery = DomainResponseDelivery;
    fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response> {
        crate::skirout::base::organization::v1::join_request::decline_organization_join_request_method()
    }
    fn scope(subject: &str) -> Result<Option<Self::Scope>, crate::otel_wasi::Error> {
        let parts: Vec<_> = subject.split('.').collect();
        match parts.as_slice() {
            [
                "typewriter",
                "from",
                "user",
                user,
                "organization",
                organization,
                "members",
                "join_requests",
                "decline",
            ] => Ok(Some(OrganizationActorScope {
                organization: SubjectToken::try_from(*organization)?,
                user: SubjectToken::try_from(*user)?,
            })),
            _ => Ok(None),
        }
    }
}
pub struct OrganizationJoinCodesWatchRoute;
impl RequestRoute for OrganizationJoinCodesWatchRoute {
    type Scope = OrganizationActorScope;
    type Request =
        crate::skirout::base::organization::v1::join_codes::WatchOrganizationJoinCodesRequest;
    type Response =
        crate::skirout::base::organization::v1::join_codes::WatchOrganizationJoinCodesResponse;
    type Delivery = DomainResponseDelivery;
    fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response> {
        crate::skirout::base::organization::v1::join_codes::watch_organization_join_codes_method()
    }
    fn scope(subject: &str) -> Result<Option<Self::Scope>, crate::otel_wasi::Error> {
        let parts: Vec<_> = subject.split('.').collect();
        match parts.as_slice() {
            [
                "typewriter",
                "from",
                "user",
                user,
                "organization",
                organization,
                "members",
                "join_codes",
                "watch",
            ] => Ok(Some(OrganizationActorScope {
                organization: SubjectToken::try_from(*organization)?,
                user: SubjectToken::try_from(*user)?,
            })),
            _ => Ok(None),
        }
    }
}
pub struct OrganizationJoinCodeGenerateRoute;
impl RequestRoute for OrganizationJoinCodeGenerateRoute {
    type Scope = OrganizationActorScope;
    type Request =
        crate::skirout::base::organization::v1::join_codes::GenerateOrganizationJoinCodeRequest;
    type Response =
        crate::skirout::base::organization::v1::join_codes::GenerateOrganizationJoinCodeResponse;
    type Delivery = DomainResponseDelivery;
    fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response> {
        crate::skirout::base::organization::v1::join_codes::generate_organization_join_code_method()
    }
    fn scope(subject: &str) -> Result<Option<Self::Scope>, crate::otel_wasi::Error> {
        let parts: Vec<_> = subject.split('.').collect();
        match parts.as_slice() {
            [
                "typewriter",
                "from",
                "user",
                user,
                "organization",
                organization,
                "members",
                "join_codes",
                "generate",
            ] => Ok(Some(OrganizationActorScope {
                organization: SubjectToken::try_from(*organization)?,
                user: SubjectToken::try_from(*user)?,
            })),
            _ => Ok(None),
        }
    }
}
pub struct OrganizationJoinCodeRevokeRoute;
impl RequestRoute for OrganizationJoinCodeRevokeRoute {
    type Scope = OrganizationActorScope;
    type Request =
        crate::skirout::base::organization::v1::join_codes::RevokeOrganizationJoinCodeRequest;
    type Response =
        crate::skirout::base::organization::v1::join_codes::RevokeOrganizationJoinCodeResponse;
    type Delivery = DomainResponseDelivery;
    fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response> {
        crate::skirout::base::organization::v1::join_codes::revoke_organization_join_code_method()
    }
    fn scope(subject: &str) -> Result<Option<Self::Scope>, crate::otel_wasi::Error> {
        let parts: Vec<_> = subject.split('.').collect();
        match parts.as_slice() {
            [
                "typewriter",
                "from",
                "user",
                user,
                "organization",
                organization,
                "members",
                "join_codes",
                "revoke",
            ] => Ok(Some(OrganizationActorScope {
                organization: SubjectToken::try_from(*organization)?,
                user: SubjectToken::try_from(*user)?,
            })),
            _ => Ok(None),
        }
    }
}
pub struct OrganizationRolesWatchRoute;
impl RequestRoute for OrganizationRolesWatchRoute {
    type Scope = OrganizationActorScope;
    type Request = crate::skirout::base::organization::v1::role::WatchOrganizationRolesRequest;
    type Response = crate::skirout::base::organization::v1::role::WatchOrganizationRolesResponse;
    type Delivery = DomainResponseDelivery;
    fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response> {
        crate::skirout::base::organization::v1::role::watch_organization_roles_method()
    }
    fn scope(subject: &str) -> Result<Option<Self::Scope>, crate::otel_wasi::Error> {
        let parts: Vec<_> = subject.split('.').collect();
        match parts.as_slice() {
            [
                "typewriter",
                "from",
                "user",
                user,
                "organization",
                organization,
                "roles",
                "watch",
            ] => Ok(Some(OrganizationActorScope {
                organization: SubjectToken::try_from(*organization)?,
                user: SubjectToken::try_from(*user)?,
            })),
            _ => Ok(None),
        }
    }
}
pub struct ServiceBindingQueryRoute;
impl RequestRoute for ServiceBindingQueryRoute {
    type Scope = ServiceScope;
    type Request = crate::skirout::base::service::v1::status::QueryServiceBindingRequest;
    type Response = crate::skirout::base::service::v1::status::QueryServiceBindingResponse;
    type Delivery = DomainResponseDelivery;
    fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response> {
        crate::skirout::base::service::v1::status::query_service_binding_method()
    }
    fn scope(subject: &str) -> Result<Option<Self::Scope>, crate::otel_wasi::Error> {
        let parts: Vec<_> = subject.split('.').collect();
        match parts.as_slice() {
            ["typewriter", "from", "service", service, "binding", "query"] => {
                Ok(Some(ServiceScope {
                    service: SubjectToken::try_from(*service)?,
                }))
            }
            ["service", service, "binding", "query"] => Ok(Some(ServiceScope {
                service: SubjectToken::try_from(*service)?,
            })),
            _ => Ok(None),
        }
    }
}
impl OutboundRequestRoute for ServiceBindingQueryRoute {
    fn subject(scope: &Self::Scope) -> String {
        let ServiceScope { service } = scope;
        format!("service.{service}.binding.query")
    }
}
pub struct RegistrationLeaseEnsureRoute;
impl RequestRoute for RegistrationLeaseEnsureRoute {
    type Scope = ServiceScope;
    type Request = crate::skirout::base::service::v1::status::EnsureRegistrationLeaseRequest;
    type Response = crate::skirout::base::service::v1::status::EnsureRegistrationLeaseResponse;
    type Delivery = DomainResponseDelivery;
    fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response> {
        crate::skirout::base::service::v1::status::ensure_registration_lease_method()
    }
    fn scope(subject: &str) -> Result<Option<Self::Scope>, crate::otel_wasi::Error> {
        let parts: Vec<_> = subject.split('.').collect();
        match parts.as_slice() {
            [
                "typewriter",
                "from",
                "service",
                service,
                "registration",
                "ensure",
            ] => Ok(Some(ServiceScope {
                service: SubjectToken::try_from(*service)?,
            })),
            _ => Ok(None),
        }
    }
}
pub struct ServiceMessagingScopeRoute;
impl RequestRoute for ServiceMessagingScopeRoute {
    type Scope = ServiceScope;
    type Request = crate::skirout::base::service::v1::topology::GetServiceMessagingScopeRequest;
    type Response = crate::skirout::base::service::v1::topology::GetServiceMessagingScopeResponse;
    type Delivery = DomainResponseDelivery;
    fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response> {
        crate::skirout::base::service::v1::topology::get_service_messaging_scope_method()
    }
    fn scope(subject: &str) -> Result<Option<Self::Scope>, crate::otel_wasi::Error> {
        let parts: Vec<_> = subject.split('.').collect();
        match parts.as_slice() {
            [
                "typewriter",
                "from",
                "service",
                service,
                "messaging",
                "scope",
            ] => Ok(Some(ServiceScope {
                service: SubjectToken::try_from(*service)?,
            })),
            ["service", service, "messaging", "scope"] => Ok(Some(ServiceScope {
                service: SubjectToken::try_from(*service)?,
            })),
            _ => Ok(None),
        }
    }
}
impl OutboundRequestRoute for ServiceMessagingScopeRoute {
    fn subject(scope: &Self::Scope) -> String {
        let ServiceScope { service } = scope;
        format!("service.{service}.messaging.scope")
    }
}
pub struct ServiceBindRoute;
impl RequestRoute for ServiceBindRoute {
    type Scope = OrganizationActorScope;
    type Request = crate::skirout::base::service::v1::registration::BindServiceRequest;
    type Response = crate::skirout::base::service::v1::registration::BindServiceResponse;
    type Delivery = DomainResponseDelivery;
    fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response> {
        crate::skirout::base::service::v1::registration::bind_service_method()
    }
    fn scope(subject: &str) -> Result<Option<Self::Scope>, crate::otel_wasi::Error> {
        let parts: Vec<_> = subject.split('.').collect();
        match parts.as_slice() {
            [
                "typewriter",
                "from",
                "user",
                user,
                "organization",
                organization,
                "services",
                "bind",
            ] => Ok(Some(OrganizationActorScope {
                organization: SubjectToken::try_from(*organization)?,
                user: SubjectToken::try_from(*user)?,
            })),
            _ => Ok(None),
        }
    }
}
pub struct OrganizationServicesWatchRoute;
impl RequestRoute for OrganizationServicesWatchRoute {
    type Scope = OrganizationActorScope;
    type Request =
        crate::skirout::base::service::v1::organization::WatchOrganizationServicesRequest;
    type Response =
        crate::skirout::base::service::v1::organization::WatchOrganizationServicesResponse;
    type Delivery = DomainResponseDelivery;
    fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response> {
        crate::skirout::base::service::v1::organization::watch_organization_services_method()
    }
    fn scope(subject: &str) -> Result<Option<Self::Scope>, crate::otel_wasi::Error> {
        let parts: Vec<_> = subject.split('.').collect();
        match parts.as_slice() {
            [
                "typewriter",
                "from",
                "user",
                user,
                "organization",
                organization,
                "services",
                "watch",
            ] => Ok(Some(OrganizationActorScope {
                organization: SubjectToken::try_from(*organization)?,
                user: SubjectToken::try_from(*user)?,
            })),
            _ => Ok(None),
        }
    }
}
pub struct OrganizationServiceUpdateRoute;
impl RequestRoute for OrganizationServiceUpdateRoute {
    type Scope = OrganizationActorScope;
    type Request =
        crate::skirout::base::service::v1::organization::UpdateOrganizationServiceRequest;
    type Response =
        crate::skirout::base::service::v1::organization::UpdateOrganizationServiceResponse;
    type Delivery = DomainResponseDelivery;
    fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response> {
        crate::skirout::base::service::v1::organization::update_organization_service_method()
    }
    fn scope(subject: &str) -> Result<Option<Self::Scope>, crate::otel_wasi::Error> {
        let parts: Vec<_> = subject.split('.').collect();
        match parts.as_slice() {
            [
                "typewriter",
                "from",
                "user",
                user,
                "organization",
                organization,
                "services",
                "update",
            ] => Ok(Some(OrganizationActorScope {
                organization: SubjectToken::try_from(*organization)?,
                user: SubjectToken::try_from(*user)?,
            })),
            _ => Ok(None),
        }
    }
}
pub struct ServiceUnbindRoute;
impl RequestRoute for ServiceUnbindRoute {
    type Scope = OrganizationActorScope;
    type Request = crate::skirout::base::service::v1::registration::UnbindServiceRequest;
    type Response = crate::skirout::base::service::v1::registration::UnbindServiceResponse;
    type Delivery = DomainResponseDelivery;
    fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response> {
        crate::skirout::base::service::v1::registration::unbind_service_method()
    }
    fn scope(subject: &str) -> Result<Option<Self::Scope>, crate::otel_wasi::Error> {
        let parts: Vec<_> = subject.split('.').collect();
        match parts.as_slice() {
            [
                "typewriter",
                "from",
                "user",
                user,
                "organization",
                organization,
                "services",
                "unbind",
            ] => Ok(Some(OrganizationActorScope {
                organization: SubjectToken::try_from(*organization)?,
                user: SubjectToken::try_from(*user)?,
            })),
            _ => Ok(None),
        }
    }
}
pub struct ServiceTopologyConfigureRoute;
impl RequestRoute for ServiceTopologyConfigureRoute {
    type Scope = OrganizationActorScope;
    type Request = crate::skirout::base::service::v1::topology::ConfigureServiceHostRequest;
    type Response = crate::skirout::base::service::v1::topology::ConfigureServiceHostResponse;
    type Delivery = DomainResponseDelivery;
    fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response> {
        crate::skirout::base::service::v1::topology::configure_service_host_method()
    }
    fn scope(subject: &str) -> Result<Option<Self::Scope>, crate::otel_wasi::Error> {
        let parts: Vec<_> = subject.split('.').collect();
        match parts.as_slice() {
            [
                "typewriter",
                "from",
                "user",
                user,
                "organization",
                organization,
                "topology",
                "configure",
            ] => Ok(Some(OrganizationActorScope {
                organization: SubjectToken::try_from(*organization)?,
                user: SubjectToken::try_from(*user)?,
            })),
            _ => Ok(None),
        }
    }
}
pub struct OrganizationTopologyWatchRoute;
impl RequestRoute for OrganizationTopologyWatchRoute {
    type Scope = OrganizationActorScope;
    type Request = crate::skirout::base::service::v1::topology::WatchOrganizationTopologyRequest;
    type Response = crate::skirout::base::service::v1::topology::WatchOrganizationTopologyResponse;
    type Delivery = DomainResponseDelivery;
    fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response> {
        crate::skirout::base::service::v1::topology::watch_organization_topology_method()
    }
    fn scope(subject: &str) -> Result<Option<Self::Scope>, crate::otel_wasi::Error> {
        let parts: Vec<_> = subject.split('.').collect();
        match parts.as_slice() {
            [
                "typewriter",
                "from",
                "user",
                user,
                "organization",
                organization,
                "topology",
                "watch",
            ] => Ok(Some(OrganizationActorScope {
                organization: SubjectToken::try_from(*organization)?,
                user: SubjectToken::try_from(*user)?,
            })),
            _ => Ok(None),
        }
    }
}
pub struct ServiceHostRegisterRoute;
impl RequestRoute for ServiceHostRegisterRoute {
    type Scope = ServiceScope;
    type Request = crate::skirout::base::service::v1::topology::RegisterServiceHostRequest;
    type Response = crate::skirout::base::service::v1::topology::RegisterServiceHostResponse;
    type Delivery = DomainResponseDelivery;
    fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response> {
        crate::skirout::base::service::v1::topology::register_service_host_method()
    }
    fn scope(subject: &str) -> Result<Option<Self::Scope>, crate::otel_wasi::Error> {
        let parts: Vec<_> = subject.split('.').collect();
        match parts.as_slice() {
            [
                "typewriter",
                "from",
                "service",
                service,
                "execution",
                "register",
            ] => Ok(Some(ServiceScope {
                service: SubjectToken::try_from(*service)?,
            })),
            _ => Ok(None),
        }
    }
}
pub struct HostExecutionWatchRoute;
impl RequestRoute for HostExecutionWatchRoute {
    type Scope = ServiceScope;
    type Request = crate::skirout::base::service::v1::topology::WatchHostExecutionRequest;
    type Response = crate::skirout::base::service::v1::topology::WatchHostExecutionResponse;
    type Delivery = DomainResponseDelivery;
    fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response> {
        crate::skirout::base::service::v1::topology::watch_host_execution_method()
    }
    fn scope(subject: &str) -> Result<Option<Self::Scope>, crate::otel_wasi::Error> {
        let parts: Vec<_> = subject.split('.').collect();
        match parts.as_slice() {
            [
                "typewriter",
                "from",
                "service",
                service,
                "execution",
                "watch",
            ] => Ok(Some(ServiceScope {
                service: SubjectToken::try_from(*service)?,
            })),
            _ => Ok(None),
        }
    }
}
pub struct HostExecutionReportRoute;
impl RequestRoute for HostExecutionReportRoute {
    type Scope = ServiceScope;
    type Request = crate::skirout::base::service::v1::topology::ReportHostExecutionRequest;
    type Response = crate::skirout::base::service::v1::topology::ReportHostExecutionResponse;
    type Delivery = DomainResponseDelivery;
    fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response> {
        crate::skirout::base::service::v1::topology::report_host_execution_method()
    }
    fn scope(subject: &str) -> Result<Option<Self::Scope>, crate::otel_wasi::Error> {
        let parts: Vec<_> = subject.split('.').collect();
        match parts.as_slice() {
            [
                "typewriter",
                "from",
                "service",
                service,
                "execution",
                "report",
            ] => Ok(Some(ServiceScope {
                service: SubjectToken::try_from(*service)?,
            })),
            _ => Ok(None),
        }
    }
}
pub struct PanelPermissionResolveRoute;
impl RequestRoute for PanelPermissionResolveRoute {
    type Scope = InternalComponentScope;
    type Request = crate::skirout::base::access::v1::permission::GetEntityPermissionRequest;
    type Response = crate::skirout::base::access::v1::permission::GetEntityPermissionResponse;
    type Delivery = PlainResponseDelivery;
    fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response> {
        crate::skirout::base::access::v1::permission::get_entity_permission_method()
    }
    fn scope(subject: &str) -> Result<Option<Self::Scope>, crate::otel_wasi::Error> {
        let parts: Vec<_> = subject.split('.').collect();
        match parts.as_slice() {
            ["auth", "permissions", "typewriter-panel"] => Ok(Some(InternalComponentScope {})),
            _ => Ok(None),
        }
    }
}
impl OutboundRequestRoute for PanelPermissionResolveRoute {
    fn subject(scope: &Self::Scope) -> String {
        let _ = scope;
        format!("auth.permissions.typewriter-panel")
    }
}
pub struct ServicesPermissionResolveRoute;
impl RequestRoute for ServicesPermissionResolveRoute {
    type Scope = InternalComponentScope;
    type Request = crate::skirout::base::access::v1::permission::GetEntityPermissionRequest;
    type Response = crate::skirout::base::access::v1::permission::GetEntityPermissionResponse;
    type Delivery = PlainResponseDelivery;
    fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response> {
        crate::skirout::base::access::v1::permission::get_entity_permission_method()
    }
    fn scope(subject: &str) -> Result<Option<Self::Scope>, crate::otel_wasi::Error> {
        let parts: Vec<_> = subject.split('.').collect();
        match parts.as_slice() {
            ["auth", "permissions", "typewriter-services"] => Ok(Some(InternalComponentScope {})),
            _ => Ok(None),
        }
    }
}
impl OutboundRequestRoute for ServicesPermissionResolveRoute {
    fn subject(scope: &Self::Scope) -> String {
        let _ = scope;
        format!("auth.permissions.typewriter-services")
    }
}
pub struct ServiceHeartbeatRoute;
impl EventRoute for ServiceHeartbeatRoute {
    type Scope = ServiceScope;
    type Event = crate::skirout::base::service::v1::lifecycle::ServiceHeartbeatNotification;
    fn serializer() -> crate::skir_client::Serializer<Self::Event> {
        <Self::Event>::serializer()
    }
    fn scope(subject: &str) -> Result<Option<Self::Scope>, crate::otel_wasi::Error> {
        let parts: Vec<_> = subject.split('.').collect();
        match parts.as_slice() {
            ["typewriter", "from", "service", service, "heartbeat"] => Ok(Some(ServiceScope {
                service: SubjectToken::try_from(*service)?,
            })),
            _ => Ok(None),
        }
    }
}
pub struct ServiceShutdownRoute;
impl EventRoute for ServiceShutdownRoute {
    type Scope = ServiceScope;
    type Event = crate::skirout::base::service::v1::lifecycle::ServiceShutdownNotification;
    fn serializer() -> crate::skir_client::Serializer<Self::Event> {
        <Self::Event>::serializer()
    }
    fn scope(subject: &str) -> Result<Option<Self::Scope>, crate::otel_wasi::Error> {
        let parts: Vec<_> = subject.split('.').collect();
        match parts.as_slice() {
            ["typewriter", "from", "service", service, "shutdown"] => Ok(Some(ServiceScope {
                service: SubjectToken::try_from(*service)?,
            })),
            _ => Ok(None),
        }
    }
}
impl OutboundEventRoute for UserOrganizationsWatchRoute {
    type Scope = UserScope;
    type Event = crate::skirout::base::organization::v1::organization::UserOrganizationsChanged;
    fn serializer() -> crate::skir_client::Serializer<Self::Event> {
        <Self::Event>::serializer()
    }
    fn subject(scope: &Self::Scope) -> String {
        let UserScope { user } = scope;
        format!("typewriter.to.user.{user}.organizations.changed")
    }
}
impl UserOrganizationsWatchRoute {
    pub fn delivery(scope: &UserScope) -> EventDelivery<Self> {
        EventDelivery::new(scope)
    }
}
impl PersistentEventRoute for UserOrganizationsWatchRoute {
    fn stream() -> &'static str {
        "TYPEWRITER_MEMBERSHIP"
    }
}
impl OutboundEventRoute for UserJoinRequestsWatchRoute {
    type Scope = UserScope;
    type Event = crate::skirout::base::organization::v1::join_request::UserJoinRequestsChanged;
    fn serializer() -> crate::skir_client::Serializer<Self::Event> {
        <Self::Event>::serializer()
    }
    fn subject(scope: &Self::Scope) -> String {
        let UserScope { user } = scope;
        format!("typewriter.to.user.{user}.join_requests.changed")
    }
}
impl UserJoinRequestsWatchRoute {
    pub fn delivery(scope: &UserScope) -> EventDelivery<Self> {
        EventDelivery::new(scope)
    }
}
impl PersistentEventRoute for UserJoinRequestsWatchRoute {
    fn stream() -> &'static str {
        "TYPEWRITER_MEMBERSHIP"
    }
}
impl OutboundEventRoute for OrganizationMembersWatchRoute {
    type Scope = OrganizationScope;
    type Event = crate::skirout::base::organization::v1::member::OrganizationMembersChanged;
    fn serializer() -> crate::skir_client::Serializer<Self::Event> {
        <Self::Event>::serializer()
    }
    fn subject(scope: &Self::Scope) -> String {
        let OrganizationScope { organization } = scope;
        format!("typewriter.to.organization.{organization}.members.changed")
    }
}
impl OrganizationMembersWatchRoute {
    pub fn delivery(scope: &OrganizationScope) -> EventDelivery<Self> {
        EventDelivery::new(scope)
    }
}
impl PersistentEventRoute for OrganizationMembersWatchRoute {
    fn stream() -> &'static str {
        "TYPEWRITER_MEMBERSHIP"
    }
}
impl OutboundEventRoute for OrganizationJoinRequestsWatchRoute {
    type Scope = OrganizationScope;
    type Event =
        crate::skirout::base::organization::v1::join_request::OrganizationJoinRequestsChanged;
    fn serializer() -> crate::skir_client::Serializer<Self::Event> {
        <Self::Event>::serializer()
    }
    fn subject(scope: &Self::Scope) -> String {
        let OrganizationScope { organization } = scope;
        format!("typewriter.to.organization.{organization}.join_requests.changed")
    }
}
impl OrganizationJoinRequestsWatchRoute {
    pub fn delivery(scope: &OrganizationScope) -> EventDelivery<Self> {
        EventDelivery::new(scope)
    }
}
impl PersistentEventRoute for OrganizationJoinRequestsWatchRoute {
    fn stream() -> &'static str {
        "TYPEWRITER_MEMBERSHIP"
    }
}
impl OutboundEventRoute for OrganizationJoinCodesWatchRoute {
    type Scope = OrganizationScope;
    type Event = crate::skirout::base::organization::v1::join_codes::OrganizationJoinCodesChanged;
    fn serializer() -> crate::skir_client::Serializer<Self::Event> {
        <Self::Event>::serializer()
    }
    fn subject(scope: &Self::Scope) -> String {
        let OrganizationScope { organization } = scope;
        format!("typewriter.to.organization.{organization}.join_codes.changed")
    }
}
impl OrganizationJoinCodesWatchRoute {
    pub fn delivery(scope: &OrganizationScope) -> EventDelivery<Self> {
        EventDelivery::new(scope)
    }
}
impl PersistentEventRoute for OrganizationJoinCodesWatchRoute {
    fn stream() -> &'static str {
        "TYPEWRITER_MEMBERSHIP"
    }
}
impl OutboundEventRoute for ServiceBindingQueryRoute {
    type Scope = ServiceScope;
    type Event = crate::skirout::base::service::v1::registration::ServiceBoundNotification;
    fn serializer() -> crate::skir_client::Serializer<Self::Event> {
        <Self::Event>::serializer()
    }
    fn subject(scope: &Self::Scope) -> String {
        let ServiceScope { service } = scope;
        format!("typewriter.to.service.{service}.registration.bound")
    }
}
impl ServiceBindingQueryRoute {
    pub fn delivery(scope: &ServiceScope) -> EventDelivery<Self> {
        EventDelivery::new(scope)
    }
}
impl TransientEventRoute for ServiceBindingQueryRoute {}
impl OutboundEventRoute for OrganizationServicesWatchRoute {
    type Scope = OrganizationScope;
    type Event = crate::skirout::base::service::v1::organization::OrganizationServicesChanged;
    fn serializer() -> crate::skir_client::Serializer<Self::Event> {
        <Self::Event>::serializer()
    }
    fn subject(scope: &Self::Scope) -> String {
        let OrganizationScope { organization } = scope;
        format!("typewriter.to.organization.{organization}.services.watch")
    }
}
impl OrganizationServicesWatchRoute {
    pub fn delivery(scope: &OrganizationScope) -> EventDelivery<Self> {
        EventDelivery::new(scope)
    }
}
impl TransientEventRoute for OrganizationServicesWatchRoute {}
impl OutboundEventRoute for OrganizationTopologyWatchRoute {
    type Scope = OrganizationScope;
    type Event = crate::skirout::base::service::v1::topology::OrganizationTopologyChanged;
    fn serializer() -> crate::skir_client::Serializer<Self::Event> {
        <Self::Event>::serializer()
    }
    fn subject(scope: &Self::Scope) -> String {
        let OrganizationScope { organization } = scope;
        format!("typewriter.to.organization.{organization}.topology.watch")
    }
}
impl OrganizationTopologyWatchRoute {
    pub fn delivery(scope: &OrganizationScope) -> EventDelivery<Self> {
        EventDelivery::new(scope)
    }
}
impl TransientEventRoute for OrganizationTopologyWatchRoute {}
impl OutboundEventRoute for HostExecutionWatchRoute {
    type Scope = ServiceScope;
    type Event = crate::skirout::base::service::v1::topology::WatchHostExecutionResponse;
    fn serializer() -> crate::skir_client::Serializer<Self::Event> {
        <Self::Event>::serializer()
    }
    fn subject(scope: &Self::Scope) -> String {
        let ServiceScope { service } = scope;
        format!("typewriter.to.service.{service}.execution.watch")
    }
}
impl HostExecutionWatchRoute {
    pub fn delivery(scope: &ServiceScope) -> EventDelivery<Self> {
        EventDelivery::new(scope)
    }
}
impl TransientEventRoute for HostExecutionWatchRoute {}
