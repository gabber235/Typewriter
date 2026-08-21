use component_test::{TestContext, TestResult, component_test};
use json_matcher::assert_jm;
use typewriter_component_test::prelude::skir_record_id;
use wasmcloud_utils::skir::base::{
    kernel::v1::record_id::RecordId,
    service::v1::organization::{
        ServiceUpdateValidationError, UpdateOrganizationServiceRequest,
        UpdateOrganizationServiceResponse, WatchOrganizationServicesRequest,
        WatchOrganizationServicesResponse,
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
            "CREATE user:actor SET name = 'actor'; CREATE user:other SET name = 'other'; CREATE organization:test_org SET name = 'test_org', founder = user:actor; CREATE organization:other_org SET name = 'other_org', founder = user:other; CREATE service:zeta SET name = 'zeta', role = { type: 'host', version: '1.0.0' }, organization = organization:test_org; CREATE service:alpha SET name = 'alpha', role = { type: 'host', version: '1.0.0' }, organization = organization:test_org; CREATE service:hidden SET name = 'hidden', role = { type: 'host', version: '1.0.0' }, organization = organization:other_org",
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
        service.revision == 1
            && service
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
            "CREATE user:actor SET name = 'actor'; CREATE organization:test_org SET name = 'test_org', founder = user:actor; CREATE service:managed SET name = 'old_name', role = { type: 'host', version: '1.0.0' }, organization = organization:test_org",
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
                            if service.name == "new_name" && service.revision == 2
                    )
                })
        });

    let response: UpdateOrganizationServiceResponse = request(
        context,
        "typewriter.from.user.actor.organization.test_org.services.update",
        &UpdateOrganizationServiceRequest {
            service_id: service_id("managed"),
            expected_revision: 1,
            name: "new_name".into(),
            _unrecognized: None,
        },
        UpdateOrganizationServiceRequest::serializer(),
        UpdateOrganizationServiceResponse::serializer(),
    )
    .await?;

    let UpdateOrganizationServiceResponse::Success(service) = response else {
        anyhow::bail!("expected successful service update");
    };
    assert_eq!(service.name, "new_name");
    assert_eq!(service.revision, 2);
    assert_jm!(
        database
            .query_json("SELECT VALUE [name, revision] FROM ONLY service:managed")
            .await?,
        ["new_name", 2]
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
            "CREATE user:actor SET name = 'actor'; CREATE user:other SET name = 'other'; CREATE organization:test_org SET name = 'test_org', founder = user:actor; CREATE organization:other_org SET name = 'other_org', founder = user:other; CREATE service:managed SET name = 'old_name', role = { type: 'host', version: '1.0.0' }, organization = organization:other_org",
        )
        .execute()
        .await?;

    let response: UpdateOrganizationServiceResponse = request(
        context,
        "typewriter.from.user.actor.organization.test_org.services.update",
        &UpdateOrganizationServiceRequest {
            service_id: service_id("managed"),
            expected_revision: 1,
            name: "new_name".into(),
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

#[component_test(ServiceRegistration)]
async fn stale_update_returns_canonical_conflict_without_writing(
    context: &mut TestContext<ServiceRegistration>,
) -> TestResult {
    let database = database(context)?;
    database
        .seed(
            "CREATE user:actor SET name = 'actor'; CREATE organization:test_org SET name = 'test_org', founder = user:actor; CREATE service:managed SET name = 'current_name', revision = 4, role = { type: 'host', version: '1.0.0' }, organization = organization:test_org",
        )
        .execute()
        .await?;

    let response: UpdateOrganizationServiceResponse = request(
        context,
        "typewriter.from.user.actor.organization.test_org.services.update",
        &UpdateOrganizationServiceRequest {
            service_id: service_id("managed"),
            expected_revision: 3,
            name: "stale_name".into(),
            _unrecognized: None,
        },
        UpdateOrganizationServiceRequest::serializer(),
        UpdateOrganizationServiceResponse::serializer(),
    )
    .await?;

    let UpdateOrganizationServiceResponse::ConflictError(conflict) = response else {
        anyhow::bail!("expected service revision conflict");
    };
    assert_eq!(conflict.expected_revision, 3);
    assert_eq!(conflict.actual.revision, 4);
    assert_eq!(conflict.actual.name, "current_name");
    assert_jm!(
        database
            .query_json("SELECT VALUE name FROM ONLY service:managed")
            .await?,
        "current_name"
    );
    assert_jm!(
        database
            .query_json("SELECT VALUE revision FROM ONLY service:managed")
            .await?,
        4
    );
    Ok(())
}

#[component_test(ServiceRegistration)]
async fn update_rejects_noncanonical_snake_case_name(
    context: &mut TestContext<ServiceRegistration>,
) -> TestResult {
    let database = database(context)?;
    database
        .seed(
            "CREATE user:actor SET name = 'actor'; CREATE organization:test_org SET name = 'test_org', founder = user:actor; CREATE service:managed SET name = 'managed', role = { type: 'host', version: '1.0.0' }, organization = organization:test_org",
        )
        .execute()
        .await?;

    let response: UpdateOrganizationServiceResponse = request(
        context,
        "typewriter.from.user.actor.organization.test_org.services.update",
        &UpdateOrganizationServiceRequest {
            service_id: service_id("managed"),
            expected_revision: 1,
            name: "invalid__name".into(),
            _unrecognized: None,
        },
        UpdateOrganizationServiceRequest::serializer(),
        UpdateOrganizationServiceResponse::serializer(),
    )
    .await?;

    assert!(matches!(
        response,
        UpdateOrganizationServiceResponse::ValidationError(error)
            if *error == ServiceUpdateValidationError::NameInvalid
    ));
    assert_jm!(
        database
            .query_json("SELECT VALUE [revision, name] FROM ONLY service:managed")
            .await?,
        [1, "managed"]
    );
    Ok(())
}
