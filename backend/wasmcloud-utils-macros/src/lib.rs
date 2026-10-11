//! Compile time helpers used by the handwritten Typewriter backend components.
//!
//! The macros keep three boundaries consistent: SurrealDB query literals are validated before
//! compilation, broker subjects are routed to typed handlers, and generated SKIR response enums
//! are constructed with the payload shape required by the wire contract. The runtime behavior
//! lives in `wasmcloud_utils`; this crate only parses declarations and emits calls into it.

use proc_macro::TokenStream;
use syn::parse_macro_input;

mod database_query;
mod paths;
mod skir_domain_result;
mod skir_response;
mod skir_transaction_outcome;
mod skir_variant;

/// Implement the `wasmcloud_utils::SkirResponse` contract for a generated response enum.
///
/// The declaration names successful variants and domain error variants. It generates wire
/// serialization, outcome classification, stable kebab case slugs, caller facing messages, the
/// generic internal error, and default construction for payloadless domain errors.
#[proc_macro]
pub fn skir_response(input: TokenStream) -> TokenStream {
    let input = parse_macro_input!(input as skir_response::SkirResponseInput);
    skir_response::expand(input).into()
}

/// Create a read query from a compile time string literal.
///
/// The literal must contain at least one statement and no mutation statement. The generated
/// value retains the final result position for typed decoding at the runtime database boundary.
#[proc_macro]
pub fn read_query(input: TokenStream) -> TokenStream {
    let input = parse_macro_input!(input as database_query::ReadQueryInput);
    match database_query::expand_read(input) {
        Ok(tokens) => tokens.into(),
        Err(error) => error.to_compile_error().into(),
    }
}

/// Create a typed transaction query after validating its statement structure.
///
/// The literal must begin with `BEGIN TRANSACTION`, end with `COMMIT TRANSACTION`, and place its
/// top level `RETURN` immediately before the commit. The generated runtime query applies bounded
/// conflict retry behavior and decodes the selected return value as the declared outcome type.
#[proc_macro]
pub fn transaction_query(input: TokenStream) -> TokenStream {
    let input = parse_macro_input!(input as database_query::TransactionQueryInput);
    match database_query::expand_transaction(input) {
        Ok(tokens) => tokens.into(),
        Err(error) => error.to_compile_error().into(),
    }
}

/// Create a typed transaction query from a path relative to the caller's manifest.
///
/// The file is read and validated during compilation, then embedded into the generated query so
/// runtime execution does not depend on the source file being present.
#[proc_macro]
pub fn transaction_query_file(input: TokenStream) -> TokenStream {
    let input = parse_macro_input!(input as database_query::TransactionQueryFileInput);
    match database_query::expand_transaction_file(input) {
        Ok(tokens) => tokens.into(),
        Err(error) => error.to_compile_error().into(),
    }
}

/// Return the compile time result index of the transaction's top level outcome statement.
///
/// This is useful when a caller must share the index with another query construction path. The
/// same transaction ordering rules as [`transaction_query`] apply.
#[proc_macro]
pub fn transaction_outcome_index(input: TokenStream) -> TokenStream {
    let query = parse_macro_input!(input as syn::LitStr);
    match database_query::expand_transaction_outcome_index(query) {
        Ok(tokens) => tokens.into(),
        Err(error) => error.to_compile_error().into(),
    }
}

/// Return the transaction outcome index for a manifest relative query file.
///
/// The file is validated during compilation and embedded in the expansion to keep the path a
/// compile time dependency.
#[proc_macro]
pub fn transaction_outcome_index_file(input: TokenStream) -> TokenStream {
    let path = parse_macro_input!(input as syn::LitStr);
    match database_query::expand_transaction_outcome_index_file(path) {
        Ok(tokens) => tokens.into(),
        Err(error) => error.to_compile_error().into(),
    }
}

/// Convert a domain slug result into either a value or an early typed SKIR response.
///
/// Known payloadless variants use the response registry. The optional mapping entries construct
/// payloadful variants from values already available at the call site. A successful value keeps
/// the surrounding function running; a response is returned with `Ok`.
#[proc_macro]
pub fn skir_domain_result(input: TokenStream) -> TokenStream {
    let input = parse_macro_input!(input as skir_domain_result::SkirDomainResultInput);

    match skir_domain_result::expand(input) {
        Ok(tokens) => tokens.into(),
        Err(error) => error.to_compile_error().into(),
    }
}

/// Map a transaction outcome enum into a success value or an early typed SKIR error response.
///
/// The success pattern extracts the value that continues the enclosing function. Each error
/// pattern names the generated response variant and supplies its payload fields. The expansion
/// assumes the enclosing function returns `Result<Response, otel_wasi::Error>`.
#[proc_macro]
pub fn skir_transaction_outcome(input: TokenStream) -> TokenStream {
    let input = parse_macro_input!(input as skir_transaction_outcome::SkirTransactionOutcomeInput);

    match skir_transaction_outcome::expand(input) {
        Ok(tokens) => tokens.into(),
        Err(error) => error.to_compile_error().into(),
    }
}

/// Construct a generated SKIR response variant and its generated payload struct.
///
/// Fields use shorthand names by default or an explicit expression after `:`. The payload's
/// unknown field storage is initialized empty because this macro constructs a new value rather
/// than preserving decoded forward compatible fields.
#[proc_macro]
pub fn skir_variant(input: TokenStream) -> TokenStream {
    let input = parse_macro_input!(input as skir_variant::SkirVariantInput);

    match skir_variant::expand(input) {
        Ok(tokens) => tokens.into(),
        Err(error) => error.to_compile_error().into(),
    }
}
