package com.typewritermc.presentation

import com.typewritermc.configuration.kind
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.CheckedType
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.catalog.isNominalSubtype
import com.typewritermc.types.catalog.resolve
import com.typewritermc.types.named
import com.typewritermc.types.storedUse
import com.typewritermc.types.template
import com.typewritermc.types.unknownVariant
import com.typewritermc.types.use
import com.typewritermc.types.zipParts
import skirout.editor.v1.catalog.PresentationDescriptor
import skirout.editor.v1.catalog.PresentationRole
import skirout.editor.v1.catalog.PresentationTarget
import skirout.editor.v1.catalog.RoleFallback
import skirout.editor.v1.type_catalog.NamedTypeUse
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeTemplate
import skirout.editor.v1.type_catalog.TypeUse

/**
 * Selects role presentations using nominal target specificity and explicitly configured role fallback.
 * Priority breaks ties only among equivalent maximal targets. A conflict stops fallback so another role cannot hide
 * an ambiguous declaration; missing roles traverse configured parents in breadth first order with cycle protection.
 */
class DefaultPresentationRegistry(
    override val catalog: CheckedCatalog,
    descriptors: List<PresentationDescriptor>,
    fallbacks: List<RoleFallback> = emptyList(),
) : PresentationRegistry {
    private val descriptors = descriptors.toList()
    private val fallbacks = fallbacks.associate { it.role to it.parents.toList() }

    override fun compatibleCandidates(
        role: PresentationRole,
        actual: CheckedType,
    ): List<PresentationDescriptor> = descriptors.filter { descriptor -> role in descriptor.roles && descriptor.target.matches(actual) }

    override fun isMoreSpecific(
        left: PresentationTarget,
        right: PresentationTarget,
        actual: CheckedType,
    ): Boolean = left.isMoreSpecificThan(right, actual)

    override fun isEquivalent(
        left: PresentationTarget,
        right: PresentationTarget,
        actual: CheckedType,
    ): Boolean = left.isEquivalentTo(right, actual)

    override fun fallbacks(role: PresentationRole): List<PresentationRole> = fallbacks[role].orEmpty()

    override fun select(
        role: PresentationRole,
        actual: CheckedType,
    ): PresentationSelection = selectByRoleFallback(role, actual)
}

internal fun PresentationTarget.isMoreSpecificThan(
    other: PresentationTarget,
    actual: CheckedType,
): Boolean =
    when {
        this is PresentationTarget.NamedWrapper && other is PresentationTarget.RepresentationWrapper -> {
            true
        }

        this is PresentationTarget.RepresentationWrapper || other is PresentationTarget.RepresentationWrapper -> {
            false
        }

        this is PresentationTarget.NamedWrapper && other is PresentationTarget.NamedWrapper -> {
            val definition = value.definition
            val otherDefinition = other.value.definition
            when {
                definition != otherDefinition -> {
                    actual.isNominalSubtype(definition, otherDefinition) &&
                        !actual.isNominalSubtype(otherDefinition, definition)
                }

                else -> {
                    other.value.template.subsumes(value.template, actual) && !value.template.subsumes(other.value.template, actual)
                }
            }
        }

        else -> {
            false
        }
    }

internal fun PresentationTarget.isMoreSpecificThan(
    other: PresentationTarget,
    catalog: CheckedCatalog,
): Boolean =
    when {
        this is PresentationTarget.NamedWrapper && other is PresentationTarget.RepresentationWrapper -> {
            true
        }

        this is PresentationTarget.RepresentationWrapper || other is PresentationTarget.RepresentationWrapper -> {
            false
        }

        this is PresentationTarget.NamedWrapper && other is PresentationTarget.NamedWrapper -> {
            if (value.definition != other.value.definition) {
                catalog.isNominalSubtype(value.definition, other.value.definition) &&
                    !catalog.isNominalSubtype(other.value.definition, value.definition)
            } else {
                other.value.template.subsumes(value.template, catalog) && !value.template.subsumes(other.value.template, catalog)
            }
        }

        else -> {
            false
        }
    }

internal fun PresentationTarget.isEquivalentTo(
    other: PresentationTarget,
    actual: CheckedType,
): Boolean =
    when {
        this is PresentationTarget.RepresentationWrapper && other is PresentationTarget.RepresentationWrapper -> {
            value == other.value
        }

        this is PresentationTarget.NamedWrapper && other is PresentationTarget.NamedWrapper -> {
            value.template.subsumes(other.value.template, actual) && other.value.template.subsumes(value.template, actual)
        }

        else -> {
            false
        }
    }

internal fun PresentationTarget.isEquivalentTo(
    other: PresentationTarget,
    catalog: CheckedCatalog,
): Boolean =
    when {
        this is PresentationTarget.RepresentationWrapper && other is PresentationTarget.RepresentationWrapper -> {
            value == other.value
        }

        this is PresentationTarget.NamedWrapper && other is PresentationTarget.NamedWrapper -> {
            value.template.subsumes(other.value.template, catalog) && other.value.template.subsumes(value.template, catalog)
        }

        else -> {
            false
        }
    }

internal fun PresentationTarget.matches(actual: CheckedType): Boolean =
    when (this) {
        is PresentationTarget.RepresentationWrapper -> {
            actual.schema.representation.kind() == value
        }

        is PresentationTarget.NamedWrapper -> {
            actual.applications().any { application -> value.template.matches(application.use, linkedMapOf(), actual) }
        }

        else -> {
            unknownVariant(this)
        }
    }

internal fun selectMostSpecificDescriptors(
    candidates: List<PresentationDescriptor>,
    actual: CheckedType,
): PresentationDescriptor? {
    val maxima =
        candidates.filter { candidate ->
            candidates.none { other ->
                other.id != candidate.id && other.target.isMoreSpecificThan(candidate.target, actual)
            }
        }
    require(maxima.size <= 1) {
        "A presentation reference is ambiguous for this binding: ${maxima.map { it.id }.joinToString()}."
    }
    return maxima.singleOrNull()
}

internal fun selectMostSpecificDescriptors(
    candidates: List<PresentationDescriptor>,
    catalog: CheckedCatalog,
): PresentationDescriptor? {
    val maxima =
        candidates.filter { candidate ->
            candidates.none { other ->
                other.id != candidate.id && other.target.isMoreSpecificThan(candidate.target, catalog)
            }
        }
    require(maxima.size <= 1) {
        "A presentation reference is ambiguous for this binding: ${maxima.map { it.id }.joinToString()}."
    }
    return maxima.singleOrNull()
}

private fun CheckedType.applications(): List<NamedTypeUse> =
    buildList {
        (use.storedUse as? TypeUse.NamedWrapper)?.value?.let(::add)
        addAll(schema.ancestors)
    }

private fun TypeTemplate.matches(
    actual: TypeUse,
    parameters: MutableMap<ParameterKey, TypeUse>,
    checked: CheckedType,
): Boolean =
    when (this) {
        is TypeTemplate.ParameterWrapper -> {
            parameters[value]?.let { it == actual } ?: run {
                parameters[value] = actual
                true
            }
        }

        is TypeTemplate.NamedWrapper -> {
            if (actual !is TypeUse.NamedWrapper) return false
            actual.value
                .applications(checked)
                .filter { application -> value.definition == application.definition && value.arguments.size == application.arguments.size }
                .any { application ->
                    val candidateParameters = LinkedHashMap(parameters)
                    val matches =
                        value.arguments.zip(application.arguments).all { (expected, supplied) ->
                            expected.matches(supplied, candidateParameters, checked)
                        }
                    if (matches) {
                        parameters.clear()
                        parameters.putAll(candidateParameters)
                    }
                    matches
                }
        }

        else -> {
            zipParts(actual)?.all { (expected, supplied) -> expected.matches(supplied, parameters, checked) } == true
        }
    }

private fun NamedTypeUse.applications(checked: CheckedType): List<NamedTypeUse> =
    when (val resolution = checked.resolve(this.use)) {
        is Resolution.Ready -> resolution.value.applications()
        is Resolution.Invalid -> emptyList()
    }

private fun TypeTemplate.subsumes(
    candidate: TypeTemplate,
    checked: CheckedType,
): Boolean = subsumes(candidate, checked::isNominalSubtype, linkedMapOf())

private fun TypeTemplate.subsumes(
    candidate: TypeTemplate,
    catalog: CheckedCatalog,
): Boolean = subsumes(candidate, catalog::isNominalSubtype, linkedMapOf())

/**
 * Whether every type [candidate] stands for is one this pattern stands for: a parameter binds once, a closed named
 * pattern takes a nominal subtype, and every other node matches a candidate of the same shape part by part.
 */
private fun TypeTemplate.subsumes(
    candidate: TypeTemplate,
    isNominalSubtype: (TypeDefinitionId, TypeDefinitionId) -> Boolean,
    parameters: MutableMap<ParameterKey, TypeTemplate>,
): Boolean {
    if (this is TypeTemplate.ParameterWrapper) {
        return parameters[value]?.let { it == candidate } ?: run {
            parameters[value] = candidate
            true
        }
    }
    val pattern = named
    val other = candidate.named
    if (pattern != null && other != null && pattern.definition != other.definition) {
        return pattern.arguments.isEmpty() && other.arguments.isEmpty() && isNominalSubtype(other.definition, pattern.definition)
    }
    return zipParts(candidate)?.all { (part, candidatePart) -> part.subsumes(candidatePart, isNominalSubtype, parameters) } == true
}

fun PresentationRegistry.selectByRoleFallback(
    requested: PresentationRole,
    actual: CheckedType,
): PresentationSelection {
    val pending = ArrayDeque<PresentationRole>()
    val visited = mutableSetOf<PresentationRole>()
    pending.add(requested)
    while (pending.isNotEmpty()) {
        val role = pending.removeFirst()
        if (!visited.add(role)) continue
        when (val result = selectWithinRole(role, actual)) {
            is PresentationSelection.Missing -> pending.addAll(fallbacks(role))
            else -> return result
        }
    }
    return PresentationSelection.Missing(requested)
}
