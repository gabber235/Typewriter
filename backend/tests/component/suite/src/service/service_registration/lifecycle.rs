use component_test::{TestContext, TestResult, component_test};
use json_matcher::assert_jm;
use typewriter_component_test::prelude::SkirMessagingExt;
use wasmcloud_utils::skir::base::service::v1::{
    lifecycle::{ServiceHeartbeatNotification, ServiceShutdownNotification},
    organization::WatchOrganizationServicesResponse,
    service::ServiceStatus,
};

use super::{ServiceRegistration, database};

fn service_update_matches(body: &[u8], expected_status: ServiceStatus) -> bool {
    let Ok(response) = WatchOrganizationServicesResponse::serializer()
        .from_bytes(body, wasmcloud_utils::skir_client::UnrecognizedValues::Drop)
    else {
        return false;
    };
    let WatchOrganizationServicesResponse::Update(service) = response else {
        return false;
    };
    service.service_id.key.to_string() == "bound_service"
        && service
            .state
            .is_some_and(|state| state.status == expected_status)
}

#[component_test(ServiceRegistration)]
async fn heartbeat_updates_unbound_service_without_organization_event(
    context: &mut TestContext<ServiceRegistration>,
) -> TestResult {
    let database = database(context)?;
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

#[component_test(ServiceRegistration)]
async fn heartbeat_publishes_bound_service_state(
    context: &mut TestContext<ServiceRegistration>,
) -> TestResult {
    let database = database(context)?;
    database
        .seed(
            "CREATE user:actor SET name = 'actor'; CREATE organization:test_org SET name = 'test_org', founder = user:actor; CREATE service:bound_service SET name = 'bound_service', roles = [{ type: 'engine', version: '1' }], organization = organization:test_org",
        )
        .execute()
        .await?;
    context
        .messaging_mock()?
        .expect_publish("typewriter.to.organization.test_org.services.watch")
        .body_matches(|body| service_update_matches(body, ServiceStatus::Online));

    context
        .messaging()?
        .publish_skir(
            "typewriter.from.service.bound_service.heartbeat",
            &ServiceHeartbeatNotification::default(),
            ServiceHeartbeatNotification::serializer(),
        )
        .await?;
    context.messaging()?.wait_idle().await?;

    let state = database
        .query_json("SELECT state.status AS status, state.last_seen AS last_seen FROM ONLY service:bound_service")
        .await?;
    assert_eq!(
        state.get("status").and_then(serde_json::Value::as_str),
        Some("ONLINE")
    );
    assert!(state.get("last_seen").is_some_and(|value| !value.is_null()));
    Ok(())
}

#[component_test(ServiceRegistration)]
async fn shutdown_marks_bound_service_offline_and_publishes_update(
    context: &mut TestContext<ServiceRegistration>,
) -> TestResult {
    let database = database(context)?;
    database
        .seed(
            "CREATE user:actor SET name = 'actor'; CREATE organization:test_org SET name = 'test_org', founder = user:actor; CREATE service:bound_service SET name = 'bound_service', roles = [{ type: 'engine', version: '1' }], organization = organization:test_org, state = { status: 'ONLINE', last_seen: time::now() }",
        )
        .execute()
        .await?;
    context
        .messaging_mock()?
        .expect_publish("typewriter.to.organization.test_org.services.watch")
        .body_matches(|body| service_update_matches(body, ServiceStatus::Offline));

    context
        .messaging()?
        .publish_skir(
            "typewriter.from.service.bound_service.shutdown",
            &ServiceShutdownNotification::default(),
            ServiceShutdownNotification::serializer(),
        )
        .await?;
    context.messaging()?.wait_idle().await?;

    assert_jm!(
        database
            .query_json("SELECT VALUE state.status FROM ONLY service:bound_service")
            .await?,
        "OFFLINE"
    );
    Ok(())
}
