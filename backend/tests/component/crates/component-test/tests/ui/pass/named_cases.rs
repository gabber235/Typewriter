use component_test::{FixtureBuilder, FixtureSpec, TestContext, component_fixture, component_test};

#[component_fixture(
    id = "example",
    primary(package = "example-component", target = "example_component"),
    dependency(package = "helper", target = "helper"),
    affected_paths("backend/example/")
)]
struct Example;

impl FixtureSpec for Example {
    fn configure(builder: FixtureBuilder<Self>) -> FixtureBuilder<Self> {
        builder.dependency("helper", |configuration| configuration)
    }
}

#[component_test(Example)]
#[case::zero(0)]
#[case::one(1)]
async fn parameterized(_context: &mut TestContext<Example>, value: u8) {
    assert!(value <= 1);
}

fn main() {}
