mod panel;
mod service;

use std::time::Duration;

use component_test::{FixtureBuilder, FixtureSpec, TestContext, component_fixture};
use typewriter_component_test::prelude::{
    SchemaPreset, SkirMessagingExt, TypewriterFixtureBuilderExt,
};
use wasmcloud_utils::{
    skir::base::access::v1::permission::{
        EntityPermissionGrant, GetEntityPermissionRequest, GetEntityPermissionResponse,
    },
    skir_client::UnrecognizedValues,
};

#[component_fixture(
    id = "auth-typewriter-permissions",
    primary(
        package = "auth-typewriter-permissions",
        target = "auth_typewriter_permissions"
    ),
    affected_paths(
        "backend/access/auth-typewriter-permissions/",
        "backend/database/schema/organization/",
        "backend/database/schema/service/",
        "backend/database/schema/user.surql"
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

/// Requests policy resolution and returns the typed reply, including a failure reply.
async fn request_permission_response(
    context: &TestContext<AuthTypewriterPermissions>,
    subject: &str,
    request: &GetEntityPermissionRequest,
) -> anyhow::Result<GetEntityPermissionResponse> {
    context
        .messaging()?
        .request_skir(
            subject,
            request,
            GetEntityPermissionRequest::serializer(),
            GetEntityPermissionResponse::serializer(),
            Duration::from_secs(2),
            UnrecognizedValues::Drop,
        )
        .await
}

/// Requests policy resolution and returns the granted permissions, failing on any other reply.
async fn request_permissions(
    context: &TestContext<AuthTypewriterPermissions>,
    subject: &str,
    request: &GetEntityPermissionRequest,
) -> anyhow::Result<EntityPermissionGrant> {
    match request_permission_response(context, subject, request).await? {
        GetEntityPermissionResponse::Granted(grant) => Ok(*grant),
        other => anyhow::bail!("expected granted permissions, received {other:?}"),
    }
}
