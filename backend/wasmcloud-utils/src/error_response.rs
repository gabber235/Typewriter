/// Macro to create a protobuf error response with minimal boilerplate.
///
/// This macro generates the verbose error response pattern commonly used in the Typewriter API.
/// It supports two main use cases:
///
/// 1. **Creating an error response struct** (for inline use or custom handling):
///    ```rust,ignore
///    let response = error_response!(
///        typewriter::api::v1::SomeResponse,
///        500,
///        "Error message"
///    );
///    ```
///
/// 2. **Creating an error response with custom details**:
///    ```rust,ignore
///    let response = error_response!(
///        typewriter::api::v1::SomeResponse,
///        400,
///        "Validation failed",
///        vec![detail1, detail2]
///    );
///    ```
///
/// The macro automatically:
/// - Derives the `Result::Error` variant path from the response type
/// - Creates the `typewriter::models::v1::Error` struct
/// - Wraps it in `Some(...)` for the result field
///
/// # Type Requirements
///
/// The response type must follow the convention where:
/// - `ResponseType` has a `result` field of type `Option<response_type::Result>`
/// - `response_type::Result` has an `Error` variant that takes `typewriter::models::v1::Error`
///
/// # Examples
///
/// ```rust,ignore
/// use wasmcloud_utils::error_response;
///
/// // Simple 500 error
/// let response = error_response!(
///     typewriter::api::v1::ListMembersResponse,
///     500,
///     "Internal server error"
/// );
///
/// // 403 error with dynamic message
/// let msg = format!("Access denied for user {}", user_id);
/// let response = error_response!(
///     typewriter::api::v1::ApproveJoinRequestResponse,
///     403,
///     msg
///    );
///
/// // Error with details
/// let response = error_response!(
///     typewriter::api::v1::SomeResponse,
///     400,
///     "Validation failed",
///     vec!["field1 is required".to_string()]
/// );
/// ```
#[macro_export]
macro_rules! error_response {
    // With details
    ($response_type:ty, $code:expr, $message:expr, $details:expr) => {{
        // Convert the response type path to the result error variant path
        // e.g., typewriter::api::v1::SomeResponse -> typewriter::api::v1::some_response::Result::Error
        <$response_type> {
            result: Some($crate::error_response!(@error_variant $response_type, $code, $message, $details)),
        }
    }};

    // Without details (empty vec)
    ($response_type:ty, $code:expr, $message:expr) => {
        $crate::error_response!($response_type, $code, $message, vec![])
    };

    // Internal: create the error variant - this requires the caller to use the full path
    (@error_variant $response_type:ty, $code:expr, $message:expr, $details:expr) => {
        paste::paste! {
            [<$response_type:snake _result>]::Error(
                typewriter::models::v1::Error {
                    code: $code,
                    message: $message.into(),
                    details: $details,
                }
            )
        }
    };
}

/// Macro to create an internal error function that returns encoded protobuf bytes.
///
/// This is a convenience macro for defining the common `internal_error_*` functions
/// that return a `Vec<u8>` containing an encoded error response.
///
/// # Usage
///
/// ```rust,ignore
/// use wasmcloud_utils::internal_error_fn;
///
/// // Define a simple internal error function
/// internal_error_fn!(
///     internal_error_list,                           // function name
///     typewriter::api::v1::ListMembersResponse,      // response type
///     list_members_response,                         // module name for Result enum
///     "Internal Server Error when listing members"   // error message
/// );
///
/// // This generates:
/// // pub fn internal_error_list() -> Vec<u8> {
/// //     typewriter::api::v1::ListMembersResponse {
/// //         result: Some(
/// //             typewriter::api::v1::list_members_response::Result::Error(
/// //                 typewriter::models::v1::Error {
/// //                     code: 500,
/// //                     message: "Internal Server Error when listing members".to_string(),
/// //                     details: vec![],
/// //                 },
/// //             ),
/// //         ),
/// //     }
/// //     .encode_to_vec()
/// // }
/// ```
#[macro_export]
macro_rules! internal_error_fn {
    ($fn_name:ident, $response_type:path, $result_module:ident, $message:expr) => {
        pub fn $fn_name() -> Vec<u8> {
            $crate::error_response_bytes!($response_type, $result_module, 500, $message)
        }
    };
}

/// Macro to create an error response and encode it to bytes in one step.
///
/// This combines error response creation with protobuf encoding, useful for
/// both `internal_error_*` functions and inline error returns.
///
/// # Usage
///
/// ```rust,ignore
/// use wasmcloud_utils::error_response_bytes;
///
/// // In a handler, return encoded error bytes directly
/// let error_bytes = error_response_bytes!(
///     typewriter::api::v1::ApproveJoinRequestResponse,
///     approve_join_request_response,
///     403,
///     "Permission denied"
/// );
/// return reply(msg, error_bytes);
/// ```
#[macro_export]
macro_rules! error_response_bytes {
    ($response_type:path, $result_module:ident, $code:expr, $message:expr) => {{
        use prost::Message;
        $response_type {
            result: Some(typewriter::api::v1::$result_module::Result::Error(
                typewriter::models::v1::Error {
                    code: $code,
                    message: $message.into(),
                    details: vec![],
                },
            )),
        }
        .encode_to_vec()
    }};

    ($response_type:path, $result_module:ident, $code:expr, $message:expr, $details:expr) => {{
        use prost::Message;
        $response_type {
            result: Some(typewriter::api::v1::$result_module::Result::Error(
                typewriter::models::v1::Error {
                    code: $code,
                    message: $message.into(),
                    details: $details,
                },
            )),
        }
        .encode_to_vec()
    }};
}

/// Macro to create an error response struct (not encoded).
///
/// Use this when you need the response struct itself rather than encoded bytes,
/// for example when you want to return early with a reply.
///
/// # Usage
///
/// ```rust,ignore
/// use wasmcloud_utils::error_response_struct;
///
/// let response = error_response_struct!(
///     typewriter::api::v1::ApproveJoinRequestResponse,
///     approve_join_request_response,
///     403,
///     error_message
/// );
/// return reply(msg, response.encode_to_vec());
/// ```
#[macro_export]
macro_rules! error_response_struct {
    ($response_type:path, $result_module:ident, $code:expr, $message:expr) => {{
        $response_type {
            result: Some(typewriter::api::v1::$result_module::Result::Error(
                typewriter::models::v1::Error {
                    code: $code,
                    message: $message.into(),
                    details: vec![],
                },
            )),
        }
    }};

    ($response_type:path, $result_module:ident, $code:expr, $message:expr, $details:expr) => {{
        $response_type {
            result: Some(typewriter::api::v1::$result_module::Result::Error(
                typewriter::models::v1::Error {
                    code: $code,
                    message: $message.into(),
                    details: $details,
                },
            )),
        }
    }};
}
