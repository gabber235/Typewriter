//! Access: the policy requests the auth callout sends the permission component, the grants it
//! answers with, and service registration as the permission component asks it about a service.

use anyhow::Result;
use base64::{Engine as _, engine::general_purpose::URL_SAFE_NO_PAD};
use component_test::{TestContext, subject_matches};
use serde_json::json;
use wasmcloud_utils::{
    SkirType,
    skir::base::{
        access::v1::permission::{
            EntityPermissionGrant, EntityPermissionQualifier, EntityPermissionQualifier_User,
            GetEntityPermissionRequest, GetEntityPermissionResponse, Permission, Permissions,
        },
        kernel::v1::record_id::RecordId,
        service::v1::{
            status::{
                QueryServiceBindingRequest, QueryServiceBindingResponse,
                QueryServiceBindingResponse_Binding, ServiceBinding, ServiceBinding_Bound,
            },
            topology::{
                GetServiceMessagingScopeRequest, GetServiceMessagingScopeResponse,
                ServiceMessagingScope,
            },
        },
    },
    skir_variant,
};

use crate::{
    Organization, SkirMessagingExpectationExt, StackUser, TypewriterContext, acme, skir_record_id,
};

/// The connection session every panel sign in names in its policy request.
pub const SESSION: &str = "0123456789abcdef0123456789abcdef";

/// The permission policy a panel sign in is resolved by.
pub const PANEL_POLICY: &str = "auth.permissions.typewriter-panel";

/// The permission policy a service sign in is resolved by.
pub const SERVICE_POLICY: &str = "auth.permissions.typewriter-services";

/// The policy request the callout sends when a person with the identity provider subject
/// `subject` and display name `name` signs in to the panel with `organization` selected.
pub fn sign_in(
    subject: &str,
    name: &str,
    organization: Option<RecordId>,
) -> GetEntityPermissionRequest {
    let claims = json!({
        "sub": subject,
        "name": name,
        "email": "panel@example.test",
        "avatar_url": "https://example.test/avatar.png"
    });
    GetEntityPermissionRequest {
        qualifier: EntityPermissionQualifier::User(Box::new(EntityPermissionQualifier_User {
            organization_id: organization,
            connection_session: SESSION.into(),
            ..Default::default()
        })),
        jwt_claims: serde_json::to_vec(&claims).expect("claims are valid JSON"),
        ..Default::default()
    }
}

/// The policy request the callout sends when the service `service` connects.
pub fn service_sign_in(service: &str) -> GetEntityPermissionRequest {
    GetEntityPermissionRequest {
        qualifier: EntityPermissionQualifier::Service(Box::default()),
        jwt_claims: serde_json::to_vec(&json!({
            "sub": service,
            "preferred_username": "Fixture Service"
        }))
        .expect("claims are valid JSON"),
        ..Default::default()
    }
}

/// Asks the permission `policy` to resolve `request`, failing on any reply but a grant.
pub async fn request_permissions<F>(
    context: &TestContext<F>,
    policy: &str,
    request: &GetEntityPermissionRequest,
) -> Result<EntityPermissionGrant> {
    let reply: GetEntityPermissionResponse = context.request(policy, request).await?;
    match reply {
        GetEntityPermissionResponse::Granted(grant) => Ok(*grant),
        other => anyhow::bail!("expected granted permissions, received {other:?}"),
    }
}

/// The permissions `user` receives on signing in to the panel with `organization` selected.
pub async fn member_grants<F>(
    context: &TestContext<F>,
    user: &StackUser,
    organization: &Organization,
) -> Result<Permissions> {
    let request = sign_in(user.token(), &user.username, Some(organization.id()));
    Ok(request_permissions(context, PANEL_POLICY, &request)
        .await?
        .permissions)
}

/// The permissions `service` receives once registration reports it bound to Acme and running
/// `realm`.
pub async fn service_grants<F>(
    context: &TestContext<F>,
    service: &str,
    realm: Realm,
) -> Result<Permissions> {
    bound_service(context, service, realm)?;
    Ok(
        request_permissions(context, SERVICE_POLICY, &service_sign_in(service))
            .await?
            .permissions,
    )
}

/// Whether the broker lets a holder of `permission` use `subject`.
pub fn permits(permission: &Permission, subject: &str) -> bool {
    permission
        .allow
        .iter()
        .any(|pattern| subject_matches(pattern, subject))
        && !permission
            .deny
            .iter()
            .any(|pattern| subject_matches(pattern, subject))
}

/// The reply inbox `name` of `user`'s panel session.
pub fn panel_inbox(user: &StackUser, name: &str) -> String {
    format!("_INBOX.{}.{SESSION}.{name}", user.token())
}

/// Asserts that `publish` lets `user` run the JetStream consumer of the membership stream for
/// `projection`, filtered to `filter`, in `organization` or outside every organization.
///
/// The consumer name is written out here rather than taken from the component, so a change to
/// how the component names consumers fails this check.
pub fn assert_consumer_grant(
    publish: &[String],
    user: &StackUser,
    organization: Option<&str>,
    projection: &str,
    filter: &str,
) {
    let identity = serde_json::to_vec(&(user.token(), organization, SESSION, projection))
        .expect("consumer identity is valid JSON");
    let consumer = format!("TW_{}", URL_SAFE_NO_PAD.encode(identity));
    for subject in [
        "$JS.API.STREAM.INFO.TYPEWRITER_MEMBERSHIP".to_owned(),
        format!("$JS.API.CONSUMER.CREATE.TYPEWRITER_MEMBERSHIP.{consumer}.{filter}"),
        format!("$JS.API.CONSUMER.INFO.TYPEWRITER_MEMBERSHIP.{consumer}"),
        format!("$JS.API.CONSUMER.MSG.NEXT.TYPEWRITER_MEMBERSHIP.{consumer}"),
        format!("$JS.API.CONSUMER.DELETE.TYPEWRITER_MEMBERSHIP.{consumer}"),
    ] {
        assert!(
            publish.contains(&subject),
            "missing consumer grant {subject}"
        );
    }
}

/// The realm a bound service runs, as service registration reports it.
#[derive(Clone, Copy)]
pub enum Realm {
    None,
    /// The service hosts the realm and coordinates it.
    Owned(&'static str),
    /// The service runs an engine attached to another host's realm.
    Attached(&'static str),
}

/// Service registration answers that `service` is bound to Acme and runs `realm`.
pub fn bound_service<F>(context: &TestContext<F>, service: &str, realm: Realm) -> Result<()> {
    expect_bound(context, service)?;
    let realm_id = |key: &str| Some(skir_record_id("realm_instance", key));
    let (owned_realm, attached_realm) = match realm {
        Realm::None => (None, None),
        Realm::Owned(key) => (realm_id(key), None),
        Realm::Attached(key) => (None, realm_id(key)),
    };
    expect_scope(
        context,
        service,
        GetServiceMessagingScopeResponse::Found(Box::new(ServiceMessagingScope {
            organization_id: acme().key,
            owned_realm,
            attached_realm,
            ..Default::default()
        })),
    )
}

/// Service registration answers that `service` is bound to Acme, leaving its scope to the case.
pub fn expect_bound<F>(context: &TestContext<F>, service: &str) -> Result<()> {
    expect_binding(
        context,
        service,
        skir_variant!(QueryServiceBindingResponse::Binding {
            binding: ServiceBinding::Bound(Box::new(ServiceBinding_Bound {
                organization_id: acme().key,
                organization_name: Some("Acme".into()),
                ..Default::default()
            })),
        }),
    )
}

/// Service registration is asked for the binding of `service`, and answers `binding`.
pub fn expect_binding<F>(
    context: &TestContext<F>,
    service: &str,
    binding: QueryServiceBindingResponse,
) -> Result<()> {
    expect_registration_query(
        context,
        &format!("service.{service}.binding.query"),
        &QueryServiceBindingRequest::default(),
        &binding,
    )
}

/// Service registration is asked for the messaging scope of `service`, and answers `scope`.
pub fn expect_scope<F>(
    context: &TestContext<F>,
    service: &str,
    scope: GetServiceMessagingScopeResponse,
) -> Result<()> {
    expect_registration_query(
        context,
        &format!("service.{service}.messaging.scope"),
        &GetServiceMessagingScopeRequest {
            service_id: skir_record_id("service", service),
            ..Default::default()
        },
        &scope,
    )
}

fn expect_registration_query<F, Req: SkirType, Resp: SkirType>(
    context: &TestContext<F>,
    subject: &str,
    request: &Req,
    reply: &Resp,
) -> Result<()> {
    context
        .messaging_mock()?
        .expect_request(subject)
        .body_skir(request)
        .reply_skir(reply);
    Ok(())
}
