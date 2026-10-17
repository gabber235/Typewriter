package com.typewritermc.discovery

import com.typewritermc.types.RepresentationTemplate
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeTemplate
import com.typewritermc.types.TypeUse
import com.typewritermc.types.catalog.TypeRecommendation

internal fun typeRecommendations(
    definitions: Map<TypeDefinitionId, TypeDefinition>,
    unavailable: Set<TypeDefinitionId> = emptySet(),
): List<TypeRecommendation> {
    val standard = StandardTypes.definitions.map(TypeDefinition::id).toSet()
    val counts = linkedMapOf<TypeUse.Named, Long>()

    fun count(template: TypeTemplate) {
        when (template) {
            is TypeTemplate.Parameter, is TypeTemplate.Scalar -> {
                Unit
            }

            is TypeTemplate.Nullable -> {
                count(template.value)
            }

            is TypeTemplate.Named -> {
                val representation = definitions[template.definition]?.representation
                val container = representation is RepresentationTemplate.Sequence || representation is RepresentationTemplate.Mapping
                if (!container && template.definition !in standard && template.definition !in unavailable) {
                    (template.toCompleteUse() as? TypeUse.Named)?.let { use ->
                        counts[use] = counts.getOrDefault(use, 0) + 1
                    }
                }
                template.arguments.forEach(::count)
            }
        }
    }

    definitions.values.forEach { definition ->
        val record = definition.representation as? RepresentationTemplate.Record ?: return@forEach
        record.fields.filter { field -> field.overrides.isEmpty() }.forEach { field -> count(field.type) }
    }
    return counts.entries
        .sortedWith(compareByDescending<Map.Entry<TypeUse.Named, Long>> { it.value }.thenBy { it.key.toString() })
        .take(TYPE_RECOMMENDATION_LIMIT)
        .map { (type, occurrences) -> TypeRecommendation(type, occurrences) }
}

private fun TypeTemplate.toCompleteUse(): TypeUse? =
    when (this) {
        is TypeTemplate.Parameter -> {
            null
        }

        is TypeTemplate.Scalar -> {
            TypeUse.Scalar(kind)
        }

        is TypeTemplate.Nullable -> {
            value.toCompleteUse()?.let(TypeUse::Nullable)
        }

        is TypeTemplate.Named -> {
            val completeArguments = arguments.map(TypeTemplate::toCompleteUse)
            if (completeArguments.any { it == null }) null else TypeUse.Named(definition, completeArguments.filterNotNull())
        }
    }

private const val TYPE_RECOMMENDATION_LIMIT = 10
