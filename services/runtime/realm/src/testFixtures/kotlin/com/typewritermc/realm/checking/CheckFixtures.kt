package com.typewritermc.realm.checking

import com.typewritermc.authoring.CompleteValue
import com.typewritermc.authoring.DraftBinding
import com.typewritermc.authoring.DraftExpectation
import com.typewritermc.authoring.ReadContext
import com.typewritermc.authoring.of
import com.typewritermc.authoring.with
import com.typewritermc.checking.CheckEvaluation
import com.typewritermc.checking.CheckInput
import com.typewritermc.checking.CheckRecipe
import com.typewritermc.checking.RegisteredPredicate
import com.typewritermc.configuration.field
import com.typewritermc.realm.authoring.AuthoringSeed
import com.typewritermc.realm.authoring.CapturedAuthoringReads
import com.typewritermc.realm.authoring.InMemoryAuthoringViewStore
import com.typewritermc.realm.authoring.TEST_DEFINITIONS
import com.typewritermc.realm.authoring.TEST_TYPE
import com.typewritermc.realm.authoring.TestCatalogLease
import com.typewritermc.realm.authoring.ViewReadHealth
import com.typewritermc.realm.authoring.ViewReadLimits
import com.typewritermc.realm.authoring.location
import com.typewritermc.realm.authoring.record
import com.typewritermc.testkit.ready
import com.typewritermc.types.named
import com.typewritermc.types.namedUse
import com.typewritermc.types.use
import skirout.editor.v1.authoring_facts.EditExpectation
import skirout.editor.v1.checking.CheckInstanceId
import skirout.editor.v1.checking.CheckOutcome
import skirout.editor.v1.checking.CheckResult
import skirout.editor.v1.checking.CheckTicket
import skirout.editor.v1.diagnostic.DiagnosticSeverity
import skirout.editor.v1.diagnostic.DiagnosticTemplate
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.CheckExecutionId
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.FieldPatternSegment
import skirout.editor.v1.type_catalog.RelativeFieldPattern
import skirout.editor.v1.type_catalog.RuleId
import skirout.editor.v1.type_catalog.RuleOrigin
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.TypeTemplate
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.kernel.v1.resource_id.ResourceId

internal val page = ResourceId(value = "page")
internal val instance =
    CheckInstanceId(
        rule = RuleId(origin = RuleOrigin(owner = TEST_TYPE, ordinal = 0), localIndex = 0),
        location = ValueLocation.of(page),
    )
internal val catalog = CatalogGeneration(value = "catalog")
internal val first =
    CheckTicket(instance = instance, incarnation = "catalog", execution = CheckExecutionId(value = "first"), catalog = catalog)

/** A finished check result of [ticket] that read the page name as [name]. */
internal fun resultOf(
    ticket: CheckTicket = first,
    name: String = "Quest",
    outcome: CheckOutcome = CheckOutcome.FINISHED,
) = CheckResult(
    ticket = ticket,
    outcome = outcome,
    expectations = listOf(EditExpectation.createValue(at = location(page, "name"), expected = DataValue.StringValueWrapper(name))),
    findings = emptyList(),
)

/** Runs [test] with a view store whose page is named [name], admitting against [current] as the latest execution. */
internal fun admitting(
    name: String = "Quest",
    current: CheckTicket = first,
    test: (InMemoryAuthoringViewStore, DefaultCheckAdmission) -> Unit,
) {
    InMemoryAuthoringViewStore(TestCatalogLease(catalog), AuthoringSeed(mapOf(page to record(name = name)))).use { store ->
        val executions =
            object : CurrentCheckExecutions {
                override fun ticket(instance: CheckInstanceId) = current
            }
        test(store, DefaultCheckAdmission(store, executions))
    }
}

/** Admits [result] as current findings and reports whether it was installed. */
internal fun DefaultCheckAdmission.publish(result: CheckResult): Pair<AdmissionResult, Boolean> {
    var installed = false
    return requireCurrentExecutionAndInputs(result) { installed = true } to installed
}

/** Evaluates [recipe] on [record] saved as [RESOURCE], returning the evaluation and the health of its reads. */
internal fun evaluate(
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

internal fun recipe(
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

internal fun predicate(
    types: List<TypeTemplate>,
    callback: (List<CompleteValue>) -> Boolean,
) = object : RegisteredPredicate {
    override val inputTypes: List<TypeTemplate> = types

    override fun invoke(completeInputs: List<CompleteValue>): Boolean = callback(completeInputs)
}

internal fun pattern(
    field: String,
    descendant: FieldPatternSegment,
) = RelativeFieldPattern(segments = listOf(FieldPatternSegment.field(field), descendant))

internal val RESOURCE = ResourceId(value = "resource")
