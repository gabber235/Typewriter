package com.typewritermc.realm.checking

import com.typewritermc.authoring.CompleteValue
import com.typewritermc.authoring.DraftBinding
import com.typewritermc.authoring.DraftExpectation
import com.typewritermc.authoring.ReadContext
import com.typewritermc.authoring.id
import com.typewritermc.authoring.of
import com.typewritermc.authoring.root
import com.typewritermc.authoring.with
import com.typewritermc.checking.CheckEvaluation
import com.typewritermc.checking.CheckInput
import com.typewritermc.checking.CheckRecipe
import com.typewritermc.checking.RegisteredPredicate
import com.typewritermc.configuration.field
import com.typewritermc.realm.authoring.AuthoringSeed
import com.typewritermc.realm.authoring.CapturedAuthoringReads
import com.typewritermc.realm.authoring.INT_USE
import com.typewritermc.realm.authoring.InMemoryAuthoringViewStore
import com.typewritermc.realm.authoring.LIST_USE
import com.typewritermc.realm.authoring.TEST_DEFINITIONS
import com.typewritermc.realm.authoring.TEST_TYPE
import com.typewritermc.realm.authoring.TestCatalogLease
import com.typewritermc.realm.authoring.ViewReadHealth
import com.typewritermc.realm.authoring.ViewReadLimits
import com.typewritermc.realm.authoring.record
import com.typewritermc.testkit.ready
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
import skirout.editor.v1.type_catalog.ValuePath
import skirout.kernel.v1.resource_id.ResourceId
import java.math.BigInteger

val RealmCheckInputsTest by testSuite {
    test("a check over map keys and values pairs them per row and reports only the mismatching row") {
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
                                    MapRow(id = ItemId(value = "c"), key = integer(3), value = integer(4)),
                                ),
                            ),
                        ),
                ),
            )
        val recipe =
            recipe(
                listOf(
                    CheckInput(TEST_TYPE, pattern("mapping", FieldPatternSegment.KEYS), INT_KIND.template),
                    CheckInput(TEST_TYPE, pattern("mapping", FieldPatternSegment.VALUES), INT_KIND.template),
                ),
                predicate(listOf(INT_KIND.template, INT_KIND.template)) { values -> values[0].value == values[1].value },
            )

        val (result) = evaluate(recipe, record, definitions = listOf(root, map))

        result.outcome shouldBe CheckOutcome.FINISHED
        result.findings.map { it.primary } shouldBe
            listOf(
                ValueLocation.of(
                    RESOURCE,
                    ValuePath(
                        segments =
                            listOf(
                                PathSegment.createField(name = "mapping"),
                                PathSegment.createItem(id = ItemId(value = "c")),
                                PathSegment.MAP_KEY,
                            ),
                    ),
                ),
            )
    }

    test("findings of complete occurrences stay visible when another occurrence needs input") {
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

        val (result) = evaluate(recipe, record)

        result.outcome shouldBe CheckOutcome.NeedsInputWrapper(listOf(numberAt("missing")))
        result.findings.map { it.primary } shouldBe listOf(numberAt("known"))
    }

    test("occurrences beyond the tuple budget make the check incomplete instead of silently partial") {
        val recipe =
            recipe(
                listOf(CheckInput(TEST_TYPE, pattern("numbers", FieldPatternSegment.ITEMS), INT_KIND.template)),
                predicate(listOf(INT_KIND.template)) { false },
            )

        val (result, health) = evaluate(recipe, record(numbers = listOf("a" to 1, "b" to 2)), ViewReadLimits(maxCheckTuples = 1))

        health.outcome(recipe.owner) shouldBe CheckOutcome.IncompleteWrapper("check occurrence tuple limit exceeded")
        result.findings.map { it.primary } shouldBe listOf(numberAt("a"))
    }
}

/** Evaluates [recipe] on [record] saved as [RESOURCE], returning the evaluation and the health of its reads. */
private fun evaluate(
    recipe: CheckRecipe,
    record: AuthoringRecord,
    limits: ViewReadLimits = ViewReadLimits(),
    definitions: List<TypeDefinition> = TEST_DEFINITIONS,
): Pair<CheckEvaluation, ViewReadHealth> {
    val catalog = TestCatalogLease(definitions = definitions)
    return InMemoryAuthoringViewStore(catalog, AuthoringSeed(mapOf(RESOURCE to record))).use { store ->
        store.capture().use { lease ->
            val reads = CapturedAuthoringReads(lease.originalView(), limits = limits)
            val binding =
                DraftBinding(
                    catalog.generation,
                    ReadContext(catalog.generation),
                    ValueLocation.of(RESOURCE),
                    DraftExpectation.Complete(catalog.checked.ready(TEST_TYPE.use())),
                    TypeSelection.CompleteWrapper(TEST_TYPE.namedUse()),
                )
            with(reads) { RealmCheckInputs().evaluate(recipe, binding) } to reads.health()
        }
    }
}

/** The location of the numbers item [item] of [RESOURCE]. */
private fun numberAt(item: String) =
    ValueLocation.of(
        RESOURCE,
        ValuePath(segments = listOf(PathSegment.createField(name = "numbers"), PathSegment.createItem(id = ItemId(value = item)))),
    )

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

private fun integer(value: Int): DataValue.IntegerWrapper = DataValue.integer(BigInteger.valueOf(value.toLong()))

private val RESOURCE = ResourceId(value = "resource")
private val MAP_TYPE = TypeDefinitionId.qualified("typewriter", "map")
private val INT_KIND = integerScalar(IntegerWidth.SIGNED_THIRTY_TWO)
