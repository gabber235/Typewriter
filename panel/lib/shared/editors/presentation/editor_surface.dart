import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// Bridges an [EditorSource] to the presentation renderer.
///
/// The source remains the authority for the current document, draft, and save
/// state. This widget listens for source changes, derives a presentation model
/// for [path], and recreates only the render model when the document changes.
/// Use [ComposedEditor] directly when one presentation combines several edit
/// owners or when the caller already owns the model lifecycle.
class EditorSurface extends StatelessWidget {
  const EditorSurface({
    required this.source,
    this.path = DataPath.root,
    this.registry,
    this.presentation,
    this.presentations = const [],
    this.collections = const [],
    this.conversions = const [],
    this.host = const EditorHostCapabilities(),
    this.referenceOrigins = const [],
    this.headerShortcuts = const {},
    this.historyNamespace = "local",
    this.readOnly = false,
    super.key,
  });

  final EditorSource source;
  final DataPath path;
  final TypeRegistry? registry;
  final PresentationNode? presentation;
  final List<PresentationDefinition> presentations;
  final List<PresentationCollectionSource> collections;
  final List<ConversionDefinition> conversions;
  final EditorHostCapabilities host;
  final List<ResourceId> referenceOrigins;
  final Map<HeaderItemCommandId, List<ShortcutActivator>> headerShortcuts;
  final String historyNamespace;
  final bool readOnly;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: source,
    builder: (context, _) {
      if (source.document == null) return const SizedBox.shrink();
      final model = PresentationModel.editor(
        owner: source,
        path: path,
        registry: registry,
        presentation: presentation,
        presentations: presentations,
        collections: collections,
        diagnostics: source.document!.diagnostics,
      );
      return ComposedEditor(
        model: model,
        host: host,
        conversions: conversions,
        referenceOrigins: referenceOrigins,
        headerShortcuts: headerShortcuts,
        historyNamespace: historyNamespace,
        readOnly: readOnly || source.readOnly,
      );
    },
  );
}
