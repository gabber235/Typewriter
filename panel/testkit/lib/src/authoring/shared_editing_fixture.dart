import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/authoring/document_builder.dart";
import "package:typewriter_testkit/src/doubles/realm.dart";
import "package:typewriter_testkit/src/authoring/application/catalog_fixtures.dart";
import "package:typewriter_testkit/src/support/held_realm_editing.dart";

/// Several authored resources of one kind edited together, the way the
/// inspector edits a selection: one Realm editing binding and one
/// presentation host over all of [resources], in a Realm that holds every
/// save until the test answers it. Everything lives until the test ends.
final class SharedAuthoredEditing {
  SharedAuthoredEditing(
    AuthoringDocument document, {
    required List<skir.ResourceId> resources,
    Future<skir.PreparedValue> Function(skir.ValuePreparationRequest)?
    prepareValue,
  }) {
    final held = heldRealmEditing(document, id: "shared", name: "Shared");
    realm = held.realm;
    workspace = held.workspace;
    binding = workspace.attach(
      resources.first,
      editedWith: resources.skip(1).toList(),
      policy: EditorCommitPolicy.applyResource,
    );
    host = AuthoredPresentationHost(
      resource: resources.first,
      editedWith: resources.skip(1).toList(),
      source: workspace.document,
      material: skir.PresentationMaterial.defaultInstance,
      role: skir.PresentationRole.inspector,
      budget: skir.EvaluationBudget(maxSteps: 100, maxCollectionItems: 100),
      capabilities: const PortablePresentationCapabilities(),
      prepareValue: prepareValue,
      edit: binding,
    );
    addTearDown(host.dispose);
    addTearDown(binding.detach);
  }

  /// The Realm that holds every save.
  late final FakeRealm realm;

  /// The editing of the document.
  late final RealmEditing workspace;

  /// The one editing binding over every selected resource.
  late final RealmEditingBinding binding;

  /// The one presentation host over every selected resource.
  late final AuthoredPresentationHost host;

  /// The value the selected resources share, as the presentation reads it.
  PortablePresentationBinding get shared =>
      host.document.bindings[configuredValueBindingId]!;

  /// What a control invoked from the current presentation acts with.
  PortableInvocationContext get context => host.rootInvocation;

  /// The reference to the field path [fields] of the shared value.
  skir.BindingRef at(List<String> fields) => skir.BindingRef(
    bindingId: configuredValueBindingId,
    path: skir.ValuePath(
      segments: [
        for (final name in fields) skir.PathSegment.createField(name: name),
      ],
    ),
  );

  /// Where the shared value's field path [fields] lives, as the controls
  /// address it.
  skir.ValueLocation location(List<String> fields) =>
      host.location(at(fields), context: context)!;

  /// Saves the staged work and returns the one edit the Realm received.
  Future<skir.PreparedEdit> save(WidgetTester tester) async {
    unawaited(binding.save());
    await tester.pump();
    return realm.saves.single.edit;
  }

  /// Saves the staged work, lets the Realm confirm it and returns the saved
  /// document.
  Future<AuthoringDocument> saved(WidgetTester tester) async {
    final saving = binding.save();
    await tester.pump();
    realm.saves.single.confirm();
    await tester.pump();
    await saving;
    return realm.document;
  }
}

/// The first of the [sharedNotes].
final sharedNoteFirst = skir.ResourceId(value: "note:first");

/// The second of the [sharedNotes].
final sharedNoteSecond = skir.ResourceId(value: "note:second");

/// Two notes that share a body and differ in their title, each with an
/// unfilled reward a Reward of the form Coins can fill.
AuthoringDocument sharedNotes() => authoredDoc(
  [
    authoredRecord(sharedNoteFirst, {
      "title": textValue("Morning"),
      "body": textValue("Shared"),
      "reward": skir.DataValue.unfilled,
    }, type: typeUse("Note")),
    authoredRecord(sharedNoteSecond, {
      "title": textValue("Evening"),
      "body": textValue("Shared"),
      "reward": skir.DataValue.unfilled,
    }, type: typeUse("Note")),
  ],
  catalog: authoredCatalog([
    declaredRecord("Reward", open: true),
    declaredRecord(
      "Coins",
      fields: {"amount": skir.ScalarKind.text},
      parents: ["Reward"],
    ),
    declaredRecord(
      "Note",
      fields: {
        "title": skir.ScalarKind.text,
        "body": skir.ScalarKind.text,
        "reward": "Reward",
      },
    ),
  ]),
).document;
