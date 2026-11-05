//! Prints the fixtures and tests the suite registers, as JSON, for `cargo xtask components`.

use typewriter_component_tests as _;

fn main() -> anyhow::Result<()> {
    let fixtures = component_test::registered_fixtures()?;
    let tests = component_test::registered_tests()?;
    let catalog = serde_json::json!({
        "fixtures": fixtures,
        "tests": tests
            .iter()
            .map(|test| serde_json::json!({
                "fixture": test.fixture_id,
                "name": test.libtest_name(),
                "case": test.case,
            }))
            .collect::<Vec<_>>(),
    });
    println!("{catalog}");
    Ok(())
}
