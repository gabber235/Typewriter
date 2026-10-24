package com.typewritermc.discovery

import com.typewritermc.types.canonicalText
import com.typewritermc.types.namedTemplate
import com.typewritermc.types.qualified
import com.typewritermc.types.toTemplate
import com.typewritermc.types.unknownVariant
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeId
import skirout.editor.v1.type_catalog.TypeTemplate
import skirout.editor.v1.type_catalog.TypeUse

/** Namespace of the opaque stand ins for free type parameters; authored declarations cannot use it. */
const val OPAQUE_PARAMETER_NAMESPACE: String = "typewriter.parameter"

/**
 * Opaque stand ins for the free type parameters of [definitions], so a generic template checks once as a closed type
 * that holds for every argument.
 *
 * Each parameter becomes an abstract record without fields of its own whose parents are its named bounds: an
 * expression sees exactly what every argument guarantees (the bounds' fields and ancestry) and nothing a particular
 * argument might add. A bound that is not a named type has no record form and constrains nothing here, so such a
 * parameter checks as an unconstrained opaque value. [close] replaces parameters by their stand ins and [open] turns
 * a checked type back into a template, so binding types derived from expressions keep referring to the parameters.
 */
internal class OpaqueParameters(
    definitions: Collection<TypeDefinition>,
) {
    private val keys: Map<ParameterKey, TypeDefinitionId> =
        definitions
            .flatMap { definition -> definition.parameters.map { it.key } }
            .associateWith { key -> TypeDefinitionId.qualified(OPAQUE_PARAMETER_NAMESPACE, "${key.owner.canonicalText}#${key.index}") }
    private val parameters: Map<TypeDefinitionId, ParameterKey> = keys.entries.associate { (key, id) -> id to key }

    /** One abstract record per parameter, to join the declarations a presentation checker resolves against. */
    val definitions: List<TypeDefinition> =
        definitions.flatMap { definition ->
            definition.parameters.map { parameter ->
                TypeDefinition(
                    id = keys.getValue(parameter.key),
                    parameters = emptyList(),
                    representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = true),
                    parents = parameter.bounds.mapNotNull { (close(it) as? TypeTemplate.NamedWrapper)?.value },
                )
            }
        }

    /** [template] with every free parameter replaced by its opaque stand in; it has no free parameters left. */
    fun close(template: TypeTemplate): TypeTemplate =
        when (template) {
            is TypeTemplate.ParameterWrapper -> {
                val id = requireNotNull(keys[template.value]) { "Type parameter ${template.value} has no declaring definition." }
                TypeTemplate.NamedWrapper(id.namedTemplate())
            }

            is TypeTemplate.NamedWrapper -> {
                TypeTemplate.NamedWrapper(template.value.copy(arguments = template.value.arguments.map(::close)))
            }

            is TypeTemplate.NullableWrapper -> {
                TypeTemplate.createNullable(value = close(template.value.value))
            }

            is TypeTemplate.ScalarWrapper -> {
                template
            }

            else -> {
                unknownVariant(template)
            }
        }

    /** The template of [use] in which every opaque stand in is the parameter it stands for again. */
    fun open(use: TypeUse): TypeTemplate = open(use.toTemplate())

    private fun open(template: TypeTemplate): TypeTemplate =
        when (template) {
            is TypeTemplate.NamedWrapper -> {
                parameters[template.value.definition]?.let { TypeTemplate.ParameterWrapper(it) }
                    ?: TypeTemplate.NamedWrapper(template.value.copy(arguments = template.value.arguments.map(::open)))
            }

            is TypeTemplate.NullableWrapper -> {
                TypeTemplate.createNullable(value = open(template.value.value))
            }

            else -> {
                template
            }
        }

    companion object {
        /** Whether [id] belongs to the namespace reserved for opaque parameters. */
        fun isReserved(id: TypeDefinitionId): Boolean =
            (id.typeId as? TypeId.QualifiedWrapper)?.value?.namespace == OPAQUE_PARAMETER_NAMESPACE
    }
}
