use component_test::{TestContext, component_fixture, component_test};

#[component_fixture(
    id = "example",
    primary(package = "example-component", target = "example_component")
)]
struct Example;

#[component_test(Example)]
#[case::same(0)]
#[case::same(1)]
async fn duplicate(_context: &mut TestContext<Example>, value: u8) {
    let _ = value;
}

fn main() {}
