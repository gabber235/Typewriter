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
import com.typewritermc.realm.checking.CheckRunDiagnostics
import com.typewritermc.realm.checking.outcome
import com.typewritermc.realm.testing.DefinitionCatalog
import com.typewritermc.realm.testing.RealmFixture
import com.typewritermc.realm.testing.shouldBeCommitted
import com.typewritermc.types.catalog.ResourceType
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
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.FieldPatternSegment
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.PathSegment
import skirout.editor.v1.type_catalog.RecordForm
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

/** A generic record type with one parameter and no fields: a selection that leaves its parameter unchosen is a partial type. */
private val PENDING_GENERIC = TypeDefinitionId.qualified("test", "pending_generic")
private val PENDING_GENERIC_DEFINITION =
    TypeDefinition.partial(
        id = PENDING_GENERIC,
        parameters = listOf(TypeParameter.partial(key = ParameterKey(owner = PENDING_GENERIC, index = 0), name = "T")),
        representation = RepresentationTemplate.createRecord(fields = emptyList(), form = RecordForm.CONCRETE),
    )

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
        val resource = ResourceId(value = "pending")
        val resources = mapOf(resource to AuthoringRecord.of(TypeSelection.of(PENDING_GENERIC), emptyMap()))
        captured(resources, DefinitionCatalog(TEST_DEFINITIONS + PENDING_GENERIC_DEFINITION)) { lease ->
            CapturedAuthoringReads(lease.originalView())
                .binding(boundPath<Any>(ValueLocation.of(resource), PENDING_GENERIC.use(listOf(TEXT_USE))))
                .shouldBeInstanceOf<Availability.Available<DraftBinding>>()
                .value.type
                .shouldBeInstanceOf<ResourceType.Partial>()
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
                configuration = TypeSelection.of(TEST_TYPE.namedUse()),
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
                        configuration = TypeSelection.of(unavailableType.namedUse()),
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
                representation = RepresentationTemplate.createRecord(fields = emptyList(), form = RecordForm.CONCRETE),
                parents = listOf(TEST_TYPE.namedTemplate()),
            )
        val catalog = DefinitionCatalog(TEST_DEFINITIONS + listOf(derived))
        val resource = ResourceId(value = "pending")
        val record =
            AuthoringRecord.of(
                configuration = TypeSelection.of(derivedType),
                fields = emptyMap(),
            )
        val resources = mapOf(resource to record)
        captured(resources, catalog) { lease ->

            val found =
                CapturedAuthoringReads(
                    lease.originalView(),
                ).discoverResources(TestDraftType(ResourceTypeMatch.Definition(TEST_TYPE)))

            found.map { it.location.resource } shouldBe listOf(resource)
            found.single().type.shouldBeInstanceOf<ResourceType.Partial>()
        }
    }

    test("a pending resource stays undecided in a type selection while the complete one matches") {
        val complete = ResourceId(value = "complete")
        val pending = ResourceId(value = "pending")
        val resources =
            mapOf(
                complete to AuthoringRecord.of(TypeSelection.of(PENDING_GENERIC, mapOf(0 to TEXT_USE)), emptyMap()),
                pending to AuthoringRecord.of(TypeSelection.of(PENDING_GENERIC), emptyMap()),
            )
        captured(resources, DefinitionCatalog(TEST_DEFINITIONS + PENDING_GENERIC_DEFINITION)) { lease ->

            val result =
                CapturedAuthoringReads(lease.originalView()).select(
                    TypedSelection(TestDraftType(ResourceTypeMatch.Application(PENDING_GENERIC.namedUse(listOf(TEXT_USE))))),
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
                representation = RepresentationTemplate.createRecord(fields = emptyList(), form = RecordForm.CONCRETE),
            )
        val catalog = DefinitionCatalog(TEST_DEFINITIONS + listOf(definition))
        val text = ResourceId(value = "text")
        val number = ResourceId(value = "number")
        val textUse = generic.namedUse(listOf(TEXT_USE))
        val numberUse = generic.namedUse(listOf(INT_USE))
        val resources =
            mapOf(
                text to AuthoringRecord.of(TypeSelection.of(textUse), emptyMap()),
                number to AuthoringRecord.of(TypeSelection.of(numberUse), emptyMap()),
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
        val definition =
            TypeDefinition.partial(
                id = generic,
                parameters =
                    listOf(
                        TypeParameter.partial(key = ParameterKey(owner = generic, index = 0), name = "T"),
                        TypeParameter.partial(key = ParameterKey(owner = generic, index = 1), name = "U"),
                    ),
                representation = RepresentationTemplate.createRecord(fields = emptyList(), form = RecordForm.CONCRETE),
            )
        val catalog = DefinitionCatalog(TEST_DEFINITIONS + listOf(definition))
        val resource = ResourceId(value = "pending")
        val unresolved = ResourceId(value = "unresolved")
        val textUse = generic.namedUse(listOf(TEXT_USE, INT_USE))
        val numberUse = generic.namedUse(listOf(INT_USE, INT_USE))
        val record =
            AuthoringRecord.of(
                TypeSelection.of(generic, mapOf(0 to TEXT_USE)),
                emptyMap(),
            )
        val resources =
            mapOf(
                resource to record,
                unresolved to
                    record.copy(
                        configuration = TypeSelection.of(generic),
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
            (InputIdentity.Membership(location(resource, "numbers")) in reads.observedInputs()) shouldBe true
        }
    }

    test("a read marked incomplete reports the check incomplete even when inputs are missing") {
        captured(emptyMap()) { lease ->
            val reads = CapturedAuthoringReads(lease.originalView())
            reads.resourceBinding(ResourceId(value = "missing"))
            reads.recordIncomplete("graph traversal limit exceeded")

            val origin = RuleOrigin(owner = TEST_TYPE, ordinal = 0)
            val outcome = reads.health().outcome(origin, CheckRunDiagnostics.of(RuleId(origin = origin, localIndex = 0), "test"))

            outcome shouldBe CheckOutcome.IncompleteWrapper("graph traversal limit exceeded")
        }
    }
}
