mod broker;
mod panel;
mod service;

use typewriter_component_test::prelude::*;

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
