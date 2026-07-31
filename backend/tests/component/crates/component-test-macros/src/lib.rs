//! Procedural macros for embedded component tests.

use proc_macro::TokenStream;
use proc_macro2::Span;
use quote::{format_ident, quote};
use syn::{
    Attribute, Expr, FnArg, Ident, ItemFn, ItemStruct, LitStr, Path, Token, Type,
    parse::{Parse, ParseStream},
    parse_macro_input,
    punctuated::Punctuated,
};

#[proc_macro_attribute]
pub fn component_fixture(attribute: TokenStream, item: TokenStream) -> TokenStream {
    let input = parse_macro_input!(attribute as FixtureArgs);
    let item = parse_macro_input!(item as ItemStruct);
    expand_fixture(input, item)
        .unwrap_or_else(syn::Error::into_compile_error)
        .into()
}

#[proc_macro_attribute]
pub fn component_test(attribute: TokenStream, item: TokenStream) -> TokenStream {
    let fixture = parse_macro_input!(attribute as FixturePath);
    let item = parse_macro_input!(item as ItemFn);
    expand_test(fixture.0, item)
        .unwrap_or_else(syn::Error::into_compile_error)
        .into()
}

struct FixturePath(Path);

impl Parse for FixturePath {
    fn parse(input: ParseStream<'_>) -> syn::Result<Self> {
        let path = input.parse()?;
        if !input.is_empty() {
            return Err(input.error("expected one fixture type"));
        }
        Ok(Self(path))
    }
}

struct FixtureArgs {
    id: LitStr,
    primary: ComponentArg,
    dependencies: Vec<ComponentArg>,
    affected_paths: Vec<LitStr>,
}

struct ComponentArg {
    package: LitStr,
    target: LitStr,
}

impl Parse for FixtureArgs {
    fn parse(input: ParseStream<'_>) -> syn::Result<Self> {
        let mut id = None;
        let mut primary = None;
        let mut dependencies = Vec::new();
        let mut affected_paths = Vec::new();

        while !input.is_empty() {
            let key: Ident = input.parse()?;
            match key.to_string().as_str() {
                "id" => {
                    let _: Token![=] = input.parse()?;
                    set_once(&mut id, input.parse()?, key.span(), "id")?;
                }
                "primary" => {
                    let content;
                    syn::parenthesized!(content in input);
                    set_once(&mut primary, content.parse()?, key.span(), "primary")?;
                }
                "dependency" => {
                    let content;
                    syn::parenthesized!(content in input);
                    dependencies.push(content.parse()?);
                }
                "affected_paths" => {
                    let content;
                    syn::parenthesized!(content in input);
                    affected_paths
                        .extend(Punctuated::<LitStr, Token![,]>::parse_terminated(&content)?);
                }
                _ => return Err(syn::Error::new(key.span(), "unknown fixture option")),
            }
            if input.peek(Token![,]) {
                let _: Token![,] = input.parse()?;
            } else if !input.is_empty() {
                return Err(input.error("expected `,` between fixture options"));
            }
        }

        Ok(Self {
            id: id.ok_or_else(|| syn::Error::new(Span::call_site(), "missing `id`"))?,
            primary: primary
                .ok_or_else(|| syn::Error::new(Span::call_site(), "missing `primary(...)`"))?,
            dependencies,
            affected_paths,
        })
    }
}

impl Parse for ComponentArg {
    fn parse(input: ParseStream<'_>) -> syn::Result<Self> {
        let mut package = None;
        let mut target = None;
        while !input.is_empty() {
            let key: Ident = input.parse()?;
            let _: Token![=] = input.parse()?;
            match key.to_string().as_str() {
                "package" => set_once(&mut package, input.parse()?, key.span(), "package")?,
                "target" => set_once(&mut target, input.parse()?, key.span(), "target")?,
                _ => return Err(syn::Error::new(key.span(), "unknown component option")),
            }
            if input.peek(Token![,]) {
                let _: Token![,] = input.parse()?;
            } else if !input.is_empty() {
                return Err(input.error("expected `,` between component options"));
            }
        }
        Ok(Self {
            package: package
                .ok_or_else(|| syn::Error::new(Span::call_site(), "missing `package`"))?,
            target: target.ok_or_else(|| syn::Error::new(Span::call_site(), "missing `target`"))?,
        })
    }
}

fn set_once<T>(slot: &mut Option<T>, value: T, span: Span, name: &str) -> syn::Result<()> {
    if slot.replace(value).is_some() {
        return Err(syn::Error::new(span, format!("duplicate `{name}`")));
    }
    Ok(())
}

fn expand_fixture(args: FixtureArgs, item: ItemStruct) -> syn::Result<proc_macro2::TokenStream> {
    if !item.generics.params.is_empty() {
        return Err(syn::Error::new_spanned(
            &item.generics,
            "component fixtures cannot be generic",
        ));
    }
    let fixture = &item.ident;
    let id = &args.id;
    let primary_package = &args.primary.package;
    let primary_target = &args.primary.target;
    let dependencies = args.dependencies.iter().map(|dependency| {
        let package = &dependency.package;
        let target = &dependency.target;
        quote!(::component_test::ComponentBuild::dependency(#package, #target))
    });
    let affected_paths = &args.affected_paths;

    Ok(quote! {
        #item

        impl ::component_test::FixtureDeclaration for #fixture {
            const DESCRIPTOR: ::component_test::FixtureDescriptor =
                ::component_test::FixtureDescriptor {
                    id: #id,
                    primary: ::component_test::ComponentBuild::primary(
                        #primary_package,
                        #primary_target,
                    ),
                    dependencies: &[#(#dependencies),*],
                    affected_paths: &[#(#affected_paths),*],
                };
        }

        ::component_test::inventory::submit! {
            ::component_test::FixtureRegistration {
                descriptor: &<#fixture as ::component_test::FixtureDeclaration>::DESCRIPTOR,
            }
        }
    })
}

struct NamedCase {
    name: Ident,
    values: Vec<Expr>,
}

fn parse_case(attribute: &Attribute) -> syn::Result<Option<NamedCase>> {
    let segments = &attribute.path().segments;
    if segments.len() != 2 || segments[0].ident != "case" {
        return Ok(None);
    }
    let values = attribute
        .parse_args_with(Punctuated::<Expr, Token![,]>::parse_terminated)?
        .into_iter()
        .collect();
    Ok(Some(NamedCase {
        name: segments[1].ident.clone(),
        values,
    }))
}

fn expand_test(fixture: Path, mut item: ItemFn) -> syn::Result<proc_macro2::TokenStream> {
    if item.sig.asyncness.is_none() {
        return Err(syn::Error::new_spanned(
            item.sig.fn_token,
            "component tests must be async",
        ));
    }
    if !item.sig.generics.params.is_empty() {
        return Err(syn::Error::new_spanned(
            &item.sig.generics,
            "component tests cannot be generic",
        ));
    }
    if item.sig.inputs.is_empty() {
        return Err(syn::Error::new_spanned(
            &item.sig.inputs,
            "first argument must be `&mut TestContext<Fixture>`",
        ));
    }
    if item
        .sig
        .inputs
        .iter()
        .any(|argument| matches!(argument, FnArg::Receiver(_)))
    {
        return Err(syn::Error::new_spanned(
            &item.sig.inputs,
            "component tests must be free functions",
        ));
    }
    reject_conflicting_attributes(&item.attrs)?;

    let mut cases = Vec::new();
    let mut retained = Vec::new();
    for attribute in item.attrs {
        if let Some(case) = parse_case(&attribute)? {
            cases.push(case);
        } else {
            retained.push(attribute);
        }
    }
    item.attrs = retained;

    let parameter_count = item.sig.inputs.len() - 1;
    if cases.is_empty() && parameter_count > 0 {
        return Err(syn::Error::new_spanned(
            &item.sig.inputs,
            "tests with case parameters require at least one `#[case::name(...)]`",
        ));
    }
    let mut names = std::collections::BTreeSet::new();
    for case in &cases {
        if !names.insert(case.name.to_string()) {
            return Err(syn::Error::new(
                case.name.span(),
                "duplicate component test case name",
            ));
        }
        if case.values.len() != parameter_count {
            return Err(syn::Error::new(
                case.name.span(),
                format!(
                    "case supplies {} values but test expects {parameter_count}",
                    case.values.len()
                ),
            ));
        }
    }

    let original = item.sig.ident.clone();
    let hidden = format_ident!("__component_test_body_{original}");
    item.sig.ident = hidden.clone();
    let wrapper_attributes = item.attrs.iter().filter(|attribute| {
        attribute.path().is_ident("cfg") || attribute.path().is_ident("ignore")
    });

    let wrappers = if cases.is_empty() {
        vec![expand_case_wrapper(
            &fixture,
            &original,
            &original,
            &hidden,
            None,
            &[],
            wrapper_attributes.clone(),
        )]
    } else {
        cases
            .iter()
            .map(|case| {
                let wrapper = format_ident!("{original}__{}", case.name);
                expand_case_wrapper(
                    &fixture,
                    &original,
                    &wrapper,
                    &hidden,
                    Some(&case.name),
                    &case.values,
                    wrapper_attributes.clone(),
                )
            })
            .collect()
    };

    Ok(quote! {
        #item
        #(#wrappers)*
    })
}

fn expand_case_wrapper<'a>(
    fixture: &Path,
    function: &Ident,
    wrapper: &Ident,
    hidden: &Ident,
    case: Option<&Ident>,
    values: &[Expr],
    attributes: impl Iterator<Item = &'a Attribute>,
) -> proc_macro2::TokenStream {
    let case_value = case.map_or_else(
        || quote!(::core::option::Option::None),
        |case| {
            let name = case.to_string();
            quote!(::core::option::Option::Some(#name))
        },
    );
    let attributes = attributes.collect::<Vec<_>>();
    let cfg_attributes = attributes
        .iter()
        .copied()
        .filter(|attribute| attribute.path().is_ident("cfg"))
        .collect::<Vec<_>>();
    let descriptor = format_ident!(
        "__COMPONENT_TEST_DESCRIPTOR_{}",
        wrapper.to_string().to_uppercase()
    );
    quote! {
        #(#cfg_attributes)*
        static #descriptor: ::component_test::TestDescriptor =
            ::component_test::TestDescriptor {
                fixture_id: <#fixture as ::component_test::FixtureDeclaration>::DESCRIPTOR.id,
                module_path: module_path!(),
                function: stringify!(#function),
                case: #case_value,
                exact_name: concat!(module_path!(), "::", stringify!(#wrapper)),
            };

        #(#attributes)*
        #[test]
        #[allow(non_snake_case)]
        fn #wrapper() {
            ::component_test::run_case::<#fixture, _>(&#descriptor, move |context| {
                ::std::boxed::Box::pin(async move {
                    ::component_test::IntoTestResult::into_test_result(
                        #hidden(context, #(#values),*).await,
                    )
                })
            });
        }

        #(#cfg_attributes)*
        ::component_test::inventory::submit! {
            ::component_test::TestRegistration {
                descriptor: &#descriptor,
            }
        }
    }
}

fn reject_conflicting_attributes(attributes: &[Attribute]) -> syn::Result<()> {
    for attribute in attributes {
        let path = attribute.path();
        let conflicts = path.is_ident("test")
            || path.is_ident("should_panic")
            || path
                .segments
                .last()
                .is_some_and(|segment| segment.ident == "test" && path.segments.len() > 1)
            || path
                .segments
                .first()
                .is_some_and(|segment| segment.ident == "rstest");
        if conflicts {
            return Err(syn::Error::new_spanned(
                attribute,
                "component tests cannot combine another test runner attribute",
            ));
        }
    }
    Ok(())
}

#[allow(dead_code)]
fn _assert_context_type(_ty: &Type) {}
