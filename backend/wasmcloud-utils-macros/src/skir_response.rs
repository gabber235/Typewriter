use convert_case::{Case, Casing};
use proc_macro2::TokenStream;
use quote::quote;
use std::collections::HashSet;
use syn::{
    Expr, Ident, Token, braced,
    parse::{Parse, ParseStream},
    token,
};

pub(crate) struct SkirResponseInput {
    ty: Ident,
    success: Vec<Ident>,
    errors: Vec<ErrorEntry>,
}

enum ErrorEntry {
    Custom {
        variant: Ident,
        binding: Option<Ident>,
        message: Expr,
    },
    StandardInvalidRecordId {
        variant: Ident,
    },
}
impl ErrorEntry {
    fn variant(&self) -> &Ident {
        match self {
            Self::Custom { variant, .. } | Self::StandardInvalidRecordId { variant } => variant,
        }
    }
}

impl Parse for SkirResponseInput {
    fn parse(input: ParseStream) -> syn::Result<Self> {
        let ty = input.parse()?;

        let content;
        braced!(content in input);

        let success = parse_success_variants(&content)?;
        let _: Token![,] = content.parse()?;
        let errors = parse_error_variants(&content, &success)?;

        Ok(Self {
            ty,
            success,
            errors,
        })
    }
}

pub(crate) fn expand(input: SkirResponseInput) -> TokenStream {
    let ty = &input.ty;
    let skir_response_path = crate::paths::skir_response_trait_path();
    let utils_path = crate::paths::utils_path();
    let outcome_arms = outcome_arms(&input, &utils_path);
    let slug_arms = slug_arms(&input);
    let message_arms = message_arms(&input);
    let domain_error_from_slug_arms = domain_error_from_slug_arms(&input);

    quote! {
        impl #skir_response_path for #ty {
            fn to_skir_bytes(&self) -> Vec<u8> {
                #ty::serializer().to_bytes(self)
            }

            fn outcome(&self) -> #utils_path::SkirResponseOutcome {
                match self {
                    #(#outcome_arms)*
                }
            }

            fn variant_slug(&self) -> &'static str {
                match self {
                    #(#slug_arms)*
                }
            }

            fn variant_message(&self) -> String {
                match self {
                    #(#message_arms)*
                }
            }

            fn internal_error() -> Self {
                #ty::InternalError(::std::boxed::Box::new(
                    #utils_path::skir::base::kernel::v1::errors::InternalError::default(),
                ))
            }

            fn domain_error_from_slug(slug: &str) -> ::std::option::Option<Self> {
                match slug {
                    #(#domain_error_from_slug_arms)*
                    _ => ::std::option::Option::None,
                }
            }
        }
    }
}

fn parse_success_variants(input: ParseStream) -> syn::Result<Vec<Ident>> {
    let keyword: Ident = input.parse()?;
    if keyword != "success" {
        return Err(syn::Error::new(keyword.span(), "expected `success`"));
    }

    let _: Token![:] = input.parse()?;

    if !input.lookahead1().peek(syn::token::Bracket) {
        let variant = input.parse()?;
        validate_not_internal_error(&variant, "success")?;
        return Ok(vec![variant]);
    }

    let content;
    syn::bracketed!(content in input);

    let mut variants = Vec::new();
    while !content.is_empty() {
        let variant = content.parse()?;
        validate_not_internal_error(&variant, "success")?;
        variants.push(variant);

        if content.peek(Token![,]) {
            let _: Token![,] = content.parse()?;
        }
    }

    if variants.is_empty() {
        return Err(syn::Error::new(
            content.span(),
            "success list must contain at least one variant",
        ));
    }

    Ok(variants)
}

fn parse_error_variants(
    input: ParseStream,
    success_variants: &[Ident],
) -> syn::Result<Vec<ErrorEntry>> {
    let keyword: Ident = input.parse()?;
    if keyword != "errors" {
        return Err(syn::Error::new(keyword.span(), "expected `errors`"));
    }

    let content;
    braced!(content in input);

    let mut errors = Vec::new();
    let mut seen = HashSet::new();

    while !content.is_empty() {
        let variant: Ident = content.parse()?;
        validate_not_internal_error(&variant, "errors")?;
        let variant_name = variant.to_string();

        if success_variants.iter().any(|success| success == &variant) {
            return Err(syn::Error::new(
                variant.span(),
                "error variant cannot also be listed as success",
            ));
        }

        if !seen.insert(variant_name) {
            return Err(syn::Error::new(
                variant.span(),
                "duplicate error variant in skir_response! declaration",
            ));
        }

        if variant == "InvalidRecordIdError" {
            if content.peek(token::Paren) || content.peek(Token![=>]) {
                return Err(syn::Error::new(
                    variant.span(),
                    "`InvalidRecordIdError` is reserved and does not accept a binding or custom message",
                ));
            }
            errors.push(ErrorEntry::StandardInvalidRecordId { variant });
        } else {
            let binding = parse_optional_binding(&content)?;
            let _: Token![=>] = content.parse()?;
            let message = content.parse()?;
            errors.push(ErrorEntry::Custom {
                variant,
                binding,
                message,
            });
        }

        if content.peek(Token![,]) {
            let _: Token![,] = content.parse()?;
        }
    }

    Ok(errors)
}

fn validate_not_internal_error(variant: &Ident, section: &str) -> syn::Result<()> {
    if variant != "InternalError" {
        return Ok(());
    }

    Err(syn::Error::new(
        variant.span(),
        format!(
            "`InternalError` is reserved in `{}` and is generated by convention from an `internal_error` Skir variant",
            section
        ),
    ))
}

fn parse_optional_binding(input: ParseStream) -> syn::Result<Option<Ident>> {
    if !input.peek(token::Paren) {
        return Ok(None);
    }

    let content;
    syn::parenthesized!(content in input);
    let binding = content.parse()?;

    if !content.is_empty() {
        return Err(syn::Error::new(
            content.span(),
            "expected single payload binding in variant pattern",
        ));
    }

    Ok(Some(binding))
}

fn outcome_arms(input: &SkirResponseInput, utils_path: &syn::Path) -> Vec<TokenStream> {
    let ty = &input.ty;
    let mut arms = Vec::new();

    for variant in &input.success {
        arms.push(quote! { #ty::#variant(_) => #utils_path::SkirResponseOutcome::Success, });
    }

    for error in &input.errors {
        let variant = error.variant();
        arms.push(quote! { #ty::#variant(_) => #utils_path::SkirResponseOutcome::DomainError, });
    }

    arms.push(quote! { #ty::InternalError(_) => #utils_path::SkirResponseOutcome::InternalError, });
    arms.push(quote! { #ty::Unknown(_) => #utils_path::SkirResponseOutcome::InternalError, });
    arms
}

fn slug_arms(input: &SkirResponseInput) -> Vec<TokenStream> {
    let ty = &input.ty;
    let mut arms = Vec::new();

    for variant in &input.success {
        let slug = variant.to_string().to_case(Case::Kebab);
        arms.push(quote! { #ty::#variant(_) => #slug, });
    }

    for error in &input.errors {
        let variant = error.variant();
        let slug = variant.to_string().to_case(Case::Kebab);
        arms.push(quote! { #ty::#variant(_) => #slug, });
    }

    arms.push(quote! { #ty::InternalError(_) => "internal-error", });
    arms.push(quote! { #ty::Unknown(_) => "unknown", });
    arms
}

fn domain_error_from_slug_arms(input: &SkirResponseInput) -> Vec<TokenStream> {
    let ty = &input.ty;
    let mut arms = Vec::new();

    for error in input
        .errors
        .iter()
        .filter(|error| matches!(error, ErrorEntry::Custom { binding: None, .. }))
    {
        let variant = error.variant();
        let slug = variant.to_string().to_case(Case::Kebab);
        arms.push(quote! {
            #slug => ::std::option::Option::Some(#ty::#variant(::std::default::Default::default())),
        });
    }

    arms
}

fn message_arms(input: &SkirResponseInput) -> Vec<TokenStream> {
    let ty = &input.ty;
    let mut arms = Vec::new();

    for variant in &input.success {
        arms.push(quote! { #ty::#variant(_) => "success".to_string(), });
    }

    for error in &input.errors {
        let variant = error.variant();
        let arm = match error {
            ErrorEntry::Custom {
                binding: Some(binding),
                message,
                ..
            } => quote! { #ty::#variant(#binding) => #message, },
            ErrorEntry::Custom { message, .. } => {
                quote! { #ty::#variant(_) => #message.to_string(), }
            }
            ErrorEntry::StandardInvalidRecordId { .. } => quote! {
                #ty::#variant(error) => ::std::format!(
                    "Expected record IDs from table '{}', but received tables: {}.",
                    error.expected_table,
                    error.given_tables.iter().map(|table| ::std::format!("'{}'", table)).collect::<::std::vec::Vec<_>>().join(", "),
                ),
            },
        };
        arms.push(arm);
    }

    arms.push(quote! { #ty::InternalError(_) => "internal error".to_string(), });
    arms.push(quote! { #ty::Unknown(_) => "unknown response variant".to_string(), });
    arms
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_reserved_invalid_record_id_shorthand() {
        let input = syn::parse_str::<SkirResponseInput>(
            "Response { success: Success, errors { InvalidRecordIdError, } }",
        )
        .expect("reserved shorthand should parse");

        assert!(matches!(
            input.errors.as_slice(),
            [ErrorEntry::StandardInvalidRecordId { .. }]
        ));
    }

    #[test]
    fn rejects_binding_on_reserved_invalid_record_id_shorthand() {
        let error = syn::parse_str::<SkirResponseInput>(
            "Response { success: Success, errors { InvalidRecordIdError(error) } }",
        )
        .err()
        .expect("reserved shorthand must reject bindings");

        assert!(error.to_string().contains("does not accept a binding"));
    }

    #[test]
    fn rejects_custom_message_on_reserved_invalid_record_id_shorthand() {
        let error = syn::parse_str::<SkirResponseInput>(
            "Response { success: Success, errors { InvalidRecordIdError => \"invalid\" } }",
        )
        .err()
        .expect("reserved shorthand must reject custom messages");

        assert!(error.to_string().contains("does not accept a binding"));
    }
}
