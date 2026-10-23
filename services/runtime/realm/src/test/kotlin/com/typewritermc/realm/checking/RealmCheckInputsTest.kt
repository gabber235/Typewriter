package com.typewritermc.realm.checking

import com.typewritermc.authoring.CompleteValue
import com.typewritermc.authoring.DraftBinding
import com.typewritermc.authoring.DraftExpectation
import com.typewritermc.authoring.ReadContext
import com.typewritermc.authoring.id
import com.typewritermc.authoring.of
import com.typewritermc.authoring.root
import com.typewritermc.authoring.with
import com.typewritermc.checking.CheckInput
import com.typewritermc.checking.CheckRecipe
import com.typewritermc.checking.RegisteredPredicate
import com.typewritermc.configuration.field
import com.typewritermc.realm.authoring.AuthoringSeed
import com.typewritermc.realm.authoring.InMemoryAuthoringViewStore
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.fields
import com.typewritermc.types.integer
import com.typewritermc.types.integerScalar
import com.typewritermc.types.listValue
import com.typewritermc.types.mapValue
import com.typewritermc.types.named
import com.typewritermc.types.namedUse
import com.typewritermc.types.qualified
import com.typewritermc.types.template
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import skirout.editor.v1.checking.CheckOutcome
import skirout.editor.v1.diagnostic.DiagnosticSeverity
import skirout.editor.v1.diagnostic.DiagnosticTemplate
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.FieldDeclaration
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.FieldPatternSegment
import skirout.editor.v1.type_catalog.IntegerWidth
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.ListItem
import skirout.editor.v1.type_catalog.MapRow
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.PathSegment
import skirout.editor.v1.type_catalog.RelativeFieldPattern
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.RuleOrigin
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeParameter
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.TypeTemplate
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.kernel.v1.resource_id.ResourceId
import java.math.BigInteger
import java.util.concurrent.atomic.AtomicInteger

val RealmCheckInputsTest by testSuite {
    test("mapKeysAndValuesShareTheSameStableRowOccurrence") {
        val mapParameterKey = ParameterKey(owner = MAP_TYPE, index = 0)
        val mapParameterValue = ParameterKey(owner = MAP_TYPE, index = 1)
        val mapUse = MAP_TYPE.namedUse(listOf(INT_USE, INT_USE))
        val root =
            TypeDefinition.partial(
                id = TEST_TYPE,
                representation =
                    RepresentationTemplate.createRecord(
                        fields =
                            listOf(
                                FieldDeclaration.partial(
                                    owner = FieldOwner(definition = TEST_TYPE, name = "mapping"),
                                    type = MAP_TYPE.template(listOf(INT_KIND.template, INT_KIND.template)),
                                ),
                            ),
                        abstract_ = false,
                    ),
            )
        val map =
            TypeDefinition.partial(
                id = MAP_TYPE,
                parameters =
                    listOf(
                        TypeParameter.partial(key = mapParameterKey, name = "K"),
                        TypeParameter.partial(key = mapParameterValue, name = "V"),
                    ),
                representation =
                    RepresentationTemplate.createMapping(
                        key = mapParameterKey.template,
                        value = mapParameterValue.template,
                    ),
            )
        val catalog = TestCatalogLease(definitions = listOf(root, map))
        val resource = ResourceId(value = "map")
        val record =
            AuthoringRecord.of(
                TypeSelection.CompleteWrapper(TEST_TYPE.namedUse()),
                mapOf(
                    "mapping" to
                        DataValue.named(
                            mapUse,
                            DataValue.mapValue(
                                listOf(
                                    MapRow(id = ItemId(value = "a"), key = integer(1), value = integer(1)),
                                    MapRow(id = ItemId(value = "b"), key = integer(2), value = integer(2)),
                                ),
                            ),
                        ),
                ),
            )
        val calls = AtomicInteger()
        val predicate =
            predicate(listOf(INT_KIND.template, INT_KIND.template)) { values ->
                calls.incrementAndGet()
                values[0].value == values[1].value
            }
        val recipe =
            recipe(
                listOf(
                    CheckInput(TEST_TYPE, pattern("mapping", FieldPatternSegment.KEYS), INT_KIND.template),
                    CheckInput(TEST_TYPE, pattern("mapping", FieldPatternSegment.VALUES), INT_KIND.template),
                ),
                predicate,
            )
        val store = store(catalog, resource, record)
        val lease = store.capture()
        val reads = CapturedAuthoringReads(lease.originalView())

        val result = with(reads) { RealmCheckInputs().evaluate(recipe, binding(catalog, resource)) }

        result.outcome shouldBe CheckOutcome.FINISHED
        result.findings.isEmpty() shouldBe true
        calls.get() shouldBe 2
        lease.close()
        store.close()
    }

    test("completeFindingsRemainVisibleWhenAnotherOccurrenceNeedsInput") {
        val catalog = TestCatalogLease()
        val resource = ResourceId(value = "list")
        val record =
            record(numbers = emptyList()).with(
                "numbers",
                DataValue.named(
                    LIST_USE,
                    DataValue.listValue(
                        listOf(
                            ListItem(id = ItemId(value = "missing"), value = DataValue.UNFILLED),
                            ListItem(id = ItemId(value = "known"), value = integer(2)),
                        ),
                    ),
                ),
            )
        val recipe =
            recipe(
                listOf(CheckInput(TEST_TYPE, pattern("numbers", FieldPatternSegment.ITEMS), INT_KIND.template)),
                predicate(listOf(INT_KIND.template)) { false },
            )
        val store = store(catalog, resource, record)
        val lease = store.capture()
        val reads = CapturedAuthoringReads(lease.originalView())

        val result = with(reads) { RealmCheckInputs().evaluate(recipe, binding(catalog, resource)) }

        result.outcome.shouldBeInstanceOf<CheckOutcome.NeedsInputWrapper>()
        result.findings.size shouldBe 1
        (
            result.findings
                .single()
                .primary
                ?.path
                ?.segments
                ?.last() as PathSegment.ItemWrapper
        ).id shouldBe ItemId(value = "known")
        lease.close()
        store.close()
    }

    test("occurrenceCartesianProductsStopAtTheCapturedReadBudget") {
        val catalog = TestCatalogLease()
        val resource = ResourceId(value = "list")
        val record = record(numbers = listOf("a" to 1, "b" to 2))
        val recipe =
            recipe(
                listOf(CheckInput(TEST_TYPE, pattern("numbers", FieldPatternSegment.ITEMS), INT_KIND.template)),
                predicate(listOf(INT_KIND.template)) { true },
            )
        val store = store(catalog, resource, record)
        val lease = store.capture()
        val reads = CapturedAuthoringReads(lease.originalView(), limits = ViewReadLimits(maxCheckTuples = 1))

        with(reads) { RealmCheckInputs().evaluate(recipe, binding(catalog, resource)) }

        reads.health().incomplete shouldBe listOf("check occurrence tuple limit exceeded")
        lease.close()
        store.close()
    }
}

private fun recipe(
    inputs: List<CheckInput>,
    predicate: RegisteredPredicate,
) = CheckRecipe(
    owner = RuleOrigin(owner = TEST_TYPE, ordinal = 0),
    inputs = inputs,
    predicate = predicate,
    diagnostic =
        DiagnosticTemplate(
            code = "test",
            message = "invalid",
            severity = DiagnosticSeverity.ERROR,
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
) = RelativeFieldPattern(segments = listOf(FieldPatternSegment.field(field), descendant))

private fun binding(
    catalog: TestCatalogLease,
    resource: ResourceId,
): DraftBinding {
    val checked = (catalog.checked.resolve(TEST_TYPE.use()) as Resolution.Ready).value
    return DraftBinding(
        catalog.generation,
        ReadContext(catalog.generation),
        ValueLocation.of(resource),
        DraftExpectation.Complete(checked),
        TypeSelection.CompleteWrapper(TEST_TYPE.namedUse()),
    )
}

private fun store(
    catalog: TestCatalogLease,
    resource: ResourceId,
    record: AuthoringRecord,
): InMemoryAuthoringViewStore {
    val resources = mapOf(resource to record)
    return InMemoryAuthoringViewStore(
        catalog,
        AuthoringSeed(resources),
    )
}

private fun integer(value: Int): DataValue.IntegerWrapper = DataValue.integer(BigInteger.valueOf(value.toLong()))

private val MAP_TYPE = TypeDefinitionId.qualified("typewriter", "map")
private val INT_KIND = integerScalar(IntegerWidth.SIGNED_THIRTY_TWO)
