use component_test::{TestContext, TestResult, component_test};
use typewriter_component_test::prelude::SkirMessagingExpectationExt;
use wasmcloud_utils::{
    skir::base::{
        access::v1::permission::{
            EntityPermissionQualifier, EntityPermissionQualifier_Service,
            GetEntityPermissionRequest,
        },
        service::v1::status::{
            GetServiceStatusRequest, GetServiceStatusResponse, GetServiceStatusResponse_Status,
            ServiceBinding, ServiceBinding_Bound, ServiceBinding_Unbound,
        },
    },
    skir_variant,
};

use super::{AuthTypewriterPermissions, request_permissions};

fn request(service_id: &str) -> GetEntityPermissionRequest {
    GetEntityPermissionRequest {
        qualifier: EntityPermissionQualifier::Service(Box::new(
            EntityPermissionQualifier_Service::default(),
        )),
        jwt_claims: serde_json::to_vec(&serde_json::json!({
            "sub": service_id,
            "preferred_username": "Fixture Service"
        }))
        .expect("claims are valid JSON"),
        _unrecognized: None,
    }
}

#[component_test(AuthTypewriterPermissions)]
async fn bound_service_receives_scoped_cloud_and_realm_permissions(
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
    for suffix in ["status", "heartbeat", "shutdown"] {
        assert!(publish.contains(&format!(
            "cloud.to.service.engine_one.organization.writers.{suffix}"
        )));
    }
    for suffix in [
        "book.watch",
        "book.resource.watch",
        "page.watch",
        "tag.watch",
        "tag.resource.watch",
    ] {
        assert!(publish.contains(&format!(
            "service.from.engine_one.organization.writers.realm.{suffix}"
        )));
    }

    let subscribe = &response.permissions.subscribe.allow;
    for suffix in ["configuration", "command"] {
        assert!(subscribe.contains(&format!(
            "cloud.from.service.engine_one.organization.writers.{suffix}"
        )));
    }
    for suffix in [
        "book.watch",
        "book.resource.watch",
        "book.create",
        "book.update",
        "page.search",
        "page.watch",
        "page.create",
        "page.update",
        "page.delete",
        "pages.chapters",
        "tag.watch",
        "tag.resource.watch",
        "tag.create",
        "tag.update",
        "tag.delete",
        "tag.move",
        "tag.resize",
    ] {
        assert!(subscribe.contains(&format!(
            "service.to.engine_one.organization.writers.realm.{suffix}"
        )));
    }
    assert!(publish.iter().all(|subject| !subject.ends_with("realm.>")));
    assert!(subscribe.iter().all(|subject| !subject.ends_with("realm.>")));
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
