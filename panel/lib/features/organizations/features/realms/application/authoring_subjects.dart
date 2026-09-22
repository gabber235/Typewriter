import "package:flutter/foundation.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "authoring_subjects.g.dart";

/// Requested resources for one generation pinned subject batch.
@immutable
final class AuthoringSubjectScope {
  const AuthoringSubjectScope({
    required this.organizationId,
    required this.realmId,
    required this.resources,
  });

  final skir.RecordId organizationId;
  final skir.RecordId realmId;
  final Map<skir.ResourceId, ResolvedTypeRef> resources;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthoringSubjectScope &&
          organizationId == other.organizationId &&
          realmId == other.realmId &&
          mapEquals(resources, other.resources);

  @override
  int get hashCode => Object.hash(
    organizationId,
    realmId,
    Object.hashAllUnordered(
      resources.entries.map((entry) => Object.hash(entry.key, entry.value)),
    ),
  );
}

/// Complete typed subject result for one canonical session observation.
final class AuthoringSubjectProjection {
  const AuthoringSubjectProjection({
    required this.catalog,
    required this.generation,
    required this.sequence,
    required this.subjects,
    required this.collections,
    required this.diagnostics,
  });

  final RealmEditorCatalogSnapshot catalog;
  final CatalogGeneration generation;
  final int sequence;
  final Map<skir.ResourceId, TypedPresentationSubject> subjects;
  final Map<PresentationCollectionSourceId, PresentationCollectionSource>
  collections;
  final List<TypeDiagnostic> diagnostics;
}

/// Resolves a whole visible resource scope under one exact catalog generation.
///
/// Dependency changes rebuild the provider with the current session sequence
/// and local draft snapshot. Riverpod discards completions from older builds,
/// so a late batch cannot replace a newer canonical or draft projection.
@riverpod
Future<AuthoringSubjectProjection> authoringSubjects(
  Ref ref,
  AuthoringSubjectScope scope,
) async {
  final session = ref.watch(
    authoringSessionProvider(scope.organizationId, scope.realmId),
  );
  final generation = session.generation;
  final sequence = session.sequence;
  if (generation == null || sequence == null) {
    throw StateError("The authoring scope is not loaded");
  }
  final cache = ref.watch(realmEditorCatalogCacheProvider);
  if (cache == null ||
      cache.route.organizationId != scope.organizationId ||
      cache.route.realmId != scope.realmId) {
    throw StateError("The Realm editor catalog is unavailable for this scope");
  }
  final diagnostics = <TypeDiagnostic>[];
  final wireSubjects = <skir.PresentationSubject>[];
  for (final id in scope.resources.keys) {
    final subject = session.presentations[id];
    if (subject == null) {
      diagnostics.add(
        _subjectDiagnostic("Resource '${id.value}' has no graph presentation"),
      );
    } else {
      wireSubjects.add(subject);
    }
  }
  final request = presentationSubjectCatalogRequest(wireSubjects);
  if (request case TypeFailure(:final diagnostics)) {
    throw StateError(
      diagnostics.map((diagnostic) => diagnostic.message).join("; "),
    );
  }
  final fetched = await cache.fetchExact(
    CatalogGeneration(generation.value),
    request.valueOrNull!,
  );
  final catalog = switch (fetched) {
    RealmEditorCatalogFetched(:final snapshot) => snapshot,
    RealmEditorCatalogGenerationMismatch() => throw StateError(
      "The subject catalog generation changed",
    ),
    RealmEditorCatalogFetchUnavailable(:final diagnostics) => throw StateError(
      diagnostics.map((item) => item.message).join("; "),
    ),
  };
  final codec = TypedAuthoringCodec(catalog);
  final collections = decodeAuthoringCollections(
    session: session,
    catalog: catalog,
    presentations: catalog.presentations.values,
  );
  diagnostics.addAll(collections.diagnostics);
  final local = ref.watch(localWorkProvider).editorValues;
  final subjects = <skir.ResourceId, TypedPresentationSubject>{};
  for (final wire in wireSubjects) {
    final decoded = codec.decodeSubject(wire);
    final subject = decoded.valueOrNull;
    if (subject == null) {
      diagnostics.addAll(decoded.diagnostics);
      continue;
    }
    final id = subject.identity.id;
    final expected = scope.resources[id];
    if (expected == null || expected != subject.content.rootType) {
      diagnostics.add(
        _subjectDiagnostic("Resource '${id.value}' has an unexpected type"),
      );
      continue;
    }
    final content = _projectSubjectContent(
      session: session,
      local: local,
      scope: scope,
      subject: subject,
      codec: codec,
    );
    if (content == null) {
      diagnostics.add(
        _subjectDiagnostic("Resource '${id.value}' is not in the scope"),
      );
      continue;
    }
    subjects[id] = (
      content: content,
      descriptor: subject.descriptor,
      identityEnvelope: subject.identityEnvelope,
      identity: subject.identity,
    );
  }
  return AuthoringSubjectProjection(
    catalog: catalog,
    generation: catalog.generation,
    sequence: sequence,
    subjects: Map.unmodifiable(subjects),
    collections: collections.sources,
    diagnostics: List.unmodifiable(diagnostics),
  );
}

TypedValueEnvelope? _projectSubjectContent({
  required AuthoringSessionState session,
  required Map<EditorResourceKey, LocalEditorValue> local,
  required AuthoringSubjectScope scope,
  required TypedPresentationSubject subject,
  required TypedAuthoringCodec codec,
}) {
  final id = subject.identity.id;
  DataValue? canonical;
  final resource = session.resources[id];
  if (resource != null) {
    final decoded = codec.decodeResource(resource).valueOrNull;
    if (decoded?.content.rootType != subject.content.rootType) return null;
    canonical = decoded?.content.rootValue;
  }
  if (canonical == null) return null;
  final draft =
      local[EditorResourceKey(
        scope: EditorResourceScope(
          organizationId: scope.organizationId,
          realmId: scope.realmId,
        ),
        identity: id,
      )];
  if (draft != null) {
    canonical = draft.projectOnto(canonical);
  }
  return subject.content.copyWith(rootValue: canonical);
}

TypeDiagnostic _subjectDiagnostic(String message, {String? code}) =>
    TypeDiagnostic(
      code: TypeDiagnosticCode.invalidValue,
      message: message,
      pathPresent: false,
      details: [
        if (code != null) TypeDiagnosticDetail(key: "code", value: code),
      ],
    );
