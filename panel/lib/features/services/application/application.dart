/// Organization service application state, resource editing, and topology views.
///
/// This library joins canonical service identity data with the separately
/// observed host topology. Providers own projections, repositories own the
/// authenticated mutation boundary, and inspectors expose only the mutation
/// paths that their resource owns. Runtime Realm and engine entries remain
/// observational and are navigated through their owning host and service.
library;

export "services.dart";
