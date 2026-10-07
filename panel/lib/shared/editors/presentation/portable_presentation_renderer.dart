import "dart:async";
import "dart:convert";
import "dart:math" as math;
import "dart:ui" as ui show TextDirection;

import "package:clock/clock.dart";
import "package:crypto/crypto.dart";
import "package:duration/duration.dart";
import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:flutter_markdown_plus/flutter_markdown_plus.dart";
import "package:http/http.dart" as http;
import "package:iconify_flutter_plus/icons/bi.dart";
import "package:iconify_flutter_plus/icons/heroicons_solid.dart";
import "package:intl/intl.dart";
import "package:json_path/json_path.dart";
import "package:skir_client/skir_client.dart" show ByteString;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/action.dart"
    as action;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/authoring.dart"
    as authoring;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/authoring_facts.dart"
    as facts;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/binding.dart"
    as binding;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/capability.dart"
    as capability;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/catalog.dart"
    as catalog_wire;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/diagnostic.dart"
    as diagnostic;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/expression.dart"
    as expression;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/presentation.dart"
    as presentation;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/search.dart"
    as search_wire;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/type_catalog.dart"
    as types;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/kernel/v1/duration.dart"
    as kernel;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:uuid/uuid.dart";

part "portable_search_input.dart";

final _configuredValueBindingId = types.ExpressionBindingId(
  value: "configured_value",
);
final _signedInt64Minimum = -(BigInt.one << 63);
final _signedInt64Maximum = (BigInt.one << 63) - BigInt.one;

String _displayNumber(double value) => value == value.truncateToDouble()
    ? value.toInt().toString()
    : value.toString();

typedef PortableSlotBuilder = Widget Function(PortablePresentationScope scope);

final class PortablePresentationScope {
  const PortablePresentationScope({
    required this.bindings,
    required this.budget,
    required this.setBinding,
    this.readOnly = false,
    this.enabled = true,
    this.invokeCommand,
    this.watchSearch,
    this.reload,
    this.reportStatus,
    this.commit,
    this.authoring,
    this.catalog,
    this.resource,
    this.onDraftChanged,
    this.openResource,
    this.prepareCreation,
    this.role,
    this.material,
    this.activePresentations = const {},
    this.slots = const {},
    this.slotBuilders = const {},
    this.host,
  });

  final Map<types.ExpressionBindingId, PortableExpressionBinding> bindings;
  final expression.EvaluationBudget budget;
  final PortableBindingSetter setBinding;
  final bool readOnly;
  final bool enabled;
  final Future<void> Function(
    types.CapabilityId capabilityId,
    types.DataValue payload,
  )?
  invokeCommand;
  final Stream<search_wire.RealmPresentationSearchUpdate> Function(
    search_wire.RealmPresentationSearchRequest request,
  )?
  watchSearch;
  final Future<void> Function()? reload;
  final ValueChanged<String>? reportStatus;
  final Future<void> Function()? commit;
  final PortableAuthoringDocument? authoring;
  final CheckedEditorCatalog? catalog;
  final types.ResourceId? resource;
  final VoidCallback? onDraftChanged;
  final ValueChanged<types.ResourceId>? openResource;
  final Future<catalog_wire.PreparedCreation> Function(
    catalog_wire.InitializationRequest request,
  )?
  prepareCreation;
  final catalog_wire.PresentationRole? role;
  final catalog_wire.PresentationMaterial? material;
  final Set<types.PresentationId> activePresentations;
  final Map<String, presentation.PresentationNode> slots;
  final Map<String, PortableSlotBuilder> slotBuilders;
  final PortablePresentationHost? host;

  PortableExpressionResult evaluate(expression.ExpressionNode node) =>
      PortableExpressionEvaluator.located(
        bindings,
        budget: budget,
      ).evaluate(node);

  types.DataValue? read(binding.BindingRef reference) {
    final source = bindings[reference.bindingId];
    if (source == null) return null;
    if (reference.path.segments.isEmpty) return source.value;
    return switch (source.value.readAt(reference.path)) {
      PortablePathValue(:final value) => value,
      PortablePathUnavailable() => null,
    };
  }

  types.ValueLocation? location(binding.BindingRef reference) {
    final source = bindings[reference.bindingId]?.location;
    if (source == null) return null;
    return types.ValueLocation(
      resource: source.resource,
      path: types.ValuePath(
        segments: [...source.path.segments, ...reference.path.segments],
      ),
    );
  }

  types.TypeUse? expectedType(binding.BindingRef reference) {
    final hosted = host?.expectedType(reference);
    if (hosted != null) return hosted;
    final target = location(reference);
    final checked = catalog;
    final authored = authoring;
    if (target == null || checked == null || authored == null) return null;
    final record = authored.resource(target.resource);
    if (record == null) return null;
    final payload = types.DataValue.createRecord(fields: record.fields);
    final value = switch (record.configuration) {
      types.TypeSelection_completeWrapper(:final value) =>
        types.DataValue.createNamed(actualType: value, payload: payload),
      _ => payload,
    };
    return checked.valueTypeAt(record.configuration, target.path, value: value);
  }

  types.TypeUse? expectedPayloadType(binding.BindingRef reference) {
    final expected = expectedType(reference);
    final unwrapped = _unwrapNullable(expected);
    if (unwrapped case types.TypeUse_namedWrapper(:final value)) {
      final representation = catalog
          ?.published(value.definition)
          ?.definition
          .representation;
      if (representation case types.RepresentationTemplate_scalarWrapper(
        :final value,
      )) {
        return types.TypeUse.wrapScalar(value.kind);
      }
    }
    return unwrapped;
  }

  void write(binding.BindingRef reference, types.DataValue value) {
    if (enabled && !readOnly) setBinding(reference, value);
  }

  void writePayload(binding.BindingRef reference, types.DataValue payload) {
    final current = read(reference);
    final actual = switch (_unwrapNullable(expectedType(reference))) {
      types.TypeUse_namedWrapper(:final value) => value,
      _ => null,
    };
    write(
      reference,
      current is types.DataValue_namedWrapper
          ? _preserveNamedIdentity(current, payload)
          : actual == null
          ? payload
          : types.DataValue.createNamed(actualType: actual, payload: payload),
    );
  }

  bool get canExecuteAction =>
      enabled && !readOnly && (authoring != null || host != null);

  Future<void> executeAction(action.EditorAction editorAction) async {
    if (!canExecuteAction) return;
    if (authoring == null && host != null) {
      final portableHost = host!;
      final result = await portableHost.execute(editorAction);
      if (result case PortablePresentationWriteRejected(:final message)) {
        reportStatus?.call(message);
      }
      return;
    }
    try {
      switch (editorAction) {
        case action.EditorAction_localWrapper(:final value):
          await _executeLocalAction(value);
        case action.EditorAction_realmWrapper(:final value):
          await _executeRealmAction(value);
        case action.EditorAction_unknown():
          reportStatus?.call("This editor action is unavailable");
      }
    } on Object catch (error) {
      reportStatus?.call("The editor action did not complete: $error");
    }
  }

  Future<void> _executeLocalAction(action.LocalEditorAction local) async {
    switch (local) {
      case action.LocalEditorAction_setValueWrapper(:final value):
        final replacement = _evaluateActionValue(value.value);
        if (replacement != null) _editBinding(value.target, replacement);
      case action.LocalEditorAction_insertListItemWrapper(:final value):
        final replacement = _evaluateActionValue(value.value);
        if (replacement == null) return;
        _editList(value.target, (location, authored) {
          return authored.insert(
            location,
            value.after,
            types.ListItem(
              id: types.ItemId(value: const Uuid().v4()),
              value: replacement.value,
            ),
          );
        }, reads: replacement.reads);
      case action.LocalEditorAction_appendListItemWrapper(:final value):
        final replacement = _evaluateActionValue(value.value);
        if (replacement == null) return;
        final items = read(value.target)?.authoredItems?.toList();
        if (items == null) {
          reportStatus?.call("The action target is not a collection");
          return;
        }
        _editList(value.target, (location, authored) {
          return authored.insert(
            location,
            items.lastOrNull?.id,
            types.ListItem(
              id: types.ItemId(value: const Uuid().v4()),
              value: replacement.value,
            ),
          );
        }, reads: replacement.reads);
      case action.LocalEditorAction_removeListItemWrapper(:final value):
        _editList(
          value.target,
          (location, authored) => authored.remove(location, value.item),
        );
      case action.LocalEditorAction_duplicateListItemWrapper(:final value):
        final collectionLocation = location(value.target);
        final items = read(value.target)?.authoredItems?.toList();
        final source = items
            ?.where((candidate) => candidate.id == value.item)
            .firstOrNull;
        if (collectionLocation == null || source == null) {
          reportStatus?.call("The collection item is no longer available");
          return;
        }
        _editList(
          value.target,
          (location, authored) {
            return authored.insert(
              location,
              source.id,
              types.ListItem(
                id: types.ItemId(value: const Uuid().v4()),
                value: source.value,
              ),
            );
          },
          reads: [
            PortableExpressionRead(
              value.target.bindingId,
              types.ValuePath(
                segments: [
                  ...value.target.path.segments,
                  types.PathSegment.createItem(id: source.id),
                ],
              ),
              location: types.ValueLocation(
                resource: collectionLocation.resource,
                path: types.ValuePath(
                  segments: [
                    ...collectionLocation.path.segments,
                    types.PathSegment.createItem(id: source.id),
                  ],
                ),
              ),
            ),
          ],
        );
      case action.LocalEditorAction_moveListItemWrapper(:final value):
        _editList(
          value.target,
          (location, authored) =>
              authored.move(location, value.item, value.after),
        );
      case action.LocalEditorAction_insertMapRowWrapper(:final value):
        final key = _evaluateActionValue(value.key);
        final replacement = _evaluateActionValue(value.value);
        if (key == null || replacement == null) return;
        _editMap(
          value.target,
          (rows) => [
            ...rows,
            types.MapRow(
              id: types.ItemId(value: const Uuid().v4()),
              key: key.value,
              value: replacement.value,
            ),
          ],
          reads: [...key.reads, ...replacement.reads],
        );
      case action.LocalEditorAction_updateMapRowWrapper(:final value):
        final key = _evaluateActionValue(value.key);
        final replacement = _evaluateActionValue(value.value);
        if (key == null || replacement == null) return;
        _editMap(
          value.target,
          (rows) => [
            for (final row in rows)
              if (row.id == value.row)
                types.MapRow(
                  id: row.id,
                  key: key.value,
                  value: replacement.value,
                )
              else
                row,
          ],
          requiredRow: value.row,
          reads: [...key.reads, ...replacement.reads],
        );
      case action.LocalEditorAction_removeMapRowWrapper(:final value):
        _editMap(
          value.target,
          (rows) => rows.where((row) => row.id != value.row).toList(),
          requiredRow: value.row,
        );
      case action.LocalEditorAction_chooseFormWrapper(:final value):
        await _chooseForm(value);
      case action.LocalEditorAction_unknown():
        reportStatus?.call("This local editor action is unavailable");
    }
  }

  Future<void> _executeRealmAction(action.RealmEditorAction realm) async {
    switch (realm) {
      case action.RealmEditorAction_reloadWrapper():
        final callback = reload;
        if (callback == null) {
          reportStatus?.call("Reload is unavailable");
          return;
        }
        await callback();
      case action.RealmEditorAction_commandWrapper(:final value):
        final callback = invokeCommand;
        if (callback == null) {
          reportStatus?.call("Realm commands are unavailable");
          return;
        }
        final payload = _evaluateActionValue(value.payload);
        if (payload != null) {
          await callback(value.capabilityId, payload.value);
        }
      case action.RealmEditorAction_unknown():
        reportStatus?.call("This Realm editor action is unavailable");
    }
  }

  _EvaluatedActionValue? _evaluateActionValue(expression.ExpressionNode node) {
    final result = evaluate(node);
    return switch (result) {
      PortableExpressionAvailable(:final value, :final reads) =>
        _EvaluatedActionValue(value, reads),
      PortableExpressionUnavailable() => _reportActionFailure(
        "The action needs values that are not available",
      ),
      PortableExpressionFailed(:final message) => _reportActionFailure(message),
    };
  }

  void _editBinding(
    binding.BindingRef target,
    _EvaluatedActionValue replacement,
  ) {
    final location = this.location(target);
    final authored = authoring;
    if (location == null || authored == null) {
      reportStatus?.call("The action target is unavailable");
      return;
    }
    final staged = authored.stageExpressionEdit(
      replacement.reads,
      (branch) => branch.set(location, replacement.value) is PortablePathValue,
    );
    if (!staged) {
      reportStatus?.call("The action target could not be updated");
      return;
    }
    onDraftChanged?.call();
  }

  _EvaluatedActionValue? _reportActionFailure(String message) {
    reportStatus?.call(message);
    return null;
  }

  void _editList(
    binding.BindingRef target,
    PortablePathResult<types.AuthoringRecord> Function(
      types.ValueLocation location,
      PortableAuthoringDocument draft,
    )
    edit, {
    Iterable<PortableExpressionRead> reads = const [],
  }) {
    final location = this.location(target);
    final authored = authoring;
    if (location == null || authored == null) {
      reportStatus?.call("The action target is unavailable");
      return;
    }
    String? failure;
    final staged = authored.stageExpressionEdit(reads, (branch) {
      final result = edit(location, branch);
      if (result case PortablePathUnavailable(:final message)) {
        failure = message;
        return false;
      }
      return true;
    });
    if (!staged) {
      reportStatus?.call(failure ?? "The collection could not be updated");
      return;
    }
    onDraftChanged?.call();
  }

  void _editMap(
    binding.BindingRef target,
    List<types.MapRow> Function(List<types.MapRow> rows) update, {
    types.ItemId? requiredRow,
    Iterable<PortableExpressionRead> reads = const [],
  }) {
    final location = this.location(target);
    final authored = authoring;
    final current = read(target)?.authoredPayload;
    if (location == null || authored == null) {
      reportStatus?.call("The action target is unavailable");
      return;
    }
    if (current is! types.DataValue_mapValueWrapper) {
      reportStatus?.call("The action target is not a map");
      return;
    }
    final rows = current.value.rows.toList();
    if (requiredRow != null && rows.every((row) => row.id != requiredRow)) {
      reportStatus?.call("The map row is no longer available");
      return;
    }
    String? failure;
    final staged = authored.stageExpressionEdit(reads, (branch) {
      final result = branch.replaceMap(location, update(rows));
      if (result case PortablePathUnavailable(:final message)) {
        failure = message;
        return false;
      }
      return true;
    });
    if (!staged) {
      reportStatus?.call(failure ?? "The map could not be updated");
      return;
    }
    onDraftChanged?.call();
  }

  Future<void> _chooseForm(action.ChooseFormAction choice) async {
    final location = this.location(choice.target);
    final authored = authoring;
    final prepare = prepareCreation;
    final named = switch (choice.type) {
      types.TypeUse_namedWrapper(:final value) => value,
      _ => null,
    };
    if (location == null ||
        authored == null ||
        prepare == null ||
        named == null) {
      reportStatus?.call("The selected form cannot be prepared");
      return;
    }
    final operation = const Uuid().v4();
    final request = catalog_wire.InitializationRequest(
      id: types.InitializationRequestId(value: "panel:form:$operation"),
      catalog: authored.generation,
      type: types.TypeSelection.wrapComplete(named),
      supplied: const [],
      intentHash: sha256
          .convert(
            utf8.encode(
              "${authored.generation.value}\u0000${location.resource.value}\u0000${_pathLabel(location.path)}\u0000$named",
            ),
          )
          .toString(),
    );
    try {
      final previousFindingCount = authored.initializationFindings.length;
      final prepared = await prepare(request);
      final result = authored.applyPreparedRecord(location, request, prepared);
      if (result case PortablePathUnavailable(:final message)) {
        reportStatus?.call(message);
        return;
      }
      onDraftChanged?.call();
      final findings = authored.initializationFindings.skip(
        previousFindingCount,
      );
      if (findings.isNotEmpty) {
        reportStatus?.call(
          findings.map(formatPortableInitializationDiagnostic).join("\n"),
        );
      }
    } on Object catch (error) {
      reportStatus?.call("The selected form could not be prepared: $error");
    }
  }

  PortablePresentationScope withReadOnly(bool value) =>
      PortablePresentationScope(
        bindings: bindings,
        budget: budget,
        setBinding: setBinding,
        readOnly: readOnly || value,
        enabled: enabled,
        invokeCommand: invokeCommand,
        watchSearch: watchSearch,
        reload: reload,
        reportStatus: reportStatus,
        commit: commit,
        authoring: authoring,
        catalog: catalog,
        resource: resource,
        onDraftChanged: onDraftChanged,
        openResource: openResource,
        prepareCreation: prepareCreation,
        role: role,
        material: material,
        activePresentations: activePresentations,
        slots: slots,
        slotBuilders: slotBuilders,
        host: host,
      );

  PortablePresentationScope withEnabled(bool value) =>
      PortablePresentationScope(
        bindings: bindings,
        budget: budget,
        setBinding: setBinding,
        readOnly: readOnly,
        enabled: enabled && value,
        invokeCommand: invokeCommand,
        watchSearch: watchSearch,
        reload: reload,
        reportStatus: reportStatus,
        commit: commit,
        authoring: authoring,
        catalog: catalog,
        resource: resource,
        onDraftChanged: onDraftChanged,
        openResource: openResource,
        prepareCreation: prepareCreation,
        role: role,
        material: material,
        activePresentations: activePresentations,
        slots: slots,
        slotBuilders: slotBuilders,
        host: host,
      );

  PortablePresentationScope withNamedPayload(PortableNamedPayload payload) {
    final configured = types.ExpressionBindingId(value: "configured_value");
    return PortablePresentationScope(
      bindings: {
        ...bindings,
        configured: PortableExpressionBinding(
          value: payload.value,
          location: payload.location,
        ),
      },
      budget: budget,
      readOnly: readOnly,
      enabled: enabled,
      invokeCommand: invokeCommand,
      watchSearch: watchSearch,
      reload: reload,
      reportStatus: reportStatus,
      commit: commit,
      authoring: authoring,
      catalog: catalog,
      resource: resource,
      onDraftChanged: onDraftChanged,
      openResource: openResource,
      prepareCreation: prepareCreation,
      role: role,
      material: material,
      activePresentations: activePresentations,
      slots: slots,
      slotBuilders: slotBuilders,
      host: host,
      setBinding: (reference, value) {
        if (reference.bindingId != configured) {
          setBinding(reference, value);
          return;
        }
        final replaced = reference.path.segments.isEmpty
            ? PortablePathValue(value)
            : payload.value.replaceAt(reference.path, value);
        if (replaced case PortablePathValue(:final value)) {
          payload.replace(value);
        }
      },
    );
  }

  PortablePresentationScope? withConfiguredValue(binding.BindingRef reference) {
    final source = bindings[reference.bindingId];
    if (source == null) return null;
    final resolved = reference.path.segments.isEmpty
        ? PortablePathValue(source.value)
        : source.value.readAt(reference.path);
    if (resolved case PortablePathUnavailable()) return null;
    final configured = types.ExpressionBindingId(value: "configured_value");
    final value = (resolved as PortablePathValue<types.DataValue>).value;
    final baseLocation = source.location;
    final location = baseLocation == null
        ? null
        : types.ValueLocation(
            resource: baseLocation.resource,
            path: types.ValuePath(
              segments: [
                ...baseLocation.path.segments,
                ...reference.path.segments,
              ],
            ),
          );
    return PortablePresentationScope(
      bindings: {
        ...bindings,
        configured: PortableExpressionBinding(value: value, location: location),
      },
      budget: budget,
      readOnly: readOnly,
      enabled: enabled,
      invokeCommand: invokeCommand,
      watchSearch: watchSearch,
      reload: reload,
      reportStatus: reportStatus,
      commit: commit,
      authoring: authoring,
      catalog: catalog,
      resource: resource,
      onDraftChanged: onDraftChanged,
      openResource: openResource,
      prepareCreation: prepareCreation,
      setBinding: (nestedReference, replacement) {
        if (nestedReference.bindingId != configured) {
          write(nestedReference, replacement);
          return;
        }
        if (nestedReference.path.segments.isEmpty) {
          writePayload(reference, replacement);
          return;
        }
        final replaced = value.replaceAt(nestedReference.path, replacement);
        if (replaced case PortablePathValue(value: final next)) {
          write(reference, next);
        }
      },
      role: role,
      material: material,
      activePresentations: activePresentations,
      slots: slots,
      slotBuilders: slotBuilders,
      host: host,
    );
  }

  PortablePresentationScope? withBinding(
    binding.BindingRef reference,
    types.ExpressionBindingId id,
  ) {
    final source = bindings[reference.bindingId];
    if (source == null) return null;
    final resolved = reference.path.segments.isEmpty
        ? PortablePathValue(source.value)
        : source.value.readAt(reference.path);
    if (resolved case PortablePathUnavailable()) return null;
    final value = (resolved as PortablePathValue<types.DataValue>).value;
    final baseLocation = source.location;
    final location = baseLocation == null
        ? null
        : types.ValueLocation(
            resource: baseLocation.resource,
            path: types.ValuePath(
              segments: [
                ...baseLocation.path.segments,
                ...reference.path.segments,
              ],
            ),
          );
    return PortablePresentationScope(
      bindings: {
        ...bindings,
        id: PortableExpressionBinding(value: value, location: location),
      },
      budget: budget,
      readOnly: readOnly,
      enabled: enabled,
      invokeCommand: invokeCommand,
      watchSearch: watchSearch,
      reload: reload,
      reportStatus: reportStatus,
      commit: commit,
      authoring: authoring,
      catalog: catalog,
      resource: resource,
      onDraftChanged: onDraftChanged,
      openResource: openResource,
      prepareCreation: prepareCreation,
      role: role,
      material: material,
      activePresentations: activePresentations,
      slots: slots,
      slotBuilders: slotBuilders,
      host: host,
      setBinding: (nestedReference, replacement) {
        if (nestedReference.bindingId != id) {
          write(nestedReference, replacement);
          return;
        }
        if (nestedReference.path.segments.isEmpty) {
          writePayload(reference, replacement);
          return;
        }
        final replaced = value.replaceAt(nestedReference.path, replacement);
        if (replaced case PortablePathValue(value: final next)) {
          write(reference, next);
        }
      },
    );
  }

  PortablePresentationScope withValues(
    Map<types.ExpressionBindingId, types.DataValue> values,
  ) => PortablePresentationScope(
    bindings: {
      ...bindings,
      for (final entry in values.entries)
        entry.key: PortableExpressionBinding(value: entry.value),
    },
    budget: budget,
    setBinding: setBinding,
    readOnly: readOnly,
    enabled: enabled,
    invokeCommand: invokeCommand,
    watchSearch: watchSearch,
    reload: reload,
    reportStatus: reportStatus,
    commit: commit,
    authoring: authoring,
    catalog: catalog,
    resource: resource,
    onDraftChanged: onDraftChanged,
    openResource: openResource,
    prepareCreation: prepareCreation,
    role: role,
    material: material,
    activePresentations: activePresentations,
    slots: slots,
    slotBuilders: slotBuilders,
    host: host,
  );

  PortablePresentationScope withSlotBuilders(
    Map<String, PortableSlotBuilder> values,
  ) => PortablePresentationScope(
    bindings: bindings,
    budget: budget,
    setBinding: setBinding,
    readOnly: readOnly,
    enabled: enabled,
    invokeCommand: invokeCommand,
    watchSearch: watchSearch,
    reload: reload,
    reportStatus: reportStatus,
    commit: commit,
    authoring: authoring,
    catalog: catalog,
    resource: resource,
    onDraftChanged: onDraftChanged,
    openResource: openResource,
    prepareCreation: prepareCreation,
    role: role,
    material: material,
    activePresentations: activePresentations,
    slots: slots,
    slotBuilders: {...slotBuilders, ...values},
    host: host,
  );

  PortablePresentationScope withActivePresentation(
    types.PresentationId presentation,
  ) => PortablePresentationScope(
    bindings: bindings,
    budget: budget,
    setBinding: setBinding,
    readOnly: readOnly,
    enabled: enabled,
    invokeCommand: invokeCommand,
    watchSearch: watchSearch,
    reload: reload,
    reportStatus: reportStatus,
    commit: commit,
    authoring: authoring,
    catalog: catalog,
    resource: resource,
    onDraftChanged: onDraftChanged,
    openResource: openResource,
    prepareCreation: prepareCreation,
    role: role,
    material: material,
    activePresentations: {...activePresentations, presentation},
    slots: slots,
    slotBuilders: slotBuilders,
    host: host,
  );

  PortablePresentationScope withMaterial(
    catalog_wire.PresentationMaterial value,
  ) => PortablePresentationScope(
    bindings: bindings,
    budget: budget,
    setBinding: setBinding,
    readOnly: readOnly,
    enabled: enabled,
    invokeCommand: invokeCommand,
    watchSearch: watchSearch,
    reload: reload,
    reportStatus: reportStatus,
    commit: commit,
    authoring: authoring,
    catalog: catalog,
    resource: resource,
    onDraftChanged: onDraftChanged,
    openResource: openResource,
    prepareCreation: prepareCreation,
    role: role,
    material: value,
    activePresentations: activePresentations,
    slots: slots,
    slotBuilders: slotBuilders,
    host: host,
  );
}

final class _AuthoredCollectionRow {
  const _AuthoredCollectionRow({
    required this.resource,
    required this.row,
    required this.key,
    required this.canonicalKey,
    required this.selectable,
    required this.scope,
  });

  final types.ResourceId resource;
  final types.DataValue row;
  final types.DataValue key;
  final String canonicalKey;
  final bool selectable;
  final PortablePresentationScope scope;
}

final class PortablePresentationNodeRenderer extends StatelessWidget {
  const PortablePresentationNodeRenderer({
    required this.node,
    required this.scope,
    this.fillAvailableSpace = false,
    super.key,
  });

  final presentation.PresentationNode node;
  final PortablePresentationScope scope;
  final bool fillAvailableSpace;

  @override
  Widget build(BuildContext context) {
    final enabled = _boolean(scope, node.properties.enabledIf, fallback: true);
    if (enabled case _ResolvedFailure(:final message)) {
      return _diagnostic(message);
    }
    final available = (enabled as _ResolvedValue<bool>).value;
    final childScope = scope
        .withReadOnly(node.properties.readOnly)
        .withEnabled(available);
    final element = node.element;
    if (element == null) {
      return _diagnostic("The presentation node has no element");
    }
    final rendered = _renderElement(context, element, childScope);
    var child = node.header == null
        ? rendered
        : _AuthoredPresentationHeader(
            header: node.header!,
            body: rendered,
            scope: childScope,
          );
    if (element case presentation.PresentationElement_sectionWrapper(
      :final value,
    )) {
      child = _decorateSection(context, value, childScope, child);
    }
    return Semantics(
      container: true,
      enabled: available,
      child: IgnorePointer(
        ignoring: !available,
        child: AnimatedOpacity(
          opacity: available ? 1 : 0.55,
          duration: const Duration(milliseconds: 120),
          child: KeyedSubtree(key: ValueKey(node.nodeId), child: child),
        ),
      ),
    );
  }

  Widget _renderElement(
    BuildContext context,
    presentation.PresentationElement element,
    PortablePresentationScope childScope,
  ) => switch (element) {
    presentation.PresentationElement_childrenWrapper(:final value) =>
      _renderChildren(
        value,
        childScope,
        fillAvailableSpace: fillAvailableSpace,
      ),
    presentation.PresentationElement_slotWrapper(:final value) => _renderSlot(
      value,
      childScope,
    ),
    presentation.PresentationElement_conditionalWrapper(:final value) =>
      _renderConditional(value, childScope),
    presentation.PresentationElement_repeatedWrapper(:final value) =>
      _renderRepeated(value, childScope),
    presentation.PresentationElement_textWrapper(:final value) => _renderText(
      context,
      value,
      childScope,
    ),
    presentation.PresentationElement_markdownWrapper(:final value) =>
      _renderMarkdown(value, childScope),
    presentation.PresentationElement_iconWrapper(:final value) => _renderIcon(
      value,
      childScope,
    ),
    presentation.PresentationElement_imageWrapper(:final value) => _renderImage(
      value,
      childScope,
    ),
    presentation.PresentationElement_badgeWrapper(:final value) => _renderBadge(
      context,
      value,
      childScope,
    ),
    presentation.PresentationElement_chipWrapper(:final value) => _renderChip(
      context,
      value,
      childScope,
    ),
    presentation.PresentationElement_progressWrapper(:final value) =>
      _renderProgress(value, childScope),
    presentation.PresentationElement_statusWrapper(:final value) =>
      _renderStatus(context, value, childScope),
    presentation.PresentationElement_dateTimeWrapper(:final value) =>
      _renderDateTime(context, value, childScope),
    presentation.PresentationElement_relativeTimeWrapper(:final value) =>
      _renderRelativeTime(context, value, childScope),
    presentation.PresentationElement_tabsWrapper(:final value) => _AuthoredTabs(
      tabs: value,
      scope: childScope,
    ),
    presentation.PresentationElement_typedFieldWrapper(:final value) =>
      _renderTypedField(value, childScope),
    presentation.PresentationElement_scopedBindingWrapper(:final value) =>
      _renderScopedBinding(value, childScope),
    presentation.PresentationElement_collectionLookupWrapper(:final value) =>
      _renderCollectionLookup(value, childScope),
    presentation.PresentationElement_collectionGraphWrapper(:final value) =>
      _renderCollectionGraph(value, childScope),
    presentation.PresentationElement_textInputWrapper(:final value) =>
      _renderTextInput(value, childScope),
    presentation.PresentationElement_namedInputWrapper(:final value) =>
      _renderNamed(value, childScope),
    presentation.PresentationElement_numericInputWrapper(:final value) =>
      _renderNumericInput(value, childScope),
    presentation.PresentationElement_toggleInputWrapper(:final value) =>
      _renderToggleInput(value, childScope),
    presentation.PresentationElement_selectInputWrapper(:final value) =>
      _renderSelectInput(value, childScope),
    presentation.PresentationElement_searchInputWrapper(:final value) =>
      PortableSearchInput(control: value, scope: childScope),
    presentation.PresentationElement_sliderInputWrapper(:final value) =>
      _renderSliderInput(value, childScope),
    presentation.PresentationElement_dateTimeInputWrapper(:final value) =>
      _renderDateTimeInput(context, value, childScope),
    presentation.PresentationElement_durationInputWrapper(:final value) =>
      _renderDurationInput(value, childScope),
    presentation.PresentationElement_colorInputWrapper(:final value) =>
      _renderColorInput(context, value, childScope),
    presentation.PresentationElement_bytesInputWrapper(:final value) =>
      _renderBytesInput(value, childScope),
    presentation.PresentationElement_enumInputWrapper(:final value) =>
      _renderEnumInput(value, childScope),
    presentation.PresentationElement_polymorphicInputWrapper(:final value) =>
      _renderPolymorphicInput(context, value, childScope),
    presentation.PresentationElement_polymorphicMatchWrapper(:final value) =>
      _renderPolymorphicMatch(value, childScope),
    presentation.PresentationElement_listInputWrapper(:final value) =>
      _renderListInput(context, value, childScope),
    presentation.PresentationElement_setInputWrapper(:final value) =>
      _renderSetInput(context, value, childScope),
    presentation.PresentationElement_mapInputWrapper(:final value) =>
      _renderMapInput(context, value, childScope),
    presentation.PresentationElement_recordInputWrapper(:final value) =>
      _renderRecordInput(value, childScope),
    presentation.PresentationElement_defaultPresentationWrapper(:final value) =>
      _renderDefaultPresentation(value, childScope),
    presentation.PresentationElement_remainingFieldsWrapper(:final value) =>
      _renderRemainingFields(context, value, childScope),
    presentation.PresentationElement_invocationWrapper(:final value) =>
      _renderInvocation(value, childScope),
    presentation.PresentationElement_nullableInputWrapper(:final value) =>
      _renderNullableInput(value, childScope),
    presentation.PresentationElement_linkInputWrapper(:final value) =>
      _renderLinkInput(context, value, childScope),
    presentation.PresentationElement_pageGraphWrapper(:final value) =>
      _renderPageGraph(context, value, childScope),
    presentation.PresentationElement_pageTimelineWrapper(:final value) =>
      _renderPageTimeline(context, value, childScope),
    presentation.PresentationElement_commitControlsWrapper() =>
      _renderCommitControls(childScope),
    presentation.PresentationElement_buttonWrapper(:final value) =>
      _renderButton(value, childScope),
    presentation.PresentationElement_iconButtonWrapper(:final value) =>
      _renderIconButton(value, childScope),
    presentation.PresentationElement_menuWrapper(:final value) => _renderMenu(
      value,
      childScope,
    ),
    presentation.PresentationElement_tooltipWrapper(:final value) =>
      _renderTooltip(value, childScope),
    presentation.PresentationElement_richTextWrapper(:final value) =>
      _renderRichText(value, childScope),
    presentation.PresentationElement_adaptiveLeadingWrapper(:final value) =>
      _renderAdaptiveLeading(value, childScope),
    presentation.PresentationElement_containerWrapper(:final value) =>
      _renderContainer(context, value, childScope),
    presentation.PresentationElement_sectionWrapper(:final value) =>
      _renderSection(context, value, childScope),
    presentation.PresentationElement_paddingWrapper(:final value) => Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        value.start,
        value.top,
        value.end,
        value.bottom,
      ),
      child: PortablePresentationNodeRenderer(
        node: value.child,
        scope: childScope,
      ),
    ),
    presentation.PresentationElement.divider => const Divider(),
    presentation.PresentationElement_spacerWrapper(:final value) =>
      _renderSpacer(value, childScope),
    presentation.PresentationElement_anchorWrapper(:final value) =>
      value.render(context, childScope),
    presentation.PresentationElement_connectionLayerWrapper(:final value) =>
      value.render(context, childScope),
    _ => _diagnostic(
      "Presentation element ${element.kind.name} is not implemented",
    ),
  };

  Widget _renderSlot(
    presentation.PresentationSlotElement element,
    PortablePresentationScope childScope,
  ) {
    final builder = childScope.slotBuilders[element.slotId];
    if (builder != null) return builder(childScope);
    final content = childScope.slots[element.slotId];
    return content == null
        ? const SizedBox.shrink()
        : PortablePresentationNodeRenderer(node: content, scope: childScope);
  }

  Widget _renderCollectionLookup(
    presentation.CollectionLookupElement element,
    PortablePresentationScope childScope,
  ) {
    final collection = _authoredCollection(element.sourceId, childScope);
    if (collection.problem != null) {
      return _diagnostic(collection.problem!);
    }
    final key = childScope.read(element.key);
    if (key == null || key == types.DataValue.unfilled) {
      return PortablePresentationNodeRenderer(
        node: element.missing,
        scope: childScope,
      );
    }
    if (collection.rows.firstOrNull case final first?
        when !_sameCollectionKeyType(first.key, key)) {
      return _diagnostic("The collection lookup key has the wrong type");
    }
    final canonical = canonicalAuthoredValue(key);
    final matches = collection.rows
        .where((candidate) => candidate.canonicalKey == canonical)
        .toList(growable: false);
    if (matches.length > 1) {
      return _diagnostic("The collection lookup key is ambiguous");
    }
    final row = matches.firstOrNull;
    return PortablePresentationNodeRenderer(
      node: row?.scope == null ? element.missing : element.found,
      scope: row?.scope ?? childScope,
    );
  }

  Widget _renderCollectionGraph(
    presentation.CollectionGraphElement element,
    PortablePresentationScope childScope,
  ) {
    final collection = _authoredCollection(element.sourceId, childScope);
    if (collection.problem != null) {
      return _diagnostic(collection.problem!);
    }
    final relation = collection.definition?.relations
        .where((candidate) => candidate.relationId == element.relationId)
        .firstOrNull;
    if (relation == null) {
      return _diagnostic("The collection graph relation is unavailable");
    }
    final evaluatedRoots = childScope.evaluate(element.roots);
    if (evaluatedRoots case PortableExpressionFailed(:final message)) {
      return _diagnostic(message);
    }
    final roots = switch (evaluatedRoots) {
      PortableExpressionAvailable(:final value) => value,
      PortableExpressionUnavailable() || PortableExpressionFailed() => null,
    };
    if (roots == null || roots == types.DataValue.unfilled) {
      return _diagnostic("The collection graph roots are unavailable");
    }
    final rowsByKey = <String, _AuthoredCollectionRow>{};
    for (final row in collection.rows) {
      if (rowsByKey.containsKey(row.canonicalKey)) {
        return _diagnostic("The collection graph contains an ambiguous key");
      }
      rowsByKey[row.canonicalKey] = row;
    }
    final forward = <String, List<String>>{};
    final reverse = <String, List<String>>{};
    for (final row in collection.rows) {
      final targets = row.scope.evaluate(relation.targets);
      if (targets is! PortableExpressionAvailable) continue;
      final keys = <String>[];
      for (final value in _collectionKeyValues(targets.value)) {
        if (!_sameCollectionKeyType(row.key, value)) {
          return _diagnostic(
            "A collection graph relation produced the wrong key type",
          );
        }
        keys.add(canonicalAuthoredValue(value));
      }
      forward[row.canonicalKey] = keys;
      for (final target in keys) {
        reverse.putIfAbsent(target, () => []).add(row.canonicalKey);
      }
    }
    final adjacency =
        element.direction == presentation.CollectionGraphDirection.reverse
        ? reverse
        : forward;
    final rootRows = <_AuthoredCollectionRow>[];
    final seen = <String>{};
    for (final root in _collectionKeyValues(roots)) {
      if (collection.rows.firstOrNull case final first?
          when !_sameCollectionKeyType(first.key, root)) {
        return _diagnostic("A collection graph root has the wrong key type");
      }
      final canonical = canonicalAuthoredValue(root);
      final row = rowsByKey[canonical];
      if (row != null && seen.add(canonical)) rootRows.add(row);
    }
    final rootSlot = _slotId(element.rootSequence.item);
    final childSlot = _slotId(element.children.item);
    if (rootSlot == null || childSlot == null) {
      return _diagnostic("The collection graph slots are unavailable");
    }
    final maximumDepth = element.maximumDepth ?? collection.rows.length;

    Widget renderNode(_AuthoredCollectionRow row, int depth) {
      final children = <_AuthoredCollectionRow>[];
      if (depth < maximumDepth) {
        for (final key in adjacency[row.canonicalKey] ?? const <String>[]) {
          final child = rowsByKey[key];
          if (child != null && seen.add(key)) children.add(child);
        }
      }
      final childValues = types.DataValue.createListValue(
        items: [
          for (final child in children)
            types.ListItem(
              id: types.ItemId(
                value: sha256
                    .convert(utf8.encode(child.canonicalKey))
                    .toString(),
              ),
              value: child.row,
            ),
        ],
      );
      final nodeScope = row.scope.withValues({
        element.childrenBindingId: childValues,
      });
      return PortablePresentationNodeRenderer(
        node: element.node,
        scope: nodeScope.withSlotBuilders({
          childSlot: (_) => _renderCollectionSequence(
            element.children,
            children,
            (child) => renderNode(child, depth + 1),
            element.childBindingId,
            childSlot,
            nodeScope,
          ),
        }),
      );
    }

    return _renderCollectionSequence(
      element.rootSequence,
      rootRows,
      (row) => renderNode(row, 0),
      collection.definition!.rowBindingId,
      rootSlot,
      childScope,
    );
  }

  Widget _renderCollectionSequence(
    presentation.SequencePresentation sequence,
    List<_AuthoredCollectionRow> rows,
    Widget Function(_AuthoredCollectionRow row) content,
    types.ExpressionBindingId itemBinding,
    String slot,
    PortablePresentationScope fallbackScope,
  ) {
    if (rows.isEmpty) {
      final empty = sequence.empty;
      return empty == null
          ? const SizedBox.shrink()
          : PortablePresentationNodeRenderer(node: empty, scope: fallbackScope);
    }
    final children = <Widget>[];
    final itemScopes = <PortablePresentationScope>[];
    for (final indexed in rows.indexed) {
      if (indexed.$1 > 0 && sequence.separator != null) {
        children.add(
          PortablePresentationNodeRenderer(
            node: sequence.separator!,
            scope: indexed.$2.scope,
          ),
        );
        itemScopes.add(indexed.$2.scope);
      }
      final row = indexed.$2;
      final scope = row.scope
          .withValues({itemBinding: row.row})
          .withSlotBuilders({slot: (_) => content(row)});
      children.add(
        PortablePresentationNodeRenderer(node: sequence.item, scope: scope),
      );
      itemScopes.add(scope);
    }
    return _renderSequence(
      children,
      sequence.layout,
      rows.first.scope,
      itemScopes: itemScopes,
    );
  }

  ({
    presentation.PresentationCollectionDefinition? definition,
    List<_AuthoredCollectionRow> rows,
    String? problem,
  })
  _authoredCollection(String sourceId, PortablePresentationScope scope) {
    final definition = scope.material?.dependencies.collections
        .where((candidate) => candidate.sourceId == sourceId)
        .firstOrNull;
    final draft = scope.authoring;
    final catalog = scope.catalog;
    if (definition == null || draft == null || catalog == null) {
      return (
        definition: definition,
        rows: const [],
        problem: "The presentation collection is unavailable",
      );
    }
    final projected = definition.projection;
    final resources = definition.resources;
    if ((projected == null) == (resources == null)) {
      return (
        definition: definition,
        rows: const [],
        problem: "The presentation collection source is invalid",
      );
    }
    final rows = <_AuthoredCollectionRow>[];
    final entries = draft.resources.entries.toList()
      ..sort((left, right) => left.key.value.compareTo(right.key.value));
    for (final entry in entries) {
      final record = entry.value;
      final eligible = resources != null
          ? catalog
                .nominalDefinitions(record.configuration)
                .contains(resources.root)
          : catalog.matchesNamedTemplate(record.configuration, projected!.root);
      if (!eligible) continue;
      final row = resources != null
          ? _authoredResourceRow(record)
          : _authoredProjectionRow(definition, projected!, record, catalog);
      if (row == null) {
        return (
          definition: definition,
          rows: const [],
          problem: "A presentation collection row could not be projected",
        );
      }
      final resourceBinding =
          resources?.resourceBindingId ?? projected!.resourceBindingId;
      final rowScope = scope.withValues({
        definition.rowBindingId: row,
        resourceBinding: types.DataValue.wrapStringValue(entry.key.value),
      });
      final key = rowScope.evaluate(definition.key);
      final selectable = rowScope.evaluate(definition.selectability);
      if (key is! PortableExpressionAvailable) {
        return (
          definition: definition,
          rows: const [],
          problem: "A presentation collection key is unavailable",
        );
      }
      final selected = switch (selectable) {
        PortableExpressionAvailable(
          value: types.DataValue_booleanWrapper(:final value),
        ) =>
          value,
        _ => false,
      };
      rows.add(
        _AuthoredCollectionRow(
          resource: entry.key,
          row: row,
          key: key.value,
          canonicalKey: canonicalAuthoredValue(key.value),
          selectable: selected,
          scope: rowScope,
        ),
      );
    }
    return (definition: definition, rows: rows, problem: null);
  }

  types.DataValue _authoredResourceRow(types.AuthoringRecord record) {
    final payload = types.DataValue.createRecord(fields: record.fields);
    return switch (record.configuration) {
      types.TypeSelection_completeWrapper(:final value) =>
        types.DataValue.createNamed(actualType: value, payload: payload),
      _ => payload,
    };
  }

  types.DataValue? _authoredProjectionRow(
    presentation.PresentationCollectionDefinition definition,
    presentation.PresentationCollectionProjection projection,
    types.AuthoringRecord record,
    CheckedEditorCatalog catalog,
  ) {
    types.DataValue? row;
    for (final field in projection.fields) {
      final source = switch (field.source) {
        presentation.PresentationCollectionProjectionValue_contentWrapper(
          :final value,
        ) =>
          switch (record.readAt(value)) {
            PortablePathValue(:final value) => value,
            PortablePathUnavailable() => types.DataValue.unfilled,
          },
        presentation.PresentationCollectionProjectionValue_literalWrapper(
          :final value,
        ) =>
          value,
        _ => null,
      };
      if (source == null) return null;
      if (field.target.segments.isEmpty) {
        if (row != null || projection.fields.length != 1) return null;
        row = source;
        continue;
      }
      row = _writeProjectionValue(
        row ?? types.DataValue.createRecord(fields: const []),
        field.target.segments.toList(growable: false),
        source,
      );
      if (row == null) return null;
    }
    row ??= types.DataValue.createRecord(fields: const []);
    if (row == types.DataValue.unfilled) return row;
    final applied = catalog.applyTemplate(
      definition.rowType,
      record.configuration,
    );
    return applied == null
        ? row
        : _completeProjectedValue(row, applied, catalog);
  }

  types.DataValue? _completeProjectedValue(
    types.DataValue authored,
    types.TypeUse expected,
    CheckedEditorCatalog catalog,
  ) {
    if (authored == types.DataValue.unfilled) return authored;
    return switch (expected) {
      types.TypeUse_nullableWrapper(:final value) =>
        authored == types.DataValue.null_
            ? authored
            : _completeProjectedValue(authored, value.value, catalog),
      types.TypeUse_namedWrapper(:final value) => _completeProjectedNamedValue(
        value: authored,
        expected: value,
        catalog: catalog,
      ),
      _ => authored,
    };
  }

  types.DataValue? _completeProjectedNamedValue({
    required types.DataValue value,
    required types.NamedTypeUse expected,
    required CheckedEditorCatalog catalog,
  }) {
    final payload = switch (value) {
      types.DataValue_namedWrapper(:final value)
          when value.actualType == expected =>
        value.payload,
      types.DataValue_namedWrapper() => null,
      _ => value,
    };
    if (payload == null) return null;
    final representation = catalog
        .published(expected.definition)
        ?.definition
        .representation;
    if (representation is! types.RepresentationTemplate_recordWrapper) {
      return types.DataValue.createNamed(
        actualType: expected,
        payload: payload,
      );
    }
    final projected = payload.authoredRecord;
    if (projected == null) return null;
    final fields = catalog.fields(types.TypeSelection.wrapComplete(expected));
    final expectedNames = {for (final field in fields) field.template.key};
    if (projected.fields.any((field) => !expectedNames.contains(field.name))) {
      return null;
    }
    final completed = <types.FieldValue>[];
    for (final field in fields) {
      final existing = projected.fields
          .where((candidate) => candidate.name == field.template.key)
          .firstOrNull;
      final expectedField = field.type;
      final fieldValue = existing?.value ?? types.DataValue.unfilled;
      final normalized = expectedField == null
          ? fieldValue
          : _completeProjectedValue(fieldValue, expectedField, catalog);
      if (normalized == null) return null;
      completed.add(
        types.FieldValue(name: field.template.key, value: normalized),
      );
    }
    return types.DataValue.createNamed(
      actualType: expected,
      payload: types.DataValue.createRecord(fields: completed),
    );
  }

  types.DataValue? _writeProjectionValue(
    types.DataValue current,
    List<types.PathSegment> segments,
    types.DataValue value,
  ) {
    if (segments.isEmpty) return value;
    final field = switch (segments.first) {
      types.PathSegment_fieldWrapper(:final value) => value.name,
      _ => null,
    };
    if (field == null) return null;
    final payload = current.authoredPayload;
    final record = payload.authoredRecord;
    if (record == null) return null;
    final fields = <types.FieldValue>[...record.fields];
    final index = fields.indexWhere((candidate) => candidate.name == field);
    final nested = _writeProjectionValue(
      index < 0
          ? types.DataValue.createRecord(fields: const [])
          : fields[index].value,
      segments.sublist(1),
      value,
    );
    if (nested == null) return null;
    final replacement = types.FieldValue(name: field, value: nested);
    if (index < 0) {
      fields.add(replacement);
    } else {
      fields[index] = replacement;
    }
    return current.withAuthoredPayload(
      types.DataValue.createRecord(fields: fields),
    );
  }

  Iterable<types.DataValue> _collectionKeyValues(types.DataValue value) {
    final items = value.authoredItems;
    if (items != null) return items.map((item) => item.value);
    return [value];
  }

  bool _sameCollectionKeyType(
    types.DataValue expected,
    types.DataValue actual,
  ) {
    if (expected.kind != actual.kind) return false;
    return switch ((expected, actual)) {
      (
        types.DataValue_namedWrapper(value: final expectedNamed),
        types.DataValue_namedWrapper(value: final actualNamed),
      ) =>
        expectedNamed.actualType == actualNamed.actualType,
      _ => true,
    };
  }

  String? _slotId(presentation.PresentationNode node) => switch (node.element) {
    presentation.PresentationElement_slotWrapper(:final value) => value.slotId,
    _ => null,
  };

  Widget _renderPolymorphicMatch(
    presentation.PolymorphicMatchElement element,
    PortablePresentationScope childScope,
  ) {
    final value = childScope.read(element.binding);
    final actual = switch (value) {
      types.DataValue_namedWrapper(:final value) => types.TypeUse.wrapNamed(
        value.actualType,
      ),
      _ => null,
    };
    if (actual == null) {
      final fallback = element.fallback;
      return fallback == null
          ? const SizedBox.shrink()
          : PortablePresentationNodeRenderer(node: fallback, scope: childScope);
    }
    final selected = element.cases
        .where(
          (candidate) =>
              childScope.catalog?.isReadableAs(
                actual,
                candidate.concreteType,
              ) ??
              actual == candidate.concreteType,
        )
        .firstOrNull;
    final node = selected?.child ?? element.fallback;
    if (node == null) return const SizedBox.shrink();
    final nested = childScope.withBinding(
      element.binding,
      element.scopeBindingId,
    );
    return nested == null
        ? _diagnostic("The polymorphic value is unavailable")
        : PortablePresentationNodeRenderer(node: node, scope: nested);
  }

  Widget _renderInvocation(
    presentation.PresentationInvocation invocation,
    PortablePresentationScope childScope,
  ) {
    final catalog = childScope.catalog;
    if (catalog == null) {
      return _diagnostic("The presentation catalog is unavailable");
    }
    var nested = childScope;
    types.TypeSelection? target;
    for (final argument in invocation.arguments) {
      final value = nested.read(argument.binding);
      if (target == null && value is types.DataValue_namedWrapper) {
        target = types.TypeSelection.wrapComplete(value.value.actualType);
      }
      final rebound = nested.withBinding(argument.binding, argument.input);
      if (rebound == null) {
        return _diagnostic("A presentation argument is unavailable");
      }
      nested = rebound;
    }
    target ??= switch (nested
        .bindings[_configuredValueBindingId]
        ?.value
        .authoredActualType) {
      final actual? => types.TypeSelection.wrapComplete(actual),
      null => null,
    };
    target ??= switch ((childScope.authoring, childScope.resource)) {
      (final draft?, final resource?) =>
        draft.resource(resource)?.configuration,
      _ => null,
    };
    final material = target == null
        ? null
        : catalog.presentationMaterial(invocation.presentationId, target);
    if (material == null) {
      return _diagnostic("The invoked presentation is unavailable");
    }
    if (nested.activePresentations.contains(invocation.presentationId)) {
      return _diagnostic("The invoked presentation is recursive");
    }
    return PortablePresentationNodeRenderer(
      node: material.layout,
      scope: nested
          .withActivePresentation(invocation.presentationId)
          .withMaterial(material),
    );
  }

  Widget _renderChildren(
    presentation.ChildrenElement element,
    PortablePresentationScope childScope, {
    required bool fillAvailableSpace,
  }) => switch (element) {
    presentation.ChildrenElement_columnWrapper(:final value) => _axis(
      value,
      childScope,
      vertical: true,
      fillAvailableSpace: fillAvailableSpace,
    ),
    presentation.ChildrenElement_rowWrapper(:final value) => _axis(
      value,
      childScope,
      vertical: false,
      fillAvailableSpace: fillAvailableSpace,
    ),
    presentation.ChildrenElement_wrapWrapper(:final value) => Wrap(
      spacing: value.layout.spacing,
      runSpacing: value.layout.runSpacing,
      alignment: _wrapAlignment(value.layout.mainAxisAlignment),
      crossAxisAlignment: _wrapCrossAlignment(value.layout.crossAxisAlignment),
      children: [
        for (final child in value.children)
          PortablePresentationNodeRenderer(node: child, scope: childScope),
      ],
    ),
    presentation.ChildrenElement_gridWrapper(:final value) => _presentationGrid(
      value.layout,
      children: [
        for (final child in value.children)
          PortablePresentationNodeRenderer(node: child, scope: childScope),
      ],
    ),
    presentation.ChildrenElement_stackWrapper(:final value) => Stack(
      children: [
        for (final child in value.children)
          PortablePresentationNodeRenderer(node: child, scope: childScope),
      ],
    ),
    _ => _diagnostic("Children layout ${element.kind.name} is not implemented"),
  };

  Widget _axis(
    presentation.AxisChildrenElement element,
    PortablePresentationScope childScope, {
    required bool vertical,
    required bool fillAvailableSpace,
  }) {
    Widget buildAxis(double? fixedChildMaximumHeight) {
      final children = <Widget>[];
      final forwardsViewport =
          vertical && fillAvailableSpace && element.children.length == 1;
      var first = true;
      for (final child in element.children) {
        if (!first && element.layout.spacing > 0) {
          children.add(
            SizedBox(
              width: vertical ? null : element.layout.spacing,
              height: vertical ? element.layout.spacing : null,
            ),
          );
        }
        first = false;
        var rendered = switch (child) {
          presentation.AxisChild_fixedWrapper(:final value) =>
            PortablePresentationNodeRenderer(node: value, scope: childScope),
          presentation.AxisChild_flexibleWrapper(:final value) => Flexible(
            flex: value.flex <= 0 ? 1 : value.flex,
            fit: value.fit == presentation.FlexFit.tight
                ? FlexFit.tight
                : FlexFit.loose,
            child: PortablePresentationNodeRenderer(
              node: value.child,
              scope: childScope,
            ),
          ),
          _ => _diagnostic("The axis child is unknown"),
        };
        if (fixedChildMaximumHeight != null &&
            child is presentation.AxisChild_fixedWrapper) {
          rendered = ConstrainedBox(
            constraints: BoxConstraints(maxHeight: fixedChildMaximumHeight),
            child: rendered,
          );
        }
        children.add(
          forwardsViewport && child is presentation.AxisChild_fixedWrapper
              ? Expanded(child: rendered)
              : rendered,
        );
      }
      if (vertical) {
        return Column(
          mainAxisSize: fillAvailableSpace
              ? MainAxisSize.max
              : MainAxisSize.min,
          mainAxisAlignment: _mainAxis(element.layout.mainAxisAlignment),
          crossAxisAlignment: _crossAxis(element.layout.crossAxisAlignment),
          children: children,
        );
      }
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: _mainAxis(element.layout.mainAxisAlignment),
        crossAxisAlignment: _crossAxis(element.layout.crossAxisAlignment),
        children: children,
      );
    }

    if (!vertical || element.children.length != 1) return buildAxis(null);
    return LayoutBuilder(
      builder: (context, constraints) => buildAxis(
        constraints.hasBoundedHeight ? constraints.maxHeight : null,
      ),
    );
  }

  Widget _renderConditional(
    presentation.ConditionalElement element,
    PortablePresentationScope childScope,
  ) {
    final condition = _boolean(childScope, element.condition);
    return switch (condition) {
      _ResolvedValue(value: true) => PortablePresentationNodeRenderer(
        node: element.whenTrue,
        scope: childScope,
      ),
      _ResolvedValue(value: false) when element.whenFalse != null =>
        PortablePresentationNodeRenderer(
          node: element.whenFalse!,
          scope: childScope,
        ),
      _ResolvedValue() => const SizedBox.shrink(),
      _ResolvedFailure(:final message) => _diagnostic(message),
    };
  }

  Widget _renderRepeated(
    presentation.RepeatedElement element,
    PortablePresentationScope childScope,
  ) {
    final evaluated = childScope.evaluate(element.source);
    if (evaluated is! PortableExpressionAvailable) {
      return _diagnostic("The repeated value is unavailable");
    }
    final rows = switch (evaluated.value.authoredPayload) {
      types.DataValue_listValueWrapper(:final value) ||
      types.DataValue_setValueWrapper(:final value) => [
        for (final item in value.items)
          (id: item.id, value: item.value, mapValue: false),
      ],
      types.DataValue_mapValueWrapper(:final value) => [
        for (final row in value.rows)
          (id: row.id, value: row.value, mapValue: true),
      ],
      _ => null,
    };
    if (rows == null) {
      return _diagnostic("The repeated value is not a collection");
    }
    if (rows.isEmpty) {
      final empty = element.presentation.empty;
      return empty == null
          ? const SizedBox.shrink()
          : PortablePresentationNodeRenderer(node: empty, scope: childScope);
    }
    final children = <Widget>[];
    final itemScopes = <PortablePresentationScope>[];
    final source = switch (element.source) {
      expression.ExpressionNode_readWrapper(:final value) => binding.BindingRef(
        bindingId: value.binding,
        path: value.path,
      ),
      _ => null,
    };
    for (final indexed in rows.indexed) {
      if (indexed.$1 > 0 && element.presentation.separator != null) {
        children.add(
          PortablePresentationNodeRenderer(
            node: element.presentation.separator!,
            scope: childScope,
          ),
        );
        itemScopes.add(childScope);
      }
      final row = indexed.$2;
      final rowReference = source == null
          ? null
          : binding.BindingRef(
              bindingId: source.bindingId,
              path: types.ValuePath(
                segments: [
                  ...source.path.segments,
                  types.PathSegment.createItem(id: row.id),
                  if (row.mapValue) types.PathSegment.mapValue,
                ],
              ),
            );
      final itemScope = rowReference == null
          ? childScope.withValues({element.itemBindingId: row.value})
          : childScope.withBinding(rowReference, element.itemBindingId);
      children.add(
        itemScope == null
            ? _diagnostic("The repeated collection item is unavailable")
            : PortablePresentationNodeRenderer(
                node: element.presentation.item,
                scope: itemScope,
              ),
      );
      itemScopes.add(itemScope ?? childScope);
    }
    return _renderSequence(
      children,
      element.presentation.layout,
      childScope,
      itemScopes: itemScopes,
    );
  }

  Widget _renderSequence(
    List<Widget> children,
    presentation.SequenceLayout layout,
    PortablePresentationScope childScope, {
    List<PortablePresentationScope>? itemScopes,
  }) => switch (layout) {
    presentation.SequenceLayout_childrenWrapper(:final value) =>
      _renderSequenceChildren(children, value),
    presentation.SequenceLayout_hierarchyWrapper(:final value) =>
      value.renderPortableHierarchy(
        scope: childScope,
        itemScopes: itemScopes ?? List.filled(children.length, childScope),
        children: children,
      ),
    _ => _diagnostic("The sequence layout is unavailable"),
  };

  Widget _renderSequenceChildren(
    List<Widget> children,
    presentation.ChildrenLayout layout,
  ) => switch (layout) {
    presentation.ChildrenLayout_columnWrapper(:final value) => Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: _mainAxis(value.mainAxisAlignment),
      crossAxisAlignment: _crossAxis(value.crossAxisAlignment),
      spacing: value.spacing,
      children: children,
    ),
    presentation.ChildrenLayout_rowWrapper(:final value) => Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: _mainAxis(value.mainAxisAlignment),
      crossAxisAlignment: _crossAxis(value.crossAxisAlignment),
      spacing: value.spacing,
      children: children,
    ),
    presentation.ChildrenLayout_wrapWrapper(:final value) => Wrap(
      spacing: value.spacing,
      runSpacing: value.runSpacing,
      alignment: _wrapAlignment(value.mainAxisAlignment),
      crossAxisAlignment: _wrapCrossAlignment(value.crossAxisAlignment),
      children: children,
    ),
    presentation.ChildrenLayout_gridWrapper(:final value) => _presentationGrid(
      value,
      children: children,
    ),
    presentation.ChildrenLayout.stack => Stack(children: children),
    _ => _diagnostic("The repeated children layout is unavailable"),
  };

  Widget _renderText(
    BuildContext context,
    presentation.TextContent content,
    PortablePresentationScope childScope,
  ) {
    final value = _string(childScope, content.value);
    if (value case _ResolvedFailure(:final message)) {
      return _diagnostic(message);
    }
    final text = (value as _ResolvedValue<String>).value;
    final color = _optionalTextColor(childScope, content.color);
    if (color case _ResolvedFailure(:final message)) {
      return _diagnostic(message);
    }
    final fontSize = _optionalTextNumber(
      childScope,
      content.fontSize,
      name: "Font size",
      minimum: 0,
    );
    if (fontSize case _ResolvedFailure(:final message)) {
      return _diagnostic(message);
    }
    final weight = _optionalTextNumber(
      childScope,
      content.fontWeight,
      name: "Font weight",
      minimum: 1,
      maximum: 1000,
    );
    if (weight case _ResolvedFailure(:final message)) {
      return _diagnostic(message);
    }
    final italic = _optionalTextNumber(
      childScope,
      content.fontItalic,
      name: "Font italic",
      minimum: 0,
      maximum: 1,
    );
    if (italic case _ResolvedFailure(:final message)) {
      return _diagnostic(message);
    }
    final opticalSize = _optionalTextNumber(
      childScope,
      content.fontOpticalSize,
      name: "Font optical size",
      minimumExclusive: 0,
    );
    if (opticalSize case _ResolvedFailure(:final message)) {
      return _diagnostic(message);
    }
    final slant = _optionalTextNumber(
      childScope,
      content.fontSlant,
      name: "Font slant",
      minimumExclusive: -90,
      maximumExclusive: 90,
    );
    if (slant case _ResolvedFailure(:final message)) {
      return _diagnostic(message);
    }
    final width = _optionalTextNumber(
      childScope,
      content.fontWidth,
      name: "Font width",
      minimumExclusive: 0,
    );
    if (width case _ResolvedFailure(:final message)) {
      return _diagnostic(message);
    }
    final alignment = _optionalTextAlignment(childScope, content.textAlignment);
    if (alignment case _ResolvedFailure(:final message)) {
      return _diagnostic(message);
    }
    final lineHeight = _optionalTextNumber(
      childScope,
      content.lineHeight,
      name: "Line height",
      minimum: 0,
    );
    if (lineHeight case _ResolvedFailure(:final message)) {
      return _diagnostic(message);
    }
    final letterSpacing = _optionalTextNumber(
      childScope,
      content.letterSpacing,
      name: "Letter spacing",
    );
    if (letterSpacing case _ResolvedFailure(:final message)) {
      return _diagnostic(message);
    }
    final decoration = _optionalTextDecoration(childScope, content.decoration);
    if (decoration case _ResolvedFailure(:final message)) {
      return _diagnostic(message);
    }
    final semanticLabel = _optionalTextString(
      childScope,
      content.semanticLabel,
      name: "Semantic label",
    );
    if (semanticLabel case _ResolvedFailure(:final message)) {
      return _diagnostic(message);
    }
    final paragraph = content.paragraph;
    final widget = Text(
      text,
      semanticsLabel: (semanticLabel as _ResolvedValue<String?>).value,
      textAlign: (alignment as _ResolvedValue<TextAlign?>).value,
      maxLines: paragraph.maxLines,
      softWrap: paragraph.softWrap,
      overflow:
          paragraph.overflow == presentation.PresentationTextOverflow.ellipsis
          ? TextOverflow.ellipsis
          : TextOverflow.clip,
      style: DefaultTextStyle.of(context).style.copyWith(
        color:
            (color as _ResolvedValue<Color?>).value ??
            _paragraphToneColor(context, paragraph.tone),
        fontSize: (fontSize as _ResolvedValue<double?>).value,
        fontVariations: [
          if ((weight as _ResolvedValue<double?>).value case final value?)
            FontVariation.weight(value),
          if ((italic as _ResolvedValue<double?>).value case final value?)
            FontVariation.italic(value),
          if ((opticalSize as _ResolvedValue<double?>).value case final value?)
            FontVariation.opticalSize(value),
          if ((slant as _ResolvedValue<double?>).value case final value?)
            FontVariation.slant(value),
          if ((width as _ResolvedValue<double?>).value case final value?)
            FontVariation.width(value),
        ],
        height: (lineHeight as _ResolvedValue<double?>).value,
        letterSpacing: (letterSpacing as _ResolvedValue<double?>).value,
        decoration: (decoration as _ResolvedValue<TextDecoration?>).value,
      ),
    );
    return paragraph.selectable ? SelectionArea(child: widget) : widget;
  }

  Widget _renderMarkdown(
    presentation.TextContent content,
    PortablePresentationScope childScope,
  ) {
    final value = _string(childScope, content.value);
    return switch (value) {
      _ResolvedValue(:final value) => MarkdownBody(
        data: value,
        selectable: content.paragraph.selectable,
      ),
      _ResolvedFailure(:final message) => _diagnostic(message),
    };
  }

  Widget _renderIcon(
    presentation.IconContent content,
    PortablePresentationScope childScope,
  ) {
    final name = _string(childScope, content.name);
    if (name case _ResolvedFailure(:final message)) {
      return _diagnostic(message);
    }
    final iconName = (name as _ResolvedValue<String>).value;
    final label = content.semanticLabel == null
        ? null
        : switch (_string(childScope, content.semanticLabel!)) {
            _ResolvedValue(:final value) => value,
            _ => null,
          };
    return Semantics(
      label: label,
      image: true,
      child: ExcludeSemantics(
        child: Icones(
          iconName,
          color: _color(childScope, content.color),
          size: _number(childScope, content.size),
        ),
      ),
    );
  }

  Widget _renderImage(
    presentation.ImageContent content,
    PortablePresentationScope childScope,
  ) {
    final source = _string(childScope, content.source);
    if (source case _ResolvedFailure(:final message)) {
      return _diagnostic(message);
    }
    final label = _controlString(content.semanticLabel, childScope);
    return Image.network(
      (source as _ResolvedValue<String>).value,
      semanticLabel: label,
      errorBuilder: (_, _, _) => _diagnostic("The image could not be loaded"),
    );
  }

  Widget _renderBadge(
    BuildContext context,
    presentation.BadgeContent content,
    PortablePresentationScope childScope,
  ) {
    final label = _string(childScope, content.label);
    return switch (label) {
      _ResolvedValue(:final value) => DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.spacing.space2,
            vertical: 3,
          ),
          child: Text(value),
        ),
      ),
      _ResolvedFailure(:final message) => _diagnostic(message),
    };
  }

  Widget _renderChip(
    BuildContext context,
    presentation.ChipContent content,
    PortablePresentationScope childScope,
  ) {
    final label = _string(childScope, content.label);
    if (label case _ResolvedFailure(:final message)) {
      return _diagnostic(message);
    }
    final resolvedColor = _optionalTextColor(childScope, content.color);
    if (resolvedColor case _ResolvedFailure(:final message)) {
      return _diagnostic(message);
    }
    final color =
        (resolvedColor as _ResolvedValue<Color?>).value ??
        Theme.of(context).colorScheme.primary;
    final hsl = HSLColor.fromColor(color);
    final foreground = Theme.of(context).brightness == Brightness.dark
        ? color
        : hsl.withLightness(hsl.lightness.clamp(0.2, 0.4)).toColor();
    return Chip(
      label: Text(
        (label as _ResolvedValue<String>).value,
        style: DefaultTextStyle.of(context).style.copyWith(color: foreground),
      ),
      backgroundColor: color.withValues(alpha: 0.18),
      side: BorderSide(color: color),
    );
  }

  Widget _renderProgress(
    presentation.ProgressContent content,
    PortablePresentationScope childScope,
  ) {
    final value = _number(childScope, content.value);
    final maximum = _number(childScope, content.maximum);
    if (value == null || maximum == null || maximum <= 0) {
      return _diagnostic("The progress value is unavailable");
    }
    final label = _controlString(content.label, childScope);
    return Semantics(
      label: label,
      value: value.toString(),
      child: LinearProgressIndicator(value: (value / maximum).clamp(0, 1)),
    );
  }

  Widget _renderStatus(
    BuildContext context,
    presentation.StatusContent content,
    PortablePresentationScope childScope,
  ) {
    final result = childScope.evaluate(content.value);
    if (result is! PortableExpressionAvailable) {
      return _diagnostic("The status value is unavailable");
    }
    final appearance =
        content.cases
            .where((candidate) => candidate.match == result.value)
            .firstOrNull
            ?.appearance ??
        content.fallback;
    final tone = appearance?.tone ?? presentation.StatusTone.unknownStatus;
    final labelResult = appearance?.label == null
        ? _ResolvedValue(portableExpressionDisplayText(result.value))
        : _string(childScope, appearance!.label!);
    if (labelResult case _ResolvedFailure(:final message)) {
      return _diagnostic(message);
    }
    final label = (labelResult as _ResolvedValue<String>).value;
    final color = _statusColor(context, tone);
    return Semantics(
      label: label,
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_statusIcon(tone), size: 14, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: DefaultTextStyle.of(context).style
                    .copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _renderDateTime(
    BuildContext context,
    presentation.DateTimeContent content,
    PortablePresentationScope childScope,
  ) {
    final value = childScope.evaluate(content.value);
    final format = _string(childScope, content.format);
    final timestamp = switch (value) {
      PortableExpressionAvailable(
        value: types.DataValue_timestampWrapper(:final value),
      ) =>
        value,
      _ => null,
    };
    if (timestamp == null || format is! _ResolvedValue<String>) {
      return _diagnostic("The date and time value is unavailable");
    }
    try {
      final display = content.timeZone == presentation.DateTimeZone.utc
          ? timestamp.toUtc()
          : timestamp.toLocal();
      return SelectableText(
        DateFormat(
          format.value,
          Localizations.localeOf(context).toLanguageTag(),
        ).format(display),
      );
    } on FormatException catch (error) {
      return _diagnostic("Invalid date and time format: ${error.message}");
    }
  }

  Widget _renderRelativeTime(
    BuildContext context,
    presentation.RelativeTimeContent content,
    PortablePresentationScope childScope,
  ) {
    final value = childScope.evaluate(content.value);
    final timestamp = switch (value) {
      PortableExpressionAvailable(
        value: types.DataValue_timestampWrapper(:final value),
      ) =>
        value,
      _ => null,
    };
    if (timestamp == null) {
      return _diagnostic("The relative time value is unavailable");
    }
    return HookBuilder(
      builder: (context) {
        final now = clock.now();
        final display = content.timeZone == presentation.DateTimeZone.utc
            ? timestamp.toUtc()
            : timestamp.toLocal();
        final displayNow = content.timeZone == presentation.DateTimeZone.utc
            ? now.toUtc()
            : now.toLocal();
        final description = describeRelativeTime(
          value: display,
          now: displayNow,
        );
        useRefreshAt(description.nextRefreshAt, now: clock.now);
        final tooltipKey = useMemoized(GlobalKey<TooltipState>.new);
        final label = content.style == presentation.RelativeTimeStyle.compact
            ? description.compact
            : description.natural;
        final exact = DateFormat(
          "yyyy/MM/dd HH:mm:ss",
          Localizations.localeOf(context).toLanguageTag(),
        ).format(display);
        return Tooltip(
          key: tooltipKey,
          message: exact,
          child: Focus(
            onFocusChange: (focused) {
              if (!focused) {
                Tooltip.dismissAllToolTips();
                return;
              }
              WidgetsBinding.instance.addPostFrameCallback((_) {
                tooltipKey.currentState?.ensureTooltipVisible();
              });
            },
            child: Semantics(
              label: description.natural,
              child: ExcludeSemantics(child: Text(label)),
            ),
          ),
        );
      },
    );
  }

  Widget _renderTypedField(
    presentation.TypedFieldElement element,
    PortablePresentationScope childScope,
  ) {
    final custom = element.presentation;
    if (custom == null) {
      return _diagnostic("The typed field has no presentation");
    }
    final nested = childScope.withConfiguredValue(element.binding);
    if (nested == null) {
      return _diagnostic("The typed field binding is unavailable");
    }
    return PortablePresentationNodeRenderer(node: custom, scope: nested);
  }

  Widget _renderScopedBinding(
    presentation.ScopedBindingElement element,
    PortablePresentationScope childScope,
  ) {
    final nested = childScope.withBinding(
      element.binding,
      element.scopeBindingId,
    );
    if (nested == null) {
      return _diagnostic("The scoped binding is unavailable");
    }
    return PortablePresentationNodeRenderer(node: element.child, scope: nested);
  }

  Widget _renderTextInput(
    presentation.TextControl textControl,
    PortablePresentationScope childScope,
  ) {
    final control = textControl.control;
    final currentValue = childScope.read(control.binding);
    final current = switch (currentValue?.authoredPayload) {
      types.DataValue_stringValueWrapper(:final value) => value,
      final value? when value == types.DataValue.unfilled => "",
      _ => null,
    };
    if (current == null) {
      return _diagnostic("The text control binding is unavailable");
    }
    final placeholder = textControl.placeholder == null
        ? null
        : switch (_string(childScope, textControl.placeholder!)) {
            _ResolvedValue(:final value) => value,
            _ => null,
          };
    final prefix = control.prefix == null
        ? const Icon(Icons.edit_outlined, size: 18)
        : PortablePresentationNodeRenderer(
            node: control.prefix!,
            scope: childScope,
          );
    final multiline = textControl.multiline == true;
    return _controlFrame(
      control,
      childScope,
      EditorTextField(
        key: ValueKey("${node.nodeId}.input"),
        text: current,
        readOnly: childScope.readOnly,
        enabled: childScope.enabled,
        singleLine: !multiline,
        minLines: multiline ? 3 : 1,
        maxLines: multiline ? 8 : 1,
        hintText: placeholder ?? "Enter text",
        prefix: prefix,
        onChanged: (next) => childScope.write(
          control.binding,
          types.DataValue.wrapStringValue(next),
        ),
      ),
    );
  }

  Widget _renderNumericInput(
    presentation.BoundControl control,
    PortablePresentationScope childScope,
  ) {
    final current = childScope.read(control.binding)?.authoredPayload;
    final expected = childScope.expectedPayloadType(control.binding);
    final text = portableNumericInputText(current: current, expected: expected);
    if (current == null || text == null) {
      return _diagnostic("The numeric control binding is unavailable");
    }
    return _controlFrame(
      control,
      childScope,
      ValidatedTextField<types.DataValue>(
        key: ValueKey("${node.nodeId}.input"),
        value: current == types.DataValue.unfilled ? null : current,
        name: "number",
        icon: HeroiconsSolid.hashtag,
        mixed: current == types.DataValue.unfilled,
        readOnly: childScope.readOnly || !childScope.enabled,
        keyboardType: const TextInputType.numberWithOptions(
          signed: true,
          decimal: true,
        ),
        inputFormatters: [
          TextInputFormatter.withFunction((oldValue, newValue) {
            return acceptsPortableNumericInput(
                  current: current,
                  expected: expected,
                  text: newValue.text,
                )
                ? newValue
                : oldValue;
          }),
        ],
        decoration: InputDecoration(
          hintText: "Enter a number",
          helperText: current == types.DataValue.unfilled
              ? "This value is Unfilled"
              : null,
          prefixIcon: _paddedControlPrefix(control, childScope),
        ),
        deserialize: (_) => text,
        serialize: (next) {
          if (next.isEmpty || next == "-" || next == ".") {
            return types.DataValue.unfilled;
          }
          final replacement = admitPortableNumericInput(
            current: current,
            expected: expected,
            text: next,
          );
          if (replacement == null) {
            throw const FormatException("Enter a valid number");
          }
          return replacement;
        },
        onChanged: (replacement) => replacement == types.DataValue.unfilled
            ? childScope.write(control.binding, types.DataValue.unfilled)
            : childScope.writePayload(control.binding, replacement),
      ),
    );
  }

  Widget _renderToggleInput(
    presentation.BoundControl control,
    PortablePresentationScope childScope,
  ) {
    final current = childScope.read(control.binding)?.authoredPayload;
    if (current != types.DataValue.unfilled &&
        current is! types.DataValue_booleanWrapper) {
      return _diagnostic("The toggle control binding is unavailable");
    }
    final editable = childScope.enabled && !childScope.readOnly;
    final selected = switch (current) {
      types.DataValue_booleanWrapper(:final value) => value,
      _ => null,
    };
    final input = current == types.DataValue.unfilled
        ? _withControlPrefix(
            control,
            childScope,
            AdaptiveChoiceControl<bool>(
              key: ValueKey("${node.nodeId}.input"),
              choices: const {true: "On", false: "Off"},
              selected: null,
              enabled: editable,
              initialization: SelectionInitializationPolicy.explicit,
              onSelected: (next) {
                if (next != null) {
                  childScope.writePayload(
                    control.binding,
                    types.DataValue.wrapBoolean(next),
                  );
                }
              },
            ),
          )
        : SwitchListTile(
            key: ValueKey("${node.nodeId}.input"),
            contentPadding: EdgeInsets.zero,
            value: selected!,
            title: Text(selected ? "On" : "Off"),
            secondary: _controlPrefix(control, childScope),
            onChanged: editable
                ? (next) => childScope.writePayload(
                    control.binding,
                    types.DataValue.wrapBoolean(next),
                  )
                : null,
          );
    return _controlFrame(control, childScope, input);
  }

  Widget _renderSelectInput(
    presentation.SelectControl select,
    PortablePresentationScope childScope,
  ) {
    final current = childScope.read(select.control.binding)?.authoredPayload;
    if (current == null) {
      return _diagnostic("The select control binding is unavailable");
    }
    final options = <({String id, String label, types.DataValue value})>[];
    for (final option in select.options) {
      final label = _string(childScope, option.label);
      final value = childScope.evaluate(option.value);
      if (label is _ResolvedValue<String> &&
          value is PortableExpressionAvailable) {
        options.add((
          id: option.optionId,
          label: label.value,
          value: value.value,
        ));
      }
    }
    final selected = options
        .where((option) => option.value.authoredPayload == current)
        .firstOrNull
        ?.id;
    return _controlFrame(
      select.control,
      childScope,
      _withControlPrefix(
        select.control,
        childScope,
        AdaptiveChoiceControl<String>(
          key: ValueKey("${node.nodeId}.input"),
          choices: {for (final option in options) option.id: option.label},
          selected: selected,
          enabled: childScope.enabled && !childScope.readOnly,
          initialization: SelectionInitializationPolicy.explicit,
          onSelected: (id) {
            final option = options.where((item) => item.id == id).firstOrNull;
            if (option != null) {
              childScope.write(select.control.binding, option.value);
            }
          },
        ),
      ),
    );
  }

  Widget _renderSliderInput(
    presentation.SliderControl slider,
    PortablePresentationScope childScope,
  ) {
    final authored = childScope.read(slider.control.binding);
    final current = authored?.authoredPayload;
    final minimum = _number(childScope, slider.minimum);
    final maximum = _number(childScope, slider.maximum);
    final divisions = _number(childScope, slider.divisions)?.round();
    if (authored == null ||
        minimum == null ||
        maximum == null ||
        minimum >= maximum) {
      return _diagnostic("The slider configuration is unavailable");
    }
    final expected = childScope.expectedPayloadType(slider.control.binding);
    types.DataValue? replacement(double next) =>
        admitPortableNumericInput(
          current: current,
          expected: expected,
          text: switch (expected) {
            types.TypeUse_scalarWrapper(
              value: types.ScalarKind_integerWrapper(),
            ) =>
              next.round().toString(),
            _ => next.toString(),
          },
        ) ??
        (expected == null ? types.DataValue.wrapFloat(next) : null);
    if (current == types.DataValue.unfilled) {
      final initial = replacement(minimum);
      if (initial == null) {
        return _diagnostic("The slider configuration is unavailable");
      }
      return _controlFrame(
        slider.control,
        childScope,
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: OutlinedButton.icon(
            key: ValueKey("${node.nodeId}.input"),
            onPressed: childScope.enabled && !childScope.readOnly
                ? () => childScope.writePayload(slider.control.binding, initial)
                : null,
            icon: const Icon(Icons.tune),
            label: Text("Set to ${_displayNumber(minimum)}"),
          ),
        ),
      );
    }
    final value = _dataNumber(current);
    if (value == null) {
      return _diagnostic("The slider control binding is unavailable");
    }
    return _controlFrame(
      slider.control,
      childScope,
      Slider(
        value: value.clamp(minimum, maximum),
        min: minimum,
        max: maximum,
        divisions: divisions != null && divisions > 0 ? divisions : null,
        onChanged: childScope.enabled && !childScope.readOnly
            ? (next) {
                final value = replacement(next);
                if (value != null) {
                  childScope.writePayload(slider.control.binding, value);
                }
              }
            : null,
      ),
    );
  }

  Widget _renderDateTimeInput(
    BuildContext context,
    presentation.DateTimeControl dateTime,
    PortablePresentationScope childScope,
  ) {
    final current = childScope.read(dateTime.control.binding);
    final payload = current?.authoredPayload;
    final timestamp = switch (payload) {
      types.DataValue_timestampWrapper(:final value) => value,
      _ => null,
    };
    if (current == null ||
        (timestamp == null && payload != types.DataValue.unfilled)) {
      return _diagnostic("The date and time binding is unavailable");
    }
    if (dateTime.includeDate == false && dateTime.includeTime == false) {
      return _diagnostic("The date and time control must enable one part");
    }
    return _controlFrame(
      dateTime.control,
      childScope,
      DateTimePickerField(
        key: ValueKey("${node.nodeId}.input"),
        value: timestamp,
        includeDate: dateTime.includeDate != false,
        includeTime: dateTime.includeTime != false,
        enabled: childScope.enabled,
        readOnly: childScope.readOnly,
        onChanged: (next) => childScope.writePayload(
          dateTime.control.binding,
          types.DataValue.wrapTimestamp(next.toUtc()),
        ),
      ),
    );
  }

  Widget _renderDurationInput(
    presentation.BoundControl control,
    PortablePresentationScope childScope,
  ) {
    final current = childScope.read(control.binding);
    final payload = current?.authoredPayload;
    final milliseconds = switch (payload) {
      types.DataValue_durationWrapper(:final value) => value.value.milliseconds,
      _ => null,
    };
    if (current == null ||
        (milliseconds == null && payload != types.DataValue.unfilled)) {
      return _diagnostic("The duration binding is unavailable");
    }
    return _controlFrame(
      control,
      childScope,
      ValidatedTextField<types.DataValue>(
        key: ValueKey("${node.nodeId}.input"),
        value: payload == types.DataValue.unfilled ? null : payload,
        name: "duration",
        icon: Bi.stopwatch_fill,
        mixed: payload == types.DataValue.unfilled,
        readOnly: childScope.readOnly || !childScope.enabled,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r"[\dwdhminsu +\-]")),
        ],
        decoration: InputDecoration(
          hintText: "Enter a duration",
          helperText: milliseconds == null ? "This value is Unfilled" : null,
          prefixIcon: _paddedControlPrefix(control, childScope),
        ),
        deserialize: (value) => value == types.DataValue.unfilled
            ? ""
            : prettyDuration(
                Duration(
                  milliseconds: (value as types.DataValue_durationWrapper)
                      .value
                      .value
                      .milliseconds,
                ),
                abbreviated: true,
                delimiter: " ",
                spacer: "",
                tersity: DurationTersity.millisecond,
              ),
        serialize: (value) {
          if (value.trim().isEmpty) return types.DataValue.unfilled;
          final duration = parseDuration(value, separator: " ");
          return types.DataValue.createDuration(
            value: kernel.Duration(milliseconds: duration.inMilliseconds),
          );
        },
        validator: (value) {
          if (value == types.DataValue.unfilled) return null;
          final encoded = BigInt.from(
            (value as types.DataValue_durationWrapper).value.value.milliseconds,
          );
          return encoded < _signedInt64Minimum || encoded > _signedInt64Maximum
              ? "Duration exceeds the supported range"
              : null;
        },
        onChanged: (value) => value == types.DataValue.unfilled
            ? childScope.write(control.binding, value)
            : childScope.writePayload(control.binding, value),
      ),
    );
  }

  Widget _renderBytesInput(
    presentation.BoundControl control,
    PortablePresentationScope childScope,
  ) {
    final current = childScope.read(control.binding);
    final payload = current?.authoredPayload;
    final bytes = switch (payload) {
      types.DataValue_bytesWrapper(:final value) => value,
      _ => null,
    };
    if (current == null ||
        (bytes == null && payload != types.DataValue.unfilled)) {
      return _diagnostic("The bytes binding is unavailable");
    }
    return _controlFrame(
      control,
      childScope,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EditorTextField(
            key: ValueKey("${node.nodeId}.input"),
            text: bytes?.toBase16() ?? "",
            enabled: childScope.enabled,
            readOnly: childScope.readOnly,
            prefix:
                _controlPrefix(control, childScope) ??
                const Icon(Icons.data_object, size: 18),
            inputFormatters: [
              TextInputFormatter.withFunction((oldValue, newValue) {
                return RegExp(r"^[0-9a-fA-F]*$").hasMatch(newValue.text)
                    ? newValue
                    : oldValue;
              }),
            ],
            decoration: InputDecoration(
              helperText: bytes == null
                  ? "This value is Unfilled"
                  : bytes.isEmpty
                  ? "Empty byte sequence"
                  : "Hexadecimal bytes",
              suffixIcon: bytes == null
                  ? null
                  : IconButton(
                      tooltip: "Clear bytes",
                      onPressed: childScope.enabled && !childScope.readOnly
                          ? () => childScope.write(
                              control.binding,
                              types.DataValue.unfilled,
                            )
                          : null,
                      icon: const Icon(Icons.clear),
                    ),
            ),
            onChanged: (text) {
              if (text.isEmpty || text.length.isOdd) {
                childScope.write(control.binding, types.DataValue.unfilled);
                return;
              }
              childScope.writePayload(
                control.binding,
                types.DataValue.wrapBytes(ByteString.fromBase16(text)),
              );
            },
          ),
          if (bytes == null)
            TextButton.icon(
              onPressed: childScope.enabled && !childScope.readOnly
                  ? () => childScope.writePayload(
                      control.binding,
                      types.DataValue.wrapBytes(ByteString.empty),
                    )
                  : null,
              icon: const Icon(Icons.add, size: 18),
              label: const Text("Use empty bytes"),
            ),
        ],
      ),
    );
  }

  Widget _renderEnumInput(
    presentation.BoundControl control,
    PortablePresentationScope childScope,
  ) {
    final current = childScope.read(control.binding);
    final payload = current?.authoredPayload;
    final selected = switch (payload) {
      types.DataValue_enumCaseWrapper(:final value) => value,
      _ => null,
    };
    final actual =
        current?.authoredActualType ??
        switch (_unwrapNullable(childScope.expectedType(control.binding))) {
          types.TypeUse_namedWrapper(:final value) => value,
          _ => null,
        };
    final representation = actual == null
        ? null
        : childScope.catalog
              ?.published(actual.definition)
              ?.definition
              .representation;
    final cases = switch (representation) {
      types.RepresentationTemplate_enumerationWrapper(:final value) =>
        value.cases.map((variant) => variant.key).toList(growable: false),
      _ => const <String>[],
    };
    if (current == null ||
        (selected == null && payload != types.DataValue.unfilled) ||
        cases.isEmpty) {
      return _diagnostic("The enumeration binding is unavailable");
    }
    return _controlFrame(
      control,
      childScope,
      _withControlPrefix(
        control,
        childScope,
        AdaptiveChoiceControl<String>(
          key: ValueKey("${node.nodeId}.input"),
          choices: {for (final value in cases) value: value},
          selected: cases.contains(selected) ? selected : null,
          enabled: childScope.enabled && !childScope.readOnly,
          initialization: SelectionInitializationPolicy.explicit,
          onSelected: (value) {
            if (value != null) {
              childScope.writePayload(
                control.binding,
                types.DataValue.wrapEnumCase(value),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _renderPolymorphicInput(
    BuildContext context,
    presentation.PolymorphicControl control,
    PortablePresentationScope childScope,
  ) {
    final current = childScope.read(control.control.binding);
    final actual = current?.authoredActualType;
    final choices = control.concreteTypes.toList(growable: false);
    final selectedIndex = choices.indexWhere((candidate) {
      return switch (candidate.concreteType) {
        types.TypeUse_namedWrapper(:final value) => value == actual,
        _ => false,
      };
    });
    final selected = selectedIndex < 0 ? null : choices[selectedIndex];
    if (current == null || choices.isEmpty) {
      return _diagnostic("The selected concrete type is unavailable");
    }
    final nested = selected?.presentation == null
        ? null
        : childScope.withConfiguredValue(control.control.binding);
    String choiceLabel(presentation.ConcreteTypePresentation candidate) =>
        switch (_string(childScope, candidate.label)) {
          _ResolvedValue(:final value) => value,
          _ =>
            childScope.catalog?.typeUseName(candidate.concreteType) ??
                "Concrete type",
        };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _controlFrame(
          control.control,
          childScope,
          OutlinedButton.icon(
            key: ValueKey("${node.nodeId}.type"),
            icon: const Icon(Icons.category_outlined),
            label: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                selected == null ? "Choose a type" : choiceLabel(selected),
              ),
            ),
            onPressed:
                childScope.enabled &&
                    !childScope.readOnly &&
                    childScope.authoring != null &&
                    childScope.prepareCreation != null
                ? () async {
                    final chosen = await showAuthoredTypeSearch(
                      context,
                      searchHint: "Search value types",
                      candidates: choices,
                      id: (candidate) => choices.indexOf(candidate).toString(),
                      label: choiceLabel,
                      display: (candidate) => switch (candidate.concreteType) {
                        types.TypeUse_namedWrapper(:final value) =>
                          childScope.catalog?.typeDisplay(value.definition),
                        _ => null,
                      },
                    );
                    if (chosen == null || !context.mounted) return;
                    await childScope._chooseForm(
                      action.ChooseFormAction(
                        target: control.control.binding,
                        type: chosen.concreteType,
                      ),
                    );
                  }
                : null,
          ),
        ),
        if (nested != null)
          PortablePresentationNodeRenderer(
            node: selected!.presentation!,
            scope: nested,
          ),
      ],
    );
  }

  Widget _renderListInput(
    BuildContext context,
    presentation.ListControl control,
    PortablePresentationScope childScope,
  ) => _renderSequenceInput(
    context: context,
    control: control.control,
    itemPresentation: control.itemPresentation,
    itemBindingId: control.itemBindingId,
    indexBindingId: control.indexBindingId,
    allowAdd: control.allowAdd,
    allowRemove: control.allowRemove,
    allowReorder: control.allowReorder,
    childScope: childScope,
  );

  Widget _renderSetInput(
    BuildContext context,
    presentation.SetControl control,
    PortablePresentationScope childScope,
  ) => _renderSequenceInput(
    context: context,
    control: control.control,
    itemPresentation: control.itemPresentation,
    itemBindingId: control.itemBindingId,
    indexBindingId: null,
    allowAdd: control.allowAdd,
    allowRemove: control.allowRemove,
    allowReorder: false,
    childScope: childScope,
  );

  Widget _renderSequenceInput({
    required BuildContext context,
    required presentation.BoundControl control,
    required presentation.PresentationNode? itemPresentation,
    required types.ExpressionBindingId itemBindingId,
    required types.ExpressionBindingId? indexBindingId,
    required bool allowAdd,
    required bool allowRemove,
    required bool allowReorder,
    required PortablePresentationScope childScope,
  }) {
    final current = childScope.read(control.binding);
    final items =
        current?.authoredItems?.toList() ??
        (current?.authoredPayload == types.DataValue.unfilled
            ? <types.ListItem>[]
            : null);
    final collection = childScope.location(control.binding);
    if (items == null || collection == null || childScope.authoring == null) {
      return _diagnostic("The collection binding is unavailable");
    }
    Widget item(int index) {
      final current = items[index];
      final reference = binding.BindingRef(
        bindingId: control.binding.bindingId,
        path: types.ValuePath(
          segments: [
            ...control.binding.path.segments,
            types.PathSegment.createItem(id: current.id),
          ],
        ),
      );
      var itemScope = childScope.withBinding(reference, itemBindingId);
      if (itemScope == null) {
        return _diagnostic(
          "Collection item ${current.id.value} is unavailable",
        );
      }
      if (indexBindingId != null) {
        itemScope = itemScope.withValues({
          indexBindingId: types.DataValue.wrapInteger(index.toString()),
        });
      }
      final content = itemPresentation == null
          ? Text(current.value.authoredString ?? current.id.value)
          : PortablePresentationNodeRenderer(
              node: itemPresentation,
              scope: itemScope,
            );
      final presentationOwnsHandle =
          itemPresentation?.header?.items.any(
            (item) => item is presentation.HeaderItem_reorderHandleWrapper,
          ) ??
          false;
      return Padding(
        key: ValueKey(current.id.value),
        padding: EdgeInsets.only(bottom: context.spacing.space2),
        child: DepthBox(
          child: Padding(
            padding: EdgeInsets.all(context.spacing.space2),
            child: Row(
              children: [
                if (allowReorder && !presentationOwnsHandle)
                  _AuthoredReorderHandle(
                    index: index,
                    label: "Reorder ${current.id.value}",
                    enabled: childScope.enabled && !childScope.readOnly,
                    canMoveEarlier: index > 0,
                    canMoveLater: index < items.length - 1,
                    onMoveEarlier: () {
                      final after = index == 1 ? null : items[index - 2].id;
                      childScope.authoring!.move(collection, current.id, after);
                      childScope.onDraftChanged?.call();
                    },
                    onMoveLater: () {
                      childScope.authoring!.move(
                        collection,
                        current.id,
                        items[index + 1].id,
                      );
                      childScope.onDraftChanged?.call();
                    },
                  ),
                Expanded(child: content),
                if (allowRemove)
                  IconButton(
                    tooltip: "Remove item",
                    onPressed: childScope.enabled && !childScope.readOnly
                        ? () {
                            childScope.authoring!.remove(
                              collection,
                              current.id,
                            );
                            childScope.onDraftChanged?.call();
                          }
                        : null,
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    final list = allowReorder
        ? ReorderableListView.builder(
            buildDefaultDragHandles: false,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (_, index) => item(index),
            onReorderItem: childScope.enabled && !childScope.readOnly
                ? (from, to) {
                    final moving = items[from];
                    final remaining = [...items]..removeAt(from);
                    final after = to == 0 ? null : remaining[to - 1].id;
                    childScope.authoring!.move(collection, moving.id, after);
                    childScope.onDraftChanged?.call();
                  }
                : (_, _) {},
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < items.length; index++) item(index),
            ],
          );
    final linkControl = switch (itemPresentation?.element) {
      presentation.PresentationElement_linkInputWrapper(:final value) => value,
      _ => null,
    };
    return _decorateCollection(
      control,
      childScope,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (items.isEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: context.spacing.space2),
              child: Text(
                "No items",
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: context.colors.contentSecondary),
              ),
            ),
          list,
          if (allowAdd)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FilledButton.icon(
                onPressed: childScope.enabled && !childScope.readOnly
                    ? () => unawaited(
                        _addSequenceItem(
                          context: context,
                          control: control,
                          linkControl: linkControl,
                          collection: collection,
                          items: items,
                          childScope: childScope,
                        ),
                      )
                    : null,
                icon: Icon(linkControl == null ? Icons.add : Icons.add_link),
                label: Text(linkControl == null ? "Add item" : "Add link"),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _addSequenceItem({
    required BuildContext context,
    required presentation.BoundControl control,
    required presentation.LinkControl? linkControl,
    required types.ValueLocation collection,
    required List<types.ListItem> items,
    required PortablePresentationScope childScope,
  }) async {
    final draft = childScope.authoring;
    if (draft == null) return;
    final item = types.ItemId(value: "panel:${const Uuid().v4()}");
    final itemReference = binding.BindingRef(
      bindingId: control.binding.bindingId,
      path: types.ValuePath(
        segments: [
          ...control.binding.path.segments,
          types.PathSegment.createItem(id: item),
        ],
      ),
    );
    final itemLocation = types.ValueLocation(
      resource: collection.resource,
      path: types.ValuePath(
        segments: [
          ...collection.path.segments,
          types.PathSegment.createItem(id: item),
        ],
      ),
    );
    if (linkControl != null) {
      Map<types.ResourceId, _AuthoredCollectionRow>? candidates;
      presentation.PresentationCollectionDefinition? candidateDefinition;
      if (linkControl.sourceId case final sourceId?) {
        final resolved = _authoredCollection(sourceId, childScope);
        if (resolved.problem != null) {
          childScope.reportStatus?.call(resolved.problem!);
          return;
        }
        candidateDefinition = resolved.definition;
        candidates = {
          for (final row in resolved.rows)
            if (row.selectable) row.resource: row,
        };
      }
      await _chooseLink(
        context: context,
        scope: childScope,
        control: linkControl,
        location: itemLocation,
        candidates: candidates,
        candidateDefinition: candidateDefinition,
      );
      return;
    }
    final expected = childScope.expectedType(itemReference);
    final named = switch (_unwrapNullable(expected)) {
      types.TypeUse_namedWrapper(:final value) => value,
      _ => null,
    };
    final representation = named == null
        ? null
        : childScope.catalog
              ?.published(named.definition)
              ?.definition
              .representation;
    final concreteRecord = switch (representation) {
      types.RepresentationTemplate_recordWrapper(:final value) =>
        !value.abstract_,
      _ => false,
    };
    PortablePathResult<types.AuthoringRecord> result;
    if (named != null && concreteRecord) {
      final prepare = childScope.prepareCreation;
      if (prepare == null) {
        childScope.reportStatus?.call("The collection item cannot be prepared");
        return;
      }
      final selection = types.TypeSelection.wrapComplete(named);
      final identity = sha256
          .convert(
            utf8.encode(
              "${draft.generation.value}\u0000${collection.resource.value}\u0000${_pathLabel(itemLocation.path)}\u0000$selection",
            ),
          )
          .toString();
      final request = catalog_wire.InitializationRequest(
        id: types.InitializationRequestId(value: "panel:item:$identity"),
        catalog: draft.generation,
        type: selection,
        supplied: const [],
        intentHash: identity,
      );
      try {
        final previousFindingCount = draft.initializationFindings.length;
        final prepared = await prepare(request);
        if (!context.mounted) return;
        result = draft.insertPrepared(
          collection,
          items.lastOrNull?.id,
          item,
          request,
          prepared,
        );
        final findings = draft.initializationFindings.skip(
          previousFindingCount,
        );
        if (findings.isNotEmpty) {
          childScope.reportStatus?.call(
            findings.map(formatPortableInitializationDiagnostic).join("\n"),
          );
        }
      } on Object catch (error) {
        childScope.reportStatus?.call(
          "The collection item could not be prepared: $error",
        );
        return;
      }
    } else {
      result = draft.insert(
        collection,
        items.lastOrNull?.id,
        types.ListItem(id: item, value: draft.defaultValue(expected)),
      );
    }
    if (result case PortablePathUnavailable(:final message)) {
      childScope.reportStatus?.call(message);
      return;
    }
    childScope.onDraftChanged?.call();
  }

  Widget _renderMapInput(
    BuildContext context,
    presentation.MapControl control,
    PortablePresentationScope childScope,
  ) {
    final current = childScope.read(control.control.binding);
    final value = current?.authoredPayload;
    final rows = switch (value) {
      types.DataValue_mapValueWrapper(:final value) => value.rows.toList(),
      _ when value == types.DataValue.unfilled => <types.MapRow>[],
      _ => null,
    };
    final collection = childScope.location(control.control.binding);
    if (rows == null || collection == null || childScope.authoring == null) {
      return _diagnostic("The map binding is unavailable");
    }
    return _decorateCollection(
      control.control,
      childScope,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final row in rows)
            _renderMapRow(context, control, row, collection, childScope),
          if (control.allowAdd)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FilledButton.icon(
                onPressed: childScope.enabled && !childScope.readOnly
                    ? () => _addMapRow(control, collection, rows, childScope)
                    : null,
                icon: const Icon(Icons.add),
                label: const Text("Add entry"),
              ),
            ),
        ],
      ),
    );
  }

  void _addMapRow(
    presentation.MapControl control,
    types.ValueLocation collection,
    List<types.MapRow> rows,
    PortablePresentationScope childScope,
  ) {
    final draft = childScope.authoring;
    if (draft == null) return;
    final item = types.ItemId(value: "panel:${const Uuid().v4()}");
    binding.BindingRef reference(types.PathSegment branch) =>
        binding.BindingRef(
          bindingId: control.control.binding.bindingId,
          path: types.ValuePath(
            segments: [
              ...control.control.binding.path.segments,
              types.PathSegment.createItem(id: item),
              branch,
            ],
          ),
        );
    final result = draft.replaceMap(collection, [
      ...rows,
      types.MapRow(
        id: item,
        key: draft.defaultValue(
          childScope.expectedType(reference(types.PathSegment.mapKey)),
        ),
        value: draft.defaultValue(
          childScope.expectedType(reference(types.PathSegment.mapValue)),
        ),
      ),
    ]);
    if (result case PortablePathUnavailable(:final message)) {
      childScope.reportStatus?.call(message);
      return;
    }
    childScope.onDraftChanged?.call();
  }

  Widget _renderMapRow(
    BuildContext context,
    presentation.MapControl control,
    types.MapRow row,
    types.ValueLocation collection,
    PortablePresentationScope childScope,
  ) {
    final base = [
      ...control.control.binding.path.segments,
      types.PathSegment.createItem(id: row.id),
    ];
    final keyReference = binding.BindingRef(
      bindingId: control.control.binding.bindingId,
      path: types.ValuePath(segments: [...base, types.PathSegment.mapKey]),
    );
    final valueReference = binding.BindingRef(
      bindingId: control.control.binding.bindingId,
      path: types.ValuePath(segments: [...base, types.PathSegment.mapValue]),
    );
    final keyScope = childScope.withBinding(keyReference, control.keyBindingId);
    final valueScope = childScope.withBinding(
      valueReference,
      control.valueBindingId,
    );
    if (keyScope == null || valueScope == null) {
      return _diagnostic("Map row ${row.id.value} is unavailable");
    }
    return Padding(
      key: ValueKey(row.id.value),
      padding: EdgeInsets.only(bottom: context.spacing.space2),
      child: DepthBox(
        child: Padding(
          padding: EdgeInsets.all(context.spacing.space2),
          child: Row(
            children: [
              Expanded(
                child: control.keyPresentation == null
                    ? Text(row.key.authoredString ?? "Key")
                    : PortablePresentationNodeRenderer(
                        node: control.keyPresentation!,
                        scope: keyScope,
                      ),
              ),
              SizedBox(width: context.spacing.space2),
              Expanded(
                child: control.valuePresentation == null
                    ? Text(row.value.authoredString ?? "Value")
                    : PortablePresentationNodeRenderer(
                        node: control.valuePresentation!,
                        scope: valueScope,
                      ),
              ),
              if (control.allowRemove)
                IconButton(
                  tooltip: "Remove row",
                  onPressed: childScope.enabled && !childScope.readOnly
                      ? () {
                          final current = switch (childScope.authoring!.read(
                            collection,
                          )) {
                            PortablePathValue(value: final value) =>
                              value.authoredPayload,
                            _ => null,
                          };
                          if (current is! types.DataValue_mapValueWrapper) {
                            return;
                          }
                          final result = childScope.authoring!.replaceMap(
                            collection,
                            current.value.rows.where(
                              (candidate) => candidate.id != row.id,
                            ),
                          );
                          if (result case PortablePathUnavailable(
                            :final message,
                          )) {
                            childScope.reportStatus?.call(message);
                          } else {
                            childScope.onDraftChanged?.call();
                          }
                        }
                      : null,
                  icon: const Icon(Icons.delete_outline),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _renderColorInput(
    BuildContext context,
    presentation.ColorControl colorControl,
    PortablePresentationScope childScope,
  ) {
    final current = childScope.read(colorControl.control.binding);
    final payload = current?.authoredPayload;
    final encoded = payload?.authoredInteger;
    if (current == null ||
        (encoded == null && payload != types.DataValue.unfilled)) {
      return _diagnostic("The color control binding is unavailable");
    }
    final color = encoded == null
        ? null
        : Color(encoded.toUnsigned(32).toInt());
    final includeAlpha = colorControl.includeAlpha;
    return _controlFrame(
      colorControl.control,
      childScope,
      ColorPickerField(
        key: ValueKey("${node.nodeId}.input"),
        color: color,
        includeAlpha: includeAlpha,
        enabled: childScope.enabled,
        readOnly: childScope.readOnly,
        onChanged: (next) => childScope.writePayload(
          colorControl.control.binding,
          types.DataValue.wrapInteger(next.toARGB32().toString()),
        ),
      ),
    );
  }

  Widget _renderRecordInput(
    presentation.RecordControl recordControl,
    PortablePresentationScope childScope,
  ) {
    final custom = recordControl.fieldPresentation;
    if (custom == null) {
      return _diagnostic("The record control has no field presentation");
    }
    if (childScope.read(recordControl.control.binding) == null) {
      return _diagnostic("The record control binding is unavailable");
    }
    final nested = childScope.withConfiguredValue(
      recordControl.control.binding,
    );
    if (nested == null) {
      return _diagnostic("The record control binding is unavailable");
    }
    return PortablePresentationNodeRenderer(node: custom, scope: nested);
  }

  Widget _renderLinkInput(
    BuildContext context,
    presentation.LinkControl control,
    PortablePresentationScope childScope,
  ) {
    final location = childScope.location(control.control.binding);
    final draft = childScope.authoring;
    final catalog = childScope.catalog;
    if (location == null || draft == null || catalog == null) {
      return _diagnostic("The link control binding is unavailable");
    }
    Map<types.ResourceId, _AuthoredCollectionRow>? candidates;
    presentation.PresentationCollectionDefinition? candidateDefinition;
    if (control.sourceId case final sourceId?) {
      final collection = _authoredCollection(sourceId, childScope);
      if (collection.problem != null) {
        return _diagnostic(collection.problem!);
      }
      candidateDefinition = collection.definition;
      candidates = {
        for (final row in collection.rows)
          if (row.selectable) row.resource: row,
      };
    }
    final current = childScope.read(control.control.binding);
    final items = current?.authoredItems?.toList(growable: false);
    if (items == null) {
      return _AuthoredLinkValueInput(
        key: ValueKey("${node.nodeId}.link"),
        control: control,
        scope: childScope,
        location: location,
        candidates: candidates,
        candidateDefinition: candidateDefinition,
      );
    }
    final rows = [
      for (final (index, item) in items.indexed)
        _AuthoredLinkValueInput(
          key: ValueKey("${node.nodeId}.link.${item.id.value}"),
          control: control,
          scope: childScope,
          location: types.ValueLocation(
            resource: location.resource,
            path: types.ValuePath(
              segments: [
                ...location.path.segments,
                types.PathSegment.createItem(id: item.id),
              ],
            ),
          ),
          candidates: candidates,
          candidateDefinition: candidateDefinition,
          framed: false,
          showPrefix: false,
          leading: control.allowReorder
              ? _AuthoredReorderHandle(
                  index: index,
                  label: "Reorder linked resource ${index + 1}",
                  enabled: childScope.enabled && !childScope.readOnly,
                  canMoveEarlier: index > 0,
                  canMoveLater: index < items.length - 1,
                  onMoveEarlier: () {
                    final after = index == 1 ? null : items[index - 2].id;
                    draft.move(location, item.id, after);
                    childScope.onDraftChanged?.call();
                  },
                  onMoveLater: () {
                    draft.move(location, item.id, items[index + 1].id);
                    childScope.onDraftChanged?.call();
                  },
                )
              : null,
        ),
    ];
    final list = control.allowReorder
        ? ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: rows.length,
            itemBuilder: (_, index) => rows[index],
            onReorderItem: (oldIndex, newIndex) {
              if (!childScope.enabled || childScope.readOnly) return;
              final moving = items[oldIndex].id;
              final remaining = [...items]..removeAt(oldIndex);
              final after = newIndex == 0 ? null : remaining[newIndex - 1].id;
              draft.move(location, moving, after);
              childScope.onDraftChanged?.call();
            },
          )
        : Column(children: rows);
    return _controlFrame(
      control.control,
      childScope,
      _withControlPrefix(
        control.control,
        childScope,
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            list,
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: childScope.enabled && !childScope.readOnly
                    ? () async {
                        final item = types.ItemId(
                          value: "panel:${const Uuid().v4()}",
                        );
                        await _chooseLink(
                          context: context,
                          scope: childScope,
                          control: control,
                          location: types.ValueLocation(
                            resource: location.resource,
                            path: types.ValuePath(
                              segments: [
                                ...location.path.segments,
                                types.PathSegment.createItem(id: item),
                              ],
                            ),
                          ),
                          candidates: candidates,
                          candidateDefinition: candidateDefinition,
                        );
                      }
                    : null,
                icon: const Icon(Icons.add_link),
                label: const Text("Add link"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _renderDefaultPresentation(
    presentation.DefaultPresentationElement element,
    PortablePresentationScope childScope,
  ) {
    final nested = childScope.withConfiguredValue(element.binding);
    if (nested == null) {
      return _diagnostic("The default presentation binding is unavailable");
    }
    final selection = _selectionFor(element.binding, childScope);
    final checked = childScope.catalog;
    if (selection != null && checked != null) {
      final material = element.presentationId == null
          ? switch (checked.selectPresentation(
              selection,
              catalog_wire.PresentationRole.inspector,
            )) {
              SelectedEditorPresentation(:final material) => material,
              _ => null,
            }
          : checked.presentationMaterial(element.presentationId!, selection);
      if (material != null) {
        if (childScope.activePresentations.contains(material.provider)) {
          if (element.presentationId != null) {
            return _diagnostic("Presentation delegation is recursive");
          }
        } else {
          return PortablePresentationNodeRenderer(
            node: material.layout,
            scope: nested
                .withActivePresentation(material.provider)
                .withMaterial(material),
          );
        }
      }
    }
    final expected = childScope.expectedType(element.binding);
    final generated = _defaultElement(
      expected ?? _typeUseForSelection(selection),
      element.binding,
      childScope,
    );
    return generated == null
        ? _diagnostic("No default presentation is available")
        : PortablePresentationNodeRenderer(
            node: presentation.PresentationNode(
              nodeId: "${node.nodeId}.default",
              properties: presentation.PresentationProperties.defaultInstance,
              element: generated,
              header: null,
            ),
            scope: childScope,
          );
  }

  Widget _renderRemainingFields(
    BuildContext context,
    presentation.RemainingFieldsElement element,
    PortablePresentationScope childScope,
  ) {
    final checked = childScope.catalog;
    final configured = childScope.bindings[_configuredValueBindingId];
    if (checked == null || configured == null) {
      return _diagnostic("The remaining fields are unavailable");
    }
    final selection = _selectionForConfigured(childScope, configured.value);
    if (selection == null) {
      return _diagnostic("The remaining field type is unavailable");
    }
    final excluded = {
      for (final pattern in element.excluded)
        if (pattern.segments.length == 1)
          switch (pattern.segments.single) {
            types.FieldPatternSegment_fieldWrapper(:final value) => value.name,
            _ => null,
          },
    }..remove(null);
    final role = childScope.role;
    final explicit = role == null
        ? const <types.ValuePath, EditorFieldPresentationSelection>{}
        : checked.fieldPresentations(selection, role);
    final children = <Widget>[];
    for (final field in checked.fields(selection)) {
      if (excluded.contains(field.template.key)) continue;
      final path = types.ValuePath(
        segments: [types.PathSegment.createField(name: field.template.key)],
      );
      final reference = binding.BindingRef(
        bindingId: _configuredValueBindingId,
        path: path,
      );
      final choice = explicit[path];
      final generated = switch (choice) {
        SelectedEditorFieldPresentation(
          presentation: final selectedPresentation,
        ) =>
          presentation.PresentationElement.createDefaultPresentation(
            binding: reference,
            presentationId: selectedPresentation,
          ),
        ConflictingEditorFieldPresentation() => null,
        null => _defaultElement(field.type, reference, childScope),
      };
      children.add(
        Column(
          key: ValueKey("${node.nodeId}.${field.template.key}"),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(field.template.key),
            if (choice is ConflictingEditorFieldPresentation)
              _diagnostic(
                "Field ${field.template.key} has conflicting presentations",
              )
            else if (generated == null)
              _diagnostic("Field ${field.template.key} has no presentation")
            else
              PortablePresentationNodeRenderer(
                node: presentation.PresentationNode(
                  nodeId: "${node.nodeId}.${field.template.key}.control",
                  properties:
                      presentation.PresentationProperties.defaultInstance,
                  element: generated,
                  header: null,
                ),
                scope: childScope,
              ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: context.spacing.space3,
      children: children,
    );
  }

  types.TypeSelection? _selectionFor(
    binding.BindingRef reference,
    PortablePresentationScope childScope,
  ) {
    final actual = childScope.read(reference)?.authoredActualType;
    if (actual != null) return types.TypeSelection.wrapComplete(actual);
    final expected = _unwrapNullable(childScope.expectedType(reference));
    return switch (expected) {
      types.TypeUse_namedWrapper(:final value) =>
        types.TypeSelection.wrapComplete(value),
      _ => null,
    };
  }

  types.TypeSelection? _selectionForConfigured(
    PortablePresentationScope childScope,
    types.DataValue value,
  ) {
    final actual = value.authoredActualType;
    if (actual != null) return types.TypeSelection.wrapComplete(actual);
    final resource = childScope.resource;
    return resource == null
        ? null
        : childScope.authoring?.resource(resource)?.configuration;
  }

  types.TypeUse? _typeUseForSelection(types.TypeSelection? selection) =>
      switch (selection) {
        types.TypeSelection_completeWrapper(:final value) =>
          types.TypeUse.wrapNamed(value),
        _ => null,
      };

  presentation.PresentationElement? _defaultElement(
    types.TypeUse? declared,
    binding.BindingRef reference,
    PortablePresentationScope childScope,
  ) {
    final type = _unwrapNullable(declared);
    if (declared is types.TypeUse_nullableWrapper) {
      final nested = _defaultElement(
        declared.value.value,
        reference,
        childScope,
      );
      return presentation.PresentationElement.wrapNullableInput(
        presentation.NullableControl(
          control: _generatedControl(reference),
          valuePresentation: nested == null
              ? null
              : presentation.PresentationNode(
                  nodeId: "${node.nodeId}.nullable",
                  properties:
                      presentation.PresentationProperties.defaultInstance,
                  element: nested,
                  header: null,
                ),
        ),
      );
    }
    if (type case types.TypeUse_scalarWrapper(:final value)) {
      return _scalarDefaultElement(value, reference);
    }
    if (type case types.TypeUse_namedWrapper(:final value)) {
      final representation = childScope.catalog
          ?.published(value.definition)
          ?.definition
          .representation;
      return switch (representation) {
        types.RepresentationTemplate_scalarWrapper(:final value) =>
          _scalarDefaultElement(value.kind, reference),
        types.RepresentationTemplate_recordWrapper() =>
          presentation.PresentationElement.wrapRecordInput(
            presentation.RecordControl(
              control: _generatedControl(reference),
              fieldPresentation: presentation.PresentationNode(
                nodeId: "${node.nodeId}.fields",
                properties: presentation.PresentationProperties.defaultInstance,
                element: presentation.PresentationElement.wrapRemainingFields(
                  presentation.RemainingFieldsElement(excluded: const []),
                ),
                header: null,
              ),
            ),
          ),
        types.RepresentationTemplate_sequenceWrapper(:final value) =>
          value.kind == types.CollectionKind.set_
              ? presentation.PresentationElement.wrapSetInput(
                  presentation.SetControl(
                    control: _generatedControl(reference),
                    itemPresentation: null,
                    allowAdd: true,
                    allowRemove: true,
                    itemBindingId: types.ExpressionBindingId(
                      value: "generated_item",
                    ),
                  ),
                )
              : presentation.PresentationElement.wrapListInput(
                  presentation.ListControl(
                    control: _generatedControl(reference),
                    itemPresentation: null,
                    allowAdd: true,
                    allowRemove: true,
                    allowReorder: true,
                    itemBindingId: types.ExpressionBindingId(
                      value: "generated_item",
                    ),
                    indexBindingId: types.ExpressionBindingId(
                      value: "generated_index",
                    ),
                  ),
                ),
        types.RepresentationTemplate_mappingWrapper() =>
          presentation.PresentationElement.wrapMapInput(
            presentation.MapControl(
              control: _generatedControl(reference),
              keyPresentation: null,
              valuePresentation: null,
              allowAdd: true,
              allowRemove: true,
              keyBindingId: types.ExpressionBindingId(value: "generated_key"),
              valueBindingId: types.ExpressionBindingId(
                value: "generated_value",
              ),
            ),
          ),
        types.RepresentationTemplate_enumerationWrapper() =>
          presentation.PresentationElement.wrapEnumInput(
            _generatedControl(reference),
          ),
        types.RepresentationTemplate_linkWrapper() =>
          presentation.PresentationElement.wrapLinkInput(
            presentation.LinkControl(
              control: _generatedControl(reference),
              allowReorder: true,
              candidatePolicy: null,
              rejectionDisplay: presentation.LinkRejectionDisplay.disabled,
              sourceId: null,
            ),
          ),
        _ => null,
      };
    }
    return null;
  }

  presentation.PresentationElement? _scalarDefaultElement(
    types.ScalarKind kind,
    binding.BindingRef reference,
  ) => switch (kind) {
    types.ScalarKind.boolean =>
      presentation.PresentationElement.wrapToggleInput(
        _generatedControl(reference),
      ),
    types.ScalarKind.text => presentation.PresentationElement.wrapTextInput(
      presentation.TextControl(
        control: _generatedControl(reference),
        multiline: null,
        placeholder: null,
        inputFormatters: const [],
      ),
    ),
    types.ScalarKind_integerWrapper() ||
    types.ScalarKind_floatWrapper() ||
    types.ScalarKind.decimal =>
      presentation.PresentationElement.wrapNumericInput(
        _generatedControl(reference),
      ),
    types.ScalarKind.timestamp =>
      presentation.PresentationElement.wrapDateTimeInput(
        presentation.DateTimeControl(
          control: _generatedControl(reference),
          includeDate: true,
          includeTime: true,
        ),
      ),
    types.ScalarKind.duration =>
      presentation.PresentationElement.wrapDurationInput(
        _generatedControl(reference),
      ),
    types.ScalarKind.bytes => presentation.PresentationElement.wrapBytesInput(
      _generatedControl(reference),
    ),
    _ => null,
  };

  presentation.BoundControl _generatedControl(binding.BindingRef reference) =>
      presentation.BoundControl(
        binding: reference,
        label: null,
        description: null,
        prefix: null,
        semanticLabel: null,
      );

  Widget _renderNullableInput(
    presentation.NullableControl nullable,
    PortablePresentationScope childScope,
  ) {
    final current = childScope.read(nullable.control.binding);
    if (current == null) {
      return _diagnostic("The nullable control binding is unavailable");
    }
    final isNull = current.authoredPayload == types.DataValue.null_;
    if (isNull) {
      return SwitchListTile(
        value: false,
        title: _controlText(nullable.control.label, childScope),
        subtitle: const Text("No value"),
        onChanged: null,
      );
    }
    final custom = nullable.valuePresentation;
    final nested = custom == null
        ? null
        : childScope.withConfiguredValue(nullable.control.binding);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          value: true,
          title: _controlText(nullable.control.label, childScope),
          onChanged: childScope.enabled && !childScope.readOnly
              ? (_) => childScope.write(
                  nullable.control.binding,
                  types.DataValue.null_,
                )
              : null,
        ),
        if (custom != null && nested != null)
          PortablePresentationNodeRenderer(node: custom, scope: nested),
      ],
    );
  }

  Widget _renderCommitControls(PortablePresentationScope childScope) => Align(
    alignment: AlignmentDirectional.centerEnd,
    child: FilledButton(
      onPressed:
          childScope.enabled &&
              !childScope.readOnly &&
              childScope.commit != null
          ? childScope.commit
          : null,
      child: const Text("Save"),
    ),
  );

  Widget _renderButton(
    presentation.ButtonElement button,
    PortablePresentationScope childScope,
  ) {
    final label = _string(childScope, button.label);
    return switch (label) {
      _ResolvedValue(:final value) => FilledButton(
        onPressed: childScope.canExecuteAction
            ? () => unawaited(childScope.executeAction(button.action))
            : null,
        child: Text(value),
      ),
      _ResolvedFailure(:final message) => _diagnostic(message),
    };
  }

  Widget _renderIconButton(
    presentation.IconButtonElement button,
    PortablePresentationScope childScope,
  ) {
    final icon = _string(childScope, button.icon);
    final label = _string(childScope, button.semanticLabel);
    if (icon is _ResolvedFailure<String>) return _diagnostic(icon.message);
    if (label is _ResolvedFailure<String>) return _diagnostic(label.message);
    return IconButton(
      tooltip: (label as _ResolvedValue<String>).value,
      onPressed: childScope.canExecuteAction
          ? () => unawaited(childScope.executeAction(button.action))
          : null,
      icon: Icon(_materialIcon((icon as _ResolvedValue<String>).value)),
    );
  }

  Widget _renderMenu(
    presentation.MenuElement menu,
    PortablePresentationScope childScope,
  ) {
    final items = <({String id, String label, action.EditorAction action})>[];
    for (final item in menu.items) {
      final label = _string(childScope, item.label);
      if (label case _ResolvedValue<String>(:final value)) {
        items.add((id: item.itemId, label: value, action: item.action));
      }
    }
    if (items.isEmpty) {
      return _diagnostic("The menu has no available actions");
    }
    final label = menu.label == null ? null : _string(childScope, menu.label!);
    return PopupMenuButton<String>(
      enabled: childScope.canExecuteAction,
      tooltip: switch (label) {
        _ResolvedValue<String>(:final value) => value,
        _ => "Open menu",
      },
      onSelected: (id) {
        final item = items.where((candidate) => candidate.id == id).firstOrNull;
        if (item != null) unawaited(childScope.executeAction(item.action));
      },
      itemBuilder: (_) => [
        for (final item in items)
          PopupMenuItem(value: item.id, child: Text(item.label)),
      ],
    );
  }

  Widget _renderTooltip(
    presentation.TooltipElement tooltip,
    PortablePresentationScope childScope,
  ) {
    final message = _string(childScope, tooltip.message);
    return switch (message) {
      _ResolvedValue(:final value) => Tooltip(
        message: value,
        child: PortablePresentationNodeRenderer(
          node: tooltip.child,
          scope: childScope,
        ),
      ),
      _ResolvedFailure(:final message) => _diagnostic(message),
    };
  }

  Widget _renderRichText(
    presentation.RichTextContent content,
    PortablePresentationScope childScope,
  ) {
    final spans = <InlineSpan>[];
    for (final run in content.runs) {
      final text = _string(childScope, run.text);
      if (text case _ResolvedFailure(:final message)) {
        return _diagnostic(message);
      }
      spans.add(TextSpan(text: (text as _ResolvedValue<String>).value));
    }
    return Text.rich(TextSpan(children: spans));
  }

  Widget _renderAdaptiveLeading(
    presentation.AdaptiveLeadingElement element,
    PortablePresentationScope childScope,
  ) => LayoutBuilder(
    builder: (context, constraints) {
      if (!constraints.hasBoundedWidth) {
        return _diagnostic("Adaptive leading requires finite maximum width");
      }
      return AdaptiveLeadingLayout(
        leading: PortablePresentationNodeRenderer(
          node: element.leading,
          scope: childScope,
        ),
        center: element.center == null
            ? null
            : PortablePresentationNodeRenderer(
                node: element.center!,
                scope: childScope,
              ),
        suffix: element.suffix == null
            ? null
            : PortablePresentationNodeRenderer(
                node: element.suffix!,
                scope: childScope,
              ),
        padding: _presentationInsets(element.padding),
        compactPadding: _presentationInsets(element.compactPadding),
        gap: element.gap,
        minCenterWidth: element.minimumCenterWidth,
      );
    },
  );

  Widget _renderPageGraph(
    BuildContext context,
    presentation.PageGraphElement element,
    PortablePresentationScope childScope,
  ) {
    final page = _pageProjection(element.control, childScope);
    if (page case _PageProjectionFailure(:final message)) {
      return _diagnostic(message);
    }
    final projection = page as _PageProjectionValue;
    final sides = switch (element.direction.kind) {
      presentation.PageGraphDirection_kind.rightToLeftConst => (
        EdgeSide.left,
        EdgeSide.right,
      ),
      presentation.PageGraphDirection_kind.topToBottomConst => (
        EdgeSide.bottom,
        EdgeSide.top,
      ),
      presentation.PageGraphDirection_kind.bottomToTopConst => (
        EdgeSide.top,
        EdgeSide.bottom,
      ),
      _ => (EdgeSide.right, EdgeSide.left),
    };
    final ids = projection.entries.map((entry) => entry.resource).toSet();
    final relations = {
      for (final relation
          in childScope.catalog?.snapshot.relations ??
              const <catalog_wire.RelationContract>[])
        relation.id: relation,
    };
    final edges = <GraphEdge>[];
    for (final link in projection.draft.links) {
      if (!ids.contains(link.first) || !ids.contains(link.second)) continue;
      edges.add(
        GraphEdge(
          id: _linkOccurrenceKey(link, relations[link.contract]),
          source: GraphIdentifier(link.first.value),
          target: GraphIdentifier(link.second.value),
          color: Theme.of(context).colorScheme.outline,
          sourceSide: sides.$1,
          targetSide: sides.$2,
        ),
      );
    }
    return Graph(
      data: GraphData(
        cellSize: 50,
        elements: [
          for (final entry in projection.entries)
            GraphElement(
              id: GraphIdentifier(entry.resource.value),
              x: entry.graph?.x ?? 0,
              y: entry.graph?.y ?? projection.entries.indexOf(entry) * 2,
              width: entry.graph?.width ?? 4,
              height: entry.graph?.height ?? 1,
              builder: (_) => _pageResourceCard(entry, childScope),
            ),
        ],
        edges: edges,
      ),
      onElementsMoved: childScope.enabled && !childScope.readOnly
          ? (changes) {
              for (final change in changes) {
                _writePageInteger(
                  projection.draft,
                  types.ResourceId(value: change.id.id),
                  "x",
                  change.x,
                );
                _writePageInteger(
                  projection.draft,
                  types.ResourceId(value: change.id.id),
                  "y",
                  change.y,
                );
              }
              childScope.onDraftChanged?.call();
            }
          : null,
      onElementsResized: childScope.enabled && !childScope.readOnly
          ? (changes) {
              for (final change in changes) {
                _writePageInteger(
                  projection.draft,
                  types.ResourceId(value: change.id.id),
                  "width",
                  change.width,
                );
                _writePageInteger(
                  projection.draft,
                  types.ResourceId(value: change.id.id),
                  "height",
                  change.height,
                );
              }
              childScope.onDraftChanged?.call();
            }
          : null,
    );
  }

  Widget _renderPageTimeline(
    BuildContext context,
    presentation.PageTimelineElement element,
    PortablePresentationScope childScope,
  ) {
    final page = _pageProjection(element.control, childScope);
    if (page case _PageProjectionFailure(:final message)) {
      return _diagnostic(message);
    }
    final projection = page as _PageProjectionValue;
    final catalog = childScope.catalog;
    if (catalog == null) {
      return _diagnostic("The page timeline catalog is unavailable");
    }
    final byId = {
      for (final entry in projection.entries) entry.resource: entry,
    };
    final tracks = <TimelineTrack>[];
    for (final entry in projection.entries) {
      final visited = <types.ResourceId>{entry.resource};
      final cues = <TimelineElement>[];
      for (final neighbor in _ownedTimelineTargets(
        projection.draft,
        catalog,
        entry.resource,
      )) {
        final cue = _timelineElement(
          context,
          projection.draft,
          catalog,
          neighbor,
          byId,
          childScope,
          visited,
          null,
        );
        if (cue != null) cues.add(cue);
      }
      tracks.add(
        TimelineTrack(
          id: TimelineIdentifier(entry.resource.value),
          header: (_) => _pageResourceCard(entry, childScope),
          elements: cues,
        ),
      );
    }
    return Timeline(
      data: TimelineData(tracks: tracks),
      onElementsCommited: childScope.enabled && !childScope.readOnly
          ? (changes) async {
              for (final change in changes) {
                final id = types.ResourceId(value: change.id.id);
                final record = projection.draft.resource(id);
                final placement = record?.authoredField("placement");
                if (placement?.authoredField("frame") != null) {
                  _writePageInteger(
                    projection.draft,
                    id,
                    "frame",
                    change.startFrame,
                  );
                } else {
                  _writePageInteger(
                    projection.draft,
                    id,
                    "startFrame",
                    change.startFrame,
                  );
                  _writePageInteger(
                    projection.draft,
                    id,
                    "endFrame",
                    change.endFrame,
                  );
                }
              }
              childScope.onDraftChanged?.call();
            }
          : null,
    );
  }

  Widget _pageResourceCard(
    _PageEntry entry,
    PortablePresentationScope childScope,
  ) {
    final content = _resourcePresentation(
      entry.resource,
      catalog_wire.PresentationRole.graphNode,
      childScope,
    );
    final editable = childScope.enabled && !childScope.readOnly;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: childScope.openResource == null
            ? null
            : () => childScope.openResource!(entry.resource),
        child: Row(
          children: [
            Expanded(child: content),
            PopupMenuButton<_PageResourceAction>(
              enabled: editable,
              onSelected: (action) {
                switch (action) {
                  case _PageResourceAction.disconnect:
                    entry.draft.disconnect(entry.occurrence);
                  case _PageResourceAction.delete:
                    entry.draft.delete(entry.resource);
                }
                childScope.onDraftChanged?.call();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: _PageResourceAction.disconnect,
                  child: Text("Disconnect from page"),
                ),
                PopupMenuItem(
                  value: _PageResourceAction.delete,
                  child: Text("Delete resource"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _resourcePresentation(
    types.ResourceId resource,
    catalog_wire.PresentationRole role,
    PortablePresentationScope parent,
  ) {
    final draft = parent.authoring;
    final catalog = parent.catalog;
    final record = draft?.resource(resource);
    if (draft == null || catalog == null || record == null) {
      return Text(resource.value);
    }
    final selected = catalog.selectPresentation(record.configuration, role);
    if (selected is! SelectedEditorPresentation) {
      return Text(
        record.authoredField("name")?.authoredString ?? resource.value,
      );
    }
    return PortablePresentationNodeRenderer(
      node: selected.material.layout,
      scope: PortablePresentationScope(
        bindings: {
          _configuredValueBindingId: PortableExpressionBinding(
            value: types.DataValue.createRecord(fields: record.fields),
            location: types.ValueLocation(
              resource: resource,
              path: types.ValuePath(segments: const []),
            ),
          ),
        },
        budget: parent.budget,
        setBinding: (reference, value) {
          if (reference.bindingId != _configuredValueBindingId) return;
          final result = draft.set(
            types.ValueLocation(resource: resource, path: reference.path),
            value,
          );
          if (result is PortablePathValue) parent.onDraftChanged?.call();
        },
        readOnly: parent.readOnly,
        enabled: parent.enabled,
        invokeCommand: parent.invokeCommand,
        watchSearch: parent.watchSearch,
        reload: parent.reload,
        reportStatus: parent.reportStatus,
        commit: parent.commit,
        authoring: draft,
        catalog: catalog,
        resource: resource,
        role: selected.resolvedRole,
        material: selected.material,
        activePresentations: {selected.material.provider},
        onDraftChanged: parent.onDraftChanged,
        openResource: parent.openResource,
        prepareCreation: parent.prepareCreation,
        host: parent.host,
      ),
    );
  }

  Widget _renderContainer(
    BuildContext context,
    presentation.ContainerLayout container,
    PortablePresentationScope childScope,
  ) => DecoratedBox(
    decoration: BoxDecoration(
      color: _color(childScope, container.backgroundColor),
      border: _border(context, container.border, childScope),
      borderRadius: _radius(context, container.radius, childScope),
    ),
    child: PortablePresentationNodeRenderer(
      node: container.child,
      scope: childScope,
    ),
  );

  Widget _renderSection(
    BuildContext context,
    presentation.SectionLayout section,
    PortablePresentationScope childScope,
  ) {
    return PortablePresentationNodeRenderer(
      node: section.child,
      scope: childScope,
    );
  }

  Widget _decorateSection(
    BuildContext context,
    presentation.SectionLayout section,
    PortablePresentationScope childScope,
    Widget child,
  ) {
    final border = _border(context, section.border, childScope);
    return DepthBox(
      child: border == null
          ? child
          : DecoratedBox(
              decoration: BoxDecoration(
                border: border,
                borderRadius: context.shapes.mediumBorderRadius,
              ),
              child: child,
            ),
    );
  }

  Widget _renderSpacer(
    presentation.SpacerLayout spacer,
    PortablePresentationScope childScope,
  ) => SizedBox(
    width: _number(childScope, spacer.width),
    height: _number(childScope, spacer.height),
  );

  Widget _renderNamed(
    presentation.NamedControl control,
    PortablePresentationScope childScope,
  ) => PortableNamedControlHost(
    control: control,
    bindings: childScope.bindings,
    budget: childScope.budget,
    setBinding: childScope.write,
    unavailableBuilder: (context, message) => _diagnostic(message),
    builder: (context, customPresentation, payload) {
      if (customPresentation == null) {
        return _diagnostic("The named control has no payload presentation");
      }
      return PortablePresentationNodeRenderer(
        node: customPresentation,
        scope: childScope.withNamedPayload(payload),
      );
    },
  );

  Widget _decorateCollection(
    presentation.BoundControl control,
    PortablePresentationScope childScope,
    Widget child,
  ) => _controlFrame(control, childScope, child);
}

Widget _controlFrame(
  presentation.BoundControl control,
  PortablePresentationScope childScope,
  Widget child,
) {
  final resolvedLabel = _controlString(control.label, childScope);
  final description = _controlString(control.description, childScope);
  final semanticLabel = _controlString(
    control.semanticLabel ?? control.label,
    childScope,
  );
  final semanticChild = semanticLabel == null || semanticLabel.isEmpty
      ? child
      : MergeSemantics(
          child: Semantics(label: semanticLabel, child: child),
        );
  return Builder(
    builder: (context) {
      final enclosingTitle = _PortableHeaderTitle.maybeOf(context);
      final label = resolvedLabel?.trim() == enclosingTitle?.trim()
          ? null
          : resolvedLabel;
      final hasMessage =
          (label != null && label.isNotEmpty) ||
          (description != null && description.isNotEmpty);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          LabeledMessage(label: label, message: description),
          if (hasMessage) const SizedBox(height: 6),
          semanticChild,
        ],
      );
    },
  );
}

Widget? _controlPrefix(
  presentation.BoundControl control,
  PortablePresentationScope childScope,
) {
  final prefix = control.prefix;
  if (prefix == null) return null;
  final rendered = PortablePresentationNodeRenderer(
    node: prefix,
    scope: childScope,
  );
  final semanticLabel = _controlString(
    control.semanticLabel ?? control.label,
    childScope,
  );
  return semanticLabel == null || semanticLabel.isEmpty
      ? rendered
      : ExcludeSemantics(child: rendered);
}

Widget? _paddedControlPrefix(
  presentation.BoundControl control,
  PortablePresentationScope childScope,
) {
  final prefix = _controlPrefix(control, childScope);
  return prefix == null
      ? null
      : Builder(
          builder: (context) => Padding(
            padding: EdgeInsets.all(context.spacing.space2),
            child: prefix,
          ),
        );
}

Widget _withControlPrefix(
  presentation.BoundControl control,
  PortablePresentationScope childScope,
  Widget child,
) {
  final prefix = _controlPrefix(control, childScope);
  if (prefix == null) return child;
  return Builder(
    builder: (context) => Row(
      children: [
        Padding(padding: EdgeInsets.all(context.spacing.space2), child: prefix),
        const SizedBox(width: 6),
        Expanded(child: child),
      ],
    ),
  );
}

final class _AuthoredLinkValueInput extends StatelessWidget {
  const _AuthoredLinkValueInput({
    required this.control,
    required this.scope,
    required this.location,
    required this.candidates,
    required this.candidateDefinition,
    this.framed = true,
    this.showPrefix = true,
    this.leading,
    super.key,
  });

  final presentation.LinkControl control;
  final PortablePresentationScope scope;
  final types.ValueLocation location;
  final Map<types.ResourceId, _AuthoredCollectionRow>? candidates;
  final presentation.PresentationCollectionDefinition? candidateDefinition;
  final bool framed;
  final bool showPrefix;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final record = scope.authoring?.resource(location.resource);
    final value = record == null
        ? null
        : switch (record.readAt(location.path)) {
            PortablePathValue(value: final value) => value,
            PortablePathUnavailable() => null,
          };
    final link = value?.authoredLink;
    final enabled = scope.enabled && !scope.readOnly;
    final selectedRow = link == null ? null : candidates?[link.target.resource];
    final summary = selectedRow != null && candidateDefinition != null
        ? _AuthoredCollectionRowAppearance(
            row: selectedRow,
            definition: candidateDefinition!,
          )
        : Text(
            link == null
                ? "No resource selected"
                : _authoredLinkTargetLabel(
                        scope.authoring?.resource(link.target.resource),
                      ) ??
                      link.target.resource.value,
            overflow: TextOverflow.ellipsis,
          );
    final content = DepthBox(
      child: Padding(
        padding: EdgeInsets.all(context.spacing.space2),
        child: Row(
          children: [
            ?leading,
            if (leading != null) SizedBox(width: context.spacing.space2),
            if (showPrefix) ?_controlPrefix(control.control, scope),
            if (showPrefix && control.control.prefix != null)
              SizedBox(width: context.spacing.space2),
            Expanded(child: summary),
            IconButton(
              tooltip: link == null
                  ? "Choose linked resource"
                  : "Change linked resource",
              onPressed: enabled
                  ? () => _chooseLink(
                      context: context,
                      scope: scope,
                      control: control,
                      location: location,
                      candidates: candidates,
                      candidateDefinition: candidateDefinition,
                    )
                  : null,
              icon: Icon(link == null ? Icons.link : Icons.edit_outlined),
            ),
            if (link != null)
              IconButton(
                tooltip: "Clear link",
                onPressed: enabled
                    ? () {
                        scope.authoring?.disconnect(
                          authoring.LinkOccurrence(
                            id: authoring.LinkOccurrenceId(
                              endpoint: link.endpoint,
                              location: location,
                            ),
                            source: location.resource,
                            target: link.target,
                          ),
                        );
                        scope.onDraftChanged?.call();
                      }
                    : null,
                icon: const Icon(Icons.link_off),
              ),
          ],
        ),
      ),
    );
    return framed ? _controlFrame(control.control, scope, content) : content;
  }
}

Future<void> _chooseLink({
  required BuildContext context,
  required PortablePresentationScope scope,
  required presentation.LinkControl control,
  required types.ValueLocation location,
  required Map<types.ResourceId, _AuthoredCollectionRow>? candidates,
  required presentation.PresentationCollectionDefinition? candidateDefinition,
}) async {
  final draft = scope.authoring;
  final catalog = scope.catalog;
  if (draft == null || catalog == null) return;
  final plans = portableLinkPlans(
    draft: draft,
    catalog: catalog,
    source: location,
  );
  if (!context.mounted) return;
  final choices = _authoredLinkChoices(
    plans: plans,
    scope: scope,
    candidates: candidates,
    candidateDefinition: candidateDefinition,
  );
  final decision = await showSearchModal<_AuthoredLinkDecision>(
    context,
    (ref, modalContext) {
      final source = _AuthoredLinkSearchSource(
        choices,
        candidatePolicy: control.candidatePolicy,
        problem: switch (plans) {
          PortableLinkPlanUnavailable(:final message) => message,
          PortableLinkPlanReady() => null,
        },
      );
      return SearchContribution(
        session: SearchSession(
          source: source,
          interaction: SearchInteraction(
            activation: SearchActivation.custom(
              dependencies: const [],
              evaluate: (_, result) {
                final choice = result.payload as _AuthoredLinkChoice;
                final reason = choice.disabledReason;
                return reason == null
                    ? const SearchActivationState.enabled()
                    : SearchActivationState.disabled(reason);
              },
              activate: (_, result) async {
                final choice = result.payload as _AuthoredLinkChoice;
                try {
                  final decision = await _resolveAuthoredLinkChoice(
                    choice: choice,
                    scope: scope,
                    source: location,
                  );
                  return SearchActivationResult.complete(decision);
                } on Object catch (error) {
                  source.reportFailure(
                    "The counterpart could not be prepared: $error",
                  );
                  return const SearchActivationResult.keepOpen();
                }
              },
            ),
            selectionMode: SearchSelectionMode.single,
          ),
        ),
      );
    },
    searchHint: "Search linked resources",
    rowRenderers: {
      _authoredLinkChoiceResultType.rowRendererId:
          _buildAuthoredLinkChoiceResult,
    },
  );
  if (decision == null) return;
  draft.connect(
    decision.plan.source,
    decision.target.resource,
    counterpart: decision.counterpart,
  );
  scope.onDraftChanged?.call();
}

final class _AuthoredLinkDecision {
  const _AuthoredLinkDecision({
    required this.plan,
    required this.target,
    required this.counterpart,
  });

  final PortableLinkPlan plan;
  final PortableLinkTargetChoice target;
  final authoring.CounterpartChoice? counterpart;
}

final class _AuthoredCollectionRowAppearance extends StatelessWidget {
  const _AuthoredCollectionRowAppearance({
    required this.row,
    required this.definition,
  });

  final _AuthoredCollectionRow row;
  final presentation.PresentationCollectionDefinition definition;

  @override
  Widget build(BuildContext context) {
    final catalog = row.scope.catalog;
    final record = row.scope.authoring?.resource(row.resource);
    final fallbackLabel =
        _authoredLinkTargetLabel(record) ?? row.resource.value;
    if (catalog == null || record == null) return Text(fallbackLabel);
    final appearance = definition.resources?.appearance;
    final material = appearance == null
        ? switch (catalog.selectPresentation(
            record.configuration,
            catalog_wire.PresentationRole.referenceOption,
          )) {
            SelectedEditorPresentation(:final material) => material,
            _ => null,
          }
        : catalog.presentationMaterial(appearance, record.configuration);
    if (material == null) return Text(fallbackLabel);
    final scope = row.scope
        .withValues({_configuredValueBindingId: row.row})
        .withMaterial(material)
        .withActivePresentation(material.provider);
    return PortablePresentationNodeRenderer(
      node: material.layout,
      scope: scope,
    );
  }
}

const _authoredLinkChoiceResultType = SearchResultType(
  id: "authoring.link.choice",
  rowRendererId: "authoring.link.choice",
  label: "Linked resource",
);

enum _AuthoredLinkChoiceKind { automatic, existing, create, unavailable }

final class _AuthoredLinkChoice {
  const _AuthoredLinkChoice({
    required this.id,
    required this.widgetKey,
    required this.plan,
    required this.target,
    required this.kind,
    required this.label,
    required this.typeLabel,
    required this.subtitle,
    required this.searchText,
    this.row,
    this.definition,
    this.occurrence,
    this.slot,
    this.disabledReason,
  });

  final String id;
  final String widgetKey;
  final PortableLinkPlan plan;
  final PortableLinkTargetChoice target;
  final _AuthoredLinkChoiceKind kind;
  final String label;
  final String typeLabel;
  final String subtitle;
  final String searchText;
  final _AuthoredCollectionRow? row;
  final presentation.PresentationCollectionDefinition? definition;
  final authoring.LinkOccurrence? occurrence;
  final PortableNewCounterpartChoice? slot;
  final String? disabledReason;
}

List<_AuthoredLinkChoice> _authoredLinkChoices({
  required PortableLinkPlanResult plans,
  required PortablePresentationScope scope,
  required Map<types.ResourceId, _AuthoredCollectionRow>? candidates,
  required presentation.PresentationCollectionDefinition? candidateDefinition,
}) {
  if (plans case PortableLinkPlanUnavailable()) return const [];
  final choices = <_AuthoredLinkChoice>[];
  for (final plan in (plans as PortableLinkPlanReady).plans) {
    final planId = [
      plan.relation.id.value,
      plan.source.id.endpoint.value,
      plan.source.id.location.resource.value,
      _pathLabel(plan.source.id.location.path),
    ].join(":");
    for (final target in plan.targets) {
      final row = candidates?[target.resource];
      if (candidates != null && row == null) continue;
      final record = scope.authoring?.resource(target.resource);
      final label = _authoredLinkTargetLabel(record) ?? target.resource.value;
      final typeLabel = record == null
          ? "Resource"
          : scope.catalog?.typeSelectionName(record.configuration) ??
                "Resource";
      final targetSearchText = [
        target.resource.value,
        label,
        typeLabel,
        if (row != null) canonicalAuthoredValue(row.row),
      ].join(" ").toLowerCase();
      if (target.automaticCounterpart) {
        choices.add(
          _AuthoredLinkChoice(
            id: "$planId:${target.resource.value}:automatic",
            widgetKey: "link.target.${target.resource.value}.automatic",
            plan: plan,
            target: target,
            kind: _AuthoredLinkChoiceKind.automatic,
            label: label,
            typeLabel: typeLabel,
            subtitle: "Use the declared counterpart",
            searchText: "$targetSearchText declared counterpart",
            row: row,
            definition: candidateDefinition,
          ),
        );
      }
      for (final occurrence in target.existing) {
        final path = _pathLabel(occurrence.id.location.path);
        choices.add(
          _AuthoredLinkChoice(
            id: "$planId:${target.resource.value}:existing:$path",
            widgetKey: "link.target.${target.resource.value}.existing.$path",
            plan: plan,
            target: target,
            kind: _AuthoredLinkChoiceKind.existing,
            label: label,
            typeLabel: typeLabel,
            subtitle: "Use $path",
            searchText: "$targetSearchText use $path",
            row: row,
            definition: candidateDefinition,
            occurrence: occurrence,
          ),
        );
      }
      for (final slot in target.creatable) {
        final path = _pathLabel(slot.containing.path);
        choices.add(
          _AuthoredLinkChoice(
            id: "$planId:${target.resource.value}:new:$path",
            widgetKey: "link.target.${target.resource.value}.new.$path",
            plan: plan,
            target: target,
            kind: _AuthoredLinkChoiceKind.create,
            label: label,
            typeLabel: typeLabel,
            subtitle: "Create counterpart in $path",
            searchText: "$targetSearchText create counterpart $path",
            row: row,
            definition: candidateDefinition,
            slot: slot,
            disabledReason: scope.prepareCreation == null
                ? "Creation preparation is unavailable"
                : null,
          ),
        );
      }
      if (!target.automaticCounterpart &&
          target.existing.isEmpty &&
          target.creatable.isEmpty) {
        choices.add(
          _AuthoredLinkChoice(
            id: "$planId:${target.resource.value}:unavailable",
            widgetKey: "link.target.${target.resource.value}.unavailable",
            plan: plan,
            target: target,
            kind: _AuthoredLinkChoiceKind.unavailable,
            label: label,
            typeLabel: typeLabel,
            subtitle: "Choose or create a counterpart location first",
            searchText: targetSearchText,
            row: row,
            definition: candidateDefinition,
            disabledReason: "No counterpart location is available",
          ),
        );
      }
    }
  }
  return choices;
}

String? _authoredLinkTargetLabel(types.AuthoringRecord? record) {
  if (record == null) return null;
  for (final field in const ["name", "title"]) {
    final value = record.authoredField(field)?.authoredString?.trim();
    if (value != null && value.isNotEmpty) return value;
  }
  return null;
}

final class _AuthoredLinkSearchSource implements SearchSource {
  _AuthoredLinkSearchSource(
    this.choices, {
    required this.candidatePolicy,
    required this.problem,
  });

  final List<_AuthoredLinkChoice> choices;
  final presentation.LinkCandidatePolicyId? candidatePolicy;
  final String? problem;
  final _snapshots = StreamController<SearchSourceSnapshot>.broadcast(
    sync: true,
  );
  SearchQueryContext _query = SearchQueryContext.empty;
  String? _failure;
  bool _disposed = false;

  @override
  Stream<SearchSourceSnapshot> get snapshots => _snapshots.stream;

  @override
  List<QuerySelectorDefinition> get selectors => const [];

  @override
  void initialize(SearchQueryContext context) => search(context);

  @override
  void search(SearchQueryContext context) {
    _query = context;
    _failure = null;
    _publish();
  }

  void reportFailure(String message) {
    _failure = message;
    _publish();
  }

  void _publish() {
    if (_disposed) return;
    final term = _query.normalizedQuery.trim().toLowerCase();
    final matches = choices
        .where((choice) => term.isEmpty || choice.searchText.contains(term))
        .toList(growable: false);
    final failure = _failure ?? problem;
    _snapshots.add(
      SearchSourceSnapshot(
        status: failure == null
            ? SearchSourceStatus.ready
            : SearchSourceStatus.error,
        nodes: [
          if (matches.isNotEmpty)
            SearchNode.section(
              id: "authoring.link.choices",
              title: "Available resources",
              children: [
                for (final choice in matches)
                  SearchNode.result(
                    result: SearchResult(
                      id: choice.id,
                      type: _authoredLinkChoiceResultType,
                      payload: choice,
                      title: choice.label,
                      subtitle: "${choice.typeLabel}. ${choice.subtitle}",
                    ),
                  ),
              ],
            ),
        ],
        errorSummaries: [
          if (failure != null)
            SearchErrorSummary(
              id: "authoring.link.prepare",
              message: failure,
              severity: SearchErrorSeverity.error,
              sourceLabel: "Linked resource",
            ),
        ],
        guidance: [
          if (candidatePolicy case final policy?)
            SearchGuidance(
              id: "authoring.link.candidate_policy",
              title: "Candidate policy",
              description: policy.value,
              visibility: SearchGuidanceVisibility.always,
            ),
        ],
      ),
    );
  }

  @override
  Future<SearchPreviewRequestResult> preview(
    SearchPreviewRequest request,
  ) async => const SearchPreviewRequestResult.error(
    message: "Linked resources do not provide a separate preview",
  );

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    unawaited(_snapshots.close());
  }
}

Widget _buildAuthoredLinkChoiceResult(SearchResultRowContext context) {
  final choice = context.result.payload as _AuthoredLinkChoice;
  return Builder(
    builder: (buildContext) {
      final color = Theme.of(buildContext).colorScheme.primary;
      final appearance = choice.row != null && choice.definition != null
          ? _AuthoredCollectionRowAppearance(
              row: choice.row!,
              definition: choice.definition!,
            )
          : SearchResultTitle(title: choice.label);
      return SearchResultCard(
        key: ValueKey(choice.widgetKey),
        color: color,
        prefix: SearchResultIconTile(
          color: color,
          onColor: color.on(buildContext),
          icon: Icon(switch (choice.kind) {
            _AuthoredLinkChoiceKind.automatic => Icons.link,
            _AuthoredLinkChoiceKind.existing => Icons.link_outlined,
            _AuthoredLinkChoiceKind.create => Icons.add_link,
            _AuthoredLinkChoiceKind.unavailable => Icons.link_off,
          }),
          focused: context.focused,
          loading: context.loading,
        ),
        selected: context.selected,
        focused: context.focused,
        onTap: context.onTap,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          spacing: buildContext.spacing.space1,
          children: [
            IgnorePointer(child: appearance),
            SearchResultDescription(
              description: "${choice.typeLabel}. ${choice.subtitle}",
            ),
          ],
        ),
        suffix: SearchResultSuffix(
          label: switch (choice.kind) {
            _AuthoredLinkChoiceKind.automatic => "automatic",
            _AuthoredLinkChoiceKind.existing => "existing",
            _AuthoredLinkChoiceKind.create => "create",
            _AuthoredLinkChoiceKind.unavailable => "unavailable",
          },
          shortcutActivator: context.shortcutActivator,
          selected: context.selected,
        ),
      );
    },
  );
}

Future<_AuthoredLinkDecision> _resolveAuthoredLinkChoice({
  required _AuthoredLinkChoice choice,
  required PortablePresentationScope scope,
  required types.ValueLocation source,
}) async {
  switch (choice.kind) {
    case _AuthoredLinkChoiceKind.automatic:
      return _AuthoredLinkDecision(
        plan: choice.plan,
        target: choice.target,
        counterpart: null,
      );
    case _AuthoredLinkChoiceKind.existing:
      return _AuthoredLinkDecision(
        plan: choice.plan,
        target: choice.target,
        counterpart: authoring.CounterpartChoice.wrapExisting(
          choice.occurrence!,
        ),
      );
    case _AuthoredLinkChoiceKind.create:
      final prepare = scope.prepareCreation;
      final draft = scope.authoring;
      final slot = choice.slot;
      if (prepare == null || draft == null || slot == null) {
        throw StateError("Creation preparation is unavailable");
      }
      final identity = _initializationIdentity(
        generation: draft.generation,
        source: source,
        target: choice.target.resource,
        slot: slot,
      );
      final prepared = await prepare(
        catalog_wire.InitializationRequest(
          id: types.InitializationRequestId(value: "panel:link:$identity"),
          catalog: draft.generation,
          type: slot.selection,
          supplied: const [],
          intentHash: identity,
        ),
      );
      return _AuthoredLinkDecision(
        plan: choice.plan,
        target: choice.target,
        counterpart: authoring.CounterpartChoice.createNew(
          containing: slot.containing,
          prepared: prepared,
        ),
      );
    case _AuthoredLinkChoiceKind.unavailable:
      throw StateError("No counterpart location is available");
  }
}

String _initializationIdentity({
  required types.CatalogGeneration generation,
  required types.ValueLocation source,
  required types.ResourceId target,
  required PortableNewCounterpartChoice slot,
}) {
  final content = [
    generation.value,
    source.resource.value,
    _pathLabel(source.path),
    target.value,
    slot.containing.resource.value,
    _pathLabel(slot.containing.path),
    slot.selection.toString(),
  ].join("\u0000");
  return sha256.convert(utf8.encode(content)).toString();
}

String _pathLabel(types.ValuePath path) {
  if (path.segments.isEmpty) return "resource root";
  return path.segments
      .map((segment) {
        return switch (segment) {
          types.PathSegment_fieldWrapper(:final value) => value.name,
          types.PathSegment_itemWrapper(:final value) =>
            "item ${value.id.value}",
          final value when value == types.PathSegment.mapKey => "key",
          final value when value == types.PathSegment.mapValue => "value",
          _ => "unknown",
        };
      })
      .join(" / ");
}

enum _PageResourceAction { disconnect, delete }

sealed class _PageProjection {
  const _PageProjection();
}

final class _PageProjectionValue extends _PageProjection {
  const _PageProjectionValue({required this.draft, required this.entries});

  final PortableAuthoringDocument draft;
  final List<_PageEntry> entries;
}

final class _PageProjectionFailure extends _PageProjection {
  const _PageProjectionFailure(this.message);

  final String message;
}

final class _PageEntry {
  const _PageEntry({
    required this.resource,
    required this.draft,
    required this.occurrence,
    required this.graph,
  });

  final types.ResourceId resource;
  final PortableAuthoringDocument draft;
  final authoring.LinkOccurrence occurrence;
  final _PageGraphPlacement? graph;
}

final class _PageGraphPlacement {
  const _PageGraphPlacement({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final int x;
  final int y;
  final int width;
  final int height;
}

_PageProjection _pageProjection(
  presentation.BoundControl control,
  PortablePresentationScope scope,
) {
  final draft = scope.authoring;
  final source = scope.location(control.binding);
  if (draft == null || source == null) {
    return const _PageProjectionFailure(
      "The page elements binding is unavailable",
    );
  }
  final relations = {
    for (final relation
        in scope.catalog?.snapshot.relations ??
            const <catalog_wire.RelationContract>[])
      relation.id: relation,
  };
  final entries = <_PageEntry>[];
  for (final link in draft.links) {
    final first =
        link.first == source.resource &&
        _pathIsAtOrBelow(link.firstLocation, source.path);
    final second =
        link.second == source.resource &&
        _pathIsAtOrBelow(link.secondLocation, source.path);
    if (!first && !second) continue;
    final relation = relations[link.contract];
    final endpoint = first ? relation?.first.id : relation?.second.id;
    final location = first ? link.firstLocation : link.secondLocation;
    final opposite = first ? link.secondLocation : link.firstLocation;
    if (endpoint == null || location == null) continue;
    final target = first ? link.second : link.first;
    final record = draft.resource(target);
    if (record == null) continue;
    entries.add(
      _PageEntry(
        resource: target,
        draft: draft,
        occurrence: authoring.LinkOccurrence(
          id: authoring.LinkOccurrenceId(
            endpoint: endpoint,
            location: types.ValueLocation(
              resource: source.resource,
              path: location,
            ),
          ),
          source: source.resource,
          target: types.LinkTarget(resource: target, opposite: opposite),
        ),
        graph: _graphPlacement(record.authoredField("placement")),
      ),
    );
  }
  return _PageProjectionValue(draft: draft, entries: entries);
}

bool _pathIsAtOrBelow(types.ValuePath? candidate, types.ValuePath parent) {
  if (candidate == null) return false;
  final child = candidate.segments.toList(growable: false);
  final root = parent.segments.toList(growable: false);
  if (child.length < root.length) return false;
  for (var index = 0; index < root.length; index++) {
    if (child[index] != root[index]) return false;
  }
  return true;
}

_PageGraphPlacement? _graphPlacement(types.DataValue? value) {
  final x = value?.authoredField("x")?.authoredInteger?.toInt();
  final y = value?.authoredField("y")?.authoredInteger?.toInt();
  final width = value?.authoredField("width")?.authoredInteger?.toInt();
  final height = value?.authoredField("height")?.authoredInteger?.toInt();
  if (x == null || y == null || width == null || height == null) return null;
  if (width <= 0 || height <= 0) return null;
  return _PageGraphPlacement(x: x, y: y, width: width, height: height);
}

String _linkOccurrenceKey(
  facts.LinkProjection link,
  catalog_wire.RelationContract? relation,
) {
  final location = link.firstLocation ?? link.secondLocation;
  final first = link.firstLocation != null;
  final endpoint = first ? relation?.first.id : relation?.second.id;
  final containing = first ? link.first : link.second;
  return _framed([
    endpoint?.value ?? link.contract.value,
    containing.value,
    _pathKey(location),
  ]);
}

String _pathKey(types.ValuePath? path) {
  if (path == null) return "n";
  return _framed([
    for (final segment in path.segments)
      switch (segment) {
        types.PathSegment_fieldWrapper(:final value) => "f:${value.name}",
        types.PathSegment_itemWrapper(:final value) => "i:${value.id.value}",
        types.PathSegment.mapKey => "k",
        types.PathSegment.mapValue => "v",
        types.PathSegment_unknown() => "u",
      },
  ]);
}

String _framed(Iterable<String> values) =>
    values.map((value) => "${value.length}:$value").join();

enum _TimelinePlacementKind { segment, keyframe }

_TimelinePlacementKind? _timelinePlacementKind(
  CheckedEditorCatalog catalog,
  types.AuthoringRecord record,
) {
  final placement = catalog
      .fields(record.configuration)
      .where((field) => field.template.key == "placement")
      .firstOrNull
      ?.type;
  if (placement == null) return null;
  if (catalog.isReadableAs(placement, _timelineKeyframePlacement)) {
    return _TimelinePlacementKind.keyframe;
  }
  if (catalog.isReadableAs(placement, _timelineSegmentPlacement)) {
    return _TimelinePlacementKind.segment;
  }
  return null;
}

final _timelineSegmentPlacement = _declaredType(
  "54e38e56871243d2ae747ed6c0083381",
);
final _timelineKeyframePlacement = _declaredType(
  "e0369811aac94bf6a291f65d1c719e1b",
);

types.TypeUse _declaredType(String id) => types.TypeUse.createNamed(
  definition: types.TypeDefinitionId(
    typeId: types.TypeId.createDeclared(value: id),
    revision: 1,
  ),
  arguments: const [],
);

bool _writePageInteger(
  PortableAuthoringDocument draft,
  types.ResourceId resource,
  String field,
  int value,
) {
  final location = types.ValueLocation(
    resource: resource,
    path: types.ValuePath(
      segments: [
        types.PathSegment.createField(name: "placement"),
        types.PathSegment.createField(name: field),
      ],
    ),
  );
  final current = draft.read(location);
  if (current is! PortablePathValue<types.DataValue>) return false;
  final replacement = current.value.withAuthoredPayload(
    types.DataValue.wrapInteger(value.toString()),
  );
  return draft.set(location, replacement) is PortablePathValue;
}

Iterable<types.ResourceId> _ownedTimelineTargets(
  PortableAuthoringDocument draft,
  CheckedEditorCatalog catalog,
  types.ResourceId source,
) sync* {
  final record = draft.resource(source);
  if (record == null) return;
  final relations = {
    for (final relation in catalog.snapshot.relations) relation.id: relation,
  };
  for (final link in draft.links) {
    final sourceIsFirst = link.first == source;
    final sourceIsSecond = link.second == source;
    if (!sourceIsFirst && !sourceIsSecond) continue;
    final relation = relations[link.contract];
    if (relation == null ||
        !relation.families.any(
          (family) => family.value == "resource.ownership",
        )) {
      continue;
    }
    final sourceEndpoint = sourceIsFirst ? relation.first : relation.second;
    final targetEndpoint = sourceIsFirst ? relation.second : relation.first;
    if (sourceEndpoint.cardinality != catalog_wire.EndpointCardinality.one ||
        targetEndpoint.cardinality != catalog_wire.EndpointCardinality.many) {
      continue;
    }
    final target = sourceIsFirst ? link.second : link.first;
    final targetRecord = draft.resource(target);
    if (targetRecord == null ||
        !catalog.isResourceDefinition(
          targetRecord.configuration,
          _timelineCueResource,
        ) ||
        _timelinePlacementKind(catalog, targetRecord) == null) {
      continue;
    }
    yield target;
  }
}

final _timelineCueResource = catalog_wire.ResourceDefinitionId(
  value: "typewriter.cue",
);

TimelineElement? _timelineElement(
  BuildContext context,
  PortableAuthoringDocument draft,
  CheckedEditorCatalog catalog,
  types.ResourceId resource,
  Map<types.ResourceId, _PageEntry> direct,
  PortablePresentationScope scope,
  Set<types.ResourceId> visited,
  TimelineIdentifier? parent,
) {
  if (direct.containsKey(resource) || !visited.add(resource)) return null;
  final record = draft.resource(resource);
  final placement = record?.authoredField("placement");
  if (record == null || placement == null) return null;
  final kind = _timelinePlacementKind(catalog, record);
  if (kind == null) return null;
  final label = record.authoredField("name")?.authoredString ?? resource.value;
  final id = TimelineIdentifier(resource.value);
  final color = Theme.of(context).colorScheme.primary;
  final frame = placement.authoredField("frame")?.authoredInteger?.toInt();
  if (kind == _TimelinePlacementKind.keyframe && frame != null && frame >= 0) {
    return TimelineKeyframe(
      id: id,
      frame: frame,
      parentId: parent,
      color: color,
      builder: (_, _) => GestureDetector(
        onTap: scope.openResource == null
            ? null
            : () => scope.openResource!(resource),
        child: Semantics(label: label, child: const Icon(Icons.circle)),
      ),
    );
  }
  final start = placement.authoredField("startFrame")?.authoredInteger?.toInt();
  final end = placement.authoredField("endFrame")?.authoredInteger?.toInt();
  if (start == null || end == null || start < 0 || end < start) return null;
  final children = <TimelineElement>[];
  for (final neighbor in _ownedTimelineTargets(draft, catalog, resource)) {
    final child = _timelineElement(
      context,
      draft,
      catalog,
      neighbor,
      direct,
      scope,
      visited,
      id,
    );
    if (child != null && child.endFrame <= end - start) children.add(child);
  }
  return TimelineSegment(
    id: id,
    startFrame: start,
    endFrame: end,
    parentId: parent,
    color: color,
    children: children,
    builder: (_, _) => GestureDetector(
      onTap: scope.openResource == null
          ? null
          : () => scope.openResource!(resource),
      child: Text(label, overflow: TextOverflow.ellipsis),
    ),
  );
}

final class _AuthoredPresentationHeader extends StatefulWidget {
  const _AuthoredPresentationHeader({
    required this.header,
    required this.body,
    required this.scope,
  });

  final presentation.PresentationHeader header;
  final Widget body;
  final PortablePresentationScope scope;

  @override
  State<_AuthoredPresentationHeader> createState() =>
      _AuthoredPresentationHeaderState();
}

final class _PortableHeaderTitle extends InheritedWidget {
  const _PortableHeaderTitle({required this.title, required super.child});

  final String title;

  static String? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_PortableHeaderTitle>()?.title;

  @override
  bool updateShouldNotify(covariant _PortableHeaderTitle oldWidget) =>
      title != oldWidget.title;
}

final class _AuthoredPresentationHeaderState
    extends State<_AuthoredPresentationHeader> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.header.initiallyExpanded ?? true;
  }

  @override
  void didUpdateWidget(covariant _AuthoredPresentationHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.header.initiallyExpanded != widget.header.initiallyExpanded) {
      _expanded = widget.header.initiallyExpanded ?? true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _items(context);
    final before = items
        .where(
          (item) =>
              item.placement.kind ==
              presentation.HeaderActionPlacement_kind.beforeTitleConst,
        )
        .toList();
    final after = items
        .where(
          (item) =>
              item.placement.kind ==
              presentation.HeaderActionPlacement_kind.afterTitleConst,
        )
        .toList();
    final end = items
        .where(
          (item) =>
              item.placement.kind ==
                  presentation.HeaderActionPlacement_kind.endConst ||
              item.placement.kind ==
                  presentation.HeaderActionPlacement_kind.unknown,
        )
        .toList();
    final title = _title();
    final description = widget.header.description == null
        ? null
        : _string(widget.scope, widget.header.description!);
    final collapsible = widget.header.initiallyExpanded != null;
    final contentPadding = widget.header.contentPadding == null
        ? EdgeInsets.symmetric(
            horizontal: context.spacing.space2,
            vertical: context.spacing.space1,
          )
        : _presentationInsets(widget.header.contentPadding);
    final header = Material(
      color: context.colors.surface.withValues(alpha: 0),
      child: InkWell(
        onTap: collapsible && widget.scope.enabled ? _toggleExpanded : null,
        child: Padding(
          padding: widget.header.headerPadding == null
              ? EdgeInsets.symmetric(
                  horizontal: context.spacing.space2,
                  vertical: context.spacing.space1,
                )
              : _presentationInsets(widget.header.headerPadding),
          child: LayoutBuilder(
            builder: (context, constraints) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PortableHeaderRow(
                  before: [
                    if (collapsible) _expandButton(),
                    for (final item in before) item.widget,
                  ],
                  title: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                    child: title,
                  ),
                  after: [for (final item in after) item.widget],
                  end: [for (final item in end) item.widget],
                ),
                if (description != null)
                  Padding(
                    padding: EdgeInsets.only(top: context.spacing.space1),
                    child: switch (description) {
                      _ResolvedValue(:final value) when value.isNotEmpty =>
                        Text(
                          value,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      _ResolvedFailure(:final message) => _diagnostic(message),
                      _ => const SizedBox.shrink(),
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    final plainTitle = _plainTitle();
    final body = Padding(
      padding: contentPadding,
      child: plainTitle == null
          ? widget.body
          : _PortableHeaderTitle(title: plainTitle, child: widget.body),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        Visibility(
          visible: _expanded,
          maintainState: true,
          maintainAnimation: true,
          child: body,
        ),
      ],
    );
  }

  void _toggleExpanded() => setState(() => _expanded = !_expanded);

  Widget _expandButton() => IconButton(
    tooltip: _expanded ? "Collapse" : "Expand",
    onPressed: widget.scope.enabled ? _toggleExpanded : null,
    icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
  );

  Widget _title() => switch (widget.header.title) {
    presentation.PresentationHeaderTitle_textWrapper(:final value) =>
      switch (_string(widget.scope, value)) {
        _ResolvedValue(:final value) => Text(
          value,
          style: context.theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        _ResolvedFailure(:final message) => _diagnostic(message),
      },
    presentation.PresentationHeaderTitle_presentationWrapper(:final value) =>
      PortablePresentationNodeRenderer(node: value, scope: widget.scope),
    _ => _diagnostic("The presentation header title is unavailable"),
  };

  String? _plainTitle() => switch (widget.header.title) {
    presentation.PresentationHeaderTitle_textWrapper(:final value) =>
      switch (_string(widget.scope, value)) {
        _ResolvedValue(:final value) => value,
        _ => null,
      },
    _ => null,
  };

  List<_AuthoredHeaderItem> _items(BuildContext context) {
    final resolved = <_AuthoredHeaderItem>[];
    var order = 0;
    for (final item in widget.header.items) {
      final currentOrder = order++;
      switch (item) {
        case presentation.HeaderItem_buttonWrapper(:final value):
          final visible = _boolean(
            widget.scope,
            value.visibleIf,
            fallback: true,
          );
          if (visible case _ResolvedValue(value: false)) continue;
          if (visible case _ResolvedFailure(:final message)) {
            resolved.add(
              _failureItem(context, message, value.placement, currentOrder),
            );
            continue;
          }
          final labelResult = _string(widget.scope, value.label);
          if (labelResult case _ResolvedFailure(:final message)) {
            resolved.add(
              _failureItem(context, message, value.placement, currentOrder),
            );
            continue;
          }
          final label = (labelResult as _ResolvedValue<String>).value;
          final iconName = _resolvedString(value.icon);
          final tooltipResult = value.tooltip == null
              ? _ResolvedValue(label)
              : _string(widget.scope, value.tooltip!);
          final enabledResult = _boolean(
            widget.scope,
            value.enabledIf,
            fallback: true,
          );
          final enabled =
              widget.scope.canExecuteAction &&
              enabledResult is _ResolvedValue<bool> &&
              enabledResult.value;
          final tooltip = switch (enabledResult) {
            _ResolvedFailure(:final message) => message,
            _ => switch (tooltipResult) {
              _ResolvedValue(:final value) => value,
              _ResolvedFailure(:final message) => message,
            },
          };
          final destructive =
              value.tone.kind ==
              presentation.HeaderActionTone_kind.destructiveConst;
          final button = TextButton.icon(
            onPressed: enabled
                ? () => _runAction(
                    context,
                    value.action,
                    value.confirmation,
                    destructive: destructive,
                  )
                : null,
            style: destructive
                ? TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  )
                : null,
            icon: Icon(
              iconName == null ? Icons.more_horiz : _materialIcon(iconName),
              size: 18,
            ),
            label: Text(label),
          );
          resolved.add(
            _AuthoredHeaderItem(
              widget: Tooltip(message: tooltip, child: button),
              placement: value.placement,
              priority: _priority(value.priority),
              order: currentOrder,
            ),
          );
        case presentation.HeaderItem_booleanToggleWrapper(:final value):
          final visible = _boolean(
            widget.scope,
            value.visibleIf,
            fallback: true,
          );
          if (visible case _ResolvedValue(value: false)) continue;
          final label = _string(widget.scope, value.label);
          final checked = _boolean(widget.scope, value.checked);
          final failure = switch ((visible, label, checked)) {
            (_ResolvedFailure(:final message), _, _) => message,
            (_, _ResolvedFailure(:final message), _) => message,
            (_, _, _ResolvedFailure(:final message)) => message,
            _ => null,
          };
          if (failure != null) {
            resolved.add(
              _failureItem(context, failure, value.placement, currentOrder),
            );
            continue;
          }
          final labelValue = (label as _ResolvedValue<String>).value;
          final checkedValue = (checked as _ResolvedValue<bool>).value;
          final enabledResult = _boolean(
            widget.scope,
            value.enabledIf,
            fallback: true,
          );
          final enabled =
              widget.scope.canExecuteAction &&
              enabledResult is _ResolvedValue<bool> &&
              enabledResult.value;
          final checkbox = Shortcuts(
            shortcuts: const {
              SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
              SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
              SingleActivator(LogicalKeyboardKey.numpadEnter): ActivateIntent(),
            },
            child: Checkbox(
              value: checkedValue,
              semanticLabel: labelValue,
              visualDensity: VisualDensity.compact,
              onChanged: enabled
                  ? (_) => _runAction(context, value.action, value.confirmation)
                  : null,
            ),
          );
          resolved.add(
            _AuthoredHeaderItem(
              widget: value.tooltip == null
                  ? enabledResult is _ResolvedFailure<bool>
                        ? Tooltip(
                            message: enabledResult.message,
                            child: checkbox,
                          )
                        : checkbox
                  : Tooltip(
                      message: switch (_string(widget.scope, value.tooltip!)) {
                        _ResolvedValue(:final value) => value,
                        _ResolvedFailure(:final message) => message,
                      },
                      child: checkbox,
                    ),
              placement: value.placement,
              priority: _priority(value.priority),
              order: currentOrder,
            ),
          );
        case presentation.HeaderItem_reorderHandleWrapper(:final value):
          final visible = _boolean(
            widget.scope,
            value.visibleIf,
            fallback: true,
          );
          if (visible case _ResolvedValue(value: false)) continue;
          final label = _string(widget.scope, value.label);
          final target = _reorderTarget(value.source);
          final failure = switch ((visible, label, target)) {
            (_ResolvedFailure(:final message), _, _) => message,
            (_, _ResolvedFailure(:final message), _) => message,
            (_, _, null) =>
              "The reorder source is not a current collection item",
            _ => null,
          };
          if (failure != null) {
            resolved.add(
              _failureItem(
                context,
                failure,
                presentation.HeaderActionPlacement.beforeTitle,
                currentOrder,
              ),
            );
            continue;
          }
          final actualTarget = target!;
          final labelValue = (label as _ResolvedValue<String>).value;
          final enabledResult = _boolean(
            widget.scope,
            value.enabledIf,
            fallback: true,
          );
          final enabled =
              widget.scope.canExecuteAction &&
              enabledResult is _ResolvedValue<bool> &&
              enabledResult.value;
          final tooltip = switch (enabledResult) {
            _ResolvedFailure(:final message) => message,
            _ =>
              value.tooltip == null
                  ? labelValue
                  : switch (_string(widget.scope, value.tooltip!)) {
                      _ResolvedValue(:final value) => value,
                      _ResolvedFailure(:final message) => message,
                    },
          };
          resolved.add(
            _AuthoredHeaderItem(
              widget: _AuthoredReorderHandle(
                index: actualTarget.index,
                label: tooltip,
                enabled: enabled,
                canMoveEarlier: actualTarget.index > 0,
                canMoveLater:
                    actualTarget.index < actualTarget.items.length - 1,
                onMoveEarlier: () => _moveReorderTarget(
                  actualTarget,
                  after: actualTarget.index == 1
                      ? null
                      : actualTarget.items[actualTarget.index - 2].id,
                ),
                onMoveLater: () => _moveReorderTarget(
                  actualTarget,
                  after: actualTarget.items[actualTarget.index + 1].id,
                ),
              ),
              placement: presentation.HeaderActionPlacement.beforeTitle,
              priority: 0,
              order: currentOrder,
            ),
          );
        case presentation.HeaderItem_unknown():
      }
    }
    resolved.sort((left, right) {
      final priority = right.priority.compareTo(left.priority);
      return priority == 0 ? left.order.compareTo(right.order) : priority;
    });
    return resolved;
  }

  _AuthoredHeaderItem _failureItem(
    BuildContext context,
    String message,
    presentation.HeaderActionPlacement placement,
    int order,
  ) => _AuthoredHeaderItem(
    widget: Tooltip(
      message: message,
      child: Icon(
        Icons.warning_amber_rounded,
        color: Theme.of(context).colorScheme.error,
        semanticLabel: message,
      ),
    ),
    placement: placement,
    priority: 0,
    order: order,
  );

  _AuthoredReorderTarget? _reorderTarget(binding.BindingRef source) {
    final location = widget.scope.location(source);
    final draft = widget.scope.authoring;
    if (location == null || draft == null) return null;
    final segments = location.path.segments.toList(growable: false);
    final last = segments.lastOrNull;
    if (last is! types.PathSegment_itemWrapper) return null;
    final item = last.value.id;
    final containing = types.ValueLocation(
      resource: location.resource,
      path: types.ValuePath(segments: segments.take(segments.length - 1)),
    );
    final collection = draft
        .resource(location.resource)
        ?.readAt(containing.path);
    final items = switch (collection) {
      PortablePathValue(:final value) => value.authoredItems?.toList(),
      _ => null,
    };
    if (items == null) return null;
    final index = items.indexWhere((candidate) => candidate.id == item);
    if (index < 0) return null;
    return _AuthoredReorderTarget(
      containing: containing,
      item: item,
      items: items,
      index: index,
    );
  }

  void _moveReorderTarget(
    _AuthoredReorderTarget target, {
    required types.ItemId? after,
  }) {
    final result = widget.scope.authoring?.move(
      target.containing,
      target.item,
      after,
    );
    switch (result) {
      case PortablePathValue():
        widget.scope.onDraftChanged?.call();
      case PortablePathUnavailable(:final message):
        widget.scope.reportStatus?.call(message);
      case null:
        widget.scope.reportStatus?.call("The reorder source is unavailable");
    }
  }

  int _priority(expression.ExpressionNode? value) {
    if (value == null) return 0;
    return switch (widget.scope.evaluate(value)) {
      PortableExpressionAvailable(:final value) =>
        switch (value.authoredPayload) {
          types.DataValue_integerWrapper(:final value) =>
            BigInt.tryParse(value)?.toInt() ?? 0,
          types.DataValue_floatWrapper(:final value) => value.round(),
          _ => 0,
        },
      _ => 0,
    };
  }

  String? _resolvedString(expression.ExpressionNode value) =>
      switch (widget.scope.evaluate(value)) {
        PortableExpressionAvailable(:final value) => value.authoredString,
        _ => null,
      };

  Future<void> _runAction(
    BuildContext context,
    action.EditorAction editorAction,
    presentation.HeaderActionConfirmation? confirmation, {
    bool destructive = false,
  }) async {
    if (confirmation != null) {
      final title = _resolvedString(confirmation.title);
      final message = _resolvedString(confirmation.message);
      final label = _resolvedString(confirmation.confirmationLabel);
      if (title == null || message == null || label == null) {
        widget.scope.reportStatus?.call(
          "The action confirmation is unavailable",
        );
        return;
      }
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Cancel"),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: destructive
                  ? FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                    )
                  : null,
              child: Text(label),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    await widget.scope.executeAction(editorAction);
  }
}

final class _AuthoredHeaderItem {
  const _AuthoredHeaderItem({
    required this.widget,
    required this.placement,
    required this.priority,
    required this.order,
  });

  final Widget widget;
  final presentation.HeaderActionPlacement placement;
  final int priority;
  final int order;
}

final class _PortableHeaderRow extends StatefulWidget {
  const _PortableHeaderRow({
    required this.before,
    required this.title,
    required this.after,
    required this.end,
  });

  final List<Widget> before;
  final Widget title;
  final List<Widget> after;
  final List<Widget> end;

  @override
  State<_PortableHeaderRow> createState() => _PortableHeaderRowState();
}

final class _PortableHeaderRowState extends State<_PortableHeaderRow> {
  var _visibleEndCount = 0;

  @override
  Widget build(BuildContext context) {
    final overflow = widget.end
        .skip(_visibleEndCount.clamp(0, widget.end.length))
        .toList();
    Widget spaced(Widget child) => Padding(
      padding: EdgeInsetsDirectional.only(end: context.spacing.space2),
      child: child,
    );
    return _PortableHeaderLayout(
      beforeTitleCount: widget.before.length,
      afterTitleCount: widget.after.length,
      endCount: widget.end.length,
      textDirection: Directionality.of(context),
      onVisibleEndCountChanged: (value) {
        if (mounted && _visibleEndCount != value) {
          setState(() => _visibleEndCount = value);
        }
      },
      children: [
        for (final item in widget.before) spaced(item),
        widget.title,
        for (final item in widget.after) spaced(item),
        for (final item in widget.end) spaced(item),
        if (widget.end.isNotEmpty)
          _PortableHeaderOverflow(
            items: overflow.isEmpty ? widget.end : overflow,
          ),
      ],
    );
  }
}

final class _PortableHeaderOverflow extends StatelessWidget {
  const _PortableHeaderOverflow({required this.items});

  final List<Widget> items;

  @override
  Widget build(BuildContext context) => MenuAnchor(
    menuChildren: [
      for (final item in items)
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.spacing.space1),
          child: item,
        ),
    ],
    builder: (context, controller, child) => IconButton(
      tooltip: "More actions",
      onPressed: controller.isOpen ? controller.close : controller.open,
      icon: const Icon(Icons.more_horiz),
    ),
  );
}

final class _PortableHeaderParentData
    extends ContainerBoxParentData<RenderBox> {
  bool visible = true;
}

final class _PortableHeaderLayout extends MultiChildRenderObjectWidget {
  const _PortableHeaderLayout({
    required this.beforeTitleCount,
    required this.afterTitleCount,
    required this.endCount,
    required this.textDirection,
    required this.onVisibleEndCountChanged,
    required super.children,
  });

  final int beforeTitleCount;
  final int afterTitleCount;
  final int endCount;
  final ui.TextDirection textDirection;
  final ValueChanged<int> onVisibleEndCountChanged;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderPortableHeaderLayout(
        beforeTitleCount,
        afterTitleCount,
        endCount,
        textDirection,
        onVisibleEndCountChanged,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderPortableHeaderLayout renderObject,
  ) {
    renderObject
      ..beforeTitleCount = beforeTitleCount
      ..afterTitleCount = afterTitleCount
      ..endCount = endCount
      ..textDirection = textDirection
      ..onVisibleEndCountChanged = onVisibleEndCountChanged;
  }
}

final class _RenderPortableHeaderLayout extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _PortableHeaderParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _PortableHeaderParentData> {
  _RenderPortableHeaderLayout(
    this._beforeTitleCount,
    this._afterTitleCount,
    this._endCount,
    this._textDirection,
    this.onVisibleEndCountChanged,
  );

  int _beforeTitleCount;
  int get beforeTitleCount => _beforeTitleCount;
  set beforeTitleCount(int value) {
    if (_beforeTitleCount == value) return;
    _beforeTitleCount = value;
    markNeedsLayout();
  }

  int _afterTitleCount;
  int get afterTitleCount => _afterTitleCount;
  set afterTitleCount(int value) {
    if (_afterTitleCount == value) return;
    _afterTitleCount = value;
    markNeedsLayout();
  }

  int _endCount;
  int get endCount => _endCount;
  set endCount(int value) {
    if (_endCount == value) return;
    _endCount = value;
    markNeedsLayout();
  }

  ui.TextDirection _textDirection;
  ui.TextDirection get textDirection => _textDirection;
  set textDirection(ui.TextDirection value) {
    if (_textDirection == value) return;
    _textDirection = value;
    markNeedsLayout();
  }

  ValueChanged<int> onVisibleEndCountChanged;
  int? _reportedVisibleEndCount;

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! _PortableHeaderParentData) {
      child.parentData = _PortableHeaderParentData();
    }
  }

  @override
  void performLayout() {
    final children = getChildrenAsList();
    final titleIndex = beforeTitleCount;
    final endStart = titleIndex + 1 + afterTitleCount;
    final overflowIndex = endStart + endCount;
    final childConstraints = constraints.loosen();
    final title = children[titleIndex];
    var fixedWidth = 0.0;
    var maxHeight = 0.0;
    for (var index = 0; index < children.length; index++) {
      if (index == titleIndex) continue;
      final child = children[index]
        ..layout(childConstraints, parentUsesSize: true);
      maxHeight = math.max(maxHeight, child.size.height);
      if (index < endStart) fixedWidth += child.size.width;
    }
    final endWidth = children
        .skip(endStart)
        .take(endCount)
        .fold(0.0, (width, child) => width + child.size.width);
    if (!constraints.hasBoundedWidth) {
      title.layout(childConstraints, parentUsesSize: true);
    }
    final availableWidth = constraints.hasBoundedWidth
        ? constraints.maxWidth
        : fixedWidth + endWidth + title.size.width;
    final overflowWidth = endCount > 0 ? children[overflowIndex].size.width : 0;
    final showOverflow = fixedWidth + endWidth > availableWidth;
    final inlineBudget = math.max(
      availableWidth - fixedWidth - (showOverflow ? overflowWidth : 0),
      0.0,
    );
    var visibleEndCount = 0;
    var visibleEndWidth = 0.0;
    for (final child in children.skip(endStart).take(endCount)) {
      if (visibleEndWidth + child.size.width > inlineBudget) break;
      visibleEndWidth += child.size.width;
      visibleEndCount++;
    }
    if (!showOverflow) visibleEndCount = endCount;
    final titleWidth = math.max(
      availableWidth -
          fixedWidth -
          visibleEndWidth -
          (showOverflow ? overflowWidth : 0),
      0.0,
    );
    title.layout(
      childConstraints.copyWith(minWidth: titleWidth, maxWidth: titleWidth),
      parentUsesSize: true,
    );
    maxHeight = math.max(maxHeight, title.size.height);
    size = constraints.constrain(Size(availableWidth, maxHeight));
    var logicalOffset = 0.0;
    var semanticsChanged = false;
    for (var index = 0; index < children.length; index++) {
      final child = children[index];
      final parentData = child.parentData! as _PortableHeaderParentData;
      final visible = switch (index) {
        _ when index < endStart => true,
        _ when index < overflowIndex => index - endStart < visibleEndCount,
        _ => showOverflow,
      };
      if (parentData.visible != visible) {
        parentData.visible = visible;
        semanticsChanged = true;
      }
      if (!visible) continue;
      final allocatedWidth = index == titleIndex
          ? titleWidth
          : child.size.width;
      final x = textDirection == ui.TextDirection.ltr
          ? logicalOffset
          : size.width - logicalOffset - child.size.width;
      parentData.offset = Offset(x, (size.height - child.size.height) / 2);
      logicalOffset += allocatedWidth;
    }
    if (semanticsChanged) markNeedsSemanticsUpdate();
    _reportVisibleEndCount(visibleEndCount);
  }

  void _reportVisibleEndCount(int value) {
    if (_reportedVisibleEndCount == value) return;
    _reportedVisibleEndCount = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!attached || _reportedVisibleEndCount != value) return;
      onVisibleEndCountChanged(value);
    });
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    var child = firstChild;
    while (child != null) {
      final parentData = child.parentData! as _PortableHeaderParentData;
      if (parentData.visible) {
        context.paintChild(child, parentData.offset + offset);
      }
      child = childAfter(child);
    }
  }

  @override
  bool paintsChild(RenderBox child) =>
      (child.parentData! as _PortableHeaderParentData).visible;

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    var child = lastChild;
    while (child != null) {
      final parentData = child.parentData! as _PortableHeaderParentData;
      if (parentData.visible &&
          result.addWithPaintOffset(
            offset: parentData.offset,
            position: position,
            hitTest: (result, transformed) =>
                child!.hitTest(result, position: transformed),
          )) {
        return true;
      }
      child = childBefore(child);
    }
    return false;
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    var child = firstChild;
    while (child != null) {
      final parentData = child.parentData! as _PortableHeaderParentData;
      if (parentData.visible) visitor(child);
      child = childAfter(child);
    }
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    final parentData = child.parentData! as _PortableHeaderParentData;
    transform.translateByDouble(
      parentData.offset.dx,
      parentData.offset.dy,
      0,
      1,
    );
  }
}

final class _AuthoredReorderTarget {
  const _AuthoredReorderTarget({
    required this.containing,
    required this.item,
    required this.items,
    required this.index,
  });

  final types.ValueLocation containing;
  final types.ItemId item;
  final List<types.ListItem> items;
  final int index;
}

final class _MoveEarlierIntent extends Intent {
  const _MoveEarlierIntent();
}

final class _MoveLaterIntent extends Intent {
  const _MoveLaterIntent();
}

final class _AuthoredReorderHandle extends StatefulWidget {
  const _AuthoredReorderHandle({
    required this.index,
    required this.label,
    required this.enabled,
    required this.canMoveEarlier,
    required this.canMoveLater,
    required this.onMoveEarlier,
    required this.onMoveLater,
  });

  final int index;
  final String label;
  final bool enabled;
  final bool canMoveEarlier;
  final bool canMoveLater;
  final VoidCallback onMoveEarlier;
  final VoidCallback onMoveLater;

  @override
  State<_AuthoredReorderHandle> createState() => _AuthoredReorderHandleState();
}

final class _AuthoredReorderHandleState extends State<_AuthoredReorderHandle> {
  final FocusNode _focusNode = FocusNode();
  bool _focused = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FocusableActionDetector(
    focusNode: _focusNode,
    enabled: widget.enabled,
    shortcuts: const {
      SingleActivator(LogicalKeyboardKey.arrowUp, alt: true):
          _MoveEarlierIntent(),
      SingleActivator(LogicalKeyboardKey.arrowDown, alt: true):
          _MoveLaterIntent(),
    },
    actions: {
      _MoveEarlierIntent: CallbackAction<_MoveEarlierIntent>(
        onInvoke: (_) {
          if (widget.canMoveEarlier) widget.onMoveEarlier();
          return null;
        },
      ),
      _MoveLaterIntent: CallbackAction<_MoveLaterIntent>(
        onInvoke: (_) {
          if (widget.canMoveLater) widget.onMoveLater();
          return null;
        },
      ),
    },
    onShowFocusHighlight: (focused) => setState(() => _focused = focused),
    child: Tooltip(
      message: widget.label,
      child: ReorderableDragStartListener(
        index: widget.index,
        enabled: widget.enabled,
        child: GestureDetector(
          onTap: widget.enabled ? _focusNode.requestFocus : null,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(
                color: _focused
                    ? Theme.of(context).colorScheme.primary
                    : context.colors.surface.withValues(alpha: 0),
                width: 2,
              ),
              borderRadius: context.shapes.smallBorderRadius,
            ),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                Icons.drag_handle,
                color: widget.enabled ? null : Theme.of(context).disabledColor,
                semanticLabel: widget.label,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

EdgeInsets _presentationInsets(presentation.PresentationInsets? insets) =>
    switch (insets) {
      presentation.PresentationInsets_allWrapper(:final value) =>
        EdgeInsets.all(value),
      presentation.PresentationInsets_symmetricWrapper(:final value) =>
        EdgeInsets.symmetric(
          horizontal: value.horizontal,
          vertical: value.vertical,
        ),
      presentation.PresentationInsets_onlyWrapper(:final value) =>
        EdgeInsets.fromLTRB(value.left, value.top, value.right, value.bottom),
      _ => EdgeInsets.zero,
    };

final class _AuthoredTabs extends StatefulWidget {
  const _AuthoredTabs({required this.tabs, required this.scope});

  final presentation.TabsLayout tabs;
  final PortablePresentationScope scope;

  @override
  State<_AuthoredTabs> createState() => _AuthoredTabsState();
}

final class _AuthoredTabsState extends State<_AuthoredTabs> {
  late String? _selected;

  @override
  void initState() {
    super.initState();
    _selected = _initialSelection();
  }

  @override
  void didUpdateWidget(covariant _AuthoredTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tabs.tabs.every((tab) => tab.tabId != _selected)) {
      _selected = _initialSelection();
    }
  }

  String? _initialSelection() {
    final requested = widget.tabs.initiallySelectedTabId;
    if (requested != null &&
        widget.tabs.tabs.any((tab) => tab.tabId == requested)) {
      return requested;
    }
    return widget.tabs.tabs.firstOrNull?.tabId;
  }

  @override
  Widget build(BuildContext context) {
    final tabs = widget.tabs.tabs.toList(growable: false);
    if (tabs.isEmpty) return _diagnostic("The tab layout has no tabs");
    final selected = tabs.firstWhere(
      (tab) => tab.tabId == _selected,
      orElse: () => tabs.first,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: context.spacing.space2,
          children: [
            for (final tab in tabs)
              ChoiceChip(
                selected: tab.tabId == selected.tabId,
                label: switch (_string(widget.scope, tab.label)) {
                  _ResolvedValue(:final value) => Text(value),
                  _ResolvedFailure() => Text(tab.tabId),
                },
                onSelected: widget.scope.enabled
                    ? (_) => setState(() => _selected = tab.tabId)
                    : null,
              ),
          ],
        ),
        SizedBox(height: context.spacing.space2),
        PortablePresentationNodeRenderer(
          node: selected.child,
          scope: widget.scope,
        ),
      ],
    );
  }
}

types.DataValue _preserveNamedIdentity(
  types.DataValue? current,
  types.DataValue payload,
) {
  if (current is! types.DataValue_namedWrapper) return payload;
  return types.DataValue.createNamed(
    actualType: current.value.actualType,
    payload: _preserveNamedIdentity(current.value.payload, payload),
  );
}

sealed class _Resolved<T> {
  const _Resolved();
}

final class _EvaluatedActionValue {
  const _EvaluatedActionValue(this.value, this.reads);

  final types.DataValue value;
  final List<PortableExpressionRead> reads;
}

final class _ResolvedValue<T> extends _Resolved<T> {
  const _ResolvedValue(this.value);

  final T value;
}

final class _ResolvedFailure<T> extends _Resolved<T> {
  const _ResolvedFailure(this.message);

  final String message;
}

_Resolved<bool> _boolean(
  PortablePresentationScope scope,
  expression.ExpressionNode? expressionNode, {
  bool fallback = false,
}) {
  if (expressionNode == null) return _ResolvedValue(fallback);
  return switch (scope.evaluate(expressionNode)) {
    PortableExpressionAvailable(:final value)
        when value.authoredPayload is types.DataValue_booleanWrapper =>
      _ResolvedValue(
        (value.authoredPayload as types.DataValue_booleanWrapper).value,
      ),
    PortableExpressionAvailable() => const _ResolvedFailure(
      "The presentation condition is not boolean",
    ),
    PortableExpressionUnavailable() => const _ResolvedFailure(
      "The presentation condition is unavailable",
    ),
    PortableExpressionFailed(:final message) => _ResolvedFailure(message),
  };
}

_Resolved<String> _string(
  PortablePresentationScope scope,
  expression.ExpressionNode expressionNode,
) => switch (scope.evaluate(expressionNode)) {
  PortableExpressionAvailable(:final value) when value.authoredString != null =>
    _ResolvedValue(value.authoredString!),
  PortableExpressionAvailable() => const _ResolvedFailure(
    "The presentation value is not text",
  ),
  PortableExpressionUnavailable() => const _ResolvedFailure(
    "The presentation value is unavailable",
  ),
  PortableExpressionFailed(:final message) => _ResolvedFailure(message),
};

MainAxisAlignment _mainAxis(
  presentation.MainAxisAlignment value,
) => switch (value) {
  presentation.MainAxisAlignment.center => MainAxisAlignment.center,
  presentation.MainAxisAlignment.end => MainAxisAlignment.end,
  presentation.MainAxisAlignment.spaceBetween => MainAxisAlignment.spaceBetween,
  presentation.MainAxisAlignment.spaceAround => MainAxisAlignment.spaceAround,
  presentation.MainAxisAlignment.spaceEvenly => MainAxisAlignment.spaceEvenly,
  _ => MainAxisAlignment.start,
};

CrossAxisAlignment _crossAxis(presentation.CrossAxisAlignment value) =>
    switch (value) {
      presentation.CrossAxisAlignment.center => CrossAxisAlignment.center,
      presentation.CrossAxisAlignment.end => CrossAxisAlignment.end,
      presentation.CrossAxisAlignment.stretch => CrossAxisAlignment.stretch,
      _ => CrossAxisAlignment.start,
    };

WrapAlignment _wrapAlignment(presentation.MainAxisAlignment value) =>
    switch (value) {
      presentation.MainAxisAlignment.center => WrapAlignment.center,
      presentation.MainAxisAlignment.end => WrapAlignment.end,
      presentation.MainAxisAlignment.spaceBetween => WrapAlignment.spaceBetween,
      presentation.MainAxisAlignment.spaceAround => WrapAlignment.spaceAround,
      presentation.MainAxisAlignment.spaceEvenly => WrapAlignment.spaceEvenly,
      _ => WrapAlignment.start,
    };

WrapCrossAlignment _wrapCrossAlignment(presentation.CrossAxisAlignment value) =>
    switch (value) {
      presentation.CrossAxisAlignment.center => WrapCrossAlignment.center,
      presentation.CrossAxisAlignment.end => WrapCrossAlignment.end,
      _ => WrapCrossAlignment.start,
    };

Widget _diagnostic(String message) => Builder(
  builder: (context) => Text(
    message,
    style: context.theme.textTheme.bodyMedium?.copyWith(
      color: context.colors.danger,
    ),
  ),
);

String? _controlString(
  expression.ExpressionNode? value,
  PortablePresentationScope scope,
) {
  if (value == null) return null;
  return switch (_string(scope, value)) {
    _ResolvedValue(:final value) => value,
    _ResolvedFailure() => null,
  };
}

Widget? _controlText(
  expression.ExpressionNode? value,
  PortablePresentationScope scope,
) {
  final text = _controlString(value, scope);
  return text == null ? null : Text(text);
}

double? _number(
  PortablePresentationScope scope,
  expression.ExpressionNode? value,
) {
  if (value == null) return null;
  return switch (scope.evaluate(value)) {
    PortableExpressionAvailable(value: final result) =>
      switch (result.authoredPayload) {
        types.DataValue_integerWrapper(:final value) => double.tryParse(value),
        types.DataValue_floatWrapper(:final value) => value,
        types.DataValue_decimalWrapper(:final value) => double.tryParse(value),
        _ => null,
      },
    _ => null,
  };
}

double? _dataNumber(types.DataValue? value) => switch (value) {
  types.DataValue_integerWrapper(:final value) => double.tryParse(value),
  types.DataValue_floatWrapper(:final value) => value,
  types.DataValue_decimalWrapper(:final value) => double.tryParse(value),
  _ => null,
};

types.TypeUse? _unwrapNullable(types.TypeUse? type) {
  var current = type;
  while (current is types.TypeUse_nullableWrapper) {
    current = current.value.value;
  }
  return current;
}

Color? _color(
  PortablePresentationScope scope,
  expression.ExpressionNode? value,
) {
  if (value == null) return null;
  return switch (scope.evaluate(value)) {
    PortableExpressionAvailable(value: final result)
        when result.authoredInteger != null =>
      Color(result.authoredInteger!.toUnsigned(32).toInt()),
    _ => null,
  };
}

_Resolved<Color?> _optionalTextColor(
  PortablePresentationScope scope,
  expression.ExpressionNode? expressionNode,
) {
  if (expressionNode == null) return const _ResolvedValue(null);
  return switch (scope.evaluate(expressionNode)) {
    PortableExpressionAvailable(value: final value)
        when value.authoredInteger != null =>
      _ResolvedValue(Color(value.authoredInteger!.toUnsigned(32).toInt())),
    PortableExpressionAvailable() => const _ResolvedFailure(
      "Text color must evaluate to a color",
    ),
    PortableExpressionUnavailable() => const _ResolvedFailure(
      "Text color is unavailable",
    ),
    PortableExpressionFailed(:final message) => _ResolvedFailure(message),
  };
}

_Resolved<double?> _optionalTextNumber(
  PortablePresentationScope scope,
  expression.ExpressionNode? expressionNode, {
  required String name,
  double? minimum,
  double? maximum,
  double? minimumExclusive,
  double? maximumExclusive,
}) {
  if (expressionNode == null) return const _ResolvedValue(null);
  final evaluated = scope.evaluate(expressionNode);
  if (evaluated case PortableExpressionFailed(:final message)) {
    return _ResolvedFailure(message);
  }
  if (evaluated is PortableExpressionUnavailable) {
    return _ResolvedFailure("$name is unavailable");
  }
  final value = _dataNumber((evaluated as PortableExpressionAvailable).value);
  if (value == null || !value.isFinite) {
    return _ResolvedFailure("$name must evaluate to a finite number");
  }
  if (minimum != null && value < minimum) {
    return _ResolvedFailure("$name must be at least $minimum");
  }
  if (maximum != null && value > maximum) {
    return _ResolvedFailure("$name must be at most $maximum");
  }
  if (minimumExclusive != null && value <= minimumExclusive) {
    return _ResolvedFailure("$name must be greater than $minimumExclusive");
  }
  if (maximumExclusive != null && value >= maximumExclusive) {
    return _ResolvedFailure("$name must be less than $maximumExclusive");
  }
  return _ResolvedValue(value);
}

_Resolved<String?> _optionalTextString(
  PortablePresentationScope scope,
  expression.ExpressionNode? expressionNode, {
  required String name,
}) {
  if (expressionNode == null) return const _ResolvedValue(null);
  return switch (scope.evaluate(expressionNode)) {
    PortableExpressionAvailable(:final value)
        when value.authoredString != null =>
      _ResolvedValue(value.authoredString),
    PortableExpressionAvailable() => _ResolvedFailure(
      "$name must evaluate to text",
    ),
    PortableExpressionUnavailable() => _ResolvedFailure("$name is unavailable"),
    PortableExpressionFailed(:final message) => _ResolvedFailure(message),
  };
}

_Resolved<TextAlign?> _optionalTextAlignment(
  PortablePresentationScope scope,
  expression.ExpressionNode? expressionNode,
) {
  final resolved = _optionalTextString(
    scope,
    expressionNode,
    name: "Text alignment",
  );
  if (resolved case _ResolvedFailure(:final message)) {
    return _ResolvedFailure(message);
  }
  return switch ((resolved as _ResolvedValue<String?>).value) {
    null => const _ResolvedValue(null),
    "start" => const _ResolvedValue(TextAlign.start),
    "center" => const _ResolvedValue(TextAlign.center),
    "end" => const _ResolvedValue(TextAlign.end),
    "justify" => const _ResolvedValue(TextAlign.justify),
    _ => const _ResolvedFailure(
      "Text alignment must be start, center, end, or justify",
    ),
  };
}

_Resolved<TextDecoration?> _optionalTextDecoration(
  PortablePresentationScope scope,
  expression.ExpressionNode? expressionNode,
) {
  final resolved = _optionalTextString(
    scope,
    expressionNode,
    name: "Text decoration",
  );
  if (resolved case _ResolvedFailure(:final message)) {
    return _ResolvedFailure(message);
  }
  return switch ((resolved as _ResolvedValue<String?>).value) {
    null => const _ResolvedValue(null),
    "none" => const _ResolvedValue(TextDecoration.none),
    "underline" => const _ResolvedValue(TextDecoration.underline),
    "strikethrough" => const _ResolvedValue(TextDecoration.lineThrough),
    _ => const _ResolvedFailure(
      "Text decoration must be none, underline, or strikethrough",
    ),
  };
}

Color? _paragraphToneColor(
  BuildContext context,
  presentation.PresentationTextTone tone,
) => switch (tone.kind) {
  presentation.PresentationTextTone_kind.secondaryConst =>
    context.colors.contentSecondary,
  _ => null,
};

Color _statusColor(BuildContext context, presentation.StatusTone tone) =>
    switch (tone.kind) {
      presentation.StatusTone_kind.successConst => context.colors.success,
      presentation.StatusTone_kind.activeConst ||
      presentation.StatusTone_kind.onlineConst => context.colors.online,
      presentation.StatusTone_kind.warningConst ||
      presentation.StatusTone_kind.pausedConst => context.colors.warning,
      presentation.StatusTone_kind.dangerConst => context.colors.danger,
      presentation.StatusTone_kind.inactiveConst ||
      presentation.StatusTone_kind.offlineConst => context.colors.offline,
      presentation.StatusTone_kind.informationConst ||
      presentation.StatusTone_kind.pendingConst ||
      presentation.StatusTone_kind.inProgressConst => context.colors.info,
      _ => context.colors.contentSecondary,
    };

IconData _statusIcon(presentation.StatusTone tone) => switch (tone.kind) {
  presentation.StatusTone_kind.neutralConst => Icons.circle_outlined,
  presentation.StatusTone_kind.informationConst => Icons.info_outline,
  presentation.StatusTone_kind.successConst => Icons.check_circle_outline,
  presentation.StatusTone_kind.warningConst => Icons.warning_amber_rounded,
  presentation.StatusTone_kind.dangerConst => Icons.error_outline,
  presentation.StatusTone_kind.activeConst => Icons.play_circle_outline,
  presentation.StatusTone_kind.inactiveConst => Icons.stop_circle_outlined,
  presentation.StatusTone_kind.onlineConst => Icons.cloud_done_outlined,
  presentation.StatusTone_kind.offlineConst => Icons.cloud_off_outlined,
  presentation.StatusTone_kind.pendingConst => Icons.schedule_outlined,
  presentation.StatusTone_kind.inProgressConst => Icons.sync,
  presentation.StatusTone_kind.pausedConst => Icons.pause_circle_outline,
  _ => Icons.help_outline,
};

Widget _presentationGrid(
  presentation.GridChildrenLayout layout, {
  required List<Widget> children,
}) => LayoutBuilder(
  builder: (context, constraints) {
    if (!constraints.hasBoundedWidth) {
      return Wrap(
        spacing: layout.horizontalSpacing,
        runSpacing: layout.verticalSpacing,
        children: children,
      );
    }
    final columns = layout.columns < 1 ? 1 : layout.columns;
    final width =
        ((constraints.maxWidth - layout.horizontalSpacing * (columns - 1)) /
                columns)
            .clamp(0.0, constraints.maxWidth);
    return Wrap(
      spacing: layout.horizontalSpacing,
      runSpacing: layout.verticalSpacing,
      children: [
        for (final child in children) SizedBox(width: width, child: child),
      ],
    );
  },
);

IconData _materialIcon(String name) => switch (name) {
  "add" => Icons.add,
  "delete" => Icons.delete,
  "edit" => Icons.edit,
  "save" => Icons.save,
  "search" => Icons.search,
  "more_vert" => Icons.more_vert,
  "auto_awesome" => Icons.auto_awesome,
  _ => Icons.help_outline,
};

BorderRadius? _radius(
  BuildContext context,
  presentation.PresentationRadius radius,
  PortablePresentationScope scope,
) => switch (radius.kind) {
  presentation.PresentationRadius_kind.noneConst => BorderRadius.zero,
  presentation.PresentationRadius_kind.smallConst =>
    context.shapes.smallBorderRadius,
  presentation.PresentationRadius_kind.mediumConst =>
    context.shapes.mediumBorderRadius,
  presentation.PresentationRadius_kind.largeConst =>
    context.shapes.largeBorderRadius,
  presentation.PresentationRadius_kind.customWrapper => BorderRadius.circular(
    _number(
          scope,
          (radius as presentation.PresentationRadius_customWrapper).value,
        ) ??
        0,
  ),
  _ => null,
};

BorderSide _borderSide(
  BuildContext context,
  presentation.PresentationBorderSide side,
  PortablePresentationScope scope,
) => BorderSide(
  color: _color(scope, side.color) ?? context.colors.borderSubtle,
  width: side.width,
);

BoxBorder? _border(
  BuildContext context,
  presentation.PresentationBorder? border,
  PortablePresentationScope scope,
) => switch (border) {
  presentation.PresentationBorder_allWrapper(:final value) =>
    Border.fromBorderSide(_borderSide(context, value, scope)),
  presentation.PresentationBorder_sidesWrapper(:final value) =>
    BorderDirectional(
      top: value.top == null
          ? BorderSide.none
          : _borderSide(context, value.top!, scope),
      start: value.start == null
          ? BorderSide.none
          : _borderSide(context, value.start!, scope),
      end: value.end == null
          ? BorderSide.none
          : _borderSide(context, value.end!, scope),
      bottom: value.bottom == null
          ? BorderSide.none
          : _borderSide(context, value.bottom!, scope),
    ),
  _ => null,
};

typedef PortablePresentationScopeBuilder = PortablePresentationScope Function({
  required PortablePresentationHost host,
  required PortablePresentationDocument document,
  required Map<types.ExpressionBindingId, PortableExpressionBinding> bindings,
  required void Function(binding.BindingRef, types.DataValue) setBinding,
  required ValueChanged<String> reportStatus,
});

final class PortablePresentationRenderer extends StatefulWidget {
  const PortablePresentationRenderer({
    required this.host,
    this.scopeBuilder,
    this.onStatus,
    this.compactDiagnostics = const [],
    super.key,
  });

  final PortablePresentationHost host;
  final PortablePresentationScopeBuilder? scopeBuilder;
  final ValueChanged<String>? onStatus;
  final List<diagnostic.DiagnosticTemplate> compactDiagnostics;

  @override
  State<PortablePresentationRenderer> createState() =>
      _PortablePresentationRendererState();
}

final class _PortablePresentationRendererState
    extends State<PortablePresentationRenderer> {
  String? _status;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.host,
    builder: (context, _) {
      final document = widget.host.document;
      final bindings = {
        for (final entry in document.bindings.entries)
          entry.key: PortableExpressionBinding(
            value: entry.value.value,
            location: entry.value.location,
          ),
      };
      final scope =
          widget.scopeBuilder?.call(
            host: widget.host,
            document: document,
            bindings: bindings,
            setBinding: _setBinding,
            reportStatus: _reportStatus,
          ) ??
          _defaultScope(document, bindings);
      final root = PortablePresentationNodeRenderer(
        node: document.root,
        scope: scope,
        fillAvailableSpace:
            document.role == catalog_wire.PresentationRole.editor,
      );
      if (document.role == catalog_wire.PresentationRole.editor) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_status case final status?)
              Semantics(
                liveRegion: true,
                child: Text(
                  status,
                  style: context.theme.textTheme.bodyMedium?.copyWith(
                    color: context.colors.danger,
                  ),
                ),
              ),
            Expanded(child: root),
          ],
        );
      }
      if (document.role != catalog_wire.PresentationRole.inspector) {
        final diagnostics = [
          ...widget.compactDiagnostics,
          if (_status case final status?)
            diagnostic.DiagnosticTemplate(
              code: "presentation_status",
              message: status,
              severity: diagnostic.DiagnosticSeverity.error,
              targets: const [],
            ),
        ];
        if (diagnostics.isEmpty) return root;
        return _CompactPresentationNotice(
          diagnostics: diagnostics,
          child: root,
        );
      }
      if (_status == null) return root;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_status case final status?)
            Semantics(
              liveRegion: true,
              child: Text(
                status,
                style: context.theme.textTheme.bodyMedium?.copyWith(
                  color: context.colors.danger,
                ),
              ),
            ),
          root,
        ],
      );
    },
  );

  PortablePresentationScope _defaultScope(
    PortablePresentationDocument document,
    Map<types.ExpressionBindingId, PortableExpressionBinding> bindings,
  ) {
    final capabilities = widget.host.capabilities;
    return PortablePresentationScope(
      bindings: bindings,
      budget: document.budget,
      setBinding: _setBinding,
      enabled: widget.host.enabled,
      readOnly: widget.host.readOnly,
      invokeCommand: capabilities.invokeCommand,
      watchSearch: capabilities.watchSearch,
      reload: capabilities.reload,
      commit: capabilities.commit,
      openResource: capabilities.openResource,
      prepareCreation: capabilities.prepareCreation,
      reportStatus: _reportStatus,
      catalog: document.catalog,
      role: document.role,
      material: document.material,
      activePresentations: document.activePresentations,
      slots: document.slots,
      host: widget.host,
    );
  }

  void _setBinding(binding.BindingRef reference, types.DataValue value) {
    unawaited(_write(reference, value));
  }

  Future<void> _write(
    binding.BindingRef reference,
    types.DataValue value,
  ) async {
    final result = await widget.host.write(reference, value);
    if (!mounted) return;
    switch (result) {
      case PortablePresentationWriteApplied():
        if (_status != null) setState(() => _status = null);
      case PortablePresentationWriteRejected(:final message):
        _reportStatus(message);
    }
  }

  void _reportStatus(String message) {
    widget.onStatus?.call(message);
    if (!mounted || widget.onStatus != null) return;
    setState(() => _status = message);
  }
}

final class _CompactPresentationNotice extends StatefulWidget {
  const _CompactPresentationNotice({
    required this.diagnostics,
    required this.child,
  });

  final List<diagnostic.DiagnosticTemplate> diagnostics;
  final Widget child;

  @override
  State<_CompactPresentationNotice> createState() =>
      _CompactPresentationNoticeState();
}

final class _CompactPresentationNoticeState
    extends State<_CompactPresentationNotice> {
  final _tooltipKey = GlobalKey<TooltipState>();

  @override
  Widget build(BuildContext context) {
    final message = widget.diagnostics
        .map((diagnostic) => diagnostic.message)
        .join("\n");
    final severity = _strongestSeverity(widget.diagnostics);
    final label = switch (severity.kind) {
      diagnostic.DiagnosticSeverity_kind.informationConst =>
        "Presentation information",
      diagnostic.DiagnosticSeverity_kind.warningConst => "Presentation warning",
      diagnostic.DiagnosticSeverity_kind.errorConst => "Presentation error",
      diagnostic.DiagnosticSeverity_kind.unknown => "Presentation problem",
    };
    final color = switch (severity.kind) {
      diagnostic.DiagnosticSeverity_kind.informationConst =>
        context.colors.info,
      diagnostic.DiagnosticSeverity_kind.warningConst => context.colors.warning,
      diagnostic.DiagnosticSeverity_kind.errorConst ||
      diagnostic.DiagnosticSeverity_kind.unknown => context.colors.danger,
    };
    final icon = switch (severity.kind) {
      diagnostic.DiagnosticSeverity_kind.informationConst =>
        Icons.info_outline_rounded,
      diagnostic.DiagnosticSeverity_kind.warningConst =>
        Icons.warning_amber_rounded,
      diagnostic.DiagnosticSeverity_kind.errorConst ||
      diagnostic.DiagnosticSeverity_kind.unknown => Icons.error_outline_rounded,
    };
    return Tooltip(
      key: _tooltipKey,
      message: message,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          widget.child,
          PositionedDirectional(
            top: 0,
            end: 0,
            child: IgnorePointer(
              child: Focus(
                debugLabel: label,
                onFocusChange: (focused) {
                  if (!focused) {
                    Tooltip.dismissAllToolTips();
                    return;
                  }
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      _tooltipKey.currentState?.ensureTooltipVisible();
                    }
                  });
                },
                child: Semantics(
                  label: label,
                  tooltip: message,
                  child: ExcludeSemantics(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: context.theme.colorScheme.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: color),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Icon(icon, size: 14, color: color),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

diagnostic.DiagnosticSeverity _strongestSeverity(
  Iterable<diagnostic.DiagnosticTemplate> diagnostics,
) => diagnostics.map((diagnostic) => diagnostic.severity).reduce((
  current,
  next,
) {
  final currentRank = _diagnosticSeverityRank(current);
  final nextRank = _diagnosticSeverityRank(next);
  return nextRank > currentRank ? next : current;
});

int _diagnosticSeverityRank(diagnostic.DiagnosticSeverity severity) =>
    switch (severity.kind) {
      diagnostic.DiagnosticSeverity_kind.informationConst => 0,
      diagnostic.DiagnosticSeverity_kind.warningConst => 1,
      diagnostic.DiagnosticSeverity_kind.errorConst ||
      diagnostic.DiagnosticSeverity_kind.unknown => 2,
    };
