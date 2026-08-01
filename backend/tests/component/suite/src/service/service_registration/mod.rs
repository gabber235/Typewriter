use std::time::Duration;

use component_test::{FixtureBuilder, FixtureSpec, TestContext, component_fixture};
use typewriter_component_test::prelude::{
    DatabaseHandle, SchemaPreset, SkirMessagingExt, TypewriterFixtureBuilderExt,
};

mod binding;
mod lifecycle;
mod management;
mod status;

#[component_fixture(
    id = "service-registration",
    primary(package = "service-registration", target = "service_registration"),
    affected_paths(
        "backend/service/service-registration/",
        "backend/database/schema/service/",
        "backend/database/schema/organization/"
    )
)]
pub struct ServiceRegistration;

impl FixtureSpec for ServiceRegistration {
    fn configure(builder: FixtureBuilder<Self>) -> FixtureBuilder<Self> {
        builder
            .messaging_subscription("typewriter.from.service.*.status")
            .messaging_subscription("typewriter.from.service.*.heartbeat")
            .messaging_subscription("typewriter.from.service.*.shutdown")
            .messaging_subscription("typewriter.from.user.*.organization.*.services.*")
            .otel()
            .typewriter_database(SchemaPreset::Registration)
    }
}

pub(crate) fn database(
    context: &TestContext<ServiceRegistration>,
) -> anyhow::Result<std::sync::Arc<DatabaseHandle>> {
    context
        .extension::<DatabaseHandle>()
        .ok_or_else(|| anyhow::anyhow!("database handle missing"))
}

pub(crate) async fn request<Req: Sync, Resp>(
    context: &TestContext<ServiceRegistration>,
    subject: &str,
    value: &Req,
    request_serializer: wasmcloud_utils::skir_client::Serializer<Req>,
    response_serializer: wasmcloud_utils::skir_client::Serializer<Resp>,
) -> anyhow::Result<Resp> {
    context
        .messaging()?
        .request_skir(
            subject,
            value,
            request_serializer,
            response_serializer,
            Duration::from_secs(2),
            wasmcloud_utils::skir_client::UnrecognizedValues::Drop,
        )
        .await
}
