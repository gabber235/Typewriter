import "package:flutter/material.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "host_execution_target_fields.dart";

class HostExecutionInspector extends StatefulWidget {
  const HostExecutionInspector({
    required this.host,
    required this.topology,
    required this.onSave,
    super.key,
  });

  final skir.ServiceHost host;
  final OrganizationTopology topology;
  final Future<void> Function(skir.HostExecutionConfiguration execution) onSave;

  @override
  State<HostExecutionInspector> createState() => _HostExecutionInspectorState();
}

class _HostExecutionInspectorState extends State<HostExecutionInspector> {
  late bool _realmEnabled;
  late bool _engineEnabled;
  late bool _useHostedRealm;
  late String _realmEngineId;
  late String _engineId;
  late int _realmMajor;
  late int _engineMajor;
  skir.RecordId? _existingRealmId;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  @override
  void didUpdateWidget(covariant HostExecutionInspector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.host.hostId != widget.host.hostId ||
        oldWidget.host.revision != widget.host.revision) {
      _reset();
    }
  }

  void _reset() {
    final realm = widget.topology.realmOwnedBy(widget.host.hostId);
    final engine = widget.topology.engineOwnedBy(widget.host.hostId);
    final realmTarget = realm?.targetEngine ?? _defaultRealmTarget;
    final engineTarget = engine?.target ?? _defaultEngineTarget;
    _realmEnabled = realm != null;
    _engineEnabled = engine != null;
    _realmEngineId = realmTarget.engineId;
    _realmMajor = realmTarget.majorVersion;
    _engineId = engineTarget.engineId;
    _engineMajor = engineTarget.majorVersion;
    _useHostedRealm = realm != null && engine?.realmId == realm.realmId;
    _existingRealmId = _useHostedRealm ? null : engine?.realmId;
    _saving = false;
    _error = null;
  }

  skir.EngineTarget get _defaultRealmTarget {
    final supported = _realmEngineOptions.first;
    return skir.EngineTarget(
      engineId: supported.engineId,
      majorVersion: supported.supportedMajorVersions.first,
    );
  }

  skir.EngineTarget get _defaultEngineTarget {
    final supported = widget.host.supportedEngines.firstOrNull;
    return skir.EngineTarget(
      engineId: supported?.engineId ?? "paper",
      majorVersion: supported?.supportedMajorVersions.firstOrNull ?? 1,
    );
  }

  List<skir.SupportedEngine> get _realmEngineOptions {
    final byId = <String, skir.SupportedEngine>{};
    for (final host in widget.topology.hosts) {
      for (final engine in host.supportedEngines) {
        byId[engine.engineId] = engine;
      }
    }
    byId.putIfAbsent(
      "paper",
      () =>
          skir.SupportedEngine(engineId: "paper", supportedMajorVersions: [1]),
    );
    return byId.values.toList()
      ..sort((a, b) => a.engineId.compareTo(b.engineId));
  }

  List<int> _versions(String engineId, Iterable<skir.SupportedEngine> engines) {
    for (final engine in engines) {
      if (engine.engineId == engineId) {
        return engine.supportedMajorVersions.toList();
      }
    }
    return [1];
  }

  Future<void> _save() async {
    if (_engineEnabled && !_useHostedRealm && _existingRealmId == null) {
      setState(
        () => _error = "Select the existing Realm this engine should use",
      );
      return;
    }
    final hadRealm = widget.topology.realmOwnedBy(widget.host.hostId) != null;
    final hadEngine = widget.topology.engineOwnedBy(widget.host.hostId) != null;
    if ((hadRealm && !_realmEnabled) || (hadEngine && !_engineEnabled)) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Remove hosted runtime?"),
          content: const Text(
            "Saving removes the disabled runtime after the backend validates its dependencies.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Remove and save"),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(
        skir.HostExecutionConfiguration(
          realm: _realmEnabled
              ? skir.HostedRealmConfiguration(
                  targetEngine: skir.EngineTarget(
                    engineId: _realmEngineId,
                    majorVersion: _realmMajor,
                  ),
                )
              : null,
          engine: _engineEnabled
              ? skir.HostedEngineConfiguration(
                  target: skir.EngineTarget(
                    engineId: _engineId,
                    majorVersion: _engineMajor,
                  ),
                  realm: _useHostedRealm
                      ? skir.EngineRealmSelection.hostedRealm
                      : skir.EngineRealmSelection.createExistingRealm(
                          realmId: _existingRealmId!,
                        ),
                )
              : null,
        ),
      );
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPaper = widget.host.entrypoint == skir.HostEntrypoint.paper;
    final realmEngines = _realmEngineOptions;
    final engineOptions = widget.host.supportedEngines.toList();
    return SingleChildScrollView(
      padding: EdgeInsets.all(context.spacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Host execution",
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          SizedBox(height: context.spacing.space1),
          Text(
            "${isPaper ? "Paper" : "Standalone"} host · ${widget.host.hostId.id}",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: context.spacing.space4),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text("Host a Realm"),
            subtitle: const Text(
              "Stores content and includes the panel engine",
            ),
            value: _realmEnabled,
            onChanged: widget.host.canHostRealm
                ? (value) => setState(() {
                    _realmEnabled = value;
                    if (!value) _useHostedRealm = false;
                  })
                : null,
          ),
          if (_realmEnabled)
            _EngineTargetFields(
              label: "Realm target",
              engines: realmEngines,
              engineId: _realmEngineId,
              major: _realmMajor,
              onEngineChanged: (value) => setState(() {
                _realmEngineId = value;
                _realmMajor = _versions(value, realmEngines).first;
              }),
              onMajorChanged: (value) => setState(() => _realmMajor = value),
            ),
          const Divider(height: 32),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text("Run an execution engine"),
            subtitle: Text(
              isPaper
                  ? "Executes assigned Realm content on Paper"
                  : "Standalone hosts cannot execute Paper content",
            ),
            value: _engineEnabled,
            onChanged: isPaper && engineOptions.isNotEmpty
                ? (value) => setState(() => _engineEnabled = value)
                : null,
          ),
          if (_engineEnabled) ...[
            _EngineTargetFields(
              label: "Engine target",
              engines: engineOptions,
              engineId: _engineId,
              major: _engineMajor,
              onEngineChanged: (value) => setState(() {
                _engineId = value;
                _engineMajor = _versions(value, engineOptions).first;
              }),
              onMajorChanged: (value) => setState(() => _engineMajor = value),
            ),
            SizedBox(height: context.spacing.space3),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text("Hosted Realm")),
                ButtonSegment(value: false, label: Text("Existing Realm")),
              ],
              selected: {_useHostedRealm},
              onSelectionChanged: (selection) =>
                  setState(() => _useHostedRealm = selection.single),
            ),
            if (!_useHostedRealm) ...[
              SizedBox(height: context.spacing.space3),
              DropdownButtonFormField<skir.RecordId>(
                initialValue: _existingRealmId,
                decoration: const InputDecoration(labelText: "Assigned Realm"),
                items: [
                  for (final realm in widget.topology.realmInstances)
                    DropdownMenuItem(
                      value: realm.realmId,
                      child: Text(realm.realmId.id),
                    ),
                ],
                onChanged: (value) => setState(() => _existingRealmId = value),
              ),
            ],
          ],
          if (_error != null) SizedBox(height: context.spacing.space3),
          if (_error != null) _ErrorText(_error!),
          SizedBox(height: context.spacing.space4),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_saving ? "Saving" : "Save configuration"),
            ),
          ),
        ],
      ),
    );
  }
}
