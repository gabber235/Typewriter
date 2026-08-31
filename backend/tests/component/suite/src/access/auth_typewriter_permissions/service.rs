use component_test::{TestContext, TestResult, component_test};
use typewriter_component_test::prelude::{SkirMessagingExpectationExt, skir_record_id};
use wasmcloud_utils::{
    skir::base::{
        access::v1::permission::{EntityPermissionQualifier, GetEntityPermissionRequest},
        service::v1::status::{
            GetServiceStatusRequest, GetServiceStatusResponse, GetServiceStatusResponse_Status,
            ServiceBinding, ServiceBinding_Bound, ServiceBinding_Unbound,
        },
        service::v1::topology::{
            GetServiceMessagingScopeRequest, GetServiceMessagingScopeResponse,
            ServiceMessagingScope,
        },
    },
    skir_variant,
};

use super::{AuthTypewriterPermissions, request_permissions};

fn request(service_id: &str) -> GetEntityPermissionRequest {
    GetEntityPermissionRequest {
        qualifier: EntityPermissionQualifier::Service(Box::default()),
        jwt_claims: serde_json::to_vec(&serde_json::json!({
            "sub": service_id,
            "preferred_username": "Fixture Service"
        }))
        .expect("claims are valid JSON"),
        _unrecognized: None,
    }
}

#[component_test(AuthTypewriterPermissions)]
async fn attached_service_receives_only_its_realm_permissions(
    context: &mut TestContext<AuthTypewriterPermissions>,
) -> TestResult {
    let status = skir_variant!(GetServiceStatusResponse::Status {
        binding: ServiceBinding::Bound(Box::new(ServiceBinding_Bound {
            organization_id: "writers".into(),
            organization_name: Some("Writers".into()),
            _unrecognized: None,
        })),
    });
    context
        .messaging_mock()?
        .expect_request("service.engine_one.status")
        .body_skir(
            &GetServiceStatusRequest::default(),
            GetServiceStatusRequest::serializer(),
        )
        .reply_skir(&status, GetServiceStatusResponse::serializer());
    let scope = GetServiceMessagingScopeResponse::Found(Box::new(ServiceMessagingScope {
        organization_id: "writers".into(),
        owned_realm: None,
        attached_realm: Some(skir_record_id("realm_instance", "quests")),
        _unrecognized: None,
    }));
    context
        .messaging_mock()?
        .expect_request("service.engine_one.messaging.scope")
        .body_skir(
            &GetServiceMessagingScopeRequest {
                service_id: skir_record_id("service", "engine_one"),
                _unrecognized: None,
            },
            GetServiceMessagingScopeRequest::serializer(),
        )
        .reply_skir(&scope, GetServiceMessagingScopeResponse::serializer());

    let response = request_permissions(
        context,
        "auth.permissions.typewriter-services",
        &request("engine_one"),
    )
    .await?;

    assert_eq!(
        response.tags,
        ["service:engine_one", "organization:writers"]
    );
    let publish = &response.permissions.publish.allow;
    assert!(publish.contains(&"cloud.to.service.engine_one.execution.watch".into()));
    assert!(publish.contains(&"cloud.to.service.engine_one.execution.register".into()));
    assert!(publish.contains(&"cloud.to.service.engine_one.execution.report".into()));
    assert!(publish.contains(&"typewriter.organization.writers.realm.quests.hosts.state".into()));
    for suffix in [
        "shared.catalog.fetch",
        "shared.publish",
        "shared.blob.metadata",
        "shared.blob.read",
        "shared.blob.begin",
        "shared.blob.write",
        "shared.blob.complete",
    ] {
        assert!(publish.contains(&format!(
            "service.to.quests.organization.writers.realm.{suffix}"
        )));
    }
    for suffix in ["status", "heartbeat", "shutdown"] {
        assert!(publish.contains(&format!(
            "cloud.to.service.engine_one.organization.writers.{suffix}"
        )));
    }
    let subscribe = &response.permissions.subscribe.allow;
    assert!(subscribe.contains(&"cloud.from.service.engine_one.execution.watch".into()));
    for suffix in ["probe", "command", "status"] {
        assert!(subscribe.contains(&format!(
            "typewriter.organization.writers.realm.quests.hosts.{suffix}"
        )));
    }
    assert!(subscribe.contains(&"typewriter.organization.writers.realm.quests.shared.changed".into()));
    assert!(subscribe.contains(&"cloud.from.service.engine_one.registration.bound".into()));
    for suffix in ["configuration", "command"] {
        assert!(subscribe.contains(&format!(
            "cloud.from.service.engine_one.organization.writers.{suffix}"
        )));
    }
    assert!(publish.iter().all(|subject| !subject.contains("realm.*")));
    assert!(subscribe.iter().all(|subject| !subject.contains("realm.*")));
    assert!(subscribe.iter().all(|subject| !subject.ends_with(".realm.>")));
    Ok(())
}

#[component_test(AuthTypewriterPermissions)]
async fn realm_service_executes_realm_routes_and_coordinates_hosts(
    context: &mut TestContext<AuthTypewriterPermissions>,
) -> TestResult {
    let status = skir_variant!(GetServiceStatusResponse::Status {
        binding: ServiceBinding::Bound(Box::new(ServiceBinding_Bound {
            organization_id: "writers".into(),
            organization_name: Some("Writers".into()),
            _unrecognized: None,
        })),
    });
    context
        .messaging_mock()?
        .expect_request("service.realm_host.status")
        .body_skir(
            &GetServiceStatusRequest::default(),
            GetServiceStatusRequest::serializer(),
        )
        .reply_skir(&status, GetServiceStatusResponse::serializer());
    let scope = GetServiceMessagingScopeResponse::Found(Box::new(ServiceMessagingScope {
        organization_id: "writers".into(),
        owned_realm: Some(skir_record_id("realm_instance", "quests")),
        attached_realm: None,
        _unrecognized: None,
    }));
    context
        .messaging_mock()?
        .expect_request("service.realm_host.messaging.scope")
        .body_skir(
            &GetServiceMessagingScopeRequest {
                service_id: skir_record_id("service", "realm_host"),
                _unrecognized: None,
            },
            GetServiceMessagingScopeRequest::serializer(),
        )
        .reply_skir(&scope, GetServiceMessagingScopeResponse::serializer());

    let response = request_permissions(
        context,
        "auth.permissions.typewriter-services",
        &request("realm_host"),
    )
    .await?;

    let publish = &response.permissions.publish.allow;
    let subscribe = &response.permissions.subscribe.allow;
    assert!(subscribe.contains(&"service.to.quests.organization.writers.realm.>".into()));
    assert!(subscribe.contains(&"typewriter.organization.writers.realm.quests.hosts.state".into()));
    assert!(publish.contains(&"service.from.quests.organization.writers.realm.>".into()));
    for suffix in ["probe", "command", "status"] {
        assert!(publish.contains(&format!(
            "typewriter.organization.writers.realm.quests.hosts.{suffix}"
        )));
    }
    assert!(publish.contains(&"typewriter.organization.writers.realm.quests.shared.changed".into()));
    assert!(publish.iter().all(|subject| !subject.contains("realm.*")));
    assert!(subscribe.iter().all(|subject| !subject.contains("realm.*")));
    Ok(())
}

#[component_test(AuthTypewriterPermissions)]
async fn unassigned_bound_service_receives_no_realm_permissions(
    context: &mut TestContext<AuthTypewriterPermissions>,
) -> TestResult {
    let status = skir_variant!(GetServiceStatusResponse::Status {
        binding: ServiceBinding::Bound(Box::new(ServiceBinding_Bound {
            organization_id: "writers".into(),
            organization_name: Some("Writers".into()),
            _unrecognized: None,
        })),
    });
    context
        .messaging_mock()?
        .expect_request("service.idle_host.status")
        .body_skir(
            &GetServiceStatusRequest::default(),
            GetServiceStatusRequest::serializer(),
        )
        .reply_skir(&status, GetServiceStatusResponse::serializer());
    let scope = GetServiceMessagingScopeResponse::Found(Box::new(ServiceMessagingScope {
        organization_id: "writers".into(),
        owned_realm: None,
        attached_realm: None,
        _unrecognized: None,
    }));
    context
        .messaging_mock()?
        .expect_request("service.idle_host.messaging.scope")
        .body_skir(
            &GetServiceMessagingScopeRequest {
                service_id: skir_record_id("service", "idle_host"),
                _unrecognized: None,
            },
            GetServiceMessagingScopeRequest::serializer(),
        )
        .reply_skir(&scope, GetServiceMessagingScopeResponse::serializer());

    let response = request_permissions(
        context,
        "auth.permissions.typewriter-services",
        &request("idle_host"),
    )
    .await?;

    assert!(response.permissions.publish.allow.iter().all(|subject| {
        !subject.starts_with("typewriter.organization.") && !subject.contains(".realm.")
    }));
    assert!(response.permissions.subscribe.allow.iter().all(|subject| {
        !subject.starts_with("typewriter.organization.") && !subject.contains(".realm.")
    }));
    Ok(())
}

#[component_test(AuthTypewriterPermissions)]
async fn unbound_service_receives_registration_notification_permission(
    context: &mut TestContext<AuthTypewriterPermissions>,
) -> TestResult {
    let status = skir_variant!(GetServiceStatusResponse::Status {
        binding: ServiceBinding::Unbound(Box::new(ServiceBinding_Unbound {
            registration_token: Some("fixture-token".into()),
            _unrecognized: None,
        })),
    });
    context
        .messaging_mock()?
        .expect_request("service.engine_one.status")
        .body_skir(
            &GetServiceStatusRequest::default(),
            GetServiceStatusRequest::serializer(),
        )
        .reply_skir(&status, GetServiceStatusResponse::serializer());

    let response = request_permissions(
        context,
        "auth.permissions.typewriter-services",
        &request("engine_one"),
    )
    .await?;

    assert_eq!(response.tags, ["service:engine_one"]);
    assert!(
        response
            .permissions
            .subscribe
            .allow
            .contains(&"cloud.from.service.engine_one.registration.bound".into())
    );
    assert!(response.permissions.publish.allow.iter().all(|subject| {
        !subject.contains(".organization.") && !subject.starts_with("service.from.")
    }));
    Ok(())
}
