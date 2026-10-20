//! Generated transport routes. Do not edit; regenerate with `bun run generate:protocol`.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum RealmRole {
    RealmCoordinator,
    RealmParticipant,
}
impl crate::transport::RealmScope {
    /// Inserts every subject the role may publish to or subscribe to within this scope.
    pub fn grant(&self, role: RealmRole, grants: &mut crate::transport::GrantSet) {
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
impl crate::transport::ServiceScope {
    /// Inserts every subject the role may publish to or subscribe to within this scope.
    pub fn grant(&self, role: ServiceRole, grants: &mut crate::transport::GrantSet) {
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
impl crate::transport::OrganizationActorScope {
    /// Inserts every subject the role may publish to or subscribe to within this scope.
    pub fn grant(
        &self,
        role: OrganizationActorRole,
        session: &crate::transport::ConnectionSession,
        grants: &mut crate::transport::GrantSet,
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
impl crate::transport::UserScope {
    /// Inserts every subject the role may publish to or subscribe to within this scope.
    pub fn grant(
        &self,
        role: UserRole,
        session: &crate::transport::ConnectionSession,
        grants: &mut crate::transport::GrantSet,
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
    actor: &crate::transport::SubjectToken,
    organization: Option<&crate::transport::SubjectToken>,
    session: &crate::transport::ConnectionSession,
    projection: &str,
) -> String {
    use base64::Engine as _;
    let identity = serde_json::json!([
        actor.as_str(),
        organization.map(crate::transport::SubjectToken::as_str),
        session.as_str(),
        projection
    ]);
    format!(
        "TW_{}",
        base64::engine::general_purpose::URL_SAFE_NO_PAD.encode(identity.to_string())
    )
}
pub struct UserOrganizationCreateRoute;
impl crate::transport::RequestRoute for UserOrganizationCreateRoute {
    type Scope = crate::transport::UserScope;
    type Request = crate::skirout::base::organization::v1::organization::CreateOrganizationRequest;
    type Response =
        crate::skirout::base::organization::v1::organization::CreateOrganizationResponse;
    type Delivery = crate::transport::DomainResponseDelivery;
    fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response> {
        crate::skirout::base::organization::v1::organization::create_organization_method()
    }
}
pub struct UserOrganizationsWatchRoute;
impl crate::transport::RequestRoute for UserOrganizationsWatchRoute {
    type Scope = crate::transport::UserScope;
    type Request = crate::skirout::base::organization::v1::user::WatchUserOrganizationsRequest;
    type Response = crate::skirout::base::organization::v1::user::WatchUserOrganizationsResponse;
    type Delivery = crate::transport::DomainResponseDelivery;
    fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response> {
        crate::skirout::base::organization::v1::user::watch_user_organizations_method()
    }
}
pub struct UserJoinRequestsWatchRoute;
impl crate::transport::RequestRoute for UserJoinRequestsWatchRoute {
    type Scope = crate::transport::UserScope;
    type Request = crate::skirout::base::organization::v1::user::WatchUserJoinRequestsRequest;
    type Response = crate::skirout::base::organization::v1::user::WatchUserJoinRequestsResponse;
    type Delivery = crate::transport::DomainResponseDelivery;
    fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response> {
        crate::skirout::base::organization::v1::user::watch_user_join_requests_method()
    }
}
pub struct UserJoinRequestSubmitRoute;
impl crate::transport::RequestRoute for UserJoinRequestSubmitRoute {
    type Scope = crate::transport::UserScope;
    type Request = crate::skirout::base::organization::v1::user::SubmitUserJoinRequestRequest;
    type Response = crate::skirout::base::organization::v1::user::SubmitUserJoinRequestResponse;
    type Delivery = crate::transport::DomainResponseDelivery;
    fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response> {
        crate::skirout::base::organization::v1::user::submit_user_join_request_method()
    }
}
pub struct UserJoinRequestCancelRoute;
impl crate::transport::RequestRoute for UserJoinRequestCancelRoute {
    type Scope = crate::transport::UserScope;
    type Request = crate::skirout::base::organization::v1::user::CancelUserJoinRequestRequest;
    type Response = crate::skirout::base::organization::v1::user::CancelUserJoinRequestResponse;
    type Delivery = crate::transport::DomainResponseDelivery;
    fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response> {
        crate::skirout::base::organization::v1::user::cancel_user_join_request_method()
    }
}
pub struct OrganizationMembersWatchRoute;
impl crate::transport::RequestRoute for OrganizationMembersWatchRoute {
    type Scope = crate::transport::OrganizationActorScope;
    type Request = crate::skirout::base::organization::v1::member::WatchOrganizationMembersRequest;
    type Response =
        crate::skirout::base::organization::v1::member::WatchOrganizationMembersResponse;
    type Delivery = crate::transport::DomainResponseDelivery;
    fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response> {
        crate::skirout::base::organization::v1::member::watch_organization_members_method()
    }
}
pub struct OrganizationMembersUpdateRoute;
impl crate::transport::RequestRoute for OrganizationMembersUpdateRoute {
    type Scope = crate::transport::OrganizationActorScope;
    type Request =
        crate::skirout::base::organization::v1::member::UpdateOrganizationMemberRolesRequest;
    type Response =
        crate::skirout::base::organization::v1::member::UpdateOrganizationMemberRolesResponse;
    type Delivery = crate::transport::DomainResponseDelivery;
    fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response> {
        crate::skirout::base::organization::v1::member::update_organization_member_roles_method()
    }
}
pub struct OrganizationMemberRemoveRoute;
impl crate::transport::RequestRoute for OrganizationMemberRemoveRoute {
    type Scope = crate::transport::OrganizationActorScope;
    type Request = crate::skirout::base::organization::v1::member::RemoveOrganizationMemberRequest;
    type Response =
        crate::skirout::base::organization::v1::member::RemoveOrganizationMemberResponse;
    type Delivery = crate::transport::DomainResponseDelivery;
    fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response> {
        crate::skirout::base::organization::v1::member::remove_organization_member_method()
    }
}
pub struct OrganizationJoinRequestsWatchRoute;
impl crate::transport::RequestRoute for OrganizationJoinRequestsWatchRoute {
    type Scope = crate::transport::OrganizationActorScope;
    type Request =
        crate::skirout::base::organization::v1::join_request::WatchOrganizationJoinRequestsRequest;
    type Response =
        crate::skirout::base::organization::v1::join_request::WatchOrganizationJoinRequestsResponse;
    type Delivery = crate::transport::DomainResponseDelivery;
    fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response> {
        crate::skirout::base::organization::v1::join_request::watch_organization_join_requests_method()
    }
}
pub struct OrganizationJoinRequestsApproveRoute;
impl crate::transport::RequestRoute for OrganizationJoinRequestsApproveRoute {
    type Scope = crate::transport::OrganizationActorScope;
    type Request = crate::skirout::base::organization::v1::join_request::ApproveOrganizationJoinRequestsRequest;
    type Response = crate::skirout::base::organization::v1::join_request::ApproveOrganizationJoinRequestsResponse;
    type Delivery = crate::transport::DomainResponseDelivery;
    fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response> {
        crate::skirout::base::organization::v1::join_request::approve_organization_join_requests_method()
    }
}
pub struct OrganizationJoinRequestDeclineRoute;
impl crate::transport::RequestRoute for OrganizationJoinRequestDeclineRoute {
    type Scope = crate::transport::OrganizationActorScope;
    type Request =
        crate::skirout::base::organization::v1::join_request::DeclineOrganizationJoinRequestRequest;
    type Response = crate::skirout::base::organization::v1::join_request::DeclineOrganizationJoinRequestResponse;
    type Delivery = crate::transport::DomainResponseDelivery;
    fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response> {
        crate::skirout::base::organization::v1::join_request::decline_organization_join_request_method()
    }
}
pub struct OrganizationJoinCodesWatchRoute;
impl crate::transport::RequestRoute for OrganizationJoinCodesWatchRoute {
    type Scope = crate::transport::OrganizationActorScope;
    type Request =
        crate::skirout::base::organization::v1::join_codes::WatchOrganizationJoinCodesRequest;
    type Response =
        crate::skirout::base::organization::v1::join_codes::WatchOrganizationJoinCodesResponse;
    type Delivery = crate::transport::DomainResponseDelivery;
    fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response> {
        crate::skirout::base::organization::v1::join_codes::watch_organization_join_codes_method()
    }
}
pub struct OrganizationJoinCodeGenerateRoute;
impl crate::transport::RequestRoute for OrganizationJoinCodeGenerateRoute {
    type Scope = crate::transport::OrganizationActorScope;
    type Request =
        crate::skirout::base::organization::v1::join_codes::GenerateOrganizationJoinCodeRequest;
    type Response =
        crate::skirout::base::organization::v1::join_codes::GenerateOrganizationJoinCodeResponse;
    type Delivery = crate::transport::DomainResponseDelivery;
    fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response> {
        crate::skirout::base::organization::v1::join_codes::generate_organization_join_code_method()
    }
}
pub struct OrganizationJoinCodeRevokeRoute;
impl crate::transport::RequestRoute for OrganizationJoinCodeRevokeRoute {
    type Scope = crate::transport::OrganizationActorScope;
    type Request =
        crate::skirout::base::organization::v1::join_codes::RevokeOrganizationJoinCodeRequest;
    type Response =
        crate::skirout::base::organization::v1::join_codes::RevokeOrganizationJoinCodeResponse;
    type Delivery = crate::transport::DomainResponseDelivery;
    fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response> {
        crate::skirout::base::organization::v1::join_codes::revoke_organization_join_code_method()
    }
}
pub struct OrganizationRolesWatchRoute;
impl crate::transport::RequestRoute for OrganizationRolesWatchRoute {
    type Scope = crate::transport::OrganizationActorScope;
    type Request = crate::skirout::base::organization::v1::role::WatchOrganizationRolesRequest;
    type Response = crate::skirout::base::organization::v1::role::WatchOrganizationRolesResponse;
    type Delivery = crate::transport::DomainResponseDelivery;
    fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response> {
        crate::skirout::base::organization::v1::role::watch_organization_roles_method()
    }
}
pub struct ServiceBindingQueryRoute;
impl crate::transport::RequestRoute for ServiceBindingQueryRoute {
    type Scope = crate::transport::ServiceScope;
    type Request = crate::skirout::base::service::v1::status::QueryServiceBindingRequest;
    type Response = crate::skirout::base::service::v1::status::QueryServiceBindingResponse;
    type Delivery = crate::transport::DomainResponseDelivery;
    fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response> {
        crate::skirout::base::service::v1::status::query_service_binding_method()
    }
}
impl crate::transport::OutboundRequestRoute for ServiceBindingQueryRoute {
    fn subject(scope: &Self::Scope) -> String {
        let crate::transport::ServiceScope { service } = scope;
        format!("service.{service}.binding.query")
    }
}
pub struct RegistrationLeaseEnsureRoute;
impl crate::transport::RequestRoute for RegistrationLeaseEnsureRoute {
    type Scope = crate::transport::ServiceScope;
    type Request = crate::skirout::base::service::v1::status::EnsureRegistrationLeaseRequest;
    type Response = crate::skirout::base::service::v1::status::EnsureRegistrationLeaseResponse;
    type Delivery = crate::transport::DomainResponseDelivery;
    fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response> {
        crate::skirout::base::service::v1::status::ensure_registration_lease_method()
    }
}
pub struct ServiceMessagingScopeRoute;
impl crate::transport::RequestRoute for ServiceMessagingScopeRoute {
    type Scope = crate::transport::ServiceScope;
    type Request = crate::skirout::base::service::v1::topology::GetServiceMessagingScopeRequest;
    type Response = crate::skirout::base::service::v1::topology::GetServiceMessagingScopeResponse;
    type Delivery = crate::transport::DomainResponseDelivery;
    fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response> {
        crate::skirout::base::service::v1::topology::get_service_messaging_scope_method()
    }
}
impl crate::transport::OutboundRequestRoute for ServiceMessagingScopeRoute {
    fn subject(scope: &Self::Scope) -> String {
        let crate::transport::ServiceScope { service } = scope;
        format!("service.{service}.messaging.scope")
    }
}
pub struct ServiceBindRoute;
impl crate::transport::RequestRoute for ServiceBindRoute {
    type Scope = crate::transport::OrganizationActorScope;
    type Request = crate::skirout::base::service::v1::registration::BindServiceRequest;
    type Response = crate::skirout::base::service::v1::registration::BindServiceResponse;
    type Delivery = crate::transport::DomainResponseDelivery;
    fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response> {
        crate::skirout::base::service::v1::registration::bind_service_method()
    }
}
pub struct OrganizationServicesWatchRoute;
impl crate::transport::RequestRoute for OrganizationServicesWatchRoute {
    type Scope = crate::transport::OrganizationActorScope;
    type Request =
        crate::skirout::base::service::v1::organization::WatchOrganizationServicesRequest;
    type Response =
        crate::skirout::base::service::v1::organization::WatchOrganizationServicesResponse;
    type Delivery = crate::transport::DomainResponseDelivery;
    fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response> {
        crate::skirout::base::service::v1::organization::watch_organization_services_method()
    }
}
pub struct OrganizationServiceUpdateRoute;
impl crate::transport::RequestRoute for OrganizationServiceUpdateRoute {
    type Scope = crate::transport::OrganizationActorScope;
    type Request =
        crate::skirout::base::service::v1::organization::UpdateOrganizationServiceRequest;
    type Response =
        crate::skirout::base::service::v1::organization::UpdateOrganizationServiceResponse;
    type Delivery = crate::transport::DomainResponseDelivery;
    fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response> {
        crate::skirout::base::service::v1::organization::update_organization_service_method()
    }
}
pub struct ServiceUnbindRoute;
impl crate::transport::RequestRoute for ServiceUnbindRoute {
    type Scope = crate::transport::OrganizationActorScope;
    type Request = crate::skirout::base::service::v1::registration::UnbindServiceRequest;
    type Response = crate::skirout::base::service::v1::registration::UnbindServiceResponse;
    type Delivery = crate::transport::DomainResponseDelivery;
    fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response> {
        crate::skirout::base::service::v1::registration::unbind_service_method()
    }
}
pub struct ServiceTopologyConfigureRoute;
impl crate::transport::RequestRoute for ServiceTopologyConfigureRoute {
    type Scope = crate::transport::OrganizationActorScope;
    type Request = crate::skirout::base::service::v1::topology::ConfigureServiceHostRequest;
    type Response = crate::skirout::base::service::v1::topology::ConfigureServiceHostResponse;
    type Delivery = crate::transport::DomainResponseDelivery;
    fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response> {
        crate::skirout::base::service::v1::topology::configure_service_host_method()
    }
}
pub struct OrganizationTopologyWatchRoute;
impl crate::transport::RequestRoute for OrganizationTopologyWatchRoute {
    type Scope = crate::transport::OrganizationActorScope;
    type Request = crate::skirout::base::service::v1::topology::WatchOrganizationTopologyRequest;
    type Response = crate::skirout::base::service::v1::topology::WatchOrganizationTopologyResponse;
    type Delivery = crate::transport::DomainResponseDelivery;
    fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response> {
        crate::skirout::base::service::v1::topology::watch_organization_topology_method()
    }
}
pub struct ServiceHostRegisterRoute;
impl crate::transport::RequestRoute for ServiceHostRegisterRoute {
    type Scope = crate::transport::ServiceScope;
    type Request = crate::skirout::base::service::v1::topology::RegisterServiceHostRequest;
    type Response = crate::skirout::base::service::v1::topology::RegisterServiceHostResponse;
    type Delivery = crate::transport::DomainResponseDelivery;
    fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response> {
        crate::skirout::base::service::v1::topology::register_service_host_method()
    }
}
pub struct HostExecutionWatchRoute;
impl crate::transport::RequestRoute for HostExecutionWatchRoute {
    type Scope = crate::transport::ServiceScope;
    type Request = crate::skirout::base::service::v1::topology::WatchHostExecutionRequest;
    type Response = crate::skirout::base::service::v1::topology::WatchHostExecutionResponse;
    type Delivery = crate::transport::DomainResponseDelivery;
    fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response> {
        crate::skirout::base::service::v1::topology::watch_host_execution_method()
    }
}
pub struct HostExecutionReportRoute;
impl crate::transport::RequestRoute for HostExecutionReportRoute {
    type Scope = crate::transport::ServiceScope;
    type Request = crate::skirout::base::service::v1::topology::ReportHostExecutionRequest;
    type Response = crate::skirout::base::service::v1::topology::ReportHostExecutionResponse;
    type Delivery = crate::transport::DomainResponseDelivery;
    fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response> {
        crate::skirout::base::service::v1::topology::report_host_execution_method()
    }
}
pub struct PanelPermissionResolveRoute;
impl crate::transport::RequestRoute for PanelPermissionResolveRoute {
    type Scope = crate::transport::InternalComponentScope;
    type Request = crate::skirout::base::access::v1::permission::GetEntityPermissionRequest;
    type Response = crate::skirout::base::access::v1::permission::GetEntityPermissionResponse;
    type Delivery = crate::transport::PlainResponseDelivery;
    fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response> {
        crate::skirout::base::access::v1::permission::get_entity_permission_method()
    }
}
impl crate::transport::OutboundRequestRoute for PanelPermissionResolveRoute {
    fn subject(_scope: &Self::Scope) -> String {
        String::from("auth.permissions.typewriter-panel")
    }
}
pub struct ServicesPermissionResolveRoute;
impl crate::transport::RequestRoute for ServicesPermissionResolveRoute {
    type Scope = crate::transport::InternalComponentScope;
    type Request = crate::skirout::base::access::v1::permission::GetEntityPermissionRequest;
    type Response = crate::skirout::base::access::v1::permission::GetEntityPermissionResponse;
    type Delivery = crate::transport::PlainResponseDelivery;
    fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response> {
        crate::skirout::base::access::v1::permission::get_entity_permission_method()
    }
}
impl crate::transport::OutboundRequestRoute for ServicesPermissionResolveRoute {
    fn subject(_scope: &Self::Scope) -> String {
        String::from("auth.permissions.typewriter-services")
    }
}
pub struct ServiceHeartbeatRoute;
impl crate::transport::EventRoute for ServiceHeartbeatRoute {
    type Scope = crate::transport::ServiceScope;
    type Event = crate::skirout::base::service::v1::lifecycle::ServiceHeartbeatNotification;
    fn serializer() -> crate::skir_client::Serializer<Self::Event> {
        <Self::Event>::serializer()
    }
}
pub struct ServiceShutdownRoute;
impl crate::transport::EventRoute for ServiceShutdownRoute {
    type Scope = crate::transport::ServiceScope;
    type Event = crate::skirout::base::service::v1::lifecycle::ServiceShutdownNotification;
    fn serializer() -> crate::skir_client::Serializer<Self::Event> {
        <Self::Event>::serializer()
    }
}
impl crate::transport::OutboundEventRoute for UserOrganizationsWatchRoute {
    type Scope = crate::transport::UserScope;
    type Event = crate::skirout::base::organization::v1::organization::UserOrganizationsChanged;
    fn serializer() -> crate::skir_client::Serializer<Self::Event> {
        <Self::Event>::serializer()
    }
    fn subject(scope: &Self::Scope) -> String {
        let crate::transport::UserScope { user } = scope;
        format!("typewriter.to.user.{user}.organizations.changed")
    }
}
impl UserOrganizationsWatchRoute {
    pub fn delivery(scope: &crate::transport::UserScope) -> crate::transport::EventDelivery<Self> {
        crate::transport::EventDelivery::new(scope)
    }
}
impl crate::transport::PersistentEventRoute for UserOrganizationsWatchRoute {
    fn stream() -> &'static str {
        "TYPEWRITER_MEMBERSHIP"
    }
}
impl crate::transport::OutboundEventRoute for UserJoinRequestsWatchRoute {
    type Scope = crate::transport::UserScope;
    type Event = crate::skirout::base::organization::v1::join_request::UserJoinRequestsChanged;
    fn serializer() -> crate::skir_client::Serializer<Self::Event> {
        <Self::Event>::serializer()
    }
    fn subject(scope: &Self::Scope) -> String {
        let crate::transport::UserScope { user } = scope;
        format!("typewriter.to.user.{user}.join_requests.changed")
    }
}
impl UserJoinRequestsWatchRoute {
    pub fn delivery(scope: &crate::transport::UserScope) -> crate::transport::EventDelivery<Self> {
        crate::transport::EventDelivery::new(scope)
    }
}
impl crate::transport::PersistentEventRoute for UserJoinRequestsWatchRoute {
    fn stream() -> &'static str {
        "TYPEWRITER_MEMBERSHIP"
    }
}
impl crate::transport::OutboundEventRoute for OrganizationMembersWatchRoute {
    type Scope = crate::transport::OrganizationScope;
    type Event = crate::skirout::base::organization::v1::member::OrganizationMembersChanged;
    fn serializer() -> crate::skir_client::Serializer<Self::Event> {
        <Self::Event>::serializer()
    }
    fn subject(scope: &Self::Scope) -> String {
        let crate::transport::OrganizationScope { organization } = scope;
        format!("typewriter.to.organization.{organization}.members.changed")
    }
}
impl OrganizationMembersWatchRoute {
    pub fn delivery(
        scope: &crate::transport::OrganizationScope,
    ) -> crate::transport::EventDelivery<Self> {
        crate::transport::EventDelivery::new(scope)
    }
}
impl crate::transport::PersistentEventRoute for OrganizationMembersWatchRoute {
    fn stream() -> &'static str {
        "TYPEWRITER_MEMBERSHIP"
    }
}
impl crate::transport::OutboundEventRoute for OrganizationJoinRequestsWatchRoute {
    type Scope = crate::transport::OrganizationScope;
    type Event =
        crate::skirout::base::organization::v1::join_request::OrganizationJoinRequestsChanged;
    fn serializer() -> crate::skir_client::Serializer<Self::Event> {
        <Self::Event>::serializer()
    }
    fn subject(scope: &Self::Scope) -> String {
        let crate::transport::OrganizationScope { organization } = scope;
        format!("typewriter.to.organization.{organization}.join_requests.changed")
    }
}
impl OrganizationJoinRequestsWatchRoute {
    pub fn delivery(
        scope: &crate::transport::OrganizationScope,
    ) -> crate::transport::EventDelivery<Self> {
        crate::transport::EventDelivery::new(scope)
    }
}
impl crate::transport::PersistentEventRoute for OrganizationJoinRequestsWatchRoute {
    fn stream() -> &'static str {
        "TYPEWRITER_MEMBERSHIP"
    }
}
impl crate::transport::OutboundEventRoute for OrganizationJoinCodesWatchRoute {
    type Scope = crate::transport::OrganizationScope;
    type Event = crate::skirout::base::organization::v1::join_codes::OrganizationJoinCodesChanged;
    fn serializer() -> crate::skir_client::Serializer<Self::Event> {
        <Self::Event>::serializer()
    }
    fn subject(scope: &Self::Scope) -> String {
        let crate::transport::OrganizationScope { organization } = scope;
        format!("typewriter.to.organization.{organization}.join_codes.changed")
    }
}
impl OrganizationJoinCodesWatchRoute {
    pub fn delivery(
        scope: &crate::transport::OrganizationScope,
    ) -> crate::transport::EventDelivery<Self> {
        crate::transport::EventDelivery::new(scope)
    }
}
impl crate::transport::PersistentEventRoute for OrganizationJoinCodesWatchRoute {
    fn stream() -> &'static str {
        "TYPEWRITER_MEMBERSHIP"
    }
}
impl crate::transport::OutboundEventRoute for ServiceBindingQueryRoute {
    type Scope = crate::transport::ServiceScope;
    type Event = crate::skirout::base::service::v1::registration::ServiceBoundNotification;
    fn serializer() -> crate::skir_client::Serializer<Self::Event> {
        <Self::Event>::serializer()
    }
    fn subject(scope: &Self::Scope) -> String {
        let crate::transport::ServiceScope { service } = scope;
        format!("typewriter.to.service.{service}.registration.bound")
    }
}
impl ServiceBindingQueryRoute {
    pub fn delivery(
        scope: &crate::transport::ServiceScope,
    ) -> crate::transport::EventDelivery<Self> {
        crate::transport::EventDelivery::new(scope)
    }
}
impl crate::transport::TransientEventRoute for ServiceBindingQueryRoute {}
impl crate::transport::OutboundEventRoute for OrganizationServicesWatchRoute {
    type Scope = crate::transport::OrganizationScope;
    type Event = crate::skirout::base::service::v1::organization::OrganizationServicesChanged;
    fn serializer() -> crate::skir_client::Serializer<Self::Event> {
        <Self::Event>::serializer()
    }
    fn subject(scope: &Self::Scope) -> String {
        let crate::transport::OrganizationScope { organization } = scope;
        format!("typewriter.to.organization.{organization}.services.watch")
    }
}
impl OrganizationServicesWatchRoute {
    pub fn delivery(
        scope: &crate::transport::OrganizationScope,
    ) -> crate::transport::EventDelivery<Self> {
        crate::transport::EventDelivery::new(scope)
    }
}
impl crate::transport::TransientEventRoute for OrganizationServicesWatchRoute {}
impl crate::transport::OutboundEventRoute for OrganizationTopologyWatchRoute {
    type Scope = crate::transport::OrganizationScope;
    type Event = crate::skirout::base::service::v1::topology::OrganizationTopologyChanged;
    fn serializer() -> crate::skir_client::Serializer<Self::Event> {
        <Self::Event>::serializer()
    }
    fn subject(scope: &Self::Scope) -> String {
        let crate::transport::OrganizationScope { organization } = scope;
        format!("typewriter.to.organization.{organization}.topology.watch")
    }
}
impl OrganizationTopologyWatchRoute {
    pub fn delivery(
        scope: &crate::transport::OrganizationScope,
    ) -> crate::transport::EventDelivery<Self> {
        crate::transport::EventDelivery::new(scope)
    }
}
impl crate::transport::TransientEventRoute for OrganizationTopologyWatchRoute {}
impl crate::transport::OutboundEventRoute for HostExecutionWatchRoute {
    type Scope = crate::transport::ServiceScope;
    type Event = crate::skirout::base::service::v1::topology::WatchHostExecutionResponse;
    fn serializer() -> crate::skir_client::Serializer<Self::Event> {
        <Self::Event>::serializer()
    }
    fn subject(scope: &Self::Scope) -> String {
        let crate::transport::ServiceScope { service } = scope;
        format!("typewriter.to.service.{service}.execution.watch")
    }
}
impl HostExecutionWatchRoute {
    pub fn delivery(
        scope: &crate::transport::ServiceScope,
    ) -> crate::transport::EventDelivery<Self> {
        crate::transport::EventDelivery::new(scope)
    }
}
impl crate::transport::TransientEventRoute for HostExecutionWatchRoute {}
/// Typed dispatch of every message the `user-organization` component receives.
pub mod user_organization {
    use crate::otel_wasi::Error;
    use crate::skirout::base::organization::v1::organization::CreateOrganizationRequest;
    use crate::skirout::base::organization::v1::organization::CreateOrganizationResponse;
    use crate::skirout::base::organization::v1::user::CancelUserJoinRequestRequest;
    use crate::skirout::base::organization::v1::user::CancelUserJoinRequestResponse;
    use crate::skirout::base::organization::v1::user::SubmitUserJoinRequestRequest;
    use crate::skirout::base::organization::v1::user::SubmitUserJoinRequestResponse;
    use crate::skirout::base::organization::v1::user::WatchUserJoinRequestsRequest;
    use crate::skirout::base::organization::v1::user::WatchUserJoinRequestsResponse;
    use crate::skirout::base::organization::v1::user::WatchUserOrganizationsRequest;
    use crate::skirout::base::organization::v1::user::WatchUserOrganizationsResponse;
    use crate::transport::UserScope;
    use crate::transport::serve_request;
    use crate::transport::unmatched;
    use crate::wasmcloud::messaging::types::NatsMessage;

    /// The subjects the component subscribes to, one per subject the dispatcher matches.
    pub const SUBSCRIPTIONS: &[&str] = &[
        "typewriter.from.user.*.organization.create",
        "typewriter.from.user.*.organization.watch",
        "typewriter.from.user.*.organization.join_requests.watch",
        "typewriter.from.user.*.organization.join_requests.request",
        "typewriter.from.user.*.organization.join_requests.cancel",
    ];

    /// One handler per route the component serves, named after the route.
    pub struct Handlers<
        UserOrganizationCreate,
        UserOrganizationsWatch,
        UserJoinRequestsWatch,
        UserJoinRequestSubmit,
        UserJoinRequestCancel,
    > {
        pub user_organization_create: UserOrganizationCreate,
        pub user_organizations_watch: UserOrganizationsWatch,
        pub user_join_requests_watch: UserJoinRequestsWatch,
        pub user_join_request_submit: UserJoinRequestSubmit,
        pub user_join_request_cancel: UserJoinRequestCancel,
    }

    /// Serves one received message on the route its subject matches. Any other subject fails
    /// with `transport-unmatched-subject`.
    #[allow(
        clippy::type_complexity,
        reason = "one type parameter per served route"
    )]
    pub async fn dispatch<
        UserOrganizationCreate,
        UserOrganizationsWatch,
        UserJoinRequestsWatch,
        UserJoinRequestSubmit,
        UserJoinRequestCancel,
    >(
        msg: NatsMessage,
        handlers: Handlers<
            UserOrganizationCreate,
            UserOrganizationsWatch,
            UserJoinRequestsWatch,
            UserJoinRequestSubmit,
            UserJoinRequestCancel,
        >,
    ) -> Result<(), Error>
    where
        UserOrganizationCreate: AsyncFnOnce(
            UserScope,
            CreateOrganizationRequest,
        ) -> Result<CreateOrganizationResponse, Error>,
        UserOrganizationsWatch: AsyncFnOnce(
            UserScope,
            WatchUserOrganizationsRequest,
        )
            -> Result<WatchUserOrganizationsResponse, Error>,
        UserJoinRequestsWatch: AsyncFnOnce(
            UserScope,
            WatchUserJoinRequestsRequest,
        ) -> Result<WatchUserJoinRequestsResponse, Error>,
        UserJoinRequestSubmit: AsyncFnOnce(
            UserScope,
            SubmitUserJoinRequestRequest,
        ) -> Result<SubmitUserJoinRequestResponse, Error>,
        UserJoinRequestCancel: AsyncFnOnce(
            UserScope,
            CancelUserJoinRequestRequest,
        ) -> Result<CancelUserJoinRequestResponse, Error>,
    {
        let subject = msg.subject.clone();
        match subject.split('.').collect::<Vec<_>>().as_slice() {
            ["typewriter", "from", "user", user, "organization", "create"] => {
                let scope = UserScope::from_tokens(user);
                serve_request::<super::UserOrganizationCreateRoute>(
                    msg,
                    scope,
                    handlers.user_organization_create,
                )
                .await
            }
            ["typewriter", "from", "user", user, "organization", "watch"] => {
                let scope = UserScope::from_tokens(user);
                serve_request::<super::UserOrganizationsWatchRoute>(
                    msg,
                    scope,
                    handlers.user_organizations_watch,
                )
                .await
            }
            [
                "typewriter",
                "from",
                "user",
                user,
                "organization",
                "join_requests",
                "watch",
            ] => {
                let scope = UserScope::from_tokens(user);
                serve_request::<super::UserJoinRequestsWatchRoute>(
                    msg,
                    scope,
                    handlers.user_join_requests_watch,
                )
                .await
            }
            [
                "typewriter",
                "from",
                "user",
                user,
                "organization",
                "join_requests",
                "request",
            ] => {
                let scope = UserScope::from_tokens(user);
                serve_request::<super::UserJoinRequestSubmitRoute>(
                    msg,
                    scope,
                    handlers.user_join_request_submit,
                )
                .await
            }
            [
                "typewriter",
                "from",
                "user",
                user,
                "organization",
                "join_requests",
                "cancel",
            ] => {
                let scope = UserScope::from_tokens(user);
                serve_request::<super::UserJoinRequestCancelRoute>(
                    msg,
                    scope,
                    handlers.user_join_request_cancel,
                )
                .await
            }
            _ => Err(unmatched(&msg)),
        }
    }
}
/// Typed dispatch of every message the `organization-members` component receives.
pub mod organization_members {
    use crate::otel_wasi::Error;
    use crate::skirout::base::organization::v1::join_codes::GenerateOrganizationJoinCodeRequest;
    use crate::skirout::base::organization::v1::join_codes::GenerateOrganizationJoinCodeResponse;
    use crate::skirout::base::organization::v1::join_codes::RevokeOrganizationJoinCodeRequest;
    use crate::skirout::base::organization::v1::join_codes::RevokeOrganizationJoinCodeResponse;
    use crate::skirout::base::organization::v1::join_codes::WatchOrganizationJoinCodesRequest;
    use crate::skirout::base::organization::v1::join_codes::WatchOrganizationJoinCodesResponse;
    use crate::skirout::base::organization::v1::join_request::ApproveOrganizationJoinRequestsRequest;
    use crate::skirout::base::organization::v1::join_request::ApproveOrganizationJoinRequestsResponse;
    use crate::skirout::base::organization::v1::join_request::DeclineOrganizationJoinRequestRequest;
    use crate::skirout::base::organization::v1::join_request::DeclineOrganizationJoinRequestResponse;
    use crate::skirout::base::organization::v1::join_request::WatchOrganizationJoinRequestsRequest;
    use crate::skirout::base::organization::v1::join_request::WatchOrganizationJoinRequestsResponse;
    use crate::skirout::base::organization::v1::member::RemoveOrganizationMemberRequest;
    use crate::skirout::base::organization::v1::member::RemoveOrganizationMemberResponse;
    use crate::skirout::base::organization::v1::member::UpdateOrganizationMemberRolesRequest;
    use crate::skirout::base::organization::v1::member::UpdateOrganizationMemberRolesResponse;
    use crate::skirout::base::organization::v1::member::WatchOrganizationMembersRequest;
    use crate::skirout::base::organization::v1::member::WatchOrganizationMembersResponse;
    use crate::transport::OrganizationActorScope;
    use crate::transport::serve_request;
    use crate::transport::unmatched;
    use crate::wasmcloud::messaging::types::NatsMessage;

    /// The subjects the component subscribes to, one per subject the dispatcher matches.
    pub const SUBSCRIPTIONS: &[&str] = &[
        "typewriter.from.user.*.organization.*.members.watch",
        "typewriter.from.user.*.organization.*.members.update",
        "typewriter.from.user.*.organization.*.members.remove",
        "typewriter.from.user.*.organization.*.members.join_requests.watch",
        "typewriter.from.user.*.organization.*.members.join_requests.approve",
        "typewriter.from.user.*.organization.*.members.join_requests.decline",
        "typewriter.from.user.*.organization.*.members.join_codes.watch",
        "typewriter.from.user.*.organization.*.members.join_codes.generate",
        "typewriter.from.user.*.organization.*.members.join_codes.revoke",
    ];

    /// One handler per route the component serves, named after the route.
    pub struct Handlers<
        OrganizationMembersWatch,
        OrganizationMembersUpdate,
        OrganizationMemberRemove,
        OrganizationJoinRequestsWatch,
        OrganizationJoinRequestsApprove,
        OrganizationJoinRequestDecline,
        OrganizationJoinCodesWatch,
        OrganizationJoinCodeGenerate,
        OrganizationJoinCodeRevoke,
    > {
        pub organization_members_watch: OrganizationMembersWatch,
        pub organization_members_update: OrganizationMembersUpdate,
        pub organization_member_remove: OrganizationMemberRemove,
        pub organization_join_requests_watch: OrganizationJoinRequestsWatch,
        pub organization_join_requests_approve: OrganizationJoinRequestsApprove,
        pub organization_join_request_decline: OrganizationJoinRequestDecline,
        pub organization_join_codes_watch: OrganizationJoinCodesWatch,
        pub organization_join_code_generate: OrganizationJoinCodeGenerate,
        pub organization_join_code_revoke: OrganizationJoinCodeRevoke,
    }

    /// Serves one received message on the route its subject matches. Any other subject fails
    /// with `transport-unmatched-subject`.
    #[allow(
        clippy::type_complexity,
        reason = "one type parameter per served route"
    )]
    pub async fn dispatch<
        OrganizationMembersWatch,
        OrganizationMembersUpdate,
        OrganizationMemberRemove,
        OrganizationJoinRequestsWatch,
        OrganizationJoinRequestsApprove,
        OrganizationJoinRequestDecline,
        OrganizationJoinCodesWatch,
        OrganizationJoinCodeGenerate,
        OrganizationJoinCodeRevoke,
    >(
        msg: NatsMessage,
        handlers: Handlers<
            OrganizationMembersWatch,
            OrganizationMembersUpdate,
            OrganizationMemberRemove,
            OrganizationJoinRequestsWatch,
            OrganizationJoinRequestsApprove,
            OrganizationJoinRequestDecline,
            OrganizationJoinCodesWatch,
            OrganizationJoinCodeGenerate,
            OrganizationJoinCodeRevoke,
        >,
    ) -> Result<(), Error>
    where
        OrganizationMembersWatch: AsyncFnOnce(
            OrganizationActorScope,
            WatchOrganizationMembersRequest,
        )
            -> Result<WatchOrganizationMembersResponse, Error>,
        OrganizationMembersUpdate:
            AsyncFnOnce(
                OrganizationActorScope,
                UpdateOrganizationMemberRolesRequest,
            ) -> Result<UpdateOrganizationMemberRolesResponse, Error>,
        OrganizationMemberRemove: AsyncFnOnce(
            OrganizationActorScope,
            RemoveOrganizationMemberRequest,
        )
            -> Result<RemoveOrganizationMemberResponse, Error>,
        OrganizationJoinRequestsWatch:
            AsyncFnOnce(
                OrganizationActorScope,
                WatchOrganizationJoinRequestsRequest,
            ) -> Result<WatchOrganizationJoinRequestsResponse, Error>,
        OrganizationJoinRequestsApprove:
            AsyncFnOnce(
                OrganizationActorScope,
                ApproveOrganizationJoinRequestsRequest,
            ) -> Result<ApproveOrganizationJoinRequestsResponse, Error>,
        OrganizationJoinRequestDecline:
            AsyncFnOnce(
                OrganizationActorScope,
                DeclineOrganizationJoinRequestRequest,
            ) -> Result<DeclineOrganizationJoinRequestResponse, Error>,
        OrganizationJoinCodesWatch:
            AsyncFnOnce(
                OrganizationActorScope,
                WatchOrganizationJoinCodesRequest,
            ) -> Result<WatchOrganizationJoinCodesResponse, Error>,
        OrganizationJoinCodeGenerate:
            AsyncFnOnce(
                OrganizationActorScope,
                GenerateOrganizationJoinCodeRequest,
            ) -> Result<GenerateOrganizationJoinCodeResponse, Error>,
        OrganizationJoinCodeRevoke:
            AsyncFnOnce(
                OrganizationActorScope,
                RevokeOrganizationJoinCodeRequest,
            ) -> Result<RevokeOrganizationJoinCodeResponse, Error>,
    {
        let subject = msg.subject.clone();
        match subject.split('.').collect::<Vec<_>>().as_slice() {
            [
                "typewriter",
                "from",
                "user",
                user,
                "organization",
                organization,
                "members",
                "watch",
            ] => {
                let scope = OrganizationActorScope::from_tokens(user, organization);
                serve_request::<super::OrganizationMembersWatchRoute>(
                    msg,
                    scope,
                    handlers.organization_members_watch,
                )
                .await
            }
            [
                "typewriter",
                "from",
                "user",
                user,
                "organization",
                organization,
                "members",
                "update",
            ] => {
                let scope = OrganizationActorScope::from_tokens(user, organization);
                serve_request::<super::OrganizationMembersUpdateRoute>(
                    msg,
                    scope,
                    handlers.organization_members_update,
                )
                .await
            }
            [
                "typewriter",
                "from",
                "user",
                user,
                "organization",
                organization,
                "members",
                "remove",
            ] => {
                let scope = OrganizationActorScope::from_tokens(user, organization);
                serve_request::<super::OrganizationMemberRemoveRoute>(
                    msg,
                    scope,
                    handlers.organization_member_remove,
                )
                .await
            }
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
            ] => {
                let scope = OrganizationActorScope::from_tokens(user, organization);
                serve_request::<super::OrganizationJoinRequestsWatchRoute>(
                    msg,
                    scope,
                    handlers.organization_join_requests_watch,
                )
                .await
            }
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
            ] => {
                let scope = OrganizationActorScope::from_tokens(user, organization);
                serve_request::<super::OrganizationJoinRequestsApproveRoute>(
                    msg,
                    scope,
                    handlers.organization_join_requests_approve,
                )
                .await
            }
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
            ] => {
                let scope = OrganizationActorScope::from_tokens(user, organization);
                serve_request::<super::OrganizationJoinRequestDeclineRoute>(
                    msg,
                    scope,
                    handlers.organization_join_request_decline,
                )
                .await
            }
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
            ] => {
                let scope = OrganizationActorScope::from_tokens(user, organization);
                serve_request::<super::OrganizationJoinCodesWatchRoute>(
                    msg,
                    scope,
                    handlers.organization_join_codes_watch,
                )
                .await
            }
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
            ] => {
                let scope = OrganizationActorScope::from_tokens(user, organization);
                serve_request::<super::OrganizationJoinCodeGenerateRoute>(
                    msg,
                    scope,
                    handlers.organization_join_code_generate,
                )
                .await
            }
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
            ] => {
                let scope = OrganizationActorScope::from_tokens(user, organization);
                serve_request::<super::OrganizationJoinCodeRevokeRoute>(
                    msg,
                    scope,
                    handlers.organization_join_code_revoke,
                )
                .await
            }
            _ => Err(unmatched(&msg)),
        }
    }
}
/// Typed dispatch of every message the `organization-roles` component receives.
pub mod organization_roles {
    use crate::otel_wasi::Error;
    use crate::skirout::base::organization::v1::role::WatchOrganizationRolesRequest;
    use crate::skirout::base::organization::v1::role::WatchOrganizationRolesResponse;
    use crate::transport::OrganizationActorScope;
    use crate::transport::serve_request;
    use crate::transport::unmatched;
    use crate::wasmcloud::messaging::types::NatsMessage;

    /// The subjects the component subscribes to, one per subject the dispatcher matches.
    pub const SUBSCRIPTIONS: &[&str] = &["typewriter.from.user.*.organization.*.roles.watch"];

    /// One handler per route the component serves, named after the route.
    pub struct Handlers<OrganizationRolesWatch> {
        pub organization_roles_watch: OrganizationRolesWatch,
    }

    /// Serves one received message on the route its subject matches. Any other subject fails
    /// with `transport-unmatched-subject`.
    #[allow(
        clippy::type_complexity,
        reason = "one type parameter per served route"
    )]
    pub async fn dispatch<OrganizationRolesWatch>(
        msg: NatsMessage,
        handlers: Handlers<OrganizationRolesWatch>,
    ) -> Result<(), Error>
    where
        OrganizationRolesWatch: AsyncFnOnce(
            OrganizationActorScope,
            WatchOrganizationRolesRequest,
        )
            -> Result<WatchOrganizationRolesResponse, Error>,
    {
        let subject = msg.subject.clone();
        match subject.split('.').collect::<Vec<_>>().as_slice() {
            [
                "typewriter",
                "from",
                "user",
                user,
                "organization",
                organization,
                "roles",
                "watch",
            ] => {
                let scope = OrganizationActorScope::from_tokens(user, organization);
                serve_request::<super::OrganizationRolesWatchRoute>(
                    msg,
                    scope,
                    handlers.organization_roles_watch,
                )
                .await
            }
            _ => Err(unmatched(&msg)),
        }
    }
}
/// Typed dispatch of every message the `service-registration` component receives.
pub mod service_registration {
    use crate::otel_wasi::Error;
    use crate::skirout::base::service::v1::lifecycle::ServiceHeartbeatNotification;
    use crate::skirout::base::service::v1::lifecycle::ServiceShutdownNotification;
    use crate::skirout::base::service::v1::organization::UpdateOrganizationServiceRequest;
    use crate::skirout::base::service::v1::organization::UpdateOrganizationServiceResponse;
    use crate::skirout::base::service::v1::organization::WatchOrganizationServicesRequest;
    use crate::skirout::base::service::v1::organization::WatchOrganizationServicesResponse;
    use crate::skirout::base::service::v1::registration::BindServiceRequest;
    use crate::skirout::base::service::v1::registration::BindServiceResponse;
    use crate::skirout::base::service::v1::registration::UnbindServiceRequest;
    use crate::skirout::base::service::v1::registration::UnbindServiceResponse;
    use crate::skirout::base::service::v1::status::EnsureRegistrationLeaseRequest;
    use crate::skirout::base::service::v1::status::EnsureRegistrationLeaseResponse;
    use crate::skirout::base::service::v1::status::QueryServiceBindingRequest;
    use crate::skirout::base::service::v1::status::QueryServiceBindingResponse;
    use crate::skirout::base::service::v1::topology::ConfigureServiceHostRequest;
    use crate::skirout::base::service::v1::topology::ConfigureServiceHostResponse;
    use crate::skirout::base::service::v1::topology::GetServiceMessagingScopeRequest;
    use crate::skirout::base::service::v1::topology::GetServiceMessagingScopeResponse;
    use crate::skirout::base::service::v1::topology::RegisterServiceHostRequest;
    use crate::skirout::base::service::v1::topology::RegisterServiceHostResponse;
    use crate::skirout::base::service::v1::topology::ReportHostExecutionRequest;
    use crate::skirout::base::service::v1::topology::ReportHostExecutionResponse;
    use crate::skirout::base::service::v1::topology::WatchHostExecutionRequest;
    use crate::skirout::base::service::v1::topology::WatchHostExecutionResponse;
    use crate::skirout::base::service::v1::topology::WatchOrganizationTopologyRequest;
    use crate::skirout::base::service::v1::topology::WatchOrganizationTopologyResponse;
    use crate::transport::OrganizationActorScope;
    use crate::transport::ServiceScope;
    use crate::transport::serve_event;
    use crate::transport::serve_request;
    use crate::transport::unmatched;
    use crate::wasmcloud::messaging::types::NatsMessage;

    /// The subjects the component subscribes to, one per subject the dispatcher matches.
    pub const SUBSCRIPTIONS: &[&str] = &[
        "typewriter.from.service.*.binding.query",
        "service.*.binding.query",
        "typewriter.from.service.*.registration.ensure",
        "typewriter.from.service.*.messaging.scope",
        "service.*.messaging.scope",
        "typewriter.from.user.*.organization.*.services.bind",
        "typewriter.from.user.*.organization.*.services.watch",
        "typewriter.from.user.*.organization.*.services.update",
        "typewriter.from.user.*.organization.*.services.unbind",
        "typewriter.from.user.*.organization.*.topology.configure",
        "typewriter.from.user.*.organization.*.topology.watch",
        "typewriter.from.service.*.execution.register",
        "typewriter.from.service.*.execution.watch",
        "typewriter.from.service.*.execution.report",
        "typewriter.from.service.*.heartbeat",
        "typewriter.from.service.*.shutdown",
    ];

    /// One handler per route the component serves, named after the route.
    pub struct Handlers<
        ServiceBindingQuery,
        RegistrationLeaseEnsure,
        ServiceMessagingScope,
        ServiceBind,
        OrganizationServicesWatch,
        OrganizationServiceUpdate,
        ServiceUnbind,
        ServiceTopologyConfigure,
        OrganizationTopologyWatch,
        ServiceHostRegister,
        HostExecutionWatch,
        HostExecutionReport,
        ServiceHeartbeat,
        ServiceShutdown,
    > {
        pub service_binding_query: ServiceBindingQuery,
        pub registration_lease_ensure: RegistrationLeaseEnsure,
        pub service_messaging_scope: ServiceMessagingScope,
        pub service_bind: ServiceBind,
        pub organization_services_watch: OrganizationServicesWatch,
        pub organization_service_update: OrganizationServiceUpdate,
        pub service_unbind: ServiceUnbind,
        pub service_topology_configure: ServiceTopologyConfigure,
        pub organization_topology_watch: OrganizationTopologyWatch,
        pub service_host_register: ServiceHostRegister,
        pub host_execution_watch: HostExecutionWatch,
        pub host_execution_report: HostExecutionReport,
        pub service_heartbeat: ServiceHeartbeat,
        pub service_shutdown: ServiceShutdown,
    }

    /// Serves one received message on the route its subject matches. Any other subject fails
    /// with `transport-unmatched-subject`.
    #[allow(
        clippy::type_complexity,
        reason = "one type parameter per served route"
    )]
    pub async fn dispatch<
        ServiceBindingQuery,
        RegistrationLeaseEnsure,
        ServiceMessagingScope,
        ServiceBind,
        OrganizationServicesWatch,
        OrganizationServiceUpdate,
        ServiceUnbind,
        ServiceTopologyConfigure,
        OrganizationTopologyWatch,
        ServiceHostRegister,
        HostExecutionWatch,
        HostExecutionReport,
        ServiceHeartbeat,
        ServiceShutdown,
    >(
        msg: NatsMessage,
        handlers: Handlers<
            ServiceBindingQuery,
            RegistrationLeaseEnsure,
            ServiceMessagingScope,
            ServiceBind,
            OrganizationServicesWatch,
            OrganizationServiceUpdate,
            ServiceUnbind,
            ServiceTopologyConfigure,
            OrganizationTopologyWatch,
            ServiceHostRegister,
            HostExecutionWatch,
            HostExecutionReport,
            ServiceHeartbeat,
            ServiceShutdown,
        >,
    ) -> Result<(), Error>
    where
        ServiceBindingQuery: AsyncFnOnce(
            ServiceScope,
            QueryServiceBindingRequest,
        ) -> Result<QueryServiceBindingResponse, Error>,
        RegistrationLeaseEnsure: AsyncFnOnce(
            ServiceScope,
            EnsureRegistrationLeaseRequest,
        )
            -> Result<EnsureRegistrationLeaseResponse, Error>,
        ServiceMessagingScope: AsyncFnOnce(
            ServiceScope,
            GetServiceMessagingScopeRequest,
        )
            -> Result<GetServiceMessagingScopeResponse, Error>,
        ServiceBind: AsyncFnOnce(
            OrganizationActorScope,
            BindServiceRequest,
        ) -> Result<BindServiceResponse, Error>,
        OrganizationServicesWatch: AsyncFnOnce(
            OrganizationActorScope,
            WatchOrganizationServicesRequest,
        )
            -> Result<WatchOrganizationServicesResponse, Error>,
        OrganizationServiceUpdate: AsyncFnOnce(
            OrganizationActorScope,
            UpdateOrganizationServiceRequest,
        )
            -> Result<UpdateOrganizationServiceResponse, Error>,
        ServiceUnbind: AsyncFnOnce(
            OrganizationActorScope,
            UnbindServiceRequest,
        ) -> Result<UnbindServiceResponse, Error>,
        ServiceTopologyConfigure: AsyncFnOnce(
            OrganizationActorScope,
            ConfigureServiceHostRequest,
        )
            -> Result<ConfigureServiceHostResponse, Error>,
        OrganizationTopologyWatch: AsyncFnOnce(
            OrganizationActorScope,
            WatchOrganizationTopologyRequest,
        )
            -> Result<WatchOrganizationTopologyResponse, Error>,
        ServiceHostRegister: AsyncFnOnce(
            ServiceScope,
            RegisterServiceHostRequest,
        ) -> Result<RegisterServiceHostResponse, Error>,
        HostExecutionWatch: AsyncFnOnce(
            ServiceScope,
            WatchHostExecutionRequest,
        ) -> Result<WatchHostExecutionResponse, Error>,
        HostExecutionReport: AsyncFnOnce(
            ServiceScope,
            ReportHostExecutionRequest,
        ) -> Result<ReportHostExecutionResponse, Error>,
        ServiceHeartbeat:
            AsyncFnOnce(ServiceScope, ServiceHeartbeatNotification) -> Result<(), Error>,
        ServiceShutdown:
            AsyncFnOnce(ServiceScope, ServiceShutdownNotification) -> Result<(), Error>,
    {
        let subject = msg.subject.clone();
        match subject.split('.').collect::<Vec<_>>().as_slice() {
            ["typewriter", "from", "service", service, "binding", "query"] => {
                let scope = ServiceScope::from_tokens(service);
                serve_request::<super::ServiceBindingQueryRoute>(
                    msg,
                    scope,
                    handlers.service_binding_query,
                )
                .await
            }
            ["service", service, "binding", "query"] => {
                let scope = ServiceScope::from_tokens(service);
                serve_request::<super::ServiceBindingQueryRoute>(
                    msg,
                    scope,
                    handlers.service_binding_query,
                )
                .await
            }
            [
                "typewriter",
                "from",
                "service",
                service,
                "registration",
                "ensure",
            ] => {
                let scope = ServiceScope::from_tokens(service);
                serve_request::<super::RegistrationLeaseEnsureRoute>(
                    msg,
                    scope,
                    handlers.registration_lease_ensure,
                )
                .await
            }
            [
                "typewriter",
                "from",
                "service",
                service,
                "messaging",
                "scope",
            ] => {
                let scope = ServiceScope::from_tokens(service);
                serve_request::<super::ServiceMessagingScopeRoute>(
                    msg,
                    scope,
                    handlers.service_messaging_scope,
                )
                .await
            }
            ["service", service, "messaging", "scope"] => {
                let scope = ServiceScope::from_tokens(service);
                serve_request::<super::ServiceMessagingScopeRoute>(
                    msg,
                    scope,
                    handlers.service_messaging_scope,
                )
                .await
            }
            [
                "typewriter",
                "from",
                "user",
                user,
                "organization",
                organization,
                "services",
                "bind",
            ] => {
                let scope = OrganizationActorScope::from_tokens(user, organization);
                serve_request::<super::ServiceBindRoute>(msg, scope, handlers.service_bind).await
            }
            [
                "typewriter",
                "from",
                "user",
                user,
                "organization",
                organization,
                "services",
                "watch",
            ] => {
                let scope = OrganizationActorScope::from_tokens(user, organization);
                serve_request::<super::OrganizationServicesWatchRoute>(
                    msg,
                    scope,
                    handlers.organization_services_watch,
                )
                .await
            }
            [
                "typewriter",
                "from",
                "user",
                user,
                "organization",
                organization,
                "services",
                "update",
            ] => {
                let scope = OrganizationActorScope::from_tokens(user, organization);
                serve_request::<super::OrganizationServiceUpdateRoute>(
                    msg,
                    scope,
                    handlers.organization_service_update,
                )
                .await
            }
            [
                "typewriter",
                "from",
                "user",
                user,
                "organization",
                organization,
                "services",
                "unbind",
            ] => {
                let scope = OrganizationActorScope::from_tokens(user, organization);
                serve_request::<super::ServiceUnbindRoute>(msg, scope, handlers.service_unbind)
                    .await
            }
            [
                "typewriter",
                "from",
                "user",
                user,
                "organization",
                organization,
                "topology",
                "configure",
            ] => {
                let scope = OrganizationActorScope::from_tokens(user, organization);
                serve_request::<super::ServiceTopologyConfigureRoute>(
                    msg,
                    scope,
                    handlers.service_topology_configure,
                )
                .await
            }
            [
                "typewriter",
                "from",
                "user",
                user,
                "organization",
                organization,
                "topology",
                "watch",
            ] => {
                let scope = OrganizationActorScope::from_tokens(user, organization);
                serve_request::<super::OrganizationTopologyWatchRoute>(
                    msg,
                    scope,
                    handlers.organization_topology_watch,
                )
                .await
            }
            [
                "typewriter",
                "from",
                "service",
                service,
                "execution",
                "register",
            ] => {
                let scope = ServiceScope::from_tokens(service);
                serve_request::<super::ServiceHostRegisterRoute>(
                    msg,
                    scope,
                    handlers.service_host_register,
                )
                .await
            }
            [
                "typewriter",
                "from",
                "service",
                service,
                "execution",
                "watch",
            ] => {
                let scope = ServiceScope::from_tokens(service);
                serve_request::<super::HostExecutionWatchRoute>(
                    msg,
                    scope,
                    handlers.host_execution_watch,
                )
                .await
            }
            [
                "typewriter",
                "from",
                "service",
                service,
                "execution",
                "report",
            ] => {
                let scope = ServiceScope::from_tokens(service);
                serve_request::<super::HostExecutionReportRoute>(
                    msg,
                    scope,
                    handlers.host_execution_report,
                )
                .await
            }
            ["typewriter", "from", "service", service, "heartbeat"] => {
                let scope = ServiceScope::from_tokens(service);
                serve_event::<super::ServiceHeartbeatRoute>(msg, scope, handlers.service_heartbeat)
                    .await
            }
            ["typewriter", "from", "service", service, "shutdown"] => {
                let scope = ServiceScope::from_tokens(service);
                serve_event::<super::ServiceShutdownRoute>(msg, scope, handlers.service_shutdown)
                    .await
            }
            _ => Err(unmatched(&msg)),
        }
    }
}
/// Typed dispatch of every message the `auth-typewriter-permissions` component receives.
pub mod auth_typewriter_permissions {
    use crate::otel_wasi::Error;
    use crate::skirout::base::access::v1::permission::GetEntityPermissionRequest;
    use crate::skirout::base::access::v1::permission::GetEntityPermissionResponse;
    use crate::transport::InternalComponentScope;
    use crate::transport::serve_request;
    use crate::transport::unmatched;
    use crate::wasmcloud::messaging::types::NatsMessage;

    /// The subjects the component subscribes to, one per subject the dispatcher matches.
    pub const SUBSCRIPTIONS: &[&str] = &[
        "auth.permissions.typewriter-panel",
        "auth.permissions.typewriter-services",
    ];

    /// One handler per route the component serves, named after the route.
    pub struct Handlers<PanelPermissionResolve, ServicesPermissionResolve> {
        pub panel_permission_resolve: PanelPermissionResolve,
        pub services_permission_resolve: ServicesPermissionResolve,
    }

    /// Serves one received message on the route its subject matches. Any other subject fails
    /// with `transport-unmatched-subject`.
    #[allow(
        clippy::type_complexity,
        reason = "one type parameter per served route"
    )]
    pub async fn dispatch<PanelPermissionResolve, ServicesPermissionResolve>(
        msg: NatsMessage,
        handlers: Handlers<PanelPermissionResolve, ServicesPermissionResolve>,
    ) -> Result<(), Error>
    where
        PanelPermissionResolve: AsyncFnOnce(
            InternalComponentScope,
            GetEntityPermissionRequest,
        ) -> Result<GetEntityPermissionResponse, Error>,
        ServicesPermissionResolve: AsyncFnOnce(
            InternalComponentScope,
            GetEntityPermissionRequest,
        )
            -> Result<GetEntityPermissionResponse, Error>,
    {
        let subject = msg.subject.clone();
        match subject.split('.').collect::<Vec<_>>().as_slice() {
            ["auth", "permissions", "typewriter-panel"] => {
                let scope = InternalComponentScope::from_tokens();
                serve_request::<super::PanelPermissionResolveRoute>(
                    msg,
                    scope,
                    handlers.panel_permission_resolve,
                )
                .await
            }
            ["auth", "permissions", "typewriter-services"] => {
                let scope = InternalComponentScope::from_tokens();
                serve_request::<super::ServicesPermissionResolveRoute>(
                    msg,
                    scope,
                    handlers.services_permission_resolve,
                )
                .await
            }
            _ => Err(unmatched(&msg)),
        }
    }
}
