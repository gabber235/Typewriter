use std::{fs, path::Path};

use proc_macro2::TokenStream;
use quote::quote;
use syn::{LitStr, Token, Type, parse::Parse, parse::ParseStream};

const MUTATION_TOKENS: &[&str] = &["CREATE", "DELETE", "INSERT", "RELATE", "UPDATE", "UPSERT"];

pub(crate) struct ReadQueryInput {
    query: LitStr,
}

impl Parse for ReadQueryInput {
    fn parse(input: ParseStream) -> syn::Result<Self> {
        let query = input.parse()?;
        if input.peek(Token![,]) {
            let _: Token![,] = input.parse()?;
        }
        if !input.is_empty() {
            return Err(input.error("read_query! accepts exactly one string literal"));
        }
        Ok(Self { query })
    }
}

pub(crate) struct TransactionQueryInput {
    outcome: Type,
    query: LitStr,
}

pub(crate) struct TransactionQueryFileInput {
    outcome: Type,
    path: LitStr,
}

impl Parse for TransactionQueryInput {
    fn parse(input: ParseStream) -> syn::Result<Self> {
        let outcome = input.parse()?;
        let _: Token![,] = input.parse()?;
        let query = input.parse()?;
        if input.peek(Token![,]) {
            let _: Token![,] = input.parse()?;
        }
        if !input.is_empty() {
            return Err(
                input.error("transaction_query! accepts an outcome type and one string literal")
            );
        }
        Ok(Self { outcome, query })
    }
}

impl Parse for TransactionQueryFileInput {
    fn parse(input: ParseStream) -> syn::Result<Self> {
        let outcome = input.parse()?;
        let _: Token![,] = input.parse()?;
        let path = input.parse()?;
        if input.peek(Token![,]) {
            let _: Token![,] = input.parse()?;
        }
        if !input.is_empty() {
            return Err(input.error(
                "transaction_query_file! accepts an outcome type and one manifest relative path",
            ));
        }
        Ok(Self { outcome, path })
    }
}

pub(crate) fn expand_read(input: ReadQueryInput) -> syn::Result<TokenStream> {
    let query_value = input.query.value();
    if let Some(token) = mutation_token(&query_value) {
        return Err(syn::Error::new(
            input.query.span(),
            format!("read_query! does not allow the mutation token {token}"),
        ));
    }
    let statements = top_level_statements(&query_value).map_err(|message| {
        syn::Error::new(input.query.span(), format!("invalid read query: {message}"))
    })?;
    let Some(outcome_index) = statements.len().checked_sub(1) else {
        return Err(syn::Error::new(
            input.query.span(),
            "read_query! requires at least one statement",
        ));
    };

    let query = input.query;
    Ok(quote! {
        ::wasmcloud_utils::database::ReadQuery::__from_literal(#query, #outcome_index)
    })
}

pub(crate) fn expand_transaction(input: TransactionQueryInput) -> syn::Result<TokenStream> {
    let outcome_index = transaction_outcome_index(&input.query)?;
    let outcome = input.outcome;
    let query = input.query;
    Ok(quote! {
        ::wasmcloud_utils::database::TransactionQuery::<#outcome>::__from_literal(#query, #outcome_index)
    })
}

pub(crate) fn expand_transaction_file(
    input: TransactionQueryFileInput,
) -> syn::Result<TokenStream> {
    let query = read_query_file(&input.path)?;
    let outcome_index = transaction_outcome_index(&query)?;
    let outcome = input.outcome;
    let path = input.path;
    Ok(quote! {
        ::wasmcloud_utils::database::TransactionQuery::<#outcome>::__from_literal(
            include_str!(concat!(env!("CARGO_MANIFEST_DIR"), "/", #path)),
            #outcome_index,
        )
    })
}

pub(crate) fn expand_transaction_outcome_index(query: LitStr) -> syn::Result<TokenStream> {
    let outcome_index = transaction_outcome_index(&query)?;
    Ok(quote! { #outcome_index })
}

pub(crate) fn expand_transaction_outcome_index_file(path: LitStr) -> syn::Result<TokenStream> {
    let query = read_query_file(&path)?;
    let outcome_index = transaction_outcome_index(&query)?;
    Ok(quote! {{
        const _: &str = include_str!(concat!(env!("CARGO_MANIFEST_DIR"), "/", #path));
        #outcome_index
    }})
}

fn read_query_file(path: &LitStr) -> syn::Result<LitStr> {
    let manifest_dir = std::env::var("CARGO_MANIFEST_DIR").map_err(|error| {
        syn::Error::new(
            path.span(),
            format!("could not locate the caller manifest directory: {error}"),
        )
    })?;
    let path_value = path.value();
    if Path::new(&path_value).is_absolute() {
        return Err(syn::Error::new(
            path.span(),
            "transaction query file path must be relative to the caller manifest",
        ));
    }
    let query_path = Path::new(&manifest_dir).join(&path_value);
    let query = fs::read_to_string(&query_path).map_err(|error| {
        syn::Error::new(
            path.span(),
            format!("could not read transaction query file {path_value}: {error}"),
        )
    })?;

    Ok(LitStr::new(&query, path.span()))
}

fn transaction_outcome_index(query: &LitStr) -> syn::Result<usize> {
    let query_value = query.value();
    let statements = top_level_statements(&query_value).map_err(|message| {
        syn::Error::new(
            query.span(),
            format!("invalid transaction query: {message}"),
        )
    })?;

    let Some(first) = statements.first() else {
        return Err(syn::Error::new(
            query.span(),
            "transaction_query! requires BEGIN TRANSACTION as its first statement",
        ));
    };
    if !statement_matches(first, "BEGIN TRANSACTION") {
        return Err(syn::Error::new(
            query.span(),
            "transaction_query! requires BEGIN TRANSACTION as its first statement",
        ));
    }

    let Some(last) = statements.last() else {
        unreachable!("the first statement exists");
    };
    if !statement_matches(last, "COMMIT TRANSACTION") {
        return Err(syn::Error::new(
            query.span(),
            "transaction_query! requires COMMIT TRANSACTION as its final statement",
        ));
    }

    let Some(outcome_index) = statements
        .iter()
        .enumerate()
        .rev()
        .find_map(|(index, statement)| statement_starts_with(statement, "RETURN").then_some(index))
    else {
        return Err(syn::Error::new(
            query.span(),
            "transaction_query! requires a top level RETURN outcome statement",
        ));
    };
    if outcome_index + 1 != statements.len() - 1 {
        return Err(syn::Error::new(
            query.span(),
            "transaction_query! requires RETURN to be the final statement before COMMIT TRANSACTION",
        ));
    }

    Ok(outcome_index)
}

fn mutation_token(query: &str) -> Option<&'static str> {
    let code = code_without_literals_and_comments(query).ok()?;
    code.split(|character: char| !character.is_ascii_alphanumeric() && character != '_')
        .map(str::to_ascii_uppercase)
        .find_map(|word| MUTATION_TOKENS.iter().copied().find(|token| word == *token))
}

fn top_level_statements(query: &str) -> Result<Vec<String>, &'static str> {
    let code = code_without_literals_and_comments(query)?;
    let mut statements = Vec::new();
    let mut start = 0;
    let mut depth = 0_u32;

    for (index, character) in code.char_indices() {
        match character {
            '(' | '[' | '{' => depth = depth.saturating_add(1),
            ')' | ']' | '}' => {
                depth = depth.checked_sub(1).ok_or("unbalanced closing delimiter")?;
            }
            ';' if depth == 0 => {
                let statement = code[start..index].trim();
                if !statement.is_empty() {
                    statements.push(statement.to_owned());
                }
                start = index + character.len_utf8();
            }
            _ => {}
        }
    }

    if depth != 0 {
        return Err("unclosed delimiter");
    }
    let trailing = code[start..].trim();
    if !trailing.is_empty() {
        statements.push(trailing.to_owned());
    }
    Ok(statements)
}

fn code_without_literals_and_comments(query: &str) -> Result<String, &'static str> {
    let bytes = query.as_bytes();
    let mut code = bytes.to_vec();
    let mut index = 0;

    while index < bytes.len() {
        match bytes[index] {
            b'\'' | b'"' | b'`' => {
                let quote = bytes[index];
                code[index] = b' ';
                index += 1;
                let mut closed = false;
                while index < bytes.len() {
                    code[index] = b' ';
                    if bytes[index] == b'\\' {
                        index += 1;
                        if index < bytes.len() {
                            code[index] = b' ';
                        }
                    } else if bytes[index] == quote {
                        closed = true;
                        index += 1;
                        break;
                    }
                    index += 1;
                }
                if !closed {
                    return Err("unclosed quoted literal");
                }
            }
            b'-' if bytes.get(index + 1) == Some(&b'-') => {
                while index < bytes.len() && bytes[index] != b'\n' {
                    code[index] = b' ';
                    index += 1;
                }
            }
            b'/' if bytes.get(index + 1) == Some(&b'/') => {
                while index < bytes.len() && bytes[index] != b'\n' {
                    code[index] = b' ';
                    index += 1;
                }
            }
            b'/' if bytes.get(index + 1) == Some(&b'*') => {
                code[index] = b' ';
                code[index + 1] = b' ';
                index += 2;
                let mut closed = false;
                while index < bytes.len() {
                    code[index] = b' ';
                    if bytes[index] == b'*' && bytes.get(index + 1) == Some(&b'/') {
                        code[index + 1] = b' ';
                        index += 2;
                        closed = true;
                        break;
                    }
                    index += 1;
                }
                if !closed {
                    return Err("unclosed block comment");
                }
            }
            _ => index += 1,
        }
    }

    String::from_utf8(code).map_err(|_| "query literal is not valid UTF-8")
}

fn statement_starts_with(statement: &str, prefix: &str) -> bool {
    let mut words = statement.split_whitespace();
    prefix.split_whitespace().all(|expected| {
        words
            .next()
            .is_some_and(|word| word.eq_ignore_ascii_case(expected))
    })
}

fn statement_matches(statement: &str, expected: &str) -> bool {
    statement
        .split_whitespace()
        .map(str::to_ascii_uppercase)
        .eq(expected.split_whitespace().map(str::to_ascii_uppercase))
}

#[cfg(test)]
mod tests {
    use proc_macro2::Span;
    use syn::LitStr;

    use super::{MUTATION_TOKENS, mutation_token, read_query_file, top_level_statements};

    #[test]
    fn rejects_every_read_mutation_token() {
        for token in MUTATION_TOKENS {
            assert_eq!(
                mutation_token(&format!("{token} person:test;")),
                Some(*token)
            );
        }
    }

    #[test]
    fn ignores_mutation_words_inside_literals_and_comments() {
        assert_eq!(
            mutation_token("SELECT 'UPDATE'; -- DELETE\nRETURN true;"),
            None
        );
    }

    #[test]
    fn locates_the_final_top_level_return() {
        let statements = top_level_statements(
            "BEGIN TRANSACTION; LET $value = { RETURN 'nested' }; RETURN $value; COMMIT TRANSACTION;",
        )
        .unwrap();

        assert_eq!(statements.len(), 4);
        assert!(statements[2].starts_with("RETURN"));
    }

    #[test]
    fn rejects_absolute_transaction_query_paths() {
        let path = LitStr::new("/tmp/query.surql", Span::call_site());

        let Err(error) = read_query_file(&path) else {
            panic!("absolute path should be rejected");
        };

        assert!(
            error
                .to_string()
                .contains("path must be relative to the caller manifest")
        );
    }
}
