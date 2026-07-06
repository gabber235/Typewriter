use proc_macro::TokenStream;
use quote::quote;
use std::{collections::HashSet, env};
use syn::{
    Expr, Ident, LitStr, Token, braced,
    parse::{Parse, ParseStream},
    parse_macro_input, token,
};

// ── skir_response! ──────────────────────────────────────────────────────────

struct SkirResponseInput {
    ty: Ident,
    success: Ident,
    errors: Vec<ErrorEntry>,
}

struct ErrorEntry {
    variant: Ident,
    binding: Option<Ident>,
    message: Expr,
}

impl Parse for SkirResponseInput {
    fn parse(input: ParseStream) -> syn::Result<Self> {
        let ty: Ident = input.parse()?;

        let content;
        braced!(content in input);

        // success: VariantName
        let _success_kw: Ident = content.parse()?;
        if _success_kw != "success" {
            return Err(syn::Error::new(_success_kw.span(), "expected `success`"));
        }
        let _colon: Token![:] = content.parse()?;
        let success: Ident = content.parse()?;
        let _comma: Token![,] = content.parse()?;

        // errors { ... }
        let _errors_kw: Ident = content.parse()?;
        if _errors_kw != "errors" {
            return Err(syn::Error::new(_errors_kw.span(), "expected `errors`"));
        }

        let errors_content;
        braced!(errors_content in content);

        let mut errors = Vec::new();
        let mut seen_error_variants = HashSet::new();
        while !errors_content.is_empty() {
            let variant: Ident = errors_content.parse()?;
            let variant_name = variant.to_string();

            if variant == success {
                return Err(syn::Error::new(
                    variant.span(),
                    "success variant cannot also be listed as an error variant",
                ));
            }
            if !seen_error_variants.insert(variant_name) {
                return Err(syn::Error::new(
                    variant.span(),
                    "duplicate error variant in skir_response! declaration",
                ));
            }

            let binding = if errors_content.peek(token::Paren) {
                let bind_content;
                syn::parenthesized!(bind_content in errors_content);
                let b: Ident = bind_content.parse()?;
                if !bind_content.is_empty() {
                    return Err(syn::Error::new(
                        bind_content.span(),
                        "expected a single payload binding in variant pattern",
                    ));
                }
                Some(b)
            } else {
                None
            };

            let _arrow: Token![=>] = errors_content.parse()?;
            let message: Expr = errors_content.parse()?;

            if errors_content.peek(Token![,]) {
                let _: Token![,] = errors_content.parse()?;
            }

            errors.push(ErrorEntry {
                variant,
                binding,
                message,
            });
        }

        Ok(SkirResponseInput {
            ty,
            success,
            errors,
        })
    }
}

#[proc_macro]
pub fn skir_response(input: TokenStream) -> TokenStream {
    let input = parse_macro_input!(input as SkirResponseInput);
    let ty = &input.ty;
    let success = &input.success;

    let mut slug_arms = Vec::new();
    let mut message_arms = Vec::new();
    let mut success_check_arms = Vec::new();

    let success_slug =
        convert_case::Casing::to_case(&success.to_string(), convert_case::Case::Kebab);
    slug_arms.push(quote! {
        #ty::#success(_) => #success_slug,
    });
    message_arms.push(quote! {
        #ty::#success(_) => "success".to_string(),
    });
    success_check_arms.push(quote! {
        #ty::#success(_) => true,
    });

    for entry in &input.errors {
        let variant = &entry.variant;
        let slug = convert_case::Casing::to_case(&variant.to_string(), convert_case::Case::Kebab);
        let message = &entry.message;

        slug_arms.push(quote! {
            #ty::#variant(_) => #slug,
        });

        message_arms.push(match &entry.binding {
            Some(binding) => {
                quote! {
                    #ty::#variant(#binding) => #message,
                }
            }
            None => {
                quote! {
                    #ty::#variant(_) => #message.to_string(),
                }
            }
        });

        success_check_arms.push(quote! {
            #ty::#variant(_) => false,
        });
    }

    slug_arms.push(quote! {
        #ty::Unknown(_) => "unknown",
    });
    message_arms.push(quote! {
        #ty::Unknown(_) => "unknown response variant".to_string(),
    });
    success_check_arms.push(quote! {
        #ty::Unknown(_) => false,
    });

    // Detect whether we're being called from within wasmcloud-utils itself.
    // If so, use `crate::` instead of `::wasmcloud_utils::`.
    let is_internal = env::var("CARGO_PKG_NAME").map_or(false, |n| n == "wasmcloud-utils");
    let skir_response_path: syn::Path = if is_internal {
        syn::parse_quote! { crate::SkirResponse }
    } else {
        syn::parse_quote! { ::wasmcloud_utils::SkirResponse }
    };

    let expanded = quote! {
        impl #skir_response_path for #ty {
            fn to_skir_bytes(&self) -> Vec<u8> {
                #ty::serializer().to_bytes(self)
            }

            fn is_success(&self) -> bool {
                match self {
                    #(#success_check_arms)*
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
        }
    };

    TokenStream::from(expanded)
}

// ── dispatch_actions! ───────────────────────────────────────────────────────

struct DispatchInput {
    msg: Expr,
    templates: Vec<(Ident, LitStr)>,
    actions: Vec<ActionEntry>,
}

struct ActionEntry {
    pattern: LitStr,
    handler: Expr,
}

impl Parse for DispatchInput {
    fn parse(input: ParseStream) -> syn::Result<Self> {
        let msg: Expr = input.parse()?;
        let _comma: Token![,] = input.parse()?;

        // Peek ahead: if we see `ident : "string"` pattern, it's named templates.
        // Otherwise it's a single template string.
        let lookahead = input.lookahead1();

        let templates: Vec<(Ident, LitStr)>;
        let actions: Vec<ActionEntry>;

        if lookahead.peek(Ident) && input.fork().parse::<Ident>()?.to_string() != "true" {
            // Check if the next pattern is `ident : "string"` (named template)
            // We need to fork and try parsing ident, colon, string
            let fork = input.fork();
            let _fork_ident: Ident = fork.parse()?;
            if fork.peek(Token![:]) {
                // Named template syntax
                templates = parse_named_templates(input)?;
                let _semi: Token![;] = input.parse()?;
                actions = parse_actions(input)?;
            } else {
                // Simple syntax: single template string
                let template: LitStr = input.parse()?;
                let _comma2: Token![,] = input.parse()?;
                templates = vec![(Ident::new("_", proc_macro2::Span::call_site()), template)];
                actions = parse_actions(input)?;
            }
        } else {
            // Simple syntax: single template string
            let template: LitStr = input.parse()?;
            let _comma2: Token![,] = input.parse()?;
            templates = vec![(Ident::new("_", proc_macro2::Span::call_site()), template)];
            actions = parse_actions(input)?;
        }

        Ok(DispatchInput {
            msg,
            templates,
            actions,
        })
    }
}

fn parse_named_templates(input: ParseStream) -> syn::Result<Vec<(Ident, LitStr)>> {
    let mut templates = Vec::new();
    loop {
        let name: Ident = input.parse()?;
        let _colon: Token![:] = input.parse()?;
        let template: LitStr = input.parse()?;
        templates.push((name, template));

        if input.peek(Token![,]) {
            let _: Token![,] = input.parse()?;
        }

        // Check if next is semicolon (end of templates) or another ident
        if input.peek(Token![;]) || input.is_empty() {
            break;
        }
    }
    Ok(templates)
}

fn parse_actions(input: ParseStream) -> syn::Result<Vec<ActionEntry>> {
    let mut actions = Vec::new();
    while !input.is_empty() {
        let pattern: LitStr = input.parse()?;
        let _arrow: Token![=>] = input.parse()?;
        let handler: Expr = input.parse()?;

        if input.peek(Token![=>]) {
            return Err(syn::Error::new(
                input.span(),
                "old dispatch action error-handler syntax is no longer supported; handlers must return Result<Response, Response>",
            ));
        }

        if input.peek(Token![,]) {
            let _: Token![,] = input.parse()?;
        }

        actions.push(ActionEntry { pattern, handler });
    }
    Ok(actions)
}

fn braced_placeholders(pattern: &str) -> Vec<String> {
    let mut placeholders = Vec::new();
    let mut rest = pattern;
    while let Some(start) = rest.find('{') {
        let after_start = &rest[start + 1..];
        let Some(end) = after_start.find('}') else {
            break;
        };
        placeholders.push(after_start[..end].to_string());
        rest = &after_start[end + 1..];
    }
    placeholders
}

#[proc_macro]
pub fn dispatch_actions(input: TokenStream) -> TokenStream {
    let input = parse_macro_input!(input as DispatchInput);
    let _msg = &input.msg;

    // Detect whether we're being called from within wasmcloud-utils itself.
    let is_internal = env::var("CARGO_PKG_NAME").map_or(false, |n| n == "wasmcloud-utils");
    let utils_path: syn::Path = if is_internal {
        syn::parse_quote! { crate }
    } else {
        syn::parse_quote! { ::wasmcloud_utils }
    };

    if input.actions.is_empty() {
        return syn::Error::new(
            proc_macro2::Span::call_site(),
            "dispatch_actions! requires at least one action",
        )
        .to_compile_error()
        .into();
    }

    let is_simple = input.templates.len() == 1 && input.templates[0].0 == "_";
    if is_simple && !input.templates[0].1.value().contains("<action>") {
        return syn::Error::new(
            input.templates[0].1.span(),
            "single-template dispatch_actions! requires the subject template to contain `<action>`",
        )
        .to_compile_error()
        .into();
    }

    let mut seen_actions = HashSet::new();
    for action in &input.actions {
        let action_string = action.pattern.value();
        if !seen_actions.insert(action_string) {
            return syn::Error::new(action.pattern.span(), "duplicate dispatch action pattern")
                .to_compile_error()
                .into();
        }
    }

    if !is_simple {
        let mut seen_templates = HashSet::new();
        let template_names: HashSet<String> = input
            .templates
            .iter()
            .map(|(name, _)| name.to_string())
            .collect();
        for (name, _) in &input.templates {
            let name_string = name.to_string();
            if !seen_templates.insert(name_string) {
                return syn::Error::new(name.span(), "duplicate named template")
                    .to_compile_error()
                    .into();
            }
        }
        for action in &input.actions {
            for placeholder in braced_placeholders(&action.pattern.value()) {
                if !template_names.contains(&placeholder) {
                    return syn::Error::new(
                        action.pattern.span(),
                        format!("unknown named template placeholder `{{{}}}`", placeholder),
                    )
                    .to_compile_error()
                    .into();
                }
            }
        }
    }

    // Build template expansion logic (used in generated code via LitStr)
    let _template_pairs: Vec<_> = input
        .templates
        .iter()
        .map(|(name, template)| {
            let name_str = name.to_string();
            quote! {
                (#name_str, #template)
            }
        })
        .collect();

    // Build match arms
    let mut arms = Vec::new();
    for action in &input.actions {
        let pattern = &action.pattern;
        let handler = &action.handler;

        let arm = if input.templates.len() == 1 && input.templates[0].0 == "_" {
            // Simple single-template syntax: template is used in parse_logic above
            let _template = &input.templates[0].1;
            quote! {
                #pattern => {
                    let result = #handler(msg.clone(), params.clone());
                    #utils_path::wasmcloud::messaging::reply_result_response(msg.clone(), result)
                }
            }
        } else {
            // Named template syntax: expand pattern
            let mut expanded_pattern = pattern.value();
            for (name, template) in &input.templates {
                let placeholder = format!("{{{}}}", name);
                expanded_pattern = expanded_pattern.replace(&placeholder, &template.value());
            }
            let expanded_lit = LitStr::new(&expanded_pattern, pattern.span());
            quote! {
                #expanded_lit => {
                    let result = #handler(msg.clone(), params.clone());
                    #utils_path::wasmcloud::messaging::reply_result_response(msg.clone(), result)
                }
            }
        };

        arms.push(arm);
    }

    // For simple syntax, use the single template for subject parsing
    let parse_logic = if input.templates.len() == 1 && input.templates[0].0 == "_" {
        let template = &input.templates[0].1;
        quote! {
            let params = #utils_path::wasmcloud::messaging::parse_subject(
                #template,
                &msg.subject,
            )?;
            let action = params
                .get("action")
                .ok_or_else(|| #utils_path::otel_wasi::Error::new(
                    "dispatch-action-missing",
                    "missing action in subject",
                ))?;
        }
    } else {
        // Named templates: try each expanded pattern
        let mut pattern_checks = Vec::new();
        for action in &input.actions {
            let pattern = &action.pattern;
            let mut expanded_pattern = pattern.value();
            for (name, template) in &input.templates {
                let placeholder = format!("{{{}}}", name);
                expanded_pattern = expanded_pattern.replace(&placeholder, &template.value());
            }
            let expanded_lit = LitStr::new(&expanded_pattern, pattern.span());
            let handler = &action.handler;
            pattern_checks.push(quote! {
                if let Ok(params) = #utils_path::wasmcloud::messaging::parse_subject(
                    #expanded_lit,
                    &msg.subject,
                ) {
                    let result = #handler(msg.clone(), params);
                    return #utils_path::wasmcloud::messaging::reply_result_response(msg.clone(), result);
                }
            });
        }
        quote! {
            #(#pattern_checks)*
            return Err(#utils_path::otel_wasi::Error::new(
                "dispatch-action-unknown",
                format!("no matching action for subject '{}'", msg.subject),
            ));
        }
    };

    let expanded = if input.templates.len() == 1 && input.templates[0].0 == "_" {
        // Simple syntax: parse subject once, match on action
        quote! {
            {
                #parse_logic

                #utils_path::otel_wasi::main_attribute!(
                    "messaging.destination.name" = msg.subject.clone(),
                    "messaging.action.name" = action.clone(),
                );

                match action.as_str() {
                    #(#arms)*
                    _ => Err(#utils_path::otel_wasi::Error::new(
                        "dispatch-action-unknown",
                        format!("unknown action '{}'", action),
                    )),
                }
            }
        }
    } else {
        // Named templates: try each pattern
        quote! {
            {
                #utils_path::otel_wasi::main_attribute!(
                    "messaging.destination.name" = msg.subject.clone(),
                );

                #parse_logic
            }
        }
    };

    TokenStream::from(expanded)
}
