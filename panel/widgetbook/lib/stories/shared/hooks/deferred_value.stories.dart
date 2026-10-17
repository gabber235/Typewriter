import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "Timing policies", type: CoalesceUpdates)
Widget deferredValueUseCase(BuildContext context) => DeferredValueStory(
  duration: Duration(
    milliseconds: context.knobs.int.slider(
      label: "Window milliseconds",
      initialValue: 100,
      min: 0,
      max: 500,
    ),
  ),
);

/// Drives both policies from the same finite burst of inputs.
class DeferredValueStory extends HookWidget {
  const DeferredValueStory({
    this.duration = const Duration(milliseconds: 100),
    super.key,
  });
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final incoming = useState(0);
    final burst = useRef<Timer?>(null);
    useEffect(
      () =>
          () => burst.value?.cancel(),
      const [],
    );
    final windowed = useDeferredValue(
      incoming.value,
      policy: CoalesceUpdates<int>(duration: duration),
    );
    final debounced = useDeferredValue(
      incoming.value,
      policy: DebounceUpdates<int>(duration: duration),
    );
    return FakeApp(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Incoming: ${incoming.value}"),
            Text("Window: $windowed"),
            Text("Debounce: $debounced"),
            TextButton(
              onPressed: () => incoming.value++,
              child: const Text("Change once"),
            ),
            TextButton(
              onPressed: () {
                burst.value?.cancel();
                incoming.value++;
                burst.value = Timer.periodic(const Duration(milliseconds: 30), (
                  timer,
                ) {
                  incoming.value++;
                  if (timer.tick == 9) timer.cancel();
                });
              },
              child: const Text("Burst of 10 changes"),
            ),
          ],
        ),
      ),
    );
  }
}
