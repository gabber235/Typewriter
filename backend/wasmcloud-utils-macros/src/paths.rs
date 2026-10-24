//! Resolve paths used by macro expansions.
//!
//! Components invoke these macros through `wasmcloud_utils`, while the utility crate also uses
//! them internally in its own tests and helpers. Expansions therefore choose the caller visible
//! crate path or the current crate path before emitting runtime references.

use syn::{Ident, Path};

pub(crate) fn utils_path() -> syn::Path {
    if is_internal_call() {
        return syn::parse_quote! { crate };
    }

    syn::parse_quote! { ::wasmcloud_utils }
}

/// Compute the generated payload type for a SKIR response variant.
///
/// Given `CancelJoinRequestResponse` and `Success`, this returns
/// `CancelJoinRequestResponse_Success`. Generic response paths are rejected because the generated
/// payload naming convention applies to the final type identifier, not to type arguments.
///
/// The `macro_name` parameter identifies the originating macro in diagnostics.
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
