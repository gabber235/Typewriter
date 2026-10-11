package com.typewritermc.types

import com.typewritermc.authoring.ArgumentSelection
import com.typewritermc.authoring.AuthoringRecord
import com.typewritermc.authoring.CompletenessResult
import com.typewritermc.authoring.ItemId
import com.typewritermc.authoring.StructuralResult
import com.typewritermc.authoring.TypeSelection
import com.typewritermc.authoring.complete
import com.typewritermc.authoring.validateStructure
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.discovery.ContributionKey
import com.typewritermc.imprint.ContributionName
import com.typewritermc.imprint.ContributionSourceId
import com.typewritermc.imprint.ProducerId
import com.typewritermc.presentation.PresentationDescriptor
import com.typewritermc.presentation.PresentationMaterial
import com.typewritermc.presentation.PresentationTarget
import com.typewritermc.presentation.explicitFieldSelections
import com.typewritermc.types.catalog.DeclarationStatus
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.catalog.EditorCatalogSnapshot
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.skir.SkirAuthoringValueCodec
import com.typewritermc.types.skir.SkirConversionResult
import com.typewritermc.types.skir.SkirDataValueCodec
import com.typewritermc.types.skir.SkirTypeCodec
import com.typewritermc.types.skir.getOrThrow
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import java.math.BigInteger

val TypeSystemFoundationTest by testSuite {
    test("definitions and complete uses remain distinct") {
        val weighted = weightedDefinition()
        val catalog = catalog(weighted)

        val missingArgument = catalog.resolve(TypeUse.Named(weighted.id)) as Resolution.Invalid
        missingArgument.diagnostics.map { it.code } shouldContainExactly listOf("argument_arity")
        catalog.isReadableAs(TypeUse.Named(weighted.id), TypeUse.Named(weighted.id)) shouldBe false

        val complete = TypeUse.Named(weighted.id, listOf(TEXT))
        (catalog.resolve(complete) is Resolution.Ready) shouldBe true
    }

    test("deep type uses fail before resolver hashing and codec recursion") {
        var boundary: TypeUse = TEXT
        repeat(511) {
            boundary = TypeUse.Nullable(boundary)
        }
        val encodedBoundary = SkirTypeCodec.encode(boundary).getOrThrow()
        val tooDeep = TypeUse.Nullable(boundary)
        val resolution = catalog().resolve(tooDeep) as Resolution.Invalid

        resolution.diagnostics.map { it.code } shouldContainExactly listOf("type_depth_limit")
        (SkirTypeCodec.encode(tooDeep) is SkirConversionResult.Failure) shouldBe true
        val encodedTooDeep =
            skirout.editor.v1.type_catalog.TypeUse.NullableWrapper(
                skirout.editor.v1.type_catalog
                    .NullableTypeUse(value = encodedBoundary),
            )
        (SkirTypeCodec.decode(encodedTooDeep) is SkirConversionResult.Failure) shouldBe true
    }

    test("deep type templates use the same codec depth boundary") {
        var boundary: TypeTemplate = TEXT_TEMPLATE
        repeat(511) {
            boundary = TypeTemplate.Nullable(boundary)
        }
        val encodedBoundary = SkirTypeCodec.encode(boundary).getOrThrow()
        val tooDeep = TypeTemplate.Nullable(boundary)

        (SkirTypeCodec.encode(tooDeep) is SkirConversionResult.Failure) shouldBe true
        val encodedTooDeep =
            skirout.editor.v1.type_catalog.TypeTemplate.NullableWrapper(
                skirout.editor.v1.type_catalog
                    .NullableTypeTemplate(value = encodedBoundary),
            )
        (SkirTypeCodec.decode(encodedTooDeep) is SkirConversionResult.Failure) shouldBe true
    }

    test("deep declaration templates are isolated before immutable catalog assembly") {
        var type: TypeTemplate = TEXT_TEMPLATE
        repeat(512) {
            type = TypeTemplate.Nullable(type)
        }
        val definitionId = id("deep_declaration")
        val definition =
            TypeDefinition(
                definitionId,
                representation =
                    RepresentationTemplate.Record(
                        listOf(FieldDeclaration(FieldOwner(definitionId, "value"), type)),
                    ),
            )

        val status = catalog(definition).definition(definitionId) as DeclarationStatus.Unavailable
        status.reasons.map { it.code } shouldContainExactly listOf("type_depth_limit")
    }

    test("checked catalogs own immutable declaration metadata") {
        val definitionId = id("immutable_source")
        val sourceFields =
            mutableListOf(
                FieldDeclaration(FieldOwner(definitionId, "value"), TEXT_TEMPLATE),
            )
        val definition = TypeDefinition(definitionId, representation = RepresentationTemplate.Record(sourceFields))
        val catalog = catalog(definition)

        sourceFields.clear()
        sourceFields += FieldDeclaration(FieldOwner(definitionId, "replacement"), TypeTemplate.Scalar(ScalarKind.Boolean))

        val resolved = catalog.resolve(TypeUse.Named(definitionId)) as Resolution.Ready
        resolved.value.schema.fields
            .map { it.key } shouldContainExactly listOf("value")
        resolved.value.schema.fields
            .single()
            .type shouldBe TEXT
    }

    test("bounds and inherited fields resolve through scoped parameters") {
        val resource = resourceDefinition()
        val reward = rewardDefinition(resource.id)
        val variable = variableDefinition(resource.id)
        val catalog = catalog(resource, reward, variable)

        val rewardUse = TypeUse.Named(reward.id)
        val valid = catalog.resolve(TypeUse.Named(variable.id, listOf(rewardUse))) as Resolution.Ready
        valid.value.schema.fields
            .map { it.key } shouldContainExactly listOf("name", "value")
        valid.value.schema.fields
            .single { it.key == "name" }
            .declarationOwner shouldBe resource.id

        val invalid = catalog.resolve(TypeUse.Named(variable.id, listOf(TEXT))) as Resolution.Invalid
        invalid.diagnostics.map { it.code } shouldContainExactly listOf("argument_bound")
    }

    test("nominal declaration ancestry does not fabricate generic arguments") {
        val resource = resourceDefinition()
        val variable = variableDefinition(resource.id)
        val unrelated = recordDefinition("unrelated")
        val catalog = catalog(resource, variable, unrelated)

        catalog.isNominalSubtype(variable.id, resource.id) shouldBe true
        catalog.isNominalSubtype(variable.id, variable.id) shouldBe true
        catalog.isNominalSubtype(resource.id, variable.id) shouldBe false
        catalog.isNominalSubtype(variable.id, unrelated.id) shouldBe false
        catalog.isNominalSubtype(id("missing"), resource.id) shouldBe false
        (catalog.resolve(TypeUse.Named(variable.id)) is Resolution.Invalid) shouldBe true
    }

    test("explicit child overrides resolve shared parent fields") {
        val left = recordDefinition("left", field("left", "shared", TEXT_TEMPLATE))
        val right = recordDefinition("right", field("right", "shared", TEXT_TEMPLATE))
        val childId = id("child")
        val child =
            TypeDefinition(
                id = childId,
                representation =
                    RepresentationTemplate.Record(
                        listOf(
                            FieldDeclaration(
                                owner = FieldOwner(childId, "shared"),
                                type = TEXT_TEMPLATE,
                                overrides = listOf(FieldOwner(left.id, "shared"), FieldOwner(right.id, "shared")),
                            ),
                        ),
                    ),
                parents = listOf(TypeTemplate.Named(left.id), TypeTemplate.Named(right.id)),
            )
        val unresolved =
            TypeDefinition(
                id = id("unresolved_child"),
                representation = RepresentationTemplate.Record(emptyList()),
                parents = listOf(TypeTemplate.Named(left.id), TypeTemplate.Named(right.id)),
            )
        val catalog = catalog(left, right, child, unresolved)

        val resolved = catalog.resolve(TypeUse.Named(child.id)) as Resolution.Ready
        resolved.value.schema.fields
            .single()
            .declarationOwner shouldBe child.id
        val invalid = catalog.resolve(TypeUse.Named(unresolved.id)) as Resolution.Invalid
        invalid.diagnostics.map { it.code } shouldContainExactly listOf("ambiguous_inherited_field")
    }

    test("generic covariance is readable while actual writes remain authoritative") {
        val resource = resourceDefinition()
        val reward = rewardDefinition(resource.id)
        val variable = variableDefinition(resource.id)
        val catalog = catalog(resource, reward, variable)
        val rewardUse = TypeUse.Named(reward.id)
        val resourceUse = TypeUse.Named(resource.id)
        val actual = TypeUse.Named(variable.id, listOf(rewardUse))
        val broad = TypeUse.Named(variable.id, listOf(resourceUse))

        catalog.isReadableAs(actual, broad) shouldBe true
        catalog.isReadableAs(broad, actual) shouldBe false

        val wrongWrite =
            AuthoringRecord(
                TypeSelection.Complete(actual),
                mapOf(
                    "name" to DataValue.StringValue("Variable"),
                    "value" to DataValue.Named(resourceUse, DataValue.Record(mapOf("name" to DataValue.StringValue("Broad")))),
                ),
            )
        (wrongWrite.validateStructure(catalog) as StructuralResult.Invalid).problems.map { it.code } shouldContainExactly
            listOf("unreadable_actual_type")
    }

    test("symbolic and concrete readability use the same catalog policy") {
        val resource = resourceDefinition()
        val reward = rewardDefinition(resource.id)
        val variable = variableDefinition(resource.id)
        val subject = id("symbolic_subject")
        val parameter = ParameterKey(subject, 0)
        val catalog = catalog(resource, reward, variable)
        val rewardUse = TypeUse.Named(reward.id)
        val resourceUse = TypeUse.Named(resource.id)
        val concreteActual = TypeUse.Named(variable.id, listOf(rewardUse))
        val concreteExpected = TypeUse.Named(variable.id, listOf(resourceUse))
        val symbolicActual = TypeTemplate.Named(variable.id, listOf(TypeTemplate.Parameter(parameter)))
        val symbolicExpected = TypeTemplate.Named(variable.id, listOf(TypeTemplate.Named(resource.id)))

        catalog.isTemplateReadableAs(
            symbolicActual,
            symbolicExpected,
            mapOf(parameter to listOf(TypeTemplate.Named(reward.id))),
        ) shouldBe catalog.isReadableAs(concreteActual, concreteExpected)
        catalog.isTemplateReadableAs(symbolicExpected, symbolicActual) shouldBe false
    }

    test("generic concrete forms infer arguments from applied abstract parents") {
        val messageId = id("message")
        val messageParameter = ParameterKey(messageId, 0)
        val message =
            TypeDefinition(
                id = messageId,
                parameters = listOf(TypeParameter(messageParameter, "T")),
                representation = RepresentationTemplate.Record(emptyList(), abstract = true),
            )
        val textMessageId = id("text_message")
        val textParameter = ParameterKey(textMessageId, 0)
        val textMessage =
            TypeDefinition(
                id = textMessageId,
                parameters = listOf(TypeParameter(textParameter, "T")),
                representation =
                    RepresentationTemplate.Record(
                        listOf(FieldDeclaration(FieldOwner(textMessageId, "payload"), TypeTemplate.Parameter(textParameter))),
                    ),
                parents = listOf(TypeTemplate.Named(messageId, listOf(TypeTemplate.Parameter(textParameter)))),
            )
        val catalog = catalog(message, textMessage)
        val expected = (catalog.resolve(TypeUse.Named(messageId, listOf(TEXT))) as Resolution.Ready).value

        catalog.concreteForms(expected).map { it.use } shouldContainExactly
            listOf(TypeUse.Named(textMessageId, listOf(TEXT)))
    }

    test("recursive generic records resolve only immediate fields") {
        val list = listDefinition()
        val tree = treeDefinition(list.id)
        val catalog = catalog(list, tree)
        val treeUse = TypeUse.Named(tree.id, listOf(TEXT))

        val resolved = catalog.resolve(treeUse) as Resolution.Ready
        resolved.value.schema.fields
            .single()
            .type shouldBe
            TypeUse.Named(list.id, listOf(TypeUse.Named(tree.id, listOf(TEXT))))
    }

    test("deep authored values return a bounded admission diagnostic") {
        val list = listDefinition()
        val tree = treeDefinition(list.id)
        val catalog = catalog(list, tree)
        val treeUse = TypeUse.Named(tree.id, listOf(TEXT))
        val listUse = TypeUse.Named(list.id, listOf(treeUse))
        val checked = (catalog.resolve(treeUse) as Resolution.Ready).value
        var value: DataValue =
            DataValue.Named(
                treeUse,
                DataValue.Record(mapOf("children" to DataValue.Named(listUse, DataValue.ListValue(emptyList())))),
            )
        repeat(600) { depth ->
            value =
                DataValue.Named(
                    treeUse,
                    DataValue.Record(
                        mapOf(
                            "children" to
                                DataValue.Named(
                                    listUse,
                                    DataValue.ListValue(listOf(ListItem(ItemId("item$depth"), value))),
                                ),
                        ),
                    ),
                )
        }

        (checked.complete(value) as CompletenessResult.Invalid).problems.map { it.code } shouldContainExactly
            listOf("value_depth_limit")
    }

    test("recursive generic bounds return a declaration diagnostic") {
        val familyId = id("recursive_family")
        val parameter = ParameterKey(familyId, 0)
        val family =
            TypeDefinition(
                familyId,
                parameters =
                    listOf(
                        TypeParameter(
                            parameter,
                            "T",
                            bounds = listOf(TypeTemplate.Named(familyId, listOf(TypeTemplate.Parameter(parameter)))),
                        ),
                    ),
                representation = RepresentationTemplate.Record(emptyList(), abstract = true),
            )
        val concrete =
            TypeDefinition(
                id("recursive_concrete"),
                representation = RepresentationTemplate.Record(emptyList()),
                parents = listOf(TypeTemplate.Named(familyId, listOf(TypeTemplate.Named(id("recursive_concrete"))))),
            )
        val catalog = catalog(family, concrete)

        val resolution = catalog.resolve(TypeUse.Named(concrete.id)) as Resolution.Invalid
        resolution.diagnostics.map { it.code } shouldContainExactly listOf("recursive_type_resolution")
    }

    test("recursive generic bounds through nullable return a declaration diagnostic") {
        val familyId = id("nullable_recursive_family")
        val concreteId = id("nullable_recursive_concrete")
        val parameter = ParameterKey(familyId, 0)
        val family =
            TypeDefinition(
                familyId,
                parameters =
                    listOf(
                        TypeParameter(
                            parameter,
                            "T",
                            bounds =
                                listOf(
                                    TypeTemplate.Nullable(
                                        TypeTemplate.Named(familyId, listOf(TypeTemplate.Parameter(parameter))),
                                    ),
                                ),
                        ),
                    ),
                representation = RepresentationTemplate.Record(emptyList(), abstract = true),
            )
        val concrete =
            TypeDefinition(
                concreteId,
                representation = RepresentationTemplate.Record(emptyList()),
                parents = listOf(TypeTemplate.Named(familyId, listOf(TypeTemplate.Named(concreteId)))),
            )
        val catalog = catalog(family, concrete)

        val resolution = catalog.resolve(TypeUse.Named(concrete.id)) as Resolution.Invalid
        resolution.diagnostics.map { it.code } shouldContainExactly listOf("recursive_type_resolution")
    }

    test("canonical equality distinguishes nested collections from sibling items") {
        val list = listDefinition()
        val tree = treeDefinition(list.id)
        val catalog = catalog(list, tree)
        val treeUse = TypeUse.Named(tree.id, listOf(TEXT))
        val listUse = TypeUse.Named(list.id, listOf(treeUse))
        val checked = (catalog.resolve(listUse) as Resolution.Ready).value

        fun sequence(children: List<DataValue>): DataValue =
            DataValue.Named(
                listUse,
                DataValue.ListValue(children.mapIndexed { index, value -> ListItem(ItemId("item$index"), value) }),
            )

        fun node(children: List<DataValue>): DataValue = DataValue.Named(treeUse, DataValue.Record(mapOf("children" to sequence(children))))
        val leaf = node(emptyList())
        val nested = (checked.complete(sequence(listOf(node(listOf(leaf, leaf))))) as CompletenessResult.Complete).value
        val siblings = (checked.complete(sequence(listOf(node(listOf(leaf)), leaf))) as CompletenessResult.Complete).value

        DefaultCanonicalValueEquality.equivalent(nested, siblings) shouldBe false
        (DefaultCanonicalValueEquality.hash(nested) == DefaultCanonicalValueEquality.hash(siblings)) shouldBe false
    }

    test("pending arguments preserve inherited independent fields") {
        val resource = resourceDefinition()
        val variable = variableDefinition(resource.id)
        val catalog = catalog(resource, variable)

        val partial =
            catalog.resolvePartial(
                TypeSelection.Pending(variable.id, listOf(ArgumentSelection.Unfilled)),
            ) as Resolution.Ready

        partial.value.knownFields.map { it.key } shouldContainExactly listOf("name")
        partial.value.dependentFields.map { it.owner.name } shouldContainExactly listOf("value")
    }

    test("known applications include only fully bound selected and inherited uses") {
        val baseId = id("known_base")
        val baseParameter = ParameterKey(baseId, 0)
        val base =
            TypeDefinition(
                baseId,
                parameters = listOf(TypeParameter(baseParameter, "T")),
                representation = RepresentationTemplate.Record(emptyList(), abstract = true),
            )
        val marker = recordDefinition("known_marker")
        val derivedId = id("known_derived")
        val first = ParameterKey(derivedId, 0)
        val second = ParameterKey(derivedId, 1)
        val derived =
            TypeDefinition(
                derivedId,
                parameters = listOf(TypeParameter(first, "A"), TypeParameter(second, "B")),
                representation = RepresentationTemplate.Record(emptyList()),
                parents =
                    listOf(
                        TypeTemplate.Named(baseId, listOf(TypeTemplate.Parameter(first))),
                        TypeTemplate.Named(marker.id),
                    ),
            )
        val catalog = catalog(base, marker, derived)

        catalog.knownApplications(
            TypeSelection.Pending(
                derivedId,
                listOf(ArgumentSelection.Chosen(TEXT), ArgumentSelection.Unfilled),
            ),
        ) shouldBe
            setOf(
                TypeUse.Named(baseId, listOf(TEXT)),
                TypeUse.Named(marker.id),
            )
        catalog.knownApplications(
            TypeSelection.Pending(
                derivedId,
                listOf(ArgumentSelection.Chosen(TEXT), ArgumentSelection.Chosen(TypeUse.Scalar(ScalarKind.Boolean))),
            ),
        ) shouldBe
            setOf(
                TypeUse.Named(derivedId, listOf(TEXT, TypeUse.Scalar(ScalarKind.Boolean))),
                TypeUse.Named(baseId, listOf(TEXT)),
                TypeUse.Named(marker.id),
            )
    }

    test("null and unfilled have distinct completeness") {
        val optional = optionalDefinition()
        val catalog = catalog(optional)
        val use = TypeUse.Named(optional.id)
        val checked = (catalog.resolve(use) as Resolution.Ready).value
        val unfinished =
            DataValue.Named(
                use,
                DataValue.Record(
                    mapOf(
                        "note" to DataValue.Null,
                        "count" to DataValue.Unfilled,
                    ),
                ),
            )

        (checked.complete(unfinished) is CompletenessResult.Unfinished) shouldBe true
        val invalidNull =
            DataValue.Named(
                use,
                DataValue.Record(mapOf("note" to DataValue.Null, "count" to DataValue.Null)),
            )
        (checked.complete(invalidNull) is CompletenessResult.Invalid) shouldBe true
    }

    test("named scalar identity remains while its payload is unfinished") {
        val code = TypeDefinition(id("code"), representation = RepresentationTemplate.Scalar(ScalarKind.Text))
        val catalog = catalog(code)
        val use = TypeUse.Named(code.id)
        val checked = (catalog.resolve(use) as Resolution.Ready).value

        val result = checked.complete(DataValue.Named(use, DataValue.Unfilled)) as CompletenessResult.Unfinished
        result.locations.size shouldBe 1
    }

    test("unknown record keys reject structural admission") {
        val simple = recordDefinition("simple", field("simple", "name", TEXT_TEMPLATE))
        val catalog = catalog(simple)
        val record =
            AuthoringRecord(
                TypeSelection.Complete(TypeUse.Named(simple.id)),
                mapOf("name" to DataValue.StringValue("ok"), "extra" to DataValue.StringValue("no")),
            )

        (record.validateStructure(catalog) as StructuralResult.Invalid).problems.map { it.code } shouldContainExactly
            listOf("unknown_field")
    }

    test("collection identities are stable but absent from canonical equality") {
        val list = listDefinition()
        val catalog = catalog(list)
        val use = TypeUse.Named(list.id, listOf(TEXT))
        val checked = (catalog.resolve(use) as Resolution.Ready).value
        val first = DataValue.Named(use, DataValue.ListValue(listOf(ListItem(ItemId("a"), DataValue.StringValue("one")))))
        val second = DataValue.Named(use, DataValue.ListValue(listOf(ListItem(ItemId("b"), DataValue.StringValue("one")))))
        val firstComplete = (checked.complete(first) as CompletenessResult.Complete).value
        val secondComplete = (checked.complete(second) as CompletenessResult.Complete).value

        DefaultCanonicalValueEquality.equivalent(firstComplete, secondComplete) shouldBe true
        DefaultCanonicalValueEquality.hash(firstComplete) shouldBe DefaultCanonicalValueEquality.hash(secondComplete)

        val duplicate =
            DataValue.Named(
                use,
                DataValue.ListValue(
                    listOf(
                        ListItem(ItemId("same"), DataValue.StringValue("one")),
                        ListItem(ItemId("same"), DataValue.StringValue("two")),
                    ),
                ),
            )
        (checked.complete(duplicate) as CompletenessResult.Invalid).problems.map { it.code } shouldContainExactly
            listOf("duplicate_item_id")
    }

    test("invalid nested declarations do not quarantine unrelated types") {
        val good = recordDefinition("good", field("good", "name", TEXT_TEMPLATE))
        val badId = id("bad")
        val missing = id("missing")
        val bad =
            TypeDefinition(
                badId,
                representation =
                    RepresentationTemplate.Record(
                        listOf(
                            FieldDeclaration(
                                FieldOwner(badId, "value"),
                                TypeTemplate.Nullable(TypeTemplate.Named(missing)),
                            ),
                        ),
                    ),
            )
        val catalog = catalog(good, bad)

        catalog.definition(good.id) shouldBe DeclarationStatus.Ready
        (catalog.definition(bad.id) is DeclarationStatus.Unavailable) shouldBe true
        (catalog.resolve(TypeUse.Named(good.id)) is Resolution.Ready) shouldBe true
    }

    test("catalog wire encoding preserves structured declaration provenance") {
        val owner =
            DeclarationOwner(
                source =
                    ContributionKey(
                        source = ContributionSourceId("extension.example"),
                        sourcePart = "realm",
                        producer = ProducerId("types"),
                        name = ContributionName("presentations/editor"),
                    ),
                localIdentity = "message.editor",
            )
        val snapshot =
            EditorCatalogSnapshot(
                generation = CatalogGeneration("catalog one"),
                types = emptyList(),
                relations = emptyList(),
                resourceDefinitions = emptyList(),
                presentations =
                    listOf(
                        PresentationDescriptor(
                            id = PresentationId("example", "editor"),
                            owner = owner,
                            target = PresentationTarget.Representation(com.typewritermc.configuration.RepresentationKind.Text),
                            roles = setOf(PresentationRole.EDITOR),
                            priority = 1,
                        ),
                    ),
                presentationMaterials = emptyList(),
                configuration = emptyList(),
                diagnostics = emptyList(),
                initialization = emptyList(),
                endpointBindings =
                    listOf(
                        EndpointBindingTemplate(
                            endpoint = EndpointId("menu.destination"),
                            containingResource = TypeTemplate.Named(id("menu")),
                            valueOwner = id("button"),
                            relativePath =
                                com.typewritermc.configuration.RelativeFieldPattern(
                                    listOf(
                                        com.typewritermc.configuration.FieldPatternSegment
                                            .Field("buttons"),
                                        com.typewritermc.configuration.FieldPatternSegment.Items,
                                        com.typewritermc.configuration.FieldPatternSegment
                                            .Field("destination"),
                                    ),
                                ),
                            target = TypeTemplate.Named(id("page")),
                            containsCollection = true,
                        ),
                    ),
            )

        val encoded =
            SkirTypeCodec
                .encode(snapshot)
                .getOrThrow()
                .presentations
                .single()
                .owner
        encoded.source.source.value shouldBe "extension.example"
        encoded.source.sourcePart shouldBe "realm"
        encoded.source.producer.value shouldBe "types"
        encoded.source.name.value shouldBe "presentations/editor"
        encoded.localIdentity shouldBe "message.editor"
        val binding =
            SkirTypeCodec
                .encode(snapshot)
                .getOrThrow()
                .endpointBindings
                .single()
        binding.endpoint.value shouldBe "menu.destination"
        binding.containsCollection shouldBe true
        binding.relativePath.segments.size shouldBe 3
        binding.valueOwner shouldBe SkirTypeCodec.encode(recordDefinition("button")).getOrThrow().id
    }

    test("data value codec preserves applied identity and rejects nonfinite floats") {
        val actual = TypeUse.Named(id("actual"))
        val value = DataValue.Named(actual, DataValue.Record(mapOf("value" to DataValue.StringValue("text"))))

        SkirDataValueCodec.decode(SkirDataValueCodec.encode(value).getOrThrow()).getOrThrow() shouldBe value
        (SkirDataValueCodec.encode(DataValue.Float(Double.NaN)) is SkirConversionResult.Failure) shouldBe true
    }

    test("authoring codecs reject duplicate root and nested record fields") {
        val fields =
            listOf(
                skirout.editor.v1.type_catalog.FieldValue(
                    name = "value",
                    value =
                        skirout.editor.v1.type_catalog.DataValue
                            .StringValueWrapper("first"),
                ),
                skirout.editor.v1.type_catalog.FieldValue(
                    name = "value",
                    value =
                        skirout.editor.v1.type_catalog.DataValue
                            .StringValueWrapper("second"),
                ),
            )
        val nested =
            SkirDataValueCodec.decode(
                skirout.editor.v1.type_catalog.DataValue
                    .createRecord(fields = fields),
            )
        val encodedRoot =
            SkirAuthoringValueCodec
                .encode(
                    AuthoringRecord(
                        configuration = TypeSelection.Complete(TypeUse.Named(id("duplicate_record"))),
                        fields = emptyMap(),
                    ),
                ).getOrThrow()
        val root = SkirAuthoringValueCodec.decode(encodedRoot.copy(fields = fields))

        (nested as SkirConversionResult.Failure).diagnostics.single().message shouldBe "Record field value is duplicated."
        (root as SkirConversionResult.Failure).diagnostics.single().message shouldBe "Record field value is duplicated."
    }

    test("presentation materials derive explicit field choices from their layout") {
        val binding =
            skirout.editor.v1.binding.BindingRef(
                path =
                    skirout.editor.v1.type_catalog.ValuePath(
                        segments =
                            listOf(
                                skirout.editor.v1.type_catalog.PathSegment
                                    .createField(name = "title"),
                            ),
                    ),
                bindingId =
                    skirout.editor.v1.type_catalog
                        .ExpressionBindingId(value = "configured_value"),
            )
        val selected = PresentationId("example", "title")
        val defaultNode =
            skirout.editor.v1.presentation.PresentationNode(
                nodeId = "default",
                properties =
                    skirout.editor.v1.presentation
                        .PresentationProperties(enabledIf = null, readOnly = false),
                element =
                    skirout.editor.v1.presentation.PresentationElement.createDefaultPresentation(
                        binding =
                            skirout.editor.v1.binding.BindingRef(
                                path =
                                    skirout.editor.v1.type_catalog
                                        .ValuePath(segments = emptyList()),
                                bindingId =
                                    skirout.editor.v1.type_catalog
                                        .ExpressionBindingId(value = "configured_value"),
                            ),
                        presentationId =
                            skirout.editor.v1.type_catalog.PresentationId(
                                namespace = selected.namespace,
                                name = selected.name,
                            ),
                    ),
                header = null,
            )
        val layout =
            skirout.editor.v1.presentation.PresentationNode(
                nodeId = "field",
                properties =
                    skirout.editor.v1.presentation
                        .PresentationProperties(enabledIf = null, readOnly = false),
                element =
                    skirout.editor.v1.presentation.PresentationElement.createTypedField(
                        binding = binding,
                        expectedType =
                            skirout.editor.v1.type_catalog.TypeTemplate.ScalarWrapper(
                                skirout.editor.v1.type_catalog.ScalarKind.TEXT,
                            ),
                        presentation = defaultNode,
                    ),
                header = null,
            )
        val material =
            PresentationMaterial(
                provider = PresentationId("example", "record"),
                target = PresentationTarget.Representation(com.typewritermc.configuration.RepresentationKind.Record),
                subject = TypeTemplate.Named(TypeDefinitionId(TypeId.Qualified("example", "record"), 1)),
                role = PresentationRole.EDITOR,
                layout = layout,
                dependencies =
                    skirout.editor.v1.presentation.PresentationDependencies
                        .partial(),
            )

        val choice = material.explicitFieldSelections().single()
        choice.field.segments shouldContainExactly
            listOf(
                com.typewritermc.configuration.FieldPatternSegment
                    .Field("title"),
            )
        choice.selected shouldBe selected

        val itemSelected = PresentationId("example", "buttonLabel")
        val itemPresentation =
            skirout.editor.v1.presentation.PresentationNode(
                nodeId = "item",
                properties =
                    skirout.editor.v1.presentation
                        .PresentationProperties(enabledIf = null, readOnly = false),
                element =
                    skirout.editor.v1.presentation.PresentationElement.createDefaultPresentation(
                        binding =
                            skirout.editor.v1.binding.BindingRef(
                                path =
                                    skirout.editor.v1.type_catalog.ValuePath(
                                        segments =
                                            listOf(
                                                skirout.editor.v1.type_catalog.PathSegment
                                                    .createField(name = "label"),
                                            ),
                                    ),
                                bindingId =
                                    skirout.editor.v1.type_catalog
                                        .ExpressionBindingId(value = "item"),
                            ),
                        presentationId =
                            skirout.editor.v1.type_catalog.PresentationId(
                                namespace = itemSelected.namespace,
                                name = itemSelected.name,
                            ),
                    ),
                header = null,
            )
        val repeated =
            skirout.editor.v1.presentation.PresentationNode(
                nodeId = "buttons",
                properties =
                    skirout.editor.v1.presentation
                        .PresentationProperties(enabledIf = null, readOnly = false),
                element =
                    skirout.editor.v1.presentation.PresentationElement.createRepeated(
                        source =
                            skirout.editor.v1.expression.ExpressionNode.createRead(
                                binding =
                                    skirout.editor.v1.type_catalog
                                        .ExpressionBindingId(value = "configured_value"),
                                path =
                                    skirout.editor.v1.type_catalog.ValuePath(
                                        segments =
                                            listOf(
                                                skirout.editor.v1.type_catalog.PathSegment
                                                    .createField(name = "buttons"),
                                            ),
                                    ),
                            ),
                        itemBindingId =
                            skirout.editor.v1.type_catalog
                                .ExpressionBindingId(value = "item"),
                        presentation =
                            skirout.editor.v1.presentation.SequencePresentation(
                                item = itemPresentation,
                                empty = null,
                                separator = null,
                                layout = skirout.editor.v1.presentation.SequenceLayout.UNKNOWN,
                            ),
                    ),
                header = null,
            )
        val repeatedChoice = material.copy(layout = repeated).explicitFieldSelections().single()
        repeatedChoice.field.segments shouldContainExactly
            listOf(
                com.typewritermc.configuration.FieldPatternSegment
                    .Field("buttons"),
                com.typewritermc.configuration.FieldPatternSegment.Items,
                com.typewritermc.configuration.FieldPatternSegment
                    .Field("label"),
            )
        repeatedChoice.selected shouldBe itemSelected
    }

    test("float32 admission requires the authored value to equal the native width") {
        val catalog = DefaultCheckedCatalog(CatalogGeneration("float32 admission"), emptyList())
        val checked =
            (
                catalog.resolve(TypeUse.Scalar(ScalarKind.Float(com.typewritermc.types.FloatWidth.FLOAT_32))) as
                    Resolution.Ready
            ).value

        val rejected = checked.complete(DataValue.Float(9.9999999))
        (rejected as CompletenessResult.Invalid).problems.single().code shouldBe "float32_precision_loss"

        val narrowed = 9.9999999f
        checked.complete(DataValue.Float(narrowed.toDouble())).shouldBeInstanceOf<CompletenessResult.Complete>()
    }
}

private val TEXT = TypeUse.Scalar(ScalarKind.Text)
private val TEXT_TEMPLATE = TypeTemplate.Scalar(ScalarKind.Text)

private fun catalog(vararg definitions: TypeDefinition) = DefaultCheckedCatalog(CatalogGeneration("test"), definitions.toList())

private fun id(name: String) = TypeDefinitionId(TypeId.Qualified("test", name), 1)

private fun field(
    owner: String,
    name: String,
    type: TypeTemplate,
) = FieldDeclaration(FieldOwner(id(owner), name), type)

private fun recordDefinition(
    name: String,
    vararg fields: FieldDeclaration,
): TypeDefinition = TypeDefinition(id(name), representation = RepresentationTemplate.Record(fields.toList()))

private fun resourceDefinition(): TypeDefinition {
    val id = id("resource")
    return TypeDefinition(
        id,
        representation =
            RepresentationTemplate.Record(
                listOf(FieldDeclaration(FieldOwner(id, "name"), TEXT_TEMPLATE)),
                abstract = true,
            ),
    )
}

private fun rewardDefinition(resource: TypeDefinitionId): TypeDefinition {
    val id = id("reward")
    return TypeDefinition(
        id,
        representation = RepresentationTemplate.Record(emptyList()),
        parents = listOf(TypeTemplate.Named(resource)),
    )
}

private fun weightedDefinition(): TypeDefinition {
    val id = id("weighted")
    val parameter = ParameterKey(id, 0)
    return TypeDefinition(
        id,
        parameters = listOf(TypeParameter(parameter, "T")),
        representation =
            RepresentationTemplate.Record(
                listOf(FieldDeclaration(FieldOwner(id, "value"), TypeTemplate.Parameter(parameter))),
            ),
    )
}

private fun variableDefinition(resource: TypeDefinitionId): TypeDefinition {
    val id = id("variable")
    val parameter = ParameterKey(id, 0)
    return TypeDefinition(
        id,
        parameters = listOf(TypeParameter(parameter, "T", listOf(TypeTemplate.Named(resource)))),
        representation =
            RepresentationTemplate.Record(
                listOf(FieldDeclaration(FieldOwner(id, "value"), TypeTemplate.Parameter(parameter))),
            ),
        parents = listOf(TypeTemplate.Named(resource)),
    )
}

private fun listDefinition(): TypeDefinition {
    val id = id("list")
    val parameter = ParameterKey(id, 0)
    return TypeDefinition(
        id,
        parameters = listOf(TypeParameter(parameter, "T")),
        representation = RepresentationTemplate.Sequence(TypeTemplate.Parameter(parameter), CollectionKind.List),
    )
}

private fun treeDefinition(list: TypeDefinitionId): TypeDefinition {
    val id = id("tree")
    val parameter = ParameterKey(id, 0)
    val tree = TypeTemplate.Named(id, listOf(TypeTemplate.Parameter(parameter)))
    return TypeDefinition(
        id,
        parameters = listOf(TypeParameter(parameter, "T")),
        representation =
            RepresentationTemplate.Record(
                listOf(
                    FieldDeclaration(
                        FieldOwner(id, "children"),
                        TypeTemplate.Named(list, listOf(tree)),
                    ),
                ),
            ),
    )
}

private fun optionalDefinition(): TypeDefinition {
    val id = id("optional")
    return TypeDefinition(
        id,
        representation =
            RepresentationTemplate.Record(
                listOf(
                    FieldDeclaration(FieldOwner(id, "note"), TypeTemplate.Nullable(TEXT_TEMPLATE)),
                    FieldDeclaration(FieldOwner(id, "count"), TypeTemplate.Scalar(ScalarKind.Integer(IntegerWidth.SIGNED_32))),
                ),
            ),
    )
}
