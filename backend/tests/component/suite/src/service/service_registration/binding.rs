use component_test::{TestContext, TestResult, component_test};
use json_matcher::assert_jm;
use wasmcloud_utils::skir::base::service::v1::{
    organization::WatchOrganizationServicesResponse,
    registration::{
        BindServiceRequest, BindServiceResponse, ServiceBoundNotification, UnbindServiceRequest,
        UnbindServiceResponse,
    },
    topology::WatchOrganizationTopologyResponse,
};

use super::{ServiceRegistration, database, request};

fn service_add_matches(body: &[u8]) -> bool {
    WatchOrganizationServicesResponse::serializer()
        .from_bytes(body, wasmcloud_utils::skir_client::UnrecognizedValues::Drop)
        .is_ok_and(|response| {
            matches!(
                response,
                WatchOrganizationServicesResponse::Add(service)
                    if service.service_id.key.to_string() == "bindable"
                        && service.organization.as_ref().is_some_and(|organization| {
                            organization.key.to_string() == "test_org"
                        })
            )
        })
}

fn bound_notification_matches(body: &[u8]) -> bool {
    ServiceBoundNotification::serializer()
        .from_bytes(body, wasmcloud_utils::skir_client::UnrecognizedValues::Drop)
        .is_ok_and(|notification| {
            notification.organization_id == "test_org"
                && notification.organization_name.as_deref() == Some("test_org")
        })
}

fn topology_removal_matches(body: &[u8], table: &str, key: &str) -> bool {
    WatchOrganizationTopologyResponse::serializer()
        .from_bytes(body, wasmcloud_utils::skir_client::UnrecognizedValues::Drop)
        .is_ok_and(|response| {
            matches!(
                response,
                WatchOrganizationTopologyResponse::ResourceRemoved(resource_id)
                    if resource_id.table == table && resource_id.key.to_string() == key
            )
        })
}

#[component_test(ServiceRegistration)]
async fn invalid_registration_token_does_not_bind_service(
    context: &mut TestContext<ServiceRegistration>,
) -> TestResult {
    let database = database(context)?;
    database
        .seed(
            "CREATE user:actor SET name = 'actor'; CREATE organization:test_org SET name = 'test_org', founder = user:actor; CREATE service:bindable SET name = 'bindable', role = { type: 'host', version: '1.0.0' }, registration = { token: 'ABCDEFGHIJ', expires_at: time::now() + 1m }",
        )
        .execute()
        .await?;

    let response: BindServiceResponse = request(
        context,
        "typewriter.from.user.actor.organization.test_org.services.bind",
        &BindServiceRequest {
            registration_token: "ZZZZZZZZZZ".into(),
            _unrecognized: None,
        },
        BindServiceRequest::serializer(),
        BindServiceResponse::serializer(),
    )
    .await?;

    assert!(matches!(
        response,
        BindServiceResponse::InvalidRegistrationTokenError(_)
    ));
    assert_jm!(
        database
            .query_json(
                "RETURN { organization_is_none: (SELECT VALUE organization FROM ONLY service:bindable) = NONE, token: (SELECT VALUE registration.token FROM ONLY service:bindable) }",
            )
            .await?,
        { "organization_is_none": true, "token": "ABCDEFGHIJ" }
    );
    Ok(())
}

#[component_test(ServiceRegistration)]
async fn missing_organization_does_not_consume_registration(
    context: &mut TestContext<ServiceRegistration>,
) -> TestResult {
    let database = database(context)?;
    database
        .seed(
            "CREATE service:bindable SET name = 'bindable', role = { type: 'host', version: '1.0.0' }, registration = { token: 'ABCDEFGHIJ', expires_at: time::now() + 1m }",
        )
        .execute()
        .await?;

    let response: BindServiceResponse = request(
        context,
        "typewriter.from.user.actor.organization.missing.services.bind",
        &BindServiceRequest {
            registration_token: "ABCDEFGHIJ".into(),
            _unrecognized: None,
        },
        BindServiceRequest::serializer(),
        BindServiceResponse::serializer(),
    )
    .await?;

    assert!(matches!(
        response,
        BindServiceResponse::OrganizationNotFoundError(_)
    ));
    assert_jm!(
        database
            .query_json("SELECT registration.token AS token FROM ONLY service:bindable")
            .await?,
        { "token": "ABCDEFGHIJ" }
    );
    Ok(())
}

#[component_test(ServiceRegistration)]
async fn valid_registration_binds_service_and_publishes_both_views(
    context: &mut TestContext<ServiceRegistration>,
) -> TestResult {
    let database = database(context)?;
    database
        .seed(
            "CREATE user:actor SET name = 'actor'; CREATE organization:test_org SET name = 'test_org', founder = user:actor; CREATE service:bindable SET name = 'bindable', role = { type: 'host', version: '1.0.0' }, registration = { token: 'ABCDEFGHIJ', expires_at: time::now() + 1m }",
        )
        .execute()
        .await?;
    let messaging = context.messaging_mock()?;
    messaging
        .expect_publish("typewriter.to.organization.test_org.services.watch")
        .body_matches(service_add_matches);
    messaging
        .expect_publish("typewriter.to.service.bindable.registration.bound")
        .body_matches(bound_notification_matches);

    let response: BindServiceResponse = request(
        context,
        "typewriter.from.user.actor.organization.test_org.services.bind",
        &BindServiceRequest {
            registration_token: "ABCDEFGHIJ".into(),
            _unrecognized: None,
        },
        BindServiceRequest::serializer(),
        BindServiceResponse::serializer(),
    )
    .await?;

    let BindServiceResponse::Success(success) = response else {
        anyhow::bail!("expected successful binding response");
    };
    assert_eq!(success.service_id, "bindable");
    assert_eq!(success.service_name.as_deref(), Some("bindable"));
    assert!(matches!(
        success.service_role,
        wasmcloud_utils::skir::base::service::v1::service::ServiceRole::Host(_)
    ));
    assert_jm!(
        database
            .query_json(
                "RETURN { organization: (SELECT VALUE organization FROM ONLY service:bindable), registration_is_none: (SELECT VALUE registration FROM ONLY service:bindable) = NONE }",
            )
            .await?,
        { "organization": "organization:test_org", "registration_is_none": true }
    );
    Ok(())
}

#[component_test(ServiceRegistration)]
async fn unbind_removes_service_and_topology_from_organization_views(
    context: &mut TestContext<ServiceRegistration>,
) -> TestResult {
    let database = database(context)?;
    database
        .seed(
            "CREATE user:actor SET name = 'actor'; CREATE organization:test_org SET name = 'test_org', founder = user:actor; CREATE service:bound SET name = 'bound', role = { type: 'host', version: '1.0.0' }, organization = organization:test_org; CREATE service_host:bound SET service_id = service:bound, entrypoint = 'PAPER', can_host_realm = true, supported_engines = [{ engine_id: 'paper' }]; CREATE realm_instance:bound SET owner_host_id = service_host:bound, target_engine = { engine_id: 'paper', version_constraint: '^1' }; CREATE engine_instance:bound SET owner_host_id = service_host:bound, realm_id = realm_instance:bound, target = { engine_id: 'paper', version_constraint: '^1' }",
        )
        .execute()
        .await?;
    let messaging = context.messaging_mock()?;
    messaging
        .expect_publish("typewriter.to.organization.test_org.services.watch")
        .body_matches(|body| {
            WatchOrganizationServicesResponse::serializer()
                .from_bytes(body, wasmcloud_utils::skir_client::UnrecognizedValues::Drop)
                .is_ok_and(|response| {
                    matches!(
                        response,
                        WatchOrganizationServicesResponse::Remove(service_id)
                            if service_id.table == "service"
                                && service_id.key.to_string() == "bound"
                    )
                })
        });
    messaging
        .expect_publish("typewriter.to.organization.test_org.topology.watch")
        .body_matches(|body| topology_removal_matches(body, "engine_instance", "bound"));
    messaging
        .expect_publish("typewriter.to.organization.test_org.topology.watch")
        .body_matches(|body| topology_removal_matches(body, "realm_instance", "bound"));
    messaging
        .expect_publish("typewriter.to.organization.test_org.topology.watch")
        .body_matches(|body| topology_removal_matches(body, "service_host", "bound"));

    let response: UnbindServiceResponse = request(
        context,
        "typewriter.from.user.actor.organization.test_org.services.unbind",
        &UnbindServiceRequest {
            service_id: "bound".into(),
            _unrecognized: None,
        },
        UnbindServiceRequest::serializer(),
        UnbindServiceResponse::serializer(),
    )
    .await?;

    assert!(matches!(response, UnbindServiceResponse::Success(_)));
    assert_jm!(
        database
            .query_json(
                "RETURN { organization_is_none: (SELECT VALUE organization FROM ONLY service:bound) = NONE, registration_is_none: (SELECT VALUE registration FROM ONLY service:bound) = NONE, host_exists: record::exists(service_host:bound), realm_exists: record::exists(realm_instance:bound), engine_exists: record::exists(engine_instance:bound) }",
            )
            .await?,
        { "organization_is_none": true, "registration_is_none": true, "host_exists": true, "realm_exists": true, "engine_exists": true }
    );
    Ok(())
}
