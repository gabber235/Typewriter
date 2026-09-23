use std::collections::HashMap;

use otel_wasi::ResultWithSlug;
use serde::Deserialize;
use wasmcloud_utils::{
    database::{RecordId, transaction_query},
    decode_skir, extract_param,
    skir::base::organization::v1::organization::*,
    skir_domain_result, skir_variant,
    wasmcloud::messaging::types::NatsMessage,
};

use wasmcloud_utils::database::organization::OrganizationRecord;

/// Database result from creating an organization and advancing the user's list sequence.
///
/// Both values come from the same transaction so the emitted user projection change identifies
/// the sequence at which the new organization became visible.
#[derive(Deserialize)]
struct CreatedOrganization {
    organization: OrganizationRecord,
    sequence: i64,
}

/// Creates an organization for the user in the message subject.
///
/// The transaction records the organization and advances the user's organization list sequence.
/// After the transaction commits, the handler persists the corresponding add change and returns
/// that same event with the created organization. The operation identity makes database work
/// replayable, while event persistence remains a separate post transaction effect.
#[tracing::instrument(skip(msg, params))]
pub async fn handle_create(
    msg: NatsMessage,
    params: HashMap<String, String>,
) -> Result<CreateOrganizationResponse, otel_wasi::Error> {
    let user_id = extract_param!(params, user_id)?;
    otel_wasi::main_attribute!("user.id" = user_id.to_string());
    let user_key = user_id;
    let user_id = RecordId::new("user", user_id);
    let request = decode_skir!(CreateOrganizationRequest, &msg.body)?;
    if request.operation_id.is_empty() {
        return Ok(wasmcloud_utils::skir_variant!(
            CreateOrganizationResponse::InvalidOperationIdError
        ));
    }
    let receipt = wasmcloud_utils::database::mutation::receipt_id(
        user_key,
        "organizations",
        "CreateOrganization",
        &request.operation_id,
    );

    let name = request.name;
    let logo_url = request.logo_url;

    let organization = transaction_query!(
        CreatedOrganization,
        r#"
        BEGIN TRANSACTION;
        RETURN {
            LET $previous = fn::mutation::recall($receipt, $request_bytes);
            IF $previous != NONE { RETURN $previous.value };
            LET $result = {
LET $organization = CREATE ONLY organization SET
            name = $name,
            logo_url = $logo_url,
            founder = $user_id
            ;

        LET $sequence = UPDATE ONLY $user_id SET organizations_sequence += 1
            RETURN VALUE organizations_sequence;
        RETURN { organization: $organization, sequence: $sequence };
            };
            IF $result != NONE {
                LET $stored = fn::mutation::commit($receipt, $request_bytes, { value: $result });
                RETURN $stored.value;
            };
            RETURN $result;
        };
        COMMIT TRANSACTION;
        "#,
    )
    .bind("name", &name)
    .bind("logo_url", &logo_url)
    .bind("user_id", user_id)
    .bind("receipt", receipt)
    .bind("request_bytes", msg.body.clone())
    .execute()
    .await
    .error_with_slug("organization-create-query-failed")?
    .decode()
    .error_with_slug("organization-create-result-parse-failed")?;
    let created = skir_domain_result!(CreateOrganizationResponse, organization,
        "operation-identity-reused-error" => {});
    let organization: Organization = created.organization.into();

    otel_wasi::main_attribute!("organization.id" = organization.organization_id.to_string());
    let event = UserOrganizationsChanged {
        sequence: created.sequence,
        operation_id: request.operation_id,
        changes: vec![UserOrganizationsChange::Add(Box::new(organization.clone()))],
        ..Default::default()
    };
    wasmcloud_utils::skir_subjects::user_organizations_changed(user_key)
        .persist(event.clone())
        .await?;

    otel_wasi::main_attribute!("organization.outcome" = "created");
    Ok(skir_variant!(CreateOrganizationResponse::Success {
        organization,
        event
    }))
}
