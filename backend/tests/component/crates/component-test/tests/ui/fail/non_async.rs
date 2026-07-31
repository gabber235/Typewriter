use component_test::{TestContext, component_fixture, component_test};

#[component_fixture(
    id = "example",
    primary(package = "example-component", target = "example_component")
)]
struct Example;

#[component_test(Example)]
fn synchronous(_context: &mut TestContext<Example>) {}

fn main() {}
