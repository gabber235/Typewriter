use component_test::{TestContext, TestResult, component_test};
use json_matcher::assert_jm;
use wasmcloud_utils::skir::base::service::v1::{
    organization::WatchOrganizationServicesResponse,
    registration::{
        BindServiceRequest, BindServiceResponse, ServiceBoundNotification, UnbindServiceRequest,
        UnbindServiceResponse,
    },
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

#[component_test(ServiceRegistration)]
async fn invalid_registration_token_does_not_bind_service(
    context: &mut TestContext<ServiceRegistration>,
) -> TestResult {
    let database = database(context)?;
    database
        .seed(
            "CREATE user:actor SET name = 'actor'; CREATE organization:test_org SET name = 'test_org', founder = user:actor; CREATE service:bindable SET name = 'bindable', roles = [{ type: 'engine', version: '1' }], registration = { token: 'ABCDEFGHIJ', expires_at: time::now() + 1m }",
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
            .query_json("SELECT organization, registration.token AS token FROM ONLY service:bindable")
            .await?,
        { "token": "ABCDEFGHIJ" }
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
            "CREATE service:bindable SET name = 'bindable', roles = [{ type: 'engine', version: '1' }], registration = { token: 'ABCDEFGHIJ', expires_at: time::now() + 1m }",
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
            "CREATE user:actor SET name = 'actor'; CREATE organization:test_org SET name = 'test_org', founder = user:actor; CREATE service:bindable SET name = 'bindable', roles = [{ type: 'engine', version: '1' }], registration = { token: 'ABCDEFGHIJ', expires_at: time::now() + 1m }",
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
    assert_eq!(success.service_roles.len(), 1);
    assert_jm!(
        database
            .query_json("SELECT organization, registration FROM ONLY service:bindable")
            .await?,
        { "organization": "organization:test_org" }
    );
    Ok(())
}

#[component_test(ServiceRegistration)]
async fn unbind_removes_organization_and_publishes_removal(
    context: &mut TestContext<ServiceRegistration>,
) -> TestResult {
    let database = database(context)?;
    database
        .seed(
            "CREATE user:actor SET name = 'actor'; CREATE organization:test_org SET name = 'test_org', founder = user:actor; CREATE service:bound SET name = 'bound', roles = [{ type: 'engine', version: '1' }], organization = organization:test_org",
        )
        .execute()
        .await?;
    context
        .messaging_mock()?
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
            .query_json("SELECT organization, registration FROM ONLY service:bound")
            .await?,
        {}
    );
    Ok(())
}
