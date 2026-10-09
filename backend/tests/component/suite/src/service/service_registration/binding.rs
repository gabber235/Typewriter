use component_test::{TestContext, TestResult, component_test};
use json_matcher::assert_jm;
use wasmcloud_utils::skir::base::service::v1::{
    organization::OrganizationServicesChanged,
    registration::{
        BindServiceRequest, BindServiceResponse, ServiceBoundNotification, UnbindServiceRequest,
        UnbindServiceResponse,
    },
    topology::OrganizationTopologyChanged,
};

use super::{ServiceRegistration, database, request};

fn service_binding_snapshot_matches(body: &[u8]) -> bool {
    OrganizationServicesChanged::serializer()
        .from_bytes(body, wasmcloud_utils::skir_client::UnrecognizedValues::Drop)
        .is_ok_and(|response| {
            matches!(
                response,
                OrganizationServicesChanged::Replace(services)
                    if services.len() == 2
                        && services.iter().all(|service| {
                            service.organization.as_ref().is_some_and(|organization| {
                                organization.key.to_string() == "test_org"
                            })
                        })
                        && services.iter().any(|service| service.service_id.key.to_string() == "bindable")
                        && services.iter().any(|service| service.service_id.key.to_string() == "existing")
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

fn topology_empty_matches(body: &[u8]) -> bool {
    OrganizationTopologyChanged::serializer()
        .from_bytes(body, wasmcloud_utils::skir_client::UnrecognizedValues::Drop)
        .is_ok_and(|response| {
            matches!(
                response,
                OrganizationTopologyChanged::Replace(topology)
                    if topology.hosts.is_empty() && topology.realms.is_empty() && topology.engines.is_empty()
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
            operation_id: crate::framework::operation_id(),
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
            operation_id: crate::framework::operation_id(),
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
            "CREATE user:actor SET name = 'actor'; CREATE organization:test_org SET name = 'test_org', founder = user:actor; CREATE service:existing SET name = 'existing', role = { type: 'host', version: '1.0.0' }, organization = organization:test_org; CREATE service:bindable SET name = 'bindable', role = { type: 'host', version: '1.0.0' }, registration = { token: 'ABCDEFGHIJ', expires_at: time::now() + 1m }",
        )
        .execute()
        .await?;
    let messaging = context.messaging_mock()?;
    messaging
        .expect_publish("typewriter.to.organization.test_org.services.watch")
        .body_matches(service_binding_snapshot_matches);
    messaging
        .expect_publish("typewriter.to.service.bindable.registration.bound")
        .body_matches(bound_notification_matches);

    let response: BindServiceResponse = request(
        context,
        "typewriter.from.user.actor.organization.test_org.services.bind",
        &BindServiceRequest {
            operation_id: crate::framework::operation_id(),
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
            OrganizationServicesChanged::serializer()
                .from_bytes(body, wasmcloud_utils::skir_client::UnrecognizedValues::Drop)
                .is_ok_and(|response| {
                    matches!(
                        response,
                        OrganizationServicesChanged::Replace(services) if services.is_empty()
                    )
                })
        });
    messaging
        .expect_publish("typewriter.to.organization.test_org.topology.watch")
        .body_matches(topology_empty_matches);

    let response: UnbindServiceResponse = request(
        context,
        "typewriter.from.user.actor.organization.test_org.services.unbind",
        &UnbindServiceRequest {
            operation_id: crate::framework::operation_id(),
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
