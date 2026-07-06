use std::collections::HashMap;

use wasmcloud_utils::{
    skir::base::organization::v1::join_request::{
        CancelJoinRequestResponse, RequestToJoinResponse,
    },
    wasmcloud::messaging::types::BrokerMessage,
};

pub fn handle_list(
    _msg: BrokerMessage,
    params: HashMap<String, String>,
) -> Result<RequestToJoinResponse, RequestToJoinResponse> {
    let _user_id = wasmcloud_utils::extract_param!(params, user_id)
        .map_err(|_| RequestToJoinResponse::Unknown(None))?;

    // TODO: Implement join request listing
    Err(RequestToJoinResponse::Unknown(None))
}

pub fn handle_request(
    _msg: BrokerMessage,
    params: HashMap<String, String>,
) -> Result<RequestToJoinResponse, RequestToJoinResponse> {
    let _user_id = wasmcloud_utils::extract_param!(params, user_id)
        .map_err(|_| RequestToJoinResponse::Unknown(None))?;

    // TODO: Implement join request
    Err(RequestToJoinResponse::Unknown(None))
}

pub fn handle_cancel(
    _msg: BrokerMessage,
    params: HashMap<String, String>,
) -> Result<CancelJoinRequestResponse, CancelJoinRequestResponse> {
    let _user_id = wasmcloud_utils::extract_param!(params, user_id)
        .map_err(|_| CancelJoinRequestResponse::Unknown(None))?;

    // TODO: Implement join request cancellation
    Err(CancelJoinRequestResponse::Unknown(None))
}
