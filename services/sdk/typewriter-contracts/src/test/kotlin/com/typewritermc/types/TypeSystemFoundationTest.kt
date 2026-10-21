package com.typewritermc.types

import com.typewritermc.authoring.CompletenessResult
import com.typewritermc.authoring.StructuralResult
import com.typewritermc.authoring.complete
import com.typewritermc.authoring.of
import com.typewritermc.authoring.validateStructure
import com.typewritermc.configuration.field
import com.typewritermc.configuration.of
import com.typewritermc.discovery.contributionKey
import com.typewritermc.imprint.ContributionName
import com.typewritermc.imprint.ContributionSourceId
import com.typewritermc.imprint.ProducerId
import com.typewritermc.presentation.PresentationDescriptor
import com.typewritermc.presentation.PresentationTarget
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.catalog.reasons
import com.typewritermc.types.skir.SkirTypeCodec
import com.typewritermc.types.skir.getOrThrow
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import io.kotest.matchers.types.shouldBeSameInstanceAs
import skirout.editor.v1.catalog.DeclarationStatus
import skirout.editor.v1.catalog.EndpointBindingTemplate
import skirout.editor.v1.catalog.PresentationRole
import skirout.editor.v1.type_catalog.ArgumentSelection
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.CollectionKind
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.DeclarationOwner
import skirout.editor.v1.type_catalog.EndpointId
import skirout.editor.v1.type_catalog.FieldDeclaration
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.FieldPatternSegment
import skirout.editor.v1.type_catalog.FieldValue
import skirout.editor.v1.type_catalog.FloatWidth
import skirout.editor.v1.type_catalog.IntegerWidth
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.ListItem
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.PresentationId
import skirout.editor.v1.type_catalog.RelativeFieldPattern
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeParameter
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.TypeTemplate
import skirout.editor.v1.type_catalog.TypeUse

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
                        abstract_ = false,
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
                representation = RepresentationTemplate.createRecord(fields = sourceFields, abstract_ = false),
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
                        abstract_ = false,
                    ),
                parents = listOf(left.id.namedTemplate(), right.id.namedTemplate()),
            )
        val unresolved =
            TypeDefinition.partial(
                id = id("unresolved_child"),
                representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
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
                TypeSelection.CompleteWrapper(actual),
                mapOf(
                    "name" to DataValue.StringValueWrapper("Variable"),
                    "value" to DataValue.named(resourceUse, DataValue.record(mapOf("name" to DataValue.StringValueWrapper("Broad")))),
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
        val parameter = ParameterKey(owner = subject, index = 0)
        val catalog = catalog(resource, reward, variable)
        val rewardUse = reward.id.use()
        val resourceUse = resource.id.namedUse()
        val concreteActual = variable.id.use(listOf(rewardUse))
        val concreteExpected = variable.id.use(listOf(resourceUse.use))
        val symbolicActual = variable.id.template(listOf(parameter.template))
        val symbolicExpected = variable.id.template(listOf(resource.id.template()))

        catalog.isTemplateReadableAs(
            symbolicActual,
            symbolicExpected,
            mapOf(parameter to listOf(reward.id.template())),
        ) shouldBe catalog.isReadableAs(concreteActual, concreteExpected)
        catalog.isTemplateReadableAs(symbolicExpected, symbolicActual) shouldBe false
    }

    test("generic concrete forms infer arguments from applied abstract parents") {
        val messageId = id("message")
        val messageParameter = ParameterKey(owner = messageId, index = 0)
        val message =
            TypeDefinition.partial(
                id = messageId,
                parameters = listOf(TypeParameter.partial(key = messageParameter, name = "T")),
                representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = true),
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
                        abstract_ = false,
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
                representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
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
                            abstract_ = false,
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

        fun link(definition: TypeDefinitionId) =
            TypeDefinition.partial(
                id = definition,
                parameters = listOf(TypeParameter.partial(key = ParameterKey(owner = definition, index = 0), name = "T")),
                representation =
                    RepresentationTemplate.createLink(
                        endpoint = EndpointId(value = definition.toString()),
                        target = ParameterKey(owner = definition, index = 0).template,
                    ),
            )

        fun reference(
            link: TypeDefinitionId,
            target: TypeDefinitionId,
        ) = link.template(listOf(target.template()))

        fun elements(target: TypeDefinitionId) = list.id.template(listOf(reference(elementLink, target)))

        fun record(
            definition: TypeDefinitionId,
            name: String,
            type: TypeTemplate,
            parent: TypeDefinitionId? = null,
        ) = TypeDefinition.partial(
            id = definition,
            representation =
                RepresentationTemplate.createRecord(
                    fields =
                        listOf(
                            FieldDeclaration.partial(
                                owner = FieldOwner(definition = definition, name = name),
                                type = type,
                                overrides =
                                    parent
                                        ?.let {
                                            listOf(FieldOwner(definition = it, name = name))
                                        }.orEmpty(),
                            ),
                        ),
                    abstract_ = parent == null,
                ),
            parents = parent?.let { listOf(it.namedTemplate()) }.orEmpty(),
        )
        val declarations =
            listOf(
                list,
                link(pageLink),
                link(elementLink),
                record(page, "elements", elements(element)),
                record(element, "page", reference(pageLink, page)),
                record(sequencePage, "elements", elements(sequenceEntry), page),
                record(sequenceEntry, "page", reference(pageLink, sequencePage), element),
            )
        val unrelatedEntry = record(id("mutual_unrelated_entry"), "page", reference(pageLink, element), element)
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
                representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = true),
            )
        val concrete =
            TypeDefinition.partial(
                id = id("recursive_concrete"),
                representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
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
                representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = true),
            )
        val concrete =
            TypeDefinition.partial(
                id = concreteId,
                representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
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

        fun sequence(children: List<DataValue>): DataValue =
            DataValue.named(
                listUse,
                DataValue.listValue(children.mapIndexed { index, value -> ListItem(id = ItemId(value = "item$index"), value = value) }),
            )

        fun node(children: List<DataValue>): DataValue = DataValue.named(treeUse, DataValue.record(mapOf("children" to sequence(children))))
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
                TypeSelection.createPending(definition = variable.id, arguments = listOf(ArgumentSelection.UNFILLED)),
            ) as Resolution.Ready

        partial.value.knownFields.map { it.key } shouldContainExactly listOf("name")
        partial.value.dependentFields.map { it.owner.name } shouldContainExactly listOf("value")
    }

    test("known applications include only fully bound selected and inherited uses") {
        val baseId = id("known_base")
        val baseParameter = ParameterKey(owner = baseId, index = 0)
        val base =
            TypeDefinition.partial(
                id = baseId,
                parameters = listOf(TypeParameter.partial(key = baseParameter, name = "T")),
                representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = true),
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
                representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
                parents = listOf(baseId.namedTemplate(listOf(first.template)), marker.id.namedTemplate()),
            )
        val catalog = catalog(base, marker, derived)

        catalog.knownApplications(
            TypeSelection.createPending(
                definition = derivedId,
                arguments = listOf(ArgumentSelection.ChosenWrapper(TEXT), ArgumentSelection.UNFILLED),
            ),
        ) shouldBe
            setOf(
                baseId.namedUse(listOf(TEXT)),
                marker.id.namedUse(),
            )
        catalog.knownApplications(
            TypeSelection.createPending(
                definition = derivedId,
                arguments = listOf(ArgumentSelection.ChosenWrapper(TEXT), ArgumentSelection.ChosenWrapper(ScalarKind.BOOLEAN.use)),
            ),
        ) shouldBe
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

        (checked.complete(unfinished) is CompletenessResult.Unfinished) shouldBe true
        val invalidNull =
            DataValue.named(
                use,
                DataValue.record(mapOf("note" to DataValue.NULL, "count" to DataValue.NULL)),
            )
        (checked.complete(invalidNull) is CompletenessResult.Invalid) shouldBe true
    }

    test("named scalar identity remains while its payload is unfinished") {
        val code =
            TypeDefinition.partial(id = id("code"), representation = RepresentationTemplate.createScalar(kind = ScalarKind.TEXT))
        val catalog = catalog(code)
        val use = code.id.namedUse()
        val checked = (catalog.resolve(use.use) as Resolution.Ready).value

        val result = checked.complete(DataValue.named(use, DataValue.UNFILLED)) as CompletenessResult.Unfinished
        result.locations.size shouldBe 1
    }

    test("unknown record keys reject structural admission") {
        val simple = recordDefinition("simple", field("simple", "name", TEXT_TEMPLATE))
        val catalog = catalog(simple)
        val record =
            AuthoringRecord.of(
                TypeSelection.CompleteWrapper(simple.id.namedUse()),
                mapOf("name" to DataValue.StringValueWrapper("ok"), "extra" to DataValue.StringValueWrapper("no")),
            )

        (record.validateStructure(catalog) as StructuralResult.Invalid).problems.map { it.code } shouldContainExactly
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
                        abstract_ = false,
                    ),
            )
        val catalog = catalog(good, bad)

        catalog.definition(good.id) shouldBe DeclarationStatus.READY
        (catalog.definition(bad.id) is DeclarationStatus.UnavailableWrapper) shouldBe true
        (catalog.resolve(good.id.use()) is Resolution.Ready) shouldBe true
    }

    test("catalog wire encoding preserves structured declaration provenance") {
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
            PresentationDescriptor(
                id = PresentationId(namespace = "example", name = "editor"),
                owner = owner,
                target = PresentationTarget.Representation(skirout.editor.v1.catalog.RepresentationKind.TEXT),
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

        val encoded = SkirTypeCodec.encode(presentation).getOrThrow().owner
        encoded.source.source.value shouldBe "extension.example"
        encoded.source.sourcePart shouldBe "realm"
        encoded.source.producer.value shouldBe "types"
        encoded.source.name.value shouldBe "presentations/editor"
        encoded.localIdentity shouldBe "message.editor"
        endpointBinding.requireValid() shouldBe endpointBinding
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
            shouldThrow<IllegalArgumentException> {
                skirout.editor.v1.type_catalog.DataValue
                    .createRecord(fields = fields)
                    .requirePortable()
            }
        val root =
            shouldThrow<IllegalArgumentException> {
                AuthoringRecord(
                    configuration = TypeSelection.CompleteWrapper(id("duplicate_record").namedUse()),
                    fields = fields,
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

private val TEXT = ScalarKind.TEXT.use
private val TEXT_TEMPLATE = ScalarKind.TEXT.template

private fun catalog(vararg definitions: TypeDefinition) = DefaultCheckedCatalog(CatalogGeneration(value = "test"), definitions.toList())

private fun id(name: String) = TypeDefinitionId.qualified("test", name)

private fun field(
    owner: String,
    name: String,
    type: TypeTemplate,
) = FieldDeclaration.partial(owner = FieldOwner(definition = id(owner), name = name), type = type)

private fun recordDefinition(
    name: String,
    vararg fields: FieldDeclaration,
): TypeDefinition =
    TypeDefinition.partial(id = id(name), representation = RepresentationTemplate.createRecord(fields = fields.toList(), abstract_ = false))

private fun resourceDefinition(): TypeDefinition {
    val id = id("resource")
    return TypeDefinition.partial(
        id = id,
        representation =
            RepresentationTemplate.createRecord(
                fields =
                    listOf(
                        FieldDeclaration.partial(owner = FieldOwner(definition = id, name = "name"), type = TEXT_TEMPLATE),
                    ),
                abstract_ = true,
            ),
    )
}

private fun rewardDefinition(resource: TypeDefinitionId): TypeDefinition {
    val id = id("reward")
    return TypeDefinition.partial(
        id = id,
        representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
        parents = listOf(resource.namedTemplate()),
    )
}

private fun weightedDefinition(): TypeDefinition {
    val id = id("weighted")
    val parameter = ParameterKey(owner = id, index = 0)
    return TypeDefinition.partial(
        id = id,
        parameters = listOf(TypeParameter.partial(key = parameter, name = "T")),
        representation =
            RepresentationTemplate.createRecord(
                fields =
                    listOf(
                        FieldDeclaration.partial(owner = FieldOwner(definition = id, name = "value"), type = parameter.template),
                    ),
                abstract_ = false,
            ),
    )
}

private fun variableDefinition(resource: TypeDefinitionId): TypeDefinition {
    val id = id("variable")
    val parameter = ParameterKey(owner = id, index = 0)
    return TypeDefinition(
        id = id,
        parameters = listOf(TypeParameter(key = parameter, name = "T", bounds = listOf(resource.template()))),
        representation =
            RepresentationTemplate.createRecord(
                fields =
                    listOf(
                        FieldDeclaration.partial(owner = FieldOwner(definition = id, name = "value"), type = parameter.template),
                    ),
                abstract_ = false,
            ),
        parents = listOf(resource.namedTemplate()),
    )
}

private fun listDefinition(): TypeDefinition {
    val id = id("list")
    val parameter = ParameterKey(owner = id, index = 0)
    return TypeDefinition.partial(
        id = id,
        parameters = listOf(TypeParameter.partial(key = parameter, name = "T")),
        representation = RepresentationTemplate.createSequence(item = parameter.template, kind = CollectionKind.LIST),
    )
}

private fun treeDefinition(list: TypeDefinitionId): TypeDefinition {
    val id = id("tree")
    val parameter = ParameterKey(owner = id, index = 0)
    val tree = id.template(listOf(parameter.template))
    return TypeDefinition.partial(
        id = id,
        parameters = listOf(TypeParameter.partial(key = parameter, name = "T")),
        representation =
            RepresentationTemplate.createRecord(
                fields =
                    listOf(
                        FieldDeclaration.partial(
                            owner = FieldOwner(definition = id, name = "children"),
                            type = list.template(listOf(tree)),
                        ),
                    ),
                abstract_ = false,
            ),
    )
}

private fun optionalDefinition(): TypeDefinition {
    val id = id("optional")
    return TypeDefinition.partial(
        id = id,
        representation =
            RepresentationTemplate.createRecord(
                fields =
                    listOf(
                        FieldDeclaration.partial(owner = FieldOwner(definition = id, name = "note"), type = TEXT_TEMPLATE.nullable()),
                        FieldDeclaration.partial(
                            owner = FieldOwner(definition = id, name = "count"),
                            type = integerScalar(IntegerWidth.SIGNED_THIRTY_TWO).template,
                        ),
                    ),
                abstract_ = false,
            ),
    )
}
