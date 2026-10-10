use component_test::{TestContext, TestResult, component_test, subject_matches};
use typewriter_component_test::prelude::{SkirMessagingExpectationExt, skir_record_id};
use wasmcloud_utils::{
    skir::base::{
        access::v1::permission::{
            EntityPermissionQualifier, GetEntityPermissionRequest, Permission, Permissions,
        },
        service::v1::status::{
            QueryServiceBindingRequest, QueryServiceBindingResponse,
            QueryServiceBindingResponse_Binding, ServiceBinding, ServiceBinding_Bound,
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

fn permits(permission: &Permission, subject: &str) -> bool {
    permission
        .allow
        .iter()
        .any(|pattern| subject_matches(pattern, subject))
        && !permission
            .deny
            .iter()
            .any(|pattern| subject_matches(pattern, subject))
}

fn assert_published_content_access(permissions: &Permissions, organization: &str, realm: &str) {
    let request = format!("service.to.{realm}.organization.{organization}.realm");
    let events = format!("service.from.{realm}.organization.{organization}.realm");
    assert!(permits(
        &permissions.publish,
        &format!("{request}.editor.authoring.compiled.query")
    ));
    for suffix in [
        "editor.authoring.compiled.changed",
        "editor.authoring.compiled.query.transfer_one",
    ] {
        assert!(permits(
            &permissions.subscribe,
            &format!("{events}.{suffix}")
        ));
    }
    for suffix in [
        "editor.authoring.edit.commit",
        "editor.authoring.type.commit",
        "editor.authoring.publish",
        "editor.authoring.state.query",
    ] {
        assert!(!permits(
            &permissions.publish,
            &format!("{request}.{suffix}")
        ));
    }
    assert!(!permits(
        &permissions.subscribe,
        &format!("{events}.editor.authoring.compiled.query.transfer_one.extra")
    ));
    for (other_organization, other_realm) in [
        (organization, "foreign_realm"),
        ("foreign_organization", realm),
    ] {
        assert!(!permits(
            &permissions.publish,
            &format!(
                "service.to.{other_realm}.organization.{other_organization}.realm.editor.authoring.compiled.query"
            )
        ));
        for suffix in [
            "editor.authoring.compiled.changed",
            "editor.authoring.compiled.query.transfer_one",
        ] {
            assert!(!permits(
                &permissions.subscribe,
                &format!(
                    "service.from.{other_realm}.organization.{other_organization}.realm.{suffix}"
                )
            ));
        }
    }
}

fn assert_rollout_participant_access(permissions: &Permissions, organization: &str, realm: &str) {
    let prefix = format!("typewriter.organization.{organization}.realm.{realm}.hosts");
    for suffix in ["probe", "command", "status"] {
        assert!(permits(
            &permissions.subscribe,
            &format!("{prefix}.{suffix}")
        ));
    }
    assert!(permits(&permissions.publish, &format!("{prefix}.state")));

    for foreign_prefix in [
        format!("typewriter.organization.{organization}.realm.foreign_realm.hosts"),
        format!("typewriter.organization.foreign_organization.realm.{realm}.hosts"),
    ] {
        for suffix in ["probe", "command", "status", "state"] {
            let subject = format!("{foreign_prefix}.{suffix}");
            assert!(!permits(&permissions.publish, &subject));
            assert!(!permits(&permissions.subscribe, &subject));
        }
    }
}

fn assert_rollout_participant_only_denials(
    permissions: &Permissions,
    organization: &str,
    realm: &str,
) {
    let prefix = format!("typewriter.organization.{organization}.realm.{realm}.hosts");
    for suffix in ["probe", "command", "status"] {
        assert!(!permits(
            &permissions.publish,
            &format!("{prefix}.{suffix}")
        ));
    }
    assert!(!permits(&permissions.subscribe, &format!("{prefix}.state")));
}

fn assert_rollout_coordinator_access(permissions: &Permissions, organization: &str, realm: &str) {
    let prefix = format!("typewriter.organization.{organization}.realm.{realm}.hosts");
    for suffix in ["probe", "command", "status"] {
        assert!(permits(&permissions.publish, &format!("{prefix}.{suffix}")));
    }
    assert!(permits(&permissions.subscribe, &format!("{prefix}.state")));
}

#[component_test(AuthTypewriterPermissions)]
async fn attached_service_receives_only_its_realm_permissions(
    context: &mut TestContext<AuthTypewriterPermissions>,
) -> TestResult {
    let status = skir_variant!(QueryServiceBindingResponse::Binding {
        binding: ServiceBinding::Bound(Box::new(ServiceBinding_Bound {
            organization_id: "writers".into(),
            organization_name: Some("Writers".into()),
            _unrecognized: None,
        })),
    });
    context
        .messaging_mock()?
        .expect_request("service.engine_one.binding.query")
        .body_skir(
            &QueryServiceBindingRequest::default(),
            QueryServiceBindingRequest::serializer(),
        )
        .reply_skir(&status, QueryServiceBindingResponse::serializer());
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

    let response_permission = response
        .permissions
        .response
        .as_ref()
        .ok_or_else(|| anyhow::anyhow!("service response permission missing"))?;
    assert_eq!(response_permission.max_messages, Some(1));
    assert_eq!(
        response_permission
            .ttl
            .as_ref()
            .map(|duration| duration.milliseconds),
        Some(300_000)
    );

    assert_eq!(
        response.tags,
        ["service:engine_one", "organization:writers"]
    );
    assert_published_content_access(&response.permissions, "writers", "quests");
    assert_rollout_participant_access(&response.permissions, "writers", "quests");
    assert_rollout_participant_only_denials(&response.permissions, "writers", "quests");
    for suffix in [
        "editor.authoring.edit.commit",
        "editor.authoring.type.commit",
        "editor.authoring.publish",
        "editor.authoring.state.query",
    ] {
        assert!(!permits(
            &response.permissions.subscribe,
            &format!("service.to.quests.organization.writers.realm.{suffix}")
        ));
    }
    for suffix in [
        "editor.authoring.compiled.changed",
        "editor.authoring.compiled.query.transfer_one",
    ] {
        assert!(!permits(
            &response.permissions.publish,
            &format!("service.from.quests.organization.writers.realm.{suffix}")
        ));
    }
    let publish = &response.permissions.publish.allow;
    assert!(publish.contains(&"cloud.to.service.engine_one.execution.watch".into()));
    assert!(publish.contains(&"cloud.to.service.engine_one.execution.register".into()));
    assert!(publish.contains(&"cloud.to.service.engine_one.execution.report".into()));
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
    assert!(publish.contains(&"cloud.to.service.engine_one.heartbeat".into()));
    assert!(publish.contains(&"cloud.to.service.engine_one.shutdown".into()));
    let subscribe = &response.permissions.subscribe.allow;
    assert!(subscribe.contains(&"cloud.from.service.engine_one.execution.watch".into()));
    assert!(subscribe.contains(&"cloud.from.service.engine_one.registration.bound".into()));
    assert!(publish.iter().all(|subject| !subject.contains("realm.*")));
    assert!(subscribe.iter().all(|subject| !subject.contains("realm.*")));
    assert!(
        subscribe
            .iter()
            .all(|subject| !subject.ends_with(".realm.>"))
    );
    Ok(())
}

#[component_test(AuthTypewriterPermissions)]
async fn realm_service_executes_realm_routes_and_coordinates_hosts(
    context: &mut TestContext<AuthTypewriterPermissions>,
) -> TestResult {
    let status = skir_variant!(QueryServiceBindingResponse::Binding {
        binding: ServiceBinding::Bound(Box::new(ServiceBinding_Bound {
            organization_id: "writers".into(),
            organization_name: Some("Writers".into()),
            _unrecognized: None,
        })),
    });
    context
        .messaging_mock()?
        .expect_request("service.realm_host.binding.query")
        .body_skir(
            &QueryServiceBindingRequest::default(),
            QueryServiceBindingRequest::serializer(),
        )
        .reply_skir(&status, QueryServiceBindingResponse::serializer());
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
    assert_published_content_access(&response.permissions, "writers", "quests");
    assert_rollout_participant_access(&response.permissions, "writers", "quests");
    assert_rollout_coordinator_access(&response.permissions, "writers", "quests");
    for suffix in [
        "editor.authoring.compiled.query",
        "editor.capability.command.invoke",
        "editor.capability.computation.invoke",
        "editor.catalog.fetch",
        "editor.catalog.invalidate",
        "editor.creation.prepare",
        "editor.presentation.search",
        "editor.presentation.search.cancel",
        "editor.authoring.state.query",
        "editor.authoring.edit.commit",
        "editor.authoring.type.preview",
        "editor.authoring.type.commit",
        "editor.authoring.search",
        "editor.authoring.publish",
        "editor.authoring.publication.watch",
        "editor.authoring.compiled.status.query",
        "shared.blob.begin",
        "shared.blob.complete",
        "shared.blob.metadata",
        "shared.blob.read",
        "shared.blob.write",
        "shared.catalog.fetch",
        "shared.publish",
    ] {
        assert!(subscribe.contains(&format!(
            "service.to.quests.organization.writers.realm.{suffix}"
        )));
    }
    for suffix in [
        "editor.catalog.fetch.*",
        "editor.catalog.invalidate",
        "editor.presentation.search",
        "editor.authoring.changed",
        "editor.authoring.state.query.*",
        "editor.authoring.compiled.changed",
        "editor.authoring.compiled.query.*",
        "editor.authoring.publication.watch",
    ] {
        assert!(publish.contains(&format!(
            "service.from.quests.organization.writers.realm.{suffix}"
        )));
    }
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
    assert!(publish.iter().all(|subject| !subject.contains("realm.*")));
    assert!(subscribe.iter().all(|subject| !subject.contains("realm.*")));
    assert!(publish.iter().all(|subject| !subject.ends_with(".realm.>")));
    assert!(
        subscribe
            .iter()
            .all(|subject| !subject.ends_with(".realm.>"))
    );
    Ok(())
}

#[component_test(AuthTypewriterPermissions)]
async fn unassigned_bound_service_receives_no_realm_permissions(
    context: &mut TestContext<AuthTypewriterPermissions>,
) -> TestResult {
    let status = skir_variant!(QueryServiceBindingResponse::Binding {
        binding: ServiceBinding::Bound(Box::new(ServiceBinding_Bound {
            organization_id: "writers".into(),
            organization_name: Some("Writers".into()),
            _unrecognized: None,
        })),
    });
    context
        .messaging_mock()?
        .expect_request("service.idle_host.binding.query")
        .body_skir(
            &QueryServiceBindingRequest::default(),
            QueryServiceBindingRequest::serializer(),
        )
        .reply_skir(&status, QueryServiceBindingResponse::serializer());
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
    let status = skir_variant!(QueryServiceBindingResponse::Binding {
        binding: ServiceBinding::Unbound,
    });
    context
        .messaging_mock()?
        .expect_request("service.engine_one.binding.query")
        .body_skir(
            &QueryServiceBindingRequest::default(),
            QueryServiceBindingRequest::serializer(),
        )
        .reply_skir(&status, QueryServiceBindingResponse::serializer());

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
