package com.typewritermc.presentation

import com.typewritermc.configuration.kind
import com.typewritermc.types.PresentationRole
import com.typewritermc.types.TypeTemplate
import com.typewritermc.types.TypeUse
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.CheckedType
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.catalog.isNominalSubtype
import com.typewritermc.types.catalog.resolve

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
                    other.type.subsumes(type, actual) && !type.subsumes(other.type, actual)
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
                other.type.subsumes(type, catalog) && !type.subsumes(other.type, catalog)
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
            type.subsumes(other.type, actual) && other.type.subsumes(type, actual)
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
            type.subsumes(other.type, catalog) && other.type.subsumes(type, catalog)
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
            actual.applications().any { application -> type.matches(application, linkedMapOf(), actual) }
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

private fun CheckedType.applications(): List<TypeUse.Named> =
    buildList {
        (use as? TypeUse.Named)?.let(::add)
        addAll(schema.ancestors)
    }

private fun TypeTemplate.matches(
    actual: TypeUse,
    parameters: MutableMap<com.typewritermc.types.ParameterKey, TypeUse>,
    checked: CheckedType,
): Boolean =
    when (this) {
        is TypeTemplate.Parameter -> {
            parameters[key]?.let { it == actual } ?: run {
                parameters[key] = actual
                true
            }
        }

        is TypeTemplate.Scalar -> {
            actual == TypeUse.Scalar(kind)
        }

        is TypeTemplate.Nullable -> {
            actual is TypeUse.Nullable && value.matches(actual.value, parameters, checked)
        }

        is TypeTemplate.Named -> {
            if (actual !is TypeUse.Named) return false
            actual
                .applications(checked)
                .filter { application -> definition == application.definition && arguments.size == application.arguments.size }
                .any { application ->
                    val candidateParameters = LinkedHashMap(parameters)
                    val matches =
                        arguments.zip(application.arguments).all { (expected, supplied) ->
                            expected.matches(supplied, candidateParameters, checked)
                        }
                    if (matches) {
                        parameters.clear()
                        parameters.putAll(candidateParameters)
                    }
                    matches
                }
        }
    }

private fun TypeUse.Named.applications(checked: CheckedType): List<TypeUse.Named> =
    when (val resolution = checked.resolve(this)) {
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
    parameters: MutableMap<com.typewritermc.types.ParameterKey, TypeTemplate>,
): Boolean =
    when (this) {
        is TypeTemplate.Parameter -> {
            parameters[key]?.let { it == candidate } ?: run {
                parameters[key] = candidate
                true
            }
        }

        is TypeTemplate.Scalar -> {
            candidate == this
        }

        is TypeTemplate.Nullable -> {
            candidate is TypeTemplate.Nullable && value.subsumes(candidate.value, checked, parameters)
        }

        is TypeTemplate.Named -> {
            if (candidate !is TypeTemplate.Named) {
                false
            } else if (definition == candidate.definition) {
                arguments.size == candidate.arguments.size &&
                    arguments.zip(candidate.arguments).all { (pattern, value) ->
                        pattern.subsumes(value, checked, parameters)
                    }
            } else {
                arguments.isEmpty() &&
                    candidate.arguments.isEmpty() &&
                    checked.isNominalSubtype(candidate.definition, definition)
            }
        }
    }

private fun TypeTemplate.subsumes(
    candidate: TypeTemplate,
    catalog: CheckedCatalog,
): Boolean = subsumes(candidate, catalog, linkedMapOf())

private fun TypeTemplate.subsumes(
    candidate: TypeTemplate,
    catalog: CheckedCatalog,
    parameters: MutableMap<com.typewritermc.types.ParameterKey, TypeTemplate>,
): Boolean =
    when (this) {
        is TypeTemplate.Parameter -> {
            parameters[key]?.let { it == candidate } ?: run {
                parameters[key] = candidate
                true
            }
        }

        is TypeTemplate.Scalar -> {
            candidate == this
        }

        is TypeTemplate.Nullable -> {
            candidate is TypeTemplate.Nullable && value.subsumes(candidate.value, catalog, parameters)
        }

        is TypeTemplate.Named -> {
            if (candidate !is TypeTemplate.Named) {
                false
            } else if (definition == candidate.definition) {
                arguments.size == candidate.arguments.size &&
                    arguments.zip(candidate.arguments).all { (pattern, value) ->
                        pattern.subsumes(value, catalog, parameters)
                    }
            } else {
                arguments.isEmpty() &&
                    candidate.arguments.isEmpty() &&
                    catalog.isNominalSubtype(candidate.definition, definition)
            }
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
