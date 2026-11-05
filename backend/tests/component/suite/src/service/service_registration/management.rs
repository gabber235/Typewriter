use json_matcher::assert_jm;
use typewriter_component_test::{
    prelude::*,
    service::{rename_service, seed_organization_services},
};
use wasmcloud_utils::skir::base::service::v1::organization::{
    OrganizationServicesChanged, ServiceUpdateValidationError, UpdateOrganizationServiceResponse,
    WatchOrganizationServicesRequest, WatchOrganizationServicesResponse,
};

use super::ServiceRegistration;

/// The name and revision `lobby` has in the database.
const STORED: &str = "SELECT VALUE [name, revision] FROM ONLY service:lobby";

#[component_test(ServiceRegistration)]
async fn watch_lists_only_organization_services_in_name_order(
    context: &mut TestContext<ServiceRegistration>,
) -> TestResult {
    seed_organization_services(context, &acme(), ada(), &["zeta", "alpha"]).await?;
    seed_organization_services(context, &globex(), grace(), &["hidden"]).await?;

    let reply: WatchOrganizationServicesResponse = context
        .request(
            from_member(ada(), &acme(), "services.watch"),
            &WatchOrganizationServicesRequest::default(),
        )
        .await?;

    let WatchOrganizationServicesResponse::List(services) = reply else {
        anyhow::bail!("expected Acme's services, received {reply:?}");
    };
    assert_eq!(
        services
            .iter()
            .map(|service| service.name.as_str())
            .collect::<Vec<_>>(),
        ["alpha", "zeta"]
    );
    assert!(
        services.iter().all(|service| {
            service.revision == 1
                && service
                    .organization
                    .as_ref()
                    .is_some_and(|organization| organization.key.to_string() == "acme")
        }),
        "{services:?}"
    );
    Ok(())
}

#[component_test(ServiceRegistration)]
async fn update_renames_owned_service_and_publishes_new_value(
    context: &mut TestContext<ServiceRegistration>,
) -> TestResult {
    seed_organization_services(context, &acme(), ada(), &["lobby"]).await?;
    context.expect_publish(
        to_organization(&acme(), "services.watch"),
        |event: &OrganizationServicesChanged| {
            matches!(event, OrganizationServicesChanged::Update(service)
                if service.name == "hub" && service.revision == 2)
        },
    )?;

    let reply: UpdateOrganizationServiceResponse = context
        .request(
            from_member(ada(), &acme(), "services.update"),
            &rename_service("lobby", 1, "hub"),
        )
        .await?;

    let UpdateOrganizationServiceResponse::Success(service) = reply else {
        anyhow::bail!("expected the rename to succeed, received {reply:?}");
    };
    assert_eq!(service.name, "hub");
    assert_eq!(service.revision, 2);
    assert_jm!(context.database()?.query_json(STORED).await?, ["hub", 2]);
    Ok(())
}

#[component_test(ServiceRegistration)]
async fn update_cannot_modify_service_from_another_organization(
    context: &mut TestContext<ServiceRegistration>,
) -> TestResult {
    seed_organization(context, &acme(), ada(), &[]).await?;
    seed_organization_services(context, &globex(), grace(), &["lobby"]).await?;

    let reply: UpdateOrganizationServiceResponse = context
        .request(
            from_member(ada(), &acme(), "services.update"),
            &rename_service("lobby", 1, "hub"),
        )
        .await?;

    assert!(
        matches!(
            reply,
            UpdateOrganizationServiceResponse::ServiceNotFoundError(_)
        ),
        "{reply:?}"
    );
    assert_jm!(context.database()?.query_json(STORED).await?, ["lobby", 1]);
    Ok(())
}

#[component_test(ServiceRegistration)]
async fn stale_update_returns_canonical_conflict_without_writing(
    context: &mut TestContext<ServiceRegistration>,
) -> TestResult {
    seed_organization_services(context, &acme(), ada(), &["lobby"]).await?;
    let renamed: UpdateOrganizationServiceResponse = context
        .arrange(
            from_member(ada(), &acme(), "services.update"),
            &rename_service("lobby", 1, "arena"),
        )
        .await?;
    assert!(
        matches!(renamed, UpdateOrganizationServiceResponse::Success(_)),
        "{renamed:?}"
    );

    let reply: UpdateOrganizationServiceResponse = context
        .request(
            from_member(ada(), &acme(), "services.update"),
            &rename_service("lobby", 1, "stale"),
        )
        .await?;

    let UpdateOrganizationServiceResponse::ConflictError(conflict) = reply else {
        anyhow::bail!("expected a revision conflict, received {reply:?}");
    };
    assert_eq!(conflict.expected_revision, 1);
    assert_eq!(conflict.actual.revision, 2);
    assert_eq!(conflict.actual.name, "arena");
    assert_jm!(context.database()?.query_json(STORED).await?, ["arena", 2]);
    Ok(())
}

#[component_test(ServiceRegistration)]
async fn repeated_rename_after_it_landed_answers_and_republishes_the_stored_service(
    context: &mut TestContext<ServiceRegistration>,
) -> TestResult {
    seed_organization_services(context, &acme(), ada(), &["lobby"]).await?;
    let first: UpdateOrganizationServiceResponse = context
        .arrange(
            from_member(ada(), &acme(), "services.update"),
            &rename_service("lobby", 1, "arena"),
        )
        .await?;
    assert!(
        matches!(first, UpdateOrganizationServiceResponse::Success(_)),
        "{first:?}"
    );
    context.expect_publish(
        to_organization(&acme(), "services.watch"),
        |event: &OrganizationServicesChanged| {
            matches!(event, OrganizationServicesChanged::Update(service)
                if service.name == "arena" && service.revision == 2)
        },
    )?;

    let reply: UpdateOrganizationServiceResponse = context
        .request(
            from_member(ada(), &acme(), "services.update"),
            &rename_service("lobby", 1, "arena"),
        )
        .await?;

    let UpdateOrganizationServiceResponse::Success(service) = reply else {
        anyhow::bail!("expected the repeated rename to succeed, received {reply:?}");
    };
    assert_eq!(service.name, "arena");
    assert_eq!(service.revision, 2);
    assert_jm!(context.database()?.query_json(STORED).await?, ["arena", 2]);
    Ok(())
}

#[component_test(ServiceRegistration)]
async fn update_rejects_noncanonical_snake_case_name(
    context: &mut TestContext<ServiceRegistration>,
) -> TestResult {
    seed_organization_services(context, &acme(), ada(), &["lobby"]).await?;

    let reply: UpdateOrganizationServiceResponse = context
        .request(
            from_member(ada(), &acme(), "services.update"),
            &rename_service("lobby", 1, "invalid__name"),
        )
        .await?;

    assert!(
        matches!(&reply, UpdateOrganizationServiceResponse::ValidationError(error)
            if **error == ServiceUpdateValidationError::NameInvalid),
        "{reply:?}"
    );
    assert_jm!(context.database()?.query_json(STORED).await?, ["lobby", 1]);
    Ok(())
}
