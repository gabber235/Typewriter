/// Public page capability for book navigation, metadata authoring, and editors.
///
/// Consumers should read page data through the projected providers when local
/// work must be visible. The authoring session remains the canonical source,
/// and the nested editor feature owns page element content.
library;

export "application/application.dart";
export "domain/domain.dart";
export "features/features.dart";
export "presentation/presentation.dart";
