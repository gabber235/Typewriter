use proc_macro::TokenStream;
use syn::parse_macro_input;

mod dispatch_actions;
mod paths;
mod skir_domain_result;
mod skir_response;

#[proc_macro]
pub fn skir_response(input: TokenStream) -> TokenStream {
    let input = parse_macro_input!(input as skir_response::SkirResponseInput);
    skir_response::expand(input).into()
}

#[proc_macro]
pub fn dispatch_actions(input: TokenStream) -> TokenStream {
    let input = parse_macro_input!(input as dispatch_actions::DispatchInput);

    match dispatch_actions::expand(input) {
        Ok(tokens) => tokens.into(),
        Err(error) => error.to_compile_error().into(),
    }
}

#[proc_macro]
pub fn skir_domain_result(input: TokenStream) -> TokenStream {
    let input = parse_macro_input!(input as skir_domain_result::SkirDomainResultInput);

    match skir_domain_result::expand(input) {
        Ok(tokens) => tokens.into(),
        Err(error) => error.to_compile_error().into(),
    }
}
