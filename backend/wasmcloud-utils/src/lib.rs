mod bindings {
    wit_bindgen::generate!({
        pub_export_macro: true,
        generate_all,
    });
}

#[macro_export]
macro_rules! export {
    ($ty:ident) => {
        ::wasmcloud_utils::__export_wasmcloud_messaging_handler_0_2_0_cabi!($ty with_types_in ::wasmcloud_utils::wasmcloud::messaging::handler);
    };
}

pub mod wasmcloud;

pub mod skirout;
pub use crate::skirout as skir;
pub use otel_wasi;
pub use skir_client;

// Re-export proc macros
pub use wasmcloud_utils_macros::{dispatch_actions, skir_response};

// SkirResponse trait
mod skir_response_trait;
pub use skir_response_trait::SkirResponse;

// Central skir response declarations
mod skir_responses;

/// Macro to extract a single parameter from the subject params HashMap.
///
/// Returns a `Result<&str, otel_wasi::Error>` — the caller must handle the error,
/// typically by mapping it to a typed response variant.
///
/// # Example
/// ```rust,no_run
/// use wasmcloud_utils::extract_param;
/// use std::collections::HashMap;
///
/// # fn main() -> Result<(), otel_wasi::Error> {
/// let mut params = HashMap::new();
/// params.insert("user_id".to_string(), "123".to_string());
///
/// let user_id = extract_param!(params, user_id)?;
/// # Ok(())
/// # }
/// ```
#[macro_export]
macro_rules! extract_param {
    ($params:expr, $param_name:ident) => {
        $params
            .get(stringify!($param_name))
            .map(|s| s.as_str())
            .ok_or_else(|| {
                $crate::otel_wasi::Error::new(
                    "param-extract-failed",
                    format!("failed to parse {} from subject", stringify!($param_name)),
                )
            })
    };
}

/// Macro to extract multiple parameters from the subject params HashMap at once.
///
/// Returns a `Result<(&str, ...), otel_wasi::Error>` — the caller must handle the error.
///
/// # Example
/// ```rust,no_run
/// use wasmcloud_utils::extract_params;
/// use std::collections::HashMap;
///
/// # fn main() -> Result<(), otel_wasi::Error> {
/// let mut params = HashMap::new();
/// params.insert("user_id".to_string(), "123".to_string());
/// params.insert("org_id".to_string(), "456".to_string());
///
/// let (user_id, org_id) = extract_params!(params, user_id, org_id)?;
/// # Ok(())
/// # }
/// ```
#[macro_export]
macro_rules! extract_params {
    ($params:expr, $($param_name:ident),+ $(,)?) => {
        (|| -> Result<_, $crate::otel_wasi::Error> {
            Ok(($(
                $crate::extract_param!($params, $param_name)?
            ),+))
        })()
    };
}

/// Decode a skir message from bytes, dropping unrecognized fields.
///
/// Returns a `Result<T, otel_wasi::Error>` — the caller must handle the error.
///
/// # Example
/// ```rust,ignore
/// let request = decode_skir!(GetEntityPermissionRequest, &msg.body)?;
/// ```
#[macro_export]
macro_rules! decode_skir {
    ($ty:ty, $body:expr) => {
        <$ty>::serializer()
            .from_bytes($body, $crate::skir_client::UnrecognizedValues::Drop)
            .map_err(|e| $crate::otel_wasi::Error::new("skir-decode-failed", e))
    };
}
