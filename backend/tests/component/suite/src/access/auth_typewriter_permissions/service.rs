//! Service grants, checked by the subjects a service must and must not reach.

use typewriter_component_test::prelude::*;
use wasmcloud_utils::{
    skir::base::{
        access::v1::permission::{
            EntityPermissionQualifier, GetEntityPermissionRequest, GetEntityPermissionResponse,
            Permissions,
        },
        service::v1::{
            status::{
                QueryServiceBindingResponse, QueryServiceBindingResponse_Binding, ServiceBinding,
                ServiceBinding_Bound,
            },
            topology::GetServiceMessagingScopeResponse,
        },
    },
    skir_variant,
    transport_routes::{REPLY_TTL_MS, SERVICE_RESPONSE_LIMIT},
};

use super::{
    AuthTypewriterPermissions, Context, Realm, SERVICE_POLICY, bound_service, expect_binding,
    expect_scope, permits, request_permissions,
};

pub(super) fn sign_in(service: &str) -> GetEntityPermissionRequest {
    GetEntityPermissionRequest {
        qualifier: EntityPermissionQualifier::Service(Box::default()),
        jwt_claims: serde_json::to_vec(&serde_json::json!({
            "sub": service,
            "preferred_username": "Fixture Service"
        }))
        .expect("claims are valid JSON"),
        ..Default::default()
    }
}

/// The grants of `service`, bound to Acme and running `realm`.
pub(super) async fn service_grants(
    context: &Context,
    service: &str,
    realm: Realm,
) -> anyhow::Result<Permissions> {
    bound_service(context, service, realm)?;
    Ok(
        request_permissions(context, SERVICE_POLICY, &sign_in(service))
            .await?
            .permissions,
    )
}

fn realm_route(realm: &str, organization: &str, route: &str) -> String {
    format!("service.to.{realm}.organization.{organization}.realm.{route}")
}

fn realm_event(realm: &str, organization: &str, event: &str) -> String {
    format!("service.from.{realm}.organization.{organization}.realm.{event}")
}

/// Another realm of Acme and the same realm key in another organization.
const FOREIGN: [(&str, &str); 2] = [("foreign_realm", "acme"), ("quests", "globex")];

#[component_test(AuthTypewriterPermissions)]
async fn a_service_may_answer_every_frame_of_its_largest_reply(
    context: &mut Context,
) -> TestResult {
    let permissions = service_grants(context, "engine_one", Realm::Attached("quests")).await?;

    let response = permissions
        .response
        .ok_or_else(|| anyhow::anyhow!("a service needs a response permission"))?;
    assert_eq!(
        response.max_messages,
        SERVICE_RESPONSE_LIMIT.map(|limit| limit as i32)
    );
    assert_eq!(
        response.ttl.as_ref().map(|ttl| ttl.milliseconds),
        Some(REPLY_TTL_MS)
    );
    Ok(())
}

#[component_test(AuthTypewriterPermissions)]
async fn an_attached_engine_reads_published_content_of_its_realm_only(
    context: &mut Context,
) -> TestResult {
    let permissions = service_grants(context, "engine_one", Realm::Attached("quests")).await?;

    assert!(permits(
        &permissions.publish,
        &realm_route("quests", "acme", "editor.authoring.compiled.query")
    ));
    assert!(permits(
        &permissions.subscribe,
        &realm_event("quests", "acme", "editor.authoring.compiled.changed")
    ));
    for route in [
        "shared.catalog.fetch",
        "shared.blob.fetch",
        "shared.publish",
    ] {
        assert!(permits(
            &permissions.publish,
            &realm_route("quests", "acme", route)
        ));
    }
    // Authoring belongs to the realm host, never to an attached engine.
    for route in [
        "editor.authoring.edit.commit",
        "editor.authoring.publish",
        "editor.authoring.state.query",
    ] {
        assert!(!permits(
            &permissions.publish,
            &realm_route("quests", "acme", route)
        ));
        assert!(!permits(
            &permissions.subscribe,
            &realm_route("quests", "acme", route)
        ));
    }
    for (realm, organization) in FOREIGN {
        assert!(!permits(
            &permissions.publish,
            &realm_route(realm, organization, "editor.authoring.compiled.query")
        ));
        assert!(!permits(
            &permissions.subscribe,
            &realm_event(realm, organization, "editor.authoring.compiled.changed")
        ));
    }
    Ok(())
}

#[component_test(AuthTypewriterPermissions)]
async fn an_attached_engine_follows_rollout_but_cannot_lead_it(
    context: &mut Context,
) -> TestResult {
    let permissions = service_grants(context, "engine_one", Realm::Attached("quests")).await?;

    for step in ["probe", "command", "status"] {
        let own = realm_event("quests", "acme", &format!("rollout.{step}"));
        assert!(permits(&permissions.subscribe, &own));
        assert!(!permits(&permissions.publish, &own));
        for (realm, organization) in FOREIGN {
            let foreign = realm_event(realm, organization, &format!("rollout.{step}"));
            assert!(!permits(&permissions.subscribe, &foreign));
            assert!(!permits(&permissions.publish, &foreign));
        }
    }
    Ok(())
}

#[component_test(AuthTypewriterPermissions)]
async fn a_bound_service_reports_its_lifecycle_on_its_own_subjects(
    context: &mut Context,
) -> TestResult {
    bound_service(context, "engine_one", Realm::Attached("quests"))?;

    let grant = request_permissions(context, SERVICE_POLICY, &sign_in("engine_one")).await?;

    assert_eq!(grant.tags, ["service:engine_one", "organization:acme"]);
    let permissions = &grant.permissions;
    for subject in [
        "cloud.to.service.engine_one.heartbeat",
        "cloud.to.service.engine_one.shutdown",
        "cloud.to.service.engine_one.execution.watch",
        "cloud.to.service.engine_one.execution.register",
        "cloud.to.service.engine_one.execution.report",
    ] {
        assert!(
            permits(&permissions.publish, subject),
            "{subject} is not granted"
        );
        assert!(!permits(
            &permissions.publish,
            &subject.replace("engine_one", "engine_two")
        ));
    }
    assert!(permits(
        &permissions.subscribe,
        "cloud.from.service.engine_one.registration.bound"
    ));
    assert!(!permits(
        &permissions.subscribe,
        "cloud.from.service.engine_two.registration.bound"
    ));
    Ok(())
}

#[component_test(AuthTypewriterPermissions)]
async fn a_realm_host_serves_its_realm_routes_only(context: &mut Context) -> TestResult {
    let permissions = service_grants(context, "realm_host", Realm::Owned("quests")).await?;

    for route in [
        "editor.catalog.fetch",
        "editor.presentation.search",
        "editor.authoring.state.query",
        "editor.authoring.edit.commit",
        "editor.authoring.publish",
        "editor.authoring.compiled.query",
        "shared.blob.store",
        "shared.publish",
    ] {
        assert!(
            permits(
                &permissions.subscribe,
                &realm_route("quests", "acme", route)
            ),
            "the host cannot serve {route}"
        );
        for (realm, organization) in FOREIGN {
            assert!(!permits(
                &permissions.subscribe,
                &realm_route(realm, organization, route)
            ));
        }
    }
    for event in [
        "editor.catalog.invalidate",
        "editor.authoring.changed",
        "editor.authoring.compiled.changed",
    ] {
        assert!(permits(
            &permissions.publish,
            &realm_event("quests", "acme", event)
        ));
        for (realm, organization) in FOREIGN {
            assert!(!permits(
                &permissions.publish,
                &realm_event(realm, organization, event)
            ));
        }
    }
    // Bulk reads reply on the requester inbox under the response permission, not on a subject.
    assert!(!permits(
        &permissions.publish,
        &realm_event("quests", "acme", "editor.catalog.fetch.transfer")
    ));
    Ok(())
}

#[component_test(AuthTypewriterPermissions)]
async fn a_realm_host_coordinates_rollout_of_its_realm(context: &mut Context) -> TestResult {
    let permissions = service_grants(context, "realm_host", Realm::Owned("quests")).await?;

    for step in ["probe", "command", "status"] {
        assert!(permits(
            &permissions.publish,
            &realm_event("quests", "acme", &format!("rollout.{step}"))
        ));
        for (realm, organization) in FOREIGN {
            assert!(!permits(
                &permissions.publish,
                &realm_event(realm, organization, &format!("rollout.{step}"))
            ));
        }
    }
    Ok(())
}

#[component_test(AuthTypewriterPermissions)]
async fn failed_scope_lookup_replies_internal_error_instead_of_a_grant(
    context: &mut Context,
) -> TestResult {
    bound_service_without_scope(context, "failing_host")?;
    expect_scope(
        context,
        "failing_host",
        GetServiceMessagingScopeResponse::InternalError(Box::default()),
    )?;

    // The callout receives a typed failure at once instead of waiting for a reply.
    let reply: GetEntityPermissionResponse = context
        .request(SERVICE_POLICY, &sign_in("failing_host"))
        .await?;

    assert!(
        matches!(reply, GetEntityPermissionResponse::InternalError(_)),
        "{reply:?}"
    );
    Ok(())
}

#[component_test(AuthTypewriterPermissions)]
async fn unknown_service_gets_no_permissions(context: &mut Context) -> TestResult {
    expect_binding(
        context,
        "stranger",
        QueryServiceBindingResponse::ServiceNotFoundError(Box::default()),
    )?;

    let reply: GetEntityPermissionResponse = context
        .request(SERVICE_POLICY, &sign_in("stranger"))
        .await?;

    assert!(
        matches!(reply, GetEntityPermissionResponse::InternalError(_)),
        "{reply:?}"
    );
    Ok(())
}

#[component_test(AuthTypewriterPermissions)]
async fn unassigned_bound_service_receives_no_realm_permissions(
    context: &mut Context,
) -> TestResult {
    let permissions = service_grants(context, "idle_host", Realm::None).await?;

    assert!(
        permissions
            .publish
            .allow
            .iter()
            .chain(&permissions.subscribe.allow)
            .all(|subject| !subject.contains(".realm."))
    );
    Ok(())
}

#[component_test(AuthTypewriterPermissions)]
async fn unbound_service_receives_registration_notification_permission(
    context: &mut Context,
) -> TestResult {
    expect_binding(
        context,
        "engine_one",
        skir_variant!(QueryServiceBindingResponse::Binding {
            binding: ServiceBinding::Unbound,
        }),
    )?;

    let grant = request_permissions(context, SERVICE_POLICY, &sign_in("engine_one")).await?;

    assert_eq!(grant.tags, ["service:engine_one"]);
    assert!(permits(
        &grant.permissions.subscribe,
        "cloud.from.service.engine_one.registration.bound"
    ));
    assert!(grant.permissions.publish.allow.iter().all(|subject| {
        !subject.contains(".organization.") && !subject.starts_with("service.from.")
    }));
    Ok(())
}

/// Registration reports `service` as bound to Acme; the scope reply is left to the case.
fn bound_service_without_scope(context: &Context, service: &str) -> anyhow::Result<()> {
    expect_binding(
        context,
        service,
        skir_variant!(QueryServiceBindingResponse::Binding {
            binding: ServiceBinding::Bound(Box::new(ServiceBinding_Bound {
                organization_id: acme().key,
                ..Default::default()
            })),
        }),
    )
}
