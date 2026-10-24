@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.authoring

import com.typewritermc.authoring.record
import com.typewritermc.expression.DefaultExpressionEvaluator
import com.typewritermc.expression.ExpressionBindings
import com.typewritermc.expression.ExpressionValueReader
import com.typewritermc.expression.operations.CatalogPortableTypes
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.fields
import com.typewritermc.types.named
import com.typewritermc.types.record
import com.typewritermc.types.template
import com.typewritermc.types.unwrapNamed
import com.typewritermc.types.use
import skirout.editor.v1.catalog.PublishedType
import skirout.editor.v1.catalog.ResourceDisplayFormulas
import skirout.editor.v1.expression.EvaluationBudget
import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ResourceTarget
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeSelection

/** One published resource display with its formulas checked against the catalog that published them. */
class CheckedResourceDisplay(
    val target: ResourceTarget,
    val label: ExpressionNode,
    val accent: ExpressionNode,
    val icon: ExpressionNode,
) {
    /** The wire form editors receive. */
    val formulas: ResourceDisplayFormulas
        get() = ResourceDisplayFormulas(target = target, label = label, accent = accent, icon = icon)
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
    private val anyResource = displays.firstOrNull { it.target == ResourceTarget.ANY_RESOURCE }
    private val typed = displays.filter { it.target is ResourceTarget.TypeWrapper }
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
     * or fails within its budget. Kotlin evaluates the rule profile only, so a label that reaches a profile panel
     * operation, such as the subject's published type name, fails here and is null; editors evaluate it in full.
     */
    context(reads: AuthoredReads)
    fun label(
        record: AuthoringRecord,
        catalog: CheckedCatalog,
    ): String? {
        val configuration = record.configuration as? TypeSelection.CompleteWrapper ?: return null
        val display = displayFor(configuration.use.definition, catalog) ?: return null
        val subject = DataValue.named(configuration.use, DataValue.RecordWrapper(record.payload))
        val evaluator =
            DefaultExpressionEvaluator(
                ExpressionValueReader { error("Display formulas read their subject as a local value.") },
                CatalogPortableTypes(catalog),
            )
        val result =
            evaluator.evaluateScoped(
                display.label,
                ExpressionBindings(emptyMap()),
                mapOf(ResourceDisplaySubject.binding to subject),
                DISPLAY_BUDGET,
            )
        return ((result as? Availability.Available)?.value?.unwrapNamed() as? DataValue.StringValueWrapper)?.value
    }
}

private val CheckedResourceDisplay.targetDefinition: TypeDefinitionId
    get() = (target as ResourceTarget.TypeWrapper).template.definition

/** Display formulas name a resource from a few fields; this bounds a pathological formula, not a real one. */
private val DISPLAY_BUDGET = EvaluationBudget(maxSteps = 10_000, maxCollectionItems = 1_000)
