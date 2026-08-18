use serde::Deserialize;

#[test]
fn database_query_compile_boundaries() {
    let tests = trybuild::TestCases::new();
    tests.pass("tests/ui/query/pass/*.rs");
    tests.compile_fail("tests/ui/query/fail/*.rs");
}

#[derive(Debug, Deserialize)]
#[serde(tag = "kind", rename_all = "snake_case")]
enum TaggedOutcome {
    Success { value: bool },
}

#[test]
fn malformed_tagged_output_is_rejected() {
    assert!(serde_json::from_value::<TaggedOutcome>(serde_json::json!({ "value": true })).is_err());
    assert!(
        serde_json::from_value::<TaggedOutcome>(serde_json::json!({
            "kind": "unknown",
            "value": true,
        }))
        .is_err()
    );
}

#[test]
fn valid_tagged_output_decodes() {
    let outcome = serde_json::from_value::<TaggedOutcome>(serde_json::json!({
        "kind": "success",
        "value": true,
    }))
    .unwrap();

    assert!(matches!(outcome, TaggedOutcome::Success { value: true }));
}
