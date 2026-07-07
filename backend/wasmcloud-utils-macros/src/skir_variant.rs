use proc_macro2::TokenStream;
use quote::quote;
use syn::{
    Expr, Ident, Path, Token,
    braced,
    parse::{Parse, ParseStream},
};

pub(crate) struct SkirVariantInput {
    response_ty: Path,
    variant: Ident,
    fields: Vec<FieldEntry>,
}

struct FieldEntry {
    name: Ident,
    value: Expr,
}

impl Parse for SkirVariantInput {
    fn parse(input: ParseStream) -> syn::Result<Self> {
        let full_path: Path = input.parse()?;

        // Split off the last segment as the variant name.
        // e.g. `RequestToJoinResponse::CodeNotFoundError` →
        //   response_ty = `RequestToJoinResponse`, variant = `CodeNotFoundError`
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

        // Try to parse `: value` — if present, use explicit value; otherwise shorthand
        let value = if input.peek(Token![:]) {
            let _: Token![:] = input.parse()?;
            input.parse()?
        } else {
            Expr::Path(syn::ExprPath {
                attrs: Vec::new(),
                qself: None,
                path: name.clone().into(),
            })
        };

        Ok(Self { name, value })
    }
}

pub(crate) fn expand(input: SkirVariantInput) -> syn::Result<TokenStream> {
    let response_ty = &input.response_ty;
    let variant = &input.variant;

    let payload_ty = crate::paths::payload_ty(response_ty, variant, "skir_variant!")?;

    let field_names: Vec<_> = input.fields.iter().map(|f| &f.name).collect();
    let field_values: Vec<_> = input.fields.iter().map(|f| &f.value).collect();

    Ok(quote! {
        #response_ty::#variant(::std::boxed::Box::new(
            #payload_ty {
                #(#field_names: #field_values,)*
                _unrecognized: ::std::option::Option::None,
            },
        ))
    })
}
