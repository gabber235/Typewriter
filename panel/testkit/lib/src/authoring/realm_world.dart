import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/core/eventually.dart";
import "package:typewriter_testkit/src/core/test_world.dart";
import "package:typewriter_testkit/src/core/trait.dart";
import "package:typewriter_testkit/src/core/world.dart";
import "package:typewriter_testkit/src/traits/authoring/realm.dart";
import "package:typewriter_testkit/src/traits/session.dart";

/// The [testWorld] of [traits] once its signed in session resolved, see
/// [RealmWorld.whenSignedIn].
Future<World> signedInWorld(List<Trait> traits) async {
  final world = testWorld(traits);
  await world.whenSignedIn();
  return world;
}

/// The panel's search over an empty Realm of Ada's organization, once the
/// Realm opened for editing and the first search answered. Every search the
/// Realm receives records in requests, and none finds anything.
Future<
  ({SourceController controller, List<skir.SearchAuthoringRequest> requests})
>
startedEmptyRealmSearch() async {
  final world = testWorld([signedIn(ada, organization: acme), realm()]);
  final requests = <skir.SearchAuthoringRequest>[];
  world.requireRealm.answerSearch = (request) async {
    requests.add(request);
    return skir.SearchAuthoringResponse.createSuccess(
      generation: world.requireRealm.document.generation,
      hits: const [],
      diagnostics: const [],
    );
  };
  await world.openRealmEditing();
  final controller = world.realmSearch();
  await pumpEventQueue();
  return (controller: controller, requests: requests);
}

/// The panel's authoring state of a world's seeded Realm, for application
/// tests that need no widget tree.
extension RealmWorld on World {
  /// Waits until the panel can connect to NATS and knows who is signed in,
  /// so work scoped to the user is not replaced under the test once the
  /// session resolves.
  Future<void> whenSignedIn() async {
    await initialized();
    await container.read(userIdProvider.future);
  }

  /// Keeps [provider] alive until the world is disposed, the way an open
  /// surface keeps what it shows.
  void keepOpen(ProviderListenable<Object?> provider) {
    final subscription = container.listen(provider, (_, _) {});
    addCleanup(subscription.close);
  }

  /// The panel's editing of the seeded Realm once the session resolved, kept
  /// alive until the world is disposed, as an open surface keeps it.
  Future<RealmEditing> openRealmEditing() async {
    await whenSignedIn();
    final subscription = container.listen(
      realmEditingProvider(requireRealm.scope),
      (_, _) {},
    );
    return subscription.read();
  }

  /// Opens [resource] in an autosaving form, makes [change] in it and saves
  /// it; returns the form once the seeded Realm, which holds saves, received
  /// the save and before it answers.
  Future<RealmEditingBinding> autosaveReceived(
    skir.ResourceId resource,
    void Function(AuthoringEdit edit) change,
  ) async {
    final editing = await openRealmEditing();
    final form = editing.form(
      resource,
      policy: EditorCommitPolicy.autosaveChanges,
    )..edit(label: "Autosave", apply: change).requireAccepted();
    unawaited(form.save());
    await eventually(() => expect(requireRealm.saves, isNotEmpty));
    return form;
  }

  /// What the panel's save activity shows across all local work.
  MutationActivityPhase get saveActivity {
    final work = container.read(localWorkProvider);
    return MutationActivityPhase.resolve(work.submissions, work.entries.values);
  }

  /// The panel's publication view of the seeded Realm.
  RealmPublicationProvider get realmPublication => realmPublicationProvider(
    requireRealm.scope.organizationId,
    requireRealm.scope.realmId,
  );

  /// Waits until [realmPublication] is a [T], reviewing [review] when given,
  /// and returns it. Someone must keep the view open while the test waits.
  Future<T> publicationView<T extends RealmPublicationView>({
    skir.PublicationStatus? review,
  }) async {
    final value = await container.eventually(
      realmPublication,
      (view) =>
          view.value is T && (review == null || view.value!.review == review),
      description: "a $T publication view",
    );
    return value.requireValue as T;
  }

  /// The local work entry the panel keeps for the work of [domain], such as
  /// "publication".
  WorkEntryState workEntry(String domain) => container
      .read(localWorkProvider)
      .entries
      .values
      .singleWhere((entry) => entry.id.driver.domain == domain);

  /// The panel's search over the seeded Realm, disposed with the test. It
  /// searches once on its own.
  SourceController realmSearch() {
    final scope = requireRealm.scope;
    final controller = SourceController(
      source: RealmAuthoringSearchSource(
        ref: container.read(_refProvider),
        organizationId: scope.organizationId,
        realmId: scope.realmId,
      ),
      baseSelectors: const [],
    );
    addTearDown(controller.dispose);
    return controller;
  }
}

/// Forms over a Realm editing, as an open inspector holds them.
extension RealmEditingForms on RealmEditing {
  /// Stages [edit] as a new operation [label] that applies whole resources
  /// and admits only its required dependencies, the way an operation
  /// prefixes a draft, and returns the operation's group and how staging went.
  ({EditGroupId group, EditStageResult staged}) stageRequired(
    String label,
    AuthoringEdit edit,
  ) {
    final group = workspace.createGroup(
      label: label,
      policy: EditorCommitPolicy.applyResource,
      commits: EditCommitAdmission.requiredDependencies,
    );
    return (
      group: group,
      staged: stagePrepared(group: group, label: label, edit: edit.prepare()),
    );
  }

  /// The conflict review of [group] once Refresh review read the saved
  /// values again and the review settled, as the review a user sees; throws
  /// why the read failed, or when the group shows no review.
  Future<AuthoringConflictReview> refreshedConflictReview(
    EditGroupId group,
  ) async {
    await refreshConflictReview(group);
    final settled = await EventuallyListenable(this).eventually(
      () => conflictReview(group),
      (review) => review is! EditReviewReading,
      description: "the conflict review of $group to finish reading",
    );
    return switch (settled) {
      EditReviewReady(:final value) => value,
      EditReviewFailed(:final error, :final stackTrace) =>
        Error.throwWithStackTrace(error, stackTrace),
      _ => throw StateError("The group shows no review"),
    };
  }

  /// Opens [resource] in a form saved under [policy], applied with its
  /// resource by default, and closes the form when the test ends.
  RealmEditingBinding form(
    skir.ResourceId resource, {
    EditorCommitPolicy policy = EditorCommitPolicy.applyResource,
  }) {
    final binding = attach(resource, policy: policy);
    addTearDown(binding.detach);
    return binding;
  }

  /// Stages the edit [label] that sets the text at [at] to [value], in a
  /// group of its own saved under [policy].
  EditStageResult setText(
    String label,
    skir.ValueLocation at,
    String value, {
    EditorCommitPolicy policy = EditorCommitPolicy.autosaveChanges,
  }) => edit(
    label: label,
    policy: policy,
    apply: (edit) => edit.set(at, skir.DataValue.wrapStringValue(value)),
  );
}

/// Edits through a form, as its fields make them.
extension RealmEditingFormEdits on RealmEditingBinding {
  /// Stages the edit [label] that sets the text at [at] to [value] in this
  /// form's group.
  EditStageResult setText(String label, skir.ValueLocation at, String value) =>
      edit(
        label: label,
        apply: (edit) => edit.set(at, skir.DataValue.wrapStringValue(value)),
      );
}

/// The world's own [Ref], for panel code that reads providers through one.
final _refProvider = Provider<Ref>((ref) => ref);
