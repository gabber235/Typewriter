//! Implements the role listing action for an organization.
//!
//! The organization identifier comes from the broker subject, while the request body is the
//! empty SKIR request marker. The database query is the authority for the returned role set and
//! orders it by descending priority so the response matches the organization role presentation.

use otel_wasi::ResultWithSlug;
use wasmcloud_utils::{
    database::{RecordId, read_query},
    otel_wasi,
    skir::base::organization::v1::role::{
        WatchOrganizationRolesRequest, WatchOrganizationRolesResponse,
    },
    transport_routes::OrganizationActorScope,
    wasmcloud::messaging::types::NatsMessage,
};

use wasmcloud_utils::database::organization::OrganizationRoleRecord;

/// Lists the roles belonging to the organization named by the message subject.
///
/// The actor identifier is recorded for tracing, but this handler does not use it to filter the
/// result. Unknown organizations therefore produce an empty list, and database or decoding
/// failures are returned through the dispatch layer as an internal error response.
#[tracing::instrument(skip_all)]
pub async fn handle_watch(
    _msg: NatsMessage,
    scope: OrganizationActorScope,
    _request: WatchOrganizationRolesRequest,
) -> Result<WatchOrganizationRolesResponse, otel_wasi::Error> {
    otel_wasi::main_attribute!(
        "actor.id" = scope.user.to_string(),
        "organization.id" = scope.organization.to_string()
    );

    let organization_id = RecordId::new("organization", scope.organization.as_str());
    let roles = read_query!(
        r#"
        SELECT * FROM organization_role
        WHERE organization = $org_id
        ORDER BY priority DESC
        "#,
    )
    .bind("org_id", organization_id)
    .execute()
    .await
    .error_with_slug("role-watch-query-failed")?
    .take::<Vec<OrganizationRoleRecord>>()
    .error_with_slug("role-watch-result-parse-failed")?
    .into_iter()
    .map(Into::into)
    .collect::<Vec<_>>();

    otel_wasi::main_attribute!(
        "role.outcome" = "listed",
        "role.result_count" = roles.len() as i64
    );
    Ok(WatchOrganizationRolesResponse::List(roles))
}
