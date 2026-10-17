package com.typewritermc.realm.checking

import com.typewritermc.authoring.ArgumentSelection
import com.typewritermc.authoring.AuthoringRecord
import com.typewritermc.authoring.Availability
import com.typewritermc.authoring.DraftBinding
import com.typewritermc.authoring.PathSegment
import com.typewritermc.authoring.ResourceDefinitionId
import com.typewritermc.authoring.TypeSelection
import com.typewritermc.authoring.ValueLocation
import com.typewritermc.authoring.ValuePath
import com.typewritermc.authoring.boundPath
import com.typewritermc.checking.CheckOutcome
import com.typewritermc.checking.InputIdentity
import com.typewritermc.checking.InputToken
import com.typewritermc.checking.ResourceTypeMatch
import com.typewritermc.checking.TypedSelection
import com.typewritermc.configuration.FieldPatternSegment
import com.typewritermc.configuration.RelativeFieldPattern
import com.typewritermc.configuration.RuleId
import com.typewritermc.configuration.RuleOrigin
import com.typewritermc.realm.authoring.AuthoringSeed
import com.typewritermc.realm.authoring.AuthoringViewDelta
import com.typewritermc.realm.authoring.InMemoryAuthoringViewStore
import com.typewritermc.types.DataValue
import com.typewritermc.types.ParameterKey
import com.typewritermc.types.RepresentationTemplate
import com.typewritermc.types.ResourceId
import com.typewritermc.types.ScalarKind
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeId
import com.typewritermc.types.TypeParameter
import com.typewritermc.types.TypeTemplate
import com.typewritermc.types.TypeUse
import de.infix.testBalloon.framework.core.testSuite

val CapturedAuthoringReadsTest by testSuite {
    test("projection reads preserve partial bindings and exact value evidence") {
        val catalog = TestCatalogLease(definitions = listOf(TEST_DEFINITION, LIST_DEFINITION, REPRESENTATION_DEFINITION))
        val resource = ResourceId("projection")
        val root = ValueLocation(resource, ValuePath())
        val nullValue = location(resource, "nullValue")
        val missingValue = location(resource, "missingValue")
        val representation = location(resource, "representation")
        val complete = record(count = 7, numbers = listOf("item" to 7))
        val authored =
            complete.copy(
                configuration = TypeSelection.Pending(TEST_TYPE, emptyList()),
                fields =
                    complete.fields +
                        ("nullValue" to DataValue.Null) +
                        ("missingValue" to DataValue.Unfilled) +
                        ("representation" to DataValue.Named(TypeUse.Named(REPRESENTATION_TYPE), DataValue.StringValue("value"))),
            )
        val resources = mapOf(resource to authored)
        val store =
            InMemoryAuthoringViewStore(
                catalog,
                AuthoringSeed(resources),
            )
        val lease = store.capture()
        val reads = CapturedAuthoringReads(lease.originalView())

        assertIs<com.typewritermc.authoring.DraftExpectation.PartialRoot>(
            assertIs<Availability.Available<com.typewritermc.authoring.DraftBinding>>(
                reads.binding(boundPath<Any>(root, TypeUse.Named(TEST_TYPE))),
            ).value.expected,
        )
        assertEquals(Availability.Available(false), reads.presence(boundPath<Any?>(nullValue, TypeUse.Nullable(TEXT_USE))))
        assertIs<Availability.Unavailable>(reads.presence(boundPath<Any>(missingValue, TEXT_USE)))
        assertEquals(
            Availability.Available("value"),
            reads.readRepresentation<String>(
                boundPath<Any>(representation, TypeUse.Named(REPRESENTATION_TYPE)),
                TEXT_USE,
            ),
        )
        assertTrue(reads.observations().any { InputIdentity.Form(root) in it.dependencies() })
        assertTrue(reads.observations().any { InputIdentity.Value(nullValue) in it.dependencies() })
        assertTrue(reads.observations().any { InputIdentity.Value(representation) in it.dependencies() })

        lease.close()
        store.close()
    }

    test("composedReadsTreatNullAndUnfilledParentsAsUnavailable") {
        val catalog = TestCatalogLease()
        val resource = ResourceId("nested")
        val record =
            AuthoringRecord(
                configuration = TypeSelection.Complete(TypeUse.Named(TEST_TYPE)),
                fields = mapOf("nullParent" to DataValue.Null, "missingParent" to DataValue.Unfilled),
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
            ValueLocation(resource, ValuePath(listOf(PathSegment.Field("nullParent"), PathSegment.Field("child"))))
        val unfilledChild =
            ValueLocation(resource, ValuePath(listOf(PathSegment.Field("missingParent"), PathSegment.Field("child"))))

        assertIs<Availability.Unavailable>(reads.read(boundPath<String>(nullChild, TEXT_USE)))
        assertIs<Availability.Unavailable>(reads.read(boundPath<String>(unfilledChild, TEXT_USE)))
        assertTrue(
            reads
                .expand(
                    ValueLocation(resource, ValuePath()),
                    RelativeFieldPattern(
                        listOf(FieldPatternSegment.Field("nullParent"), FieldPatternSegment.Field("child")),
                    ),
                ).isEmpty(),
        )
        assertEquals(
            listOf(unfilledChild),
            reads.expand(
                ValueLocation(resource, ValuePath()),
                RelativeFieldPattern(
                    listOf(FieldPatternSegment.Field("missingParent"), FieldPatternSegment.Field("child")),
                ),
            ),
        )
        assertTrue(reads.health().failures.isEmpty())

        lease.close()
        store.close()
    }

    test("typedSelectionIgnoresAnUnrelatedUnavailableResourceWithoutRecordingFailure") {
        val catalog = TestCatalogLease()
        val available = ResourceId("available")
        val unavailable = ResourceId("unavailable")
        val unavailableType = TypeDefinitionId(TypeId.Qualified("removed", "resource"), 1)
        val resources =
            mapOf(
                available to record(name = "match"),
                unavailable to
                    AuthoringRecord(
                        configuration = TypeSelection.Complete(TypeUse.Named(unavailableType)),
                        fields = mapOf("legacy" to DataValue.StringValue("preserved")),
                    ),
            )
        val store =
            InMemoryAuthoringViewStore(
                catalog,
                AuthoringSeed(
                    resources,
                    mapOf(
                        available to ResourceDefinitionId("test"),
                        unavailable to ResourceDefinitionId("removed_definition"),
                    ),
                ),
            )
        val lease = store.capture()
        val reads = CapturedAuthoringReads(lease.originalView())

        val selected = reads.select(TypedSelection(TestDraftType(ResourceTypeMatch.Definition(TEST_TYPE))))

        assertEquals(listOf(available), selected.knownMatches.map { it.binding.location.resource })
        assertTrue(selected.undecided.isEmpty())
        assertTrue(selected.failures.isEmpty())
        assertTrue(reads.health().failures.isEmpty())

        lease.close()
        store.close()
    }

    test("pendingGenericDescendantRemainsDiscoverableAsItsNominalBase") {
        val parameter = ParameterKey(DERIVED_TYPE, 0)
        val derived =
            TypeDefinition(
                id = DERIVED_TYPE,
                parameters = listOf(TypeParameter(parameter, "T")),
                representation = RepresentationTemplate.Record(emptyList()),
                parents = listOf(TypeTemplate.Named(TEST_TYPE)),
            )
        val catalog = TestCatalogLease(definitions = listOf(TEST_DEFINITION, LIST_DEFINITION, derived))
        val resource = ResourceId("pending")
        val record =
            AuthoringRecord(
                configuration = TypeSelection.Pending(DERIVED_TYPE, listOf(ArgumentSelection.Unfilled)),
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

        assertEquals(listOf(resource), found.map { it.location.resource })
        assertIs<com.typewritermc.authoring.DraftExpectation.PartialRoot>(found.single().expected)

        lease.close()
        store.close()
    }

    test("partialApplicationSelectionKeepsUndecidedMembershipInThresholds") {
        val catalog = TestCatalogLease()
        val complete = ResourceId("complete")
        val pending = ResourceId("pending")
        val completeRecord = record()
        val pendingRecord =
            AuthoringRecord(
                configuration = TypeSelection.Pending(TEST_TYPE, emptyList<ArgumentSelection>()),
                fields = completeRecord.fields,
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
                TypedSelection(TestDraftType(ResourceTypeMatch.Application(TypeUse.Named(TEST_TYPE)))),
            )

        assertEquals(1, result.knownMatches.size)
        assertEquals(listOf(pending), result.undecided.map { it.resource })
        assertEquals(Availability.Available(true), result.atLeast(1))
        assertEquals(Availability.Available(false), result.atMost(0))
        assertIs<Availability.Unavailable>(result.count())

        lease.close()
        store.close()
    }

    test("applicationSelectionRequiresTheExactAppliedType") {
        val generic = TypeDefinitionId(TypeId.Qualified("test", "generic_resource"), 1)
        val parameter = ParameterKey(generic, 0)
        val definition =
            TypeDefinition(
                id = generic,
                parameters = listOf(TypeParameter(parameter, "T")),
                representation = RepresentationTemplate.Record(emptyList()),
            )
        val catalog = TestCatalogLease(definitions = listOf(TEST_DEFINITION, LIST_DEFINITION, definition), resourceRoot = generic)
        val text = ResourceId("text")
        val number = ResourceId("number")
        val textUse = TypeUse.Named(generic, listOf(TEXT_USE))
        val numberUse = TypeUse.Named(generic, listOf(INT_USE))
        val resources =
            mapOf(
                text to AuthoringRecord(TypeSelection.Complete(textUse), emptyMap()),
                number to AuthoringRecord(TypeSelection.Complete(numberUse), emptyMap()),
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

        assertEquals(listOf(text), selected.knownMatches.map { it.binding.location.resource })
        assertTrue(selected.undecided.isEmpty())

        lease.close()
        store.close()
    }

    test("pendingGenericBindingRequiresProvableAppliedArguments") {
        val generic = TypeDefinitionId(TypeId.Qualified("test", "generic_binding"), 1)
        val parameter = ParameterKey(generic, 0)
        val definition =
            TypeDefinition(
                id = generic,
                parameters = listOf(TypeParameter(parameter, "T")),
                representation = RepresentationTemplate.Record(emptyList()),
            )
        val catalog = TestCatalogLease(definitions = listOf(TEST_DEFINITION, LIST_DEFINITION, definition), resourceRoot = generic)
        val resource = ResourceId("pending")
        val unresolved = ResourceId("unresolved")
        val textUse = TypeUse.Named(generic, listOf(TEXT_USE))
        val numberUse = TypeUse.Named(generic, listOf(INT_USE))
        val record =
            AuthoringRecord(
                TypeSelection.Pending(generic, listOf(ArgumentSelection.Chosen(TEXT_USE))),
                emptyMap(),
            )
        val resources =
            mapOf(
                resource to record,
                unresolved to
                    record.copy(
                        configuration = TypeSelection.Pending(generic, listOf(ArgumentSelection.Unfilled)),
                    ),
            )
        val store =
            InMemoryAuthoringViewStore(
                catalog,
                AuthoringSeed(resources),
            )
        val lease = store.capture()
        val root = ValueLocation(resource, ValuePath())

        val matching = CapturedAuthoringReads(lease.originalView()).binding(boundPath<Any>(root, textUse))
        val mismatched = CapturedAuthoringReads(lease.originalView()).binding(boundPath<Any>(root, numberUse))
        val unresolvedBinding =
            CapturedAuthoringReads(lease.originalView()).binding(
                boundPath<Any>(ValueLocation(unresolved, ValuePath()), textUse),
            )

        assertIs<Availability.Available<DraftBinding>>(matching)
        assertIs<Availability.Failed>(mismatched)
        assertIs<Availability.Available<DraftBinding>>(unresolvedBinding)
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
                ValueLocation(resource, ValuePath()),
                RelativeFieldPattern(listOf(FieldPatternSegment.Field("numbers"), FieldPatternSegment.Items)),
            )

        assertEquals(
            listOf(
                ValueLocation(
                    resource,
                    ValuePath(listOf(PathSegment.Field("numbers"), PathSegment.Item(com.typewritermc.authoring.ItemId("a")))),
                ),
                ValueLocation(
                    resource,
                    ValuePath(listOf(PathSegment.Field("numbers"), PathSegment.Item(com.typewritermc.authoring.ItemId("b")))),
                ),
            ),
            expanded,
        )
        assertTrue(reads.observations().any { InputIdentity.Value(location(resource, "numbers")) in it.dependencies() })

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

        val outcome = reads.health().outcome(RuleOrigin(TEST_TYPE, 0))

        assertEquals(CheckOutcome.Incomplete("graph traversal limit exceeded"), outcome)
        lease.close()
        store.close()
    }

    test("incrementalDependencyResultsEqualFullRecomputationAfterScriptedEdits") {
        val catalog = TestCatalogLease()
        val resource = ResourceId("page")
        val root = ValueLocation(resource, ValuePath())
        val name = location(resource, "name")
        val count = location(resource, "count")
        val initial = record(name = "alpha", count = 1)
        val store =
            InMemoryAuthoringViewStore(
                catalog,
                AuthoringSeed(mapOf(resource to initial)),
            )
        val nameId = CheckInstanceId(RuleId(RuleOrigin(TEST_TYPE, 0), 0), name)
        val countId = CheckInstanceId(RuleId(RuleOrigin(TEST_TYPE, 1), 0), count)
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
            assertEquals(full, incremental)
        }

        store.close()
    }
}

private val DERIVED_TYPE = TypeDefinitionId(TypeId.Qualified("test", "derived"), 1)
private val REPRESENTATION_TYPE = TypeDefinitionId(TypeId.Qualified("test", "text_representation"), 1)
private val REPRESENTATION_DEFINITION =
    TypeDefinition(
        id = REPRESENTATION_TYPE,
        representation = RepresentationTemplate.Scalar(ScalarKind.Text),
    )
