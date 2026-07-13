// Central declarations for generated skir response enums.
// Each declaration teaches wasmcloud-utils about success and domain-error
// variants so dispatch_actions! can always reply with a typed response.
//
// The conventional `InternalError` variant is generated automatically by
// skir_response! and must exist on every response enum declared here.

use crate::skir::base::access::v1::sentinel::*;
use crate::skir::base::organization::v1::join_codes::*;
use crate::skir::base::organization::v1::join_request::*;
use crate::skir::base::organization::v1::member::*;
use crate::skir::base::organization::v1::organization::*;
use crate::skir::base::organization::v1::user::*;
use crate::skir::base::service::v1::identity::*;
use crate::skir::base::service::v1::status::*;
use crate::skirout::base::organization::v1::role::*;

wasmcloud_utils_macros::skir_response! {
    GetSentinelCredentialsResponse {
        success: Success,
        errors {}
    }
}

wasmcloud_utils_macros::skir_response! {
    IssueServiceIdentityResponse {
        success: Success,
        errors {
            MalformedRequestError => "Malformed request",
            UnknownRoleError => "Unknown role",
            RolesRequiredError => "Roles required",
            RoleUnknownPropertyError => "Unknown role property",
            RoleTypeInvalidError => "Invalid role type",
            RoleVersionBlankError => "Blank role version",
            RoleInvalidError => "Invalid role",
            CustomRoleNameRequiredError => "Custom role name required",
            CustomRoleNameInvalidError => "Invalid custom role name",
            BuiltinRoleNameForbiddenError => "Built-in role name forbidden",
            EngineRoleDuplicateError => "Duplicate engine role",
            RealmRoleDuplicateError => "Duplicate realm role",
            CustomRoleDuplicateError => "Duplicate custom role",
            IdentityProviderUnavailableError => "Identity provider unavailable",
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
    SubmitUserJoinRequestResponse {
        success: [RequestMade, AutoAccepted],
        errors {
            CodeNotFoundError(e) => format!("Could not find code: '{}'", e.code.key),
            AlreadyMemberError => "User is already a member of this organization",
            NoAssignableRolesError => "No assignable roles are available for this organization",
            MaxPendingRequestsError => "User already has the maximum number of pending join requests",
            PendingRequestExistsError => "User already has a pending join request for this organization",
        }
    }
}

wasmcloud_utils_macros::skir_response! {
    CancelUserJoinRequestResponse {
        success: Success,
        errors {
            RequestNotFoundError(e) => format!("Join request not found: '{}'", e.request_id),
        }
    }
}

wasmcloud_utils_macros::skir_response! {
    WatchOrganizationJoinCodesResponse {
        success: [List, Add, Remove],
        errors {}
    }
}

wasmcloud_utils_macros::skir_response! {
    GenerateOrganizationJoinCodeResponse {
        success: Success,
        errors {
            RolesNotFoundError(e) => format!("Roles not found: {:?}", e.role_ids),
            RolesNotAssignableError(e) => format!("Roles not assignable: {:?}", e.role_ids),
            InvalidExpirationError(e) => format!("Invalid expiration duration: {:?}", e.duration),
        }
    }
}

wasmcloud_utils_macros::skir_response! {
    RevokeOrganizationJoinCodeResponse {
        success: Success,
        errors {
            CodeNotFoundError(e) => format!("Join code not found: '{}'", e.code_id),
        }
    }
}

wasmcloud_utils_macros::skir_response! {
    WatchOrganizationJoinRequestsResponse {
        success: [List, Add, Remove],
        errors {}
    }
}

wasmcloud_utils_macros::skir_response! {
    ApproveOrganizationJoinRequestResponse {
        success: Success,
        errors {
            RequestNotFoundError(e) => format!("Join request not found: '{}'", e.request_id),
            RolesNotFoundError(e) => format!("Roles not found: {:?}", e.role_ids),
            RolesNotAssignableError(e) => format!("Roles not assignable: {:?}", e.role_ids),
            RolesRequiredError => "At least one role is required",
            UserAlreadyMemberError(e) => format!("User is already a member: '{}'", e.user_id),
        }
    }
}

wasmcloud_utils_macros::skir_response! {
    DeclineOrganizationJoinRequestResponse {
        success: Success,
        errors {
            RequestNotFoundError(e) => format!("Join request not found: '{}'", e.request_id),
        }
    }
}

wasmcloud_utils_macros::skir_response! {
    WatchOrganizationMembersResponse {
        success: [List, Add, Update, Remove],
        errors {}
    }
}

wasmcloud_utils_macros::skir_response! {
    UpdateOrganizationMemberRolesResponse {
        success: Success,
        errors {
            UserNotFoundError(e) => format!("User not found: '{}'", e.user_id),
            RolesNotFoundError(e) => format!("Roles not found: {:?}", e.role_ids),
            RolesNotAssignableError(e) => format!("Roles not assignable: {:?}", e.role_ids),
            RolesRequiredError => "At least one role is required",
            FounderRoleRequiredError => "Founder role is required",
        }
    }
}

wasmcloud_utils_macros::skir_response! {
    RemoveOrganizationMemberResponse {
        success: Success,
        errors {
            UserNotMemberError(e) => format!("User is not a member: '{}'", e.user_id),
            FounderCannotBeRemovedError(e) => format!("Founder cannot be removed: '{}'", e.user_id),
        }
    }
}

wasmcloud_utils_macros::skir_response! {
    WatchOrganizationRolesResponse {
        success: [List, Add, Update, Remove],
        errors {}
    }
}
