/// A second user acting while the scenario's panel stays open: the same panel
/// code on its own session and broker connection, without a screen.
///
/// A scenario that needs something to change under the user's eyes, such as
/// their membership being removed, has the other person act here, so the
/// panel on screen learns of it the way it would from another machine.
library;

import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

import "panel.dart";
import "stack.dart" as stack;
import "wait.dart";

/// The fixture user [username] signed in on a session of their own, until
/// the scenario ends.
Future<RemoteSession> remoteSession(String username) async {
  final session = RemoteSession._(username);
  addTearDown(session._close);
  await session._signIn();
  return session;
}

/// One headless session; see [remoteSession].
final class RemoteSession {
  RemoteSession._(this.username);

  final String username;
  final _store = OidcMemoryStore();
  ProviderContainer? _container;
  AuthoringScope? _followed;

  Future<void> _signIn() async {
    final user = stack.user(username);
    final container = _open(organization: null);
    final manager = await container.read(authProvider.future);
    if (manager == null) throw StateError("the panel has no session client");
    await manager.loginPassword(
      username: user.username,
      password: user.password,
    );
    container.invalidate(authProvider);
  }

  /// A container scoped to [organization], the way the panel is while that
  /// organization's pages are open.
  ProviderContainer _open({
    required skir.RecordId? organization,
    skir.RecordId? realm,
  }) {
    _container?.dispose();
    _followed = null;
    final container = ProviderContainer(
      retry: panelRetry,
      overrides: [
        ...appOverrides(),
        oidcStoreProvider.overrideWithValue(_store),
        organizationIdProvider.overrideWithValue(organization),
        realmIdProvider.overrideWithValue(realm),
      ],
    );
    return _container = container;
  }

  /// Removes the member [member] from the organization [organization], both
  /// by the names the panel shows, as the members page does.
  Future<void> removeMember(String organization, String member) async {
    final (scoped, id) = await _openOrganization(organization);
    final members = await _watch(scoped, organizationMembersProvider.future);
    final removed = members.firstWhere(
      (candidate) => candidate.name == member,
      orElse: () => throw TestFailure("$organization has no member $member"),
    );
    // Held while the commands run, as a screen holding the repository does;
    // a bare read lets it dispose at the first await.
    final commands = scoped
        .listen(membershipResourceRepositoryProvider(id), (_, _) {})
        .read();
    final work = scoped.read(localWorkControllerProvider);
    (await work.execute(commands.remove(removed.userId))).requireAccepted();
  }

  /// Makes [person] a stranger to [organization] again: removes their
  /// membership and declines their pending join requests, so a scenario that
  /// has them join starts from the same state on every run, a rerun
  /// included.
  Future<void> forget(String organization, String person) async {
    final (scoped, id) = await _openOrganization(organization);
    // Held while the commands run, as a screen holding the repository does;
    // a bare read lets it dispose at the first await.
    final commands = scoped
        .listen(membershipResourceRepositoryProvider(id), (_, _) {})
        .read();
    final work = scoped.read(localWorkControllerProvider);
    final members = await _watch(scoped, organizationMembersProvider.future);
    for (final member in members.where((member) => member.name == person)) {
      (await work.execute(commands.remove(member.userId))).requireAccepted();
    }
    final requests = await _watch(
      scoped,
      organizationJoinRequestsProvider.future,
    );
    for (final request in requests.where(
      (request) => request.userName == person,
    )) {
      (await work.execute(commands.decline(request.requestId)))
          .requireAccepted();
    }
  }

  /// Opens the realm holding [target] in this session, as having it on
  /// screen does, so a later [write] needs no setup.
  Future<void> follow(OpenResource target) async {
    final container = _open(
      organization: target.scope.organizationId,
      realm: target.scope.realmId,
    );
    _followed = target.scope;
    await container.read(authProvider.future);
    container.listen(workingAuthoringDocumentProvider(target.scope), (_, _) {});
    await until(
      "$username's session reads the realm",
      () => container
          .read(workingAuthoringDocumentProvider(target.scope))
          .hasValue,
    );
  }

  /// Waits until this session reads [text] at [fields] of [target], the
  /// saved value every other user sees.
  Future<void> expectSaved(
    OpenResource target,
    List<String> fields,
    String text,
  ) async {
    if (_followed != target.scope) await follow(target);
    final container = _container!;
    String? saved() {
      final document = container
          .read(workingAuthoringDocumentProvider(target.scope))
          .value;
      final read = document?.read(
        authoredFieldLocation(target.resource, fields),
      );
      return switch (read) {
        PortablePathValue(
          value: skir.DataValue_stringValueWrapper(:final value),
        ) =>
          value,
        _ => null,
      };
    }

    await until(
      "$username reads \"$text\" at ${fields.join(".")}; it reads "
      "\"${saved()}\"",
      () => saved() == text,
    );
  }

  /// Sets the text at [fields] of [target] to [text] and saves it, as this
  /// user typing it on their own panel does.
  Future<void> write(OpenResource target, List<String> fields, String text) =>
      _save(
        target,
        "Set ${fields.join(".")}",
        (edit) => edit.setFieldPayload(
          resource: target.resource,
          fields: fields,
          payload: skir.DataValue.wrapStringValue(text),
        ),
      );

  /// Deletes [target] when the scenario ends, passed or failed, so content
  /// the scenario breaks on purpose never outlives it.
  void deleteAfterwards(OpenResource target) => addTearDown(
    () => _save(target, "Delete", (edit) => edit.delete(target.resource)),
  );

  Future<void> _save(
    OpenResource target,
    String label,
    void Function(AuthoringEdit edit) apply,
  ) async {
    if (_followed != target.scope) await follow(target);
    final editing = _container!.read(realmEditingProvider(target.scope));
    final staged = editing.edit(
      label: label,
      policy: EditorCommitPolicy.applyResource,
      apply: apply,
    );
    if (staged is! EditStaged) {
      throw TestFailure("$username could not stage \"$label\": $staged");
    }
    await editing.save(staged.group);
    await until(
      "$username's \"$label\" is saved",
      () => !editing.hasWorkFor(target.resource),
    );
  }

  /// A container scoped to the organization the panel shows as
  /// [organization], with the session loaded, and that organization's id.
  Future<(ProviderContainer, skir.RecordId)> _openOrganization(
    String organization,
  ) async {
    final unscoped = _open(organization: null);
    await unscoped.read(authProvider.future);
    final organizations = await _watch(unscoped, organizationsProvider.future);
    final target = organizations.firstWhere(
      // The panel shows a name formatted for reading, such as "Acme" for
      // the stored "acme".
      (candidate) => candidate.name.formatted == organization,
      orElse: () =>
          throw TestFailure("$username sees no organization $organization"),
    );
    final scoped = _open(organization: target.organizationId);
    // The user loaded, so repositories read next live on the session that
    // carries them, not on one replaced once the user arrives.
    await scoped.read(userIdProvider.future);
    return (scoped, target.organizationId);
  }

  /// Reads [provider] while listening, as a screen showing it does, so a
  /// provider that disposes without listeners settles first.
  Future<T> _watch<T>(
    ProviderContainer container,
    ProviderListenable<Future<T>> provider,
  ) => container.listen(provider, (_, _) {}).read();

  void _close() {
    _container?.dispose();
    _container = null;
  }
}
