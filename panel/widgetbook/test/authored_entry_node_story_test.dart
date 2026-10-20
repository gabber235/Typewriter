import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_workspace/stories/features/organizations/features/realms/presentation/authored_resource_items.stories.dart";
import "package:widgetbook_workspace/stories/features/organizations/features/realms/presentation/resource_operation_drop_target.stories.dart";

void main() {
  final screenshots = Platform.environment["SAVE_ENTRY_NODE_SCREENSHOTS"] ?? "";
  if (screenshots.isNotEmpty) {
    TestWidgetsFlutterBinding.ensureInitialized();
    setUpAll(() async {
      for (final (family, asset) in [
        (
          "JetBrainsMono",
          "assets/fonts/JetBrains_Mono/JetBrainsMono-VariableFont_wght.ttf",
        ),
        ("Lilex", "assets/fonts/Lilex/Lilex-VariableFont_wght.ttf"),
        ("MaterialIcons", "fonts/MaterialIcons-Regular.otf"),
      ]) {
        await (FontLoader(family)..addFont(rootBundle.load(asset))).load();
      }
    });
  }
  testWidgets(
    "compiled node feedback survives leaving and returning to its graph",
    (tester) async {
      const scene = ValueKey("drag.scene");
      await tester.pumpWidget(
        RepaintBoundary(
          key: scene,
          child: resourceOperationDropTargetExample(delayed: false),
        ),
      );
      await tester.pumpAndSettle();
      final nodes = find.byType(AuthoredGraphItem);
      final source = tester.getCenter(nodes.first);
      final pageTarget = find.byType(ResourcePageDropTarget);
      final destination = tester.getCenter(pageTarget);
      // The nested route blocks sidebar semantics. The foreground border
      // exposes the target's checked availability without that projection.
      final targetFrame = find.descendant(
        of: pageTarget,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is DecoratedBox &&
              widget.position == DecorationPosition.foreground,
        ),
      );
      BoxBorder? targetBorder() =>
          (tester.widget<DecoratedBox>(targetFrame).decoration as BoxDecoration)
              .border;
      final availableBorder = Border.all(
        width: 2,
        color: Theme.of(tester.element(pageTarget)).colorScheme.primary,
      );
      expect(targetBorder(), isNull);
      final sourceContext = tester.element(nodes.first);
      final rootOverlay = Overlay.of(sourceContext, rootOverlay: true);
      expect(Overlay.of(sourceContext), isNot(same(rootOverlay)));
      final container = ProviderScope.containerOf(sourceContext);
      final diagnosticTree = PortableDiagnosticScope.of(sourceContext).tree;
      final originalAnchors = diagnosticTree.snapshot.nodes.length;
      final scope = container.read(selectedAuthoringScopeProvider)!;
      final workspace = container.read(realmEditingProvider(scope));
      final gesture = await tester.startGesture(source);
      await gesture.moveBy(const Offset(25, 0));
      await tester.pump();
      await gesture.moveTo(destination);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(targetBorder(), availableBorder);
      expect(find.text("Welcome to the village"), findsNWidgets(2));
      final previewContext = tester.element(
        find.text("Welcome to the village").last,
      );
      expect(Overlay.of(previewContext), same(rootOverlay));
      expect(ProviderScope.containerOf(previewContext), same(container));
      expect(
        PortableDiagnosticScope.of(previewContext).tree,
        isNot(same(diagnosticTree)),
      );
      expect(diagnosticTree.snapshot.nodes.length, originalAnchors);
      expect(Focus.of(previewContext).canRequestFocus, isFalse);
      final previewBounds = tester.getRect(
        find.byType(PortableDiagnosticPreview),
      );
      final sidebarBounds = tester.getRect(find.byType(ResourcePageDropTarget));
      final sample = Offset(sidebarBounds.right - 20, previewBounds.top + 10);
      expect(previewBounds.contains(sample), isTrue);
      expect(sidebarBounds.contains(sample), isTrue);
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(scene),
      );
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1);
        final bytes = (await image.toByteData(
          format: ImageByteFormat.rawRgba,
        ))!;
        final point = boundary.globalToLocal(sample);
        final offset = (point.dy.floor() * image.width + point.dx.floor()) * 4;
        final pixel = List.generate(
          4,
          (channel) => bytes.getUint8(offset + channel),
        );
        image.dispose();
        expect(pixel, [231, 76, 60, 255]);
      });
      await gesture.moveTo(source);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text("Welcome to the village"), findsOneWidget);
      expect(find.byType(PortableDiagnosticPreview), findsNothing);
      expect(diagnosticTree.snapshot.nodes.length, originalAnchors);
      expect(targetBorder(), isNull);
      await gesture.moveTo(destination);
      await tester.pumpAndSettle();
      expect(targetBorder(), availableBorder);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        workspace.document.relations.children[compiledEntryDestinationId],
        contains(compiledEntryFirstId),
      );
      expect(find.text("Welcome to the village"), findsNothing);
    },
  );
  for (final brightness in Brightness.values) {
    for (final narrow in [false, true]) {
      testWidgets(
        "compiled owned node story is interactive in $brightness with narrow $narrow",
        (tester) async {
          tester.view.devicePixelRatio = 1;
          await tester.binding.setSurfaceSize(const Size(1000, 600));
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(() => tester.binding.setSurfaceSize(null));
          const scene = ValueKey("entry.scene");
          await tester.pumpWidget(
            Theme(
              data: buildTheme(brightness),
              child: RepaintBoundary(
                key: scene,
                child: compiledEntryGraphStory(narrow: narrow),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.byType(AuthoredGraphItem), findsNWidgets(2));
          expect(find.byType(ResourcePageDropTarget), findsOneWidget);
          expect(find.byType(Card), findsNothing);
          final nodes = find.byType(AuthoredGraphItem);
          await tester.tap(nodes.first);
          await tester.pumpAndSettle();
          final container = ProviderScope.containerOf(
            tester.element(nodes.first),
          );
          expect(
            container.read(selectionProvider).single.id,
            compiledEntryFirstId.value,
          );
          final state = tester
              .widget<PresentationInteractionScope>(
                find
                    .descendant(
                      of: nodes.first,
                      matching: find.byType(PresentationInteractionScope),
                    )
                    .first,
              )
              .value;
          expect(state.selected, isTrue);
          expect(state.focused, isTrue);
          expect(tester.takeException(), isNull);
          if (screenshots.isNotEmpty) {
            final boundary = tester.renderObject<RenderRepaintBoundary>(
              find.byKey(scene),
            );
            await tester.runAsync(() async {
              final image = await boundary.toImage();
              final bytes = await image.toByteData(format: ImageByteFormat.png);
              final target = File(
                "$screenshots/${brightness.name}_${narrow ? 'narrow' : 'wide'}.png",
              );
              await target.parent.create(recursive: true);
              await target.writeAsBytes(bytes!.buffer.asUint8List());
              image.dispose();
            });
          }
        },
      );
    }
  }
}
