mod broker;
mod panel;
mod service;

use typewriter_component_test::prelude::*;
use wasmcloud_utils::{
    skir::base::{
        access::v1::permission::{
            EntityPermissionGrant, GetEntityPermissionRequest, GetEntityPermissionResponse,
            Permission,
        },
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

#[component_fixture(
    id = "auth-typewriter-permissions",
    primary(
        package = "auth-typewriter-permissions",
        target = "auth_typewriter_permissions"
    )
)]
pub struct AuthTypewriterPermissions;

impl FixtureSpec for AuthTypewriterPermissions {
    fn configure(builder: FixtureBuilder<Self>) -> FixtureBuilder<Self> {
        builder
            .messaging_subscriptions(
                wasmcloud_utils::transport_routes::auth_typewriter_permissions::SUBSCRIPTIONS,
            )
            .otel()
            .typewriter_database(SchemaPreset::Full)
    }
}

type Context = TestContext<AuthTypewriterPermissions>;

const PANEL_POLICY: &str = "auth.permissions.typewriter-panel";
const SERVICE_POLICY: &str = "auth.permissions.typewriter-services";

/// Requests policy resolution and returns the granted permissions, failing on any other reply.
async fn request_permissions(
    context: &Context,
    subject: &str,
    request: &GetEntityPermissionRequest,
) -> anyhow::Result<EntityPermissionGrant> {
    let reply: GetEntityPermissionResponse = context.request(subject, request).await?;
    match reply {
        GetEntityPermissionResponse::Granted(grant) => Ok(*grant),
        other => anyhow::bail!("expected granted permissions, received {other:?}"),
    }
}

/// Whether the broker lets a holder of `permission` use `subject`.
fn permits(permission: &Permission, subject: &str) -> bool {
    permission
        .allow
        .iter()
        .any(|pattern| subject_matches(pattern, subject))
        && !permission
            .deny
            .iter()
            .any(|pattern| subject_matches(pattern, subject))
}

/// The realm a bound service runs, as service registration reports it.
#[derive(Clone, Copy)]
enum Realm {
    None,
    /// The service hosts the realm and coordinates it.
    Owned(&'static str),
    /// The service runs an engine attached to another host's realm.
    Attached(&'static str),
}

/// Service registration answers that `service` is bound to Acme and runs `realm`.
fn bound_service(context: &Context, service: &str, realm: Realm) -> anyhow::Result<()> {
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
    )?;
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

/// Service registration answers the binding query of `service` with `binding`.
fn expect_binding(
    context: &Context,
    service: &str,
    binding: QueryServiceBindingResponse,
) -> anyhow::Result<()> {
    context
        .messaging_mock()?
        .expect_request(format!("service.{service}.binding.query"))
        .body_skir(&QueryServiceBindingRequest::default())
        .reply_skir(&binding);
    Ok(())
}

/// Service registration answers the messaging scope query of `service` with `scope`.
fn expect_scope(
    context: &Context,
    service: &str,
    scope: GetServiceMessagingScopeResponse,
) -> anyhow::Result<()> {
    context
        .messaging_mock()?
        .expect_request(format!("service.{service}.messaging.scope"))
        .body_skir(&GetServiceMessagingScopeRequest {
            service_id: skir_record_id("service", service),
            ..Default::default()
        })
        .reply_skir(&scope);
    Ok(())
}
