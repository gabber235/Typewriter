use otel_wasi::ResultWithSlug;
use serde::Deserialize;
use wasmcloud_utils::{
    database::{RecordId, read_query},
    decode_skir,
    skir::base::service::v1::topology::{
        GetServiceMessagingScopeRequest, GetServiceMessagingScopeResponse,
        GetServiceMessagingScopeResponse_NotFound, ServiceMessagingScope,
    },
    skir_variant,
    wasmcloud::messaging::types::BrokerMessage,
};

#[derive(Debug, Deserialize)]
struct MessagingScopeRecord {
    organization_id: RecordId,
    owned_realm: Option<RecordId>,
    attached_realm: Option<RecordId>,
}

#[tracing::instrument(skip(msg))]
pub async fn handle(
    msg: BrokerMessage,
    _params: HashMap<String, String>,
) -> Result<GetServiceMessagingScopeResponse, otel_wasi::Error> {
    let request = decode_skir!(GetServiceMessagingScopeRequest, &msg.body)?;
    let service_id: RecordId = request.service_id.into();
    let result = read_query!(
        r#"
        LET $service = array::first(SELECT organization FROM $service_id);
        LET $host = array::first(SELECT id FROM service_host WHERE service_id = $service_id);

        RETURN IF $service = NONE {
            NONE
        } ELSE {
            {
                organization_id: $service.organization,
                owned_realm: IF $host = NONE { NONE } ELSE {
                    array::first(SELECT VALUE id FROM realm_instance WHERE owner_host_id = $host.id)
                },
                attached_realm: IF $host = NONE { NONE } ELSE {
                    array::first(SELECT VALUE realm_id FROM engine_instance WHERE owner_host_id = $host.id)
                },
            }
        };
        "#,
    )
    .bind("service_id", service_id)
    .execute()
    .await
    .error_with_slug("service-messaging-scope-query-failed")?;

    let scope: Option<MessagingScopeRecord> = result
        .parse()
        .error_with_slug("service-messaging-scope-decode-failed")?;

    Ok(match scope {
        Some(scope) => GetServiceMessagingScopeResponse::Found(Box::new(ServiceMessagingScope {
            organization_id: scope.organization_id.key.to_string(),
            owned_realm: scope.owned_realm.map(Into::into),
            attached_realm: scope.attached_realm.map(Into::into),
            _unrecognized: None,
        })),
        None => skir_variant!(GetServiceMessagingScopeResponse::NotFound {}),
    })
}
use std::collections::HashMap;
