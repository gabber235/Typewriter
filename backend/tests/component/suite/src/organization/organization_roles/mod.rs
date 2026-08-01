use std::time::Duration;

use component_test::{
    FixtureBuilder, FixtureSpec, TestContext, TestResult, component_fixture, component_test,
};
use typewriter_component_test::prelude::{
    DatabaseHandle, SchemaPreset, SkirMessagingExt, TypewriterFixtureBuilderExt,
};
use wasmcloud_utils::{
    skir::base::organization::v1::role::{
        WatchOrganizationRolesRequest, WatchOrganizationRolesResponse,
    },
    skir_client::UnrecognizedValues,
};

#[component_fixture(
    id = "organization-roles",
    primary(package = "organization-roles", target = "organization_roles"),
    affected_paths(
        "backend/organization/organization-roles/",
        "backend/database/schema/organization/"
    )
)]
pub struct OrganizationRoles;

impl FixtureSpec for OrganizationRoles {
    fn configure(builder: FixtureBuilder<Self>) -> FixtureBuilder<Self> {
        builder
            .messaging_subscription("typewriter.from.user.*.organization.*.roles.*")
            .otel()
            .typewriter_database(SchemaPreset::Organization)
    }
}

#[component_test(OrganizationRoles)]
async fn watch_scopes_roles_and_orders_by_priority(
    context: &mut TestContext<OrganizationRoles>,
) -> TestResult {
    let database = context
        .extension::<DatabaseHandle>()
        .ok_or_else(|| anyhow::anyhow!("database handle missing"))?;
    database
        .execute(
            r#"
            CREATE user:founder_a SET name = 'founder_a';
            CREATE user:founder_b SET name = 'founder_b';
            CREATE organization:alpha SET name = 'alpha', founder = user:founder_a;
            CREATE organization:beta SET name = 'beta', founder = user:founder_b;
            CREATE organization_role:editor SET
                name = 'editor',
                organization = organization:alpha,
                priority = 10;
            "#,
        )
        .await?;

    let response = context
        .messaging()?
        .request_skir(
            "typewriter.from.user.viewer.organization.alpha.roles.watch",
            &WatchOrganizationRolesRequest::default(),
            WatchOrganizationRolesRequest::serializer(),
            WatchOrganizationRolesResponse::serializer(),
            Duration::from_secs(2),
            UnrecognizedValues::Drop,
        )
        .await?;

    let WatchOrganizationRolesResponse::List(roles) = response else {
        anyhow::bail!("expected role list response")
    };
    assert_eq!(
        roles
            .iter()
            .map(|role| role.name.as_str())
            .collect::<Vec<_>>(),
        vec!["founder", "editor", "writer"]
    );
    assert!(
        roles
            .iter()
            .all(|role| role.role_id.table == "organization_role")
    );
    Ok(())
}

#[component_test(OrganizationRoles)]
async fn watch_unknown_organization_returns_empty_list(
    context: &mut TestContext<OrganizationRoles>,
) -> TestResult {
    let response = context
        .messaging()?
        .request_skir(
            "typewriter.from.user.viewer.organization.missing.roles.watch",
            &WatchOrganizationRolesRequest::default(),
            WatchOrganizationRolesRequest::serializer(),
            WatchOrganizationRolesResponse::serializer(),
            Duration::from_secs(2),
            UnrecognizedValues::Drop,
        )
        .await?;

    assert!(matches!(response, WatchOrganizationRolesResponse::List(roles) if roles.is_empty()));
    Ok(())
}
