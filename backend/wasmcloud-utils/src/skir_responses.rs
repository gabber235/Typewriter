// Central declarations for generated skir response enums.
// Each declaration teaches wasmcloud-utils about success and domain-error
// variants so dispatch_actions! can always reply with a typed response.
//
// The conventional `InternalError` variant is generated automatically by
// skir_response! and must exist on every response enum declared here.

use crate::skir::base::access::v1::sentinel::{
    GetSentinelCredentialsResponse, GetSentinelCredentialsResponse_InternalError,
};
use crate::skir::base::organization::v1::join_request::{
    CancelJoinRequestResponse, CancelJoinRequestResponse_InternalError, RequestToJoinResponse,
    RequestToJoinResponse_InternalError, WatchUserJoinRequestsResponse,
    WatchUserJoinRequestsResponse_InternalError,
};
use crate::skir::base::organization::v1::organization::{
    CreateOrganizationResponse, CreateOrganizationResponse_InternalError,
    DeleteOrganizationResponse, DeleteOrganizationResponse_InternalError,
    WatchUserOrganizationsResponse, WatchUserOrganizationsResponse_InternalError,
};
use crate::skir::base::service::v1::status::{
    GetServiceStatusResponse, GetServiceStatusResponse_InternalError,
};

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
    WatchUserOrganizationsResponse {
        success: [List, Add, Remove],
        errors {}
    }
}

wasmcloud_utils_macros::skir_response! {
    WatchUserJoinRequestsResponse {
        success: [List, Add, Remove],
        errors {}
    }
}

wasmcloud_utils_macros::skir_response! {
    RequestToJoinResponse {
        success: [RequestMade, AutoAccepted],
        errors {
            CodeNotFoundError(e) => format!("Could not find code: '{}'", e.code.key.to_string()),
            AlreadyMemberError => "User is already a member of this organization",
            NoAssignableRolesError => "No assignable roles are available for this organization",
            MaxPendingRequestsError => "User already has the maximum number of pending join requests",
            PendingRequestExistsError => "User already has a pending join request for this organization",
        }
    }
}

wasmcloud_utils_macros::skir_response! {
    CancelJoinRequestResponse {
        success: Success,
        errors {
            RequestNotFoundError(e) => format!("Join request not found: '{}'", e.request_id),
        }
    }
}
