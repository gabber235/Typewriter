package com.typewritermc.authoring

import com.typewritermc.types.DataPath
import com.typewritermc.types.RelationId
import com.typewritermc.types.ResolvedTypeRef
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

/** Stable identity for one editor creation context. */
@JvmInline
@Serializable
value class AuthoringCreationSlotId(
    val value: String,
) {
    init {
        require(value.isNotBlank()) { "Creation slot ids must not be blank." }
    }
}

enum class AuthoringCreationHostCardinality {
    EXACTLY_ONE,
    ONE_OR_MORE,
}

enum class AuthoringCreationRelationDirection {
    OUTGOING,
    INCOMING,
    BOTH,
}

data class AuthoringCreationHostFilter(
    val definitions: Set<ResourceDefinitionId> = emptySet(),
    val assignableTo: TypeExpression? = null,
)

sealed interface AuthoringCreationContext {
    data object Standalone : AuthoringCreationContext

    data class DeclaredRelation(
        val hosts: AuthoringCreationHostFilter,
        val cardinality: AuthoringCreationHostCardinality,
        val relation: RelationId,
        val direction: AuthoringCreationRelationDirection,
    ) : AuthoringCreationContext

    data class ReferencePath(
        val hosts: AuthoringCreationHostFilter,
        val cardinality: AuthoringCreationHostCardinality,
        val path: DataPath,
    ) : AuthoringCreationContext
}

/** Describes one generic resource creation entry point. */
data class AuthoringCreationSlotDefinition(
    val id: AuthoringCreationSlotId,
    val label: String,
    val creates: ResourceDefinitionId,
    val context: AuthoringCreationContext,
    val concreteRoots: List<ResolvedTypeRef>,
) {
    init {
        require(label.isNotBlank()) { "Creation slot labels must not be blank." }
        require(concreteRoots.isNotEmpty()) { "Creation slots must expose at least one concrete root." }
        require(concreteRoots.distinct().size == concreteRoots.size) {
            "Creation slot concrete roots must be unique."
        }
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
    val creationSlots: Map<AuthoringCreationSlotId, AuthoringCreationSlotDefinition>,
    val compilation: Map<AuthoringCompilationProjectionId, AuthoringCompilationProjection>,
) {
    /** Fails when a policy refers to a definition that is not part of this catalog. */
    fun validateOrThrow() {
        val known = definitions.keys
        val unknownSearch = search.keys - known
        val unknownPresentations = presentations.keys - known
        val unknownCreation = creationSlots.values.filterNot { it.creates in known }
        val unknownCreationHosts =
            creationSlots.values
                .flatMap { slot ->
                    when (val context = slot.context) {
                        AuthoringCreationContext.Standalone -> emptySet()
                        is AuthoringCreationContext.DeclaredRelation -> context.hosts.definitions - known
                        is AuthoringCreationContext.ReferencePath -> context.hosts.definitions - known
                    }
                }.toSet()
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
        require(unknownCreation.isEmpty()) {
            "Creation slots reference unknown definitions: ${unknownCreation.map { it.id.value }}."
        }
        require(unknownCreationHosts.isEmpty()) {
            "Creation slot host filters reference unknown definitions: " +
                unknownCreationHosts.sortedBy(ResourceDefinitionId::value) + "."
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
        private val creationSlots = linkedMapOf<AuthoringCreationSlotId, AuthoringCreationSlotDefinition>()
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

        fun creationSlot(value: AuthoringCreationSlotDefinition) {
            require(creationSlots.put(value.id, value) == null) {
                "Creation slot is contributed more than once: ${value.id.value}."
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
                creationSlots = creationSlots.toSortedMap(compareBy(AuthoringCreationSlotId::value)),
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
