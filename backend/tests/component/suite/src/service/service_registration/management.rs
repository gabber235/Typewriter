use component_test::{TestContext, TestResult, component_test};
use json_matcher::assert_jm;
use typewriter_component_test::prelude::skir_record_id;
use wasmcloud_utils::skir::base::{
    kernel::v1::record_id::RecordId,
    service::v1::organization::{
        UpdateOrganizationServiceRequest, UpdateOrganizationServiceResponse,
        WatchOrganizationServicesRequest, WatchOrganizationServicesResponse,
    },
};

use super::{ServiceRegistration, database, request};

fn service_id(value: &str) -> RecordId {
    skir_record_id("service", value)
}

#[component_test(ServiceRegistration)]
async fn watch_lists_only_organization_services_in_name_order(
    context: &mut TestContext<ServiceRegistration>,
) -> TestResult {
    let database = database(context)?;
    database
        .seed(
            "CREATE user:actor SET name = 'actor'; CREATE user:other SET name = 'other'; CREATE organization:test_org SET name = 'test_org', founder = user:actor; CREATE organization:other_org SET name = 'other_org', founder = user:other; CREATE service:zeta SET name = 'zeta', roles = [{ type: 'engine', version: '1' }], organization = organization:test_org; CREATE service:alpha SET name = 'alpha', roles = [{ type: 'realm', version: '1' }], organization = organization:test_org; CREATE service:hidden SET name = 'hidden', roles = [{ type: 'engine', version: '1' }], organization = organization:other_org",
        )
        .execute()
        .await?;

    let response: WatchOrganizationServicesResponse = request(
        context,
        "typewriter.from.user.actor.organization.test_org.services.watch",
        &WatchOrganizationServicesRequest::default(),
        WatchOrganizationServicesRequest::serializer(),
        WatchOrganizationServicesResponse::serializer(),
    )
    .await?;

    let WatchOrganizationServicesResponse::List(services) = response else {
        anyhow::bail!("expected organization service list");
    };
    assert_eq!(
        services
            .iter()
            .map(|service| service.name.as_str())
            .collect::<Vec<_>>(),
        vec!["alpha", "zeta"]
    );
    assert!(services.iter().all(|service| {
        service
            .organization
            .as_ref()
            .is_some_and(|organization| organization.key.to_string() == "test_org")
    }));
    Ok(())
}

#[component_test(ServiceRegistration)]
async fn update_renames_owned_service_and_publishes_new_value(
    context: &mut TestContext<ServiceRegistration>,
) -> TestResult {
    let database = database(context)?;
    database
        .seed(
            "CREATE user:actor SET name = 'actor'; CREATE organization:test_org SET name = 'test_org', founder = user:actor; CREATE service:managed SET name = 'old_name', roles = [{ type: 'engine', version: '1' }], organization = organization:test_org",
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
                        WatchOrganizationServicesResponse::Update(service)
                            if service.name == "new_name"
                    )
                })
        });

    let response: UpdateOrganizationServiceResponse = request(
        context,
        "typewriter.from.user.actor.organization.test_org.services.update",
        &UpdateOrganizationServiceRequest {
            service_id: service_id("managed"),
            name: Some("new_name".into()),
            _unrecognized: None,
        },
        UpdateOrganizationServiceRequest::serializer(),
        UpdateOrganizationServiceResponse::serializer(),
    )
    .await?;

    assert!(matches!(
        response,
        UpdateOrganizationServiceResponse::Success(_)
    ));
    assert_jm!(
        database
            .query_json("SELECT VALUE name FROM ONLY service:managed")
            .await?,
        "new_name"
    );
    Ok(())
}

#[component_test(ServiceRegistration)]
async fn update_cannot_modify_service_from_another_organization(
    context: &mut TestContext<ServiceRegistration>,
) -> TestResult {
    let database = database(context)?;
    database
        .seed(
            "CREATE user:actor SET name = 'actor'; CREATE user:other SET name = 'other'; CREATE organization:test_org SET name = 'test_org', founder = user:actor; CREATE organization:other_org SET name = 'other_org', founder = user:other; CREATE service:managed SET name = 'old_name', roles = [{ type: 'engine', version: '1' }], organization = organization:other_org",
        )
        .execute()
        .await?;

    let response: UpdateOrganizationServiceResponse = request(
        context,
        "typewriter.from.user.actor.organization.test_org.services.update",
        &UpdateOrganizationServiceRequest {
            service_id: service_id("managed"),
            name: Some("new_name".into()),
            _unrecognized: None,
        },
        UpdateOrganizationServiceRequest::serializer(),
        UpdateOrganizationServiceResponse::serializer(),
    )
    .await?;

    assert!(matches!(
        response,
        UpdateOrganizationServiceResponse::ServiceNotFoundError(_)
    ));
    assert_jm!(
        database
            .query_json("SELECT VALUE name FROM ONLY service:managed")
            .await?,
        "old_name"
    );
    Ok(())
}
