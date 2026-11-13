package com.typewritermc.types

import com.typewritermc.authoring.CompletenessResult
import com.typewritermc.authoring.complete
import com.typewritermc.authoring.of
import com.typewritermc.authoring.text
import com.typewritermc.authoring.validateStructure
import com.typewritermc.configuration.field
import com.typewritermc.configuration.of
import com.typewritermc.discovery.contributionKey
import com.typewritermc.imprint.ContributionName
import com.typewritermc.imprint.ContributionSourceId
import com.typewritermc.imprint.ProducerId
import com.typewritermc.presentation.of
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.catalog.ResourceType
import com.typewritermc.types.catalog.reasons
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import io.kotest.matchers.types.shouldBeSameInstanceAs
import skirout.editor.v1.catalog.DeclarationStatus
import skirout.editor.v1.catalog.EndpointBindingTemplate
import skirout.editor.v1.catalog.PresentationDescriptor
import skirout.editor.v1.catalog.PresentationRole
import skirout.editor.v1.catalog.PresentationTarget
import skirout.editor.v1.diagnostic.StructuralResult
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.DeclarationOwner
import skirout.editor.v1.type_catalog.EndpointId
import skirout.editor.v1.type_catalog.FieldDeclaration
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.FieldPatternSegment
import skirout.editor.v1.type_catalog.FieldValue
import skirout.editor.v1.type_catalog.FloatWidth
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.ListItem
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.PresentationId
import skirout.editor.v1.type_catalog.RecordForm
import skirout.editor.v1.type_catalog.RelativeFieldPattern
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeParameter
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.TypeTemplate
import skirout.editor.v1.type_catalog.TypeUse
import skirout.kernel.v1.resource_id.ResourceId

private val OWNER = ResourceId(value = "owner")

val TypeSystemFoundationTest by testSuite {
    test("definitions and complete uses remain distinct") {
        val weighted = weightedDefinition()
        val catalog = catalog(weighted)

        val missingArgument = catalog.resolve(weighted.id.use()) as Resolution.Invalid
        missingArgument.diagnostics.map { it.code } shouldContainExactly listOf("argument_arity")
        catalog.isReadableAs(weighted.id.use(), weighted.id.use()) shouldBe false

        val complete = weighted.id.use(listOf(TEXT))
        (catalog.resolve(complete) is Resolution.Ready) shouldBe true
    }

    test("deep type uses fail before resolver hashing and at the validation boundary") {
        var boundary: TypeUse = TEXT
        repeat(511) {
            boundary = boundary.nullable()
        }
        boundary.requireValid()
        val tooDeep = boundary.nullable()
        val resolution = catalog().resolve(tooDeep) as Resolution.Invalid

        resolution.diagnostics.map { it.code } shouldContainExactly listOf("type_depth_limit")
        shouldThrow<IllegalArgumentException> { tooDeep.requireValid() }
    }

    test("deep type templates use the same validation depth boundary") {
        var boundary: TypeTemplate = TEXT_TEMPLATE
        repeat(511) {
            boundary = boundary.nullable()
        }
        boundary.requireValid()

        shouldThrow<IllegalArgumentException> { boundary.nullable().requireValid() }
    }

    test("deep declaration templates are isolated before immutable catalog assembly") {
        var type: TypeTemplate = TEXT_TEMPLATE
        repeat(512) {
            type = type.nullable()
        }
        val definitionId = id("deep_declaration")
        val definition =
            TypeDefinition.partial(
                id = definitionId,
                representation =
                    RepresentationTemplate.createRecord(
                        fields =
                            listOf(
                                FieldDeclaration.partial(owner = FieldOwner(definition = definitionId, name = "value"), type = type),
                            ),
                        form = RecordForm.CONCRETE,
                    ),
            )

        val status = catalog(definition).definition(definitionId) as DeclarationStatus.UnavailableWrapper
        status.reasons.map { it.code } shouldContainExactly listOf("type_depth_limit")
    }

    test("checked catalogs own immutable declaration metadata") {
        val definitionId = id("immutable_source")
        val sourceFields =
            mutableListOf(
                FieldDeclaration.partial(owner = FieldOwner(definition = definitionId, name = "value"), type = TEXT_TEMPLATE),
            )
        val definition =
            TypeDefinition.partial(
                id = definitionId,
                representation = RepresentationTemplate.createRecord(fields = sourceFields, form = RecordForm.CONCRETE),
            )
        val catalog = catalog(definition)

        sourceFields.clear()
        sourceFields +=
            FieldDeclaration.partial(
                owner = FieldOwner(definition = definitionId, name = "replacement"),
                type = ScalarKind.BOOLEAN.template,
            )

        val resolved = catalog.resolve(definitionId.use()) as Resolution.Ready
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

        val rewardUse = reward.id.use()
        val valid = catalog.resolve(variable.id.use(listOf(rewardUse))) as Resolution.Ready
        valid.value.schema.fields
            .map { it.key } shouldContainExactly listOf("name", "value")
        valid.value.schema.fields
            .single { it.key == "name" }
            .declarationOwner shouldBe resource.id

        val invalid = catalog.resolve(variable.id.use(listOf(TEXT))) as Resolution.Invalid
        invalid.diagnostics.map { it.code } shouldContainExactly listOf("argument_bound")
    }

    test("a resolved field says whether a constructor may leave it out, through inheritance and overrides") {
        val parentId = id("defaults_parent")
        val parent =
            recordDefinition(
                "defaults_parent",
                field("defaults_parent", "level", TEXT_TEMPLATE).copy(hasConstructorDefault = true),
                field("defaults_parent", "title", TEXT_TEMPLATE).copy(hasConstructorDefault = true),
            )
        val childId = id("defaults_child")
        val child =
            recordDefinition(
                "defaults_child",
                field("defaults_child", "title", TEXT_TEMPLATE).copy(overrides = listOf(FieldOwner(definition = parentId, name = "title"))),
                field("defaults_child", "name", TEXT_TEMPLATE),
            ).copy(parents = listOf(parentId.namedTemplate()))

        val resolved = catalog(parent, child).resolve(childId.use()) as Resolution.Ready

        resolved.value.schema.fields
            .associate { it.key to it.hasConstructorDefault } shouldBe
            mapOf("level" to true, "title" to false, "name" to false)
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
        (catalog.resolve(variable.id.use()) is Resolution.Invalid) shouldBe true
    }

    test("explicit child overrides resolve shared parent fields") {
        val left = recordDefinition("left", field("left", "shared", TEXT_TEMPLATE))
        val right = recordDefinition("right", field("right", "shared", TEXT_TEMPLATE))
        val childId = id("child")
        val child =
            TypeDefinition.partial(
                id = childId,
                representation =
                    RepresentationTemplate.createRecord(
                        fields =
                            listOf(
                                FieldDeclaration.partial(
                                    owner = FieldOwner(definition = childId, name = "shared"),
                                    type = TEXT_TEMPLATE,
                                    overrides =
                                        listOf(
                                            FieldOwner(definition = left.id, name = "shared"),
                                            FieldOwner(definition = right.id, name = "shared"),
                                        ),
                                ),
                            ),
                        form = RecordForm.CONCRETE,
                    ),
                parents = listOf(left.id.namedTemplate(), right.id.namedTemplate()),
            )
        val unresolved =
            TypeDefinition.partial(
                id = id("unresolved_child"),
                representation = RepresentationTemplate.createRecord(fields = emptyList(), form = RecordForm.CONCRETE),
                parents = listOf(left.id.namedTemplate(), right.id.namedTemplate()),
            )
        val catalog = catalog(left, right, child, unresolved)

        val resolved = catalog.resolve(child.id.use()) as Resolution.Ready
        resolved.value.schema.fields
            .single()
            .declarationOwner shouldBe child.id
        val invalid = catalog.resolve(unresolved.id.use()) as Resolution.Invalid
        invalid.diagnostics.map { it.code } shouldContainExactly listOf("ambiguous_inherited_field")
    }

    test("generic covariance is readable while actual writes remain authoritative") {
        val resource = resourceDefinition()
        val reward = rewardDefinition(resource.id)
        val variable = variableDefinition(resource.id)
        val catalog = catalog(resource, reward, variable)
        val rewardUse = reward.id.use()
        val resourceUse = resource.id.namedUse()
        val actual = variable.id.namedUse(listOf(rewardUse))
        val broad = variable.id.use(listOf(resourceUse.use))

        catalog.isReadableAs(actual.use, broad) shouldBe true
        catalog.isReadableAs(broad, actual.use) shouldBe false

        val wrongWrite =
            AuthoringRecord.of(
                TypeSelection.of(actual),
                mapOf(
                    "name" to DataValue.StringValueWrapper("Variable"),
                    "value" to DataValue.named(resourceUse, DataValue.record(mapOf("name" to DataValue.StringValueWrapper("Broad")))),
                ),
            )
        (wrongWrite.validateStructure(OWNER, catalog) as StructuralResult.InvalidWrapper).value.map { it.code } shouldContainExactly
            listOf("unreadable_actual_type")
    }

    test("symbolic and concrete readability use the same catalog policy") {
        val resource = resourceDefinition()
        val reward = rewardDefinition(resource.id)
        val variable = variableDefinition(resource.id)
        val subject = id("symbolic_subject")
        val parameter = ParameterKey(owner = subject, index = 0)
        val catalog = catalog(resource, reward, variable)
        val rewardUse = reward.id.use()
        val resourceUse = resource.id.namedUse()
        val concreteActual = variable.id.use(listOf(rewardUse))
        val concreteExpected = variable.id.use(listOf(resourceUse.use))
        val symbolicActual = variable.id.template(listOf(parameter.template))
        val symbolicExpected = variable.id.template(listOf(resource.id.template()))

        catalog.isReadableAs(concreteActual, concreteExpected) shouldBe true
        catalog.isTemplateReadableAs(
            symbolicActual,
            symbolicExpected,
            mapOf(parameter to listOf(reward.id.template())),
        ) shouldBe true
        catalog.isTemplateReadableAs(symbolicExpected, symbolicActual) shouldBe false
    }

    test("generic concrete forms infer arguments from applied abstract parents") {
        val messageId = id("message")
        val messageParameter = ParameterKey(owner = messageId, index = 0)
        val message =
            TypeDefinition.partial(
                id = messageId,
                parameters = listOf(TypeParameter.partial(key = messageParameter, name = "T")),
                representation = RepresentationTemplate.createRecord(fields = emptyList(), form = RecordForm.OPEN),
            )
        val textMessageId = id("text_message")
        val textParameter = ParameterKey(owner = textMessageId, index = 0)
        val textMessage =
            TypeDefinition(
                id = textMessageId,
                parameters = listOf(TypeParameter.partial(key = textParameter, name = "T")),
                representation =
                    RepresentationTemplate.createRecord(
                        fields =
                            listOf(
                                FieldDeclaration.partial(
                                    owner = FieldOwner(definition = textMessageId, name = "payload"),
                                    type = textParameter.template,
                                ),
                            ),
                        form = RecordForm.CONCRETE,
                    ),
                parents = listOf(messageId.namedTemplate(listOf(textParameter.template))),
            )
        val catalog = catalog(message, textMessage)
        val expected = (catalog.resolve(messageId.use(listOf(TEXT))) as Resolution.Ready).value

        catalog.concreteForms(expected).map { it.use } shouldContainExactly
            listOf(textMessageId.use(listOf(TEXT)))
    }

    test("recursive generic records resolve only immediate fields") {
        val list = listDefinition()
        val tree = treeDefinition(list.id)
        val catalog = catalog(list, tree)
        val treeUse = tree.id.namedUse(listOf(TEXT))

        val resolved = catalog.resolve(treeUse.use) as Resolution.Ready
        resolved.value.schema.fields
            .single()
            .type shouldBe
            list.id.use(listOf(tree.id.use(listOf(TEXT))))
    }

    test("field narrowing retains direct and inherited generic argument bounds") {
        val resource = resourceDefinition()
        val variable = variableDefinition(resource.id)
        val parent = recordDefinition("bound_parent", field("bound_parent", "payload", resource.id.template()))
        val invalidParent =
            TypeDefinition.partial(
                id = id("invalid_bound_parent"),
                representation = RepresentationTemplate.createRecord(fields = emptyList(), form = RecordForm.CONCRETE),
                parents = listOf(variable.id.namedTemplate(listOf(TEXT_TEMPLATE))),
            )
        listOf(variable.id.template(listOf(TEXT_TEMPLATE)), invalidParent.id.template()).forEach { invalidType ->
            val child =
                TypeDefinition.partial(
                    id = id("bound_child"),
                    representation =
                        RepresentationTemplate.createRecord(
                            fields =
                                listOf(
                                    FieldDeclaration.partial(
                                        owner = FieldOwner(definition = id("bound_child"), name = "payload"),
                                        type = invalidType,
                                        overrides = listOf(FieldOwner(definition = parent.id, name = "payload")),
                                    ),
                                ),
                            form = RecordForm.CONCRETE,
                        ),
                    parents = listOf(parent.id.namedTemplate()),
                )
            val resolved = catalog(resource, variable, parent, invalidParent, child).resolve(child.id.use())
            (resolved is Resolution.Invalid) shouldBe true
            (resolved as Resolution.Invalid).diagnostics.map { it.code } shouldContainExactly listOf("invalid_field_narrowing")
        }
    }

    test("mutually narrowed page and entry references resolve in either lookup order") {
        val page = id("mutual_page")
        val element = id("mutual_element")
        val sequencePage = id("mutual_sequence_page")
        val sequenceEntry = id("mutual_sequence_entry")
        val pageLink = id("mutual_page_link")
        val elementLink = id("mutual_element_link")
        val list = listDefinition()

        val declarations =
            listOf(
                list,
                linkDefinition(pageLink),
                linkDefinition(elementLink),
                fieldRecord(page, "elements", elementsOf(list.id, elementLink, element)),
                fieldRecord(element, "page", referenceTo(pageLink, page)),
                fieldRecord(sequencePage, "elements", elementsOf(list.id, elementLink, sequenceEntry), page),
                fieldRecord(sequenceEntry, "page", referenceTo(pageLink, sequencePage), element),
            )
        val unrelatedEntry = fieldRecord(id("mutual_unrelated_entry"), "page", referenceTo(pageLink, element), element)
        val invalid =
            catalog(
                *(declarations + unrelatedEntry).toTypedArray(),
            ).resolve(unrelatedEntry.id.use()) as Resolution.Invalid
        invalid.diagnostics.map { it.code } shouldContainExactly listOf("invalid_field_narrowing")
        listOf(listOf(sequencePage, sequenceEntry), listOf(sequenceEntry, sequencePage)).forEach { order ->
            val checked = catalog(*declarations.toTypedArray())
            order.forEach { definition -> (checked.resolve(definition.use()) is Resolution.Ready) shouldBe true }
            (checked.resolve(sequencePage.use()) as Resolution.Ready)
                .value.schema.fields
                .single()
                .type shouldBe
                list.id.use(listOf(elementLink.use(listOf(sequenceEntry.use()))))
            (checked.resolve(sequenceEntry.use()) as Resolution.Ready)
                .value.schema.fields
                .single()
                .type shouldBe
                pageLink.use(listOf(sequencePage.use()))
        }
    }

    test("deep authored values return a bounded admission diagnostic") {
        val list = listDefinition()
        val tree = treeDefinition(list.id)
        val catalog = catalog(list, tree)
        val treeUse = tree.id.namedUse(listOf(TEXT))
        val listUse = list.id.namedUse(listOf(treeUse.use))
        val checked = (catalog.resolve(treeUse.use) as Resolution.Ready).value
        var value: DataValue =
            DataValue.named(
                treeUse,
                DataValue.record(mapOf("children" to DataValue.named(listUse, DataValue.listValue(emptyList())))),
            )
        repeat(600) { depth ->
            value =
                DataValue.named(
                    treeUse,
                    DataValue.record(
                        mapOf(
                            "children" to
                                DataValue.named(
                                    listUse,
                                    DataValue.listValue(listOf(ListItem(id = ItemId(value = "item$depth"), value = value))),
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
        val parameter = ParameterKey(owner = familyId, index = 0)
        val family =
            TypeDefinition.partial(
                id = familyId,
                parameters =
                    listOf(
                        TypeParameter(key = parameter, name = "T", bounds = listOf(familyId.template(listOf(parameter.template)))),
                    ),
                representation = RepresentationTemplate.createRecord(fields = emptyList(), form = RecordForm.OPEN),
            )
        val concrete =
            TypeDefinition.partial(
                id = id("recursive_concrete"),
                representation = RepresentationTemplate.createRecord(fields = emptyList(), form = RecordForm.CONCRETE),
                parents = listOf(familyId.namedTemplate(listOf(id("recursive_concrete").template()))),
            )
        val catalog = catalog(family, concrete)

        val resolution = catalog.resolve(concrete.id.use()) as Resolution.Invalid
        resolution.diagnostics.map { it.code } shouldContainExactly listOf("recursive_type_resolution")
    }

    test("recursive generic bounds through nullable return a declaration diagnostic") {
        val familyId = id("nullable_recursive_family")
        val concreteId = id("nullable_recursive_concrete")
        val parameter = ParameterKey(owner = familyId, index = 0)
        val family =
            TypeDefinition.partial(
                id = familyId,
                parameters =
                    listOf(
                        TypeParameter(
                            key = parameter,
                            name = "T",
                            bounds =
                                listOf(
                                    familyId.template(listOf(parameter.template)).nullable(),
                                ),
                        ),
                    ),
                representation = RepresentationTemplate.createRecord(fields = emptyList(), form = RecordForm.OPEN),
            )
        val concrete =
            TypeDefinition.partial(
                id = concreteId,
                representation = RepresentationTemplate.createRecord(fields = emptyList(), form = RecordForm.CONCRETE),
                parents = listOf(familyId.namedTemplate(listOf(concreteId.template()))),
            )
        val catalog = catalog(family, concrete)

        val resolution = catalog.resolve(concrete.id.use()) as Resolution.Invalid
        resolution.diagnostics.map { it.code } shouldContainExactly listOf("recursive_type_resolution")
    }

    test("canonical equality distinguishes nested collections from sibling items") {
        val list = listDefinition()
        val tree = treeDefinition(list.id)
        val catalog = catalog(list, tree)
        val treeUse = tree.id.namedUse(listOf(TEXT))
        val listUse = list.id.namedUse(listOf(treeUse.use))
        val checked = (catalog.resolve(listUse.use) as Resolution.Ready).value

        val leaf = nodeValue(treeUse, listUse, emptyList())
        val nested =
            (
                checked.complete(
                    sequenceValue(listUse, listOf(nodeValue(treeUse, listUse, listOf(leaf, leaf)))),
                ) as CompletenessResult.Complete
            ).value
        val siblings =
            (
                checked.complete(
                    sequenceValue(listUse, listOf(nodeValue(treeUse, listUse, listOf(leaf)), leaf)),
                ) as CompletenessResult.Complete
            ).value

        DefaultCanonicalValueEquality.equivalent(nested, siblings) shouldBe false
        (DefaultCanonicalValueEquality.hash(nested) == DefaultCanonicalValueEquality.hash(siblings)) shouldBe false
    }

    test("pending arguments preserve inherited independent fields") {
        val resource = resourceDefinition()
        val variable = variableDefinition(resource.id)
        val catalog = catalog(resource, variable)

        val partial = (catalog.typeOf(OWNER, TypeSelection.of(variable.id)) as Resolution.Ready).value as ResourceType.Partial

        partial.schema.knownFields.map { it.key } shouldContainExactly listOf("name")
        partial.schema.dependentFields.map { it.owner.name } shouldContainExactly listOf("value")
    }

    test("a selection with an argument chosen for every parameter is the complete type") {
        val resource = resourceDefinition()
        val variable = variableDefinition(resource.id)
        val catalog = catalog(resource, variable)

        val type = (catalog.typeOf(OWNER, TypeSelection.of(variable.id, mapOf(0 to resource.id.use()))) as Resolution.Ready).value

        (type as ResourceType.Complete).checked.use shouldBe variable.id.use(listOf(resource.id.use()))
        type.knownFields.map { it.key } shouldContainExactly listOf("name", "value")
    }

    test("a choice for a parameter the definition does not have is an arity problem") {
        val resource = resourceDefinition()
        val variable = variableDefinition(resource.id)
        val catalog = catalog(resource, variable)

        val type = catalog.typeOf(OWNER, TypeSelection.of(variable.id, mapOf(1 to resource.id.use())))

        (type as Resolution.Invalid).diagnostics.map { it.code } shouldContainExactly listOf("argument_arity")
    }

    test("known applications include only fully bound selected and inherited uses") {
        val baseId = id("known_base")
        val baseParameter = ParameterKey(owner = baseId, index = 0)
        val base =
            TypeDefinition.partial(
                id = baseId,
                parameters = listOf(TypeParameter.partial(key = baseParameter, name = "T")),
                representation = RepresentationTemplate.createRecord(fields = emptyList(), form = RecordForm.OPEN),
            )
        val marker = recordDefinition("known_marker")
        val derivedId = id("known_derived")
        val first = ParameterKey(owner = derivedId, index = 0)
        val second = ParameterKey(owner = derivedId, index = 1)
        val derived =
            TypeDefinition(
                id = derivedId,
                parameters =
                    listOf(
                        TypeParameter.partial(key = first, name = "A"),
                        TypeParameter.partial(key = second, name = "B"),
                    ),
                representation = RepresentationTemplate.createRecord(fields = emptyList(), form = RecordForm.CONCRETE),
                parents = listOf(baseId.namedTemplate(listOf(first.template)), marker.id.namedTemplate()),
            )
        val catalog = catalog(base, marker, derived)

        catalog.knownApplications(TypeSelection.of(derivedId, mapOf(0 to TEXT))) shouldBe
            setOf(
                baseId.namedUse(listOf(TEXT)),
                marker.id.namedUse(),
            )
        catalog.knownApplications(TypeSelection.of(derivedId, mapOf(0 to TEXT, 1 to ScalarKind.BOOLEAN.use))) shouldBe
            setOf(
                derivedId.namedUse(listOf(TEXT, ScalarKind.BOOLEAN.use)),
                baseId.namedUse(listOf(TEXT)),
                marker.id.namedUse(),
            )
    }

    test("null and unfilled have distinct completeness") {
        val optional = optionalDefinition()
        val catalog = catalog(optional)
        val use = optional.id.namedUse()
        val checked = (catalog.resolve(use.use) as Resolution.Ready).value
        val unfinished =
            DataValue.named(
                use,
                DataValue.record(
                    mapOf(
                        "note" to DataValue.NULL,
                        "count" to DataValue.UNFILLED,
                    ),
                ),
            )

        (checked.complete(unfinished) as CompletenessResult.Unfinished).locations.map { it.path.text } shouldContainExactly listOf("count")
        val invalidNull =
            DataValue.named(
                use,
                DataValue.record(mapOf("note" to DataValue.NULL, "count" to DataValue.NULL)),
            )
        (checked.complete(invalidNull) as CompletenessResult.Invalid).problems.map { it.location.path.text to it.code } shouldContainExactly
            listOf("count" to "wrong_scalar")
    }

    test("named scalar identity remains while its payload is unfinished") {
        val code =
            TypeDefinition.partial(id = id("code"), representation = RepresentationTemplate.createScalar(kind = ScalarKind.TEXT))
        val catalog = catalog(code)
        val use = code.id.namedUse()
        val checked = (catalog.resolve(use.use) as Resolution.Ready).value

        val result = checked.complete(DataValue.named(use, DataValue.UNFILLED)) as CompletenessResult.Unfinished
        result.locations.map { it.path.text } shouldContainExactly listOf("")
    }

    test("unknown record keys reject structural admission") {
        val simple = recordDefinition("simple", field("simple", "name", TEXT_TEMPLATE))
        val catalog = catalog(simple)
        val record =
            AuthoringRecord.of(
                TypeSelection.of(simple.id.namedUse()),
                mapOf("name" to DataValue.StringValueWrapper("ok"), "extra" to DataValue.StringValueWrapper("no")),
            )

        (record.validateStructure(OWNER, catalog) as StructuralResult.InvalidWrapper).value.map { it.code } shouldContainExactly
            listOf("unknown_field")
    }

    test("collection identities are stable but absent from canonical equality") {
        val list = listDefinition()
        val catalog = catalog(list)
        val use = list.id.namedUse(listOf(TEXT))
        val checked = (catalog.resolve(use.use) as Resolution.Ready).value
        val first =
            DataValue.named(
                use,
                DataValue.listValue(listOf(ListItem(id = ItemId(value = "a"), value = DataValue.StringValueWrapper("one")))),
            )
        val second =
            DataValue.named(
                use,
                DataValue.listValue(listOf(ListItem(id = ItemId(value = "b"), value = DataValue.StringValueWrapper("one")))),
            )
        val firstComplete = (checked.complete(first) as CompletenessResult.Complete).value
        val secondComplete = (checked.complete(second) as CompletenessResult.Complete).value

        DefaultCanonicalValueEquality.equivalent(firstComplete, secondComplete) shouldBe true
        DefaultCanonicalValueEquality.hash(firstComplete) shouldBe DefaultCanonicalValueEquality.hash(secondComplete)
    }

    test("a list with two items under one id is invalid") {
        val list = listDefinition()
        val catalog = catalog(list)
        val use = list.id.namedUse(listOf(TEXT))
        val checked = (catalog.resolve(use.use) as Resolution.Ready).value
        val duplicate =
            DataValue.named(
                use,
                DataValue.listValue(
                    listOf(
                        ListItem(id = ItemId(value = "same"), value = DataValue.StringValueWrapper("one")),
                        ListItem(id = ItemId(value = "same"), value = DataValue.StringValueWrapper("two")),
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
            TypeDefinition.partial(
                id = badId,
                representation =
                    RepresentationTemplate.createRecord(
                        fields =
                            listOf(
                                FieldDeclaration.partial(
                                    owner = FieldOwner(definition = badId, name = "value"),
                                    type = missing.template().nullable(),
                                ),
                            ),
                        form = RecordForm.CONCRETE,
                    ),
            )
        val catalog = catalog(good, bad)

        catalog.definition(good.id) shouldBe DeclarationStatus.READY
        (catalog.definition(bad.id) is DeclarationStatus.UnavailableWrapper) shouldBe true
        (catalog.resolve(good.id.use()) is Resolution.Ready) shouldBe true
    }

    test("a presentation and an endpoint binding keep their declaration provenance through the wire") {
        val owner =
            DeclarationOwner(
                source =
                    contributionKey(
                        source = ContributionSourceId("extension.example"),
                        sourcePart = "realm",
                        producer = ProducerId("types"),
                        name = ContributionName("presentations/editor"),
                    ),
                localIdentity = "message.editor",
            )
        val presentation =
            PresentationDescriptor.of(
                id = PresentationId(namespace = "example", name = "editor"),
                owner = owner,
                target = PresentationTarget.RepresentationWrapper(skirout.editor.v1.catalog.RepresentationKind.TEXT),
                roles = setOf(PresentationRole.WORKSPACE),
                priority = 1,
            )
        val endpointBinding =
            EndpointBindingTemplate(
                endpoint = EndpointId(value = "menu.destination"),
                containingResource = id("menu").namedTemplate(),
                valueOwner = id("button"),
                relativePath =
                    RelativeFieldPattern.of(
                        FieldPatternSegment.field("buttons"),
                        FieldPatternSegment.ITEMS,
                        FieldPatternSegment.field("destination"),
                    ),
                target = id("page").template(),
                containsCollection = true,
            )

        val decoded = PresentationDescriptor.serializer.fromBytes(PresentationDescriptor.serializer.toBytes(presentation).toByteArray())
        decoded.owner shouldBe owner
        EndpointBindingTemplate.serializer
            .fromBytes(EndpointBindingTemplate.serializer.toBytes(endpointBinding).toByteArray())
            .requireValid() shouldBe endpointBinding
    }

    test("the portable check keeps canonical values and rejects nonfinite floats") {
        val actual = id("actual").namedUse()
        val value = DataValue.named(actual, DataValue.record(mapOf("value" to DataValue.StringValueWrapper("text"))))

        value.requirePortable() shouldBeSameInstanceAs value
        shouldThrow<IllegalArgumentException> { DataValue.FloatWrapper(Double.NaN).requirePortable() }
        shouldThrow<IllegalArgumentException> { DataValue.UNKNOWN.requirePortable() }
        shouldThrow<IllegalArgumentException> {
            DataValue.listValue(listOf(ListItem(id = ItemId(value = " "), value = DataValue.NULL))).requirePortable()
        }
        shouldThrow<IllegalArgumentException> { DataValue.DecimalWrapper("01.5").requirePortable() }
        shouldThrow<IllegalArgumentException> { DataValue.IntegerWrapper("seven").requirePortable() }
    }

    test("the portable check restores record field order and integer notation") {
        val unordered =
            DataValue.createRecord(
                fields =
                    listOf(
                        FieldValue(name = "second", value = DataValue.IntegerWrapper("007")),
                        FieldValue(name = "first", value = DataValue.IntegerWrapper("-0")),
                    ),
            )

        unordered.requirePortable() shouldBe DataValue.record("first" to DataValue.integer(0), "second" to DataValue.integer(7))
    }

    test("authoring record checks reject duplicate root and nested record fields") {
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
            shouldThrow<IllegalArgumentException> {
                skirout.editor.v1.type_catalog.DataValue
                    .createRecord(fields = fields)
                    .requirePortable()
            }
        val root =
            shouldThrow<IllegalArgumentException> {
                AuthoringRecord(
                    configuration = TypeSelection.of(id("duplicate_record").namedUse()),
                    fields = fields,
                    types = emptyList(),
                ).requireValid()
            }

        nested.message shouldBe "Record field value is duplicated."
        root.message shouldBe "Record field value is duplicated."
    }

    test("float32 admission requires the authored value to equal the native width") {
        val catalog = DefaultCheckedCatalog(CatalogGeneration(value = "float32 admission"), emptyList())
        val checked =
            (
                catalog.resolve(floatScalar(FloatWidth.THIRTY_TWO).use) as
                    Resolution.Ready
            ).value

        val rejected = checked.complete(DataValue.FloatWrapper(9.9999999))
        (rejected as CompletenessResult.Invalid).problems.single().code shouldBe "float32_precision_loss"

        val narrowed = 9.9999999f
        checked.complete(DataValue.FloatWrapper(narrowed.toDouble())).shouldBeInstanceOf<CompletenessResult.Complete>()
    }
}
