use std::{fs, path::Path};

const MUTATIONS: [&str; 6] = ["CREATE", "DELETE", "INSERT", "RELATE", "UPDATE", "UPSERT"];

#[test]
fn production_mutations_use_retrying_transactions() {
    let backend = Path::new(env!("CARGO_MANIFEST_DIR"))
        .parent()
        .expect("wasmcloud utils is inside the backend directory");

    for component in ["access", "organization", "service"] {
        inspect_directory(&backend.join(component));
    }
}

fn inspect_directory(directory: &Path) {
    for entry in fs::read_dir(directory).expect("production directory must be readable") {
        let path = entry.expect("directory entry must be readable").path();
        if path.is_dir() {
            inspect_directory(&path);
            continue;
        }
        if path.extension().is_none_or(|extension| extension != "rs") {
            continue;
        }

        inspect_source(&path);
    }
}

fn inspect_source(path: &Path) {
    let source = fs::read_to_string(path).expect("production source must be readable");
    for mutation in MUTATIONS {
        for (offset, _) in source.match_indices(mutation) {
            let prefix = &source[..offset];
            let direct_query = call_position(prefix, "query(");
            let retrying_transaction = prefix.rfind("retrying_transaction(");
            if direct_query.is_none() && retrying_transaction.is_none() {
                continue;
            }

            let query_start = direct_query
                .max(retrying_transaction)
                .expect("query start exists");
            if source[query_start..offset].contains(".execute()") {
                continue;
            }

            assert!(
                retrying_transaction > direct_query,
                "{} contains a {mutation} mutation outside retrying_transaction",
                path.display()
            );
        }
    }
}

fn call_position(source: &str, call: &str) -> Option<usize> {
    source
        .match_indices(call)
        .filter_map(|(offset, _)| {
            let preceding = source[..offset].chars().next_back();
            preceding
                .is_none_or(|character| !character.is_alphanumeric() && character != '_')
                .then_some(offset)
        })
        .last()
}
