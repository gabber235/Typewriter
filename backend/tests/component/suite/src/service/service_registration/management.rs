use json_matcher::assert_jm;
use typewriter_component_test::{
    prelude::*,
    service::{rename_services, seed_organization_services},
};
use wasmcloud_utils::skir::base::service::v1::organization::{
    OrganizationServicesChanged, ServiceRenameRefusal, ServiceUpdateValidationError,
    UpdateOrganizationServicesResponse, WatchOrganizationServicesRequest,
    WatchOrganizationServicesResponse,
};

use super::ServiceRegistration;

/// The name and revision `lobby` has in the database.
const STORED: &str = "SELECT VALUE [name, revision] FROM ONLY service:lobby";
/// The names and revisions `arena` and `lobby` have in the database.
const BOTH_STORED: &str = "RETURN [[service:arena.name, service:arena.revision], [service:lobby.name, service:lobby.revision]]";

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

    let reply: UpdateOrganizationServicesResponse = context
        .request(
            from_member(ada(), &acme(), "services.update"),
            &rename_services(&[("lobby", 1, "hub")]),
        )
        .await?;

    let UpdateOrganizationServicesResponse::Success(services) = reply else {
        anyhow::bail!("expected the rename to succeed, received {reply:?}");
    };
    assert_eq!(
        services
            .iter()
            .map(|service| (service.name.as_str(), service.revision))
            .collect::<Vec<_>>(),
        [("hub", 2)]
    );
    assert_jm!(context.database()?.query_json(STORED).await?, ["hub", 2]);
    Ok(())
}

#[component_test(ServiceRegistration)]
async fn a_batch_renames_every_service_and_publishes_each(
    context: &mut TestContext<ServiceRegistration>,
) -> TestResult {
    seed_organization_services(context, &acme(), ada(), &["arena", "lobby"]).await?;
    for name in ["stage", "hub"] {
        context.expect_publish(
            to_organization(&acme(), "services.watch"),
            move |event: &OrganizationServicesChanged| {
                matches!(event, OrganizationServicesChanged::Update(service)
                    if service.name == name && service.revision == 2)
            },
        )?;
    }

    let reply: UpdateOrganizationServicesResponse = context
        .request(
            from_member(ada(), &acme(), "services.update"),
            &rename_services(&[("arena", 1, "stage"), ("lobby", 1, "hub")]),
        )
        .await?;

    let UpdateOrganizationServicesResponse::Success(services) = reply else {
        anyhow::bail!("expected the batch to succeed, received {reply:?}");
    };
    assert_eq!(
        services
            .iter()
            .map(|service| service.name.as_str())
            .collect::<Vec<_>>(),
        ["stage", "hub"]
    );
    assert_jm!(
        context.database()?.query_json(BOTH_STORED).await?,
        [["stage", 2], ["hub", 2]]
    );
    Ok(())
}

/// One refused rename keeps every other rename in its batch from landing, and the reply names
/// each refused item with its own reason.
#[component_test(ServiceRegistration)]
async fn a_batch_with_one_invalid_name_renames_nothing(
    context: &mut TestContext<ServiceRegistration>,
) -> TestResult {
    seed_organization_services(context, &acme(), ada(), &["arena", "lobby"]).await?;
    context.expect_no_publish(to_organization(&acme(), "services.watch"))?;

    let reply: UpdateOrganizationServicesResponse = context
        .request(
            from_member(ada(), &acme(), "services.update"),
            &rename_services(&[("arena", 1, "stage"), ("lobby", 1, "invalid__name")]),
        )
        .await?;

    let UpdateOrganizationServicesResponse::RefusedError(refused) = reply else {
        anyhow::bail!("expected the batch to be refused, received {reply:?}");
    };
    assert_eq!(refused.len(), 1, "{refused:?}");
    assert_eq!(refused[0].service_id.key.to_string(), "lobby");
    assert!(
        matches!(&refused[0].reason, ServiceRenameRefusal::ValidationError(error)
            if **error == ServiceUpdateValidationError::NameInvalid),
        "{refused:?}"
    );
    assert_jm!(
        context.database()?.query_json(BOTH_STORED).await?,
        [["arena", 1], ["lobby", 1]]
    );
    Ok(())
}

#[component_test(ServiceRegistration)]
async fn a_batch_lists_every_refused_rename_with_its_reason(
    context: &mut TestContext<ServiceRegistration>,
) -> TestResult {
    seed_organization_services(context, &acme(), ada(), &["arena", "lobby"]).await?;
    seed_organization_services(context, &globex(), grace(), &["hidden"]).await?;
    let renamed: UpdateOrganizationServicesResponse = context
        .arrange(
            from_member(ada(), &acme(), "services.update"),
            &rename_services(&[("lobby", 1, "hub")]),
        )
        .await?;
    assert!(
        matches!(renamed, UpdateOrganizationServicesResponse::Success(_)),
        "{renamed:?}"
    );
    context.expect_no_publish(to_organization(&acme(), "services.watch"))?;

    let reply: UpdateOrganizationServicesResponse = context
        .request(
            from_member(ada(), &acme(), "services.update"),
            &rename_services(&[
                ("arena", 1, "stage"),
                ("lobby", 1, "stale"),
                ("hidden", 1, "found"),
            ]),
        )
        .await?;

    let UpdateOrganizationServicesResponse::RefusedError(refused) = reply else {
        anyhow::bail!("expected the batch to be refused, received {reply:?}");
    };
    assert_eq!(refused.len(), 2, "{refused:?}");
    let ServiceRenameRefusal::ConflictError(conflict) = &refused[0].reason else {
        anyhow::bail!("expected lobby to conflict, received {refused:?}");
    };
    assert_eq!(refused[0].service_id.key.to_string(), "lobby");
    assert_eq!(conflict.expected_revision, 1);
    assert_eq!(
        (conflict.actual.name.as_str(), conflict.actual.revision),
        ("hub", 2)
    );
    assert_eq!(refused[1].service_id.key.to_string(), "hidden");
    assert!(
        matches!(
            refused[1].reason,
            ServiceRenameRefusal::ServiceNotFoundError(_)
        ),
        "{refused:?}"
    );
    assert_jm!(
        context.database()?.query_json(BOTH_STORED).await?,
        [["arena", 1], ["hub", 2]]
    );
    Ok(())
}

#[component_test(ServiceRegistration)]
async fn repeated_rename_after_it_landed_answers_and_republishes_the_stored_service(
    context: &mut TestContext<ServiceRegistration>,
) -> TestResult {
    seed_organization_services(context, &acme(), ada(), &["lobby"]).await?;
    let first: UpdateOrganizationServicesResponse = context
        .arrange(
            from_member(ada(), &acme(), "services.update"),
            &rename_services(&[("lobby", 1, "arena")]),
        )
        .await?;
    assert!(
        matches!(first, UpdateOrganizationServicesResponse::Success(_)),
        "{first:?}"
    );
    context.expect_publish(
        to_organization(&acme(), "services.watch"),
        |event: &OrganizationServicesChanged| {
            matches!(event, OrganizationServicesChanged::Update(service)
                if service.name == "arena" && service.revision == 2)
        },
    )?;

    let reply: UpdateOrganizationServicesResponse = context
        .request(
            from_member(ada(), &acme(), "services.update"),
            &rename_services(&[("lobby", 1, "arena")]),
        )
        .await?;

    let UpdateOrganizationServicesResponse::Success(services) = reply else {
        anyhow::bail!("expected the repeated rename to succeed, received {reply:?}");
    };
    assert_eq!(
        services
            .iter()
            .map(|service| (service.name.as_str(), service.revision))
            .collect::<Vec<_>>(),
        [("arena", 2)]
    );
    assert_jm!(context.database()?.query_json(STORED).await?, ["arena", 2]);
    Ok(())
}

#[component_test(ServiceRegistration)]
async fn a_batch_naming_a_service_twice_is_refused_without_writing(
    context: &mut TestContext<ServiceRegistration>,
) -> TestResult {
    seed_organization_services(context, &acme(), ada(), &["lobby"]).await?;
    context.expect_no_publish(to_organization(&acme(), "services.watch"))?;

    let reply: UpdateOrganizationServicesResponse = context
        .request(
            from_member(ada(), &acme(), "services.update"),
            &rename_services(&[("lobby", 1, "hub"), ("lobby", 1, "stage")]),
        )
        .await?;

    let UpdateOrganizationServicesResponse::RefusedError(refused) = reply else {
        anyhow::bail!("expected the batch to be refused, received {reply:?}");
    };
    assert_eq!(refused.len(), 1, "{refused:?}");
    assert!(
        matches!(refused[0].reason, ServiceRenameRefusal::DuplicateError(_)),
        "{refused:?}"
    );
    assert_jm!(context.database()?.query_json(STORED).await?, ["lobby", 1]);
    Ok(())
}
