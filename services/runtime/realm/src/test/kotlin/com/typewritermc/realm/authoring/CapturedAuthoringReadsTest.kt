@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.realm.authoring

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
import com.typewritermc.expression.operations.HostFailure
import com.typewritermc.realm.checking.DefaultReverseDependencyIndex
import com.typewritermc.realm.checking.dependencies
import com.typewritermc.realm.checking.outcome
import com.typewritermc.realm.testing.DefinitionCatalog
import com.typewritermc.realm.testing.RealmFixture
import com.typewritermc.realm.testing.shouldBeCommitted
import com.typewritermc.types.fields
import com.typewritermc.types.integer
import com.typewritermc.types.namedTemplate
import com.typewritermc.types.namedUse
import com.typewritermc.types.nullable
import com.typewritermc.types.qualified
import com.typewritermc.types.toSkir
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import skirout.editor.v1.authoring.EditIntent
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
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeParameter
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath
import skirout.kernel.v1.resource_id.ResourceId
import java.math.BigInteger

val CapturedAuthoringReadsTest by testSuite {
    val derivedType = TypeDefinitionId.qualified("test", "derived")

    test("an authored null is present as null while an unfilled value is unavailable") {
        projection { reads ->
            reads.presence(boundPath<Any?>(NULL_VALUE, TEXT_USE.nullable())) shouldBe Availability.Available(false)
            reads.presence(boundPath<Any>(MISSING_VALUE, TEXT_USE)) shouldBe Availability.Unavailable(listOf(MISSING_VALUE))
        }
    }

    test("a value stored in a representation type reads as that representation") {
        projection { reads ->
            reads.readRepresentation<String>(boundPath<Any>(REPRESENTATION_VALUE, REPRESENTATION_TYPE.use()), TEXT_USE) shouldBe
                Availability.Available("value")
        }
    }

    test("a resource whose type is still pending binds as a partial root") {
        projection { reads ->
            reads
                .binding(boundPath<Any>(ValueLocation.of(PROJECTION), TEST_TYPE.use()))
                .shouldBeInstanceOf<Availability.Available<DraftBinding>>()
                .value.expected
                .shouldBeInstanceOf<com.typewritermc.authoring.DraftExpectation.PartialRoot>()
        }
    }

    test("each read records exactly the inputs its result depends on") {

        val existence = InputIdentity.Existence(PROJECTION)
        val form = InputIdentity.Form(ValueLocation.of(PROJECTION))
        io.kotest.assertions.assertSoftly {
            dependenciesOf { it.presence(boundPath<Any?>(NULL_VALUE, TEXT_USE.nullable())) } shouldBe
                setOf(existence, form, InputIdentity.Value(NULL_VALUE))
            dependenciesOf {
                it.readRepresentation<String>(
                    boundPath<Any>(REPRESENTATION_VALUE, REPRESENTATION_TYPE.use()),
                    TEXT_USE,
                )
            } shouldBe
                setOf(existence, form, InputIdentity.Value(REPRESENTATION_VALUE))
            dependenciesOf { it.binding(boundPath<Any>(ValueLocation.of(PROJECTION), TEST_TYPE.use())) } shouldBe setOf(existence, form)
        }
    }

    test("a child of a null or unfilled parent is unavailable and only the unfilled parent expands") {
        val resource = ResourceId(value = "nested")
        val record =
            AuthoringRecord.of(
                configuration = TypeSelection.CompleteWrapper(TEST_TYPE.namedUse()),
                fields = mapOf("nullParent" to DataValue.NULL, "missingParent" to DataValue.UNFILLED),
            )
        val resources = mapOf(resource to record)
        captured(resources) { lease ->
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
        }
    }

    test("a typed selection ignores a resource of an unavailable type without recording a failure") {
        val available = ResourceId(value = "available")
        val unavailable = ResourceId(value = "unavailable")
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
        captured(resources) { lease ->
            val reads = CapturedAuthoringReads(lease.originalView())

            val selected = reads.select(TypedSelection(TestDraftType(ResourceTypeMatch.Definition(TEST_TYPE))))

            selected.knownMatches.map {
                it.binding.location.resource
            } shouldBe listOf(available)
            selected.undecided.isEmpty() shouldBe true
            selected.failures.isEmpty() shouldBe true
            reads.health().failures.isEmpty() shouldBe true
        }
    }

    test("a pending generic descendant is discovered as its nominal base") {
        val parameter = ParameterKey(owner = derivedType, index = 0)
        val derived =
            TypeDefinition(
                id = derivedType,
                parameters = listOf(TypeParameter.partial(key = parameter, name = "T")),
                representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
                parents = listOf(TEST_TYPE.namedTemplate()),
            )
        val catalog = DefinitionCatalog(TEST_DEFINITIONS + listOf(derived))
        val resource = ResourceId(value = "pending")
        val record =
            AuthoringRecord.of(
                configuration = TypeSelection.createPending(definition = derivedType, arguments = listOf(ArgumentSelection.UNFILLED)),
                fields = emptyMap(),
            )
        val resources = mapOf(resource to record)
        captured(resources, catalog) { lease ->

            val found =
                CapturedAuthoringReads(
                    lease.originalView(),
                ).discoverResources(TestDraftType(ResourceTypeMatch.Definition(TEST_TYPE)))

            found.map { it.location.resource } shouldBe listOf(resource)
            found.single().expected.shouldBeInstanceOf<com.typewritermc.authoring.DraftExpectation.PartialRoot>()
        }
    }

    test("a pending resource stays undecided in a type selection while the complete one matches") {
        val complete = ResourceId(value = "complete")
        val pending = ResourceId(value = "pending")
        val completeRecord = record()
        val pendingRecord =
            AuthoringRecord.of(
                configuration = TypeSelection.createPending(definition = TEST_TYPE, arguments = emptyList<ArgumentSelection>()),
                fields = completeRecord.fieldMap,
            )
        val resources = mapOf(complete to completeRecord, pending to pendingRecord)
        captured(resources) { lease ->

            val result =
                CapturedAuthoringReads(lease.originalView()).select(
                    TypedSelection(TestDraftType(ResourceTypeMatch.Application(TEST_TYPE.namedUse()))),
                )

            result.knownMatches.map { it.binding.location.resource } shouldBe listOf(complete)
            result.undecided.map { it.resource.toSkir() } shouldBe listOf(pending)
            result.atLeast(1) shouldBe Availability.Available(true)
            result.atMost(0) shouldBe Availability.Available(false)
            result.count().shouldBeInstanceOf<Availability.Unavailable>()
        }
    }

    test("an applied type selection matches only resources of that exact applied type") {
        val generic = TypeDefinitionId.qualified("test", "generic_resource")
        val parameter = ParameterKey(owner = generic, index = 0)
        val definition =
            TypeDefinition.partial(
                id = generic,
                parameters = listOf(TypeParameter.partial(key = parameter, name = "T")),
                representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
            )
        val catalog = DefinitionCatalog(TEST_DEFINITIONS + listOf(definition))
        val text = ResourceId(value = "text")
        val number = ResourceId(value = "number")
        val textUse = generic.namedUse(listOf(TEXT_USE))
        val numberUse = generic.namedUse(listOf(INT_USE))
        val resources =
            mapOf(
                text to AuthoringRecord.of(TypeSelection.CompleteWrapper(textUse), emptyMap()),
                number to AuthoringRecord.of(TypeSelection.CompleteWrapper(numberUse), emptyMap()),
            )
        captured(resources, catalog) { lease ->

            val selected =
                CapturedAuthoringReads(lease.originalView()).select(
                    TypedSelection(TestDraftType(ResourceTypeMatch.Application(textUse))),
                )

            selected.knownMatches.map {
                it.binding.location.resource
            } shouldBe listOf(text)
            selected.undecided.isEmpty() shouldBe true
        }
    }

    test("binding a pending generic succeeds only when its chosen arguments match the requested type") {
        val generic = TypeDefinitionId.qualified("test", "generic_binding")
        val parameter = ParameterKey(owner = generic, index = 0)
        val definition =
            TypeDefinition.partial(
                id = generic,
                parameters = listOf(TypeParameter.partial(key = parameter, name = "T")),
                representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
            )
        val catalog = DefinitionCatalog(TEST_DEFINITIONS + listOf(definition))
        val resource = ResourceId(value = "pending")
        val unresolved = ResourceId(value = "unresolved")
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
        captured(resources, catalog) { lease ->
            val root = ValueLocation.of(resource)

            val matching = CapturedAuthoringReads(lease.originalView()).binding(boundPath<Any>(root, textUse.use))
            val mismatched = CapturedAuthoringReads(lease.originalView()).binding(boundPath<Any>(root, numberUse.use))
            val unresolvedBinding =
                CapturedAuthoringReads(lease.originalView()).binding(
                    boundPath<Any>(ValueLocation.of(unresolved), textUse.use),
                )

            matching.shouldBeInstanceOf<Availability.Available<DraftBinding>>()
            mismatched.shouldBeInstanceOf<Availability.Failed>().diagnostic.let { it.failure to it.locations } shouldBe
                (HostFailure.UnreadableBinding to listOf(root))
            unresolvedBinding.shouldBeInstanceOf<Availability.Available<DraftBinding>>()
        }
    }

    test("a pattern over list items expands to their stable item locations") {
        val resource = ResourceId(value = "page")
        val authored = record(numbers = listOf("a" to 1, "b" to 2))
        captured(mapOf(resource to authored)) { lease ->
            val reads = CapturedAuthoringReads(lease.originalView())

            val expanded =
                reads.expand(
                    ValueLocation.of(resource),
                    RelativeFieldPattern(segments = listOf(FieldPatternSegment.field("numbers"), FieldPatternSegment.ITEMS)),
                )

            expanded shouldBe
                listOf(
                    listItemAt(resource, "numbers", "a"),
                    listItemAt(resource, "numbers", "b"),
                )
            reads.observations().any { InputIdentity.Value(location(resource, "numbers")) in it.dependencies() } shouldBe true
        }
    }

    test("a read marked incomplete reports the check incomplete even when inputs are missing") {
        captured(emptyMap()) { lease ->
            val reads = CapturedAuthoringReads(lease.originalView())
            reads.resourceBinding(ResourceId(value = "missing"))
            reads.recordIncomplete("graph traversal limit exceeded")

            val outcome = reads.health().outcome(RuleOrigin(owner = TEST_TYPE, ordinal = 0))

            outcome shouldBe CheckOutcome.IncompleteWrapper("graph traversal limit exceeded")
        }
    }

    test("rechecking only the checks an edit affects gives the same results as rechecking all") {
        val resource = ResourceId(value = "page")
        val root = ValueLocation.of(resource)
        val name = location(resource, "name")
        val count = location(resource, "count")
        val initial = record(name = "alpha", count = 1)
        RealmFixture.of(DefinitionCatalog(TEST_DEFINITIONS), mapOf(resource to initial)).use { realm ->
            val nameId =
                CheckInstanceId(rule = RuleId(origin = RuleOrigin(owner = TEST_TYPE, ordinal = 0), localIndex = 0), location = name)
            val countId =
                CheckInstanceId(rule = RuleId(origin = RuleOrigin(owner = TEST_TYPE, ordinal = 1), localIndex = 0), location = count)
            val index = DefaultReverseDependencyIndex()
            val incremental = linkedMapOf<CheckInstanceId, Boolean>()

            val evaluate: (CheckInstanceId) -> Pair<Boolean, List<skirout.editor.v1.authoring_facts.EditExpectation>> = { id ->
                realm.views.capture().use {
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
                    count to DataValue.integer(BigInteger.valueOf(20)),
                    name to DataValue.StringValueWrapper("beta"),
                    name to DataValue.StringValueWrapper("alpha"),
                )
            edits.forEach { (changedLocation, value) ->
                realm.commit(EditIntent.createSetValue(at = changedLocation, value = value)).shouldBeCommitted()
                val changed = setOf(InputIdentity.Value(changedLocation))
                index.affectedBy(changed).forEach { id ->
                    val (result, observations) = evaluate(id)
                    incremental[id] = result
                    index.replace(id, observations)
                }
                val full = listOf(nameId, countId).associateWith { evaluate(it).first }
                incremental shouldBe full
            }
        }
    }
}
