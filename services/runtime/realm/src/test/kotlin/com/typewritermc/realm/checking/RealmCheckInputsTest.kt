package com.typewritermc.realm.checking

import com.typewritermc.authoring.ArgumentSelection
import com.typewritermc.authoring.AuthoringRecord
import com.typewritermc.authoring.Availability
import com.typewritermc.authoring.CompleteValue
import com.typewritermc.authoring.DraftBinding
import com.typewritermc.authoring.DraftExpectation
import com.typewritermc.authoring.ItemId
import com.typewritermc.authoring.PathSegment
import com.typewritermc.authoring.ReadContext
import com.typewritermc.authoring.TypeSelection
import com.typewritermc.authoring.ValueLocation
import com.typewritermc.authoring.ValuePath
import com.typewritermc.checking.CheckInput
import com.typewritermc.checking.CheckOutcome
import com.typewritermc.checking.CheckRecipe
import com.typewritermc.checking.DiagnosticSeverity
import com.typewritermc.checking.DiagnosticTemplate
import com.typewritermc.checking.RegisteredPredicate
import com.typewritermc.checking.SnapshotId
import com.typewritermc.configuration.FieldPatternSegment
import com.typewritermc.configuration.RelativeFieldPattern
import com.typewritermc.configuration.RuleOrigin
import com.typewritermc.realm.authoring.AuthoredSnapshotSeed
import com.typewritermc.realm.authoring.InMemoryAuthoringSnapshotStore
import com.typewritermc.types.CollectionKind
import com.typewritermc.types.DataValue
import com.typewritermc.types.FieldDeclaration
import com.typewritermc.types.FieldOwner
import com.typewritermc.types.IntegerWidth
import com.typewritermc.types.ListItem
import com.typewritermc.types.MapRow
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
import com.typewritermc.types.catalog.Resolution
import de.infix.testBalloon.framework.core.testSuite
import java.math.BigInteger
import java.util.concurrent.atomic.AtomicInteger

val RealmCheckInputsTest by testSuite {
    test("mapKeysAndValuesShareTheSameStableRowOccurrence") {
        val mapParameterKey = ParameterKey(MAP_TYPE, 0)
        val mapParameterValue = ParameterKey(MAP_TYPE, 1)
        val mapUse = TypeUse.Named(MAP_TYPE, listOf(INT_USE, INT_USE))
        val root =
            TypeDefinition(
                id = TEST_TYPE,
                representation =
                    RepresentationTemplate.Record(
                        listOf(
                            FieldDeclaration(
                                FieldOwner(TEST_TYPE, "mapping"),
                                TypeTemplate.Named(
                                    MAP_TYPE,
                                    listOf(TypeTemplate.Scalar(INT_KIND), TypeTemplate.Scalar(INT_KIND)),
                                ),
                            ),
                        ),
                    ),
            )
        val map =
            TypeDefinition(
                id = MAP_TYPE,
                parameters = listOf(TypeParameter(mapParameterKey, "K"), TypeParameter(mapParameterValue, "V")),
                representation =
                    RepresentationTemplate.Mapping(
                        TypeTemplate.Parameter(mapParameterKey),
                        TypeTemplate.Parameter(mapParameterValue),
                    ),
            )
        val catalog = TestCatalogLease(definitions = listOf(root, map))
        val resource = ResourceId("map")
        val record =
            AuthoringRecord(
                TypeSelection.Complete(TypeUse.Named(TEST_TYPE)),
                mapOf(
                    "mapping" to
                        DataValue.Named(
                            mapUse,
                            DataValue.MapValue(
                                listOf(
                                    MapRow(ItemId("a"), integer(1), integer(1)),
                                    MapRow(ItemId("b"), integer(2), integer(2)),
                                ),
                            ),
                        ),
                ),
            )
        val calls = AtomicInteger()
        val predicate =
            predicate(listOf(TypeTemplate.Scalar(INT_KIND), TypeTemplate.Scalar(INT_KIND))) { values ->
                calls.incrementAndGet()
                values[0].value == values[1].value
            }
        val recipe =
            recipe(
                listOf(
                    CheckInput(TEST_TYPE, pattern("mapping", FieldPatternSegment.Keys), TypeTemplate.Scalar(INT_KIND)),
                    CheckInput(TEST_TYPE, pattern("mapping", FieldPatternSegment.Values), TypeTemplate.Scalar(INT_KIND)),
                ),
                predicate,
            )
        val store = store(catalog, resource, record)
        val lease = store.capture()
        val reads = SnapshotReads(lease.originalView())

        val result = with(reads) { RealmCheckInputs().evaluate(recipe, binding(catalog, resource)) }

        assertEquals(CheckOutcome.Finished, result.outcome)
        assertTrue(result.findings.isEmpty())
        assertEquals(2, calls.get())
        lease.close()
        store.close()
    }

    test("completeFindingsRemainVisibleWhenAnotherOccurrenceNeedsInput") {
        val catalog = TestCatalogLease()
        val resource = ResourceId("list")
        val record =
            record(numbers = emptyList()).copy(
                fields =
                    record(numbers = emptyList()).fields +
                        (
                            "numbers" to
                                DataValue.Named(
                                    LIST_USE,
                                    DataValue.ListValue(
                                        listOf(
                                            ListItem(ItemId("missing"), DataValue.Unfilled),
                                            ListItem(ItemId("known"), integer(2)),
                                        ),
                                    ),
                                )
                        ),
            )
        val recipe =
            recipe(
                listOf(CheckInput(TEST_TYPE, pattern("numbers", FieldPatternSegment.Items), TypeTemplate.Scalar(INT_KIND))),
                predicate(listOf(TypeTemplate.Scalar(INT_KIND))) { false },
            )
        val store = store(catalog, resource, record)
        val lease = store.capture()
        val reads = SnapshotReads(lease.originalView())

        val result = with(reads) { RealmCheckInputs().evaluate(recipe, binding(catalog, resource)) }

        assertIs<CheckOutcome.NeedsInput>(result.outcome)
        assertEquals(1, result.findings.size)
        assertEquals(
            ItemId("known"),
            (
                result.findings
                    .single()
                    .primary
                    ?.path
                    ?.segments
                    ?.last() as PathSegment.Item
            ).id,
        )
        lease.close()
        store.close()
    }

    test("occurrenceCartesianProductsStopAtTheCapturedReadBudget") {
        val catalog = TestCatalogLease()
        val resource = ResourceId("list")
        val record = record(numbers = listOf("a" to 1, "b" to 2))
        val recipe =
            recipe(
                listOf(CheckInput(TEST_TYPE, pattern("numbers", FieldPatternSegment.Items), TypeTemplate.Scalar(INT_KIND))),
                predicate(listOf(TypeTemplate.Scalar(INT_KIND))) { true },
            )
        val store = store(catalog, resource, record)
        val lease = store.capture()
        val reads = SnapshotReads(lease.originalView(), limits = SnapshotReadLimits(maxCheckTuples = 1))

        with(reads) { RealmCheckInputs().evaluate(recipe, binding(catalog, resource)) }

        assertEquals(listOf("check occurrence tuple limit exceeded"), reads.health().incomplete)
        lease.close()
        store.close()
    }
}

private fun recipe(
    inputs: List<CheckInput>,
    predicate: RegisteredPredicate,
) = CheckRecipe(
    owner = RuleOrigin(TEST_TYPE, 0),
    inputs = inputs,
    predicate = predicate,
    diagnostic =
        DiagnosticTemplate(
            code = "test",
            message = "invalid",
            severity = DiagnosticSeverity.Error,
            targets = listOf(inputs.first().path),
        ),
)

private fun predicate(
    types: List<TypeTemplate>,
    callback: (List<CompleteValue>) -> Boolean,
) = object : RegisteredPredicate {
    override val inputTypes: List<TypeTemplate> = types

    override fun invoke(completeInputs: List<CompleteValue>): Boolean = callback(completeInputs)
}

private fun pattern(
    field: String,
    descendant: FieldPatternSegment,
) = RelativeFieldPattern(listOf(FieldPatternSegment.Field(field), descendant))

private fun binding(
    catalog: TestCatalogLease,
    resource: ResourceId,
): DraftBinding {
    val checked = (catalog.checked.resolve(TypeUse.Named(TEST_TYPE)) as Resolution.Ready).value
    return DraftBinding(
        SnapshotId("s0"),
        catalog.generation,
        ReadContext(SnapshotId("s0"), catalog.generation),
        ValueLocation(resource, ValuePath()),
        DraftExpectation.Complete(checked),
        TypeSelection.Complete(TypeUse.Named(TEST_TYPE)),
    )
}

private fun store(
    catalog: TestCatalogLease,
    resource: ResourceId,
    record: AuthoringRecord,
): InMemoryAuthoringSnapshotStore {
    val resources = mapOf(resource to record)
    return InMemoryAuthoringSnapshotStore(
        catalog,
        AuthoredSnapshotSeed(SnapshotId("s0"), resources, tokensFor(resources, catalog.generation)),
    )
}

private fun integer(value: Int): DataValue.Integer = DataValue.Integer(BigInteger.valueOf(value.toLong()))

private val MAP_TYPE = TypeDefinitionId(TypeId.Qualified("typewriter", "map"), 1)
private val INT_KIND = ScalarKind.Integer(IntegerWidth.SIGNED_32)
