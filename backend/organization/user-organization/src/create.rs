use std::collections::HashMap;

use otel_wasi::ResultWithSlug;
use surrealdb_component_sdk::query;
use wasmcloud_utils::{
    decode_skir, extract_param,
    skir::base::organization::v1::{organization::*, user::*},
    wasmcloud::messaging::types::BrokerMessage,
};

use crate::OrganizationRecord;

pub async fn handle_create(
    msg: BrokerMessage,
    params: HashMap<String, String>,
) -> Result<CreateOrganizationResponse, otel_wasi::Error> {
    let user_id = extract_param!(params, user_id)?;
    let request = decode_skir!(CreateOrganizationRequest, &msg.body)?;

    let name = request.name;
    let logo_url = request.logo_url;

    let organization: Organization = query(
        r#"
        BEGIN TRANSACTION;

        LET $org = CREATE ONLY organization SET
            name = $name,
            logo_url = $logo_url,
            founder = type::thing('user', $user_id)
            ;

        RETURN $org;

        COMMIT TRANSACTION;
        "#,
    )
    .bind("name", &name)
    .bind("logo_url", &logo_url)
    .bind("user_id", user_id)
    .execute()
    .await
    .error_with_slug("slug")?
    .parse::<OrganizationRecord>(0)
    .error_with_slug("slug")?
    .into();

    wasmcloud_utils::skir_subjects::user_organizations(user_id)
        .publish(WatchUserOrganizationsResponse::Add(Box::new(
            organization.clone(),
        )))
        .await?;

    Ok(CreateOrganizationResponse::Success(organization.into()))
}
