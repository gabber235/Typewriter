use std::collections::HashMap;

use wasmcloud_utils::{
    decode_skir,
    skir::base::organization::v1::organization::{
        CreateOrganizationRequest, CreateOrganizationResponse,
    },
    wasmcloud::messaging::types::BrokerMessage,
};

pub fn handle_create(
    msg: BrokerMessage,
    params: HashMap<String, String>,
) -> Result<CreateOrganizationResponse, CreateOrganizationResponse> {
    let _user_id = wasmcloud_utils::extract_param!(params, user_id)
        .map_err(|_| CreateOrganizationResponse::Unknown(None))?;
    let _request = decode_skir!(CreateOrganizationRequest, &msg.body)
        .map_err(|_| CreateOrganizationResponse::Unknown(None))?;

    // TODO: Implement organization creation
    Err(CreateOrganizationResponse::Unknown(None))
}
