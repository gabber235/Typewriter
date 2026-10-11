//! Registry of the typed SKIR responses used by backend components.
//!
//! Each declaration binds a generated response enum to its successful variants and
//! known domain errors. The dispatch macro uses this registry through the `SkirResponse`
//! contract, so every handler can return a typed reply, including the generated
//! `InternalError` fallback.

use crate::skir::base::access::v1::sentinel::*;
use crate::skir::base::organization::v1::join_codes::*;
use crate::skir::base::organization::v1::join_request::*;
use crate::skir::base::organization::v1::member::*;
use crate::skir::base::organization::v1::organization::*;
use crate::skir::base::organization::v1::user::*;
use crate::skir::base::service::v1::identity::*;
use crate::skir::base::service::v1::organization::*;
use crate::skir::base::service::v1::registration::*;
use crate::skir::base::service::v1::status::*;
use crate::skir::base::service::v1::topology::*;
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
            RoleUnknownPropertyError => "Unknown role property",
            RoleTypeInvalidError => "Invalid role type",
            RoleVersionInvalidError => "Invalid role version",
            CustomRoleNameRequiredError => "Custom role name required",
            CustomRoleNameInvalidError => "Invalid custom role name",
            BuiltinRoleNameForbiddenError => "Built-in role name forbidden",
            IdentityProviderUnavailableError => "Identity provider unavailable",
        }
    }
}

wasmcloud_utils_macros::skir_response! {
    QueryServiceBindingResponse {
        success: Binding,
        errors {
            ServiceNotFoundError => "Service not found",
        }
    }
}

wasmcloud_utils_macros::skir_response! {
    EnsureRegistrationLeaseResponse {
        success: [Issued, AlreadyBound],
        errors {
            ServiceNotFoundError => "Service not found",
        }
    }
}

wasmcloud_utils_macros::skir_response! {
    BindServiceResponse {
        success: Success,
        errors {
            InvalidRegistrationTokenError => "Invalid or expired registration token",
            OrganizationNotFoundError => "Organization not found",
        }
    }
}

wasmcloud_utils_macros::skir_response! {
    UnbindServiceResponse {
        success: Success,
        errors {
            ServiceNotFoundError => "Service not found in organization",
        }
    }
}

wasmcloud_utils_macros::skir_response! {
    WatchOrganizationServicesResponse {
        success: List,
        errors {}
    }
}

wasmcloud_utils_macros::skir_response! {
    UpdateOrganizationServiceResponse {
        success: Success,
        errors {
            InvalidRecordIdError,
            ConflictError => "Service changed elsewhere",
            ServiceNotFoundError => "Service not found in organization",
            ValidationError => "Service update is invalid",
        }
    }
}

wasmcloud_utils_macros::skir_response! {
    RegisterServiceHostResponse {
        success: Success,
        errors {}
    }
}

wasmcloud_utils_macros::skir_response! {
    ConfigureServiceHostResponse {
        success: Success,
        errors {
            InvalidRecordIdError,
            ConflictError => "Host changed elsewhere",
            InvalidConfigurationError => "Host configuration is invalid",
            IncompatibleEngineError => "Engine target is incompatible",
            RealmNotFoundError => "Realm not found",
        }
    }
}

wasmcloud_utils_macros::skir_response! {
    WatchOrganizationTopologyResponse {
        success: List,
        errors {}
    }
}

wasmcloud_utils_macros::skir_response! {
    WatchHostExecutionResponse {
        success: Desired,
        errors {}
    }
}

wasmcloud_utils_macros::skir_response! {
    ReportHostExecutionResponse {
        success: Success,
        errors {
            StaleRevisionError => "Host topology revision is stale",
        }
    }
}

wasmcloud_utils_macros::skir_response! {
    GetServiceMessagingScopeResponse {
        success: Found,
        errors {
            NotFound => "Service messaging scope not found",
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
        errors {
            InvalidRecordIdError,
        }
    }
}

wasmcloud_utils_macros::skir_response! {
    WatchUserOrganizationsResponse {
        success: [Snapshot, Changed],
        errors {}
    }
}

wasmcloud_utils_macros::skir_response! {
    WatchUserJoinRequestsResponse {
        success: [Snapshot, Changed],
        errors {}
    }
}

wasmcloud_utils_macros::skir_response! {
    SubmitUserJoinRequestResponse {
        success: [RequestMade, AutoAccepted],
        errors {
            InvalidRecordIdError,
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
            InvalidRecordIdError,
            RequestNotFoundError(e) => format!("Join request not found: '{}'", e.request_id),
        }
    }
}

wasmcloud_utils_macros::skir_response! {
    WatchOrganizationJoinCodesResponse {
        success: [Snapshot, Changed],
        errors {}
    }
}

wasmcloud_utils_macros::skir_response! {
    GenerateOrganizationJoinCodeResponse {
        success: Success,
        errors {
            InvalidRecordIdError,
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
            InvalidRecordIdError,
            CodeNotFoundError(e) => format!("Join code not found: '{}'", e.code_id),
        }
    }
}

wasmcloud_utils_macros::skir_response! {
    WatchOrganizationJoinRequestsResponse {
        success: [Snapshot, Changed],
        errors {}
    }
}

wasmcloud_utils_macros::skir_response! {
    ApproveOrganizationJoinRequestsResponse {
        success: Success,
        errors {
            InvalidRecordIdError,
            InvalidSelectionError => "Selection must contain distinct targets",
            RequestNotFoundError(e) => format!("Join requests not found: {:?}", e.request_ids),
            RolesNotFoundError(e) => format!("Roles not found: {:?}", e.role_ids),
            RolesNotAssignableError(e) => format!("Roles not assignable: {:?}", e.role_ids),
            RolesRequiredError => "At least one role is required",
            UserAlreadyMemberError(e) => format!("Users are already members: {:?}", e.user_ids),
        }
    }
}

wasmcloud_utils_macros::skir_response! {
    DeclineOrganizationJoinRequestResponse {
        success: Success,
        errors {
            InvalidRecordIdError,
            RequestNotFoundError(e) => format!("Join request not found: '{}'", e.request_id),
        }
    }
}

wasmcloud_utils_macros::skir_response! {
    WatchOrganizationMembersResponse {
        success: Snapshot,
        errors {}
    }
}

wasmcloud_utils_macros::skir_response! {
    UpdateOrganizationMemberRolesResponse {
        success: Success,
        errors {
            InvalidRecordIdError,
            InvalidSelectionError => "Selection must contain distinct targets",
            UserNotFoundError(e) => format!("Users not found: {:?}", e.user_ids),
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
            InvalidRecordIdError,
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
