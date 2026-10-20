//! Broker permissions collected for one connection.

use std::collections::BTreeSet;

/// The subjects a connection may publish to and subscribe to.
///
/// The generated `grant` functions of each route scope insert the subjects their role's routes
/// derive; the sets keep every subject once and iterate in a stable order.
#[derive(Debug, Default)]
pub struct GrantSet {
    pub publish: BTreeSet<String>,
    pub subscribe: BTreeSet<String>,
}
