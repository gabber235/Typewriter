import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

/// A draft of a source resource whose wrapper record links to target
/// resources with a back reference, and an existing and an empty target.
/// The flags vary the shape of the wrapper and of its inverse link.
final class LinkChoicesFixture {
  factory LinkChoicesFixture({
    bool incompatibleInverse = false,
    bool directCollection = false,
    bool abstractWrapper = false,
    bool nestedCollection = false,
  }) {
    final wrapper = abstractWrapper ? "AbstractWrapper" : "Wrapper";
    final linked = directCollection || nestedCollection;
    final emptyLinks = typedValue(
      "Links",
      skir.DataValue.createListValue(items: const []),
    );
    skir.AuthoringResource node(String id, skir.DataValue wrapperValue) =>
        authoredRecord(id, {
          "source": skir.DataValue.unfilled,
          "wrapper": directCollection ? emptyLinks : wrapperValue,
        }, type: typeUse("Node"));
    final saved = authoredDoc(
      [
        node("resource:source", skir.DataValue.unfilled),
        node(
          "resource:existing",
          typedValue(
            "Wrapper",
            recordEditorValue({
              "back": nestedCollection ? emptyLinks : skir.DataValue.unfilled,
              "label": textValue("existing"),
            }),
          ),
        ),
        node("resource:empty", skir.DataValue.unfilled),
      ],
      catalog: authoredCatalog(
        [
          if (abstractWrapper) declaredRecord("AbstractWrapper", open: true),
          declaredCollection("Links", "TargetLink"),
          declaredRecord(
            "Node",
            fields: {
              "source": "SourceLink",
              "wrapper": directCollection ? "Links" : wrapper,
            },
          ),
          declaredRecord(
            "Wrapper",
            fields: {
              "back": nestedCollection ? "Links" : "TargetLink",
              "label": skir.ScalarKind.text,
            },
            parents: [if (abstractWrapper) "AbstractWrapper"],
          ),
          declaredLink("SourceLink", endpoint: "test.source", target: "Node"),
          declaredLink(
            "TargetLink",
            endpoint: "test.target",
            target: incompatibleInverse ? wrapper : "Node",
          ),
        ],
        relations: [
          declaredRelation(
            "test.links",
            endpointOf(
              "test.source",
              "Node",
              cardinality: linked
                  ? skir.EndpointCardinality.many
                  : skir.EndpointCardinality.one,
            ),
            endpointOf(
              "test.target",
              "Node",
              cardinality: linked
                  ? skir.EndpointCardinality.one
                  : skir.EndpointCardinality.many,
            ),
          ),
        ],
        endpoints: [
          endpointBinding(
            "test.source",
            resource: "Node",
            path: ["source"],
            target: "Node",
          ),
          if (!abstractWrapper)
            endpointBinding(
              "test.target",
              resource: "Node",
              owner: directCollection ? "Node" : "Wrapper",
              path: [
                "wrapper",
                directCollection ? skir.FieldPatternSegment.items : "back",
              ],
              target: incompatibleInverse ? wrapper : "Node",
            ),
        ],
        generation: "catalog:links",
      ),
    );
    return LinkChoicesFixture._(
      draft: saved.edit,
      catalog: saved.catalog,
      source: valueAt("resource:source", ["source"]),
      existingTarget: skir.ResourceId(value: "resource:existing"),
      emptyTarget: skir.ResourceId(value: "resource:empty"),
      nestedLinkPath: valueAt("resource:source", ["wrapper", "back"]).path,
      wrapperUse: typeUse("Wrapper"),
      wrapperSelection: selectionOfUse(typeUse("Wrapper")),
    );
  }

  LinkChoicesFixture._({
    required this.draft,
    required this.catalog,
    required this.source,
    required this.existingTarget,
    required this.emptyTarget,
    required this.nestedLinkPath,
    required this.wrapperUse,
    required this.wrapperSelection,
  });

  final AuthoringEdit draft;
  final CheckedEditorCatalog catalog;
  final skir.ValueLocation source;
  final skir.ResourceId existingTarget;
  final skir.ResourceId emptyTarget;
  final skir.ValuePath nestedLinkPath;
  final skir.NamedTypeUse wrapperUse;
  final skir.TypeSelection wrapperSelection;

  /// The resources the links in [resource]'s `wrapper.back` lead to.
  List<skir.ResourceId?> backLinks(
    AuthoringDocument document,
    skir.ResourceId resource,
  ) {
    final back = document.valueAt(
      authoredFieldLocation(resource, ["wrapper", "back"]),
    );
    return [
      for (final item in back?.authoredItems ?? const <skir.ListItem>[])
        item.value.authoredLink?.target.resource,
    ];
  }
}

/// Resolving links of an authoring edit the way choosing a link target does.
extension SingleLinkResolution on AuthoringEdit {
  /// Resolves the link from [field] of [source] to [target] through the one
  /// plan that field offers, against the edit's own catalog.
  ResolvedReference resolveSingleLink(
    skir.ResourceId source,
    String field,
    skir.ResourceId target,
  ) {
    final plan = (linkPlans(
      catalog: catalog!,
      source: skir.ValueLocation(
        resource: source,
        path: editorRootPath.field(field),
      ),
    ) as PortableLinkPlanReady).plans.single;
    return resolveReference(
      catalog: catalog!,
      plan: plan,
      target: plan.targets.singleWhere((choice) => choice.resource == target),
    );
  }
}
