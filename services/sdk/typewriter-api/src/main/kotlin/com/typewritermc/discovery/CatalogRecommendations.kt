package com.typewritermc.discovery

import com.typewritermc.types.StandardTypes
import com.typewritermc.types.canonicalText
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.catalog.isReady
import com.typewritermc.types.nullable
import com.typewritermc.types.unknownVariant
import com.typewritermc.types.use
import skirout.editor.v1.catalog.TypeRecommendation
import skirout.editor.v1.type_catalog.NamedTypeUse
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeTemplate
import skirout.editor.v1.type_catalog.TypeUse

internal fun typeRecommendations(
    definitions: Map<TypeDefinitionId, TypeDefinition>,
    catalog: CheckedCatalog,
): List<TypeRecommendation> {
    val standard = StandardTypes.definitions.map(TypeDefinition::id).toSet()
    val counts = linkedMapOf<NamedTypeUse, Long>()

    fun count(template: TypeTemplate) {
        when (template) {
            is TypeTemplate.ParameterWrapper, is TypeTemplate.ScalarWrapper -> {
                Unit
            }

            is TypeTemplate.NullableWrapper -> {
                count(template.value.value)
            }

            is TypeTemplate.NamedWrapper -> {
                val representation = definitions[template.value.definition]?.representation
                val container =
                    representation is RepresentationTemplate.SequenceWrapper || representation is RepresentationTemplate.MappingWrapper
                if (!container && template.value.definition !in standard && catalog.isReady(template.value.definition)) {
                    (template.toCompleteUse() as? TypeUse.NamedWrapper)?.takeIf { catalog.resolve(it) is Resolution.Ready }?.let { use ->
                        counts[use.value] = counts.getOrDefault(use.value, 0) + 1
                    }
                }
                template.value.arguments.forEach(::count)
            }

            else -> {
                unknownVariant(template)
            }
        }
    }

    definitions.values.filter { catalog.isReady(it.id) }.forEach { definition ->
        val record = definition.representation as? RepresentationTemplate.RecordWrapper ?: return@forEach
        record.value.fields
            .filter { field -> field.overrides.isEmpty() }
            .forEach { field -> count(field.type) }
    }
    return counts.entries
        .sortedWith(compareByDescending<Map.Entry<NamedTypeUse, Long>> { it.value }.thenBy { it.key.use.canonicalText })
        .take(TYPE_RECOMMENDATION_LIMIT)
        .map { (type, occurrences) -> TypeRecommendation(type = type, occurrences = occurrences) }
}

private fun TypeTemplate.toCompleteUse(): TypeUse? =
    when (this) {
        is TypeTemplate.ParameterWrapper -> {
            null
        }

        is TypeTemplate.ScalarWrapper -> {
            value.use
        }

        is TypeTemplate.NullableWrapper -> {
            value.value.toCompleteUse()?.nullable()
        }

        is TypeTemplate.NamedWrapper -> {
            val completeArguments = value.arguments.map(TypeTemplate::toCompleteUse)
            if (completeArguments.any { it == null }) null else value.definition.use(completeArguments.filterNotNull())
        }

        else -> {
            unknownVariant(this)
        }
    }

private const val TYPE_RECOMMENDATION_LIMIT = 10
