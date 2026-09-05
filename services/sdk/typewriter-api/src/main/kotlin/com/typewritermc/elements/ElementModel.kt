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

interface Element : Referenceable {
    val id: ElementInstanceId
}

interface Entry : Element

interface Cue : Element

interface Segment : Cue {
    val startFrame: Int
    val endFrame: Int
}

interface Keyframe : Cue {
    val frame: Int
}

@JvmInline
@Serializable
value class ElementTypeId(
    val value: DeclaredTypeId,
)

@JvmInline
@Serializable(with = ElementInstanceIdSerializer::class)
@TypewriterString
value class ElementInstanceId(
    val value: String,
)

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

@Target(AnnotationTarget.CLASS)
@Retention(AnnotationRetention.BINARY)
annotation class TypewriterElementFacet(
    val element: KClass<out Element>,
    val realm: Boolean = false,
    val execution: Boolean = true,
)

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

interface ElementPrototype<E : Element> : ConcreteTypePrototype<E> {
    val descriptor: ElementDescriptor
}

fun ElementDescriptor.isAvailable(facts: DeploymentFacts): Boolean = availability.evaluate(facts)

fun ElementDescriptor.requireMatchingValue(value: DataValue.Polymorphic) {
    require(value.concreteType.id == TypeId.Declared(id.value)) {
        "Element value type ${value.concreteType.id} does not match descriptor ${id.value}."
    }
}
