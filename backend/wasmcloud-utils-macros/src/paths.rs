use syn::{Ident, Path};

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

/// Compute the inner payload type for a skir response variant.
///
/// Given a response type like `CancelJoinRequestResponse` and a variant like `Success`,
/// returns `CancelJoinRequestResponse_Success`.
///
/// The `macro_name` parameter is used in error messages.
pub(crate) fn payload_ty(
    response_ty: &Path,
    variant_ident: &Ident,
    macro_name: &str,
) -> syn::Result<Path> {
    let mut payload_ty = response_ty.clone();
    let Some(last_segment) = payload_ty.segments.last_mut() else {
        return Err(syn::Error::new_spanned(
            response_ty,
            "expected response type path",
        ));
    };

    if !last_segment.arguments.is_empty() {
        return Err(syn::Error::new_spanned(
            &last_segment.arguments,
            format!("{macro_name} response type must not have generic arguments"),
        ));
    }

    let payload_ident = Ident::new(
        &format!("{}_{}", last_segment.ident, variant_ident),
        last_segment.ident.span(),
    );
    last_segment.ident = payload_ident;

    Ok(payload_ty)
}

fn is_internal_call() -> bool {
    std::env::var("CARGO_PKG_NAME").is_ok_and(|name| name == "wasmcloud-utils")
}
