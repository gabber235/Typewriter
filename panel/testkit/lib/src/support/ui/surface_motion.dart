import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

/// The sidebar with focus inside its navigation, where its resize keys act.
final sidebarWithNavigation = SizedBox.fromSize(
  size: desktopWindow,
  child: Align(
    alignment: Alignment.centerLeft,
    child: Sidebar(
      child: Focus(
        autofocus: true,
        child: Semantics(
          label: "Navigation",
          container: true,
          child: const SizedBox.expand(),
        ),
      ),
    ),
  ),
);

/// A "Running" button at the top left whose popover shows "Stopped".
final class PopoverChip extends StatelessWidget {
  const PopoverChip({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: AnchoredPopup(
          builder: (context, show) =>
              TextButton(onPressed: show, child: const Text("Running")),
          popupBuilder: (context, close) =>
              const SizedBox(width: 200, height: 120, child: Text("Stopped")),
        ),
      ),
    ),
  );
}

/// A "Page heading" over an "Open" button whose dialog says "Dialog title",
/// the page sinking back behind it.
final class DialogBackdropPage extends StatelessWidget {
  const DialogBackdropPage({super.key});

  @override
  Widget build(BuildContext context) => DialogBackdrop(
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Page heading"),
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showAdvancedDialog<void>(
                context: context,
                builder: (_) => const Dialog(child: Text("Dialog title")),
              ),
              child: const Text("Open"),
            ),
          ),
        ],
      ),
    ),
  );
}

/// A delete icon whose tooltip reads "Delete the page".
const deletePageTooltip = PanelTooltip(
  message: "Delete the page",
  child: Icon(Icons.delete),
);

/// A 200 by 120 "Target" button with a context menu of Rename and Delete;
/// each choice is added to [chosen].
final class ContextMenuTarget extends StatelessWidget {
  const ContextMenuTarget(this.chosen, {super.key});

  final List<String> chosen;

  @override
  Widget build(BuildContext context) => Center(
    child: ContextMenuRegion(
      items: [
        MenuItem(label: "Rename", onPressed: () => chosen.add("Rename")),
        MenuItem(label: "Delete", onPressed: () => chosen.add("Delete")),
      ],
      builder: (context, menu, child) => Button(
        face: ButtonFace.bare,
        label: "Target",
        onPressed: () {},
        child: const SizedBox(width: 200, height: 120),
      ),
    ),
  );
}

/// Surface motion as a user meets it.
extension SurfaceMotion on WidgetTester {
  /// A graph viewport controller over an empty canvas.
  Future<GraphViewportController> showViewport({required bool reduced}) async {
    GraphViewportController? controller;
    await pumpPanel(
      [if (reduced) reducedMotion],
      at: PanelLocation.component(
        HookBuilder(
          builder: (context) {
            controller = useGraphViewportController(
              initialTransform: Matrix4.identity(),
            );
            return const SizedBox();
          },
        ),
      ),
    );
    return controller!;
  }

  /// Where the tooltip [message] paints on its first frame after a mouse
  /// rests on [target] for the tooltip wait.
  Future<Rect> firstFrameOfTooltip(String message, Finder target) async {
    final mouse = await createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(getCenter(target));
    await pump();
    await pump(element(target).timing.tooltipWait);
    await pump();
    return getRect(find.text(message));
  }

  /// An organization with a join code, a member and a join request, whose
  /// sidebar moves between its pages.
  Future<PanelDriver> pumpOrganizationPages({bool reduced = false}) =>
      pumpPanel([
        signedIn(ada, organization: acme),
        membership(
          joinCodes: [joinCode("spring")],
          members: [member("ken")],
          joinRequests: [joinRequest("lea", name: "lea")],
        ),
        if (reduced) reducedMotion,
      ]);

  /// Follows the sidebar link [link] and shows the first frame of the page.
  Future<void> followLink(String link) async {
    await tap(find.text(link).first);
    await pump();
    await pump();
  }

  /// How far the first row that ripples in still is from its place.
  Offset firstRowShift() {
    final rows = find.byWidgetPredicate(
      (widget) => widget is Enter && widget.token == MotionToken.loadIn,
    );
    expect(rows, findsWidgets, reason: "the page ripples its rows in");
    final transform = widget<Transform>(
      find.descendant(of: rows.first, matching: find.byType(Transform)).first,
    );
    final translation = transform.transform.getTranslation();
    return Offset(translation.x, translation.y);
  }
}

/// Where the viewport's top left sits in the scene.
Offset viewportOrigin(GraphViewportController controller) =>
    controller.transformation.toScene(Offset.zero);

/// Page [index] of a directional content switcher: a 200 wide box of
/// [height] reading "Page index".
DirectionalContentSwitcher switcherPage(int index, {double height = 80}) =>
    DirectionalContentSwitcher(
      index: index,
      child: SizedBox(
        key: ValueKey(index),
        width: 200,
        height: height,
        child: Text("Page $index"),
      ),
    );
