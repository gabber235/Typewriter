/// Public entry point for the reusable search capability.
///
/// The application layer owns query state, source composition, actions, and
/// lifecycle. The domain layer parses input and turns hierarchical source
/// nodes into stable rows. Presentation widgets consume the resulting state.
library;

export "application/application.dart";
export "domain/domain.dart";
export "presentation/presentation.dart";
export "search_engine.dart";
