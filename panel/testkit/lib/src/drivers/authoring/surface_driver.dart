import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/drivers/panel_driver.dart";

/// Moving between the surfaces of the seeded Realm.
extension SurfaceDrivers on PanelDriver {
  /// Opens the surface of [resource] in the seeded Realm, the way a link to
  /// it does, with [selected] selected when given.
  Future<void> openSurface(
    skir.ResourceId resource, {
    skir.ResourceId? selected,
  }) async {
    await container
        .read(appRouterProvider)
        .navigate(
          const RealmRouteTree().surface(
            world.requireRealm.scope,
            SurfaceTarget.resource(routed: resource, selected: selected),
          ),
        );
    await settle();
  }

  /// The seeded Realm's saved document once the panel saved [saves] edits
  /// to it.
  Future<AuthoringDocument> savedAfter({int saves = 1}) async {
    final realm = world.requireRealm;
    await eventually(() => expect(realm.saves, hasLength(saves)));
    await settle();
    expect(realm.saves, hasLength(saves));
    return realm.document;
  }

  /// Drags the item [label] onto the middle of [target] and drops it.
  Future<void> dragItem(String label, Rect target) async {
    final gesture = await tester.startGesture(item(label).rect.center);
    await gesture.moveBy(const Offset(25, 0));
    await tester.pump();
    await gesture.moveTo(target.center);
    await tester.pump();
    await gesture.up();
    await settle();
  }

  /// Fills the open operation form's [field] with [value] and submits the
  /// form with the keyboard: Tab passes Cancel, then reaches Submit.
  Future<void> submitOperationForm(String field, String value) async {
    await tester.enterText(
      find.descendant(
        of: find.bySemanticsLabel(field),
        matching: find.byType(EditableText),
      ),
      value,
    );
    await settle();
    await press(LogicalKeyboardKey.tab);
    expect(hasFocusOn("Cancel"), isTrue);
    await press(LogicalKeyboardKey.tab);
    expect(hasFocusOn("Submit"), isTrue);
    await press(LogicalKeyboardKey.enter);
  }

  /// The saved content as this panel's edits leave it, before they are
  /// saved: what every surface of the Realm shows.
  AuthoringDocument get working => container
      .read(workingAuthoringDocumentProvider(world.requireRealm.scope))
      .requireValue;
}

/// Showing components above the open surface of the Realm.
extension AboveSurfaceDrivers on PanelDriver {
  /// Shows [child] above the open surface, inside the panel and its open
  /// Realm, for a component no surface of the seeded catalog shows, such as
  /// a resource another pane lists. It stays until the test ends.
  Future<void> showAbove(
    Widget child, {
    Alignment at = Alignment.center,
  }) async {
    // A route of its own gives the component a focus scope, so focus returns
    // to it after a dialog closes, as it does on a surface.
    unawaited(
      container
          .read(appRouterProvider)
          .navigatorKey
          .currentState!
          .push(
            PageRouteBuilder<void>(
              opaque: false,
              pageBuilder: (context, _, _) => Align(
                alignment: at,
                child: Material(child: child),
              ),
            ),
          ),
    );
    await settle();
  }

  /// Shows [resource] of the seeded Realm as a draggable item labeled
  /// [label] above the open surface, the way a resource another pane lists
  /// can be dragged onto it; returns where it is on screen.
  ///
  /// The item floats in the window's overlay, so the surface below still
  /// receives the drag.
  Future<Rect> showDraggable(skir.ResourceId resource, String label) async {
    final scope = world.requireRealm.scope;
    final entry = OverlayEntry(
      builder: (context) => Positioned(
        left: 8,
        bottom: 8,
        child: Material(
          child: ResourceDragSource(
            drag: ResourceDrag(
              scope: scope,
              primary: AuthoringResourceIdentifier.inScope(scope, resource),
              subjects: [resource],
            ),
            enabled: true,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(label),
            ),
          ),
        ),
      ),
    );
    container
        .read(appRouterProvider)
        .navigatorKey
        .currentState!
        .overlay!
        .insert(entry);
    addTearDown(() {
      if (entry.mounted) entry.remove();
    });
    await settle();
    return tester.getRect(find.text(label));
  }
}
