//! Generated transport routes. Do not edit; regenerate with `bun run generate:protocol`.
/// The most bytes of an encoded reply that one reply frame carries.
pub const RESPONSE_CHUNK_BYTES: usize = 524288;
/// The most frames one reply may have, and so the most messages a responder may send to one
/// requester inbox.
pub const MAX_RESPONSE_CHUNKS: usize = 64;
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
    fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response> {
        crate::skirout::base::organization::v1::organization::create_organization_method()
    }
}
pub struct UserOrganizationsWatchRoute;
impl crate::transport::RequestRoute for UserOrganizationsWatchRoute {
    type Scope = crate::transport::UserScope;
    type Request = crate::skirout::base::organization::v1::user::WatchUserOrganizationsRequest;
    type Response = crate::skirout::base::organization::v1::user::WatchUserOrganizationsResponse;
    fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response> {
        crate::skirout::base::organization::v1::user::watch_user_organizations_method()
    }
}
pub struct UserJoinRequestsWatchRoute;
impl crate::transport::RequestRoute for UserJoinRequestsWatchRoute {
    type Scope = crate::transport::UserScope;
    type Request = crate::skirout::base::organization::v1::user::WatchUserJoinRequestsRequest;
    type Response = crate::skirout::base::organization::v1::user::WatchUserJoinRequestsResponse;
    fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response> {
        crate::skirout::base::organization::v1::user::watch_user_join_requests_method()
    }
}
pub struct UserJoinRequestSubmitRoute;
impl crate::transport::RequestRoute for UserJoinRequestSubmitRoute {
    type Scope = crate::transport::UserScope;
    type Request = crate::skirout::base::organization::v1::user::SubmitUserJoinRequestRequest;
    type Response = crate::skirout::base::organization::v1::user::SubmitUserJoinRequestResponse;
    fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response> {
        crate::skirout::base::organization::v1::user::submit_user_join_request_method()
    }
}
pub struct UserJoinRequestCancelRoute;
impl crate::transport::RequestRoute for UserJoinRequestCancelRoute {
    type Scope = crate::transport::UserScope;
    type Request = crate::skirout::base::organization::v1::user::CancelUserJoinRequestRequest;
    type Response = crate::skirout::base::organization::v1::user::CancelUserJoinRequestResponse;
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
    fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response> {
        crate::skirout::base::organization::v1::join_request::watch_organization_join_requests_method()
    }
}
pub struct OrganizationJoinRequestsApproveRoute;
impl crate::transport::RequestRoute for OrganizationJoinRequestsApproveRoute {
    type Scope = crate::transport::OrganizationActorScope;
    type Request = crate::skirout::base::organization::v1::join_request::ApproveOrganizationJoinRequestsRequest;
    type Response = crate::skirout::base::organization::v1::join_request::ApproveOrganizationJoinRequestsResponse;
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
    fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response> {
        crate::skirout::base::organization::v1::join_codes::revoke_organization_join_code_method()
    }
}
pub struct OrganizationRolesWatchRoute;
impl crate::transport::RequestRoute for OrganizationRolesWatchRoute {
    type Scope = crate::transport::OrganizationActorScope;
    type Request = crate::skirout::base::organization::v1::role::WatchOrganizationRolesRequest;
    type Response = crate::skirout::base::organization::v1::role::WatchOrganizationRolesResponse;
    fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response> {
        crate::skirout::base::organization::v1::role::watch_organization_roles_method()
    }
}
pub struct ServiceBindingQueryRoute;
impl crate::transport::RequestRoute for ServiceBindingQueryRoute {
    type Scope = crate::transport::ServiceScope;
    type Request = crate::skirout::base::service::v1::status::QueryServiceBindingRequest;
    type Response = crate::skirout::base::service::v1::status::QueryServiceBindingResponse;
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
    fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response> {
        crate::skirout::base::service::v1::status::ensure_registration_lease_method()
    }
}
pub struct ServiceMessagingScopeRoute;
impl crate::transport::RequestRoute for ServiceMessagingScopeRoute {
    type Scope = crate::transport::ServiceScope;
    type Request = crate::skirout::base::service::v1::topology::GetServiceMessagingScopeRequest;
    type Response = crate::skirout::base::service::v1::topology::GetServiceMessagingScopeResponse;
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
    fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response> {
        crate::skirout::base::service::v1::organization::update_organization_service_method()
    }
}
pub struct ServiceUnbindRoute;
impl crate::transport::RequestRoute for ServiceUnbindRoute {
    type Scope = crate::transport::OrganizationActorScope;
    type Request = crate::skirout::base::service::v1::registration::UnbindServiceRequest;
    type Response = crate::skirout::base::service::v1::registration::UnbindServiceResponse;
    fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response> {
        crate::skirout::base::service::v1::registration::unbind_service_method()
    }
}
pub struct ServiceTopologyConfigureRoute;
impl crate::transport::RequestRoute for ServiceTopologyConfigureRoute {
    type Scope = crate::transport::OrganizationActorScope;
    type Request = crate::skirout::base::service::v1::topology::ConfigureServiceHostRequest;
    type Response = crate::skirout::base::service::v1::topology::ConfigureServiceHostResponse;
    fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response> {
        crate::skirout::base::service::v1::topology::configure_service_host_method()
    }
}
pub struct OrganizationTopologyWatchRoute;
impl crate::transport::RequestRoute for OrganizationTopologyWatchRoute {
    type Scope = crate::transport::OrganizationActorScope;
    type Request = crate::skirout::base::service::v1::topology::WatchOrganizationTopologyRequest;
    type Response = crate::skirout::base::service::v1::topology::WatchOrganizationTopologyResponse;
    fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response> {
        crate::skirout::base::service::v1::topology::watch_organization_topology_method()
    }
}
pub struct ServiceHostRegisterRoute;
impl crate::transport::RequestRoute for ServiceHostRegisterRoute {
    type Scope = crate::transport::ServiceScope;
    type Request = crate::skirout::base::service::v1::topology::RegisterServiceHostRequest;
    type Response = crate::skirout::base::service::v1::topology::RegisterServiceHostResponse;
    fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response> {
        crate::skirout::base::service::v1::topology::register_service_host_method()
    }
}
pub struct HostExecutionWatchRoute;
impl crate::transport::RequestRoute for HostExecutionWatchRoute {
    type Scope = crate::transport::ServiceScope;
    type Request = crate::skirout::base::service::v1::topology::WatchHostExecutionRequest;
    type Response = crate::skirout::base::service::v1::topology::WatchHostExecutionResponse;
    fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response> {
        crate::skirout::base::service::v1::topology::watch_host_execution_method()
    }
}
pub struct HostExecutionReportRoute;
impl crate::transport::RequestRoute for HostExecutionReportRoute {
    type Scope = crate::transport::ServiceScope;
    type Request = crate::skirout::base::service::v1::topology::ReportHostExecutionRequest;
    type Response = crate::skirout::base::service::v1::topology::ReportHostExecutionResponse;
    fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response> {
        crate::skirout::base::service::v1::topology::report_host_execution_method()
    }
}
pub struct PanelPermissionResolveRoute;
impl crate::transport::RequestRoute for PanelPermissionResolveRoute {
    type Scope = crate::transport::InternalComponentScope;
    type Request = crate::skirout::base::access::v1::permission::GetEntityPermissionRequest;
    type Response = crate::skirout::base::access::v1::permission::GetEntityPermissionResponse;
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
impl crate::SkirResponse
    for crate::skirout::base::access::v1::permission::GetEntityPermissionResponse
{
    fn to_skir_bytes(&self) -> Vec<u8> {
        Self::serializer().to_bytes(self)
    }
    fn outcome(&self) -> crate::SkirResponseOutcome {
        match self {
            crate::skirout::base::access::v1::permission::GetEntityPermissionResponse::Granted(
                _,
            ) => crate::SkirResponseOutcome::Success,
            // internal_error and the generated unknown variant
            _ => crate::SkirResponseOutcome::InternalError,
        }
    }
    fn variant_slug(&self) -> &'static str {
        match self {
            crate::skirout::base::access::v1::permission::GetEntityPermissionResponse::Granted(_) => "granted",
            crate::skirout::base::access::v1::permission::GetEntityPermissionResponse::InternalError(_) => "internal-error",
            _ => "unknown",
        }
    }
    fn variant_message(&self) -> String {
        self.variant_slug().to_owned()
    }
    fn internal_error() -> Self {
        crate::skirout::base::access::v1::permission::GetEntityPermissionResponse::InternalError(
            ::std::default::Default::default(),
        )
    }
}
impl crate::SkirResponse
    for crate::skirout::base::access::v1::sentinel::GetSentinelCredentialsResponse
{
    fn to_skir_bytes(&self) -> Vec<u8> {
        Self::serializer().to_bytes(self)
    }
    fn outcome(&self) -> crate::SkirResponseOutcome {
        match self {
            crate::skirout::base::access::v1::sentinel::GetSentinelCredentialsResponse::Success(
                _,
            ) => crate::SkirResponseOutcome::Success,
            // internal_error and the generated unknown variant
            _ => crate::SkirResponseOutcome::InternalError,
        }
    }
    fn variant_slug(&self) -> &'static str {
        match self {
            crate::skirout::base::access::v1::sentinel::GetSentinelCredentialsResponse::InternalError(_) => "internal-error",
            crate::skirout::base::access::v1::sentinel::GetSentinelCredentialsResponse::Success(_) => "success",
            _ => "unknown",
        }
    }
    fn variant_message(&self) -> String {
        self.variant_slug().to_owned()
    }
    fn internal_error() -> Self {
        crate::skirout::base::access::v1::sentinel::GetSentinelCredentialsResponse::InternalError(
            ::std::default::Default::default(),
        )
    }
}
impl crate::SkirResponse
    for crate::skirout::base::editor::v1::authoring::QueryAuthoringStateResponse
{
    fn to_skir_bytes(&self) -> Vec<u8> {
        Self::serializer().to_bytes(self)
    }
    fn outcome(&self) -> crate::SkirResponseOutcome {
        match self {
            crate::skirout::base::editor::v1::authoring::QueryAuthoringStateResponse::State(_) => crate::SkirResponseOutcome::Success,
            crate::skirout::base::editor::v1::authoring::QueryAuthoringStateResponse::CatalogChangedError(_) => crate::SkirResponseOutcome::DomainError,
            // internal_error and the generated unknown variant
            _ => crate::SkirResponseOutcome::InternalError,
        }
    }
    fn variant_slug(&self) -> &'static str {
        match self {
            crate::skirout::base::editor::v1::authoring::QueryAuthoringStateResponse::State(_) => "state",
            crate::skirout::base::editor::v1::authoring::QueryAuthoringStateResponse::CatalogChangedError(_) => "catalog-changed-error",
            crate::skirout::base::editor::v1::authoring::QueryAuthoringStateResponse::InternalError(_) => "internal-error",
            _ => "unknown",
        }
    }
    fn variant_message(&self) -> String {
        self.variant_slug().to_owned()
    }
    fn internal_error() -> Self {
        crate::skirout::base::editor::v1::authoring::QueryAuthoringStateResponse::InternalError(
            ::std::default::Default::default(),
        )
    }
    fn domain_error_from_slug(slug: &str) -> Option<Self> {
        match slug {
            "catalog-changed-error" => Some(crate::skirout::base::editor::v1::authoring::QueryAuthoringStateResponse::CatalogChangedError(::std::default::Default::default())),
            _ => None,
        }
    }
}
impl crate::SkirResponse for crate::skirout::base::editor::v1::authoring::SearchAuthoringResponse {
    fn to_skir_bytes(&self) -> Vec<u8> {
        Self::serializer().to_bytes(self)
    }
    fn outcome(&self) -> crate::SkirResponseOutcome {
        match self {
            crate::skirout::base::editor::v1::authoring::SearchAuthoringResponse::Success(_) => crate::SkirResponseOutcome::Success,
            crate::skirout::base::editor::v1::authoring::SearchAuthoringResponse::InvalidError(_) | crate::skirout::base::editor::v1::authoring::SearchAuthoringResponse::CatalogChangedError(_) => crate::SkirResponseOutcome::DomainError,
            // internal_error and the generated unknown variant
            _ => crate::SkirResponseOutcome::InternalError,
        }
    }
    fn variant_slug(&self) -> &'static str {
        match self {
            crate::skirout::base::editor::v1::authoring::SearchAuthoringResponse::Success(_) => "success",
            crate::skirout::base::editor::v1::authoring::SearchAuthoringResponse::InvalidError(_) => "invalid-error",
            crate::skirout::base::editor::v1::authoring::SearchAuthoringResponse::CatalogChangedError(_) => "catalog-changed-error",
            crate::skirout::base::editor::v1::authoring::SearchAuthoringResponse::InternalError(_) => "internal-error",
            _ => "unknown",
        }
    }
    fn variant_message(&self) -> String {
        self.variant_slug().to_owned()
    }
    fn internal_error() -> Self {
        crate::skirout::base::editor::v1::authoring::SearchAuthoringResponse::InternalError(
            ::std::default::Default::default(),
        )
    }
    fn domain_error_from_slug(slug: &str) -> Option<Self> {
        match slug {
            "invalid-error" => Some(crate::skirout::base::editor::v1::authoring::SearchAuthoringResponse::InvalidError(::std::default::Default::default())),
            "catalog-changed-error" => Some(crate::skirout::base::editor::v1::authoring::SearchAuthoringResponse::CatalogChangedError(::std::default::Default::default())),
            _ => None,
        }
    }
}
impl crate::SkirResponse
    for crate::skirout::base::editor::v1::authoring::CommitPreparedEditResponse
{
    fn to_skir_bytes(&self) -> Vec<u8> {
        Self::serializer().to_bytes(self)
    }
    fn outcome(&self) -> crate::SkirResponseOutcome {
        match self {
            crate::skirout::base::editor::v1::authoring::CommitPreparedEditResponse::Committed => crate::SkirResponseOutcome::Success,
            crate::skirout::base::editor::v1::authoring::CommitPreparedEditResponse::ConflictError(_) | crate::skirout::base::editor::v1::authoring::CommitPreparedEditResponse::RejectedError(_) | crate::skirout::base::editor::v1::authoring::CommitPreparedEditResponse::CatalogChangedError(_) => crate::SkirResponseOutcome::DomainError,
            // internal_error and the generated unknown variant
            _ => crate::SkirResponseOutcome::InternalError,
        }
    }
    fn variant_slug(&self) -> &'static str {
        match self {
            crate::skirout::base::editor::v1::authoring::CommitPreparedEditResponse::Committed => "committed",
            crate::skirout::base::editor::v1::authoring::CommitPreparedEditResponse::ConflictError(_) => "conflict-error",
            crate::skirout::base::editor::v1::authoring::CommitPreparedEditResponse::RejectedError(_) => "rejected-error",
            crate::skirout::base::editor::v1::authoring::CommitPreparedEditResponse::CatalogChangedError(_) => "catalog-changed-error",
            crate::skirout::base::editor::v1::authoring::CommitPreparedEditResponse::InternalError(_) => "internal-error",
            _ => "unknown",
        }
    }
    fn variant_message(&self) -> String {
        self.variant_slug().to_owned()
    }
    fn internal_error() -> Self {
        crate::skirout::base::editor::v1::authoring::CommitPreparedEditResponse::InternalError(
            ::std::default::Default::default(),
        )
    }
    fn domain_error_from_slug(slug: &str) -> Option<Self> {
        match slug {
            "conflict-error" => Some(crate::skirout::base::editor::v1::authoring::CommitPreparedEditResponse::ConflictError(::std::default::Default::default())),
            "rejected-error" => Some(crate::skirout::base::editor::v1::authoring::CommitPreparedEditResponse::RejectedError(::std::default::Default::default())),
            "catalog-changed-error" => Some(crate::skirout::base::editor::v1::authoring::CommitPreparedEditResponse::CatalogChangedError(::std::default::Default::default())),
            _ => None,
        }
    }
}
impl crate::SkirResponse
    for crate::skirout::base::editor::v1::authoring::PreviewTypeArgumentChangeResponse
{
    fn to_skir_bytes(&self) -> Vec<u8> {
        Self::serializer().to_bytes(self)
    }
    fn outcome(&self) -> crate::SkirResponseOutcome {
        match self {
            crate::skirout::base::editor::v1::authoring::PreviewTypeArgumentChangeResponse::Ready(_) | crate::skirout::base::editor::v1::authoring::PreviewTypeArgumentChangeResponse::Incomplete(_) => crate::SkirResponseOutcome::Success,
            crate::skirout::base::editor::v1::authoring::PreviewTypeArgumentChangeResponse::InvalidArgumentsError(_) | crate::skirout::base::editor::v1::authoring::PreviewTypeArgumentChangeResponse::RejectedError(_) => crate::SkirResponseOutcome::DomainError,
            // internal_error and the generated unknown variant
            _ => crate::SkirResponseOutcome::InternalError,
        }
    }
    fn variant_slug(&self) -> &'static str {
        match self {
            crate::skirout::base::editor::v1::authoring::PreviewTypeArgumentChangeResponse::Ready(_) => "ready",
            crate::skirout::base::editor::v1::authoring::PreviewTypeArgumentChangeResponse::InvalidArgumentsError(_) => "invalid-arguments-error",
            crate::skirout::base::editor::v1::authoring::PreviewTypeArgumentChangeResponse::Incomplete(_) => "incomplete",
            crate::skirout::base::editor::v1::authoring::PreviewTypeArgumentChangeResponse::RejectedError(_) => "rejected-error",
            crate::skirout::base::editor::v1::authoring::PreviewTypeArgumentChangeResponse::InternalError(_) => "internal-error",
            _ => "unknown",
        }
    }
    fn variant_message(&self) -> String {
        self.variant_slug().to_owned()
    }
    fn internal_error() -> Self {
        crate::skirout::base::editor::v1::authoring::PreviewTypeArgumentChangeResponse::InternalError(::std::default::Default::default())
    }
    fn domain_error_from_slug(slug: &str) -> Option<Self> {
        match slug {
            "invalid-arguments-error" => Some(crate::skirout::base::editor::v1::authoring::PreviewTypeArgumentChangeResponse::InvalidArgumentsError(::std::default::Default::default())),
            "rejected-error" => Some(crate::skirout::base::editor::v1::authoring::PreviewTypeArgumentChangeResponse::RejectedError(::std::default::Default::default())),
            _ => None,
        }
    }
}
impl crate::SkirResponse
    for crate::skirout::base::editor::v1::authoring::PrepareTypeArgumentChangeResponse
{
    fn to_skir_bytes(&self) -> Vec<u8> {
        Self::serializer().to_bytes(self)
    }
    fn outcome(&self) -> crate::SkirResponseOutcome {
        match self {
            crate::skirout::base::editor::v1::authoring::PrepareTypeArgumentChangeResponse::Prepared(_) | crate::skirout::base::editor::v1::authoring::PrepareTypeArgumentChangeResponse::NeedsInput(_) => crate::SkirResponseOutcome::Success,
            crate::skirout::base::editor::v1::authoring::PrepareTypeArgumentChangeResponse::RejectedError(_) => crate::SkirResponseOutcome::DomainError,
            // internal_error and the generated unknown variant
            _ => crate::SkirResponseOutcome::InternalError,
        }
    }
    fn variant_slug(&self) -> &'static str {
        match self {
            crate::skirout::base::editor::v1::authoring::PrepareTypeArgumentChangeResponse::Prepared(_) => "prepared",
            crate::skirout::base::editor::v1::authoring::PrepareTypeArgumentChangeResponse::NeedsInput(_) => "needs-input",
            crate::skirout::base::editor::v1::authoring::PrepareTypeArgumentChangeResponse::RejectedError(_) => "rejected-error",
            crate::skirout::base::editor::v1::authoring::PrepareTypeArgumentChangeResponse::InternalError(_) => "internal-error",
            _ => "unknown",
        }
    }
    fn variant_message(&self) -> String {
        self.variant_slug().to_owned()
    }
    fn internal_error() -> Self {
        crate::skirout::base::editor::v1::authoring::PrepareTypeArgumentChangeResponse::InternalError(::std::default::Default::default())
    }
    fn domain_error_from_slug(slug: &str) -> Option<Self> {
        match slug {
            "rejected-error" => Some(crate::skirout::base::editor::v1::authoring::PrepareTypeArgumentChangeResponse::RejectedError(::std::default::Default::default())),
            _ => None,
        }
    }
}
impl crate::SkirResponse for crate::skirout::base::editor::v1::capability::ComputationResult {
    fn to_skir_bytes(&self) -> Vec<u8> {
        Self::serializer().to_bytes(self)
    }
    fn outcome(&self) -> crate::SkirResponseOutcome {
        match self {
            crate::skirout::base::editor::v1::capability::ComputationResult::Success(_) => crate::SkirResponseOutcome::Success,
            crate::skirout::base::editor::v1::capability::ComputationResult::InvalidError(_) | crate::skirout::base::editor::v1::capability::ComputationResult::UnavailableError(_) | crate::skirout::base::editor::v1::capability::ComputationResult::PermissionDeniedError(_) | crate::skirout::base::editor::v1::capability::ComputationResult::StaleGenerationError(_) => crate::SkirResponseOutcome::DomainError,
            // internal_error and the generated unknown variant
            _ => crate::SkirResponseOutcome::InternalError,
        }
    }
    fn variant_slug(&self) -> &'static str {
        match self {
            crate::skirout::base::editor::v1::capability::ComputationResult::Success(_) => "success",
            crate::skirout::base::editor::v1::capability::ComputationResult::InvalidError(_) => "invalid-error",
            crate::skirout::base::editor::v1::capability::ComputationResult::UnavailableError(_) => "unavailable-error",
            crate::skirout::base::editor::v1::capability::ComputationResult::PermissionDeniedError(_) => "permission-denied-error",
            crate::skirout::base::editor::v1::capability::ComputationResult::StaleGenerationError(_) => "stale-generation-error",
            crate::skirout::base::editor::v1::capability::ComputationResult::InternalError(_) => "internal-error",
            _ => "unknown",
        }
    }
    fn variant_message(&self) -> String {
        self.variant_slug().to_owned()
    }
    fn internal_error() -> Self {
        crate::skirout::base::editor::v1::capability::ComputationResult::InternalError(
            ::std::default::Default::default(),
        )
    }
    fn domain_error_from_slug(slug: &str) -> Option<Self> {
        match slug {
            "invalid-error" => Some(crate::skirout::base::editor::v1::capability::ComputationResult::InvalidError(::std::default::Default::default())),
            "unavailable-error" => Some(crate::skirout::base::editor::v1::capability::ComputationResult::UnavailableError(::std::default::Default::default())),
            "permission-denied-error" => Some(crate::skirout::base::editor::v1::capability::ComputationResult::PermissionDeniedError(::std::default::Default::default())),
            "stale-generation-error" => Some(crate::skirout::base::editor::v1::capability::ComputationResult::StaleGenerationError(::std::default::Default::default())),
            _ => None,
        }
    }
}
impl crate::SkirResponse for crate::skirout::base::editor::v1::capability::CommandResult {
    fn to_skir_bytes(&self) -> Vec<u8> {
        Self::serializer().to_bytes(self)
    }
    fn outcome(&self) -> crate::SkirResponseOutcome {
        match self {
            crate::skirout::base::editor::v1::capability::CommandResult::Success(_) => {
                crate::SkirResponseOutcome::Success
            }
            crate::skirout::base::editor::v1::capability::CommandResult::InvalidError(_)
            | crate::skirout::base::editor::v1::capability::CommandResult::UnavailableError(_)
            | crate::skirout::base::editor::v1::capability::CommandResult::PermissionDeniedError(
                _,
            )
            | crate::skirout::base::editor::v1::capability::CommandResult::StaleGenerationError(
                _,
            ) => crate::SkirResponseOutcome::DomainError,
            // internal_error and the generated unknown variant
            _ => crate::SkirResponseOutcome::InternalError,
        }
    }
    fn variant_slug(&self) -> &'static str {
        match self {
            crate::skirout::base::editor::v1::capability::CommandResult::Success(_) => "success",
            crate::skirout::base::editor::v1::capability::CommandResult::InvalidError(_) => {
                "invalid-error"
            }
            crate::skirout::base::editor::v1::capability::CommandResult::UnavailableError(_) => {
                "unavailable-error"
            }
            crate::skirout::base::editor::v1::capability::CommandResult::PermissionDeniedError(
                _,
            ) => "permission-denied-error",
            crate::skirout::base::editor::v1::capability::CommandResult::StaleGenerationError(
                _,
            ) => "stale-generation-error",
            crate::skirout::base::editor::v1::capability::CommandResult::InternalError(_) => {
                "internal-error"
            }
            _ => "unknown",
        }
    }
    fn variant_message(&self) -> String {
        self.variant_slug().to_owned()
    }
    fn internal_error() -> Self {
        crate::skirout::base::editor::v1::capability::CommandResult::InternalError(
            ::std::default::Default::default(),
        )
    }
    fn domain_error_from_slug(slug: &str) -> Option<Self> {
        match slug {
            "invalid-error" => Some(
                crate::skirout::base::editor::v1::capability::CommandResult::InvalidError(
                    ::std::default::Default::default(),
                ),
            ),
            "unavailable-error" => Some(
                crate::skirout::base::editor::v1::capability::CommandResult::UnavailableError(
                    ::std::default::Default::default(),
                ),
            ),
            "permission-denied-error" => Some(
                crate::skirout::base::editor::v1::capability::CommandResult::PermissionDeniedError(
                    ::std::default::Default::default(),
                ),
            ),
            "stale-generation-error" => Some(
                crate::skirout::base::editor::v1::capability::CommandResult::StaleGenerationError(
                    ::std::default::Default::default(),
                ),
            ),
            _ => None,
        }
    }
}
impl crate::SkirResponse for crate::skirout::base::editor::v1::catalog::CatalogFetchResult {
    fn to_skir_bytes(&self) -> Vec<u8> {
        Self::serializer().to_bytes(self)
    }
    fn outcome(&self) -> crate::SkirResponseOutcome {
        match self {
            crate::skirout::base::editor::v1::catalog::CatalogFetchResult::Catalog(_) => crate::SkirResponseOutcome::Success,
            crate::skirout::base::editor::v1::catalog::CatalogFetchResult::GenerationChangedError(_) => crate::SkirResponseOutcome::DomainError,
            // internal_error and the generated unknown variant
            _ => crate::SkirResponseOutcome::InternalError,
        }
    }
    fn variant_slug(&self) -> &'static str {
        match self {
            crate::skirout::base::editor::v1::catalog::CatalogFetchResult::Catalog(_) => "catalog",
            crate::skirout::base::editor::v1::catalog::CatalogFetchResult::GenerationChangedError(_) => "generation-changed-error",
            crate::skirout::base::editor::v1::catalog::CatalogFetchResult::InternalError(_) => "internal-error",
            _ => "unknown",
        }
    }
    fn variant_message(&self) -> String {
        self.variant_slug().to_owned()
    }
    fn internal_error() -> Self {
        crate::skirout::base::editor::v1::catalog::CatalogFetchResult::InternalError(
            ::std::default::Default::default(),
        )
    }
    fn domain_error_from_slug(slug: &str) -> Option<Self> {
        match slug {
            "generation-changed-error" => Some(crate::skirout::base::editor::v1::catalog::CatalogFetchResult::GenerationChangedError(::std::default::Default::default())),
            _ => None,
        }
    }
}
impl crate::SkirResponse for crate::skirout::base::editor::v1::catalog::WatchEditorCatalogResponse {
    fn to_skir_bytes(&self) -> Vec<u8> {
        Self::serializer().to_bytes(self)
    }
    fn outcome(&self) -> crate::SkirResponseOutcome {
        match self {
            crate::skirout::base::editor::v1::catalog::WatchEditorCatalogResponse::Invalidated(
                _,
            ) => crate::SkirResponseOutcome::Success,
            // internal_error and the generated unknown variant
            _ => crate::SkirResponseOutcome::InternalError,
        }
    }
    fn variant_slug(&self) -> &'static str {
        match self {
            crate::skirout::base::editor::v1::catalog::WatchEditorCatalogResponse::Invalidated(_) => "invalidated",
            crate::skirout::base::editor::v1::catalog::WatchEditorCatalogResponse::InternalError(_) => "internal-error",
            _ => "unknown",
        }
    }
    fn variant_message(&self) -> String {
        self.variant_slug().to_owned()
    }
    fn internal_error() -> Self {
        crate::skirout::base::editor::v1::catalog::WatchEditorCatalogResponse::InternalError(
            ::std::default::Default::default(),
        )
    }
}
impl crate::SkirResponse for crate::skirout::base::editor::v1::catalog::PrepareValueResult {
    fn to_skir_bytes(&self) -> Vec<u8> {
        Self::serializer().to_bytes(self)
    }
    fn outcome(&self) -> crate::SkirResponseOutcome {
        match self {
            crate::skirout::base::editor::v1::catalog::PrepareValueResult::Ready(_)
            | crate::skirout::base::editor::v1::catalog::PrepareValueResult::NeedsInput(_) => {
                crate::SkirResponseOutcome::Success
            }
            crate::skirout::base::editor::v1::catalog::PrepareValueResult::UnavailableError(_)
            | crate::skirout::base::editor::v1::catalog::PrepareValueResult::CatalogChangedError(
                _,
            ) => crate::SkirResponseOutcome::DomainError,
            // internal_error and the generated unknown variant
            _ => crate::SkirResponseOutcome::InternalError,
        }
    }
    fn variant_slug(&self) -> &'static str {
        match self {
            crate::skirout::base::editor::v1::catalog::PrepareValueResult::Ready(_) => "ready",
            crate::skirout::base::editor::v1::catalog::PrepareValueResult::NeedsInput(_) => {
                "needs-input"
            }
            crate::skirout::base::editor::v1::catalog::PrepareValueResult::UnavailableError(_) => {
                "unavailable-error"
            }
            crate::skirout::base::editor::v1::catalog::PrepareValueResult::CatalogChangedError(
                _,
            ) => "catalog-changed-error",
            crate::skirout::base::editor::v1::catalog::PrepareValueResult::InternalError(_) => {
                "internal-error"
            }
            _ => "unknown",
        }
    }
    fn variant_message(&self) -> String {
        self.variant_slug().to_owned()
    }
    fn internal_error() -> Self {
        crate::skirout::base::editor::v1::catalog::PrepareValueResult::InternalError(
            ::std::default::Default::default(),
        )
    }
    fn domain_error_from_slug(slug: &str) -> Option<Self> {
        match slug {
            "unavailable-error" => Some(
                crate::skirout::base::editor::v1::catalog::PrepareValueResult::UnavailableError(
                    ::std::default::Default::default(),
                ),
            ),
            "catalog-changed-error" => Some(
                crate::skirout::base::editor::v1::catalog::PrepareValueResult::CatalogChangedError(
                    ::std::default::Default::default(),
                ),
            ),
            _ => None,
        }
    }
}
impl crate::SkirResponse
    for crate::skirout::base::editor::v1::compiled_content::QueryPublishedContentResponse
{
    fn to_skir_bytes(&self) -> Vec<u8> {
        Self::serializer().to_bytes(self)
    }
    fn outcome(&self) -> crate::SkirResponseOutcome {
        match self {
            crate::skirout::base::editor::v1::compiled_content::QueryPublishedContentResponse::Content(_) | crate::skirout::base::editor::v1::compiled_content::QueryPublishedContentResponse::Absent(_) => crate::SkirResponseOutcome::Success,
            // internal_error and the generated unknown variant
            _ => crate::SkirResponseOutcome::InternalError,
        }
    }
    fn variant_slug(&self) -> &'static str {
        match self {
            crate::skirout::base::editor::v1::compiled_content::QueryPublishedContentResponse::Content(_) => "content",
            crate::skirout::base::editor::v1::compiled_content::QueryPublishedContentResponse::Absent(_) => "absent",
            crate::skirout::base::editor::v1::compiled_content::QueryPublishedContentResponse::InternalError(_) => "internal-error",
            _ => "unknown",
        }
    }
    fn variant_message(&self) -> String {
        self.variant_slug().to_owned()
    }
    fn internal_error() -> Self {
        crate::skirout::base::editor::v1::compiled_content::QueryPublishedContentResponse::InternalError(::std::default::Default::default())
    }
}
impl crate::SkirResponse
    for crate::skirout::base::editor::v1::compiled_content::QueryCompiledResourceStatusResponse
{
    fn to_skir_bytes(&self) -> Vec<u8> {
        Self::serializer().to_bytes(self)
    }
    fn outcome(&self) -> crate::SkirResponseOutcome {
        match self {
            crate::skirout::base::editor::v1::compiled_content::QueryCompiledResourceStatusResponse::Success(_) => crate::SkirResponseOutcome::Success,
            // internal_error and the generated unknown variant
            _ => crate::SkirResponseOutcome::InternalError,
        }
    }
    fn variant_slug(&self) -> &'static str {
        match self {
            crate::skirout::base::editor::v1::compiled_content::QueryCompiledResourceStatusResponse::Success(_) => "success",
            crate::skirout::base::editor::v1::compiled_content::QueryCompiledResourceStatusResponse::InternalError(_) => "internal-error",
            _ => "unknown",
        }
    }
    fn variant_message(&self) -> String {
        self.variant_slug().to_owned()
    }
    fn internal_error() -> Self {
        crate::skirout::base::editor::v1::compiled_content::QueryCompiledResourceStatusResponse::InternalError(::std::default::Default::default())
    }
}
impl crate::SkirResponse
    for crate::skirout::base::editor::v1::publication::PublishAuthoringResponse
{
    fn to_skir_bytes(&self) -> Vec<u8> {
        Self::serializer().to_bytes(self)
    }
    fn outcome(&self) -> crate::SkirResponseOutcome {
        match self {
            crate::skirout::base::editor::v1::publication::PublishAuthoringResponse::Publishing | crate::skirout::base::editor::v1::publication::PublishAuthoringResponse::Activated(_) | crate::skirout::base::editor::v1::publication::PublishAuthoringResponse::NoChanges => crate::SkirResponseOutcome::Success,
            crate::skirout::base::editor::v1::publication::PublishAuthoringResponse::BlockedError(_) | crate::skirout::base::editor::v1::publication::PublishAuthoringResponse::InterruptedError(_) | crate::skirout::base::editor::v1::publication::PublishAuthoringResponse::CandidateChangedError(_) => crate::SkirResponseOutcome::DomainError,
            // internal_error and the generated unknown variant
            _ => crate::SkirResponseOutcome::InternalError,
        }
    }
    fn variant_slug(&self) -> &'static str {
        match self {
            crate::skirout::base::editor::v1::publication::PublishAuthoringResponse::Publishing => "publishing",
            crate::skirout::base::editor::v1::publication::PublishAuthoringResponse::Activated(_) => "activated",
            crate::skirout::base::editor::v1::publication::PublishAuthoringResponse::BlockedError(_) => "blocked-error",
            crate::skirout::base::editor::v1::publication::PublishAuthoringResponse::InterruptedError(_) => "interrupted-error",
            crate::skirout::base::editor::v1::publication::PublishAuthoringResponse::NoChanges => "no-changes",
            crate::skirout::base::editor::v1::publication::PublishAuthoringResponse::CandidateChangedError(_) => "candidate-changed-error",
            crate::skirout::base::editor::v1::publication::PublishAuthoringResponse::InternalError(_) => "internal-error",
            _ => "unknown",
        }
    }
    fn variant_message(&self) -> String {
        self.variant_slug().to_owned()
    }
    fn internal_error() -> Self {
        crate::skirout::base::editor::v1::publication::PublishAuthoringResponse::InternalError(
            ::std::default::Default::default(),
        )
    }
    fn domain_error_from_slug(slug: &str) -> Option<Self> {
        match slug {
            "blocked-error" => Some(crate::skirout::base::editor::v1::publication::PublishAuthoringResponse::BlockedError(::std::default::Default::default())),
            "interrupted-error" => Some(crate::skirout::base::editor::v1::publication::PublishAuthoringResponse::InterruptedError(::std::default::Default::default())),
            "candidate-changed-error" => Some(crate::skirout::base::editor::v1::publication::PublishAuthoringResponse::CandidateChangedError(::std::default::Default::default())),
            _ => None,
        }
    }
}
impl crate::SkirResponse
    for crate::skirout::base::editor::v1::publication::WatchPublicationResponse
{
    fn to_skir_bytes(&self) -> Vec<u8> {
        Self::serializer().to_bytes(self)
    }
    fn outcome(&self) -> crate::SkirResponseOutcome {
        match self {
            crate::skirout::base::editor::v1::publication::WatchPublicationResponse::ViewChanged(_) => crate::SkirResponseOutcome::Success,
            // internal_error and the generated unknown variant
            _ => crate::SkirResponseOutcome::InternalError,
        }
    }
    fn variant_slug(&self) -> &'static str {
        match self {
            crate::skirout::base::editor::v1::publication::WatchPublicationResponse::ViewChanged(_) => "view-changed",
            crate::skirout::base::editor::v1::publication::WatchPublicationResponse::InternalError(_) => "internal-error",
            _ => "unknown",
        }
    }
    fn variant_message(&self) -> String {
        self.variant_slug().to_owned()
    }
    fn internal_error() -> Self {
        crate::skirout::base::editor::v1::publication::WatchPublicationResponse::InternalError(
            ::std::default::Default::default(),
        )
    }
}
impl crate::SkirResponse
    for crate::skirout::base::editor::v1::publication::QueryPublicationViewResponse
{
    fn to_skir_bytes(&self) -> Vec<u8> {
        Self::serializer().to_bytes(self)
    }
    fn outcome(&self) -> crate::SkirResponseOutcome {
        match self {
            crate::skirout::base::editor::v1::publication::QueryPublicationViewResponse::View(_) => crate::SkirResponseOutcome::Success,
            crate::skirout::base::editor::v1::publication::QueryPublicationViewResponse::ViewChangedError(_) => crate::SkirResponseOutcome::DomainError,
            // internal_error and the generated unknown variant
            _ => crate::SkirResponseOutcome::InternalError,
        }
    }
    fn variant_slug(&self) -> &'static str {
        match self {
            crate::skirout::base::editor::v1::publication::QueryPublicationViewResponse::View(_) => "view",
            crate::skirout::base::editor::v1::publication::QueryPublicationViewResponse::ViewChangedError(_) => "view-changed-error",
            crate::skirout::base::editor::v1::publication::QueryPublicationViewResponse::InternalError(_) => "internal-error",
            _ => "unknown",
        }
    }
    fn variant_message(&self) -> String {
        self.variant_slug().to_owned()
    }
    fn internal_error() -> Self {
        crate::skirout::base::editor::v1::publication::QueryPublicationViewResponse::InternalError(
            ::std::default::Default::default(),
        )
    }
    fn domain_error_from_slug(slug: &str) -> Option<Self> {
        match slug {
            "view-changed-error" => Some(crate::skirout::base::editor::v1::publication::QueryPublicationViewResponse::ViewChangedError(::std::default::Default::default())),
            _ => None,
        }
    }
}
impl crate::SkirResponse
    for crate::skirout::base::editor::v1::resource_operations::ResolveResourceOperationsResult
{
    fn to_skir_bytes(&self) -> Vec<u8> {
        Self::serializer().to_bytes(self)
    }
    fn outcome(&self) -> crate::SkirResponseOutcome {
        match self {
            crate::skirout::base::editor::v1::resource_operations::ResolveResourceOperationsResult::Resolved(_) => crate::SkirResponseOutcome::Success,
            crate::skirout::base::editor::v1::resource_operations::ResolveResourceOperationsResult::StaleObservationError(_) | crate::skirout::base::editor::v1::resource_operations::ResolveResourceOperationsResult::InvalidError(_) | crate::skirout::base::editor::v1::resource_operations::ResolveResourceOperationsResult::CatalogChangedError(_) | crate::skirout::base::editor::v1::resource_operations::ResolveResourceOperationsResult::PermissionDeniedError(_) | crate::skirout::base::editor::v1::resource_operations::ResolveResourceOperationsResult::FailedError(_) => crate::SkirResponseOutcome::DomainError,
            // internal_error and the generated unknown variant
            _ => crate::SkirResponseOutcome::InternalError,
        }
    }
    fn variant_slug(&self) -> &'static str {
        match self {
            crate::skirout::base::editor::v1::resource_operations::ResolveResourceOperationsResult::Resolved(_) => "resolved",
            crate::skirout::base::editor::v1::resource_operations::ResolveResourceOperationsResult::StaleObservationError(_) => "stale-observation-error",
            crate::skirout::base::editor::v1::resource_operations::ResolveResourceOperationsResult::InvalidError(_) => "invalid-error",
            crate::skirout::base::editor::v1::resource_operations::ResolveResourceOperationsResult::CatalogChangedError(_) => "catalog-changed-error",
            crate::skirout::base::editor::v1::resource_operations::ResolveResourceOperationsResult::PermissionDeniedError(_) => "permission-denied-error",
            crate::skirout::base::editor::v1::resource_operations::ResolveResourceOperationsResult::FailedError(_) => "failed-error",
            crate::skirout::base::editor::v1::resource_operations::ResolveResourceOperationsResult::InternalError(_) => "internal-error",
            _ => "unknown",
        }
    }
    fn variant_message(&self) -> String {
        self.variant_slug().to_owned()
    }
    fn internal_error() -> Self {
        crate::skirout::base::editor::v1::resource_operations::ResolveResourceOperationsResult::InternalError(::std::default::Default::default())
    }
    fn domain_error_from_slug(slug: &str) -> Option<Self> {
        match slug {
            "stale-observation-error" => Some(crate::skirout::base::editor::v1::resource_operations::ResolveResourceOperationsResult::StaleObservationError(::std::default::Default::default())),
            "invalid-error" => Some(crate::skirout::base::editor::v1::resource_operations::ResolveResourceOperationsResult::InvalidError(::std::default::Default::default())),
            "catalog-changed-error" => Some(crate::skirout::base::editor::v1::resource_operations::ResolveResourceOperationsResult::CatalogChangedError(::std::default::Default::default())),
            "permission-denied-error" => Some(crate::skirout::base::editor::v1::resource_operations::ResolveResourceOperationsResult::PermissionDeniedError(::std::default::Default::default())),
            "failed-error" => Some(crate::skirout::base::editor::v1::resource_operations::ResolveResourceOperationsResult::FailedError(::std::default::Default::default())),
            _ => None,
        }
    }
}
impl crate::SkirResponse
    for crate::skirout::base::editor::v1::resource_operations::AuthoringActionResult
{
    fn to_skir_bytes(&self) -> Vec<u8> {
        Self::serializer().to_bytes(self)
    }
    fn outcome(&self) -> crate::SkirResponseOutcome {
        match self {
            crate::skirout::base::editor::v1::resource_operations::AuthoringActionResult::NeedsInput(_) | crate::skirout::base::editor::v1::resource_operations::AuthoringActionResult::Preview(_) => crate::SkirResponseOutcome::Success,
            crate::skirout::base::editor::v1::resource_operations::AuthoringActionResult::StaleObservationError(_) | crate::skirout::base::editor::v1::resource_operations::AuthoringActionResult::InvalidError(_) | crate::skirout::base::editor::v1::resource_operations::AuthoringActionResult::UnavailableError(_) | crate::skirout::base::editor::v1::resource_operations::AuthoringActionResult::CatalogChangedError(_) | crate::skirout::base::editor::v1::resource_operations::AuthoringActionResult::PermissionDeniedError(_) | crate::skirout::base::editor::v1::resource_operations::AuthoringActionResult::FailedError(_) => crate::SkirResponseOutcome::DomainError,
            // internal_error and the generated unknown variant
            _ => crate::SkirResponseOutcome::InternalError,
        }
    }
    fn variant_slug(&self) -> &'static str {
        match self {
            crate::skirout::base::editor::v1::resource_operations::AuthoringActionResult::NeedsInput(_) => "needs-input",
            crate::skirout::base::editor::v1::resource_operations::AuthoringActionResult::Preview(_) => "preview",
            crate::skirout::base::editor::v1::resource_operations::AuthoringActionResult::StaleObservationError(_) => "stale-observation-error",
            crate::skirout::base::editor::v1::resource_operations::AuthoringActionResult::InvalidError(_) => "invalid-error",
            crate::skirout::base::editor::v1::resource_operations::AuthoringActionResult::UnavailableError(_) => "unavailable-error",
            crate::skirout::base::editor::v1::resource_operations::AuthoringActionResult::CatalogChangedError(_) => "catalog-changed-error",
            crate::skirout::base::editor::v1::resource_operations::AuthoringActionResult::PermissionDeniedError(_) => "permission-denied-error",
            crate::skirout::base::editor::v1::resource_operations::AuthoringActionResult::FailedError(_) => "failed-error",
            crate::skirout::base::editor::v1::resource_operations::AuthoringActionResult::InternalError(_) => "internal-error",
            _ => "unknown",
        }
    }
    fn variant_message(&self) -> String {
        self.variant_slug().to_owned()
    }
    fn internal_error() -> Self {
        crate::skirout::base::editor::v1::resource_operations::AuthoringActionResult::InternalError(
            ::std::default::Default::default(),
        )
    }
    fn domain_error_from_slug(slug: &str) -> Option<Self> {
        match slug {
            "stale-observation-error" => Some(crate::skirout::base::editor::v1::resource_operations::AuthoringActionResult::StaleObservationError(::std::default::Default::default())),
            "invalid-error" => Some(crate::skirout::base::editor::v1::resource_operations::AuthoringActionResult::InvalidError(::std::default::Default::default())),
            "unavailable-error" => Some(crate::skirout::base::editor::v1::resource_operations::AuthoringActionResult::UnavailableError(::std::default::Default::default())),
            "catalog-changed-error" => Some(crate::skirout::base::editor::v1::resource_operations::AuthoringActionResult::CatalogChangedError(::std::default::Default::default())),
            "permission-denied-error" => Some(crate::skirout::base::editor::v1::resource_operations::AuthoringActionResult::PermissionDeniedError(::std::default::Default::default())),
            "failed-error" => Some(crate::skirout::base::editor::v1::resource_operations::AuthoringActionResult::FailedError(::std::default::Default::default())),
            _ => None,
        }
    }
}
impl crate::SkirResponse
    for crate::skirout::base::editor::v1::resource_operations::ResolveDropCandidatesResult
{
    fn to_skir_bytes(&self) -> Vec<u8> {
        Self::serializer().to_bytes(self)
    }
    fn outcome(&self) -> crate::SkirResponseOutcome {
        match self {
            crate::skirout::base::editor::v1::resource_operations::ResolveDropCandidatesResult::Resolved(_) => crate::SkirResponseOutcome::Success,
            crate::skirout::base::editor::v1::resource_operations::ResolveDropCandidatesResult::StaleObservationError(_) | crate::skirout::base::editor::v1::resource_operations::ResolveDropCandidatesResult::InvalidError(_) | crate::skirout::base::editor::v1::resource_operations::ResolveDropCandidatesResult::CatalogChangedError(_) | crate::skirout::base::editor::v1::resource_operations::ResolveDropCandidatesResult::PermissionDeniedError(_) | crate::skirout::base::editor::v1::resource_operations::ResolveDropCandidatesResult::FailedError(_) => crate::SkirResponseOutcome::DomainError,
            // internal_error and the generated unknown variant
            _ => crate::SkirResponseOutcome::InternalError,
        }
    }
    fn variant_slug(&self) -> &'static str {
        match self {
            crate::skirout::base::editor::v1::resource_operations::ResolveDropCandidatesResult::Resolved(_) => "resolved",
            crate::skirout::base::editor::v1::resource_operations::ResolveDropCandidatesResult::StaleObservationError(_) => "stale-observation-error",
            crate::skirout::base::editor::v1::resource_operations::ResolveDropCandidatesResult::InvalidError(_) => "invalid-error",
            crate::skirout::base::editor::v1::resource_operations::ResolveDropCandidatesResult::CatalogChangedError(_) => "catalog-changed-error",
            crate::skirout::base::editor::v1::resource_operations::ResolveDropCandidatesResult::PermissionDeniedError(_) => "permission-denied-error",
            crate::skirout::base::editor::v1::resource_operations::ResolveDropCandidatesResult::FailedError(_) => "failed-error",
            crate::skirout::base::editor::v1::resource_operations::ResolveDropCandidatesResult::InternalError(_) => "internal-error",
            _ => "unknown",
        }
    }
    fn variant_message(&self) -> String {
        self.variant_slug().to_owned()
    }
    fn internal_error() -> Self {
        crate::skirout::base::editor::v1::resource_operations::ResolveDropCandidatesResult::InternalError(::std::default::Default::default())
    }
    fn domain_error_from_slug(slug: &str) -> Option<Self> {
        match slug {
            "stale-observation-error" => Some(crate::skirout::base::editor::v1::resource_operations::ResolveDropCandidatesResult::StaleObservationError(::std::default::Default::default())),
            "invalid-error" => Some(crate::skirout::base::editor::v1::resource_operations::ResolveDropCandidatesResult::InvalidError(::std::default::Default::default())),
            "catalog-changed-error" => Some(crate::skirout::base::editor::v1::resource_operations::ResolveDropCandidatesResult::CatalogChangedError(::std::default::Default::default())),
            "permission-denied-error" => Some(crate::skirout::base::editor::v1::resource_operations::ResolveDropCandidatesResult::PermissionDeniedError(::std::default::Default::default())),
            "failed-error" => Some(crate::skirout::base::editor::v1::resource_operations::ResolveDropCandidatesResult::FailedError(::std::default::Default::default())),
            _ => None,
        }
    }
}
impl crate::SkirResponse
    for crate::skirout::base::editor::v1::search::RealmPresentationSearchUpdate
{
    fn to_skir_bytes(&self) -> Vec<u8> {
        Self::serializer().to_bytes(self)
    }
    fn outcome(&self) -> crate::SkirResponseOutcome {
        match self {
            crate::skirout::base::editor::v1::search::RealmPresentationSearchUpdate::Snapshot(_) => crate::SkirResponseOutcome::Success,
            crate::skirout::base::editor::v1::search::RealmPresentationSearchUpdate::UnavailableError(_) | crate::skirout::base::editor::v1::search::RealmPresentationSearchUpdate::StaleObservationError(_) => crate::SkirResponseOutcome::DomainError,
            // internal_error and the generated unknown variant
            _ => crate::SkirResponseOutcome::InternalError,
        }
    }
    fn variant_slug(&self) -> &'static str {
        match self {
            crate::skirout::base::editor::v1::search::RealmPresentationSearchUpdate::Snapshot(_) => "snapshot",
            crate::skirout::base::editor::v1::search::RealmPresentationSearchUpdate::UnavailableError(_) => "unavailable-error",
            crate::skirout::base::editor::v1::search::RealmPresentationSearchUpdate::StaleObservationError(_) => "stale-observation-error",
            crate::skirout::base::editor::v1::search::RealmPresentationSearchUpdate::InternalError(_) => "internal-error",
            _ => "unknown",
        }
    }
    fn variant_message(&self) -> String {
        self.variant_slug().to_owned()
    }
    fn internal_error() -> Self {
        crate::skirout::base::editor::v1::search::RealmPresentationSearchUpdate::InternalError(
            ::std::default::Default::default(),
        )
    }
    fn domain_error_from_slug(slug: &str) -> Option<Self> {
        match slug {
            "unavailable-error" => Some(crate::skirout::base::editor::v1::search::RealmPresentationSearchUpdate::UnavailableError(::std::default::Default::default())),
            "stale-observation-error" => Some(crate::skirout::base::editor::v1::search::RealmPresentationSearchUpdate::StaleObservationError(::std::default::Default::default())),
            _ => None,
        }
    }
}
impl crate::SkirResponse
    for crate::skirout::base::editor::v1::search::CancelRealmPresentationSearchResult
{
    fn to_skir_bytes(&self) -> Vec<u8> {
        Self::serializer().to_bytes(self)
    }
    fn outcome(&self) -> crate::SkirResponseOutcome {
        match self {
            crate::skirout::base::editor::v1::search::CancelRealmPresentationSearchResult::Canceled => crate::SkirResponseOutcome::Success,
            crate::skirout::base::editor::v1::search::CancelRealmPresentationSearchResult::NotFoundError => crate::SkirResponseOutcome::DomainError,
            // internal_error and the generated unknown variant
            _ => crate::SkirResponseOutcome::InternalError,
        }
    }
    fn variant_slug(&self) -> &'static str {
        match self {
            crate::skirout::base::editor::v1::search::CancelRealmPresentationSearchResult::Canceled => "canceled",
            crate::skirout::base::editor::v1::search::CancelRealmPresentationSearchResult::NotFoundError => "not-found-error",
            crate::skirout::base::editor::v1::search::CancelRealmPresentationSearchResult::InternalError(_) => "internal-error",
            _ => "unknown",
        }
    }
    fn variant_message(&self) -> String {
        self.variant_slug().to_owned()
    }
    fn internal_error() -> Self {
        crate::skirout::base::editor::v1::search::CancelRealmPresentationSearchResult::InternalError(
            ::std::default::Default::default(),
        )
    }
    fn domain_error_from_slug(slug: &str) -> Option<Self> {
        match slug {
            "not-found-error" => Some(crate::skirout::base::editor::v1::search::CancelRealmPresentationSearchResult::NotFoundError),
            _ => None,
        }
    }
}
impl crate::SkirResponse
    for crate::skirout::base::organization::v1::join_codes::WatchOrganizationJoinCodesResponse
{
    fn to_skir_bytes(&self) -> Vec<u8> {
        Self::serializer().to_bytes(self)
    }
    fn outcome(&self) -> crate::SkirResponseOutcome {
        match self {
            crate::skirout::base::organization::v1::join_codes::WatchOrganizationJoinCodesResponse::Snapshot(_) | crate::skirout::base::organization::v1::join_codes::WatchOrganizationJoinCodesResponse::Changed(_) => crate::SkirResponseOutcome::Success,
            // internal_error and the generated unknown variant
            _ => crate::SkirResponseOutcome::InternalError,
        }
    }
    fn variant_slug(&self) -> &'static str {
        match self {
            crate::skirout::base::organization::v1::join_codes::WatchOrganizationJoinCodesResponse::InternalError(_) => "internal-error",
            crate::skirout::base::organization::v1::join_codes::WatchOrganizationJoinCodesResponse::Snapshot(_) => "snapshot",
            crate::skirout::base::organization::v1::join_codes::WatchOrganizationJoinCodesResponse::Changed(_) => "changed",
            _ => "unknown",
        }
    }
    fn variant_message(&self) -> String {
        self.variant_slug().to_owned()
    }
    fn internal_error() -> Self {
        crate::skirout::base::organization::v1::join_codes::WatchOrganizationJoinCodesResponse::InternalError(::std::default::Default::default())
    }
}
impl crate::SkirResponse
    for crate::skirout::base::organization::v1::join_codes::GenerateOrganizationJoinCodeResponse
{
    fn to_skir_bytes(&self) -> Vec<u8> {
        Self::serializer().to_bytes(self)
    }
    fn outcome(&self) -> crate::SkirResponseOutcome {
        match self {
            crate::skirout::base::organization::v1::join_codes::GenerateOrganizationJoinCodeResponse::Success(_) => crate::SkirResponseOutcome::Success,
            crate::skirout::base::organization::v1::join_codes::GenerateOrganizationJoinCodeResponse::RolesNotFoundError(_) | crate::skirout::base::organization::v1::join_codes::GenerateOrganizationJoinCodeResponse::RolesNotAssignableError(_) | crate::skirout::base::organization::v1::join_codes::GenerateOrganizationJoinCodeResponse::InvalidExpirationError(_) | crate::skirout::base::organization::v1::join_codes::GenerateOrganizationJoinCodeResponse::InvalidRecordIdError(_) => crate::SkirResponseOutcome::DomainError,
            // internal_error and the generated unknown variant
            _ => crate::SkirResponseOutcome::InternalError,
        }
    }
    fn variant_slug(&self) -> &'static str {
        match self {
            crate::skirout::base::organization::v1::join_codes::GenerateOrganizationJoinCodeResponse::InternalError(_) => "internal-error",
            crate::skirout::base::organization::v1::join_codes::GenerateOrganizationJoinCodeResponse::Success(_) => "success",
            crate::skirout::base::organization::v1::join_codes::GenerateOrganizationJoinCodeResponse::RolesNotFoundError(_) => "roles-not-found-error",
            crate::skirout::base::organization::v1::join_codes::GenerateOrganizationJoinCodeResponse::RolesNotAssignableError(_) => "roles-not-assignable-error",
            crate::skirout::base::organization::v1::join_codes::GenerateOrganizationJoinCodeResponse::InvalidExpirationError(_) => "invalid-expiration-error",
            crate::skirout::base::organization::v1::join_codes::GenerateOrganizationJoinCodeResponse::InvalidRecordIdError(_) => "invalid-record-id-error",
            _ => "unknown",
        }
    }
    fn variant_message(&self) -> String {
        match self {
            crate::skirout::base::organization::v1::join_codes::GenerateOrganizationJoinCodeResponse::RolesNotFoundError(_) => "Roles not found.".to_owned(),
            crate::skirout::base::organization::v1::join_codes::GenerateOrganizationJoinCodeResponse::RolesNotAssignableError(_) => "Roles not assignable.".to_owned(),
            crate::skirout::base::organization::v1::join_codes::GenerateOrganizationJoinCodeResponse::InvalidExpirationError(_) => "Invalid expiration duration.".to_owned(),
            crate::skirout::base::organization::v1::join_codes::GenerateOrganizationJoinCodeResponse::InvalidRecordIdError(_) => "Record IDs from an unexpected table.".to_owned(),
            other => other.variant_slug().to_owned(),
        }
    }
    fn internal_error() -> Self {
        crate::skirout::base::organization::v1::join_codes::GenerateOrganizationJoinCodeResponse::InternalError(::std::default::Default::default())
    }
    fn domain_error_from_slug(slug: &str) -> Option<Self> {
        match slug {
            "roles-not-found-error" => Some(crate::skirout::base::organization::v1::join_codes::GenerateOrganizationJoinCodeResponse::RolesNotFoundError(::std::default::Default::default())),
            "roles-not-assignable-error" => Some(crate::skirout::base::organization::v1::join_codes::GenerateOrganizationJoinCodeResponse::RolesNotAssignableError(::std::default::Default::default())),
            "invalid-expiration-error" => Some(crate::skirout::base::organization::v1::join_codes::GenerateOrganizationJoinCodeResponse::InvalidExpirationError(::std::default::Default::default())),
            "invalid-record-id-error" => Some(crate::skirout::base::organization::v1::join_codes::GenerateOrganizationJoinCodeResponse::InvalidRecordIdError(::std::default::Default::default())),
            _ => None,
        }
    }
}
impl crate::SkirResponse
    for crate::skirout::base::organization::v1::join_codes::RevokeOrganizationJoinCodeResponse
{
    fn to_skir_bytes(&self) -> Vec<u8> {
        Self::serializer().to_bytes(self)
    }
    fn outcome(&self) -> crate::SkirResponseOutcome {
        match self {
            crate::skirout::base::organization::v1::join_codes::RevokeOrganizationJoinCodeResponse::Success(_) => crate::SkirResponseOutcome::Success,
            crate::skirout::base::organization::v1::join_codes::RevokeOrganizationJoinCodeResponse::CodeNotFoundError(_) | crate::skirout::base::organization::v1::join_codes::RevokeOrganizationJoinCodeResponse::InvalidRecordIdError(_) => crate::SkirResponseOutcome::DomainError,
            // internal_error and the generated unknown variant
            _ => crate::SkirResponseOutcome::InternalError,
        }
    }
    fn variant_slug(&self) -> &'static str {
        match self {
            crate::skirout::base::organization::v1::join_codes::RevokeOrganizationJoinCodeResponse::InternalError(_) => "internal-error",
            crate::skirout::base::organization::v1::join_codes::RevokeOrganizationJoinCodeResponse::Success(_) => "success",
            crate::skirout::base::organization::v1::join_codes::RevokeOrganizationJoinCodeResponse::CodeNotFoundError(_) => "code-not-found-error",
            crate::skirout::base::organization::v1::join_codes::RevokeOrganizationJoinCodeResponse::InvalidRecordIdError(_) => "invalid-record-id-error",
            _ => "unknown",
        }
    }
    fn variant_message(&self) -> String {
        match self {
            crate::skirout::base::organization::v1::join_codes::RevokeOrganizationJoinCodeResponse::CodeNotFoundError(_) => "Join code not found.".to_owned(),
            crate::skirout::base::organization::v1::join_codes::RevokeOrganizationJoinCodeResponse::InvalidRecordIdError(_) => "Record IDs from an unexpected table.".to_owned(),
            other => other.variant_slug().to_owned(),
        }
    }
    fn internal_error() -> Self {
        crate::skirout::base::organization::v1::join_codes::RevokeOrganizationJoinCodeResponse::InternalError(::std::default::Default::default())
    }
    fn domain_error_from_slug(slug: &str) -> Option<Self> {
        match slug {
            "code-not-found-error" => Some(crate::skirout::base::organization::v1::join_codes::RevokeOrganizationJoinCodeResponse::CodeNotFoundError(::std::default::Default::default())),
            "invalid-record-id-error" => Some(crate::skirout::base::organization::v1::join_codes::RevokeOrganizationJoinCodeResponse::InvalidRecordIdError(::std::default::Default::default())),
            _ => None,
        }
    }
}
impl crate::SkirResponse
    for crate::skirout::base::organization::v1::join_request::WatchOrganizationJoinRequestsResponse
{
    fn to_skir_bytes(&self) -> Vec<u8> {
        Self::serializer().to_bytes(self)
    }
    fn outcome(&self) -> crate::SkirResponseOutcome {
        match self {
            crate::skirout::base::organization::v1::join_request::WatchOrganizationJoinRequestsResponse::Snapshot(_) | crate::skirout::base::organization::v1::join_request::WatchOrganizationJoinRequestsResponse::Changed(_) => crate::SkirResponseOutcome::Success,
            // internal_error and the generated unknown variant
            _ => crate::SkirResponseOutcome::InternalError,
        }
    }
    fn variant_slug(&self) -> &'static str {
        match self {
            crate::skirout::base::organization::v1::join_request::WatchOrganizationJoinRequestsResponse::InternalError(_) => "internal-error",
            crate::skirout::base::organization::v1::join_request::WatchOrganizationJoinRequestsResponse::Snapshot(_) => "snapshot",
            crate::skirout::base::organization::v1::join_request::WatchOrganizationJoinRequestsResponse::Changed(_) => "changed",
            _ => "unknown",
        }
    }
    fn variant_message(&self) -> String {
        self.variant_slug().to_owned()
    }
    fn internal_error() -> Self {
        crate::skirout::base::organization::v1::join_request::WatchOrganizationJoinRequestsResponse::InternalError(::std::default::Default::default())
    }
}
impl crate::SkirResponse for crate::skirout::base::organization::v1::join_request::ApproveOrganizationJoinRequestsResponse {
    fn to_skir_bytes(&self) -> Vec<u8> {
        Self::serializer().to_bytes(self)
    }
    fn outcome(&self) -> crate::SkirResponseOutcome {
        match self {
            crate::skirout::base::organization::v1::join_request::ApproveOrganizationJoinRequestsResponse::Success(_) => crate::SkirResponseOutcome::Success,
            crate::skirout::base::organization::v1::join_request::ApproveOrganizationJoinRequestsResponse::RequestNotFoundError(_) | crate::skirout::base::organization::v1::join_request::ApproveOrganizationJoinRequestsResponse::RolesNotFoundError(_) | crate::skirout::base::organization::v1::join_request::ApproveOrganizationJoinRequestsResponse::RolesNotAssignableError(_) | crate::skirout::base::organization::v1::join_request::ApproveOrganizationJoinRequestsResponse::RolesRequiredError(_) | crate::skirout::base::organization::v1::join_request::ApproveOrganizationJoinRequestsResponse::UserAlreadyMemberError(_) | crate::skirout::base::organization::v1::join_request::ApproveOrganizationJoinRequestsResponse::InvalidSelectionError(_) | crate::skirout::base::organization::v1::join_request::ApproveOrganizationJoinRequestsResponse::InvalidRecordIdError(_) => crate::SkirResponseOutcome::DomainError,
            // internal_error and the generated unknown variant
            _ => crate::SkirResponseOutcome::InternalError,
        }
    }
    fn variant_slug(&self) -> &'static str {
        match self {
            crate::skirout::base::organization::v1::join_request::ApproveOrganizationJoinRequestsResponse::InternalError(_) => "internal-error",
            crate::skirout::base::organization::v1::join_request::ApproveOrganizationJoinRequestsResponse::Success(_) => "success",
            crate::skirout::base::organization::v1::join_request::ApproveOrganizationJoinRequestsResponse::RequestNotFoundError(_) => "request-not-found-error",
            crate::skirout::base::organization::v1::join_request::ApproveOrganizationJoinRequestsResponse::RolesNotFoundError(_) => "roles-not-found-error",
            crate::skirout::base::organization::v1::join_request::ApproveOrganizationJoinRequestsResponse::RolesNotAssignableError(_) => "roles-not-assignable-error",
            crate::skirout::base::organization::v1::join_request::ApproveOrganizationJoinRequestsResponse::RolesRequiredError(_) => "roles-required-error",
            crate::skirout::base::organization::v1::join_request::ApproveOrganizationJoinRequestsResponse::UserAlreadyMemberError(_) => "user-already-member-error",
            crate::skirout::base::organization::v1::join_request::ApproveOrganizationJoinRequestsResponse::InvalidSelectionError(_) => "invalid-selection-error",
            crate::skirout::base::organization::v1::join_request::ApproveOrganizationJoinRequestsResponse::InvalidRecordIdError(_) => "invalid-record-id-error",
            _ => "unknown",
        }
    }
    fn variant_message(&self) -> String {
        match self {
            crate::skirout::base::organization::v1::join_request::ApproveOrganizationJoinRequestsResponse::RequestNotFoundError(_) => "Join requests not found.".to_owned(),
            crate::skirout::base::organization::v1::join_request::ApproveOrganizationJoinRequestsResponse::RolesNotFoundError(_) => "Roles not found.".to_owned(),
            crate::skirout::base::organization::v1::join_request::ApproveOrganizationJoinRequestsResponse::RolesNotAssignableError(_) => "Roles not assignable.".to_owned(),
            crate::skirout::base::organization::v1::join_request::ApproveOrganizationJoinRequestsResponse::RolesRequiredError(_) => "At least one role is required.".to_owned(),
            crate::skirout::base::organization::v1::join_request::ApproveOrganizationJoinRequestsResponse::UserAlreadyMemberError(_) => "Users are already members.".to_owned(),
            crate::skirout::base::organization::v1::join_request::ApproveOrganizationJoinRequestsResponse::InvalidSelectionError(_) => "Selection must contain distinct targets.".to_owned(),
            crate::skirout::base::organization::v1::join_request::ApproveOrganizationJoinRequestsResponse::InvalidRecordIdError(_) => "Record IDs from an unexpected table.".to_owned(),
            other => other.variant_slug().to_owned(),
        }
    }
    fn internal_error() -> Self {
        crate::skirout::base::organization::v1::join_request::ApproveOrganizationJoinRequestsResponse::InternalError(::std::default::Default::default())
    }
    fn domain_error_from_slug(slug: &str) -> Option<Self> {
        match slug {
            "request-not-found-error" => Some(crate::skirout::base::organization::v1::join_request::ApproveOrganizationJoinRequestsResponse::RequestNotFoundError(::std::default::Default::default())),
            "roles-not-found-error" => Some(crate::skirout::base::organization::v1::join_request::ApproveOrganizationJoinRequestsResponse::RolesNotFoundError(::std::default::Default::default())),
            "roles-not-assignable-error" => Some(crate::skirout::base::organization::v1::join_request::ApproveOrganizationJoinRequestsResponse::RolesNotAssignableError(::std::default::Default::default())),
            "roles-required-error" => Some(crate::skirout::base::organization::v1::join_request::ApproveOrganizationJoinRequestsResponse::RolesRequiredError(::std::default::Default::default())),
            "user-already-member-error" => Some(crate::skirout::base::organization::v1::join_request::ApproveOrganizationJoinRequestsResponse::UserAlreadyMemberError(::std::default::Default::default())),
            "invalid-selection-error" => Some(crate::skirout::base::organization::v1::join_request::ApproveOrganizationJoinRequestsResponse::InvalidSelectionError(::std::default::Default::default())),
            "invalid-record-id-error" => Some(crate::skirout::base::organization::v1::join_request::ApproveOrganizationJoinRequestsResponse::InvalidRecordIdError(::std::default::Default::default())),
            _ => None,
        }
    }
}
impl crate::SkirResponse
    for crate::skirout::base::organization::v1::join_request::DeclineOrganizationJoinRequestResponse
{
    fn to_skir_bytes(&self) -> Vec<u8> {
        Self::serializer().to_bytes(self)
    }
    fn outcome(&self) -> crate::SkirResponseOutcome {
        match self {
            crate::skirout::base::organization::v1::join_request::DeclineOrganizationJoinRequestResponse::Success(_) => crate::SkirResponseOutcome::Success,
            crate::skirout::base::organization::v1::join_request::DeclineOrganizationJoinRequestResponse::RequestNotFoundError(_) | crate::skirout::base::organization::v1::join_request::DeclineOrganizationJoinRequestResponse::InvalidRecordIdError(_) => crate::SkirResponseOutcome::DomainError,
            // internal_error and the generated unknown variant
            _ => crate::SkirResponseOutcome::InternalError,
        }
    }
    fn variant_slug(&self) -> &'static str {
        match self {
            crate::skirout::base::organization::v1::join_request::DeclineOrganizationJoinRequestResponse::InternalError(_) => "internal-error",
            crate::skirout::base::organization::v1::join_request::DeclineOrganizationJoinRequestResponse::Success(_) => "success",
            crate::skirout::base::organization::v1::join_request::DeclineOrganizationJoinRequestResponse::RequestNotFoundError(_) => "request-not-found-error",
            crate::skirout::base::organization::v1::join_request::DeclineOrganizationJoinRequestResponse::InvalidRecordIdError(_) => "invalid-record-id-error",
            _ => "unknown",
        }
    }
    fn variant_message(&self) -> String {
        match self {
            crate::skirout::base::organization::v1::join_request::DeclineOrganizationJoinRequestResponse::RequestNotFoundError(_) => "Join request not found.".to_owned(),
            crate::skirout::base::organization::v1::join_request::DeclineOrganizationJoinRequestResponse::InvalidRecordIdError(_) => "Record IDs from an unexpected table.".to_owned(),
            other => other.variant_slug().to_owned(),
        }
    }
    fn internal_error() -> Self {
        crate::skirout::base::organization::v1::join_request::DeclineOrganizationJoinRequestResponse::InternalError(::std::default::Default::default())
    }
    fn domain_error_from_slug(slug: &str) -> Option<Self> {
        match slug {
            "request-not-found-error" => Some(crate::skirout::base::organization::v1::join_request::DeclineOrganizationJoinRequestResponse::RequestNotFoundError(::std::default::Default::default())),
            "invalid-record-id-error" => Some(crate::skirout::base::organization::v1::join_request::DeclineOrganizationJoinRequestResponse::InvalidRecordIdError(::std::default::Default::default())),
            _ => None,
        }
    }
}
impl crate::SkirResponse
    for crate::skirout::base::organization::v1::member::WatchOrganizationMembersResponse
{
    fn to_skir_bytes(&self) -> Vec<u8> {
        Self::serializer().to_bytes(self)
    }
    fn outcome(&self) -> crate::SkirResponseOutcome {
        match self {
            crate::skirout::base::organization::v1::member::WatchOrganizationMembersResponse::Snapshot(_) => crate::SkirResponseOutcome::Success,
            // internal_error and the generated unknown variant
            _ => crate::SkirResponseOutcome::InternalError,
        }
    }
    fn variant_slug(&self) -> &'static str {
        match self {
            crate::skirout::base::organization::v1::member::WatchOrganizationMembersResponse::InternalError(_) => "internal-error",
            crate::skirout::base::organization::v1::member::WatchOrganizationMembersResponse::Snapshot(_) => "snapshot",
            _ => "unknown",
        }
    }
    fn variant_message(&self) -> String {
        self.variant_slug().to_owned()
    }
    fn internal_error() -> Self {
        crate::skirout::base::organization::v1::member::WatchOrganizationMembersResponse::InternalError(::std::default::Default::default())
    }
}
impl crate::SkirResponse
    for crate::skirout::base::organization::v1::member::UpdateOrganizationMemberRolesResponse
{
    fn to_skir_bytes(&self) -> Vec<u8> {
        Self::serializer().to_bytes(self)
    }
    fn outcome(&self) -> crate::SkirResponseOutcome {
        match self {
            crate::skirout::base::organization::v1::member::UpdateOrganizationMemberRolesResponse::Success(_) => crate::SkirResponseOutcome::Success,
            crate::skirout::base::organization::v1::member::UpdateOrganizationMemberRolesResponse::UserNotFoundError(_) | crate::skirout::base::organization::v1::member::UpdateOrganizationMemberRolesResponse::RolesNotFoundError(_) | crate::skirout::base::organization::v1::member::UpdateOrganizationMemberRolesResponse::RolesNotAssignableError(_) | crate::skirout::base::organization::v1::member::UpdateOrganizationMemberRolesResponse::RolesRequiredError(_) | crate::skirout::base::organization::v1::member::UpdateOrganizationMemberRolesResponse::FounderRoleRequiredError(_) | crate::skirout::base::organization::v1::member::UpdateOrganizationMemberRolesResponse::InvalidSelectionError(_) | crate::skirout::base::organization::v1::member::UpdateOrganizationMemberRolesResponse::InvalidRecordIdError(_) => crate::SkirResponseOutcome::DomainError,
            // internal_error and the generated unknown variant
            _ => crate::SkirResponseOutcome::InternalError,
        }
    }
    fn variant_slug(&self) -> &'static str {
        match self {
            crate::skirout::base::organization::v1::member::UpdateOrganizationMemberRolesResponse::InternalError(_) => "internal-error",
            crate::skirout::base::organization::v1::member::UpdateOrganizationMemberRolesResponse::Success(_) => "success",
            crate::skirout::base::organization::v1::member::UpdateOrganizationMemberRolesResponse::UserNotFoundError(_) => "user-not-found-error",
            crate::skirout::base::organization::v1::member::UpdateOrganizationMemberRolesResponse::RolesNotFoundError(_) => "roles-not-found-error",
            crate::skirout::base::organization::v1::member::UpdateOrganizationMemberRolesResponse::RolesNotAssignableError(_) => "roles-not-assignable-error",
            crate::skirout::base::organization::v1::member::UpdateOrganizationMemberRolesResponse::RolesRequiredError(_) => "roles-required-error",
            crate::skirout::base::organization::v1::member::UpdateOrganizationMemberRolesResponse::FounderRoleRequiredError(_) => "founder-role-required-error",
            crate::skirout::base::organization::v1::member::UpdateOrganizationMemberRolesResponse::InvalidSelectionError(_) => "invalid-selection-error",
            crate::skirout::base::organization::v1::member::UpdateOrganizationMemberRolesResponse::InvalidRecordIdError(_) => "invalid-record-id-error",
            _ => "unknown",
        }
    }
    fn variant_message(&self) -> String {
        match self {
            crate::skirout::base::organization::v1::member::UpdateOrganizationMemberRolesResponse::UserNotFoundError(_) => "Users not found.".to_owned(),
            crate::skirout::base::organization::v1::member::UpdateOrganizationMemberRolesResponse::RolesNotFoundError(_) => "Roles not found.".to_owned(),
            crate::skirout::base::organization::v1::member::UpdateOrganizationMemberRolesResponse::RolesNotAssignableError(_) => "Roles not assignable.".to_owned(),
            crate::skirout::base::organization::v1::member::UpdateOrganizationMemberRolesResponse::RolesRequiredError(_) => "At least one role is required.".to_owned(),
            crate::skirout::base::organization::v1::member::UpdateOrganizationMemberRolesResponse::FounderRoleRequiredError(_) => "Founder role is required.".to_owned(),
            crate::skirout::base::organization::v1::member::UpdateOrganizationMemberRolesResponse::InvalidSelectionError(_) => "Selection must contain distinct targets.".to_owned(),
            crate::skirout::base::organization::v1::member::UpdateOrganizationMemberRolesResponse::InvalidRecordIdError(_) => "Record IDs from an unexpected table.".to_owned(),
            other => other.variant_slug().to_owned(),
        }
    }
    fn internal_error() -> Self {
        crate::skirout::base::organization::v1::member::UpdateOrganizationMemberRolesResponse::InternalError(::std::default::Default::default())
    }
    fn domain_error_from_slug(slug: &str) -> Option<Self> {
        match slug {
            "user-not-found-error" => Some(crate::skirout::base::organization::v1::member::UpdateOrganizationMemberRolesResponse::UserNotFoundError(::std::default::Default::default())),
            "roles-not-found-error" => Some(crate::skirout::base::organization::v1::member::UpdateOrganizationMemberRolesResponse::RolesNotFoundError(::std::default::Default::default())),
            "roles-not-assignable-error" => Some(crate::skirout::base::organization::v1::member::UpdateOrganizationMemberRolesResponse::RolesNotAssignableError(::std::default::Default::default())),
            "roles-required-error" => Some(crate::skirout::base::organization::v1::member::UpdateOrganizationMemberRolesResponse::RolesRequiredError(::std::default::Default::default())),
            "founder-role-required-error" => Some(crate::skirout::base::organization::v1::member::UpdateOrganizationMemberRolesResponse::FounderRoleRequiredError(::std::default::Default::default())),
            "invalid-selection-error" => Some(crate::skirout::base::organization::v1::member::UpdateOrganizationMemberRolesResponse::InvalidSelectionError(::std::default::Default::default())),
            "invalid-record-id-error" => Some(crate::skirout::base::organization::v1::member::UpdateOrganizationMemberRolesResponse::InvalidRecordIdError(::std::default::Default::default())),
            _ => None,
        }
    }
}
impl crate::SkirResponse
    for crate::skirout::base::organization::v1::member::RemoveOrganizationMemberResponse
{
    fn to_skir_bytes(&self) -> Vec<u8> {
        Self::serializer().to_bytes(self)
    }
    fn outcome(&self) -> crate::SkirResponseOutcome {
        match self {
            crate::skirout::base::organization::v1::member::RemoveOrganizationMemberResponse::Success(_) => crate::SkirResponseOutcome::Success,
            crate::skirout::base::organization::v1::member::RemoveOrganizationMemberResponse::UserNotMemberError(_) | crate::skirout::base::organization::v1::member::RemoveOrganizationMemberResponse::FounderCannotBeRemovedError(_) | crate::skirout::base::organization::v1::member::RemoveOrganizationMemberResponse::InvalidRecordIdError(_) => crate::SkirResponseOutcome::DomainError,
            // internal_error and the generated unknown variant
            _ => crate::SkirResponseOutcome::InternalError,
        }
    }
    fn variant_slug(&self) -> &'static str {
        match self {
            crate::skirout::base::organization::v1::member::RemoveOrganizationMemberResponse::InternalError(_) => "internal-error",
            crate::skirout::base::organization::v1::member::RemoveOrganizationMemberResponse::Success(_) => "success",
            crate::skirout::base::organization::v1::member::RemoveOrganizationMemberResponse::UserNotMemberError(_) => "user-not-member-error",
            crate::skirout::base::organization::v1::member::RemoveOrganizationMemberResponse::FounderCannotBeRemovedError(_) => "founder-cannot-be-removed-error",
            crate::skirout::base::organization::v1::member::RemoveOrganizationMemberResponse::InvalidRecordIdError(_) => "invalid-record-id-error",
            _ => "unknown",
        }
    }
    fn variant_message(&self) -> String {
        match self {
            crate::skirout::base::organization::v1::member::RemoveOrganizationMemberResponse::UserNotMemberError(_) => "User is not a member.".to_owned(),
            crate::skirout::base::organization::v1::member::RemoveOrganizationMemberResponse::FounderCannotBeRemovedError(_) => "Founder cannot be removed.".to_owned(),
            crate::skirout::base::organization::v1::member::RemoveOrganizationMemberResponse::InvalidRecordIdError(_) => "Record IDs from an unexpected table.".to_owned(),
            other => other.variant_slug().to_owned(),
        }
    }
    fn internal_error() -> Self {
        crate::skirout::base::organization::v1::member::RemoveOrganizationMemberResponse::InternalError(::std::default::Default::default())
    }
    fn domain_error_from_slug(slug: &str) -> Option<Self> {
        match slug {
            "user-not-member-error" => Some(crate::skirout::base::organization::v1::member::RemoveOrganizationMemberResponse::UserNotMemberError(::std::default::Default::default())),
            "founder-cannot-be-removed-error" => Some(crate::skirout::base::organization::v1::member::RemoveOrganizationMemberResponse::FounderCannotBeRemovedError(::std::default::Default::default())),
            "invalid-record-id-error" => Some(crate::skirout::base::organization::v1::member::RemoveOrganizationMemberResponse::InvalidRecordIdError(::std::default::Default::default())),
            _ => None,
        }
    }
}
impl crate::SkirResponse
    for crate::skirout::base::organization::v1::organization::CreateOrganizationResponse
{
    fn to_skir_bytes(&self) -> Vec<u8> {
        Self::serializer().to_bytes(self)
    }
    fn outcome(&self) -> crate::SkirResponseOutcome {
        match self {
            crate::skirout::base::organization::v1::organization::CreateOrganizationResponse::Success(_) => crate::SkirResponseOutcome::Success,
            // internal_error and the generated unknown variant
            _ => crate::SkirResponseOutcome::InternalError,
        }
    }
    fn variant_slug(&self) -> &'static str {
        match self {
            crate::skirout::base::organization::v1::organization::CreateOrganizationResponse::InternalError(_) => "internal-error",
            crate::skirout::base::organization::v1::organization::CreateOrganizationResponse::Success(_) => "success",
            _ => "unknown",
        }
    }
    fn variant_message(&self) -> String {
        self.variant_slug().to_owned()
    }
    fn internal_error() -> Self {
        crate::skirout::base::organization::v1::organization::CreateOrganizationResponse::InternalError(::std::default::Default::default())
    }
}
impl crate::SkirResponse
    for crate::skirout::base::organization::v1::organization::DeleteOrganizationResponse
{
    fn to_skir_bytes(&self) -> Vec<u8> {
        Self::serializer().to_bytes(self)
    }
    fn outcome(&self) -> crate::SkirResponseOutcome {
        match self {
            crate::skirout::base::organization::v1::organization::DeleteOrganizationResponse::Success(_) => crate::SkirResponseOutcome::Success,
            crate::skirout::base::organization::v1::organization::DeleteOrganizationResponse::InvalidRecordIdError(_) => crate::SkirResponseOutcome::DomainError,
            // internal_error and the generated unknown variant
            _ => crate::SkirResponseOutcome::InternalError,
        }
    }
    fn variant_slug(&self) -> &'static str {
        match self {
            crate::skirout::base::organization::v1::organization::DeleteOrganizationResponse::InternalError(_) => "internal-error",
            crate::skirout::base::organization::v1::organization::DeleteOrganizationResponse::Success(_) => "success",
            crate::skirout::base::organization::v1::organization::DeleteOrganizationResponse::InvalidRecordIdError(_) => "invalid-record-id-error",
            _ => "unknown",
        }
    }
    fn variant_message(&self) -> String {
        match self {
            crate::skirout::base::organization::v1::organization::DeleteOrganizationResponse::InvalidRecordIdError(_) => "Record IDs from an unexpected table.".to_owned(),
            other => other.variant_slug().to_owned(),
        }
    }
    fn internal_error() -> Self {
        crate::skirout::base::organization::v1::organization::DeleteOrganizationResponse::InternalError(::std::default::Default::default())
    }
    fn domain_error_from_slug(slug: &str) -> Option<Self> {
        match slug {
            "invalid-record-id-error" => Some(crate::skirout::base::organization::v1::organization::DeleteOrganizationResponse::InvalidRecordIdError(::std::default::Default::default())),
            _ => None,
        }
    }
}
impl crate::SkirResponse
    for crate::skirout::base::organization::v1::role::WatchOrganizationRolesResponse
{
    fn to_skir_bytes(&self) -> Vec<u8> {
        Self::serializer().to_bytes(self)
    }
    fn outcome(&self) -> crate::SkirResponseOutcome {
        match self {
            crate::skirout::base::organization::v1::role::WatchOrganizationRolesResponse::List(_) | crate::skirout::base::organization::v1::role::WatchOrganizationRolesResponse::Add(_) | crate::skirout::base::organization::v1::role::WatchOrganizationRolesResponse::Update(_) | crate::skirout::base::organization::v1::role::WatchOrganizationRolesResponse::Remove(_) => crate::SkirResponseOutcome::Success,
            // internal_error and the generated unknown variant
            _ => crate::SkirResponseOutcome::InternalError,
        }
    }
    fn variant_slug(&self) -> &'static str {
        match self {
            crate::skirout::base::organization::v1::role::WatchOrganizationRolesResponse::InternalError(_) => "internal-error",
            crate::skirout::base::organization::v1::role::WatchOrganizationRolesResponse::List(_) => "list",
            crate::skirout::base::organization::v1::role::WatchOrganizationRolesResponse::Add(_) => "add",
            crate::skirout::base::organization::v1::role::WatchOrganizationRolesResponse::Update(_) => "update",
            crate::skirout::base::organization::v1::role::WatchOrganizationRolesResponse::Remove(_) => "remove",
            _ => "unknown",
        }
    }
    fn variant_message(&self) -> String {
        self.variant_slug().to_owned()
    }
    fn internal_error() -> Self {
        crate::skirout::base::organization::v1::role::WatchOrganizationRolesResponse::InternalError(
            ::std::default::Default::default(),
        )
    }
}
impl crate::SkirResponse
    for crate::skirout::base::organization::v1::user::WatchUserOrganizationsResponse
{
    fn to_skir_bytes(&self) -> Vec<u8> {
        Self::serializer().to_bytes(self)
    }
    fn outcome(&self) -> crate::SkirResponseOutcome {
        match self {
            crate::skirout::base::organization::v1::user::WatchUserOrganizationsResponse::Snapshot(_) | crate::skirout::base::organization::v1::user::WatchUserOrganizationsResponse::Changed(_) => crate::SkirResponseOutcome::Success,
            // internal_error and the generated unknown variant
            _ => crate::SkirResponseOutcome::InternalError,
        }
    }
    fn variant_slug(&self) -> &'static str {
        match self {
            crate::skirout::base::organization::v1::user::WatchUserOrganizationsResponse::InternalError(_) => "internal-error",
            crate::skirout::base::organization::v1::user::WatchUserOrganizationsResponse::Snapshot(_) => "snapshot",
            crate::skirout::base::organization::v1::user::WatchUserOrganizationsResponse::Changed(_) => "changed",
            _ => "unknown",
        }
    }
    fn variant_message(&self) -> String {
        self.variant_slug().to_owned()
    }
    fn internal_error() -> Self {
        crate::skirout::base::organization::v1::user::WatchUserOrganizationsResponse::InternalError(
            ::std::default::Default::default(),
        )
    }
}
impl crate::SkirResponse
    for crate::skirout::base::organization::v1::user::WatchUserJoinRequestsResponse
{
    fn to_skir_bytes(&self) -> Vec<u8> {
        Self::serializer().to_bytes(self)
    }
    fn outcome(&self) -> crate::SkirResponseOutcome {
        match self {
            crate::skirout::base::organization::v1::user::WatchUserJoinRequestsResponse::Snapshot(_) | crate::skirout::base::organization::v1::user::WatchUserJoinRequestsResponse::Changed(_) => crate::SkirResponseOutcome::Success,
            // internal_error and the generated unknown variant
            _ => crate::SkirResponseOutcome::InternalError,
        }
    }
    fn variant_slug(&self) -> &'static str {
        match self {
            crate::skirout::base::organization::v1::user::WatchUserJoinRequestsResponse::InternalError(_) => "internal-error",
            crate::skirout::base::organization::v1::user::WatchUserJoinRequestsResponse::Snapshot(_) => "snapshot",
            crate::skirout::base::organization::v1::user::WatchUserJoinRequestsResponse::Changed(_) => "changed",
            _ => "unknown",
        }
    }
    fn variant_message(&self) -> String {
        self.variant_slug().to_owned()
    }
    fn internal_error() -> Self {
        crate::skirout::base::organization::v1::user::WatchUserJoinRequestsResponse::InternalError(
            ::std::default::Default::default(),
        )
    }
}
impl crate::SkirResponse
    for crate::skirout::base::organization::v1::user::SubmitUserJoinRequestResponse
{
    fn to_skir_bytes(&self) -> Vec<u8> {
        Self::serializer().to_bytes(self)
    }
    fn outcome(&self) -> crate::SkirResponseOutcome {
        match self {
            crate::skirout::base::organization::v1::user::SubmitUserJoinRequestResponse::RequestMade(_) | crate::skirout::base::organization::v1::user::SubmitUserJoinRequestResponse::AutoAccepted(_) => crate::SkirResponseOutcome::Success,
            crate::skirout::base::organization::v1::user::SubmitUserJoinRequestResponse::CodeNotFoundError(_) | crate::skirout::base::organization::v1::user::SubmitUserJoinRequestResponse::AlreadyMemberError(_) | crate::skirout::base::organization::v1::user::SubmitUserJoinRequestResponse::NoAssignableRolesError(_) | crate::skirout::base::organization::v1::user::SubmitUserJoinRequestResponse::MaxPendingRequestsError(_) | crate::skirout::base::organization::v1::user::SubmitUserJoinRequestResponse::PendingRequestExistsError(_) | crate::skirout::base::organization::v1::user::SubmitUserJoinRequestResponse::InvalidRecordIdError(_) => crate::SkirResponseOutcome::DomainError,
            // internal_error and the generated unknown variant
            _ => crate::SkirResponseOutcome::InternalError,
        }
    }
    fn variant_slug(&self) -> &'static str {
        match self {
            crate::skirout::base::organization::v1::user::SubmitUserJoinRequestResponse::InternalError(_) => "internal-error",
            crate::skirout::base::organization::v1::user::SubmitUserJoinRequestResponse::RequestMade(_) => "request-made",
            crate::skirout::base::organization::v1::user::SubmitUserJoinRequestResponse::AutoAccepted(_) => "auto-accepted",
            crate::skirout::base::organization::v1::user::SubmitUserJoinRequestResponse::CodeNotFoundError(_) => "code-not-found-error",
            crate::skirout::base::organization::v1::user::SubmitUserJoinRequestResponse::AlreadyMemberError(_) => "already-member-error",
            crate::skirout::base::organization::v1::user::SubmitUserJoinRequestResponse::NoAssignableRolesError(_) => "no-assignable-roles-error",
            crate::skirout::base::organization::v1::user::SubmitUserJoinRequestResponse::MaxPendingRequestsError(_) => "max-pending-requests-error",
            crate::skirout::base::organization::v1::user::SubmitUserJoinRequestResponse::PendingRequestExistsError(_) => "pending-request-exists-error",
            crate::skirout::base::organization::v1::user::SubmitUserJoinRequestResponse::InvalidRecordIdError(_) => "invalid-record-id-error",
            _ => "unknown",
        }
    }
    fn variant_message(&self) -> String {
        match self {
            crate::skirout::base::organization::v1::user::SubmitUserJoinRequestResponse::CodeNotFoundError(_) => "Join code not found.".to_owned(),
            crate::skirout::base::organization::v1::user::SubmitUserJoinRequestResponse::AlreadyMemberError(_) => "User is already a member of this organization.".to_owned(),
            crate::skirout::base::organization::v1::user::SubmitUserJoinRequestResponse::NoAssignableRolesError(_) => "No assignable roles are available for this organization.".to_owned(),
            crate::skirout::base::organization::v1::user::SubmitUserJoinRequestResponse::MaxPendingRequestsError(_) => "User already has the maximum number of pending join requests.".to_owned(),
            crate::skirout::base::organization::v1::user::SubmitUserJoinRequestResponse::PendingRequestExistsError(_) => "User already has a pending join request for this organization.".to_owned(),
            crate::skirout::base::organization::v1::user::SubmitUserJoinRequestResponse::InvalidRecordIdError(_) => "Record IDs from an unexpected table.".to_owned(),
            other => other.variant_slug().to_owned(),
        }
    }
    fn internal_error() -> Self {
        crate::skirout::base::organization::v1::user::SubmitUserJoinRequestResponse::InternalError(
            ::std::default::Default::default(),
        )
    }
    fn domain_error_from_slug(slug: &str) -> Option<Self> {
        match slug {
            "code-not-found-error" => Some(crate::skirout::base::organization::v1::user::SubmitUserJoinRequestResponse::CodeNotFoundError(::std::default::Default::default())),
            "already-member-error" => Some(crate::skirout::base::organization::v1::user::SubmitUserJoinRequestResponse::AlreadyMemberError(::std::default::Default::default())),
            "no-assignable-roles-error" => Some(crate::skirout::base::organization::v1::user::SubmitUserJoinRequestResponse::NoAssignableRolesError(::std::default::Default::default())),
            "max-pending-requests-error" => Some(crate::skirout::base::organization::v1::user::SubmitUserJoinRequestResponse::MaxPendingRequestsError(::std::default::Default::default())),
            "pending-request-exists-error" => Some(crate::skirout::base::organization::v1::user::SubmitUserJoinRequestResponse::PendingRequestExistsError(::std::default::Default::default())),
            "invalid-record-id-error" => Some(crate::skirout::base::organization::v1::user::SubmitUserJoinRequestResponse::InvalidRecordIdError(::std::default::Default::default())),
            _ => None,
        }
    }
}
impl crate::SkirResponse
    for crate::skirout::base::organization::v1::user::CancelUserJoinRequestResponse
{
    fn to_skir_bytes(&self) -> Vec<u8> {
        Self::serializer().to_bytes(self)
    }
    fn outcome(&self) -> crate::SkirResponseOutcome {
        match self {
            crate::skirout::base::organization::v1::user::CancelUserJoinRequestResponse::Success(_) => crate::SkirResponseOutcome::Success,
            crate::skirout::base::organization::v1::user::CancelUserJoinRequestResponse::RequestNotFoundError(_) | crate::skirout::base::organization::v1::user::CancelUserJoinRequestResponse::InvalidRecordIdError(_) => crate::SkirResponseOutcome::DomainError,
            // internal_error and the generated unknown variant
            _ => crate::SkirResponseOutcome::InternalError,
        }
    }
    fn variant_slug(&self) -> &'static str {
        match self {
            crate::skirout::base::organization::v1::user::CancelUserJoinRequestResponse::InternalError(_) => "internal-error",
            crate::skirout::base::organization::v1::user::CancelUserJoinRequestResponse::Success(_) => "success",
            crate::skirout::base::organization::v1::user::CancelUserJoinRequestResponse::RequestNotFoundError(_) => "request-not-found-error",
            crate::skirout::base::organization::v1::user::CancelUserJoinRequestResponse::InvalidRecordIdError(_) => "invalid-record-id-error",
            _ => "unknown",
        }
    }
    fn variant_message(&self) -> String {
        match self {
            crate::skirout::base::organization::v1::user::CancelUserJoinRequestResponse::RequestNotFoundError(_) => "Join request not found.".to_owned(),
            crate::skirout::base::organization::v1::user::CancelUserJoinRequestResponse::InvalidRecordIdError(_) => "Record IDs from an unexpected table.".to_owned(),
            other => other.variant_slug().to_owned(),
        }
    }
    fn internal_error() -> Self {
        crate::skirout::base::organization::v1::user::CancelUserJoinRequestResponse::InternalError(
            ::std::default::Default::default(),
        )
    }
    fn domain_error_from_slug(slug: &str) -> Option<Self> {
        match slug {
            "request-not-found-error" => Some(crate::skirout::base::organization::v1::user::CancelUserJoinRequestResponse::RequestNotFoundError(::std::default::Default::default())),
            "invalid-record-id-error" => Some(crate::skirout::base::organization::v1::user::CancelUserJoinRequestResponse::InvalidRecordIdError(::std::default::Default::default())),
            _ => None,
        }
    }
}
impl crate::SkirResponse
    for crate::skirout::base::service::v1::artifact::FetchSharedArtifactCatalogResponse
{
    fn to_skir_bytes(&self) -> Vec<u8> {
        Self::serializer().to_bytes(self)
    }
    fn outcome(&self) -> crate::SkirResponseOutcome {
        match self {
            crate::skirout::base::service::v1::artifact::FetchSharedArtifactCatalogResponse::Success(_) => crate::SkirResponseOutcome::Success,
            // internal_error and the generated unknown variant
            _ => crate::SkirResponseOutcome::InternalError,
        }
    }
    fn variant_slug(&self) -> &'static str {
        match self {
            crate::skirout::base::service::v1::artifact::FetchSharedArtifactCatalogResponse::Success(_) => "success",
            crate::skirout::base::service::v1::artifact::FetchSharedArtifactCatalogResponse::InternalError(_) => "internal-error",
            _ => "unknown",
        }
    }
    fn variant_message(&self) -> String {
        self.variant_slug().to_owned()
    }
    fn internal_error() -> Self {
        crate::skirout::base::service::v1::artifact::FetchSharedArtifactCatalogResponse::InternalError(::std::default::Default::default())
    }
}
impl crate::SkirResponse
    for crate::skirout::base::service::v1::artifact::PublishSharedArtifactResponse
{
    fn to_skir_bytes(&self) -> Vec<u8> {
        Self::serializer().to_bytes(self)
    }
    fn outcome(&self) -> crate::SkirResponseOutcome {
        match self {
            crate::skirout::base::service::v1::artifact::PublishSharedArtifactResponse::Published(_) | crate::skirout::base::service::v1::artifact::PublishSharedArtifactResponse::Unchanged(_) => crate::SkirResponseOutcome::Success,
            crate::skirout::base::service::v1::artifact::PublishSharedArtifactResponse::ConflictError(_) => crate::SkirResponseOutcome::DomainError,
            // internal_error and the generated unknown variant
            _ => crate::SkirResponseOutcome::InternalError,
        }
    }
    fn variant_slug(&self) -> &'static str {
        match self {
            crate::skirout::base::service::v1::artifact::PublishSharedArtifactResponse::Published(_) => "published",
            crate::skirout::base::service::v1::artifact::PublishSharedArtifactResponse::Unchanged(_) => "unchanged",
            crate::skirout::base::service::v1::artifact::PublishSharedArtifactResponse::ConflictError(_) => "conflict-error",
            crate::skirout::base::service::v1::artifact::PublishSharedArtifactResponse::InternalError(_) => "internal-error",
            _ => "unknown",
        }
    }
    fn variant_message(&self) -> String {
        self.variant_slug().to_owned()
    }
    fn internal_error() -> Self {
        crate::skirout::base::service::v1::artifact::PublishSharedArtifactResponse::InternalError(
            ::std::default::Default::default(),
        )
    }
    fn domain_error_from_slug(slug: &str) -> Option<Self> {
        match slug {
            "conflict-error" => Some(crate::skirout::base::service::v1::artifact::PublishSharedArtifactResponse::ConflictError(::std::default::Default::default())),
            _ => None,
        }
    }
}
impl crate::SkirResponse for crate::skirout::base::service::v1::artifact::ReadArtifactBlobResponse {
    fn to_skir_bytes(&self) -> Vec<u8> {
        Self::serializer().to_bytes(self)
    }
    fn outcome(&self) -> crate::SkirResponseOutcome {
        match self {
            crate::skirout::base::service::v1::artifact::ReadArtifactBlobResponse::Success(_) => crate::SkirResponseOutcome::Success,
            crate::skirout::base::service::v1::artifact::ReadArtifactBlobResponse::NotFoundError(_) | crate::skirout::base::service::v1::artifact::ReadArtifactBlobResponse::InvalidError(_) => crate::SkirResponseOutcome::DomainError,
            // internal_error and the generated unknown variant
            _ => crate::SkirResponseOutcome::InternalError,
        }
    }
    fn variant_slug(&self) -> &'static str {
        match self {
            crate::skirout::base::service::v1::artifact::ReadArtifactBlobResponse::Success(_) => "success",
            crate::skirout::base::service::v1::artifact::ReadArtifactBlobResponse::NotFoundError(_) => "not-found-error",
            crate::skirout::base::service::v1::artifact::ReadArtifactBlobResponse::InvalidError(_) => "invalid-error",
            crate::skirout::base::service::v1::artifact::ReadArtifactBlobResponse::InternalError(_) => "internal-error",
            _ => "unknown",
        }
    }
    fn variant_message(&self) -> String {
        self.variant_slug().to_owned()
    }
    fn internal_error() -> Self {
        crate::skirout::base::service::v1::artifact::ReadArtifactBlobResponse::InternalError(
            ::std::default::Default::default(),
        )
    }
    fn domain_error_from_slug(slug: &str) -> Option<Self> {
        match slug {
            "not-found-error" => Some(crate::skirout::base::service::v1::artifact::ReadArtifactBlobResponse::NotFoundError(::std::default::Default::default())),
            "invalid-error" => Some(crate::skirout::base::service::v1::artifact::ReadArtifactBlobResponse::InvalidError(::std::default::Default::default())),
            _ => None,
        }
    }
}
impl crate::SkirResponse
    for crate::skirout::base::service::v1::artifact::BeginArtifactBlobWriteResponse
{
    fn to_skir_bytes(&self) -> Vec<u8> {
        Self::serializer().to_bytes(self)
    }
    fn outcome(&self) -> crate::SkirResponseOutcome {
        match self {
            crate::skirout::base::service::v1::artifact::BeginArtifactBlobWriteResponse::Accepted(_) => crate::SkirResponseOutcome::Success,
            crate::skirout::base::service::v1::artifact::BeginArtifactBlobWriteResponse::InvalidError(_) | crate::skirout::base::service::v1::artifact::BeginArtifactBlobWriteResponse::ConflictError(_) => crate::SkirResponseOutcome::DomainError,
            // internal_error and the generated unknown variant
            _ => crate::SkirResponseOutcome::InternalError,
        }
    }
    fn variant_slug(&self) -> &'static str {
        match self {
            crate::skirout::base::service::v1::artifact::BeginArtifactBlobWriteResponse::Accepted(_) => "accepted",
            crate::skirout::base::service::v1::artifact::BeginArtifactBlobWriteResponse::InvalidError(_) => "invalid-error",
            crate::skirout::base::service::v1::artifact::BeginArtifactBlobWriteResponse::ConflictError(_) => "conflict-error",
            crate::skirout::base::service::v1::artifact::BeginArtifactBlobWriteResponse::InternalError(_) => "internal-error",
            _ => "unknown",
        }
    }
    fn variant_message(&self) -> String {
        self.variant_slug().to_owned()
    }
    fn internal_error() -> Self {
        crate::skirout::base::service::v1::artifact::BeginArtifactBlobWriteResponse::InternalError(
            ::std::default::Default::default(),
        )
    }
    fn domain_error_from_slug(slug: &str) -> Option<Self> {
        match slug {
            "invalid-error" => Some(crate::skirout::base::service::v1::artifact::BeginArtifactBlobWriteResponse::InvalidError(::std::default::Default::default())),
            "conflict-error" => Some(crate::skirout::base::service::v1::artifact::BeginArtifactBlobWriteResponse::ConflictError(::std::default::Default::default())),
            _ => None,
        }
    }
}
impl crate::SkirResponse
    for crate::skirout::base::service::v1::artifact::WriteArtifactBlobChunkResponse
{
    fn to_skir_bytes(&self) -> Vec<u8> {
        Self::serializer().to_bytes(self)
    }
    fn outcome(&self) -> crate::SkirResponseOutcome {
        match self {
            crate::skirout::base::service::v1::artifact::WriteArtifactBlobChunkResponse::Accepted(_) => crate::SkirResponseOutcome::Success,
            crate::skirout::base::service::v1::artifact::WriteArtifactBlobChunkResponse::NotFoundError(_) | crate::skirout::base::service::v1::artifact::WriteArtifactBlobChunkResponse::InvalidError(_) | crate::skirout::base::service::v1::artifact::WriteArtifactBlobChunkResponse::ConflictError(_) => crate::SkirResponseOutcome::DomainError,
            // internal_error and the generated unknown variant
            _ => crate::SkirResponseOutcome::InternalError,
        }
    }
    fn variant_slug(&self) -> &'static str {
        match self {
            crate::skirout::base::service::v1::artifact::WriteArtifactBlobChunkResponse::Accepted(_) => "accepted",
            crate::skirout::base::service::v1::artifact::WriteArtifactBlobChunkResponse::NotFoundError(_) => "not-found-error",
            crate::skirout::base::service::v1::artifact::WriteArtifactBlobChunkResponse::InvalidError(_) => "invalid-error",
            crate::skirout::base::service::v1::artifact::WriteArtifactBlobChunkResponse::ConflictError(_) => "conflict-error",
            crate::skirout::base::service::v1::artifact::WriteArtifactBlobChunkResponse::InternalError(_) => "internal-error",
            _ => "unknown",
        }
    }
    fn variant_message(&self) -> String {
        self.variant_slug().to_owned()
    }
    fn internal_error() -> Self {
        crate::skirout::base::service::v1::artifact::WriteArtifactBlobChunkResponse::InternalError(
            ::std::default::Default::default(),
        )
    }
    fn domain_error_from_slug(slug: &str) -> Option<Self> {
        match slug {
            "not-found-error" => Some(crate::skirout::base::service::v1::artifact::WriteArtifactBlobChunkResponse::NotFoundError(::std::default::Default::default())),
            "invalid-error" => Some(crate::skirout::base::service::v1::artifact::WriteArtifactBlobChunkResponse::InvalidError(::std::default::Default::default())),
            "conflict-error" => Some(crate::skirout::base::service::v1::artifact::WriteArtifactBlobChunkResponse::ConflictError(::std::default::Default::default())),
            _ => None,
        }
    }
}
impl crate::SkirResponse
    for crate::skirout::base::service::v1::artifact::CompleteArtifactBlobWriteResponse
{
    fn to_skir_bytes(&self) -> Vec<u8> {
        Self::serializer().to_bytes(self)
    }
    fn outcome(&self) -> crate::SkirResponseOutcome {
        match self {
            crate::skirout::base::service::v1::artifact::CompleteArtifactBlobWriteResponse::Success(_) => crate::SkirResponseOutcome::Success,
            crate::skirout::base::service::v1::artifact::CompleteArtifactBlobWriteResponse::NotFoundError(_) | crate::skirout::base::service::v1::artifact::CompleteArtifactBlobWriteResponse::InvalidError(_) | crate::skirout::base::service::v1::artifact::CompleteArtifactBlobWriteResponse::ConflictError(_) => crate::SkirResponseOutcome::DomainError,
            // internal_error and the generated unknown variant
            _ => crate::SkirResponseOutcome::InternalError,
        }
    }
    fn variant_slug(&self) -> &'static str {
        match self {
            crate::skirout::base::service::v1::artifact::CompleteArtifactBlobWriteResponse::Success(_) => "success",
            crate::skirout::base::service::v1::artifact::CompleteArtifactBlobWriteResponse::NotFoundError(_) => "not-found-error",
            crate::skirout::base::service::v1::artifact::CompleteArtifactBlobWriteResponse::InvalidError(_) => "invalid-error",
            crate::skirout::base::service::v1::artifact::CompleteArtifactBlobWriteResponse::ConflictError(_) => "conflict-error",
            crate::skirout::base::service::v1::artifact::CompleteArtifactBlobWriteResponse::InternalError(_) => "internal-error",
            _ => "unknown",
        }
    }
    fn variant_message(&self) -> String {
        self.variant_slug().to_owned()
    }
    fn internal_error() -> Self {
        crate::skirout::base::service::v1::artifact::CompleteArtifactBlobWriteResponse::InternalError(::std::default::Default::default())
    }
    fn domain_error_from_slug(slug: &str) -> Option<Self> {
        match slug {
            "not-found-error" => Some(crate::skirout::base::service::v1::artifact::CompleteArtifactBlobWriteResponse::NotFoundError(::std::default::Default::default())),
            "invalid-error" => Some(crate::skirout::base::service::v1::artifact::CompleteArtifactBlobWriteResponse::InvalidError(::std::default::Default::default())),
            "conflict-error" => Some(crate::skirout::base::service::v1::artifact::CompleteArtifactBlobWriteResponse::ConflictError(::std::default::Default::default())),
            _ => None,
        }
    }
}
impl crate::SkirResponse
    for crate::skirout::base::service::v1::artifact::FetchArtifactBlobMetadataResponse
{
    fn to_skir_bytes(&self) -> Vec<u8> {
        Self::serializer().to_bytes(self)
    }
    fn outcome(&self) -> crate::SkirResponseOutcome {
        match self {
            crate::skirout::base::service::v1::artifact::FetchArtifactBlobMetadataResponse::Success(_) => crate::SkirResponseOutcome::Success,
            crate::skirout::base::service::v1::artifact::FetchArtifactBlobMetadataResponse::NotFoundError(_) | crate::skirout::base::service::v1::artifact::FetchArtifactBlobMetadataResponse::InvalidError(_) => crate::SkirResponseOutcome::DomainError,
            // internal_error and the generated unknown variant
            _ => crate::SkirResponseOutcome::InternalError,
        }
    }
    fn variant_slug(&self) -> &'static str {
        match self {
            crate::skirout::base::service::v1::artifact::FetchArtifactBlobMetadataResponse::Success(_) => "success",
            crate::skirout::base::service::v1::artifact::FetchArtifactBlobMetadataResponse::NotFoundError(_) => "not-found-error",
            crate::skirout::base::service::v1::artifact::FetchArtifactBlobMetadataResponse::InvalidError(_) => "invalid-error",
            crate::skirout::base::service::v1::artifact::FetchArtifactBlobMetadataResponse::InternalError(_) => "internal-error",
            _ => "unknown",
        }
    }
    fn variant_message(&self) -> String {
        self.variant_slug().to_owned()
    }
    fn internal_error() -> Self {
        crate::skirout::base::service::v1::artifact::FetchArtifactBlobMetadataResponse::InternalError(::std::default::Default::default())
    }
    fn domain_error_from_slug(slug: &str) -> Option<Self> {
        match slug {
            "not-found-error" => Some(crate::skirout::base::service::v1::artifact::FetchArtifactBlobMetadataResponse::NotFoundError(::std::default::Default::default())),
            "invalid-error" => Some(crate::skirout::base::service::v1::artifact::FetchArtifactBlobMetadataResponse::InvalidError(::std::default::Default::default())),
            _ => None,
        }
    }
}
impl crate::SkirResponse
    for crate::skirout::base::service::v1::identity::IssueServiceIdentityResponse
{
    fn to_skir_bytes(&self) -> Vec<u8> {
        Self::serializer().to_bytes(self)
    }
    fn outcome(&self) -> crate::SkirResponseOutcome {
        match self {
            crate::skirout::base::service::v1::identity::IssueServiceIdentityResponse::Success(_) => crate::SkirResponseOutcome::Success,
            crate::skirout::base::service::v1::identity::IssueServiceIdentityResponse::MalformedRequestError(_) | crate::skirout::base::service::v1::identity::IssueServiceIdentityResponse::UnknownRoleError(_) | crate::skirout::base::service::v1::identity::IssueServiceIdentityResponse::RoleUnknownPropertyError(_) | crate::skirout::base::service::v1::identity::IssueServiceIdentityResponse::RoleTypeInvalidError(_) | crate::skirout::base::service::v1::identity::IssueServiceIdentityResponse::RoleVersionInvalidError(_) | crate::skirout::base::service::v1::identity::IssueServiceIdentityResponse::CustomRoleNameRequiredError(_) | crate::skirout::base::service::v1::identity::IssueServiceIdentityResponse::CustomRoleNameInvalidError(_) | crate::skirout::base::service::v1::identity::IssueServiceIdentityResponse::BuiltinRoleNameForbiddenError(_) | crate::skirout::base::service::v1::identity::IssueServiceIdentityResponse::IdentityProviderUnavailableError(_) => crate::SkirResponseOutcome::DomainError,
            // internal_error and the generated unknown variant
            _ => crate::SkirResponseOutcome::InternalError,
        }
    }
    fn variant_slug(&self) -> &'static str {
        match self {
            crate::skirout::base::service::v1::identity::IssueServiceIdentityResponse::InternalError(_) => "internal-error",
            crate::skirout::base::service::v1::identity::IssueServiceIdentityResponse::Success(_) => "success",
            crate::skirout::base::service::v1::identity::IssueServiceIdentityResponse::MalformedRequestError(_) => "malformed-request-error",
            crate::skirout::base::service::v1::identity::IssueServiceIdentityResponse::UnknownRoleError(_) => "unknown-role-error",
            crate::skirout::base::service::v1::identity::IssueServiceIdentityResponse::RoleUnknownPropertyError(_) => "role-unknown-property-error",
            crate::skirout::base::service::v1::identity::IssueServiceIdentityResponse::RoleTypeInvalidError(_) => "role-type-invalid-error",
            crate::skirout::base::service::v1::identity::IssueServiceIdentityResponse::RoleVersionInvalidError(_) => "role-version-invalid-error",
            crate::skirout::base::service::v1::identity::IssueServiceIdentityResponse::CustomRoleNameRequiredError(_) => "custom-role-name-required-error",
            crate::skirout::base::service::v1::identity::IssueServiceIdentityResponse::CustomRoleNameInvalidError(_) => "custom-role-name-invalid-error",
            crate::skirout::base::service::v1::identity::IssueServiceIdentityResponse::BuiltinRoleNameForbiddenError(_) => "builtin-role-name-forbidden-error",
            crate::skirout::base::service::v1::identity::IssueServiceIdentityResponse::IdentityProviderUnavailableError(_) => "identity-provider-unavailable-error",
            _ => "unknown",
        }
    }
    fn variant_message(&self) -> String {
        match self {
            crate::skirout::base::service::v1::identity::IssueServiceIdentityResponse::MalformedRequestError(_) => "Malformed request.".to_owned(),
            crate::skirout::base::service::v1::identity::IssueServiceIdentityResponse::UnknownRoleError(_) => "Unknown role.".to_owned(),
            crate::skirout::base::service::v1::identity::IssueServiceIdentityResponse::RoleUnknownPropertyError(_) => "Unknown role property.".to_owned(),
            crate::skirout::base::service::v1::identity::IssueServiceIdentityResponse::RoleTypeInvalidError(_) => "Invalid role type.".to_owned(),
            crate::skirout::base::service::v1::identity::IssueServiceIdentityResponse::RoleVersionInvalidError(_) => "Invalid role version.".to_owned(),
            crate::skirout::base::service::v1::identity::IssueServiceIdentityResponse::CustomRoleNameRequiredError(_) => "Custom role name required.".to_owned(),
            crate::skirout::base::service::v1::identity::IssueServiceIdentityResponse::CustomRoleNameInvalidError(_) => "Invalid custom role name.".to_owned(),
            crate::skirout::base::service::v1::identity::IssueServiceIdentityResponse::BuiltinRoleNameForbiddenError(_) => "Built in role name forbidden.".to_owned(),
            crate::skirout::base::service::v1::identity::IssueServiceIdentityResponse::IdentityProviderUnavailableError(_) => "Identity provider unavailable.".to_owned(),
            other => other.variant_slug().to_owned(),
        }
    }
    fn internal_error() -> Self {
        crate::skirout::base::service::v1::identity::IssueServiceIdentityResponse::InternalError(
            ::std::default::Default::default(),
        )
    }
    fn domain_error_from_slug(slug: &str) -> Option<Self> {
        match slug {
            "malformed-request-error" => Some(crate::skirout::base::service::v1::identity::IssueServiceIdentityResponse::MalformedRequestError(::std::default::Default::default())),
            "unknown-role-error" => Some(crate::skirout::base::service::v1::identity::IssueServiceIdentityResponse::UnknownRoleError(::std::default::Default::default())),
            "role-unknown-property-error" => Some(crate::skirout::base::service::v1::identity::IssueServiceIdentityResponse::RoleUnknownPropertyError(::std::default::Default::default())),
            "role-type-invalid-error" => Some(crate::skirout::base::service::v1::identity::IssueServiceIdentityResponse::RoleTypeInvalidError(::std::default::Default::default())),
            "role-version-invalid-error" => Some(crate::skirout::base::service::v1::identity::IssueServiceIdentityResponse::RoleVersionInvalidError(::std::default::Default::default())),
            "custom-role-name-required-error" => Some(crate::skirout::base::service::v1::identity::IssueServiceIdentityResponse::CustomRoleNameRequiredError(::std::default::Default::default())),
            "custom-role-name-invalid-error" => Some(crate::skirout::base::service::v1::identity::IssueServiceIdentityResponse::CustomRoleNameInvalidError(::std::default::Default::default())),
            "builtin-role-name-forbidden-error" => Some(crate::skirout::base::service::v1::identity::IssueServiceIdentityResponse::BuiltinRoleNameForbiddenError(::std::default::Default::default())),
            "identity-provider-unavailable-error" => Some(crate::skirout::base::service::v1::identity::IssueServiceIdentityResponse::IdentityProviderUnavailableError(::std::default::Default::default())),
            _ => None,
        }
    }
}
impl crate::SkirResponse
    for crate::skirout::base::service::v1::organization::WatchOrganizationServicesResponse
{
    fn to_skir_bytes(&self) -> Vec<u8> {
        Self::serializer().to_bytes(self)
    }
    fn outcome(&self) -> crate::SkirResponseOutcome {
        match self {
            crate::skirout::base::service::v1::organization::WatchOrganizationServicesResponse::List(_) => crate::SkirResponseOutcome::Success,
            // internal_error and the generated unknown variant
            _ => crate::SkirResponseOutcome::InternalError,
        }
    }
    fn variant_slug(&self) -> &'static str {
        match self {
            crate::skirout::base::service::v1::organization::WatchOrganizationServicesResponse::InternalError(_) => "internal-error",
            crate::skirout::base::service::v1::organization::WatchOrganizationServicesResponse::List(_) => "list",
            _ => "unknown",
        }
    }
    fn variant_message(&self) -> String {
        self.variant_slug().to_owned()
    }
    fn internal_error() -> Self {
        crate::skirout::base::service::v1::organization::WatchOrganizationServicesResponse::InternalError(::std::default::Default::default())
    }
}
impl crate::SkirResponse
    for crate::skirout::base::service::v1::organization::UpdateOrganizationServiceResponse
{
    fn to_skir_bytes(&self) -> Vec<u8> {
        Self::serializer().to_bytes(self)
    }
    fn outcome(&self) -> crate::SkirResponseOutcome {
        match self {
            crate::skirout::base::service::v1::organization::UpdateOrganizationServiceResponse::Success(_) => crate::SkirResponseOutcome::Success,
            crate::skirout::base::service::v1::organization::UpdateOrganizationServiceResponse::ConflictError(_) | crate::skirout::base::service::v1::organization::UpdateOrganizationServiceResponse::ServiceNotFoundError(_) | crate::skirout::base::service::v1::organization::UpdateOrganizationServiceResponse::ValidationError(_) | crate::skirout::base::service::v1::organization::UpdateOrganizationServiceResponse::InvalidRecordIdError(_) => crate::SkirResponseOutcome::DomainError,
            // internal_error and the generated unknown variant
            _ => crate::SkirResponseOutcome::InternalError,
        }
    }
    fn variant_slug(&self) -> &'static str {
        match self {
            crate::skirout::base::service::v1::organization::UpdateOrganizationServiceResponse::InternalError(_) => "internal-error",
            crate::skirout::base::service::v1::organization::UpdateOrganizationServiceResponse::Success(_) => "success",
            crate::skirout::base::service::v1::organization::UpdateOrganizationServiceResponse::ConflictError(_) => "conflict-error",
            crate::skirout::base::service::v1::organization::UpdateOrganizationServiceResponse::ServiceNotFoundError(_) => "service-not-found-error",
            crate::skirout::base::service::v1::organization::UpdateOrganizationServiceResponse::ValidationError(_) => "validation-error",
            crate::skirout::base::service::v1::organization::UpdateOrganizationServiceResponse::InvalidRecordIdError(_) => "invalid-record-id-error",
            _ => "unknown",
        }
    }
    fn variant_message(&self) -> String {
        match self {
            crate::skirout::base::service::v1::organization::UpdateOrganizationServiceResponse::ConflictError(_) => "Service changed elsewhere.".to_owned(),
            crate::skirout::base::service::v1::organization::UpdateOrganizationServiceResponse::ServiceNotFoundError(_) => "Service not found in organization.".to_owned(),
            crate::skirout::base::service::v1::organization::UpdateOrganizationServiceResponse::ValidationError(_) => "Service update is invalid.".to_owned(),
            crate::skirout::base::service::v1::organization::UpdateOrganizationServiceResponse::InvalidRecordIdError(_) => "Record IDs from an unexpected table.".to_owned(),
            other => other.variant_slug().to_owned(),
        }
    }
    fn internal_error() -> Self {
        crate::skirout::base::service::v1::organization::UpdateOrganizationServiceResponse::InternalError(::std::default::Default::default())
    }
    fn domain_error_from_slug(slug: &str) -> Option<Self> {
        match slug {
            "conflict-error" => Some(crate::skirout::base::service::v1::organization::UpdateOrganizationServiceResponse::ConflictError(::std::default::Default::default())),
            "service-not-found-error" => Some(crate::skirout::base::service::v1::organization::UpdateOrganizationServiceResponse::ServiceNotFoundError(::std::default::Default::default())),
            "validation-error" => Some(crate::skirout::base::service::v1::organization::UpdateOrganizationServiceResponse::ValidationError(::std::default::Default::default())),
            "invalid-record-id-error" => Some(crate::skirout::base::service::v1::organization::UpdateOrganizationServiceResponse::InvalidRecordIdError(::std::default::Default::default())),
            _ => None,
        }
    }
}
impl crate::SkirResponse for crate::skirout::base::service::v1::registration::BindServiceResponse {
    fn to_skir_bytes(&self) -> Vec<u8> {
        Self::serializer().to_bytes(self)
    }
    fn outcome(&self) -> crate::SkirResponseOutcome {
        match self {
            crate::skirout::base::service::v1::registration::BindServiceResponse::Success(_) => crate::SkirResponseOutcome::Success,
            crate::skirout::base::service::v1::registration::BindServiceResponse::InvalidRegistrationTokenError(_) | crate::skirout::base::service::v1::registration::BindServiceResponse::OrganizationNotFoundError(_) => crate::SkirResponseOutcome::DomainError,
            // internal_error and the generated unknown variant
            _ => crate::SkirResponseOutcome::InternalError,
        }
    }
    fn variant_slug(&self) -> &'static str {
        match self {
            crate::skirout::base::service::v1::registration::BindServiceResponse::InternalError(_) => "internal-error",
            crate::skirout::base::service::v1::registration::BindServiceResponse::Success(_) => "success",
            crate::skirout::base::service::v1::registration::BindServiceResponse::InvalidRegistrationTokenError(_) => "invalid-registration-token-error",
            crate::skirout::base::service::v1::registration::BindServiceResponse::OrganizationNotFoundError(_) => "organization-not-found-error",
            _ => "unknown",
        }
    }
    fn variant_message(&self) -> String {
        match self {
            crate::skirout::base::service::v1::registration::BindServiceResponse::InvalidRegistrationTokenError(_) => "Invalid or expired registration token.".to_owned(),
            crate::skirout::base::service::v1::registration::BindServiceResponse::OrganizationNotFoundError(_) => "Organization not found.".to_owned(),
            other => other.variant_slug().to_owned(),
        }
    }
    fn internal_error() -> Self {
        crate::skirout::base::service::v1::registration::BindServiceResponse::InternalError(
            ::std::default::Default::default(),
        )
    }
    fn domain_error_from_slug(slug: &str) -> Option<Self> {
        match slug {
            "invalid-registration-token-error" => Some(crate::skirout::base::service::v1::registration::BindServiceResponse::InvalidRegistrationTokenError(::std::default::Default::default())),
            "organization-not-found-error" => Some(crate::skirout::base::service::v1::registration::BindServiceResponse::OrganizationNotFoundError(::std::default::Default::default())),
            _ => None,
        }
    }
}
impl crate::SkirResponse
    for crate::skirout::base::service::v1::registration::UnbindServiceResponse
{
    fn to_skir_bytes(&self) -> Vec<u8> {
        Self::serializer().to_bytes(self)
    }
    fn outcome(&self) -> crate::SkirResponseOutcome {
        match self {
            crate::skirout::base::service::v1::registration::UnbindServiceResponse::Success(_) => crate::SkirResponseOutcome::Success,
            crate::skirout::base::service::v1::registration::UnbindServiceResponse::ServiceNotFoundError(_) => crate::SkirResponseOutcome::DomainError,
            // internal_error and the generated unknown variant
            _ => crate::SkirResponseOutcome::InternalError,
        }
    }
    fn variant_slug(&self) -> &'static str {
        match self {
            crate::skirout::base::service::v1::registration::UnbindServiceResponse::InternalError(_) => "internal-error",
            crate::skirout::base::service::v1::registration::UnbindServiceResponse::Success(_) => "success",
            crate::skirout::base::service::v1::registration::UnbindServiceResponse::ServiceNotFoundError(_) => "service-not-found-error",
            _ => "unknown",
        }
    }
    fn variant_message(&self) -> String {
        match self {
            crate::skirout::base::service::v1::registration::UnbindServiceResponse::ServiceNotFoundError(_) => "Service not found in organization.".to_owned(),
            other => other.variant_slug().to_owned(),
        }
    }
    fn internal_error() -> Self {
        crate::skirout::base::service::v1::registration::UnbindServiceResponse::InternalError(
            ::std::default::Default::default(),
        )
    }
    fn domain_error_from_slug(slug: &str) -> Option<Self> {
        match slug {
            "service-not-found-error" => Some(crate::skirout::base::service::v1::registration::UnbindServiceResponse::ServiceNotFoundError(::std::default::Default::default())),
            _ => None,
        }
    }
}
impl crate::SkirResponse for crate::skirout::base::service::v1::rollout::ProbeRealmHostsResponse {
    fn to_skir_bytes(&self) -> Vec<u8> {
        Self::serializer().to_bytes(self)
    }
    fn outcome(&self) -> crate::SkirResponseOutcome {
        match self {
            crate::skirout::base::service::v1::rollout::ProbeRealmHostsResponse::Present(_) => {
                crate::SkirResponseOutcome::Success
            }
            // internal_error and the generated unknown variant
            _ => crate::SkirResponseOutcome::InternalError,
        }
    }
    fn variant_slug(&self) -> &'static str {
        match self {
            crate::skirout::base::service::v1::rollout::ProbeRealmHostsResponse::Present(_) => {
                "present"
            }
            crate::skirout::base::service::v1::rollout::ProbeRealmHostsResponse::InternalError(
                _,
            ) => "internal-error",
            _ => "unknown",
        }
    }
    fn variant_message(&self) -> String {
        self.variant_slug().to_owned()
    }
    fn internal_error() -> Self {
        crate::skirout::base::service::v1::rollout::ProbeRealmHostsResponse::InternalError(
            ::std::default::Default::default(),
        )
    }
}
impl crate::SkirResponse
    for crate::skirout::base::service::v1::rollout::ApplyRolloutCommandResponse
{
    fn to_skir_bytes(&self) -> Vec<u8> {
        Self::serializer().to_bytes(self)
    }
    fn outcome(&self) -> crate::SkirResponseOutcome {
        match self {
            crate::skirout::base::service::v1::rollout::ApplyRolloutCommandResponse::Accepted(_) => crate::SkirResponseOutcome::Success,
            crate::skirout::base::service::v1::rollout::ApplyRolloutCommandResponse::StaleAttemptError(_) | crate::skirout::base::service::v1::rollout::ApplyRolloutCommandResponse::AttemptConflictError(_) | crate::skirout::base::service::v1::rollout::ApplyRolloutCommandResponse::CommandRejectedError(_) | crate::skirout::base::service::v1::rollout::ApplyRolloutCommandResponse::CommandFailedError(_) => crate::SkirResponseOutcome::DomainError,
            // internal_error and the generated unknown variant
            _ => crate::SkirResponseOutcome::InternalError,
        }
    }
    fn variant_slug(&self) -> &'static str {
        match self {
            crate::skirout::base::service::v1::rollout::ApplyRolloutCommandResponse::Accepted(_) => "accepted",
            crate::skirout::base::service::v1::rollout::ApplyRolloutCommandResponse::StaleAttemptError(_) => "stale-attempt-error",
            crate::skirout::base::service::v1::rollout::ApplyRolloutCommandResponse::AttemptConflictError(_) => "attempt-conflict-error",
            crate::skirout::base::service::v1::rollout::ApplyRolloutCommandResponse::CommandRejectedError(_) => "command-rejected-error",
            crate::skirout::base::service::v1::rollout::ApplyRolloutCommandResponse::CommandFailedError(_) => "command-failed-error",
            crate::skirout::base::service::v1::rollout::ApplyRolloutCommandResponse::InternalError(_) => "internal-error",
            _ => "unknown",
        }
    }
    fn variant_message(&self) -> String {
        match self {
            crate::skirout::base::service::v1::rollout::ApplyRolloutCommandResponse::StaleAttemptError(_) => "Rollout attempt is stale.".to_owned(),
            crate::skirout::base::service::v1::rollout::ApplyRolloutCommandResponse::AttemptConflictError(_) => "Rollout attempt conflicts with another projection.".to_owned(),
            crate::skirout::base::service::v1::rollout::ApplyRolloutCommandResponse::CommandRejectedError(_) => "Participant rejected the command in its current lifecycle state.".to_owned(),
            crate::skirout::base::service::v1::rollout::ApplyRolloutCommandResponse::CommandFailedError(_) => "Participant failed while applying the command.".to_owned(),
            other => other.variant_slug().to_owned(),
        }
    }
    fn internal_error() -> Self {
        crate::skirout::base::service::v1::rollout::ApplyRolloutCommandResponse::InternalError(
            ::std::default::Default::default(),
        )
    }
    fn domain_error_from_slug(slug: &str) -> Option<Self> {
        match slug {
            "stale-attempt-error" => Some(crate::skirout::base::service::v1::rollout::ApplyRolloutCommandResponse::StaleAttemptError(::std::default::Default::default())),
            "attempt-conflict-error" => Some(crate::skirout::base::service::v1::rollout::ApplyRolloutCommandResponse::AttemptConflictError(::std::default::Default::default())),
            "command-rejected-error" => Some(crate::skirout::base::service::v1::rollout::ApplyRolloutCommandResponse::CommandRejectedError(::std::default::Default::default())),
            "command-failed-error" => Some(crate::skirout::base::service::v1::rollout::ApplyRolloutCommandResponse::CommandFailedError(::std::default::Default::default())),
            _ => None,
        }
    }
}
impl crate::SkirResponse
    for crate::skirout::base::service::v1::rollout::QueryParticipantStatusResponse
{
    fn to_skir_bytes(&self) -> Vec<u8> {
        Self::serializer().to_bytes(self)
    }
    fn outcome(&self) -> crate::SkirResponseOutcome {
        match self {
            crate::skirout::base::service::v1::rollout::QueryParticipantStatusResponse::Status(
                _,
            ) => crate::SkirResponseOutcome::Success,
            // internal_error and the generated unknown variant
            _ => crate::SkirResponseOutcome::InternalError,
        }
    }
    fn variant_slug(&self) -> &'static str {
        match self {
            crate::skirout::base::service::v1::rollout::QueryParticipantStatusResponse::Status(_) => "status",
            crate::skirout::base::service::v1::rollout::QueryParticipantStatusResponse::InternalError(_) => "internal-error",
            _ => "unknown",
        }
    }
    fn variant_message(&self) -> String {
        self.variant_slug().to_owned()
    }
    fn internal_error() -> Self {
        crate::skirout::base::service::v1::rollout::QueryParticipantStatusResponse::InternalError(
            ::std::default::Default::default(),
        )
    }
}
impl crate::SkirResponse
    for crate::skirout::base::service::v1::status::QueryServiceBindingResponse
{
    fn to_skir_bytes(&self) -> Vec<u8> {
        Self::serializer().to_bytes(self)
    }
    fn outcome(&self) -> crate::SkirResponseOutcome {
        match self {
            crate::skirout::base::service::v1::status::QueryServiceBindingResponse::Binding(_) => crate::SkirResponseOutcome::Success,
            crate::skirout::base::service::v1::status::QueryServiceBindingResponse::ServiceNotFoundError(_) => crate::SkirResponseOutcome::DomainError,
            // internal_error and the generated unknown variant
            _ => crate::SkirResponseOutcome::InternalError,
        }
    }
    fn variant_slug(&self) -> &'static str {
        match self {
            crate::skirout::base::service::v1::status::QueryServiceBindingResponse::Binding(_) => "binding",
            crate::skirout::base::service::v1::status::QueryServiceBindingResponse::ServiceNotFoundError(_) => "service-not-found-error",
            crate::skirout::base::service::v1::status::QueryServiceBindingResponse::InternalError(_) => "internal-error",
            _ => "unknown",
        }
    }
    fn variant_message(&self) -> String {
        match self {
            crate::skirout::base::service::v1::status::QueryServiceBindingResponse::ServiceNotFoundError(_) => "Service not found.".to_owned(),
            other => other.variant_slug().to_owned(),
        }
    }
    fn internal_error() -> Self {
        crate::skirout::base::service::v1::status::QueryServiceBindingResponse::InternalError(
            ::std::default::Default::default(),
        )
    }
    fn domain_error_from_slug(slug: &str) -> Option<Self> {
        match slug {
            "service-not-found-error" => Some(crate::skirout::base::service::v1::status::QueryServiceBindingResponse::ServiceNotFoundError(::std::default::Default::default())),
            _ => None,
        }
    }
}
impl crate::SkirResponse
    for crate::skirout::base::service::v1::status::EnsureRegistrationLeaseResponse
{
    fn to_skir_bytes(&self) -> Vec<u8> {
        Self::serializer().to_bytes(self)
    }
    fn outcome(&self) -> crate::SkirResponseOutcome {
        match self {
            crate::skirout::base::service::v1::status::EnsureRegistrationLeaseResponse::Issued(_) | crate::skirout::base::service::v1::status::EnsureRegistrationLeaseResponse::AlreadyBound(_) => crate::SkirResponseOutcome::Success,
            crate::skirout::base::service::v1::status::EnsureRegistrationLeaseResponse::ServiceNotFoundError(_) => crate::SkirResponseOutcome::DomainError,
            // internal_error and the generated unknown variant
            _ => crate::SkirResponseOutcome::InternalError,
        }
    }
    fn variant_slug(&self) -> &'static str {
        match self {
            crate::skirout::base::service::v1::status::EnsureRegistrationLeaseResponse::Issued(_) => "issued",
            crate::skirout::base::service::v1::status::EnsureRegistrationLeaseResponse::AlreadyBound(_) => "already-bound",
            crate::skirout::base::service::v1::status::EnsureRegistrationLeaseResponse::ServiceNotFoundError(_) => "service-not-found-error",
            crate::skirout::base::service::v1::status::EnsureRegistrationLeaseResponse::InternalError(_) => "internal-error",
            _ => "unknown",
        }
    }
    fn variant_message(&self) -> String {
        match self {
            crate::skirout::base::service::v1::status::EnsureRegistrationLeaseResponse::ServiceNotFoundError(_) => "Service not found.".to_owned(),
            other => other.variant_slug().to_owned(),
        }
    }
    fn internal_error() -> Self {
        crate::skirout::base::service::v1::status::EnsureRegistrationLeaseResponse::InternalError(
            ::std::default::Default::default(),
        )
    }
    fn domain_error_from_slug(slug: &str) -> Option<Self> {
        match slug {
            "service-not-found-error" => Some(crate::skirout::base::service::v1::status::EnsureRegistrationLeaseResponse::ServiceNotFoundError(::std::default::Default::default())),
            _ => None,
        }
    }
}
impl crate::SkirResponse
    for crate::skirout::base::service::v1::topology::ConfigureServiceHostResponse
{
    fn to_skir_bytes(&self) -> Vec<u8> {
        Self::serializer().to_bytes(self)
    }
    fn outcome(&self) -> crate::SkirResponseOutcome {
        match self {
            crate::skirout::base::service::v1::topology::ConfigureServiceHostResponse::Success(_) => crate::SkirResponseOutcome::Success,
            crate::skirout::base::service::v1::topology::ConfigureServiceHostResponse::ConflictError(_) | crate::skirout::base::service::v1::topology::ConfigureServiceHostResponse::InvalidConfigurationError(_) | crate::skirout::base::service::v1::topology::ConfigureServiceHostResponse::IncompatibleEngineError(_) | crate::skirout::base::service::v1::topology::ConfigureServiceHostResponse::RealmNotFoundError(_) | crate::skirout::base::service::v1::topology::ConfigureServiceHostResponse::InvalidRecordIdError(_) => crate::SkirResponseOutcome::DomainError,
            // internal_error and the generated unknown variant
            _ => crate::SkirResponseOutcome::InternalError,
        }
    }
    fn variant_slug(&self) -> &'static str {
        match self {
            crate::skirout::base::service::v1::topology::ConfigureServiceHostResponse::Success(_) => "success",
            crate::skirout::base::service::v1::topology::ConfigureServiceHostResponse::ConflictError(_) => "conflict-error",
            crate::skirout::base::service::v1::topology::ConfigureServiceHostResponse::InvalidConfigurationError(_) => "invalid-configuration-error",
            crate::skirout::base::service::v1::topology::ConfigureServiceHostResponse::IncompatibleEngineError(_) => "incompatible-engine-error",
            crate::skirout::base::service::v1::topology::ConfigureServiceHostResponse::RealmNotFoundError(_) => "realm-not-found-error",
            crate::skirout::base::service::v1::topology::ConfigureServiceHostResponse::InvalidRecordIdError(_) => "invalid-record-id-error",
            crate::skirout::base::service::v1::topology::ConfigureServiceHostResponse::InternalError(_) => "internal-error",
            _ => "unknown",
        }
    }
    fn variant_message(&self) -> String {
        match self {
            crate::skirout::base::service::v1::topology::ConfigureServiceHostResponse::ConflictError(_) => "Host changed elsewhere.".to_owned(),
            crate::skirout::base::service::v1::topology::ConfigureServiceHostResponse::InvalidConfigurationError(_) => "Host configuration is invalid.".to_owned(),
            crate::skirout::base::service::v1::topology::ConfigureServiceHostResponse::IncompatibleEngineError(_) => "Engine target is incompatible.".to_owned(),
            crate::skirout::base::service::v1::topology::ConfigureServiceHostResponse::RealmNotFoundError(_) => "Realm not found.".to_owned(),
            crate::skirout::base::service::v1::topology::ConfigureServiceHostResponse::InvalidRecordIdError(_) => "Record IDs from an unexpected table.".to_owned(),
            other => other.variant_slug().to_owned(),
        }
    }
    fn internal_error() -> Self {
        crate::skirout::base::service::v1::topology::ConfigureServiceHostResponse::InternalError(
            ::std::default::Default::default(),
        )
    }
    fn domain_error_from_slug(slug: &str) -> Option<Self> {
        match slug {
            "conflict-error" => Some(crate::skirout::base::service::v1::topology::ConfigureServiceHostResponse::ConflictError(::std::default::Default::default())),
            "invalid-configuration-error" => Some(crate::skirout::base::service::v1::topology::ConfigureServiceHostResponse::InvalidConfigurationError(::std::default::Default::default())),
            "incompatible-engine-error" => Some(crate::skirout::base::service::v1::topology::ConfigureServiceHostResponse::IncompatibleEngineError(::std::default::Default::default())),
            "realm-not-found-error" => Some(crate::skirout::base::service::v1::topology::ConfigureServiceHostResponse::RealmNotFoundError(::std::default::Default::default())),
            "invalid-record-id-error" => Some(crate::skirout::base::service::v1::topology::ConfigureServiceHostResponse::InvalidRecordIdError(::std::default::Default::default())),
            _ => None,
        }
    }
}
impl crate::SkirResponse
    for crate::skirout::base::service::v1::topology::WatchOrganizationTopologyResponse
{
    fn to_skir_bytes(&self) -> Vec<u8> {
        Self::serializer().to_bytes(self)
    }
    fn outcome(&self) -> crate::SkirResponseOutcome {
        match self {
            crate::skirout::base::service::v1::topology::WatchOrganizationTopologyResponse::List(_) => crate::SkirResponseOutcome::Success,
            // internal_error and the generated unknown variant
            _ => crate::SkirResponseOutcome::InternalError,
        }
    }
    fn variant_slug(&self) -> &'static str {
        match self {
            crate::skirout::base::service::v1::topology::WatchOrganizationTopologyResponse::List(_) => "list",
            crate::skirout::base::service::v1::topology::WatchOrganizationTopologyResponse::InternalError(_) => "internal-error",
            _ => "unknown",
        }
    }
    fn variant_message(&self) -> String {
        self.variant_slug().to_owned()
    }
    fn internal_error() -> Self {
        crate::skirout::base::service::v1::topology::WatchOrganizationTopologyResponse::InternalError(::std::default::Default::default())
    }
}
impl crate::SkirResponse
    for crate::skirout::base::service::v1::topology::WatchHostExecutionResponse
{
    fn to_skir_bytes(&self) -> Vec<u8> {
        Self::serializer().to_bytes(self)
    }
    fn outcome(&self) -> crate::SkirResponseOutcome {
        match self {
            crate::skirout::base::service::v1::topology::WatchHostExecutionResponse::Desired(_) => {
                crate::SkirResponseOutcome::Success
            }
            // internal_error and the generated unknown variant
            _ => crate::SkirResponseOutcome::InternalError,
        }
    }
    fn variant_slug(&self) -> &'static str {
        match self {
            crate::skirout::base::service::v1::topology::WatchHostExecutionResponse::Desired(_) => "desired",
            crate::skirout::base::service::v1::topology::WatchHostExecutionResponse::InternalError(_) => "internal-error",
            _ => "unknown",
        }
    }
    fn variant_message(&self) -> String {
        self.variant_slug().to_owned()
    }
    fn internal_error() -> Self {
        crate::skirout::base::service::v1::topology::WatchHostExecutionResponse::InternalError(
            ::std::default::Default::default(),
        )
    }
}
impl crate::SkirResponse
    for crate::skirout::base::service::v1::topology::ReportHostExecutionResponse
{
    fn to_skir_bytes(&self) -> Vec<u8> {
        Self::serializer().to_bytes(self)
    }
    fn outcome(&self) -> crate::SkirResponseOutcome {
        match self {
            crate::skirout::base::service::v1::topology::ReportHostExecutionResponse::Success(_) => crate::SkirResponseOutcome::Success,
            crate::skirout::base::service::v1::topology::ReportHostExecutionResponse::StaleRevisionError(_) => crate::SkirResponseOutcome::DomainError,
            // internal_error and the generated unknown variant
            _ => crate::SkirResponseOutcome::InternalError,
        }
    }
    fn variant_slug(&self) -> &'static str {
        match self {
            crate::skirout::base::service::v1::topology::ReportHostExecutionResponse::Success(_) => "success",
            crate::skirout::base::service::v1::topology::ReportHostExecutionResponse::StaleRevisionError(_) => "stale-revision-error",
            crate::skirout::base::service::v1::topology::ReportHostExecutionResponse::InternalError(_) => "internal-error",
            _ => "unknown",
        }
    }
    fn variant_message(&self) -> String {
        match self {
            crate::skirout::base::service::v1::topology::ReportHostExecutionResponse::StaleRevisionError(_) => "Host topology revision is stale.".to_owned(),
            other => other.variant_slug().to_owned(),
        }
    }
    fn internal_error() -> Self {
        crate::skirout::base::service::v1::topology::ReportHostExecutionResponse::InternalError(
            ::std::default::Default::default(),
        )
    }
    fn domain_error_from_slug(slug: &str) -> Option<Self> {
        match slug {
            "stale-revision-error" => Some(crate::skirout::base::service::v1::topology::ReportHostExecutionResponse::StaleRevisionError(::std::default::Default::default())),
            _ => None,
        }
    }
}
impl crate::SkirResponse
    for crate::skirout::base::service::v1::topology::GetServiceMessagingScopeResponse
{
    fn to_skir_bytes(&self) -> Vec<u8> {
        Self::serializer().to_bytes(self)
    }
    fn outcome(&self) -> crate::SkirResponseOutcome {
        match self {
            crate::skirout::base::service::v1::topology::GetServiceMessagingScopeResponse::Found(_) => crate::SkirResponseOutcome::Success,
            crate::skirout::base::service::v1::topology::GetServiceMessagingScopeResponse::NotFoundError(_) => crate::SkirResponseOutcome::DomainError,
            // internal_error and the generated unknown variant
            _ => crate::SkirResponseOutcome::InternalError,
        }
    }
    fn variant_slug(&self) -> &'static str {
        match self {
            crate::skirout::base::service::v1::topology::GetServiceMessagingScopeResponse::Found(_) => "found",
            crate::skirout::base::service::v1::topology::GetServiceMessagingScopeResponse::NotFoundError(_) => "not-found-error",
            crate::skirout::base::service::v1::topology::GetServiceMessagingScopeResponse::InternalError(_) => "internal-error",
            _ => "unknown",
        }
    }
    fn variant_message(&self) -> String {
        match self {
            crate::skirout::base::service::v1::topology::GetServiceMessagingScopeResponse::NotFoundError(_) => "Service messaging scope not found.".to_owned(),
            other => other.variant_slug().to_owned(),
        }
    }
    fn internal_error() -> Self {
        crate::skirout::base::service::v1::topology::GetServiceMessagingScopeResponse::InternalError(
            ::std::default::Default::default(),
        )
    }
    fn domain_error_from_slug(slug: &str) -> Option<Self> {
        match slug {
            "not-found-error" => Some(crate::skirout::base::service::v1::topology::GetServiceMessagingScopeResponse::NotFoundError(::std::default::Default::default())),
            _ => None,
        }
    }
}
impl crate::SkirResponse
    for crate::skirout::base::service::v1::topology::RegisterServiceHostResponse
{
    fn to_skir_bytes(&self) -> Vec<u8> {
        Self::serializer().to_bytes(self)
    }
    fn outcome(&self) -> crate::SkirResponseOutcome {
        match self {
            crate::skirout::base::service::v1::topology::RegisterServiceHostResponse::Success(
                _,
            ) => crate::SkirResponseOutcome::Success,
            // internal_error and the generated unknown variant
            _ => crate::SkirResponseOutcome::InternalError,
        }
    }
    fn variant_slug(&self) -> &'static str {
        match self {
            crate::skirout::base::service::v1::topology::RegisterServiceHostResponse::Success(_) => "success",
            crate::skirout::base::service::v1::topology::RegisterServiceHostResponse::InternalError(_) => "internal-error",
            _ => "unknown",
        }
    }
    fn variant_message(&self) -> String {
        self.variant_slug().to_owned()
    }
    fn internal_error() -> Self {
        crate::skirout::base::service::v1::topology::RegisterServiceHostResponse::InternalError(
            ::std::default::Default::default(),
        )
    }
}
