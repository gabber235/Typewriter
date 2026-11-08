package com.typewritermc.discovery

import com.typewritermc.types.StandardTypes
import com.typewritermc.types.canonicalText
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.catalog.isReady
import com.typewritermc.types.closedUse
import com.typewritermc.types.named
import com.typewritermc.types.use
import com.typewritermc.types.walk
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
        template.walk().forEach { node ->
            val named = node.named ?: return@forEach
            val representation = definitions[named.definition]?.representation
            val container =
                representation is RepresentationTemplate.SequenceWrapper || representation is RepresentationTemplate.MappingWrapper
            if (!container && named.definition !in standard && catalog.isReady(named.definition)) {
                (node.closedUse as? TypeUse.NamedWrapper)?.takeIf { catalog.resolve(it) is Resolution.Ready }?.let { use ->
                    counts[use.value] = counts.getOrDefault(use.value, 0) + 1
                }
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

private const val TYPE_RECOMMENDATION_LIMIT = 10
