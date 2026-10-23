/// Organization projections, mutations, collaboration presence, and scoped resource owners.
///
/// Providers in this module own server reconciliation and lifecycle. Presentation
/// code consumes their state and invokes their operations without duplicating
/// transport or cache ownership.
library;

export "organization.dart";
export "organization_presence.dart";
export "user_join_requests.dart";
