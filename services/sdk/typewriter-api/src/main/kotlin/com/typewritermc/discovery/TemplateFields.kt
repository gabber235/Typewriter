package com.typewritermc.discovery

import com.typewritermc.authoring.field
import com.typewritermc.authoring.name
import com.typewritermc.capability.id
import com.typewritermc.configuration.field
import com.typewritermc.configuration.name
import com.typewritermc.types.catalog.of
import com.typewritermc.types.catalog.reasons
import com.typewritermc.types.field
import com.typewritermc.types.fields
import com.typewritermc.types.namedTemplate
import com.typewritermc.types.substitute
import com.typewritermc.types.template
import com.typewritermc.types.unknownVariant
import skirout.editor.v1.catalog.ConfigurationRecipe
import skirout.editor.v1.catalog.DeclarationStatus
import skirout.editor.v1.catalog.EffectiveFieldTemplate
import skirout.editor.v1.diagnostic.DeclarationDiagnostic
import skirout.editor.v1.type_catalog.FieldDeclaration
import skirout.editor.v1.type_catalog.FieldPatternSegment
import skirout.editor.v1.type_catalog.NamedTypeTemplate
import skirout.editor.v1.type_catalog.RelativeFieldPattern
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId

internal fun TypeDefinition.effectiveFields(
    definitions: Map<TypeDefinitionId, TypeDefinition>,
    recipes: List<ConfigurationRecipe>,
): List<EffectiveFieldTemplate> {
    val fields = templateFields(definitions).fields
    val applicableOwners = (listOf(id) + transitiveAncestors(definitions).map(NamedTypeTemplate::definition)).toSet()
    return fields.map { field ->
        val matching =
            recipes.filter { recipe ->
                recipe.origin.owner in applicableOwners &&
                    recipe.relativePath.segments == listOf(FieldPatternSegment.field(field.owner.name))
            }
        EffectiveFieldTemplate(
            key = field.owner.name,
            owner = field.owner,
            type = field.type,
            rules = matching.flatMap(ConfigurationRecipe::rules).map { it.id },
        )
    }
}

internal data class TemplateFieldsResult(
    val fields: List<FieldDeclaration>,
    val diagnostics: List<DeclarationDiagnostic>,
)

internal fun TypeDefinition.templateFields(definitions: Map<TypeDefinitionId, TypeDefinition>): TemplateFieldsResult =
    collectTemplateFields(
        template = id.namedTemplate(parameters.map { it.key.template }),
        definitions = definitions,
        affected = id,
        stack = emptySet(),
    )

internal fun TypeDefinition.transitiveAncestors(definitions: Map<TypeDefinitionId, TypeDefinition>): List<NamedTypeTemplate> {
    val roots = parents
    val result = linkedSetOf<NamedTypeTemplate>()

    fun visit(
        template: NamedTypeTemplate,
        stack: Set<TypeDefinitionId>,
    ) {
        if (!result.add(template) || template.definition in stack) return
        val definition = definitions[template.definition] ?: return
        val arguments =
            definition.parameters
                .map { it.key }
                .zip(template.arguments)
                .toMap()
        definition.parents.forEach { parent -> visit(parent.substitute(arguments), stack + template.definition) }
    }

    roots.forEach { visit(it, setOf(id)) }
    return result.toList()
}

private fun collectTemplateFields(
    template: NamedTypeTemplate,
    definitions: Map<TypeDefinitionId, TypeDefinition>,
    affected: TypeDefinitionId,
    stack: Set<TypeDefinitionId>,
): TemplateFieldsResult {
    if (template.definition in stack) return TemplateFieldsResult(emptyList(), emptyList())
    val definition = definitions[template.definition] ?: return TemplateFieldsResult(emptyList(), emptyList())
    val arguments =
        definition.parameters
            .map { it.key }
            .zip(template.arguments)
            .toMap()
    val parentResults =
        definition.parents.map { parent ->
            collectTemplateFields(
                parent.substitute(arguments),
                definitions,
                affected,
                stack + template.definition,
            )
        }
    val inherited = parentResults.flatMap(TemplateFieldsResult::fields)
    val diagnostics = parentResults.flatMap(TemplateFieldsResult::diagnostics).toMutableList()
    val own =
        (definition.representation as? RepresentationTemplate.RecordWrapper)?.value?.fields.orEmpty().map { field ->
            field.copy(type = field.type.substitute(arguments))
        }
    val fieldOrder = (inherited.map { it.owner.name } + own.map { it.owner.name }).distinct()
    val inheritedByName = inherited.groupBy { it.owner.name }.toMutableMap()
    val merged = linkedMapOf<String, FieldDeclaration>()
    own.forEach { field ->
        val inheritedFields = inheritedByName.remove(field.owner.name).orEmpty()
        val inheritedOwners = inheritedFields.map(FieldDeclaration::owner).toSet()
        if (inheritedOwners.isNotEmpty() && !field.overrides.containsAll(inheritedOwners)) {
            diagnostics +=
                DeclarationDiagnostic.of(
                    affected = affected,
                    code = "missing_field_override",
                    field = RelativeFieldPattern(segments = listOf(FieldPatternSegment.field(field.owner.name))),
                )
        }
        merged[field.owner.name] = field
    }
    inheritedByName.forEach { (name, fields) ->
        if (fields.map(FieldDeclaration::owner).distinct().size > 1 || fields.map(FieldDeclaration::type).distinct().size > 1) {
            diagnostics +=
                DeclarationDiagnostic.of(
                    affected = affected,
                    code = "ambiguous_inherited_field",
                    field = RelativeFieldPattern(segments = listOf(FieldPatternSegment.field(name))),
                )
        } else {
            merged[name] = fields.first()
        }
    }
    return TemplateFieldsResult(fieldOrder.mapNotNull(merged::get), diagnostics.distinct())
}

internal fun DeclarationStatus.diagnostics(): List<DeclarationDiagnostic> =
    when (this) {
        DeclarationStatus.READY -> emptyList()
        is DeclarationStatus.UnavailableWrapper -> reasons
        else -> unknownVariant(this)
    }
