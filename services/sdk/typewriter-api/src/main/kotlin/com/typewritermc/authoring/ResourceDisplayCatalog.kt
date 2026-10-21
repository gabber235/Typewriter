@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.authoring

import com.typewritermc.expression.CanonicalQueryReader
import com.typewritermc.expression.CheckedExpressionProgram
import com.typewritermc.expression.DefaultExpressionEvaluator
import com.typewritermc.expression.EvaluationBudget
import com.typewritermc.expression.ExpressionBindings
import com.typewritermc.expression.ExpressionValueReader
import com.typewritermc.types.DataValue
import com.typewritermc.types.ResourceId
import com.typewritermc.types.ResourceTarget
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.ResourceDisplayFormulas
import com.typewritermc.types.template
import com.typewritermc.types.unwrapNamed
import com.typewritermc.types.use
import skirout.editor.v1.catalog.PublishedType
import skirout.editor.v1.type_catalog.TypeDefinitionId

/** One published resource display with its formulas checked against the catalog that published them. */
class CheckedResourceDisplay(
    val target: ResourceTarget,
    val label: CheckedExpressionProgram,
    val accent: CheckedExpressionProgram,
    val icon: CheckedExpressionProgram,
) {
    /** The wire form editors receive. */
    val formulas: ResourceDisplayFormulas
        get() = ResourceDisplayFormulas(target, label.body, accent.body, icon.body)
}

/**
 * The resource displays of one catalog generation and the published types their formulas read.
 *
 * [displayFor] picks the display whose target type is the most specific nominal supertype of a resource's type. When
 * no typed display applies, or two unrelated ones apply equally, the any resource display applies. Editors apply the
 * same rule to the published formulas.
 */
class ResourceDisplayCatalog(
    val displays: List<CheckedResourceDisplay> = emptyList(),
    types: List<PublishedType> = emptyList(),
) {
    private val anyResource = displays.firstOrNull { it.target == ResourceTarget.AnyResource }
    private val typed = displays.filter { it.target is ResourceTarget.Type }
    private val types = types.associateBy { it.definition.id }

    /** The published type of [definition], or null when this catalog publishes no such type. */
    fun publishedType(definition: TypeDefinitionId): PublishedType? = types[definition]

    /** The display that names resources of [definition], or null when the catalog declares none at all. */
    fun displayFor(
        definition: TypeDefinitionId,
        catalog: CheckedCatalog,
    ): CheckedResourceDisplay? {
        val applicable = typed.filter { catalog.isNominalSubtype(definition, it.targetDefinition) }
        val mostSpecific =
            applicable.filter { candidate ->
                applicable.all { other -> catalog.isNominalSubtype(candidate.targetDefinition, other.targetDefinition) }
            }
        return mostSpecific.singleOrNull() ?: anyResource
    }

    /**
     * The label of [record] from its display. Display formulas read only their subject, so the record alone names
     * it. Null for a pending type selection, which has no complete subject value, and when the label is unavailable
     * or fails within its budget.
     */
    context(reads: AuthoredReads)
    fun label(
        record: AuthoringRecord,
        catalog: CheckedCatalog,
    ): String? {
        val configuration = record.configuration as? TypeSelection.Complete ?: return null
        val display = displayFor(configuration.use.definition, catalog) ?: return null
        val subject = DataValue.Named(configuration.use, DataValue.Record(record.fields))
        val evaluator =
            DefaultExpressionEvaluator(
                ExpressionValueReader { error("Display formulas read their subject as a local value.") },
                queries = DisplayQueries(catalog),
            )
        val result =
            evaluator.evaluateChecked(
                display.label,
                ExpressionBindings(emptyMap()),
                DISPLAY_BUDGET,
                mapOf(ResourceDisplaySubject.binding to subject),
            )
        return ((result as? Availability.Available)?.value?.unwrapNamed() as? DataValue.StringValue)?.value
    }

    /** Answers the declaration queries of display formulas; catalog assembly rejects formulas reading other resources. */
    private inner class DisplayQueries(
        override val catalog: CheckedCatalog,
    ) : CanonicalQueryReader {
        context(reads: AuthoredReads)
        override fun resource(id: ResourceId): Availability<AuthoringRecord> =
            Availability.Unavailable(listOf(ValueLocation(id, ValuePath())))

        context(reads: AuthoredReads)
        override fun declaration(id: TypeDefinitionId): Availability<PublishedType> =
            types[id]?.let { Availability.Available(it) } ?: Availability.Unavailable(emptyList())
    }
}

private val CheckedResourceDisplay.targetDefinition: TypeDefinitionId
    get() = (target as ResourceTarget.Type).template.definition

/** Display formulas name a resource from a few fields; this bounds a pathological formula, not a real one. */
private val DISPLAY_BUDGET = EvaluationBudget(maxSteps = 10_000, maxCollectionItems = 1_000)
