part of "services.dart";

PresentationDefinition _hostInspectorPresentation({
  required Map<String, List<String>> realmTargets,
  required Map<String, List<String>> engineTargets,
  required List<TopologyRealm> realms,
  required bool canHostRealm,
  required Color color,
}) => PresentationDefinition(
  id: _hostInspectorPresentationId,
  target: NamedType(_hostInspectorTypeRef),
  root: PresentationNode(
    id: "serviceHost.inspector",
    element: ColumnElement(
      spacing: _dashboardSectionSpacing,
      crossAxisAlignment: PresentationCrossAxisAlignment.start,
      children: [
        _hostServiceSection(color),
        _hostDetailsSection(color),
        _hostConfigurationSection(
          color: color,
          canHostRealm: canHostRealm,
          realmTargets: realmTargets,
          engineTargets: engineTargets,
          realms: realms,
        ),
      ],
    ),
  ),
);

PresentationNode _hostServiceSection(Color color) {
  final state = _hostExpression(
    _hostPath(_HostInspectorFields.service, _HostInspectorFields.state),
    const StringType(),
  );
  return _dashboardSection(
    id: "serviceHost.service",
    title: "Service",
    description: "Identity and connection",
    color: color,
    children: [
      PresentationNode(
        id: "serviceHost.service.name",
        element: TextInputElement(
          control: _hostControl(
            _hostPath(_HostInspectorFields.service, _HostInspectorFields.name),
            "Name",
          ),
          multiline: false,
          inputFormatters: identifierInputFormats,
        ),
      ),
      _dashboardCard(
        id: "serviceHost.service.overview",
        label: "CONNECTION",
        color: color,
        children: [
          _statusElement(
            id: "serviceHost.service.status",
            value: state,
            tones: const {
              "Connected": StatusTone.online,
              "Offline": StatusTone.offline,
            },
          ),
          _dashboardGrid(
            id: "serviceHost.service.facts",
            children: [
              _hostReadOnlyField(
                id: "serviceHost.service.version",
                section: _HostInspectorFields.service,
                field: _HostInspectorFields.version,
                label: "Version",
              ),
              _readOnlyField(
                id: "serviceHost.service.lastSeen",
                label: "Last seen",
                content: _optionalRelativeTimeContent(
                  binding: BindingReference(
                    bindingId: const BindingId(0),
                    path: _hostPath(
                      _HostInspectorFields.service,
                      _HostInspectorFields.lastSeen,
                    ),
                  ),
                  scopeBindingId: const BindingId(72),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

PresentationNode _hostDetailsSection(Color color) {
  final state = _hostExpression(
    _hostPath(_HostInspectorFields.host, _HostInspectorFields.state),
    const StringType(),
  );
  final message = _hostExpression(
    _hostPath(_HostInspectorFields.host, _HostInspectorFields.message),
    const StringType(),
  );
  return _dashboardSection(
    id: "serviceHost.host",
    title: "Host",
    description: "Capabilities and runtime health",
    color: color,
    children: [
      _dashboardCard(
        id: "serviceHost.host.capabilities",
        label: "CAPABILITIES",
        color: color,
        children: [
          _dashboardGrid(
            id: "serviceHost.host.capabilityFacts",
            children: [
              _hostReadOnlyField(
                id: "serviceHost.host.entrypoint",
                section: _HostInspectorFields.host,
                field: _HostInspectorFields.entrypoint,
                label: "Entry point",
              ),
              _hostBooleanField(
                id: "serviceHost.host.canHostRealm",
                field: _HostInspectorFields.canHostRealm,
                label: "Realm hosting",
              ),
            ],
          ),
          _hostEngineList(),
        ],
      ),
      _dashboardCard(
        id: "serviceHost.host.health",
        label: "RUNTIME HEALTH",
        color: color,
        children: [
          _statusElement(
            id: "serviceHost.host.status",
            value: state,
            tones: const {
              "Active": StatusTone.active,
              "Reconciling": StatusTone.inProgress,
              "Drifted": StatusTone.warning,
              "Failed": StatusTone.danger,
              "Offline": StatusTone.offline,
            },
          ),
          _readOnlyField(
            id: "serviceHost.host.updatedAt",
            label: "Updated",
            content: _dateTimeContent(
              _hostExpression(
                _hostPath(
                  _HostInspectorFields.host,
                  _HostInspectorFields.updatedAt,
                ),
                const TimestampType(),
              ),
            ),
          ),
          _whenValueIsPresent(
            id: "serviceHost.host.message.visible",
            value: message,
            child: _hostReadOnlyField(
              id: "serviceHost.host.message",
              section: _HostInspectorFields.host,
              field: _HostInspectorFields.message,
              label: "Message",
              color: Colors.redAccent.asColorLiteral,
            ),
          ),
        ],
      ),
    ],
  );
}

PresentationNode _hostReadOnlyField({
  required String id,
  required String section,
  required String field,
  required String label,
  TypedExpression? color,
}) {
  final value = _hostExpression(_hostPath(section, field), const StringType());
  return _readOnlyField(id: id, label: label, value: value, color: color);
}

PresentationNode _hostBooleanField({
  required String id,
  required String field,
  required String label,
}) => PresentationNode(
  id: id,
  properties: const PresentationProperties(readOnly: true),
  header: PresentationHeader(
    title: label.asStringLiteral.asHeaderTitle,
    headerPadding: const PresentationInsets.all(0),
    contentPadding: const PresentationInsets.only(top: 4),
  ),
  element: StatusElement(
    value: _hostExpression(
      _hostPath(_HostInspectorFields.host, field),
      const BooleanType(),
    ),
    cases: [
      StatusCase(
        match: const BooleanValue(true),
        appearance: StatusAppearance(
          tone: StatusTone.active,
          label: "Available".asStringLiteral,
        ),
      ),
      StatusCase(
        match: const BooleanValue(false),
        appearance: StatusAppearance(
          tone: StatusTone.inactive,
          label: "Unavailable".asStringLiteral,
        ),
      ),
    ],
  ),
);

PresentationNode _hostEngineList() => PresentationNode(
  id: "serviceHost.host.supportedEngines",
  properties: const PresentationProperties(readOnly: true),
  header: PresentationHeader(
    title: "Supported engines".asStringLiteral.asHeaderTitle,
    headerPadding: const PresentationInsets.all(0),
    contentPadding: const PresentationInsets.only(top: 4),
  ),
  element: RepeatedElement(
    source: _hostExpression(
      _hostPath(
        _HostInspectorFields.host,
        _HostInspectorFields.supportedEngines,
      ),
      _stringListType,
    ),
    itemBindingId: const BindingId(71),
    presentation: SequencePresentation(
      layout: const PresentationSequenceLayout.children(
        PresentationChildrenLayout.wrap(spacing: 6, runSpacing: 6),
      ),
      item: PresentationNode(
        id: "serviceHost.host.supportedEngines.item",
        element: ChipElement(
          label: const TypedExpression(
            resultType: StringType(),
            expression: BindingExpression(
              BindingReference(bindingId: BindingId(71)),
            ),
          ),
          color: engineServiceRoleColor.asColorLiteral,
        ),
      ),
    ),
  ),
);
