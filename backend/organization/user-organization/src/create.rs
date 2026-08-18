use std::collections::HashMap;

use otel_wasi::ResultWithSlug;
use wasmcloud_utils::{
    database::{RecordId, transaction_query},
    decode_skir, extract_param,
    skir::base::organization::v1::{organization::*, user::*},
    skir_domain_result,
    wasmcloud::messaging::types::BrokerMessage,
};

use wasmcloud_utils::database::organization::OrganizationRecord;

#[tracing::instrument(skip(msg, params))]
pub async fn handle_create(
    msg: BrokerMessage,
    params: HashMap<String, String>,
) -> Result<CreateOrganizationResponse, otel_wasi::Error> {
    let user_id = extract_param!(params, user_id)?;
    otel_wasi::main_attribute!("user.id" = user_id.to_string());
    let user_key = user_id;
    let user_id = RecordId::new("user", user_id);
    let request = decode_skir!(CreateOrganizationRequest, &msg.body)?;

    let name = request.name;
    let logo_url = request.logo_url;

    let organization = transaction_query!(
        OrganizationRecord,
        r#"
        BEGIN TRANSACTION;

        LET $organization = CREATE ONLY organization SET
            name = $name,
            logo_url = $logo_url,
            founder = $user_id
            ;

        RETURN $organization;

        COMMIT TRANSACTION;
        "#,
    )
    .bind("name", &name)
    .bind("logo_url", &logo_url)
    .bind("user_id", user_id)
    .execute()
    .await
    .error_with_slug("organization-create-query-failed")?
    .decode()
    .error_with_slug("organization-create-result-parse-failed")?;
    let organization: Organization =
        skir_domain_result!(CreateOrganizationResponse, organization).into();

    otel_wasi::main_attribute!("organization.id" = organization.organization_id.to_string());
    wasmcloud_utils::skir_subjects::user_organizations(user_key)
        .publish(WatchUserOrganizationsResponse::Add(Box::new(
            organization.clone(),
        )))
        .await?;

    otel_wasi::main_attribute!("organization.outcome" = "created");
    Ok(CreateOrganizationResponse::Success(organization.into()))
}
