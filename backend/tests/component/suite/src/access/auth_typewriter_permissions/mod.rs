mod panel;
mod service;

use std::time::Duration;

use component_test::{FixtureBuilder, FixtureSpec, TestContext, component_fixture};
use typewriter_component_test::prelude::{
    SchemaPreset, SkirMessagingExt, TypewriterFixtureBuilderExt,
};
use wasmcloud_utils::{
    skir::base::access::v1::permission::{GetEntityPermissionRequest, GetEntityPermissionResponse},
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
        "backend/database/schema/user.surql"
    )
)]
pub struct AuthTypewriterPermissions;

impl FixtureSpec for AuthTypewriterPermissions {
    fn configure(builder: FixtureBuilder<Self>) -> FixtureBuilder<Self> {
        builder
            .messaging_subscription("auth.permissions.typewriter-panel")
            .messaging_subscription("auth.permissions.typewriter-services")
            .otel()
            .typewriter_database(SchemaPreset::Organization)
    }
}

async fn request_permissions(
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
