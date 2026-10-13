import "package:typewriter_panel/typewriter_panel.dart";

/// Observes native paint states after the frame that published them.
/// Native controls may publish disabled state during their own build.
/// The controller owns state; this hook only retains an immutable observation.
ValueListenable<Set<WidgetState>> useWidgetStateObservation(
  WidgetStatesController controller,
) {
  final observation = useValueNotifier(
    Set<WidgetState>.unmodifiable(controller.value),
  );
  useEffect(() {
    var active = true;
    var pending = false;
    void observe() {
      if (pending) return;
      pending = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        pending = false;
        if (!active || setEquals(observation.value, controller.value)) return;
        observation.value = Set<WidgetState>.unmodifiable(controller.value);
      });
      WidgetsBinding.instance.ensureVisualUpdate();
    }

    controller.addListener(observe);
    observe();
    return () {
      active = false;
      controller.removeListener(observe);
    };
  }, [controller, observation]);
  return observation;
}
