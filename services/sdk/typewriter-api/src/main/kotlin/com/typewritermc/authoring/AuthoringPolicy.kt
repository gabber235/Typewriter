package com.typewritermc.authoring

import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeExpression
import kotlinx.serialization.Serializable

/** Locates matched text inside the indexed document used for ranking and highlighting. */
@Serializable
data class AuthoringSearchMatch(
    val text: String,
    val start: Int,
    val end: Int,
) {
    init {
        require(start in 0..end && end <= text.length) { "Search match bounds must fit the matched text." }
    }
}

/** Generic search context accompanying any projected resource subject. */
@com.typewritermc.types.TypewriterType(id = "6e959f2dc65342dc9a2409cf3497e09f")
data class AuthoringSearchContext(
    val ownerPath: List<ResourceId>,
    val match: AuthoringSearchMatch?,
)

/** Stable open identity for one kind of authored resource. */
@JvmInline
@Serializable
value class ResourceDefinitionId(
    val value: String,
) {
    init {
        require(value.isNotBlank()) { "Resource definition ids must not be blank." }
    }
}

/** Structural identity and accepted root type for one authored resource. */
data class AuthoringResourceDefinition(
    val id: ResourceDefinitionId,
    val acceptedRoot: TypeExpression,
    val navigationHandler: String = "generic",
) {
    init {
        require(navigationHandler.isNotBlank()) { "Resource navigation handlers must not be blank." }
    }
}

/** Describes one selector key understood by the indexed authoring search endpoint. */
data class AuthoringSearchSelector(
    val id: SearchSelectorId,
    val key: String,
    val values: AuthoringSearchSelectorValues = AuthoringSearchSelectorValues.FreeText,
    val caseSensitive: Boolean = false,
    val multiplicity: AuthoringSearchSelectorMultiplicity = AuthoringSearchSelectorMultiplicity.MULTIPLE,
    val colorValue: Long? = null,
) {
    init {
        require(key.isNotBlank()) { "Search selector keys must not be blank." }
    }
}

sealed interface AuthoringSearchSelectorValues {
    data object FreeText : AuthoringSearchSelectorValues

    data class Enumeration(
        val values: List<String>,
    ) : AuthoringSearchSelectorValues {
        init {
            require(values.isNotEmpty()) { "Enumerated search selectors must expose at least one value." }
            require(values.all(String::isNotBlank)) { "Enumerated search selector values must not be blank." }
            require(values.distinct().size == values.size) { "Enumerated search selector values must be unique." }
        }
    }
}

enum class AuthoringSearchSelectorMultiplicity {
    SINGLE,
    MULTIPLE,
}

/** Describes one user visible facet backed by an indexed selector. */
data class AuthoringSearchFacet(
    val id: String,
    val label: String,
    val selectorId: SearchSelectorId,
) {
    init {
        require(id.isNotBlank()) { "Search facet ids must not be blank." }
        require(label.isNotBlank()) { "Search facet labels must not be blank." }
    }
}

/** A provider contributes independent authoring policies to one Realm catalog. */
fun interface AuthoringPolicyProvider {
    fun contribute(builder: AuthoringPolicyCatalog.Builder)
}

/** One immutable, validated set of Realm authoring policies. */
class AuthoringPolicyCatalog private constructor(
    val definitions: Map<ResourceDefinitionId, AuthoringResourceDefinition>,
    val validations: Map<AuthoringValidationRuleId, AuthoringValidationRule>,
    val search: Map<ResourceDefinitionId, AuthoringSearchProjection>,
    val searchSelectors: List<AuthoringSearchSelector>,
    val searchFacets: List<AuthoringSearchFacet>,
    val presentations: Map<ResourceDefinitionId, AuthoringPresentationProjection>,
    val compilation: Map<AuthoringCompilationProjectionId, AuthoringCompilationProjection>,
) {
    /** Fails when a policy refers to a definition that is not part of this catalog. */
    fun validateOrThrow() {
        val known = definitions.keys
        val unknownSearch = search.keys - known
        val unknownPresentations = presentations.keys - known
        val unknownGraphDefinitions =
            (
                validations.values.map(AuthoringValidationRule::graphRequirement) +
                    search.values.map(AuthoringSearchProjection::graphRequirement) +
                    presentations.values.map(AuthoringPresentationProjection::graphRequirement) +
                    compilation.values.map(AuthoringCompilationProjection::graphRequirement)
            ).flatMap { it.definitions - known }.toSet()
        require(unknownSearch.isEmpty()) {
            "Search policies reference unknown definitions: ${unknownSearch.sortedBy(ResourceDefinitionId::value)}."
        }
        require(unknownPresentations.isEmpty()) {
            "Presentation policies reference unknown definitions: " +
                unknownPresentations.sortedBy(ResourceDefinitionId::value) + "."
        }
        require(unknownGraphDefinitions.isEmpty()) {
            "Graph requirements reference unknown definitions: " +
                unknownGraphDefinitions.sortedBy(ResourceDefinitionId::value) + "."
        }
        val selectors = searchSelectors.mapTo(mutableSetOf(), AuthoringSearchSelector::id)
        require(searchFacets.all { it.selectorId in selectors }) {
            "Search facets must reference registered selectors."
        }
    }

    class Builder {
        private val definitions = linkedMapOf<ResourceDefinitionId, AuthoringResourceDefinition>()
        private val validations = linkedMapOf<AuthoringValidationRuleId, AuthoringValidationRule>()
        private val search = linkedMapOf<ResourceDefinitionId, AuthoringSearchProjection>()
        private val searchSelectors = linkedMapOf<SearchSelectorId, AuthoringSearchSelector>()
        private val searchFacets = linkedMapOf<String, AuthoringSearchFacet>()
        private val presentations = linkedMapOf<ResourceDefinitionId, AuthoringPresentationProjection>()
        private val compilation = linkedMapOf<AuthoringCompilationProjectionId, AuthoringCompilationProjection>()

        fun definition(value: AuthoringResourceDefinition) {
            require(definitions.put(value.id, value) == null) {
                "Resource definition is contributed more than once: ${value.id.value}."
            }
        }

        fun validation(value: AuthoringValidationRule) {
            require(validations.put(value.id, value) == null) {
                "Validation rule is contributed more than once: ${value.id.value}."
            }
        }

        fun search(value: AuthoringSearchProjection) {
            require(search.put(value.resourceDefinition, value) == null) {
                "Search projection is contributed more than once: ${value.resourceDefinition.value}."
            }
        }

        fun searchSelector(value: AuthoringSearchSelector) {
            require(searchSelectors.put(value.id, value) == null) {
                "Search selector is contributed more than once: ${value.id}."
            }
        }

        fun searchFacet(value: AuthoringSearchFacet) {
            require(searchFacets.put(value.id, value) == null) {
                "Search facet is contributed more than once: ${value.id}."
            }
        }

        fun presentation(value: AuthoringPresentationProjection) {
            require(presentations.put(value.resourceDefinition, value) == null) {
                "Presentation projection is contributed more than once: ${value.resourceDefinition.value}."
            }
        }

        fun compilation(value: AuthoringCompilationProjection) {
            require(compilation.put(value.id, value) == null) {
                "Compilation projection is contributed more than once: ${value.id.value}."
            }
        }

        fun build(): AuthoringPolicyCatalog =
            AuthoringPolicyCatalog(
                definitions = definitions.toSortedMap(compareBy(ResourceDefinitionId::value)),
                validations = validations.toSortedMap(compareBy(AuthoringValidationRuleId::value)),
                search = search.toSortedMap(compareBy(ResourceDefinitionId::value)),
                searchSelectors = searchSelectors.values.sortedBy { it.id.value },
                searchFacets = searchFacets.values.sortedBy(AuthoringSearchFacet::id),
                presentations = presentations.toSortedMap(compareBy(ResourceDefinitionId::value)),
                compilation = compilation.toSortedMap(compareBy(AuthoringCompilationProjectionId::value)),
            ).also(AuthoringPolicyCatalog::validateOrThrow)
    }

    companion object {
        fun assemble(providers: Collection<AuthoringPolicyProvider>): AuthoringPolicyCatalog =
            Builder()
                .also { builder ->
                    providers.forEach { it.contribute(builder) }
                }.build()
    }
}
