//! Service grants, checked by the subjects a service must and must not reach.

use super::AuthTypewriterPermissions;
use typewriter_component_test::{
    access::{
        Realm, SERVICE_POLICY, bound_service, expect_binding, expect_bound, expect_scope, permits,
        request_permissions, service_grants, service_sign_in,
    },
    prelude::*,
};
use wasmcloud_utils::{
    skir::base::{
        access::v1::permission::GetEntityPermissionResponse,
        service::v1::{
            status::{
                QueryServiceBindingResponse, QueryServiceBindingResponse_Binding, ServiceBinding,
            },
            topology::GetServiceMessagingScopeResponse,
        },
    },
    skir_variant,
    transport_routes::{REPLY_TTL_MS, SERVICE_RESPONSE_LIMIT},
};

/// Another realm of Acme and the same realm key in another organization.
const FOREIGN: [(&str, &str); 2] = [("foreign_realm", "acme"), ("quests", "globex")];

#[component_test(AuthTypewriterPermissions)]
async fn a_service_may_answer_every_frame_of_its_largest_reply(
    context: &mut TestContext<AuthTypewriterPermissions>,
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
    context: &mut TestContext<AuthTypewriterPermissions>,
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
    context: &mut TestContext<AuthTypewriterPermissions>,
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
    context: &mut TestContext<AuthTypewriterPermissions>,
) -> TestResult {
    bound_service(context, "engine_one", Realm::Attached("quests"))?;

    let grant =
        request_permissions(context, SERVICE_POLICY, &service_sign_in("engine_one")).await?;

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
async fn a_realm_host_serves_its_realm_routes_only(
    context: &mut TestContext<AuthTypewriterPermissions>,
) -> TestResult {
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
async fn a_realm_host_coordinates_rollout_of_its_realm(
    context: &mut TestContext<AuthTypewriterPermissions>,
) -> TestResult {
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
    context: &mut TestContext<AuthTypewriterPermissions>,
) -> TestResult {
    expect_bound(context, "failing_host")?;
    expect_scope(
        context,
        "failing_host",
        GetServiceMessagingScopeResponse::InternalError(Box::default()),
    )?;

    // The callout receives a typed failure at once instead of waiting for a reply.
    let reply: GetEntityPermissionResponse = context
        .request(SERVICE_POLICY, &service_sign_in("failing_host"))
        .await?;

    assert!(
        matches!(reply, GetEntityPermissionResponse::InternalError(_)),
        "{reply:?}"
    );
    Ok(())
}

#[component_test(AuthTypewriterPermissions)]
async fn unknown_service_gets_no_permissions(
    context: &mut TestContext<AuthTypewriterPermissions>,
) -> TestResult {
    expect_binding(
        context,
        "stranger",
        QueryServiceBindingResponse::ServiceNotFoundError(Box::default()),
    )?;

    let reply: GetEntityPermissionResponse = context
        .request(SERVICE_POLICY, &service_sign_in("stranger"))
        .await?;

    assert!(
        matches!(reply, GetEntityPermissionResponse::InternalError(_)),
        "{reply:?}"
    );
    Ok(())
}

#[component_test(AuthTypewriterPermissions)]
async fn unassigned_bound_service_receives_no_realm_permissions(
    context: &mut TestContext<AuthTypewriterPermissions>,
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
    context: &mut TestContext<AuthTypewriterPermissions>,
) -> TestResult {
    expect_binding(
        context,
        "engine_one",
        skir_variant!(QueryServiceBindingResponse::Binding {
            binding: ServiceBinding::Unbound,
        }),
    )?;

    let grant =
        request_permissions(context, SERVICE_POLICY, &service_sign_in("engine_one")).await?;

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
