@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.realm.checking

import com.typewritermc.authoring.Availability
import com.typewritermc.authoring.DraftBinding
import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.authoring.boundPath
import com.typewritermc.authoring.fieldMap
import com.typewritermc.authoring.of
import com.typewritermc.authoring.root
import com.typewritermc.checking.InputIdentity
import com.typewritermc.checking.ResourceTypeMatch
import com.typewritermc.checking.TypedSelection
import com.typewritermc.configuration.field
import com.typewritermc.realm.authoring.AuthoringSeed
import com.typewritermc.realm.authoring.AuthoringViewDelta
import com.typewritermc.realm.authoring.InMemoryAuthoringViewStore
import com.typewritermc.types.ResourceId
import com.typewritermc.types.fields
import com.typewritermc.types.named
import com.typewritermc.types.namedTemplate
import com.typewritermc.types.namedUse
import com.typewritermc.types.nullable
import com.typewritermc.types.qualified
import com.typewritermc.types.toResourceId
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import skirout.editor.v1.checking.CheckInstanceId
import skirout.editor.v1.checking.CheckOutcome
import skirout.editor.v1.type_catalog.ArgumentSelection
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.FieldPatternSegment
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.PathSegment
import skirout.editor.v1.type_catalog.RelativeFieldPattern
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.RuleId
import skirout.editor.v1.type_catalog.RuleOrigin
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeParameter
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath

val CapturedAuthoringReadsTest by testSuite {
    test("projection reads preserve partial bindings and exact value evidence") {
        val catalog = TestCatalogLease(definitions = listOf(TEST_DEFINITION, LIST_DEFINITION, REPRESENTATION_DEFINITION))
        val resource = ResourceId("projection")
        val root = ValueLocation.of(resource)
        val nullValue = location(resource, "nullValue")
        val missingValue = location(resource, "missingValue")
        val representation = location(resource, "representation")
        val complete = record(count = 7, numbers = listOf("item" to 7))
        val authored =
            AuthoringRecord.of(
                configuration = TypeSelection.createPending(definition = TEST_TYPE, arguments = emptyList()),
                fields =
                    complete.fieldMap +
                        ("nullValue" to DataValue.NULL) +
                        ("missingValue" to DataValue.UNFILLED) +
                        ("representation" to DataValue.named(REPRESENTATION_TYPE.namedUse(), DataValue.StringValueWrapper("value"))),
            )
        val resources = mapOf(resource to authored)
        val store =
            InMemoryAuthoringViewStore(
                catalog,
                AuthoringSeed(resources),
            )
        val lease = store.capture()
        val reads = CapturedAuthoringReads(lease.originalView())

        reads
            .binding(
                boundPath<Any>(root, TEST_TYPE.use()),
            ).shouldBeInstanceOf<Availability.Available<com.typewritermc.authoring.DraftBinding>>()
            .value.expected
            .shouldBeInstanceOf<com.typewritermc.authoring.DraftExpectation.PartialRoot>()
        reads.presence(boundPath<Any?>(nullValue, TEXT_USE.nullable())) shouldBe Availability.Available(false)
        reads.presence(boundPath<Any>(missingValue, TEXT_USE)).shouldBeInstanceOf<Availability.Unavailable>()
        reads.readRepresentation<String>(
            boundPath<Any>(representation, REPRESENTATION_TYPE.use()),
            TEXT_USE,
        ) shouldBe Availability.Available("value")
        reads.observations().any { InputIdentity.Form(root) in it.dependencies() } shouldBe true
        reads.observations().any { InputIdentity.Value(nullValue) in it.dependencies() } shouldBe true
        reads.observations().any { InputIdentity.Value(representation) in it.dependencies() } shouldBe true

        lease.close()
        store.close()
    }

    test("composedReadsTreatNullAndUnfilledParentsAsUnavailable") {
        val catalog = TestCatalogLease()
        val resource = ResourceId("nested")
        val record =
            AuthoringRecord.of(
                configuration = TypeSelection.CompleteWrapper(TEST_TYPE.namedUse()),
                fields = mapOf("nullParent" to DataValue.NULL, "missingParent" to DataValue.UNFILLED),
            )
        val resources = mapOf(resource to record)
        val store =
            InMemoryAuthoringViewStore(
                catalog,
                AuthoringSeed(resources),
            )
        val lease = store.capture()
        val reads = CapturedAuthoringReads(lease.originalView())

        val nullChild =
            ValueLocation.of(
                resource,
                ValuePath(segments = listOf(PathSegment.createField(name = "nullParent"), PathSegment.createField(name = "child"))),
            )
        val unfilledChild =
            ValueLocation.of(
                resource,
                ValuePath(segments = listOf(PathSegment.createField(name = "missingParent"), PathSegment.createField(name = "child"))),
            )

        reads.read(boundPath<String>(nullChild, TEXT_USE)).shouldBeInstanceOf<Availability.Unavailable>()
        reads.read(boundPath<String>(unfilledChild, TEXT_USE)).shouldBeInstanceOf<Availability.Unavailable>()
        reads
            .expand(
                ValueLocation.of(resource),
                RelativeFieldPattern(
                    segments = listOf(FieldPatternSegment.field("nullParent"), FieldPatternSegment.field("child")),
                ),
            ).isEmpty() shouldBe true
        reads.expand(
            ValueLocation.of(resource),
            RelativeFieldPattern(
                segments = listOf(FieldPatternSegment.field("missingParent"), FieldPatternSegment.field("child")),
            ),
        ) shouldBe listOf(unfilledChild)
        reads.health().failures.isEmpty() shouldBe true

        lease.close()
        store.close()
    }

    test("typedSelectionIgnoresAnUnrelatedUnavailableResourceWithoutRecordingFailure") {
        val catalog = TestCatalogLease()
        val available = ResourceId("available")
        val unavailable = ResourceId("unavailable")
        val unavailableType = TypeDefinitionId.qualified("removed", "resource")
        val resources =
            mapOf(
                available to record(name = "match"),
                unavailable to
                    AuthoringRecord.of(
                        configuration = TypeSelection.CompleteWrapper(unavailableType.namedUse()),
                        fields = mapOf("legacy" to DataValue.StringValueWrapper("preserved")),
                    ),
            )
        val store =
            InMemoryAuthoringViewStore(
                catalog,
                AuthoringSeed(resources),
            )
        val lease = store.capture()
        val reads = CapturedAuthoringReads(lease.originalView())

        val selected = reads.select(TypedSelection(TestDraftType(ResourceTypeMatch.Definition(TEST_TYPE))))

        selected.knownMatches.map {
            it.binding.location.resource
                .toResourceId()
        } shouldBe listOf(available)
        selected.undecided.isEmpty() shouldBe true
        selected.failures.isEmpty() shouldBe true
        reads.health().failures.isEmpty() shouldBe true

        lease.close()
        store.close()
    }

    test("pendingGenericDescendantRemainsDiscoverableAsItsNominalBase") {
        val parameter = ParameterKey(owner = DERIVED_TYPE, index = 0)
        val derived =
            TypeDefinition(
                id = DERIVED_TYPE,
                parameters = listOf(TypeParameter.partial(key = parameter, name = "T")),
                representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
                parents = listOf(TEST_TYPE.namedTemplate()),
            )
        val catalog = TestCatalogLease(definitions = listOf(TEST_DEFINITION, LIST_DEFINITION, derived))
        val resource = ResourceId("pending")
        val record =
            AuthoringRecord.of(
                configuration = TypeSelection.createPending(definition = DERIVED_TYPE, arguments = listOf(ArgumentSelection.UNFILLED)),
                fields = emptyMap(),
            )
        val resources = mapOf(resource to record)
        val store =
            InMemoryAuthoringViewStore(
                catalog,
                AuthoringSeed(resources),
            )
        val lease = store.capture()

        val found = CapturedAuthoringReads(lease.originalView()).discoverResources(TestDraftType(ResourceTypeMatch.Definition(TEST_TYPE)))

        found.map { it.location.resource.toResourceId() } shouldBe listOf(resource)
        found.single().expected.shouldBeInstanceOf<com.typewritermc.authoring.DraftExpectation.PartialRoot>()

        lease.close()
        store.close()
    }

    test("partialApplicationSelectionKeepsUndecidedMembershipInThresholds") {
        val catalog = TestCatalogLease()
        val complete = ResourceId("complete")
        val pending = ResourceId("pending")
        val completeRecord = record()
        val pendingRecord =
            AuthoringRecord.of(
                configuration = TypeSelection.createPending(definition = TEST_TYPE, arguments = emptyList<ArgumentSelection>()),
                fields = completeRecord.fieldMap,
            )
        val resources = mapOf(complete to completeRecord, pending to pendingRecord)
        val store =
            InMemoryAuthoringViewStore(
                catalog,
                AuthoringSeed(resources),
            )
        val lease = store.capture()

        val result =
            CapturedAuthoringReads(lease.originalView()).select(
                TypedSelection(TestDraftType(ResourceTypeMatch.Application(TEST_TYPE.namedUse()))),
            )

        result.knownMatches.size shouldBe 1
        result.undecided.map { it.resource } shouldBe listOf(pending)
        result.atLeast(1) shouldBe Availability.Available(true)
        result.atMost(0) shouldBe Availability.Available(false)
        result.count().shouldBeInstanceOf<Availability.Unavailable>()

        lease.close()
        store.close()
    }

    test("applicationSelectionRequiresTheExactAppliedType") {
        val generic = TypeDefinitionId.qualified("test", "generic_resource")
        val parameter = ParameterKey(owner = generic, index = 0)
        val definition =
            TypeDefinition.partial(
                id = generic,
                parameters = listOf(TypeParameter.partial(key = parameter, name = "T")),
                representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
            )
        val catalog = TestCatalogLease(definitions = listOf(TEST_DEFINITION, LIST_DEFINITION, definition))
        val text = ResourceId("text")
        val number = ResourceId("number")
        val textUse = generic.namedUse(listOf(TEXT_USE))
        val numberUse = generic.namedUse(listOf(INT_USE))
        val resources =
            mapOf(
                text to AuthoringRecord.of(TypeSelection.CompleteWrapper(textUse), emptyMap()),
                number to AuthoringRecord.of(TypeSelection.CompleteWrapper(numberUse), emptyMap()),
            )
        val store =
            InMemoryAuthoringViewStore(
                catalog,
                AuthoringSeed(resources),
            )
        val lease = store.capture()

        val selected =
            CapturedAuthoringReads(lease.originalView()).select(
                TypedSelection(TestDraftType(ResourceTypeMatch.Application(textUse))),
            )

        selected.knownMatches.map {
            it.binding.location.resource
                .toResourceId()
        } shouldBe listOf(text)
        selected.undecided.isEmpty() shouldBe true

        lease.close()
        store.close()
    }

    test("pendingGenericBindingRequiresProvableAppliedArguments") {
        val generic = TypeDefinitionId.qualified("test", "generic_binding")
        val parameter = ParameterKey(owner = generic, index = 0)
        val definition =
            TypeDefinition.partial(
                id = generic,
                parameters = listOf(TypeParameter.partial(key = parameter, name = "T")),
                representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
            )
        val catalog = TestCatalogLease(definitions = listOf(TEST_DEFINITION, LIST_DEFINITION, definition))
        val resource = ResourceId("pending")
        val unresolved = ResourceId("unresolved")
        val textUse = generic.namedUse(listOf(TEXT_USE))
        val numberUse = generic.namedUse(listOf(INT_USE))
        val record =
            AuthoringRecord.of(
                TypeSelection.createPending(definition = generic, arguments = listOf(ArgumentSelection.ChosenWrapper(TEXT_USE))),
                emptyMap(),
            )
        val resources =
            mapOf(
                resource to record,
                unresolved to
                    record.copy(
                        configuration = TypeSelection.createPending(definition = generic, arguments = listOf(ArgumentSelection.UNFILLED)),
                    ),
            )
        val store =
            InMemoryAuthoringViewStore(
                catalog,
                AuthoringSeed(resources),
            )
        val lease = store.capture()
        val root = ValueLocation.of(resource)

        val matching = CapturedAuthoringReads(lease.originalView()).binding(boundPath<Any>(root, textUse.use))
        val mismatched = CapturedAuthoringReads(lease.originalView()).binding(boundPath<Any>(root, numberUse.use))
        val unresolvedBinding =
            CapturedAuthoringReads(lease.originalView()).binding(
                boundPath<Any>(ValueLocation.of(unresolved), textUse.use),
            )

        matching.shouldBeInstanceOf<Availability.Available<DraftBinding>>()
        mismatched.shouldBeInstanceOf<Availability.Failed>()
        unresolvedBinding.shouldBeInstanceOf<Availability.Available<DraftBinding>>()
        lease.close()
        store.close()
    }

    test("descendantPatternsUseStableItemLocationsAndRecordMembership") {
        val catalog = TestCatalogLease()
        val resource = ResourceId("page")
        val authored = record(numbers = listOf("a" to 1, "b" to 2))
        val store =
            InMemoryAuthoringViewStore(
                catalog,
                AuthoringSeed(mapOf(resource to authored)),
            )
        val lease = store.capture()
        val reads = CapturedAuthoringReads(lease.originalView())

        val expanded =
            reads.expand(
                ValueLocation.of(resource),
                RelativeFieldPattern(segments = listOf(FieldPatternSegment.field("numbers"), FieldPatternSegment.ITEMS)),
            )

        expanded shouldBe
            listOf(
                ValueLocation.of(
                    resource,
                    ValuePath(
                        segments =
                            listOf(
                                PathSegment.createField(name = "numbers"),
                                PathSegment.createItem(
                                    id =
                                        skirout.editor.v1.type_catalog
                                            .ItemId(value = "a"),
                                ),
                            ),
                    ),
                ),
                ValueLocation.of(
                    resource,
                    ValuePath(
                        segments =
                            listOf(
                                PathSegment.createField(name = "numbers"),
                                PathSegment.createItem(
                                    id =
                                        skirout.editor.v1.type_catalog
                                            .ItemId(value = "b"),
                                ),
                            ),
                    ),
                ),
            )
        reads.observations().any { InputIdentity.Value(location(resource, "numbers")) in it.dependencies() } shouldBe true

        lease.close()
        store.close()
    }

    test("graphReadIncompletenessOverridesMissingInputs") {
        val catalog = TestCatalogLease()
        val store =
            InMemoryAuthoringViewStore(
                catalog,
                AuthoringSeed(emptyMap()),
            )
        val lease = store.capture()
        val reads = CapturedAuthoringReads(lease.originalView())
        reads.resourceBinding(ResourceId("missing"))
        reads.recordIncomplete("graph traversal limit exceeded")

        val outcome = reads.health().outcome(RuleOrigin(owner = TEST_TYPE, ordinal = 0))

        outcome shouldBe CheckOutcome.IncompleteWrapper("graph traversal limit exceeded")
        lease.close()
        store.close()
    }

    test("incrementalDependencyResultsEqualFullRecomputationAfterScriptedEdits") {
        val catalog = TestCatalogLease()
        val resource = ResourceId("page")
        val root = ValueLocation.of(resource)
        val name = location(resource, "name")
        val count = location(resource, "count")
        val initial = record(name = "alpha", count = 1)
        val store =
            InMemoryAuthoringViewStore(
                catalog,
                AuthoringSeed(mapOf(resource to initial)),
            )
        val nameId = CheckInstanceId(rule = RuleId(origin = RuleOrigin(owner = TEST_TYPE, ordinal = 0), localIndex = 0), location = name)
        val countId = CheckInstanceId(rule = RuleId(origin = RuleOrigin(owner = TEST_TYPE, ordinal = 1), localIndex = 0), location = count)
        val index = DefaultReverseDependencyIndex()
        val incremental = linkedMapOf<CheckInstanceId, Boolean>()

        fun evaluate(id: CheckInstanceId): Pair<Boolean, List<com.typewritermc.authoring.EditExpectation>> {
            val lease = store.capture()
            return lease.use {
                val reads = CapturedAuthoringReads(it.originalView())
                val accepted =
                    when (id) {
                        nameId -> reads.read(boundPath<String>(name, TEXT_USE)).available().startsWith("a")
                        countId -> reads.read(boundPath<Int>(count, INT_USE)).available() < 10
                        else -> error("Unknown check instance.")
                    }
                accepted to reads.observations()
            }
        }

        listOf(nameId, countId).forEach { id ->
            val (value, observations) = evaluate(id)
            incremental[id] = value
            index.replace(id, observations)
        }

        val edits =
            listOf(
                record(name = "alpha", count = 20) to count,
                record(name = "beta", count = 20) to name,
                record(name = "alpha", count = 20) to name,
            )
        edits.forEachIndexed { edit, (next, changedLocation) ->
            store.install(store.prepare(AuthoringViewDelta(upsertedResources = mapOf(resource to next))))
            val changed = setOf(InputIdentity.Value(changedLocation))
            index.affectedBy(changed).forEach { id ->
                val (value, observations) = evaluate(id)
                incremental[id] = value
                index.replace(id, observations)
            }
            val full = listOf(nameId, countId).associateWith { evaluate(it).first }
            incremental shouldBe full
        }

        store.close()
    }
}

private val DERIVED_TYPE = TypeDefinitionId.qualified("test", "derived")
private val REPRESENTATION_TYPE = TypeDefinitionId.qualified("test", "text_representation")
private val REPRESENTATION_DEFINITION =
    TypeDefinition.partial(id = REPRESENTATION_TYPE, representation = RepresentationTemplate.createScalar(kind = ScalarKind.TEXT))
