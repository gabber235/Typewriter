// Organization membership management includes the live membership projection,
// role assignment controls, and responsive member administration screens.
//
// The application providers own the observed membership projections. Widgets
// submit prepared repository commands through shared local work and own their
// transient selection, focus, and expansion state. Join codes and join requests
// remain separate child capabilities exported by this feature boundary.

export "application/application.dart";
export "features/features.dart";
export "presentation/presentation.dart";
