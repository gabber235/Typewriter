//! The query macros accept literal reads and committed transactions, and reject mutating reads,
//! non literal queries, uncommitted transactions and outcomes that cannot be decoded, at compile
//! time.

#[test]
fn database_query_compile_boundaries() {
    let tests = trybuild::TestCases::new();
    tests.pass("tests/ui/query/pass/*.rs");
    tests.compile_fail("tests/ui/query/fail/*.rs");
}
