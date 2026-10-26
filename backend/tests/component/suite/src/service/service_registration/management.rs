use json_matcher::assert_jm;
use typewriter_component_test::prelude::*;
use wasmcloud_utils::skir::base::service::v1::organization::{
    OrganizationServicesChanged, ServiceUpdateValidationError, UpdateOrganizationServiceRequest,
    UpdateOrganizationServiceResponse, WatchOrganizationServicesRequest,
    WatchOrganizationServicesResponse,
};

use super::{Context, ServiceRegistration, acme_with_service, globex};

fn rename(key: &str, expected_revision: i64, name: &str) -> UpdateOrganizationServiceRequest {
    UpdateOrganizationServiceRequest {
        service_id: skir_record_id("service", key),
        expected_revision,
        name: name.into(),
        ..Default::default()
    }
}

async fn update(
    context: &Context,
    request: &UpdateOrganizationServiceRequest,
) -> anyhow::Result<UpdateOrganizationServiceResponse> {
    context
        .request(from_member(ada(), &acme(), "services.update"), request)
        .await
}

/// The name and revision the service `key` has in the database.
async fn stored(context: &Context, key: &str) -> anyhow::Result<serde_json::Value> {
    context
        .database()?
        .seed("SELECT VALUE [name, revision] FROM ONLY $service")
        .bind("service", surrealdb_types::RecordId::new("service", key))?
        .query_json()
        .await
}

#[component_test(ServiceRegistration)]
async fn watch_lists_only_organization_services_in_name_order(context: &mut Context) -> TestResult {
    Seed::new()
        .organization(&acme(), ada())
        .organization(&globex(), grace())
        .organization_service(&acme(), "zeta")
        .organization_service(&acme(), "alpha")
        .organization_service(&globex(), "hidden")
        .apply(&context.database()?)
        .await?;

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
async fn update_renames_owned_service_and_publishes_new_value(context: &mut Context) -> TestResult {
    acme_with_service(context, "lobby").await?;
    context.expect_publish(
        to_organization(&acme(), "services.watch"),
        |event: &OrganizationServicesChanged| {
            matches!(event, OrganizationServicesChanged::Update(service)
                if service.name == "hub" && service.revision == 2)
        },
    )?;

    let reply = update(context, &rename("lobby", 1, "hub")).await?;

    let UpdateOrganizationServiceResponse::Success(service) = reply else {
        anyhow::bail!("expected the rename to succeed, received {reply:?}");
    };
    assert_eq!(service.name, "hub");
    assert_eq!(service.revision, 2);
    assert_jm!(stored(context, "lobby").await?, ["hub", 2]);
    Ok(())
}

#[component_test(ServiceRegistration)]
async fn update_cannot_modify_service_from_another_organization(
    context: &mut Context,
) -> TestResult {
    Seed::new()
        .organization(&acme(), ada())
        .organization(&globex(), grace())
        .organization_service(&globex(), "lobby")
        .apply(&context.database()?)
        .await?;

    let reply = update(context, &rename("lobby", 1, "hub")).await?;

    assert!(
        matches!(
            reply,
            UpdateOrganizationServiceResponse::ServiceNotFoundError(_)
        ),
        "{reply:?}"
    );
    assert_jm!(stored(context, "lobby").await?, ["lobby", 1]);
    Ok(())
}

#[component_test(ServiceRegistration)]
async fn stale_update_returns_canonical_conflict_without_writing(
    context: &mut Context,
) -> TestResult {
    acme_with_service(context, "lobby").await?;
    let renamed: UpdateOrganizationServiceResponse = context
        .arrange(
            from_member(ada(), &acme(), "services.update"),
            &rename("lobby", 1, "arena"),
        )
        .await?;
    assert!(
        matches!(renamed, UpdateOrganizationServiceResponse::Success(_)),
        "{renamed:?}"
    );

    let reply = update(context, &rename("lobby", 1, "stale")).await?;

    let UpdateOrganizationServiceResponse::ConflictError(conflict) = reply else {
        anyhow::bail!("expected a revision conflict, received {reply:?}");
    };
    assert_eq!(conflict.expected_revision, 1);
    assert_eq!(conflict.actual.revision, 2);
    assert_eq!(conflict.actual.name, "arena");
    assert_jm!(stored(context, "lobby").await?, ["arena", 2]);
    Ok(())
}

#[component_test(ServiceRegistration)]
async fn update_rejects_noncanonical_snake_case_name(context: &mut Context) -> TestResult {
    acme_with_service(context, "lobby").await?;

    let reply = update(context, &rename("lobby", 1, "invalid__name")).await?;

    assert!(
        matches!(&reply, UpdateOrganizationServiceResponse::ValidationError(error)
            if **error == ServiceUpdateValidationError::NameInvalid),
        "{reply:?}"
    );
    assert_jm!(stored(context, "lobby").await?, ["lobby", 1]);
    Ok(())
}
