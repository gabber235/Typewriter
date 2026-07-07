pub(crate) fn skir_response_trait_path() -> syn::Path {
    if is_internal_call() {
        return syn::parse_quote! { crate::SkirResponse };
    }

    syn::parse_quote! { ::wasmcloud_utils::SkirResponse }
}

pub(crate) fn utils_path() -> syn::Path {
    if is_internal_call() {
        return syn::parse_quote! { crate };
    }

    syn::parse_quote! { ::wasmcloud_utils }
}

fn is_internal_call() -> bool {
    std::env::var("CARGO_PKG_NAME").is_ok_and(|name| name == "wasmcloud-utils")
}
