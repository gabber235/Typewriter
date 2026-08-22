part of "services.dart";

final _realmInstanceInspectorPresentation = _runtimeInspectorPresentation(
  id: _realmInstanceInspectorPresentationId,
  target: _realmInstanceInspectorTypeRef,
  rootId: "realmInstance.inspector",
  color: realmServiceRoleColor,
  placementFields: const [
    (_RuntimeInspectorFields.ownerHost, "Owner host"),
    (_RuntimeInspectorFields.target, "Target"),
  ],
);

final _engineInstanceInspectorPresentation = _runtimeInspectorPresentation(
  id: _engineInstanceInspectorPresentationId,
  target: _engineInstanceInspectorTypeRef,
  rootId: "engineInstance.inspector",
  color: engineServiceRoleColor,
  placementFields: const [
    (_RuntimeInspectorFields.ownerHost, "Owner host"),
    (_RuntimeInspectorFields.assignedRealm, "Assigned Realm"),
    (_RuntimeInspectorFields.target, "Target"),
  ],
);

PresentationDefinition _runtimeInspectorPresentation({
  required PresentationId id,
  required ResolvedTypeRef target,
  required String rootId,
  required Color color,
  required List<(String, String)> placementFields,
}) {
  final status = _fieldExpression(
    _RuntimeInspectorFields.runtimeStatus,
    const StringType(),
  );
  final message = _fieldExpression(
    _RuntimeInspectorFields.runtimeMessage,
    const StringType(),
  );
  return PresentationDefinition(
    id: id,
    target: NamedType(target),
    root: PresentationNode(
      id: rootId,
      properties: const PresentationProperties(readOnly: true),
      element: ColumnElement(
        spacing: _dashboardSectionSpacing,
        crossAxisAlignment: PresentationCrossAxisAlignment.start,
        children: [
          _dashboardSection(
            id: "$rootId.overview",
            title: "Runtime",
            description: "Current deployment health",
            color: color,
            children: [
              _dashboardCard(
                id: "$rootId.health",
                label: "STATUS",
                color: color,
                children: [
                  _statusElement(
                    id: "$rootId.status",
                    value: status,
                    tones: const {
                      "Active": StatusTone.active,
                      "Staging": StatusTone.inProgress,
                      "Quiescing": StatusTone.paused,
                      "Drifted": StatusTone.warning,
                      "Rolled back": StatusTone.warning,
                      "Failed": StatusTone.danger,
                      "Absent": StatusTone.inactive,
                    },
                  ),
                  _dashboardGrid(
                    id: "$rootId.deploymentFacts",
                    children: [
                      _runtimeField(
                        rootId,
                        _RuntimeInspectorFields.manifestRevision,
                        "Manifest",
                      ),
                      _runtimeField(
                        rootId,
                        _RuntimeInspectorFields.artifactVersion,
                        "Artifact",
                      ),
                    ],
                  ),
                  _readOnlyField(
                    id: "$rootId.${_RuntimeInspectorFields.updatedAt}",
                    label: "Updated",
                    content: _dateTimeContent(
                      _fieldExpression(
                        _RuntimeInspectorFields.updatedAt,
                        const TimestampType(),
                      ),
                    ),
                  ),
                  _whenValueIsPresent(
                    id: "$rootId.message.visible",
                    value: message,
                    child: _runtimeField(
                      rootId,
                      _RuntimeInspectorFields.runtimeMessage,
                      "Message",
                      color: Colors.redAccent.asColorLiteral,
                    ),
                  ),
                ],
              ),
            ],
          ),
          _dashboardSection(
            id: "$rootId.placement",
            title: "Placement",
            description: "Where this runtime executes",
            color: color,
            children: [
              _dashboardCard(
                id: "$rootId.placement.card",
                label: "ASSIGNMENT",
                color: color,
                children: [
                  for (final (field, label) in placementFields)
                    _runtimeField(rootId, field, label),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

PresentationNode _runtimeField(
  String rootId,
  String field,
  String label, {
  TypedExpression? color,
}) {
  final value = _fieldExpression(field, const StringType());
  return _readOnlyField(
    id: "$rootId.$field",
    label: label,
    value: value,
    color: color,
  );
}
