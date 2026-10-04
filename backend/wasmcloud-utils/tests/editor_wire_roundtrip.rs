use wasmcloud_utils::skir::base::editor::v1::{
    authoring, binding, catalog, checking,
    expression::{CollectionExpression, ExpressionCall, ExpressionNode, ExpressionRead},
    presentation::{
        AxisChild, AxisChildrenElement, AxisChildrenLayout, BoundControl, ChildrenElement,
        NamedControl, PageGraphDirection, PageGraphElement, PageTimelineElement,
        PresentationElement, PresentationNode, TextContent,
    },
    publication, search,
    type_catalog::{
        ArgumentSelection, AuthoringRecord, DataValue, DeclaredTypeId, EndpointId,
        ExpressionBindingId, FieldPathSegment, FieldValue, ItemId, LinkTarget, LinkValue, ListItem,
        ListPayload, MapPayload, MapRow, NamedTypeUse, NamedValue, OperationId, PathSegment,
        PendingTypeSelection, QualifiedTypeId, ResourceId, ScalarKind, TypeDefinitionId, TypeId,
        TypeSelection, TypeTemplate, TypeUse, ValuePath,
    },
};
use wasmcloud_utils::skir_client::{KeyedVec, UnrecognizedValues};

const TEXT_ID: &str = "11111111-1111-4111-8111-111111111111";
const TREE_ID: &str = "22222222-2222-4222-8222-222222222222";
const VARIABLE_ID: &str = "33333333-3333-4333-8333-333333333333";
const RESOURCE_ID: &str = "44444444-4444-4444-8444-444444444444";

fn declared(name: &str) -> TypeDefinitionId {
    TypeDefinitionId {
        type_id: TypeId::Declared(Box::new(DeclaredTypeId {
            value: name.to_owned(),
            _unrecognized: None,
        })),
        revision: 1,
        _unrecognized: None,
    }
}

#[test]
fn presentation_search_request_preserves_contiguous_field_payloads() {
    let request = search::RealmPresentationSearchRequest {
        subscription_id: "search:one".to_owned(),
        generation: wasmcloud_utils::skir::base::editor::v1::type_catalog::CatalogGeneration {
            value: "catalog:one".to_owned(),
            _unrecognized: None,
        },
        capability_id: wasmcloud_utils::skir::base::editor::v1::type_catalog::CapabilityId {
            value: "capability:one".to_owned(),
            _unrecognized: None,
        },
        payload: DataValue::StringValue("payload".to_owned()),
        result_type: TypeTemplate::Scalar(Box::new(ScalarKind::Text)),
        query: search::RealmSearchQuery {
            normalized_query: "quest".to_owned(),
            selectors: vec![],
            selector_expression: None,
            terms: vec!["quest".to_owned()],
            _unrecognized: None,
        },
        _unrecognized: None,
    };

    let bytes = search::RealmPresentationSearchRequest::serializer().to_bytes(&request);
    let decoded = search::RealmPresentationSearchRequest::serializer()
        .from_bytes(&bytes, UnrecognizedValues::Drop)
        .expect("presentation search request must decode");
    assert_eq!(decoded, request);
}

fn named(definition: TypeDefinitionId, arguments: Vec<TypeUse>) -> NamedTypeUse {
    NamedTypeUse {
        definition,
        arguments,
        _unrecognized: None,
    }
}

#[test]
fn authored_tree_round_trips_complete_pending_nested_generic_and_link_values() {
    let text = TypeUse::Named(Box::new(named(declared(TEXT_ID), vec![])));
    let generic = named(declared(TREE_ID), vec![text.clone()]);
    let link = DataValue::Link(Box::new(LinkValue {
        endpoint: EndpointId {
            value: "typewriter.pages.first".to_owned(),
            _unrecognized: None,
        },
        target: LinkTarget {
            resource: ResourceId {
                value: "page:target".to_owned(),
                _unrecognized: None,
            },
            opposite: None,
            _unrecognized: None,
        },
        _unrecognized: None,
    }));
    let nested = DataValue::Named(Box::new(NamedValue {
        actual_type: generic.clone(),
        payload: DataValue::ListValue(Box::new(ListPayload {
            items: vec![
                ListItem {
                    id: ItemId {
                        value: "child:one".to_owned(),
                        _unrecognized: None,
                    },
                    value: DataValue::Unfilled,
                    _unrecognized: None,
                },
                ListItem {
                    id: ItemId {
                        value: "child:two".to_owned(),
                        _unrecognized: None,
                    },
                    value: link,
                    _unrecognized: None,
                },
            ],
            _unrecognized: None,
        })),
        _unrecognized: None,
    }));
    let record = AuthoringRecord {
        configuration: TypeSelection::Pending(Box::new(PendingTypeSelection {
            definition: declared(VARIABLE_ID),
            arguments: vec![ArgumentSelection::Chosen(Box::new(TypeUse::Named(
                Box::new(generic),
            )))],
            _unrecognized: None,
        })),
        fields: KeyedVec::new(vec![
            FieldValue {
                name: "value".to_owned(),
                value: nested,
                _unrecognized: None,
            },
            FieldValue {
                name: "rows".to_owned(),
                value: DataValue::MapValue(Box::new(MapPayload {
                    rows: vec![MapRow {
                        id: ItemId {
                            value: "row:one".to_owned(),
                            _unrecognized: None,
                        },
                        key: DataValue::StringValue("duplicate".to_owned()),
                        value: DataValue::SetValue(Box::new(ListPayload {
                            items: vec![ListItem {
                                id: ItemId {
                                    value: "set:one".to_owned(),
                                    _unrecognized: None,
                                },
                                value: DataValue::Integer("18446744073709551615".to_owned()),
                                _unrecognized: None,
                            }],
                            _unrecognized: None,
                        })),
                        _unrecognized: None,
                    }],
                    _unrecognized: None,
                })),
                _unrecognized: None,
            },
        ]),
        _unrecognized: None,
    };

    let bytes = AuthoringRecord::serializer().to_bytes(&record);
    let decoded = AuthoringRecord::serializer()
        .from_bytes(&bytes, UnrecognizedValues::Drop)
        .expect("authoring record must decode");

    assert_eq!(decoded, record);

    let complete = AuthoringRecord {
        configuration: TypeSelection::Complete(Box::new(named(declared(TREE_ID), vec![text]))),
        fields: KeyedVec::new(vec![]),
        _unrecognized: None,
    };
    let complete_bytes = AuthoringRecord::serializer().to_bytes(&complete);
    let complete_decoded = AuthoringRecord::serializer()
        .from_bytes(&complete_bytes, UnrecognizedValues::Drop)
        .expect("complete authoring record must decode");

    assert_eq!(complete_decoded, complete);
}

#[test]
fn expression_and_layout_round_trip_without_losing_portable_nodes() {
    let label = ExpressionNode::Literal(Box::new(DataValue::StringValue("Name".to_owned())));
    let child = PresentationNode {
        node_id: "label".to_owned(),
        element: Some(PresentationElement::Text(Box::new(TextContent {
            value: label,
            ..Default::default()
        }))),
        ..Default::default()
    };
    let root = PresentationNode {
        node_id: "root".to_owned(),
        element: Some(PresentationElement::Children(Box::new(
            ChildrenElement::Row(Box::new(AxisChildrenElement {
                children: vec![
                    AxisChild::Fixed(Box::new(child.clone())),
                    AxisChild::Fixed(Box::new(PresentationNode {
                        node_id: "named".to_owned(),
                        element: Some(PresentationElement::NamedInput(Box::new(NamedControl {
                            payload_presentation: Some(child),
                            ..Default::default()
                        }))),
                        ..Default::default()
                    })),
                ],
                layout: AxisChildrenLayout {
                    spacing: 12.0,
                    ..Default::default()
                },
                _unrecognized: None,
            })),
        ))),
        ..Default::default()
    };

    let bytes = PresentationNode::serializer().to_bytes(&root);
    let decoded = PresentationNode::serializer()
        .from_bytes(&bytes, UnrecognizedValues::Drop)
        .expect("presentation node must decode");

    assert_eq!(decoded, root);
}

#[test]
fn qualified_definition_identity_round_trips() {
    let value = TypeDefinitionId {
        type_id: TypeId::Qualified(Box::new(QualifiedTypeId {
            namespace: "example".to_owned(),
            name: "resource".to_owned(),
            _unrecognized: None,
        })),
        revision: 1,
        _unrecognized: None,
    };

    let bytes = TypeDefinitionId::serializer().to_bytes(&value);
    let decoded = TypeDefinitionId::serializer()
        .from_bytes(&bytes, UnrecognizedValues::Drop)
        .expect("definition identity must decode");

    assert_eq!(decoded, value);
}

#[test]
fn page_workspaces_preserve_their_field_binding_and_graph_direction() {
    let control = BoundControl {
        binding: binding::BindingRef {
            binding_id: ExpressionBindingId {
                value: "configured_value".to_owned(),
                _unrecognized: None,
            },
            path: ValuePath {
                segments: vec![PathSegment::Field(Box::new(FieldPathSegment {
                    name: "elements".to_owned(),
                    _unrecognized: None,
                }))],
                _unrecognized: None,
            },
            _unrecognized: None,
        },
        ..Default::default()
    };
    let elements = [
        PresentationElement::PageGraph(Box::new(PageGraphElement {
            control: control.clone(),
            direction: PageGraphDirection::RightToLeft,
            _unrecognized: None,
        })),
        PresentationElement::PageTimeline(Box::new(PageTimelineElement {
            control,
            _unrecognized: None,
        })),
    ];
    for element in elements {
        let bytes = PresentationElement::serializer().to_bytes(&element);
        let decoded = PresentationElement::serializer()
            .from_bytes(&bytes, UnrecognizedValues::Drop)
            .expect("page workspace must decode");
        assert_eq!(decoded, element);
    }
}

#[test]
fn collection_expressions_preserve_fold_bindings_and_optional_body() {
    let binding = |value: &str| ExpressionBindingId {
        value: value.to_owned(),
        _unrecognized: None,
    };
    let read = |value: &str| {
        ExpressionNode::Read(Box::new(ExpressionRead {
            binding: binding(value),
            ..Default::default()
        }))
    };
    let input = ExpressionNode::Literal(Box::new(DataValue::ListValue(Box::new(ListPayload {
        items: vec![ListItem {
            id: ItemId {
                value: "score:one".to_owned(),
                _unrecognized: None,
            },
            value: DataValue::Integer("3".to_owned()),
            _unrecognized: None,
        }],
        _unrecognized: None,
    }))));
    let fold = CollectionExpression {
        operation: OperationId {
            value: "typewriter.collection.fold".to_owned(),
            _unrecognized: None,
        },
        input: input.clone(),
        bindings: vec![binding("total"), binding("score")],
        arguments: vec![ExpressionNode::Literal(Box::new(DataValue::Integer(
            "0".to_owned(),
        )))],
        body: Some(ExpressionNode::Call(Box::new(ExpressionCall {
            operation: OperationId {
                value: "typewriter.number.add".to_owned(),
                _unrecognized: None,
            },
            arguments: vec![read("total"), read("score")],
            _unrecognized: None,
        }))),
        _unrecognized: None,
    };
    let reverse = CollectionExpression {
        operation: OperationId {
            value: "typewriter.collection.reverse".to_owned(),
            _unrecognized: None,
        },
        input,
        ..Default::default()
    };
    for value in [fold, reverse] {
        let bytes = CollectionExpression::serializer().to_bytes(&value);
        let decoded = CollectionExpression::serializer()
            .from_bytes(&bytes, UnrecognizedValues::Drop)
            .expect("collection expression must decode");
        assert_eq!(decoded, value);
    }
}

#[test]
fn snapshot_bound_lifecycle_contracts_round_trip_with_typed_evidence() {
    let catalog_snapshot = catalog::EditorCatalogWireSnapshot {
        role_fallbacks: vec![catalog::RoleFallback {
            role: catalog::PresentationRole::ReferenceOption,
            parents: vec![
                catalog::PresentationRole::ReferenceSummary,
                catalog::PresentationRole::CatalogOption,
            ],
            _unrecognized: None,
        }],
        ..Default::default()
    };
    let catalog_bytes =
        catalog::EditorCatalogWireSnapshot::serializer().to_bytes(&catalog_snapshot);
    let decoded_catalog = catalog::EditorCatalogWireSnapshot::serializer()
        .from_bytes(&catalog_bytes, UnrecognizedValues::Drop)
        .expect("ordered role fallbacks must decode");
    assert_eq!(decoded_catalog, catalog_snapshot);
    let location = wasmcloud_utils::skir::base::editor::v1::type_catalog::ValueLocation {
        resource: ResourceId {
            value: "resource:one".to_owned(),
            _unrecognized: None,
        },
        ..Default::default()
    };
    let observation = checking::InputObservation {
        identity: checking::InputIdentity::Value(Box::new(checking::ValueInputIdentity {
            at: location.clone(),
            _unrecognized: None,
        })),
        token: wasmcloud_utils::skir::base::editor::v1::type_catalog::InputToken {
            value: "input:7".to_owned(),
            _unrecognized: None,
        },
        _unrecognized: None,
    };
    let snapshot = authoring::AuthoringSnapshot {
        snapshot: wasmcloud_utils::skir::base::editor::v1::type_catalog::SnapshotId {
            value: "snapshot:9".to_owned(),
            _unrecognized: None,
        },
        generation: wasmcloud_utils::skir::base::editor::v1::type_catalog::CatalogGeneration {
            value: "catalog:4".to_owned(),
            _unrecognized: None,
        },
        observations: vec![observation.clone()],
        absent_input_token: wasmcloud_utils::skir::base::editor::v1::type_catalog::InputToken {
            value: "absent".to_owned(),
            _unrecognized: None,
        },
        ..Default::default()
    };
    let snapshot_bytes = authoring::AuthoringSnapshot::serializer().to_bytes(&snapshot);
    let decoded_snapshot = authoring::AuthoringSnapshot::serializer()
        .from_bytes(&snapshot_bytes, UnrecognizedValues::Drop)
        .expect("snapshot input evidence must decode");
    assert_eq!(decoded_snapshot, snapshot);
    let prepared = authoring::PreparedEdit {
        id: wasmcloud_utils::skir::base::editor::v1::type_catalog::BatchId {
            value: "batch:one".to_owned(),
            _unrecognized: None,
        },
        catalog: wasmcloud_utils::skir::base::editor::v1::type_catalog::CatalogGeneration {
            value: "catalog:4".to_owned(),
            _unrecognized: None,
        },
        snapshot: wasmcloud_utils::skir::base::editor::v1::type_catalog::SnapshotId {
            value: "snapshot:9".to_owned(),
            _unrecognized: None,
        },
        observations: vec![observation.clone()],
        intents: vec![authoring::EditIntent::SetValue(Box::new(
            authoring::SetValueIntent {
                at: location.clone(),
                value: DataValue::StringValue("updated".to_owned()),
                _unrecognized: None,
            },
        ))],
        _unrecognized: None,
    };
    let prepared_bytes = authoring::PreparedEdit::serializer().to_bytes(&prepared);
    let prepared_decoded = authoring::PreparedEdit::serializer()
        .from_bytes(&prepared_bytes, UnrecognizedValues::Drop)
        .expect("prepared edit must decode");
    assert_eq!(prepared_decoded, prepared);

    let initialization = catalog::InitializationRequest {
        id: wasmcloud_utils::skir::base::editor::v1::type_catalog::InitializationRequestId {
            value: "initialization:one".to_owned(),
            _unrecognized: None,
        },
        catalog: prepared.catalog.clone(),
        type_: TypeSelection::Complete(Box::new(named(declared(RESOURCE_ID), vec![]))),
        supplied: KeyedVec::new(vec![FieldValue {
            name: "name".to_owned(),
            value: DataValue::StringValue("created".to_owned()),
            _unrecognized: None,
        }]),
        intent_hash: "intent:create".to_owned(),
        _unrecognized: None,
    };
    let initialization_bytes =
        catalog::InitializationRequest::serializer().to_bytes(&initialization);
    let initialization_decoded = catalog::InitializationRequest::serializer()
        .from_bytes(&initialization_bytes, UnrecognizedValues::Drop)
        .expect("initialization request must decode");
    assert_eq!(initialization_decoded, initialization);

    let pending = TypeSelection::Pending(Box::new(PendingTypeSelection {
        definition: declared(RESOURCE_ID),
        arguments: vec![
            ArgumentSelection::Chosen(Box::new(TypeUse::Named(Box::new(named(
                declared(RESOURCE_ID),
                vec![],
            ))))),
            ArgumentSelection::Unfilled,
        ],
        _unrecognized: None,
    }));
    let repair = authoring::TypeArgumentChangePreview {
        catalog: prepared.catalog.clone(),
        source_snapshot: prepared.snapshot.clone(),
        resource: location.resource.clone(),
        next: pending.clone(),
        observations: vec![observation],
        intents: vec![
            authoring::TypeRepairIntent::ConfigureResource(Box::new(
                authoring::ResourceConfigurationIntent {
                    resource: location.resource.clone(),
                    configuration: pending.clone(),
                    _unrecognized: None,
                },
            )),
            authoring::TypeRepairIntent::Clear(Box::new(location.clone())),
        ],
        link_repairs: vec![],
        cleared_locations: vec![location],
        _unrecognized: None,
    };
    let repair_bytes = authoring::TypeArgumentChangePreview::serializer().to_bytes(&repair);
    let repair_decoded = authoring::TypeArgumentChangePreview::serializer()
        .from_bytes(&repair_bytes, UnrecognizedValues::Drop)
        .expect("type repair preview must decode");
    assert_eq!(repair_decoded, repair);

    let publication = publication::PublicationAttempt {
        id: wasmcloud_utils::skir::base::editor::v1::type_catalog::PublicationId {
            value: "publication:one".to_owned(),
            _unrecognized: None,
        },
        capture: prepared.snapshot,
        catalog: prepared.catalog,
        engine_inputs: publication::EngineImplementationInputs {
            token: wasmcloud_utils::skir::base::editor::v1::type_catalog::InputToken {
                value: "engine:3".to_owned(),
                _unrecognized: None,
            },
            ..Default::default()
        },
        state: publication::PublicationState::Checking,
        _unrecognized: None,
    };
    let publication_bytes = publication::PublicationAttempt::serializer().to_bytes(&publication);
    let publication_decoded = publication::PublicationAttempt::serializer()
        .from_bytes(&publication_bytes, UnrecognizedValues::Drop)
        .expect("publication attempt must decode");
    assert_eq!(publication_decoded, publication);
}

#[test]
fn complete_authoring_intent_vocabulary_and_preview_identity_round_trip() {
    let resource = ResourceId {
        value: "resource:wire".to_owned(),
        _unrecognized: None,
    };
    let location = wasmcloud_utils::skir::base::editor::v1::type_catalog::ValueLocation {
        resource: resource.clone(),
        ..Default::default()
    };
    let endpoint = EndpointId {
        value: "relation:first".to_owned(),
        _unrecognized: None,
    };
    let occurrence = authoring::LinkOccurrence {
        id: authoring::LinkOccurrenceId {
            endpoint,
            location: location.clone(),
            _unrecognized: None,
        },
        source: resource.clone(),
        target: LinkTarget {
            resource: resource.clone(),
            opposite: None,
            _unrecognized: None,
        },
        _unrecognized: None,
    };
    let record = AuthoringRecord {
        configuration: TypeSelection::Complete(Box::new(named(declared(RESOURCE_ID), vec![]))),
        fields: KeyedVec::new(vec![]),
        _unrecognized: None,
    };
    let pending_configuration = TypeSelection::Pending(Box::new(PendingTypeSelection {
        definition: declared(RESOURCE_ID),
        arguments: vec![ArgumentSelection::Unfilled],
        _unrecognized: None,
    }));
    let item = ListItem {
        id: ItemId {
            value: "item:wire".to_owned(),
            _unrecognized: None,
        },
        value: DataValue::Unfilled,
        _unrecognized: None,
    };
    let intents = vec![
        authoring::EditIntent::CreateResource(Box::new(authoring::CreateResourceIntent {
            id: resource.clone(),
            record: record.clone(),
            _unrecognized: None,
        })),
        authoring::EditIntent::DeleteResource(Box::new(authoring::DeleteResourceIntent {
            id: resource.clone(),
            _unrecognized: None,
        })),
        authoring::EditIntent::SetValue(Box::new(authoring::SetValueIntent {
            at: location.clone(),
            value: DataValue::Unfilled,
            _unrecognized: None,
        })),
        authoring::EditIntent::Insert(Box::new(authoring::InsertIntent {
            at: location.clone(),
            after: None,
            item: item.clone(),
            _unrecognized: None,
        })),
        authoring::EditIntent::Remove(Box::new(authoring::RemoveIntent {
            at: location.clone(),
            item: item.id.clone(),
            _unrecognized: None,
        })),
        authoring::EditIntent::Move(Box::new(authoring::MoveIntent {
            at: location.clone(),
            item: item.id.clone(),
            after: None,
            _unrecognized: None,
        })),
        authoring::EditIntent::ConnectRelation(Box::new(authoring::ConnectIntent {
            source: occurrence.clone(),
            target: resource.clone(),
            counterpart: Some(authoring::CounterpartChoice::New(Box::new(
                authoring::NewCounterpartChoice {
                    containing: location.clone(),
                    prepared: catalog::PreparedCreation {
                        record: record.clone(),
                        findings: vec![],
                        _unrecognized: None,
                    },
                    _unrecognized: None,
                },
            ))),
            _unrecognized: None,
        })),
        authoring::EditIntent::DisconnectRelation(Box::new(occurrence.id.clone())),
        authoring::EditIntent::Retag(Box::new(authoring::RetagIntent {
            at: location.clone(),
            type_: named(declared(RESOURCE_ID), vec![]),
            _unrecognized: None,
        })),
        authoring::EditIntent::ConfigureResource(Box::new(
            authoring::ResourceConfigurationIntent {
                resource: resource.clone(),
                configuration: pending_configuration,
                _unrecognized: None,
            },
        )),
    ];
    let bytes = authoring::EditIntent::serializer().to_bytes(&intents[0]);
    assert_eq!(
        authoring::EditIntent::serializer()
            .from_bytes(&bytes, UnrecognizedValues::Drop)
            .expect("complete edit intent must decode"),
        intents[0],
    );
    for intent in intents {
        let bytes = authoring::EditIntent::serializer().to_bytes(&intent);
        let decoded = authoring::EditIntent::serializer()
            .from_bytes(&bytes, UnrecognizedValues::Drop)
            .expect("edit intent must decode");
        assert_eq!(decoded, intent);
    }

    let preview = authoring::TypeArgumentChangePreview {
        catalog: wasmcloud_utils::skir::base::editor::v1::type_catalog::CatalogGeneration {
            value: "catalog:wire".to_owned(),
            _unrecognized: None,
        },
        source_snapshot: wasmcloud_utils::skir::base::editor::v1::type_catalog::SnapshotId {
            value: "snapshot:wire".to_owned(),
            _unrecognized: None,
        },
        resource,
        next: TypeSelection::Complete(Box::new(named(declared(RESOURCE_ID), vec![]))),
        observations: vec![],
        intents: vec![],
        link_repairs: vec![],
        cleared_locations: vec![location],
        _unrecognized: None,
    };
    let bytes = authoring::TypeArgumentChangePreview::serializer().to_bytes(&preview);
    let decoded = authoring::TypeArgumentChangePreview::serializer()
        .from_bytes(&bytes, UnrecognizedValues::Drop)
        .expect("preview identity must decode");
    assert_eq!(decoded, preview);
}
