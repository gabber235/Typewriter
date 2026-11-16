import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/authoring/application/application.dart";
import "package:typewriter_testkit/src/authoring/realm_world.dart";
import "package:typewriter_testkit/src/drivers/authoring/surface_driver.dart";
import "package:typewriter_testkit/src/drivers/panel_driver.dart";

/// Editing the seeded Realm through components shown above its surface.
extension EditingDrivers on PanelDriver {
  /// The panel's editing of the seeded Realm, the one every surface of the
  /// open Realm edits through.
  Future<RealmEditing> openEditing() async {
    final editing = await world.openRealmEditing();
    await settle();
    return editing;
  }

  /// Shows the inspection of [fixture]'s resource for [role] above the
  /// surface, editing it through the panel's editing under [policy], and
  /// returns that editing.
  Future<RealmEditing> inspectDraft(
    AuthoredDraft fixture, {
    EditorCommitPolicy policy = EditorCommitPolicy.autosaveChanges,
    skir.PresentationRole role = skir.PresentationRole.inspector,
  }) async {
    final editing = await openEditing();
    editing.form(fixture.draft.resources.keys.first, policy: policy);
    await showAbove(
      Scaffold(
        body: AuthoredResourceInspection(
          resource: fixture.resource,
          workspace: editing,
          commands: world.requireRealm.commands,
          role: role,
          commitPolicy: policy,
        ),
      ),
    );
    return editing;
  }

  /// Shows the inspector editor of [fixture]'s resource above the surface,
  /// with a budget no test content exhausts, and returns the form it edits.
  Future<RealmEditingBinding> editDraft(AuthoredDraft fixture) async {
    final binding = (await openEditing()).form(fixture.resource);
    await showAbove(
      Scaffold(
        body: AuthoredResourceEditor(
          resource: fixture.resource,
          document: binding.document,
          edit: binding,
          role: skir.PresentationRole.inspector,
          budget: skir.EvaluationBudget(
            maxSteps: 10000,
            maxCollectionItems: 10000,
          ),
        ),
      ),
    );
    return binding;
  }

  /// Shows [resource] of [document] in a workspace editor that cannot edit,
  /// above the surface, with a small evaluation budget.
  Future<void> showDocumentEditor(
    skir.ResourceId resource,
    AuthoringDocument document,
  ) => showAbove(
    Scaffold(
      body: AuthoredResourceEditor(
        resource: resource,
        document: document,
        role: skir.PresentationRole.workspace,
        budget: skir.EvaluationBudget(maxSteps: 1000, maxCollectionItems: 100),
      ),
    ),
  );

  /// Closes the component [AboveSurfaceDrivers.showAbove] showed last, the
  /// way closing a pane unmounts it, and leaves the Realm open.
  Future<void> closeAbove() async {
    container.read(appRouterProvider).navigatorKey.currentState!.pop();
    await settle();
  }

  /// Types "Mine" into [fixture]'s first field, lets its save be refused
  /// because someone else saved "Theirs" meanwhile, and opens the review of
  /// the refused save. Returns the panel's editing.
  Future<RealmEditing> reviewRefusedSave(AuthoredDraft fixture) async {
    final editing = await inspectDraft(fixture);
    final saved = world.requireRealm;
    await fieldAt(0).type("Mine");
    await tester.pump(const Duration(milliseconds: 250));
    await settle();
    // The panel learns of "Theirs" only by reading the saved values again,
    // which reports them to everything that shows them, as the Realm's
    // session does.
    saved.answerRefresh = () {
      saved.remoteChange(
        (edit) => edit.set(
          authoredFieldLocation(fixture.resource, ["title"]),
          skir.DataValue.wrapStringValue("Theirs"),
        ),
      );
      return Future.value(saved.document);
    };
    saved.saves.single.reject(
      skir.CommitPreparedEditResponse.wrapConflictError(const []),
    );
    await settle();
    await tapOn(find.text("Review changes"));
    return editing;
  }
}
