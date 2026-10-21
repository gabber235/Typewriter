package com.typewritermc.presentation

import com.typewritermc.configuration.kind
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.CheckedType
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.catalog.isNominalSubtype
import com.typewritermc.types.catalog.resolve
import com.typewritermc.types.template
import com.typewritermc.types.unknownVariant
import com.typewritermc.types.use
import skirout.editor.v1.catalog.PresentationRole
import skirout.editor.v1.type_catalog.NamedTypeUse
import skirout.editor.v1.type_catalog.ParameterKey
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
        this is PresentationTarget.Named && other is PresentationTarget.Representation -> {
            true
        }

        this is PresentationTarget.Representation || other is PresentationTarget.Representation -> {
            false
        }

        this is PresentationTarget.Named && other is PresentationTarget.Named -> {
            val definition = type.definition
            val otherDefinition = other.type.definition
            when {
                definition != otherDefinition -> {
                    actual.isNominalSubtype(definition, otherDefinition) &&
                        !actual.isNominalSubtype(otherDefinition, definition)
                }

                else -> {
                    other.type.template.subsumes(type.template, actual) && !type.template.subsumes(other.type.template, actual)
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
        this is PresentationTarget.Named && other is PresentationTarget.Representation -> {
            true
        }

        this is PresentationTarget.Representation || other is PresentationTarget.Representation -> {
            false
        }

        this is PresentationTarget.Named && other is PresentationTarget.Named -> {
            if (type.definition != other.type.definition) {
                catalog.isNominalSubtype(type.definition, other.type.definition) &&
                    !catalog.isNominalSubtype(other.type.definition, type.definition)
            } else {
                other.type.template.subsumes(type.template, catalog) && !type.template.subsumes(other.type.template, catalog)
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
        this is PresentationTarget.Representation && other is PresentationTarget.Representation -> {
            kind == other.kind
        }

        this is PresentationTarget.Named && other is PresentationTarget.Named -> {
            type.template.subsumes(other.type.template, actual) && other.type.template.subsumes(type.template, actual)
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
        this is PresentationTarget.Representation && other is PresentationTarget.Representation -> {
            kind == other.kind
        }

        this is PresentationTarget.Named && other is PresentationTarget.Named -> {
            type.template.subsumes(other.type.template, catalog) && other.type.template.subsumes(type.template, catalog)
        }

        else -> {
            false
        }
    }

internal fun PresentationTarget.matches(actual: CheckedType): Boolean =
    when (this) {
        is PresentationTarget.Representation -> {
            actual.schema.representation.kind() == kind
        }

        is PresentationTarget.Named -> {
            actual.applications().any { application -> type.template.matches(application.use, linkedMapOf(), actual) }
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
        (use as? TypeUse.NamedWrapper)?.value?.let(::add)
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

        is TypeTemplate.ScalarWrapper -> {
            actual == value.use
        }

        is TypeTemplate.NullableWrapper -> {
            actual is TypeUse.NullableWrapper && value.value.matches(actual.value.value, parameters, checked)
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
            unknownVariant(this)
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
): Boolean = subsumes(candidate, checked, linkedMapOf())

private fun TypeTemplate.subsumes(
    candidate: TypeTemplate,
    checked: CheckedType,
    parameters: MutableMap<ParameterKey, TypeTemplate>,
): Boolean =
    when (this) {
        is TypeTemplate.ParameterWrapper -> {
            parameters[value]?.let { it == candidate } ?: run {
                parameters[value] = candidate
                true
            }
        }

        is TypeTemplate.ScalarWrapper -> {
            candidate == this
        }

        is TypeTemplate.NullableWrapper -> {
            candidate is TypeTemplate.NullableWrapper && value.value.subsumes(candidate.value.value, checked, parameters)
        }

        is TypeTemplate.NamedWrapper -> {
            if (candidate !is TypeTemplate.NamedWrapper) {
                false
            } else if (value.definition == candidate.value.definition) {
                value.arguments.size == candidate.value.arguments.size &&
                    value.arguments.zip(candidate.value.arguments).all { (pattern, value) ->
                        pattern.subsumes(value, checked, parameters)
                    }
            } else {
                value.arguments.isEmpty() &&
                    candidate.value.arguments.isEmpty() &&
                    checked.isNominalSubtype(candidate.value.definition, value.definition)
            }
        }

        else -> {
            unknownVariant(this)
        }
    }

private fun TypeTemplate.subsumes(
    candidate: TypeTemplate,
    catalog: CheckedCatalog,
): Boolean = subsumes(candidate, catalog, linkedMapOf())

private fun TypeTemplate.subsumes(
    candidate: TypeTemplate,
    catalog: CheckedCatalog,
    parameters: MutableMap<ParameterKey, TypeTemplate>,
): Boolean =
    when (this) {
        is TypeTemplate.ParameterWrapper -> {
            parameters[value]?.let { it == candidate } ?: run {
                parameters[value] = candidate
                true
            }
        }

        is TypeTemplate.ScalarWrapper -> {
            candidate == this
        }

        is TypeTemplate.NullableWrapper -> {
            candidate is TypeTemplate.NullableWrapper && value.value.subsumes(candidate.value.value, catalog, parameters)
        }

        is TypeTemplate.NamedWrapper -> {
            if (candidate !is TypeTemplate.NamedWrapper) {
                false
            } else if (value.definition == candidate.value.definition) {
                value.arguments.size == candidate.value.arguments.size &&
                    value.arguments.zip(candidate.value.arguments).all { (pattern, value) ->
                        pattern.subsumes(value, catalog, parameters)
                    }
            } else {
                value.arguments.isEmpty() &&
                    candidate.value.arguments.isEmpty() &&
                    catalog.isNominalSubtype(candidate.value.definition, value.definition)
            }
        }

        else -> {
            unknownVariant(this)
        }
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
