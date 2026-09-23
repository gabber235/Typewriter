package com.typewritermc.elements

import com.typewritermc.authoring.Placement
import com.typewritermc.authoring.TimelineCuePlacement
import com.typewritermc.authoring.TimelineKeyframePlacement
import com.typewritermc.authoring.TimelineSegmentPlacement
import com.typewritermc.discovery.DeploymentFacts
import com.typewritermc.types.Color
import com.typewritermc.types.ConcreteTypePrototype
import com.typewritermc.types.DataValue
import com.typewritermc.types.DeclaredTypeId
import com.typewritermc.types.Icon
import com.typewritermc.types.Referenceable
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.TypeId
import com.typewritermc.types.TypewriterType
import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.MetaSerializable
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlin.reflect.KClass

/**
 * Base contract for authored instances that can be referenced by other content.
 *
 * Resource identity lives outside the typed content. [ContentTypeId] identifies the schema. Runtime behavior is
 * supplied through separate facets.
 */
interface Element : Referenceable {
    val name: String
    val placement: Placement
}

/**
 * Marks an element that can occupy an entry role, including a timeline track.
 */
interface Entry : Element

/**
 * Marks an element positioned within a timeline. Use [Segment] for an interval and [Keyframe] for a single frame.
 */
interface Cue : Referenceable {
    val placement: TimelineCuePlacement
}

/**
 * Describes a timeline interval in frame indices.
 *
 * Implementations expose authored bounds; this interface does not validate them or define playback scheduling.
 */
interface Segment : Cue {
    override val placement: TimelineSegmentPlacement
}

/**
 * Describes a timeline cue at one frame index. Scheduling and execution belong to the runtime using the cue.
 */
interface Keyframe : Cue {
    override val placement: TimelineKeyframePlacement
}

/**
 * Identifies an element schema independently of any stored instance.
 *
 * Its declared identity must match the structural type advertised by [ContentDescriptor].
 */
@JvmInline
@Serializable
@TypewriterType(id = "ef2cd4c6ab4f4c5a9f0850f3d7a0f58f")
value class ContentTypeId(
    val value: DeclaredTypeId,
)

/**
 * Declares the persistent schema identity and editor metadata of an authored element.
 *
 * The serialization compiler plugin generates its default serializer. Typewriter code generation produces its
 * prototype and discovery descriptor. Keep the identity stable across releases and change the revision deliberately
 * when evolving the stored schema.
 */
@OptIn(ExperimentalSerializationApi::class)
@MetaSerializable
@Target(AnnotationTarget.CLASS)
@Retention(AnnotationRetention.BINARY)
annotation class TypewriterContent(
    val id: String,
    val revision: Int = 1,
    val name: String,
    val description: String,
    val icon: String,
    val color: String,
)

/**
 * Overrides automatic search projection for one serialized property subtree.
 *
 * The generated definition addresses the property by its serialized name. Explicit text modes include logical
 * string leaves, while reference leaves remain structural identities and are never projected as text.
 */
@Target(AnnotationTarget.PROPERTY)
@Retention(AnnotationRetention.BINARY)
annotation class ContentSearch(
    val mode: ContentSearchMode,
)

/** Controls how text leaves in an authored property subtree enter the search document. */
@Serializable
enum class ContentSearchMode {
    SUMMARY,
    BODY,
    KEYWORD,
    NONE,
}

/** Identifies the automatic projection algorithm understood by a search consumer. */
@Serializable
enum class ContentSearchPolicy {
    ORDINARY_TEXT,
}

/**
 * Overrides the automatic policy for a property declared by [ownerType].
 *
 * [field] is the serialized property name. The mode applies recursively unless a nested property supplies a more
 * specific override.
 */
@Serializable
data class ContentSearchPropertyOverride(
    val ownerType: ResolvedTypeRef,
    val field: String,
    val mode: ContentSearchMode,
) {
    init {
        require(ownerType.arguments.isEmpty()) { "Search override owner types must not contain arguments." }
        require(field.isNotBlank()) { "Search override field names must not be blank." }
    }
}

/**
 * Generated instructions for projecting dynamic element values into a search document.
 *
 * [ContentSearchPolicy.ORDINARY_TEXT] traverses records, collections, named values, and polymorphic concrete types.
 * Plain string leaves default to [ContentSearchMode.BODY]. Logical strings require an explicit text mode. References
 * remain excluded. [revisionFingerprintInputs] contains every reachable nominal definition so a catalog revision
 * change invalidates projections that depend on its structure or subtype set.
 */
@Serializable
data class ContentSearchDefinition(
    val policy: ContentSearchPolicy,
    val propertyOverrides: List<ContentSearchPropertyOverride>,
    val revisionFingerprintInputs: List<ResolvedTypeRef>,
) {
    init {
        require(revisionFingerprintInputs.all { it.arguments.isEmpty() }) {
            "Search revision fingerprint inputs must not contain arguments."
        }
        require(revisionFingerprintInputs.distinct().size == revisionFingerprintInputs.size) {
            "Search revision fingerprint inputs must be unique."
        }
        require(propertyOverrides.distinctBy { it.ownerType to it.field }.size == propertyOverrides.size) {
            "Search property overrides must be unique per owner and field."
        }
    }
}

/**
 * Associates an execution runtime facet with an element type.
 *
 * A facet supplies behavior separately from the serializable element model. Code generation exposes it only through
 * execution discovery, and its attachment resources belong to the runtime activation.
 */
@Target(AnnotationTarget.CLASS)
@Retention(AnnotationRetention.BINARY)
annotation class TypewriterElementFacet(
    val element: KClass<out Element>,
)

/**
 * Evaluates whether an element is available under deployment facts, independently of source part eligibility.
 *
 * Missing facts fail equality checks. Empty [All] succeeds and empty [Any] fails. Expressions are data suitable
 * for catalog transport rather than executable extension predicates.
 */
@Serializable
sealed interface AvailabilityExpression {
    /** Evaluates this catalog expression against the facts reported by the current deployment. */
    fun evaluate(facts: DeploymentFacts): Boolean

    @Serializable
    @SerialName("always")
    data object Always : AvailabilityExpression {
        override fun evaluate(facts: DeploymentFacts): Boolean = true
    }

    @Serializable
    @SerialName("fact")
    data class Fact(
        val key: String,
        val expected: String,
    ) : AvailabilityExpression {
        init {
            require(key.isNotBlank()) { "Availability fact keys must not be blank." }
        }

        override fun evaluate(facts: DeploymentFacts): Boolean = facts.values[key] == expected
    }

    @Serializable
    @SerialName("all")
    data class All(
        val expressions: List<AvailabilityExpression>,
    ) : AvailabilityExpression {
        override fun evaluate(facts: DeploymentFacts): Boolean = expressions.all { it.evaluate(facts) }
    }

    @Serializable
    @SerialName("any")
    data class Any(
        val expressions: List<AvailabilityExpression>,
    ) : AvailabilityExpression {
        override fun evaluate(facts: DeploymentFacts): Boolean = expressions.any { it.evaluate(facts) }
    }

    @Serializable
    @SerialName("not")
    data class Not(
        val expression: AvailabilityExpression,
    ) : AvailabilityExpression {
        override fun evaluate(facts: DeploymentFacts): Boolean = !expression.evaluate(facts)
    }
}

/**
 * Publishes editor metadata and deployment availability for one element schema.
 *
 * The structural reference must use the same declared identity as [id]. Availability describes facts; source part
 * eligibility is recorded separately in [ContentCatalogEntry].
 */
@Serializable
enum class ContentRole {
    ELEMENT,
    CUE,
}

@Serializable
data class ContentDescriptor(
    val id: ContentTypeId,
    val type: ResolvedTypeRef,
    val role: ContentRole,
    val name: String,
    val description: String,
    val icon: Icon,
    val color: Color,
    val availability: AvailabilityExpression,
    val searchDefinition: ContentSearchDefinition? = null,
) {
    init {
        require(type.id == TypeId.Declared(id.value)) { "Element and structural type identities must match." }
        require(name.isNotBlank()) { "Element names must not be blank." }
    }
}

/**
 * Combines the codec for a concrete element with its editor descriptor.
 *
 * Generated implementations let authoring and runtime consumers share the same structural type identity.
 */
interface ContentPrototype<E : Referenceable> : ConcreteTypePrototype<E> {
    /** Metadata used to expose this prototype in the deployment element catalog. */
    val descriptor: ContentDescriptor
}

/** Evaluates the descriptor's deployment availability expression against the supplied facts. */
fun ContentDescriptor.isAvailable(facts: DeploymentFacts): Boolean = availability.evaluate(facts)

/**
 * Rejects a polymorphic value whose declared type identity differs from this element.
 *
 * This checks identity only. It does not verify revision compatibility or validate the payload shape.
 */
fun ContentDescriptor.requireMatchingValue(value: DataValue.Polymorphic) {
    require(value.concreteType.id == TypeId.Declared(id.value)) {
        "Element value type ${value.concreteType.id} does not match descriptor ${id.value}."
    }
}
