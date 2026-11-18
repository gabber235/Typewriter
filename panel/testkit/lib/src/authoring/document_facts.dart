import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// What a test reads from, or derives from, a saved authoring document.
extension AuthoringDocumentFacts on AuthoringDocument {
  /// The start and end frame [cue] is saved at, or null when it has no
  /// timeline placement in this document.
  (int, int)? frames(skir.ResourceId cue) => switch (resource(cue)
      ?.placement(catalog)) {
    ReadyPlacement(
      placement: TimelineSegmentPlacement(:final startFrame, :final endFrame),
    ) =>
      (startFrame, endFrame),
    _ => null,
  };

  /// This document typed by its catalog extended with [types] and
  /// [relations], such as the types an extension adds.
  AuthoringDocument withCatalogEntries({
    List<skir.PublishedType> types = const [],
    List<skir.RelationContract> relations = const [],
  }) => copyWith(
    catalog: CheckedEditorCatalog(
      (catalog.snapshot.toMutable()
            ..types = [...catalog.snapshot.types, ...types]
            ..relations = [...catalog.snapshot.relations, ...relations])
          .toFrozen(),
    ),
  );

  /// This document typed by a catalog of another [generation].
  AuthoringDocument withCatalogGeneration(String generation) => copyWith(
    catalog: CheckedEditorCatalog(
      (catalog.snapshot.toMutable()
            ..generation = skir.CatalogGeneration(value: generation))
          .toFrozen(),
    ),
  );

  /// The resource the link in [field] of [resource] points to, or null when
  /// that field holds no link.
  skir.ResourceId? linkTarget(skir.ResourceId resource, String field) => this
      .resource(resource)
      ?.authoredField(field)
      ?.authoredLink
      ?.target
      .resource;

  /// The value saved at [at], or null when nothing is saved there.
  skir.DataValue? valueAt(skir.ValueLocation at) => switch (read(at)) {
    PortablePathValue(:final value) => value,
    _ => null,
  };

  /// The evidence a diagnostic about [resource] carries when it was found
  /// in this document: the catalog generation and the resource as saved.
  skir.DiagnosticEvidence evidenceOf(skir.ResourceId resource) =>
      skir.DiagnosticEvidence(
        catalog: generation,
        evidence: [
          skir.CheckEvidence.wrapFact(
            skir.EditExpectation.createResource(
              id: resource,
              expected: this.resource(resource),
            ),
          ),
        ],
      );
}

/// The Realm editor's replies on the wire, as the handlers a test registers
/// on its NATS double return them.
extension RealmEditorReplies on AuthoringDocument {
  /// This document as the Realm reports its saved state.
  skir.AuthoringState get savedState => skir.AuthoringState(
    confirmedObservation: confirmedObservation!,
    generation: generation,
    resources: entries.values.toList(),
    links: links,
    findings: const [],
  );

  /// The Realm's reply to a saved state query: this document.
  Uint8List get stateReply => skir.QueryAuthoringStateResponse.serializer
      .toBytes(skir.QueryAuthoringStateResponse.wrapState(savedState));
}

/// The Realm editor's catalog replies on the wire.
extension CatalogReplies on CheckedEditorCatalog {
  /// The Realm's reply to a catalog fetch: this catalog.
  Uint8List get fetchReply => skir.CatalogFetchResult.serializer.toBytes(
    skir.CatalogFetchResult.wrapCatalog(snapshot),
  );
}

/// What a test reads from a draft.
extension AuthoringEditFacts on AuthoringEdit {
  /// The value the draft holds at [at], or null when it holds none there.
  skir.DataValue? valueAt(skir.ValueLocation at) => switch (read(at)) {
    PortablePathValue(:final value) => value,
    _ => null,
  };
}
