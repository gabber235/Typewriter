// Central declarations for generated skir response enums.
// Each declaration teaches wasmcloud-utils about the success and error variants
// so that dispatch_actions! can always reply with a typed response.

use crate::skir::base::access::v1::sentinel::GetSentinelCredentialsResponse;
use crate::skir::base::organization::v1::join_request::{
    CancelJoinRequestResponse, RequestToJoinResponse,
};
use crate::skir::base::organization::v1::organization::{
    CreateOrganizationResponse, DeleteOrganizationResponse,
};
use crate::skir::base::service::v1::status::GetServiceStatusResponse;

wasmcloud_utils_macros::skir_response! {
    GetSentinelCredentialsResponse {
        success: Success,
        errors {
            ConfigurationError => "Sentinel credentials are not configured correctly",
            InvalidCredentials => "Sentinel credentials are invalid",
        }
    }
}

wasmcloud_utils_macros::skir_response! {
    GetServiceStatusResponse {
        success: Status,
        errors {
            ServiceNotFound => "Service not found",
            InternalError => "Internal error while fetching service status",
        }
    }
}

wasmcloud_utils_macros::skir_response! {
    CreateOrganizationResponse {
        success: Success,
        errors {}
    }
}

wasmcloud_utils_macros::skir_response! {
    DeleteOrganizationResponse {
        success: Success,
        errors {}
    }
}

wasmcloud_utils_macros::skir_response! {
    RequestToJoinResponse {
        success: Success,
        errors {}
    }
}

wasmcloud_utils_macros::skir_response! {
    CancelJoinRequestResponse {
        success: Success,
        errors {}
    }
}
