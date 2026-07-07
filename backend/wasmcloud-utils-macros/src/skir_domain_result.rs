use convert_case::{Case, Casing};
use proc_macro2::TokenStream;
use quote::quote;
use syn::{
    Expr, Ident, LitStr, Path, Token, braced,
    parse::{Parse, ParseStream},
};

pub(crate) struct SkirDomainResultInput {
    response_ty: Path,
    result: Expr,
    overrides: Vec<OverrideEntry>,
}

struct OverrideEntry {
    slug: LitStr,
    fields: Vec<FieldEntry>,
}

struct FieldEntry {
    name: Ident,
    value: Expr,
}

impl Parse for SkirDomainResultInput {
    fn parse(input: ParseStream) -> syn::Result<Self> {
        let response_ty = input.parse()?;
        let _: Token![,] = input.parse()?;
        let result = input.parse()?;

        let mut overrides = Vec::new();
        if input.peek(Token![,]) {
            let _: Token![,] = input.parse()?;
        }

        while !input.is_empty() {
            overrides.push(input.parse()?);

            if input.peek(Token![,]) {
                let _: Token![,] = input.parse()?;
            }
        }

        Ok(Self {
            response_ty,
            result,
            overrides,
        })
    }
}

impl Parse for OverrideEntry {
    fn parse(input: ParseStream) -> syn::Result<Self> {
        let slug = input.parse()?;
        let _: Token![=>] = input.parse()?;

        let content;
        braced!(content in input);

        let mut fields = Vec::new();
        while !content.is_empty() {
            let name = content.parse()?;
            let _: Token![:] = content.parse()?;
            let value = content.parse()?;
            fields.push(FieldEntry { name, value });

            if content.peek(Token![,]) {
                let _: Token![,] = content.parse()?;
            }
        }

        Ok(Self { slug, fields })
    }
}

pub(crate) fn expand(input: SkirDomainResultInput) -> syn::Result<TokenStream> {
    let utils_path = crate::paths::utils_path();
    let response_ty = &input.response_ty;
    let result = &input.result;
    let override_arms = override_arms(&input)?;

    Ok(quote! {
        {
            match #utils_path::SkirDomainResultExt::into_skir_domain_result_with::<#response_ty, _>(
                #result,
                |slug| match slug {
                    #(#override_arms)*
                    _ => ::std::option::Option::None,
                },
            )? {
                #utils_path::SkirDomainResult::Value(value) => value,
                #utils_path::SkirDomainResult::Response(response) => return ::std::result::Result::Ok(response),
            }
        }
    })
}

fn override_arms(input: &SkirDomainResultInput) -> syn::Result<Vec<TokenStream>> {
    input
        .overrides
        .iter()
        .map(|entry| override_arm(&input.response_ty, entry))
        .collect()
}

fn override_arm(response_ty: &Path, entry: &OverrideEntry) -> syn::Result<TokenStream> {
    let slug_value = entry.slug.value();
    let variant_ident = Ident::new(&slug_value.to_case(Case::Pascal), entry.slug.span());
    let payload_ty = payload_ty(response_ty, &variant_ident)?;
    let field_names = entry.fields.iter().map(|field| &field.name);
    let field_values = entry.fields.iter().map(|field| &field.value);
    let slug = &entry.slug;

    Ok(quote! {
        #slug => {
            let payload = #payload_ty {
                #(#field_names: #field_values,)*
                _unrecognized: ::std::option::Option::None,
            };
            ::std::option::Option::Some(#response_ty::#variant_ident(::std::boxed::Box::new(payload)))
        }
    })
}

fn payload_ty(response_ty: &Path, variant_ident: &Ident) -> syn::Result<Path> {
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
            "skir_domain_result! response type must not have generic arguments",
        ));
    }

    let payload_ident = Ident::new(
        &format!("{}_{}", last_segment.ident, variant_ident),
        last_segment.ident.span(),
    );
    last_segment.ident = payload_ident;

    Ok(payload_ty)
}
