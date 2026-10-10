//! Shared runtime contracts for Typewriter wasmCloud components.
//!
//! This crate combines generated SKIR types with the boundaries that components use to
//! decode requests, classify and serialize responses, access SurrealDB values, and
//! publish broker messages. The public helpers preserve those contracts without making
//! individual components repeat transport or identifier conversion rules.

extern crate self as wasmcloud_utils;

mod bindings {
    wit_bindgen::generate!({
        pub_export_macro: true,
        generate_all,
    });
}

#[macro_export]
macro_rules! export {
    ($ty:ident) => {
        ::wasmcloud_utils::__export_wasmcloud_nats_core_handler_0_1_0_cabi!($ty with_types_in ::wasmcloud_utils::wasmcloud::messaging::core_handler);
    };
}

pub mod database;
pub mod http;
pub mod publication;
pub mod wasmcloud;

#[rustfmt::skip]
#[allow(clippy::redundant_closure)]
pub mod skirout;
pub use crate::skirout as skir;
pub use otel_wasi;
pub use skir_client;

// Proc macros are re exported here so component crates use one public contract surface.
pub use wasmcloud_utils_macros::{
    read_query, skir_domain_result, skir_response, skir_transaction_outcome, skir_variant,
    transaction_outcome_index, transaction_outcome_index_file, transaction_query,
    transaction_query_file,
};

// Response classification and conversion from database outcomes.
mod skir_response_trait;
pub use skir_response_trait::{
    SkirDomainResult, SkirDomainResultExt, SkirResponse, SkirResponseOutcome,
};

// Response enums registered for dispatch and typed messaging replies.
mod skir_responses;

pub mod skir_utils;

#[path = "transport_routes/skirout/mod.rs"]
pub mod transport_routes;

/// Validate that SKIR record IDs belong to the expected database table.
///
/// On mismatch, return the enclosing response's standardized `InvalidRecordIdError`
/// domain variant. The response enum must define that conventional variant.
///
/// # Example
/// ```rust,ignore
/// validate_record_ids!(UpdateOrganizationServiceResponse, request.service_id, "service");
/// ```
#[macro_export]
macro_rules! validate_record_ids {
    ($response:ident, $record_ids:expr, $expected_table:expr $(,)?) => {{
        let record_ids = &$record_ids;
        let expected_table = $expected_table;
        let given_tables =
            $crate::skir_utils::RecordIdTableInput::invalid_tables(record_ids, expected_table);
        if !given_tables.is_empty() {
            let error = $crate::skir::base::kernel::v1::errors::InvalidRecordIdError {
                expected_table: expected_table.to_owned(),
                given_tables,
                _unrecognized: None,
            };
            return Ok($response::InvalidRecordIdError(::std::boxed::Box::new(
                error,
            )));
        }
    }};
}

/// Decode a SKIR message while dropping fields unknown to this component.
///
/// Decoding failures are translated to `skir-decode-failed`. Dropping unknown
/// fields keeps older and newer contract versions interoperable at this boundary.
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
