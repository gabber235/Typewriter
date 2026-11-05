use typewriter_component_test::prelude::*;

mod binding;
mod lifecycle;
mod management;
mod status;
mod topology;

#[component_fixture(
    id = "service-registration",
    primary(package = "service-registration", target = "service_registration")
)]
pub struct ServiceRegistration;

impl FixtureSpec for ServiceRegistration {
    fn configure(builder: FixtureBuilder<Self>) -> FixtureBuilder<Self> {
        builder
            .messaging_subscriptions(
                wasmcloud_utils::transport_routes::service_registration::SUBSCRIPTIONS,
            )
            .otel()
            .typewriter_database(SchemaPreset::Registration)
    }
}
