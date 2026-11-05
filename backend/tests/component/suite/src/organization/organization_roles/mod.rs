use typewriter_component_test::prelude::*;
use wasmcloud_utils::skir::base::organization::v1::role::{
    WatchOrganizationRolesRequest, WatchOrganizationRolesResponse,
};

#[component_fixture(
    id = "organization-roles",
    primary(package = "organization-roles", target = "organization_roles")
)]
pub struct OrganizationRoles;

impl FixtureSpec for OrganizationRoles {
    fn configure(builder: FixtureBuilder<Self>) -> FixtureBuilder<Self> {
        builder
            .messaging_subscriptions(
                wasmcloud_utils::transport_routes::organization_roles::SUBSCRIPTIONS,
            )
            .otel()
            .typewriter_database(SchemaPreset::Organization)
    }
}

#[component_test(OrganizationRoles)]
async fn watch_scopes_roles_and_orders_by_priority(
    context: &mut TestContext<OrganizationRoles>,
) -> TestResult {
    let acme = acme();
    let globex = globex();
    Seed::new()
        .organization(&acme, ada())
        .organization(&globex, grace())
        .role(&acme, "editor", 10)
        .role(&globex, "reviewer", 10)
        .apply(context)
        .await?;

    let reply: WatchOrganizationRolesResponse = context
        .request(
            from_member(ada(), &acme, "roles.watch"),
            &WatchOrganizationRolesRequest::default(),
        )
        .await?;

    let WatchOrganizationRolesResponse::List(roles) = reply else {
        anyhow::bail!("expected role list, received {reply:?}")
    };
    assert_eq!(
        roles
            .iter()
            .map(|role| role.name.as_str())
            .collect::<Vec<_>>(),
        ["founder", "editor", "writer"]
    );
    Ok(())
}

#[component_test(OrganizationRoles)]
async fn watch_unknown_organization_returns_empty_list(
    context: &mut TestContext<OrganizationRoles>,
) -> TestResult {
    let reply: WatchOrganizationRolesResponse = context
        .request(
            from_member(ada(), &Organization::new("missing"), "roles.watch"),
            &WatchOrganizationRolesRequest::default(),
        )
        .await?;

    assert!(
        matches!(&reply, WatchOrganizationRolesResponse::List(roles) if roles.is_empty()),
        "{reply:?}"
    );
    Ok(())
}
