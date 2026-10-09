import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

final class AuthoredPresentationHost extends ChangeNotifier
    implements PortablePresentationHost {
  AuthoredPresentationHost({
    required this.resource,
    required this._source,
    required this.material,
    required this.role,
    required this.budget,
    required this.capabilities,
    this.available = true,
    this.readOnly = false,
    this.prepareCreation,
    this.edit,
    this.reportStatus,
  });

  final skir.ResourceId resource;
  AuthoringDocument _source;
  AuthoringDocument get authored => edit?.document ?? _source;
  final skir.PresentationMaterial material;
  final skir.PresentationRole role;
  final skir.EvaluationBudget budget;
  @override
  PortablePresentationCapabilities capabilities;
  bool available;
  @override
  bool readOnly;
  Future<skir.PreparedCreation> Function(skir.InitializationRequest request)?
  prepareCreation;
  final AuthoringBinding? edit;
  ValueChanged<String>? reportStatus;
  var _disposed = false;

  /// Updates view metadata without replacing an active operation's host.
  void update({
    required AuthoringDocument source,
    required PortablePresentationCapabilities capabilities,
    required bool available,
    required bool readOnly,
    Future<skir.PreparedCreation> Function(skir.InitializationRequest)?
    prepareCreation,
    ValueChanged<String>? reportStatus,
  }) {
    _source = source;
    this.capabilities = capabilities;
    this.available = available;
    this.readOnly = readOnly;
    this.prepareCreation = prepareCreation;
    this.reportStatus = reportStatus;
  }

  @override
  bool get enabled => !_disposed && available;

  @override
  PortablePresentationDocument get document {
    final record = authored.resource(resource);
    if (record == null) {
      throw StateError("The authored resource is absent");
    }
    final checked = authored.catalog;
    if (checked.snapshot.generation != authored.generation) {
      throw StateError("The authoring catalog is unavailable");
    }
    final payload = skir.DataValue.createRecord(fields: record.fields);
    final value = switch (record.configuration) {
      skir.TypeSelection_completeWrapper(:final value) =>
        skir.DataValue.createNamed(actualType: value, payload: payload),
      _ => payload,
    };
    return PortablePresentationDocument(
      catalog: checked,
      root: material.layout,
      bindings: {
        presentationSubjectIdentifierBindingId: PortablePresentationBinding(
          schema: CompletePortablePresentationBinding(
            skir.TypeUse.wrapScalar(skir.ScalarKind.text),
          ),
          value: skir.DataValue.wrapStringValue(resource.value),
        ),
        configuredValueBindingId: PortablePresentationBinding(
          schema: switch (record.configuration) {
            skir.TypeSelection_completeWrapper(:final value) =>
              CompletePortablePresentationBinding(
                skir.TypeUse.wrapNamed(value),
              ),
            _ => PartialPortablePresentationBinding(record.configuration),
          },
          value: value,
          editable: true,
          location: skir.ValueLocation(
            resource: resource,
            path: skir.ValuePath(segments: const []),
          ),
        ),
      },
      budget: budget,
      role: role,
      material: material,
      activePresentations: {material.provider},
    );
  }

  @override
  skir.DataValue? read(skir.BindingRef reference) {
    final exposed = document.bindings[reference.bindingId];
    if (exposed == null) return null;
    if (reference.path.segments.isEmpty) return exposed.value;
    return switch (exposed.value.readAt(reference.path)) {
      PortablePathValue(:final value) => value,
      PortablePathUnavailable() => null,
    };
  }

  @override
  skir.ValueLocation? location(skir.BindingRef reference) {
    final base = document.bindings[reference.bindingId]?.location;
    if (base == null) return null;
    return skir.ValueLocation(
      resource: base.resource,
      path: skir.ValuePath(
        segments: [...base.path.segments, ...reference.path.segments],
      ),
    );
  }

  @override
  skir.TypeUse? expectedType(skir.BindingRef reference) {
    final target = location(reference);
    final record = target == null ? null : authored.resource(target.resource);
    return record == null
        ? null
        : authored.catalog.valueTypeAt(
            record.configuration,
            target!.path,
            value: _recordValue(record),
          );
  }

  skir.DataValue _recordValue(skir.AuthoringRecord record) {
    final payload = skir.DataValue.createRecord(fields: record.fields);
    return switch (record.configuration) {
      skir.TypeSelection_completeWrapper(:final value) =>
        skir.DataValue.createNamed(actualType: value, payload: payload),
      _ => payload,
    };
  }

  @override
  Future<PortablePresentationWriteResult> write(
    skir.BindingRef reference,
    skir.DataValue value,
  ) async {
    if (!enabled || readOnly) {
      return const PortablePresentationWriteRejected(
        "This presentation is read only",
      );
    }
    final target = location(reference);
    if (target == null) {
      return const PortablePresentationWriteRejected(
        "The presentation binding is unavailable",
      );
    }
    final binding = edit;
    if (binding == null) {
      return const PortablePresentationWriteRejected(
        "This presentation is read only",
      );
    }
    final previousFindingCount = authored.initializationFindings.length;
    final result = await binding.prepare(
      label: "Edit value",
      from: authored,
      apply: (operation) async {
        if (prepareCreation case final prepare?) {
          await operation.setWithInitialization(target, value, prepare);
        } else {
          operation.set(target, value);
        }
        if (_disposed || !enabled || readOnly) {
          throw StateError("The presentation closed during preparation");
        }
      },
    );
    if (result case AuthoringEditRejected(:final message)) {
      return PortablePresentationWriteRejected(message);
    }
    final findings = authored.initializationFindings.skip(previousFindingCount);
    if (!_disposed && findings.isNotEmpty) {
      reportStatus?.call(
        findings.map(formatPortableInitializationDiagnostic).join("\n"),
      );
    }
    return const PortablePresentationWriteApplied();
  }

  @override
  Future<PortablePresentationWriteResult> execute(
    skir.EditorAction editorAction,
  ) async => _disposed
      ? const PortablePresentationWriteRejected(
          "This presentation is no longer available",
        )
      : const PortablePresentationWriteRejected(
          "This action requires the authored Realm operation boundary",
        );

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    super.dispose();
  }
}
