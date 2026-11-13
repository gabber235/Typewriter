import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";

/// The real panel over a world built from [traits], opened [at] a location,
/// as a Widgetbook story.
///
/// A story is a [PanelStage]: the same app, router, theme and doubles a
/// widget test pumps. The world lives as long as the story's knobs keep their
/// values, so clicks through a story (saves, creations, failures) stay in its
/// doubles; changing a knob, or the Widgetbook theme, starts a fresh world.
///
/// Rive animations play in the browser and render as empty boxes in story
/// tests. The Widgetbook theme chooses the appearance unless [traits] set one. A
/// window trait renders the panel at that window's size, scaled down when
/// the preview is smaller. The stage never reports its routes to the browser,
/// so Widgetbook keeps its own address.
class Story extends HookWidget {
  const Story(this.traits, {this.at, super.key});

  /// The sources of the world, such as `signedIn(ada, organization: acme)`.
  final List<Trait> traits;

  /// Where the panel opens; null opens the world's home.
  final PanelLocation? at;

  @override
  Widget build(BuildContext context) {
    final widgetbook = WidgetbookState.maybeOf(context);
    final setsAppearance = traits.any((trait) => trait.slot == Slot.appearance);
    final darkTheme =
        !setsAppearance && Theme.of(context).brightness == Brightness.dark;
    // A new story, knob value or theme starts a new world.
    final identity =
        "${widgetbook?.path}?${widgetbook?.queryParams["knobs"]}&dark=$darkTheme";
    final world = useMemoized(() {
      final world = World.build([
        ...traits,
        if (darkTheme) dark,
        // A browser runs the real Rive runtime; a test runner has none.
        if (kIsWeb) liveAnimations,
      ]);
      // The panel's router would read and rewrite the browser address, where
      // Widgetbook keeps the open story and its knobs.
      world.container
          .read(appRouterProvider)
          .routeInfoProvider(
            initialRouteInformation: RouteInformation(uri: Uri.parse("/")),
            neglectWhen: (_) => true,
          );
      return world;
    }, [identity]);
    final stage = PanelStage.world(world, at: at, key: ValueKey(identity));
    if (!traits.any((trait) => trait.slot == Slot.window)) return stage;
    return FittedBox(
      child: SizedBox.fromSize(
        size: world.window,
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(size: world.window),
          child: stage,
        ),
      ),
    );
  }
}

/// Knobs that choose the traits of a [Story].
extension StoryKnobs on KnobsBuilder {
  /// A dropdown named [label] over [options], each a named set of traits;
  /// returns the traits of the chosen option, [initial] or the first.
  List<Trait> traits(
    String label,
    Map<String, List<Trait>> options, {
    String? initial,
  }) {
    final chosen = object.dropdown<String>(
      label: label,
      options: options.keys.toList(),
      initialOption: initial ?? options.keys.first,
    );
    return options[chosen]!;
  }

  /// The Width segments over [widths], each a width by the name the knob
  /// shows; returns the chosen width, the first one at start.
  double width(Map<String, double> widths) {
    final chosen = object.segmented<String>(
      label: "Width",
      options: widths.keys.toList(),
      initialOption: widths.keys.first,
    );
    return widths[chosen]!;
  }

  /// The seed story data is generated from; another seed reshuffles it, the
  /// same seed shows the same data on every reload.
  int seed({int initialValue = 1}) => this.int.slider(
    label: "Seed",
    initialValue: initialValue,
    min: 1,
    max: 50,
  );
}

/// How a form field story shows its field: whether it is enabled or read
/// only, and how wide it is.
final class FieldKnobs {
  const FieldKnobs({
    this.enabled = true,
    this.readOnly = false,
    this.width = 420,
  });

  final bool enabled;
  final bool readOnly;
  final double width;
}

/// The knobs every form field story offers.
extension FieldStoryKnobs on KnobsBuilder {
  /// The Enabled, Read only and Field width knobs.
  FieldKnobs field() => FieldKnobs(
    enabled: boolean(label: "Enabled", initialValue: true),
    readOnly: boolean(label: "Read only", initialValue: false),
    width: this.double.slider(
      label: "Field width",
      initialValue: 420,
      min: 260,
      max: 640,
    ),
  );
}
