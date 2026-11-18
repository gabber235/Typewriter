package com.typewritermc.realm.checking

import com.typewritermc.authoring.CompleteValue
import com.typewritermc.authoring.DraftBinding
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
import com.typewritermc.types.catalog.ResourceType
import com.typewritermc.types.use
import skirout.editor.v1.diagnostic.DiagnosticSeverity
import skirout.editor.v1.diagnostic.DiagnosticTemplate
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.FieldPatternSegment
import skirout.editor.v1.type_catalog.RelativeFieldPattern
import skirout.editor.v1.type_catalog.RuleId
import skirout.editor.v1.type_catalog.RuleOrigin
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeTemplate
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.kernel.v1.resource_id.ResourceId

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
                    ResourceType.Complete(catalog.checked.ready(TEST_TYPE.use())),
                )
            with(reads) {
                RealmCheckInputs().evaluate(
                    recipe,
                    binding,
                    CheckRunDiagnostics.of(RuleId(origin = recipe.owner, localIndex = 0), "test")::next,
                )
            } to reads.health()
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
