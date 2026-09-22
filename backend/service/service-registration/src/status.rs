//! Reports the service registration state and maintains its unbound registration lease.
//!
//! Status is intentionally service scoped and separate from the organization scoped bind,
//! metadata update, and unbind operations. It is the service registrar's bootstrap boundary. A
//! bound service returns its durable organization association. An unbound service returns the
//! current token, creating one when needed and renewing it when it enters the two minute renewal
//! window. The lease is temporary bearer authority, not liveness; heartbeat and shutdown own
//! liveness state.
//!
//! The lease read and any renewal share one transaction so the response describes the same state
//! that was observed. No mutation receipt is used here because status is a current state query,
//! not a caller identified command. Its canonical response is `Status` or `ServiceNotFoundError`;
//! database and decoding failures remain internal errors. Later bind and unbind publications do
//! not alter this service scoped response contract.

use std::collections::HashMap;

use otel_wasi::ResultWithSlug;
use serde::Deserialize;
use wasmcloud_utils::{
    database::{RecordId, transaction_query},
    decode_skir, extract_param,
    skir::base::service::v1::status::{
        GetServiceStatusRequest, GetServiceStatusResponse, GetServiceStatusResponse_Status,
        ServiceBinding, ServiceBinding_Bound, ServiceBinding_Unbound,
    },
    skir_domain_result, skir_variant,
    wasmcloud::messaging::types::NatsMessage,
};

use crate::utils;
use wasmcloud_utils::database::organization::OrganizationRecord;

#[derive(Debug, Deserialize)]
struct StatusQueryResult {
    organization: Option<OrganizationRecord>,
    token: Option<String>,
}

/// Returns the current binding state and, when unbound, the lease available for operator binding.
///
/// The transaction renews an expiring unbound lease before constructing the response, while a
/// bound service bypasses lease handling and exposes only its organization. The service registrar
/// uses this result to decide whether to authenticate against an existing binding or wait for an
/// operator to consume the token. It does not prove service liveness.
#[tracing::instrument(skip(msg, params))]
pub async fn handle_status(
    msg: NatsMessage,
    params: HashMap<String, String>,
) -> Result<GetServiceStatusResponse, otel_wasi::Error> {
    let service_id = extract_param!(params, service_id)?;
    otel_wasi::main_attribute!("service.id" = service_id.to_string());
    let _ = decode_skir!(GetServiceStatusRequest, &msg.body)?;
    let service_id = RecordId::new("service", service_id);

    let result = transaction_query!(
        StatusQueryResult,
        r#"
        BEGIN TRANSACTION;

        RETURN {
            LET $registration_lease = 2m30s;
            LET $registration_renewal_window = 2m;
            LET $services = SELECT
                IF organization THEN { id: organization.id, name: organization.name } ELSE NONE END AS organization,
                registration.token AS existing_token,
                registration.expires_at AS existing_expires_at
            FROM $service_id
            FETCH organization;

            IF array::is_empty($services) {
                THROW 'service-not-found-error'
            };

            LET $service = array::first($services);
            IF $service.organization != NONE {
                RETURN { organization: $service.organization, token: NONE }
            };

            LET $registration_token = IF $service.existing_token != NONE AND $service.existing_expires_at > time::now() {
                $service.existing_token
            } ELSE {
                $new_token
            };

            IF $service.existing_token = NONE OR $service.existing_expires_at <= time::now() + $registration_renewal_window {
                UPDATE ONLY $service_id SET registration = {
                    token: $registration_token,
                    expires_at: time::now() + $registration_lease
                }
            };

            RETURN { organization: NONE, token: $registration_token };
        };

        COMMIT TRANSACTION;
        "#,
    )
    .bind("service_id", service_id)
    .bind("new_token", utils::generate_registration_token())
    .execute()
    .await
    .error_with_slug("service-status-query-failed")?
    .decode()
    .error_with_slug("service-status-result-parse-failed")?;

    let status = skir_domain_result!(GetServiceStatusResponse, result);

    let binding = if let Some(organization) = status.organization {
        skir_variant!(ServiceBinding::Bound {
            organization_id: organization.id.key.to_string(),
            organization_name: Some(organization.name),
        })
    } else {
        skir_variant!(ServiceBinding::Unbound {
            registration_token: status.token,
        })
    };

    Ok(skir_variant!(GetServiceStatusResponse::Status { binding }))
}
