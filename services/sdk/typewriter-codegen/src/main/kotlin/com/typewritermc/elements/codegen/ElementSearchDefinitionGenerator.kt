package com.typewritermc.elements.codegen

import com.typewritermc.elements.ContentSearchDefinition
import com.typewritermc.elements.ContentSearchMode
import com.typewritermc.elements.ContentSearchPolicy
import com.typewritermc.elements.ContentSearchPropertyOverride
import com.typewritermc.types.NominalTypeKind
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeExpression
import com.typewritermc.types.TypeGraph
import com.typewritermc.types.TypeId

internal object ElementSearchDefinitionGenerator {
    fun generate(
        graph: TypeGraph,
        overrides: List<ContentSearchPropertyOverride>,
    ): ElementSearchGenerationResult {
        val definitions = graph.definitions.associateBy(TypeDefinition::id)
        val invalid =
            overrides.filter { override ->
                override.mode != ContentSearchMode.NONE &&
                    !graph.propertySupportsExplicitText(override, definitions)
            }
        if (invalid.isNotEmpty()) return ElementSearchGenerationResult.InvalidOverrides(invalid)

        return ElementSearchGenerationResult.Success(
            ContentSearchDefinition(
                policy = ContentSearchPolicy.ORDINARY_TEXT,
                propertyOverrides = overrides.sortedWith(searchOverrideComparator),
                revisionFingerprintInputs =
                    graph.definitions
                        .map(TypeDefinition::id)
                        .distinct()
                        .sortedBy(ResolvedTypeRef::sortKey),
            ),
        )
    }
}

internal sealed interface ElementSearchGenerationResult {
    data class Success(
        val definition: ContentSearchDefinition,
    ) : ElementSearchGenerationResult

    data class InvalidOverrides(
        val overrides: List<ContentSearchPropertyOverride>,
    ) : ElementSearchGenerationResult
}

private fun TypeGraph.propertySupportsExplicitText(
    override: ContentSearchPropertyOverride,
    definitions: Map<ResolvedTypeRef, TypeDefinition>,
): Boolean {
    val owner = definitions[override.ownerType] ?: return false
    val field = (owner.representation as? TypeExpression.Record)?.fields?.singleOrNull { it.name == override.field } ?: return false
    return field.type.hasExplicitTextLeaf(definitions, emptyMap(), emptySet())
}

private fun TypeExpression.hasExplicitTextLeaf(
    definitions: Map<ResolvedTypeRef, TypeDefinition>,
    parameters: Map<String, TypeExpression>,
    visiting: Set<ResolvedTypeRef>,
): Boolean =
    when (this) {
        TypeExpression.Any,
        TypeExpression.Boolean,
        TypeExpression.Unit,
        is TypeExpression.Bytes,
        is TypeExpression.Decimal,
        is TypeExpression.Duration,
        is TypeExpression.Float,
        is TypeExpression.Integer,
        is TypeExpression.Timestamp,
        is TypeExpression.Reference,
        -> {
            false
        }

        is TypeExpression.StringType -> {
            true
        }

        is TypeExpression.Enumeration -> {
            valueType.hasExplicitTextLeaf(definitions, parameters, visiting)
        }

        is TypeExpression.ListType -> {
            element.hasExplicitTextLeaf(definitions, parameters, visiting)
        }

        is TypeExpression.MapType -> {
            key.hasExplicitTextLeaf(definitions, parameters, visiting) ||
                value.hasExplicitTextLeaf(definitions, parameters, visiting)
        }

        is TypeExpression.Record -> {
            fields.any { it.type.hasExplicitTextLeaf(definitions, parameters, visiting) }
        }

        is TypeExpression.Parameter -> {
            parameters[name]?.hasExplicitTextLeaf(definitions, parameters, visiting) == true
        }

        is TypeExpression.Named -> {
            reference.hasExplicitTextLeaf(definitions, visiting)
        }
    }

private fun ResolvedTypeRef.hasExplicitTextLeaf(
    definitions: Map<ResolvedTypeRef, TypeDefinition>,
    visiting: Set<ResolvedTypeRef>,
): Boolean {
    val definitionId = copy(arguments = emptyList())
    if (definitionId in visiting) return false
    val definition = definitions[definitionId] ?: return false
    val parameters =
        definition.parameters
            .mapIndexedNotNull {
                index,
                parameter,
                ->
                arguments.getOrNull(index)?.let { parameter.name to it }
            }.toMap()
    val nextVisiting = visiting + definitionId
    if (definition.representation.hasExplicitTextLeaf(definitions, parameters, nextVisiting)) return true
    if (definition.kind == NominalTypeKind.CONCRETE) return false
    return definitions.values.any { candidate ->
        candidate.isSubtypeOf(definitionId, definitions, emptySet()) &&
            candidate.id.hasExplicitTextLeaf(definitions, nextVisiting)
    }
}

private fun TypeDefinition.isSubtypeOf(
    target: ResolvedTypeRef,
    definitions: Map<ResolvedTypeRef, TypeDefinition>,
    visiting: Set<ResolvedTypeRef>,
): Boolean {
    if (id in visiting) return false
    if (parents.any { it.id == target.id && it.revision == target.revision }) return true
    val nextVisiting = visiting + id
    return parents.any { parent ->
        definitions[parent.copy(arguments = emptyList())]?.isSubtypeOf(target, definitions, nextVisiting) == true
    }
}

private val searchOverrideComparator =
    compareBy<ContentSearchPropertyOverride> { it.ownerType.sortKey }.thenBy(ContentSearchPropertyOverride::field)

private val ResolvedTypeRef.sortKey: String
    get() = "$id:$revision:${arguments.joinToString()}"
