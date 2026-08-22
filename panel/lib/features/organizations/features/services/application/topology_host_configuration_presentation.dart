part of "services.dart";

PresentationNode _hostConfigurationSection({
  required Color color,
  required bool canHostRealm,
  required Map<String, List<int>> realmTargets,
  required Map<String, List<int>> engineTargets,
  required List<TopologyRealm> realms,
}) => _dashboardSection(
  id: "serviceHost.configuration",
  title: "Configuration",
  description: "Workloads managed by this host",
  color: color,
  children: [
    if (canHostRealm) _realmConfigurationCard(targets: realmTargets),
    _engineConfigurationCard(
      targets: engineTargets,
      realms: realms,
      canHostRealm: canHostRealm,
    ),
  ],
);

PresentationNode _realmConfigurationCard({
  required Map<String, List<int>> targets,
}) => _dashboardCard(
  id: "serviceHost.configuration.realm",
  label: "REALM HOSTING",
  color: realmServiceRoleColor,
  children: [
    PresentationNode(
      id: "serviceHost.realmEnabled",
      element: ToggleInputElement(
        _configurationControl(
          _HostInspectorFields.realmEnabled,
          "Host a Realm",
        ),
      ),
    ),
    PresentationNode(
      id: "serviceHost.realmConfiguration",
      element: ConditionalElement(
        condition: _configurationExpression(
          _HostInspectorFields.realmEnabled,
          const BooleanType(),
        ),
        whenTrue: _engineTargetSelect(
          id: "serviceHost.realmTarget",
          field: _HostInspectorFields.realmTarget,
          label: "Realm target",
          targets: targets,
        ),
      ),
    ),
  ],
);

PresentationNode _engineConfigurationCard({
  required Map<String, List<int>> targets,
  required List<TopologyRealm> realms,
  required bool canHostRealm,
}) => _dashboardCard(
  id: "serviceHost.configuration.engine",
  label: "EXECUTION ENGINE",
  color: engineServiceRoleColor,
  children: [
    PresentationNode(
      id: "serviceHost.engineEnabled",
      element: ToggleInputElement(
        _configurationControl(
          _HostInspectorFields.engineEnabled,
          "Run an execution engine",
        ),
      ),
    ),
    PresentationNode(
      id: "serviceHost.engineConfiguration",
      element: ConditionalElement(
        condition: _configurationExpression(
          _HostInspectorFields.engineEnabled,
          const BooleanType(),
        ),
        whenTrue: PresentationNode(
          id: "serviceHost.engineConfiguration.fields",
          element: ColumnElement(
            spacing: 12,
            crossAxisAlignment: PresentationCrossAxisAlignment.start,
            children: [
              _engineTargetSelect(
                id: "serviceHost.engineTarget",
                field: _HostInspectorFields.engineTarget,
                label: "Engine target",
                targets: targets,
              ),
              _realmAssignment(canHostRealm: canHostRealm, realms: realms),
            ],
          ),
        ),
      ),
    ),
  ],
);

PresentationNode _realmAssignment({
  required bool canHostRealm,
  required List<TopologyRealm> realms,
}) => PresentationNode(
  id: "serviceHost.realmAssignment",
  element: canHostRealm
      ? ConditionalElement(
          condition: _configurationExpression(
            _HostInspectorFields.realmEnabled,
            const BooleanType(),
          ).compare(ComparisonOperator.equal, false.asBooleanLiteral),
          whenTrue: _realmAssignmentSelect(
            id: "serviceHost.realmAssignment.remote",
            realms: realms,
          ),
        )
      : _realmAssignmentSelect(
          id: "serviceHost.realmAssignment.remote",
          realms: realms,
        ).element,
);

PresentationNode _engineTargetSelect({
  required String id,
  required String field,
  required String label,
  required Map<String, List<int>> targets,
}) => PresentationNode(
  id: id,
  element: SelectInputElement(
    control: _configurationControl(field, label),
    options: [
      for (final entry in targets.entries)
        for (final version in entry.value)
          SelectOption(
            id: _encodeTarget(entry.key, version),
            label: "${entry.key.formatted} $version.x".asStringLiteral,
            value: _encodeTarget(entry.key, version).asStringLiteral,
          ),
    ],
  ),
);

PresentationNode _realmAssignmentSelect({
  required String id,
  required List<TopologyRealm> realms,
}) => PresentationNode(
  id: id,
  element: SelectInputElement(
    control: _configurationControl(
      _HostInspectorFields.realmAssignment,
      "Assigned Realm",
    ),
    options: [
      for (final realm in realms)
        SelectOption(
          id: realm.realmId.id,
          label: realm.ownerHost.name.formatted.asStringLiteral,
          value: realm.realmId.id.asStringLiteral,
        ),
    ],
  ),
);
