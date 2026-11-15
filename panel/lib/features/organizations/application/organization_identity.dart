import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Renaming an organization through the shared value editing workspace.
///
/// The name saves on its own after editing, as a service name does. An
/// organization has no revision, so a rename never conflicts: the last one
/// saved wins. A refusal, such as a name another organization holds, shows
/// under the field and keeps the typed name.
ValueEditingRegistration organizationIdentityTarget({
  required skir.Organization organization,
  required Organizations organizations,
  required Future<List<skir.Organization>> Function() current,
  LocalWork? work,
}) => ValueEditingRegistration(
  targetId: organization.organizationId,
  label: "${organization.name}: name",
  persistence: OrganizationIdentityPersistence(
    organizations,
    current,
    organization.organizationId,
  ),
  snapshot: organization.identitySnapshot,
  observe: work == null
      ? null
      : (workspace) => work.observe(organizationsProvider, (next) {
          if (next.mapUnready<ValueEditDocument>() case final unready?) {
            return workspace.observe(unready);
          }
          final current = next.requireValue.firstWhereOrNull(
            (value) => value.organizationId == organization.organizationId,
          );
          workspace.acceptConfirmed(
            current == null
                ? workspace.confirmed.copyWith(exists: false)
                : ValueEditDocument.fromSnapshot(
                    current.identitySnapshot,
                    identity: workspace.confirmed.identity,
                  ),
          );
        }),
);

/// The portable field that edits an organization name through [owner], with
/// its save status.
BoundPresentationHost organizationIdentityPresentationHost({
  required EditOwner owner,
}) => BoundPresentationHost(
  catalog: _organizationPortableCatalog,
  root: _organizationIdentityPresentation,
  budget: skir.EvaluationBudget(maxSteps: 256, maxCollectionItems: 16),
  bindings: [
    BoundPresentationBinding.owned(
      id: _nameBinding,
      use: skir.TypeUse.wrapScalar(skir.ScalarKind.text),
      owner: owner,
      control: owner is EditingControlOwner
          ? (owner as EditingControlOwner).bindControl()
          : null,
      read: (owner) {
        final value = owner.value(_namePath).valueOrNull;
        return value is skir.DataValue_stringValueWrapper
            ? value
            : skir.DataValue.unfilled;
      },
      write: (path, value) {
        PortablePresentationWriteResult reject(String code, String message) =>
            PortablePresentationWriteResult.rejected([
              PortablePresentationDiagnostic(
                code: code,
                message: message,
                severity: skir.DiagnosticSeverity.error,
                targets: [
                  PortableDiagnosticTarget.binding(
                    skir.BindingRef(bindingId: _nameBinding, path: path),
                  ),
                ],
              ),
            ]);
        if (path.segments.isNotEmpty) {
          return reject(
            "invalid_path",
            "The organization name path is invalid",
          );
        }
        if (value is! skir.DataValue_stringValueWrapper) {
          return reject("invalid_value", "The organization name must be text");
        }
        return owner
            .update(_namePath, value)
            .toPortablePresentationResult(
              binding: _nameBinding,
              sourcePath: _namePath,
            );
      },
    ),
  ],
);

/// The editor snapshot of an organization's name.
extension OrganizationIdentityValue on skir.Organization {
  /// The value the name editor owns.
  skir.DataValue get identityValue => skir.DataValue.createRecord(
    fields: [
      skir.FieldValue(
        name: "name",
        value: skir.DataValue.wrapStringValue(name),
      ),
    ],
  );

  EditorSnapshot get identitySnapshot => OrganizationIdentitySnapshot(this);
}

/// An organization's name as the editor reads and validates it.
final class OrganizationIdentitySnapshot extends EditorSnapshot {
  const OrganizationIdentitySnapshot(this.organization);

  final skir.Organization organization;

  @override
  EditorDocument get document => EditorDocument(
    rootType: _organizationIdentityType,
    catalog: _organizationIdentityCatalog,
    confirmedValue: organization.identityValue,
    revision: _unrevisioned,
  );

  @override
  EditorMutationResult validate(skir.ValuePath path, skir.DataValue value) {
    final text = value.authoredString;
    if (path == _namePath && text != null) {
      return text.isValidIdentifier
          ? EditorMutationResult.applied(value)
          : EditorMutationResult.invalid([
              _nameDiagnostic(organizationNameRule),
            ]);
    }
    if (path == editorRootPath) {
      final fields = value.authoredRecord?.fields.toList(growable: false);
      final name = value.editorValueAt(_namePath);
      if (fields?.length == 1 &&
          name?.authoredString?.isValidIdentifier == true) {
        return EditorMutationResult.applied(value);
      }
    }
    return EditorMutationResult.invalid([
      _nameDiagnostic("The organization name is invalid"),
    ]);
  }
}

/// Sends a rename of one organization as a batch of one and reads its
/// outcome back for the editor.
final class OrganizationIdentityPersistence extends ValueEditPersistence {
  const OrganizationIdentityPersistence(
    this.organizations,
    this.current,
    this.organization,
  );

  final Organizations organizations;

  /// The organizations the signed in user belongs to, once they arrived.
  final Future<List<skir.Organization>> Function() current;
  final skir.RecordId organization;

  @override
  EditorResourceKey get key => EditorResourceKey(
    scope: EditorResourceScope(organizationId: organization),
    identity: organization,
  );

  @override
  Set<Object> get reservations => {organization};

  @override
  Future<EditorSnapshot?> refreshSnapshot() async {
    final values = await current();
    return values
        .firstWhereOrNull((value) => value.organizationId == organization)
        ?.identitySnapshot;
  }

  @override
  PreparedCommit<TypedMutationResult> prepareValue(
    EditorSnapshot snapshot,
    EditorCommit commit,
  ) {
    final name = commit.rootValue.editorValueAt(_namePath)?.authoredString;
    if (name == null || name.trim().isEmpty) {
      throw StateError("Name must not be empty");
    }
    return organizations
        .prepareUpdate([
          skir.OrganizationUpdate(
            organizationId: organization,
            name: name,
            logoUrl: null,
          ),
        ])
        .mapResponse(
          (response) => switch (response) {
            skir.UpdateOrganizationsResponse_successWrapper(:final value) =>
              switch (value.organizations.firstWhereOrNull(
                (updated) => updated.organizationId == organization,
              )) {
                final updated? => MutationSuccess(
                  revision: _unrevisioned,
                  value: updated.identityValue,
                ),
                null => unavailableMutation(
                  "The organization could not be renamed",
                ),
              },
            skir.UpdateOrganizationsResponse_refusedErrorWrapper(
              :final value,
            ) =>
              switch (value.firstWhereOrNull(
                (refused) => refused.organizationId == organization,
              )) {
                final refused? => refused.reason.renameResult,
                null => unavailableMutation(
                  heldBackReason(
                    name: snapshot.organizationName,
                    noun: "organization",
                    done: "renamed",
                  ),
                ),
              },
            _ => unavailableMutation("The organization could not be renamed"),
          },
        );
  }
}

extension on EditorSnapshot {
  /// The name of the organization this snapshot edits.
  String? get organizationName => switch (this) {
    OrganizationIdentitySnapshot(:final organization) => organization.name,
    ResultEditorSnapshot(:final delegate) => delegate.organizationName,
    _ => null,
  };
}

extension on skir.OrganizationUpdateRefusal {
  /// What this refusal means for the rename that received it.
  TypedMutationResult get renameResult => switch (this) {
    skir.OrganizationUpdateRefusal_nameTakenErrorWrapper() ||
    skir.OrganizationUpdateRefusal_nameInvalidErrorWrapper() => MutationInvalid(
      [_nameDiagnostic(message)],
    ),
    skir.OrganizationUpdateRefusal_organizationNotFoundErrorWrapper() =>
      unavailableMutation(message, targetDeleted: true),
    _ => unavailableMutation(message),
  };
}

/// An organization has no revision; every snapshot and result carries this
/// one, so a rename never conflicts.
const _unrevisioned = 1;

final _namePath = editorRootPath.field("name");

EditorDiagnostic _nameDiagnostic(String message) => EditorDiagnostic(
  code: EditorDiagnosticCode.invalidValue,
  message: message,
  path: _namePath,
);

final _organizationIdentityDefinition = skir.TypeDefinitionId(
  typeId: skir.TypeId.createQualified(
    namespace: "panel.organization",
    name: "OrganizationIdentity",
  ),
  revision: 1,
);

final _organizationIdentityType = skir.TypeUse.wrapNamed(
  skir.NamedTypeUse(
    definition: _organizationIdentityDefinition,
    arguments: const [],
  ),
);

final _nameField = skir.EffectiveFieldTemplate(
  key: "name",
  owner: skir.FieldOwner(
    definition: _organizationIdentityDefinition,
    name: "name",
  ),
  type: skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
  rules: const [],
);

final _organizationIdentityCatalog = trustedLocalTypeCatalog(
  generation: "panel.organization.identity",
  types: [
    skir.PublishedType(
      name: "",
      extension_: "",
      searchKey: null,
      placementField: null,
      definition: skir.TypeDefinition(
        id: _organizationIdentityDefinition,
        parameters: const [],
        representation: skir.RepresentationTemplate.createRecord(
          fields: [
            skir.FieldDeclaration(
              owner: _nameField.owner,
              type: _nameField.type,
              overrides: const [],
              hasConstructorDefault: false,
            ),
          ],
          form: skir.RecordForm.concrete,
        ),
        parents: const [],
      ),
      status: skir.DeclarationStatus.ready,
      effectiveFields: [_nameField],
      ancestorTemplates: const [],
      display: defaultTypeDisplay(""),
    ),
  ],
);

final _organizationPortableCatalog = skir.EditorCatalog.defaultInstance
    .asTrustedLocalCatalog();

final _nameBinding = skir.ExpressionBindingId(
  value: "organization.identity.name",
);

final _nameCandidate = skir.ExpressionBindingId(
  value: "presentation.organization_name_completion",
);

skir.ExpressionNode _literal(String value) =>
    skir.ExpressionNode.wrapLiteral(skir.DataValue.wrapStringValue(value));

/// Typed names become valid ones as they are typed: lowercase, with spaces
/// and dashes turned into underscores.
final _nameMappings =
    (skir.ValueMappings.mutable()
          ..completion = skir.ExpressionMapping(
            inputBinding: skir.BindingDeclaration(
              id: _nameCandidate,
              type: skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
            ),
            body: portableCall("regex.replace", [
              portableCall("regex.replace", [
                portableCall("text.lower", [
                  skir.ExpressionNode.createInput(
                    binding: _nameCandidate,
                    path: editorRootPath,
                  ),
                ]),
                _literal(r"[\s\-]+"),
                _literal("_"),
              ]),
              _literal("[^a-z0-9_]"),
              _literal(""),
            ]),
          ))
        .toFrozen();

skir.PresentationNode _organizationIdentityPresentation() {
  final binding = skir.BindingRef(
    bindingId: _nameBinding,
    path: skir.ValuePath(segments: const []),
  );
  return skir.PresentationNode(
    nodeId: "organizationIdentity",
    properties: skir.PresentationProperties.defaultInstance,
    element: skir.PresentationElement.wrapChildren(
      skir.ChildrenElement.createColumn(
        children: [
          skir.PresentationNode(
            nodeId: "organizationIdentity.name",
            properties: skir.PresentationProperties.defaultInstance,
            element: skir.PresentationElement.createTextInput(
              control: skir.BoundControl(
                binding: binding,
                label: _literal("Name"),
                description: null,
                prefix: null,
                semanticLabel: _literal("Organization name"),
              ),
              appearance: null,
              content: null,
              mappings: _nameMappings,
              entry: null,
              options:
                  (skir.TextEditingOptions.mutable()
                        ..lines = skir.TextLines.single
                        ..characterFilters = [
                          skir.CharacterFilter.wrapAllow(r"[A-Za-z0-9_\s\-]"),
                        ])
                      .toFrozen(),
            ),
            header: null,
          ),
          skir.PresentationNode(
            nodeId: "organizationIdentity.save",
            properties: skir.PresentationProperties.defaultInstance,
            element: skir.PresentationElement.createCommitControls(
              binding: binding,
            ),
            header: null,
          ),
        ].map(skir.AxisChild.wrapFixed),
        layout: skir.AxisChildrenLayout(
          clipOverflow: false,
          spacing: 8,
          mainAxisAlignment: skir.MainAxisAlignment.start,
          crossAxisAlignment: skir.CrossAxisAlignment.stretch,
        ),
      ),
    ),
    header: null,
  );
}
