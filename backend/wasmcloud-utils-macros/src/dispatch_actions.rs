use proc_macro2::{Span, TokenStream, TokenTree};
use quote::quote;
use std::collections::HashSet;
use syn::{
    Expr, Ident, LitStr, Token,
    parse::{Parse, ParseStream},
};

pub(crate) struct DispatchInput {
    msg: Expr,
    templates: Vec<TemplateEntry>,
    actions: Vec<ActionEntry>,
}

struct TemplateEntry {
    name: Ident,
    template: LitStr,
}

struct ActionEntry {
    pattern: LitStr,
    handler: Expr,
    is_async: bool,
}

impl Parse for DispatchInput {
    fn parse(input: ParseStream) -> syn::Result<Self> {
        let msg = input.parse()?;
        let _: Token![,] = input.parse()?;
        let templates = parse_templates(input)?;
        let actions = parse_actions(input)?;

        Ok(Self {
            msg,
            templates,
            actions,
        })
    }
}

pub(crate) fn expand(input: DispatchInput) -> syn::Result<TokenStream> {
    validate(&input)?;

    let msg = &input.msg;
    let utils_path = crate::paths::utils_path();
    let parse_logic = parse_logic(&input, &utils_path);

    if input.is_simple_template() {
        let arms = simple_action_arms(&input, &utils_path);

        return Ok(quote! {
            {
                let msg = #msg;

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
        });
    }

    Ok(quote! {
        {
            let msg = #msg;

            #utils_path::otel_wasi::main_attribute!(
                "messaging.destination.name" = msg.subject.clone(),
            );

            #parse_logic
        }
    })
}

impl DispatchInput {
    fn is_simple_template(&self) -> bool {
        self.templates.len() == 1 && self.templates[0].name == "_"
    }
}

fn parse_templates(input: ParseStream) -> syn::Result<Vec<TemplateEntry>> {
    if starts_named_templates(input)? {
        let templates = parse_named_templates(input)?;
        let _: Token![;] = input.parse()?;
        return Ok(templates);
    }

    let template = input.parse()?;
    let _: Token![,] = input.parse()?;

    Ok(vec![TemplateEntry {
        name: Ident::new("_", Span::call_site()),
        template,
    }])
}

fn starts_named_templates(input: ParseStream) -> syn::Result<bool> {
    if !input.lookahead1().peek(Ident) {
        return Ok(false);
    }

    let fork = input.fork();
    let ident: Ident = fork.parse()?;
    if ident == "true" {
        return Ok(false);
    }

    Ok(fork.peek(Token![:]))
}

fn parse_named_templates(input: ParseStream) -> syn::Result<Vec<TemplateEntry>> {
    let mut templates = Vec::new();

    loop {
        let name = input.parse()?;
        let _: Token![:] = input.parse()?;
        let template = input.parse()?;

        templates.push(TemplateEntry { name, template });

        if input.peek(Token![,]) {
            let _: Token![,] = input.parse()?;
        }

        if input.peek(Token![;]) || input.is_empty() {
            break;
        }
    }

    Ok(templates)
}

fn parse_actions(input: ParseStream) -> syn::Result<Vec<ActionEntry>> {
    let mut actions = Vec::new();

    while !input.is_empty() {
        let pattern = input.parse()?;
        let _: Token![=>] = input.parse()?;
        let (handler, is_async) = parse_handler(input)?;

        if input.peek(Token![=>]) {
            return Err(syn::Error::new(
                input.span(),
                "old dispatch action error-handler syntax no longer supported; handlers must return Result<Response, otel_wasi::Error>",
            ));
        }

        if input.peek(Token![,]) {
            let _: Token![,] = input.parse()?;
        }

        actions.push(ActionEntry {
            pattern,
            handler,
            is_async,
        });
    }

    Ok(actions)
}

fn parse_handler(input: ParseStream) -> syn::Result<(Expr, bool)> {
    let mut tokens = Vec::new();

    while !input.is_empty() && !input.peek(Token![,]) && !input.peek(Token![=>]) {
        tokens.push(input.parse::<TokenTree>()?);
    }

    if tokens.is_empty() {
        return Err(syn::Error::new(input.span(), "expected action handler"));
    }

    let has_async_prefix = has_async_prefix(&tokens);
    if has_async_prefix {
        tokens.remove(0);
    }

    let has_async_suffix = has_async_suffix(&tokens);
    if has_async_suffix {
        tokens.truncate(tokens.len() - 2);
    }

    let is_async = has_async_prefix || has_async_suffix;

    if tokens.is_empty() {
        return Err(syn::Error::new(
            input.span(),
            "expected action handler after `async` marker",
        ));
    }

    let handler = syn::parse2(tokens.into_iter().collect())?;
    Ok((handler, is_async))
}

fn has_async_prefix(tokens: &[TokenTree]) -> bool {
    let Some(TokenTree::Ident(ident)) = tokens.first() else {
        return false;
    };

    ident == "async"
}

fn has_async_suffix(tokens: &[TokenTree]) -> bool {
    let [.., dot, async_marker] = tokens else {
        return false;
    };

    matches!(dot, TokenTree::Punct(punct) if punct.as_char() == '.')
        && matches!(async_marker, TokenTree::Ident(ident) if ident == "async")
}

fn validate(input: &DispatchInput) -> syn::Result<()> {
    if input.actions.is_empty() {
        return Err(syn::Error::new(
            Span::call_site(),
            "dispatch_actions! requires at least one action",
        ));
    }

    if input.is_simple_template() {
        return validate_simple_template(input);
    }

    validate_named_templates(input)
}

fn validate_simple_template(input: &DispatchInput) -> syn::Result<()> {
    let template = &input.templates[0].template;
    if !template.value().contains("<action>") {
        return Err(syn::Error::new(
            template.span(),
            "single-template dispatch_actions! requires the subject template to contain `<action>`",
        ));
    }

    validate_unique_actions(input)
}

fn validate_named_templates(input: &DispatchInput) -> syn::Result<()> {
    validate_unique_actions(input)?;
    let template_names = validate_unique_templates(input)?;

    for action in &input.actions {
        for placeholder in braced_placeholders(&action.pattern.value()) {
            if template_names.contains(&placeholder) {
                continue;
            }

            return Err(syn::Error::new(
                action.pattern.span(),
                format!("unknown named template placeholder `{{{}}}`", placeholder),
            ));
        }
    }

    Ok(())
}

fn validate_unique_actions(input: &DispatchInput) -> syn::Result<()> {
    let mut seen = HashSet::new();

    for action in &input.actions {
        if seen.insert(action.pattern.value()) {
            continue;
        }

        return Err(syn::Error::new(
            action.pattern.span(),
            "duplicate dispatch action pattern",
        ));
    }

    Ok(())
}

fn validate_unique_templates(input: &DispatchInput) -> syn::Result<HashSet<String>> {
    let mut seen = HashSet::new();

    for template in &input.templates {
        let name = template.name.to_string();
        if seen.insert(name) {
            continue;
        }

        return Err(syn::Error::new(
            template.name.span(),
            "duplicate named template",
        ));
    }

    Ok(seen)
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

fn simple_action_arms(input: &DispatchInput, utils_path: &syn::Path) -> Vec<TokenStream> {
    input
        .actions
        .iter()
        .map(|action| {
            let pattern = &action.pattern;
            let handler_call =
                handler_call(action, quote! { msg.clone() }, quote! { params.clone() });

            quote! {
                #pattern => {
                    let result = #handler_call;
                    #utils_path::wasmcloud::messaging::reply_handler_result(msg.clone(), result).await
                }
            }
        })
        .collect()
}

fn handler_call(action: &ActionEntry, msg: TokenStream, params: TokenStream) -> TokenStream {
    let handler = &action.handler;

    if action.is_async {
        return quote! { #handler(#msg, #params).await };
    }

    quote! { #handler(#msg, #params) }
}

fn parse_logic(input: &DispatchInput, utils_path: &syn::Path) -> TokenStream {
    if input.is_simple_template() {
        return simple_parse_logic(input, utils_path);
    }

    named_template_parse_logic(input, utils_path)
}

fn simple_parse_logic(input: &DispatchInput, utils_path: &syn::Path) -> TokenStream {
    let template = &input.templates[0].template;

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
}

fn named_template_parse_logic(input: &DispatchInput, utils_path: &syn::Path) -> TokenStream {
    let pattern_checks: Vec<_> = input
        .actions
        .iter()
        .map(|action| named_template_pattern_check(action, &input.templates, utils_path))
        .collect();

    quote! {
        #(#pattern_checks)*
        return Err(#utils_path::otel_wasi::Error::new(
            "dispatch-action-unknown",
            format!("no matching action subject '{}'", msg.subject),
        ));
    }
}

fn named_template_pattern_check(
    action: &ActionEntry,
    templates: &[TemplateEntry],
    utils_path: &syn::Path,
) -> TokenStream {
    let expanded_lit = expanded_pattern_literal(&action.pattern, templates);
    let handler_call = handler_call(action, quote! { msg.clone() }, quote! { params });

    quote! {
        if let Ok(params) = #utils_path::wasmcloud::messaging::parse_subject(
            #expanded_lit,
            &msg.subject,
        ) {
            let result = #handler_call;
            return #utils_path::wasmcloud::messaging::reply_handler_result(msg.clone(), result).await;
        }
    }
}

fn expanded_pattern_literal(pattern: &LitStr, templates: &[TemplateEntry]) -> LitStr {
    let mut expanded = pattern.value();

    for template in templates {
        let placeholder = format!("{{{}}}", template.name);
        expanded = expanded.replace(&placeholder, &template.template.value());
    }

    LitStr::new(&expanded, pattern.span())
}
