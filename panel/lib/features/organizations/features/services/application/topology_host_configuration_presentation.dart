part of "services.dart";

PresentationNode _hostConfigurationSection({
  required Color color,
  required bool canHostRealm,
  required Map<String, List<String>> realmTargets,
  required Map<String, List<String>> engineTargets,
  required List<TopologyRealm> realms,
}) => _dashboardSection(
  id: "serviceHost.configuration",
  title: "Configuration",
  color: color,
  children: [
    if (canHostRealm)
      _workloadMode(
        field: "realm",
        label: "Host a Realm",
        title: "REALM HOSTING",
        color: realmServiceRoleColor,
        disabled: _realmDisabled,
        enabled: _realmHosted,
        scopeId: const BindingId(30),
        fields: [
          _targetChoice(const BindingId(30), realmTargets, "Realm target"),
        ],
      ),
    _workloadMode(
      field: "engine",
      label: "Run an execution engine",
      title: "EXECUTION ENGINE",
      color: engineServiceRoleColor,
      disabled: _engineDisabled,
      enabled: _engineEnabled,
      scopeId: const BindingId(31),
      fields: [
        _targetChoice(const BindingId(31), engineTargets, "Engine target"),
        PresentationNode(
          id: "engine.realm.availability",
          element: PolymorphicMatchElement(
            binding: BindingReference(
              bindingId: const BindingId(1),
              path: DataPath.root.field("realm"),
            ),
            scopeBindingId: const BindingId(33),
            cases: [
              PolymorphicMatchCase(
                type: _realmDisabled,
                child: _engineRealmChoice(realms),
              ),
              PolymorphicMatchCase(
                type: _realmHosted,
                child: PresentationNode(
                  id: "engine.realm.hostedMatch",
                  element: ConditionalElement(
                    condition: _equalTargets(
                      _draftTargetExpression(const BindingId(31)),
                      _draftTargetExpression(const BindingId(33)),
                    ),
                    whenTrue: const PresentationNode(
                      id: "engine.realm.inferred",
                      element: ColumnElement(children: []),
                    ),
                    whenFalse: _engineRealmChoice(realms),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
    const PresentationNode(
      id: "host.configuration.commit",
      element: CommitControlsElement(
        binding: BindingReference(bindingId: BindingId(1)),
      ),
    ),
  ],
);

PresentationNode _workloadMode({
  required String field,
  required String label,
  required String title,
  required Color color,
  required ResolvedTypeRef disabled,
  required ResolvedTypeRef enabled,
  required BindingId scopeId,
  required List<PresentationNode> fields,
}) {
  final binding = BindingReference(
    bindingId: const BindingId(1),
    path: DataPath.root.field(field),
  );
  return _dashboardCard(
    id: "serviceHost.configuration.$field",
    label: title,
    color: color,
    children: [
      PresentationNode(
        id: "host.configuration.$field",
        element: PolymorphicMatchElement(
          binding: binding,
          scopeBindingId: scopeId,
          cases: [
            for (final currentType in [disabled, enabled])
              PolymorphicMatchCase(
                type: currentType,
                child: PresentationNode(
                  id: "$field.${currentType == enabled ? "enabled" : "disabled"}",
                  header: PresentationHeader(
                    binding: binding,
                    title: label.asStringLiteral.asHeaderTitle,
                    items: [
                      HeaderBooleanToggleItem(
                        id: booleanToggleHeaderItemId,
                        label: label.asStringLiteral,
                        checked: (currentType == enabled).asBooleanLiteral,
                        placement: HeaderActionPlacement.beforeTitle,
                        action: LocalEditorAction(
                          ReplaceConcreteTypeAction(
                            target: binding,
                            concreteType: currentType == enabled
                                ? disabled
                                : enabled,
                          ),
                        ),
                      ),
                    ],
                  ),
                  element: ColumnElement(
                    spacing: 12,
                    children:
                        (currentType == enabled
                                ? fields
                                : const <PresentationNode>[])
                            .map(PresentationAxisChild.fixed)
                            .toList(),
                  ),
                ),
              ),
          ],
        ),
      ),
    ],
  );
}

PresentationNode _targetChoice(
  BindingId scope,
  Map<String, List<String>> targets,
  String label,
) => PresentationNode(
  id: "target.${scope.value}",
  element: SelectInputElement(
    control: BoundControl(
      binding: BindingReference(
        bindingId: scope,
        path: DataPath.root.field("target"),
      ),
      label: label.asStringLiteral,
    ),
    options: [
      for (final entry in targets.entries)
        for (final version in entry.value)
          SelectOption(
            id: _encodeTarget(entry.key, version),
            label: _targetLabel(
              TopologyEngineTarget(
                engineId: entry.key,
                versionConstraint: version,
              ),
            ).asStringLiteral,
            value: _encodeTarget(entry.key, version).asStringLiteral,
          ),
    ],
  ),
);

TypedExpression _draftTargetExpression(BindingId binding) => TypedExpression(
  resultType: const StringType(),
  expression: BindingExpression(
    BindingReference(bindingId: binding, path: DataPath.root.field("target")),
  ),
);

TypedExpression _equalTargets(TypedExpression left, TypedExpression right) =>
    TypedExpression(
      resultType: const BooleanType(),
      expression: BooleanExpression(
        operator: BooleanOperator.and,
        operands: [
          TypedExpression(
            resultType: const BooleanType(),
            expression: ComparisonExpression(
              operator: ComparisonOperator.notEqual,
              left: left,
              right: "".asStringLiteral,
            ),
          ),
          TypedExpression(
            resultType: const BooleanType(),
            expression: ComparisonExpression(
              operator: ComparisonOperator.equal,
              left: left,
              right: right,
            ),
          ),
        ],
      ),
    );

PresentationNode _engineRealmChoice(List<TopologyRealm> realms) {
  final groups = <String, List<TopologyRealm>>{};
  for (final realm in realms) {
    final target = _encodeTarget(
      realm.targetEngine.engineId,
      realm.targetEngine.versionConstraint,
    );
    groups.putIfAbsent(target, () => []).add(realm);
  }
  var choice = _realmOptions(const [], "none");
  for (final entry in groups.entries) {
    choice = PresentationNode(
      id: "engine.realm.target.${entry.key}",
      element: ConditionalElement(
        condition: _equalTargets(
          _draftTargetExpression(const BindingId(31)),
          entry.key.asStringLiteral,
        ),
        whenTrue: _realmOptions(entry.value, entry.key),
        whenFalse: choice,
      ),
    );
  }
  return choice;
}

PresentationNode _realmOptions(List<TopologyRealm> realms, String target) =>
    PresentationNode(
      id: "engine.realm.$target",
      element: SelectInputElement(
        control: BoundControl(
          binding: BindingReference(
            bindingId: const BindingId(31),
            path: DataPath.root.field("realm"),
          ),
          label: "Assigned Realm".asStringLiteral,
        ),
        options: [
          for (final realm in realms)
            SelectOption(
              id: realm.realmId.id,
              label: realm.ownerHost.name.asStringLiteral,
              value: realm.realmId.id.asStringLiteral,
            ),
        ],
      ),
    );
