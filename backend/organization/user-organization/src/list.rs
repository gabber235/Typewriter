use std::collections::HashMap;

use wasmcloud_utils::{
    skir::base::organization::v1::organization::CreateOrganizationResponse,
    wasmcloud::messaging::types::BrokerMessage,
};

pub fn handle_list(
    _msg: BrokerMessage,
    params: HashMap<String, String>,
) -> Result<CreateOrganizationResponse, CreateOrganizationResponse> {
    let _user_id = wasmcloud_utils::extract_param!(params, user_id)
        .map_err(|_| CreateOrganizationResponse::Unknown(None))?;

    // TODO: Implement organization listing
    Err(CreateOrganizationResponse::Unknown(None))
}
