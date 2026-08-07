use proc_macro2::TokenStream;
use quote::quote;
use syn::{
    Expr, Ident, Pat, Path, Token, braced,
    parse::{Parse, ParseStream},
};

mod keyword {
    syn::custom_keyword!(errors);
    syn::custom_keyword!(success);
}

pub(crate) struct SkirTransactionOutcomeInput {
    response_ty: Path,
    outcome: Expr,
    success: SuccessEntry,
    errors: Vec<ErrorEntry>,
}

struct SuccessEntry {
    pattern: Pat,
    value: Expr,
}

struct ErrorEntry {
    pattern: Pat,
    fields: Vec<FieldEntry>,
}

struct FieldEntry {
    name: Ident,
    value: Expr,
}

impl Parse for SkirTransactionOutcomeInput {
    fn parse(input: ParseStream) -> syn::Result<Self> {
        let response_ty = input.parse()?;
        let _: Token![,] = input.parse()?;
        let outcome = input.parse()?;
        let _: Token![,] = input.parse()?;
        let success = input.parse()?;
        let _: Token![,] = input.parse()?;
        let _: keyword::errors = input.parse()?;

        let content;
        braced!(content in input);
        let mut errors = Vec::new();
        while !content.is_empty() {
            errors.push(content.parse()?);
            if content.peek(Token![,]) {
                let _: Token![,] = content.parse()?;
            }
        }

        if input.peek(Token![,]) {
            let _: Token![,] = input.parse()?;
        }
        if !input.is_empty() {
            return Err(input.error("unexpected tokens after transaction outcome mapping"));
        }

        Ok(Self {
            response_ty,
            outcome,
            success,
            errors,
        })
    }
}

impl Parse for SuccessEntry {
    fn parse(input: ParseStream) -> syn::Result<Self> {
        let _: keyword::success = input.parse()?;
        let pattern = Pat::parse_single(input)?;
        let _: Token![=>] = input.parse()?;
        let value = input.parse()?;
        Ok(Self { pattern, value })
    }
}

impl Parse for ErrorEntry {
    fn parse(input: ParseStream) -> syn::Result<Self> {
        let pattern = Pat::parse_single(input)?;
        let _: Token![=>] = input.parse()?;

        let content;
        braced!(content in input);
        let mut fields = Vec::new();
        while !content.is_empty() {
            fields.push(content.parse()?);
            if content.peek(Token![,]) {
                let _: Token![,] = content.parse()?;
            }
        }

        Ok(Self { pattern, fields })
    }
}

impl Parse for FieldEntry {
    fn parse(input: ParseStream) -> syn::Result<Self> {
        let name: Ident = input.parse()?;
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

pub(crate) fn expand(input: SkirTransactionOutcomeInput) -> syn::Result<TokenStream> {
    let response_ty = &input.response_ty;
    let outcome = &input.outcome;
    let success_pattern = &input.success.pattern;
    let success_value = &input.success.value;
    let error_arms = input
        .errors
        .iter()
        .map(|entry| error_arm(response_ty, entry))
        .collect::<syn::Result<Vec<_>>>()?;

    Ok(quote! {
        match #outcome {
            #success_pattern => #success_value,
            #(#error_arms)*
        }
    })
}

fn error_arm(response_ty: &Path, entry: &ErrorEntry) -> syn::Result<TokenStream> {
    let pattern = &entry.pattern;
    let variant = pattern_variant(pattern)?;
    let payload_ty = crate::paths::payload_ty(response_ty, variant, "skir_transaction_outcome!")?;
    let field_names = entry.fields.iter().map(|field| &field.name);
    let field_values = entry.fields.iter().map(|field| &field.value);

    Ok(quote! {
        #pattern => {
            let payload = #payload_ty {
                #(#field_names: #field_values,)*
                _unrecognized: ::std::option::Option::None,
            };
            return ::std::result::Result::Ok(
                #response_ty::#variant(::std::boxed::Box::new(payload))
            );
        }
    })
}

fn pattern_variant(pattern: &Pat) -> syn::Result<&Ident> {
    let path = match pattern {
        Pat::Path(pattern) => &pattern.path,
        Pat::Struct(pattern) => &pattern.path,
        _ => {
            return Err(syn::Error::new_spanned(
                pattern,
                "expected an outcome enum unit or struct variant pattern",
            ));
        }
    };

    path.segments
        .last()
        .map(|segment| &segment.ident)
        .ok_or_else(|| syn::Error::new_spanned(pattern, "expected an outcome enum variant"))
}
