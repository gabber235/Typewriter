use component_test::{
    FixtureBuilder, FixtureSpec, TestContext, TestResult, component_fixture, component_test,
};
use json_matcher::assert_jm;
use typewriter_component_test::prelude::{
    DatabaseHandle, SchemaPreset, SkirMessagingExt, TypewriterFixtureBuilderExt,
};
use wasmcloud_utils::skir::base::service::v1::lifecycle::ServiceHeartbeatNotification;

#[component_fixture(
    id = "service-registration",
    primary(package = "service-registration", target = "service_registration"),
    affected_paths(
        "backend/service/service-registration/",
        "backend/database/schema/service/"
    )
)]
pub struct ServiceRegistration;

impl FixtureSpec for ServiceRegistration {
    fn configure(builder: FixtureBuilder<Self>) -> FixtureBuilder<Self> {
        builder
            .messaging_subscription("typewriter.from.service.*.heartbeat")
            .otel()
            .typewriter_database(SchemaPreset::Registration)
    }
}

#[component_test(ServiceRegistration)]
async fn heartbeat_uses_real_messaging(
    context: &mut TestContext<ServiceRegistration>,
) -> TestResult {
    let database = context
        .extension::<DatabaseHandle>()
        .ok_or_else(|| anyhow::anyhow!("database handle missing"))?;
    database
        .seed(
            "CREATE service:demo_service SET name = 'demo_service', roles = [{ type: 'engine', version: '1' }]",
        )
        .execute()
        .await?;

    context
        .messaging()?
        .publish_skir(
            "typewriter.from.service.demo_service.heartbeat",
            &ServiceHeartbeatNotification::default(),
            ServiceHeartbeatNotification::serializer(),
        )
        .await?;
    context.messaging()?.wait_idle().await?;

    let state = database
        .query_json("SELECT VALUE state.status AS status FROM ONLY service:demo_service")
        .await?;
    assert_jm!(state, "ONLINE");
    Ok(())
}
