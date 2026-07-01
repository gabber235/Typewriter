mod bindings {
    wit_bindgen::generate!({
        pub_export_macro: true,
        generate_all,
    });
}

mod error_response;

#[macro_export]
macro_rules! export {
    ($ty:ident) => {
        ::wasmcloud_utils::__export_wasmcloud_messaging_handler_0_2_0_cabi!($ty with_types_in ::wasmcloud_utils::wasmcloud::messaging::handler);
    };
}

pub mod wasmcloud;

pub mod skirout;
pub use crate::skirout as skir;
pub use skir_client;

/// Macro to simplify action dispatching by automatically generating the handler function type signatures.
///
/// Each action can optionally have an error handler that generates error response bytes when that action fails.
/// The error handler will be called and its result sent as a reply to the original message.
/// Use `=> handler => error_handler` syntax to specify an error handler.
///
/// # Example (single template - backwards compatible)
/// ```rust,no_run
/// use wasmcloud_utils::dispatch_actions;
/// use wasmcloud_utils::wasmcloud::messaging::types::BrokerMessage;
/// use std::collections::HashMap;
///
/// fn handle_list(msg: BrokerMessage, params: HashMap<String, String>) -> Result<(), String> {
///     Ok(())
/// }
///
/// fn handle_create(msg: BrokerMessage, params: HashMap<String, String>) -> Result<(), String> {
///     Ok(())
/// }
///
/// fn handle_create_error() -> Vec<u8> {
///     vec![1, 2, 3] // protobuf encoded error response
/// }
///
/// fn handle_message(msg: BrokerMessage) -> Result<(), String> {
///     dispatch_actions!(
///         msg,
///         "user.<user_id>.organization.<action>",
///         "list" => handle_list,
///         "create" => handle_create => handle_create_error,
///     )
/// }
/// ```
///
/// # Example (named templates)
/// ```rust,no_run
/// use wasmcloud_utils::dispatch_actions;
/// use wasmcloud_utils::wasmcloud::messaging::types::BrokerMessage;
/// use std::collections::HashMap;
///
/// fn handle_status(msg: BrokerMessage, params: HashMap<String, String>) -> Result<(), String> {
///     Ok(())
/// }
///
/// fn handle_bind(msg: BrokerMessage, params: HashMap<String, String>) -> Result<(), String> {
///     Ok(())
/// }
///
/// fn handle_message(msg: BrokerMessage) -> Result<(), String> {
///     dispatch_actions!(
///         msg,
///         services: "typewriter.in.service.<service_id>",
///         user_services: "typewriter.in.user.<user_id>.organization.<org_id>.services";
///         "{services}.status" => handle_status,
///         "{user_services}.bind" => handle_bind,
///     )
/// }
/// ```
#[macro_export]
macro_rules! dispatch_actions {
    // New syntax with named templates: dispatch_actions!(msg, name: "template", ...; "pattern" => handler, ...)
    // Note the semicolon separator between templates and actions
    ($msg:expr, $($name:ident : $template:expr),+ ; $($rest:tt)+) => {{
        let templates: &[(&str, &str)] = &[
            $((stringify!($name), $template)),+
        ];

        $crate::wasmcloud::messaging::dispatch_action_with_templates(
            $msg,
            templates,
            &$crate::dispatch_actions!(@collect [] $($rest)+),
        )
    }};

    // Original syntax (backwards compatible): dispatch_actions!(msg, "template.<action>", "action" => handler, ...)
    ($msg:expr, $template:expr, $($rest:tt)+) => {{
        $crate::wasmcloud::messaging::dispatch_action(
            $msg,
            $template,
            &$crate::dispatch_actions!(@collect [] $($rest)+),
        )
    }};

    (@collect [$($acc:tt)*] $action_name:expr => $handler:expr => $error_handler:expr, $($rest:tt)+) => {
        $crate::dispatch_actions!(@collect [$($acc)* (
            $action_name,
            $handler as fn($crate::wasmcloud::messaging::types::BrokerMessage, ::std::collections::HashMap<String, String>) -> Result<(), String>,
            Some($error_handler as fn() -> Vec<u8>),
        ),] $($rest)+)
    };

    (@collect [$($acc:tt)*] $action_name:expr => $handler:expr, $($rest:tt)+) => {
        $crate::dispatch_actions!(@collect [$($acc)* (
            $action_name,
            $handler as fn($crate::wasmcloud::messaging::types::BrokerMessage, ::std::collections::HashMap<String, String>) -> Result<(), String>,
            None,
        ),] $($rest)+)
    };

    (@collect [$($acc:tt)*] $action_name:expr => $handler:expr => $error_handler:expr $(,)?) => {
        [$($acc)* (
            $action_name,
            $handler as fn($crate::wasmcloud::messaging::types::BrokerMessage, ::std::collections::HashMap<String, String>) -> Result<(), String>,
            Some($error_handler as fn() -> Vec<u8>),
        )]
    };

    (@collect [$($acc:tt)*] $action_name:expr => $handler:expr $(,)?) => {
        [$($acc)* (
            $action_name,
            $handler as fn($crate::wasmcloud::messaging::types::BrokerMessage, ::std::collections::HashMap<String, String>) -> Result<(), String>,
            None,
        )]
    };
}

/// Macro to extract a single parameter from the subject params HashMap.
///
/// Returns a reference to the parameter value as a string slice.
/// The macro handles error checking internally and will return early if the parameter is not found.
///
/// # Example
/// ```rust,no_run
/// use wasmcloud_utils::extract_param;
/// use std::collections::HashMap;
///
/// let mut params = HashMap::new();
/// params.insert("user_id".to_string(), "123".to_string());
///
/// let user_id = extract_param!(params, user_id);
/// ```
#[macro_export]
macro_rules! extract_param {
    ($params:expr, $param_name:ident) => {
        $params
            .get(stringify!($param_name))
            .map(|s| s.as_str())
            .ok_or_else(|| format!("failed to parse {} from subject", stringify!($param_name)))?
    };
}

/// Macro to extract multiple parameters from the subject params HashMap at once.
///
/// Returns a tuple of references to the parameter values as string slices,
/// in the same order as specified.
/// The macro handles error checking internally and will return early if any parameter is not found.
///
/// # Example
/// ```rust,no_run
/// use wasmcloud_utils::extract_params;
/// use std::collections::HashMap;
///
/// let mut params = HashMap::new();
/// params.insert("user_id".to_string(), "123".to_string());
/// params.insert("org_id".to_string(), "456".to_string());
///
/// let (user_id, org_id) = extract_params!(params, user_id, org_id);
/// ```
#[macro_export]
macro_rules! extract_params {
    ($params:expr, $($param_name:ident),+ $(,)?) => {
        ($(
            $params
                .get(stringify!($param_name))
                .map(|s| s.as_str())
                .ok_or_else(|| format!("failed to parse {} from subject", stringify!($param_name)))?
        ),+)
    };
}
