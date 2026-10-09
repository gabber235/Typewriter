import "package:typewriter_panel/typewriter_panel.dart";

part "presentation_interaction_scope.freezed.dart";

// State getters are supplied by the generated Freezed mixin.
// ignore: avoid_classes_with_only_static_members
@freezed
abstract class PresentationInteraction with _$PresentationInteraction {
  const factory PresentationInteraction({
    @Default(false) bool selected,
    @Default(false) bool hovered,
    @Default(false) bool focused,
    @Default(false) bool pressed,
    @Default(false) bool disabled,
  }) = _PresentationInteraction;

  const PresentationInteraction._();

  static PresentationInteraction fromWidgetStates(Set<WidgetState> states) =>
      PresentationInteraction(
        selected: states.contains(WidgetState.selected),
        hovered: states.contains(WidgetState.hovered),
        focused: states.contains(WidgetState.focused),
        pressed: states.contains(WidgetState.pressed),
        disabled: states.contains(WidgetState.disabled),
      );
}

/// Publishes an owner's observed state without inheriting another owner's flags.
///
/// The nearest scope replaces the outer observation. Controllers remain owned
/// by the interactive widget; presentation styling cannot change their state.
class PresentationInteractionScope extends InheritedWidget {
  const PresentationInteractionScope({
    required this.value,
    required super.child,
    super.key,
  });

  final PresentationInteraction value;

  static PresentationInteraction of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<PresentationInteractionScope>()
          ?.value ??
      const PresentationInteraction();

  @override
  bool updateShouldNotify(PresentationInteractionScope previous) =>
      previous.value != value;
}
