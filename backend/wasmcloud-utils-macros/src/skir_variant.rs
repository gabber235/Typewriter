//! Parse and expand construction of generated SKIR response variants.
//!
//! The generated response enum and its payload struct use a naming convention derived from the
//! response type and variant. This macro centralizes that convention and initializes the generated
//! unknown field storage for newly constructed values.

use proc_macro2::TokenStream;
use quote::quote;
use syn::{
    Expr, Ident, Path, Token, braced,
    parse::{Parse, ParseStream},
};

pub(crate) struct SkirVariantInput {
    response_ty: Path,
    variant: Ident,
    fields: Vec<FieldEntry>,
}

struct FieldEntry {
    name: Ident,
    /// `None` for the shorthand `name`, which takes the binding of that name.
    value: Option<Expr>,
}

impl Parse for SkirVariantInput {
    fn parse(input: ParseStream) -> syn::Result<Self> {
        let full_path: Path = input.parse()?;

        // The final path segment is the response variant. Generated payload types reuse the
        // response and variant names, so the preceding path remains the response type path.
        let mut segments: Vec<_> = full_path.segments.clone().into_iter().collect();
        let Some(variant_segment) = segments.pop() else {
            return Err(syn::Error::new_spanned(
                &full_path,
                "expected ResponseType::Variant",
            ));
        };

        if !variant_segment.arguments.is_empty() {
            return Err(syn::Error::new_spanned(
                &variant_segment.arguments,
                "variant must not have generic arguments",
            ));
        }

        let variant = variant_segment.ident;
        let response_ty = Path {
            leading_colon: full_path.leading_colon,
            segments: segments.into_iter().collect(),
        };

        let fields = if input.peek(syn::token::Brace) {
            let content;
            braced!(content in input);
            let mut fields = Vec::new();
            while !content.is_empty() {
                fields.push(content.parse()?);
                if content.peek(Token![,]) {
                    let _: Token![,] = content.parse()?;
                }
            }
            fields
        } else {
            Vec::new()
        };

        Ok(Self {
            response_ty,
            variant,
            fields,
        })
    }
}

impl Parse for FieldEntry {
    fn parse(input: ParseStream) -> syn::Result<Self> {
        let name: Ident = input.parse()?;

        // An omitted value is Rust struct literal shorthand, which the expansion keeps.
        let value = if input.peek(Token![:]) {
            let _: Token![:] = input.parse()?;
            Some(input.parse()?)
        } else {
            None
        };

        Ok(Self { name, value })
    }
}

/// Emit a boxed generated payload with no preserved unknown fields.
pub(crate) fn expand(input: SkirVariantInput) -> syn::Result<TokenStream> {
    let response_ty = &input.response_ty;
    let variant = &input.variant;

    let payload_ty = crate::paths::payload_ty(response_ty, variant, "skir_variant!")?;

    let fields = input.fields.iter().map(|field| {
        let name = &field.name;
        match &field.value {
            Some(value) => quote! { #name: #value },
            None => quote! { #name },
        }
    });

    Ok(quote! {
        #response_ty::#variant(::std::boxed::Box::new(
            #payload_ty {
                #(#fields,)*
                _unrecognized: ::std::option::Option::None,
            },
        ))
    })
}
