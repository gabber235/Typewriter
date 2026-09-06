package com.typewritermc.elements

import com.typewritermc.discovery.DeploymentFacts
import com.typewritermc.types.Color
import com.typewritermc.types.ConcreteTypePrototype
import com.typewritermc.types.DataValue
import com.typewritermc.types.DeclaredTypeId
import com.typewritermc.types.Icon
import com.typewritermc.types.Referenceable
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.TypeId
import com.typewritermc.types.TypewriterString
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlin.reflect.KClass

/**
 * Base contract for authored instances that can be referenced by other content.
 *
 * [id] identifies the instance, while [ElementTypeId] identifies its schema. Runtime behavior is supplied through
 * execution contracts or separate facets.
 */
interface Element : Referenceable {
    val id: ElementInstanceId
}

/**
 * Marks an element that can occupy an entry role, including a timeline track.
 *
 * This marker does not itself provide execution; entries that execute implement [ExecutableEntry].
 */
interface Entry : Element

/**
 * Marks an element positioned within a timeline. Use [Segment] for an interval and [Keyframe] for a single frame.
 */
interface Cue : Element

/**
 * Describes a timeline interval in frame indices.
 *
 * Implementations expose authored bounds; this interface does not validate them or define playback scheduling.
 */
interface Segment : Cue {
    val startFrame: Int
    val endFrame: Int
}

/**
 * Describes a timeline cue at one frame index. Scheduling and execution belong to the runtime using the cue.
 */
interface Keyframe : Cue {
    val frame: Int
}

/**
 * Identifies an element schema independently of any stored instance.
 *
 * Its declared identity must match the structural type advertised by [ElementDescriptor].
 */
@JvmInline
@Serializable
value class ElementTypeId(
    val value: DeclaredTypeId,
)

/**
 * Carries an element instance key across authoring, references, and runtime decoding.
 *
 * It serializes as a plain string. Construction does not validate format or establish that an element exists.
 */
@JvmInline
@Serializable(with = ElementInstanceIdSerializer::class)
@TypewriterString
value class ElementInstanceId(
    val value: String,
)

/**
 * Declares the persistent schema identity and editor metadata of an authored element.
 *
 * Code generation produces its prototype and discovery descriptor. Keep the identity stable across releases and
 * change the revision deliberately when evolving the stored schema.
 */
@Target(AnnotationTarget.CLASS)
@Retention(AnnotationRetention.BINARY)
annotation class TypewriterElement(
    val id: String,
    val revision: Int = 1,
    val name: String,
    val description: String,
    val icon: String,
    val color: String,
)

/**
 * Associates a runtime facet with an element type in selected discovery domains.
 *
 * Execution is selected by default. A facet supplies behavior separately from the serializable element model; its
 * attachment resources belong to the runtime activation.
 */
@Target(AnnotationTarget.CLASS)
@Retention(AnnotationRetention.BINARY)
annotation class TypewriterElementFacet(
    val element: KClass<out Element>,
    val realm: Boolean = false,
    val execution: Boolean = true,
)

/**
 * Evaluates whether an element is available under deployment facts, independently of source part eligibility.
 *
 * Missing facts fail equality checks. Empty [All] succeeds and empty [Any] fails. Expressions are data suitable
 * for catalog transport rather than executable extension predicates.
 */
@Serializable
sealed interface AvailabilityExpression {
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
 * eligibility is recorded separately in [ElementCatalogEntry].
 */
@Serializable
data class ElementDescriptor(
    val id: ElementTypeId,
    val type: ResolvedTypeRef,
    val name: String,
    val description: String,
    val icon: Icon,
    val color: Color,
    val availability: AvailabilityExpression,
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
interface ElementPrototype<E : Element> : ConcreteTypePrototype<E> {
    val descriptor: ElementDescriptor
}

fun ElementDescriptor.isAvailable(facts: DeploymentFacts): Boolean = availability.evaluate(facts)

/**
 * Rejects a polymorphic value whose declared type identity differs from this element.
 *
 * This checks identity only. It does not verify revision compatibility or validate the payload shape.
 */
fun ElementDescriptor.requireMatchingValue(value: DataValue.Polymorphic) {
    require(value.concreteType.id == TypeId.Declared(id.value)) {
        "Element value type ${value.concreteType.id} does not match descriptor ${id.value}."
    }
}
