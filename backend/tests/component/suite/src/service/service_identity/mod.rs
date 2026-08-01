use component_test::{FixtureBuilder, FixtureSpec, component_fixture};
use typewriter_component_test::prelude::{SchemaPreset, TypewriterFixtureBuilderExt};

mod http_contract;
mod issuance;

pub(crate) struct Authentik;

#[component_fixture(
    id = "service-identity",
    primary(package = "service-identity", target = "service_identity"),
    affected_paths(
        "backend/service/service-identity/",
        "backend/database/schema/service/"
    )
)]
pub struct ServiceIdentity;

impl FixtureSpec for ServiceIdentity {
    fn configure(builder: FixtureBuilder<Self>) -> FixtureBuilder<Self> {
        builder
            .http("service-identity.test")
            .otel()
            .outgoing_http::<Authentik>("http://authentik.test")
            .primary(|component| {
                component
                    .environment("AUTHENTIK_URL", "http://authentik.test")
                    .secret_environment("AUTHENTIK_TOKEN", "fixture-token")
            })
            .typewriter_database(SchemaPreset::Service)
    }
}
