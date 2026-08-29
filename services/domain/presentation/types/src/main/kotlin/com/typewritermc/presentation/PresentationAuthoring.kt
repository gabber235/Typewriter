package com.typewritermc.presentation

import com.typewritermc.capability.RealmCommandCapabilityRef
import com.typewritermc.capability.RealmSearchCapabilityRef
import com.typewritermc.types.TypePrototypeRegistry
import skirout.editor.v1.presentation.PresentationNode
import kotlin.reflect.KClass
import kotlin.reflect.KProperty1

/** Marks a top level presentation specification for compile time discovery. */
@Target(AnnotationTarget.FUNCTION)
@Retention(AnnotationRetention.BINARY)
annotation class TypewriterPresentation(
    val default: Boolean = false,
    val priority: Int = 0,
)

class PresentationBuildContext internal constructor(
    private val prototypes: TypePrototypeRegistry,
) {
    internal fun field(
        owner: KClass<*>,
        kotlinName: String,
    ): FieldReference {
        val prototype = prototypes.require(owner)
        val serializedName =
            requireNotNull(prototype.serializedFieldNames[kotlinName]) {
                "Serialized field metadata is unavailable for ${owner.qualifiedName}.$kotlinName."
            }
        return FieldReference(serializedName)
    }
}

/** An authored presentation before deployment specific type metadata is applied. */
class PresentationSpec<T : Any> internal constructor(
    val name: String,
    val target: KClass<T>,
    internal val root: AuthoredPresentationNode,
) {
    init {
        require(name.isNotBlank()) { "Presentation names must not be blank." }
    }
}

context(context: PresentationBuildContext)
inline fun <reified T : Any> presentation(
    name: String,
    block: PresentationBuilder<T>.() -> Unit,
): PresentationSpec<T> =
    PresentationBuilder(T::class, context)
        .apply(block)
        .build(name)

@PresentationDsl
class PresentationBuilder<T : Any>
    @PublishedApi
    internal constructor(
        @PublishedApi internal val target: KClass<T>,
        @PublishedApi internal val context: PresentationBuildContext,
    ) {
        private val children = mutableListOf<AuthoredPresentationNode>()

        fun section(
            key: String,
            title: String? = null,
            initiallyExpanded: Boolean? = null,
            block: PresentationBuilder<T>.() -> Unit,
        ) {
            require(key.isNotBlank()) { "Section keys must not be blank." }
            val content = PresentationBuilder(target, context).apply(block).column()
            children += AuthoredPresentationNode.Section(key, title, initiallyExpanded, content)
        }

        fun textInput(
            property: KProperty1<T, String>,
            multiline: Boolean? = null,
            label: String? = null,
        ) {
            children += AuthoredPresentationNode.TextInput(context.field(target, property.name), multiline, label)
        }

        fun numericInput(
            property: KProperty1<T, Number>,
            label: String? = null,
        ) {
            children += AuthoredPresentationNode.NumericInput(context.field(target, property.name), label)
        }

        fun commandButton(
            label: String,
            capability: RealmCommandCapabilityRef<T>,
        ) {
            require(label.isNotBlank()) { "Command button labels must not be blank." }
            children += AuthoredPresentationNode.CommandButton(label, capability)
        }

        fun <Result : Any> realmSearchInput(
            property: KProperty1<T, Result>,
            capability: RealmSearchCapabilityRef<T, Result>,
            resultKey: KProperty1<Result, String>,
            resultLabel: KProperty1<Result, String> = resultKey,
            label: String? = null,
        ) {
            children +=
                AuthoredPresentationNode.RealmSearchInput(
                    field = context.field(target, property.name),
                    capability = capability,
                    resultKey = context.field(capability.resultType, resultKey.name),
                    resultLabel = context.field(capability.resultType, resultLabel.name),
                    label = label,
                )
        }

        fun <V : Any> polymorphicInput(
            property: KProperty1<T, V>,
            block: PolymorphicPresentationBuilder<V>.() -> Unit,
        ) {
            val types = PolymorphicPresentationBuilder<V>(context).apply(block).build()
            require(types.isNotEmpty()) { "Polymorphic inputs require at least one concrete type." }
            children += AuthoredPresentationNode.PolymorphicInput(context.field(target, property.name), types)
        }

        /** Embeds any node from the complete canonical presentation algebra. */
        fun wire(node: PresentationNode) {
            require(node.nodeId.isNotBlank()) { "Embedded presentation nodes require an explicit node id." }
            children += AuthoredPresentationNode.Wire(node)
        }

        @PublishedApi
        internal fun build(name: String): PresentationSpec<T> = PresentationSpec(name, target, column())

        @PublishedApi
        internal fun column(): AuthoredPresentationNode = AuthoredPresentationNode.Column(children.toList())
    }

@PresentationDsl
class PolymorphicPresentationBuilder<T : Any> internal constructor(
    @PublishedApi internal val context: PresentationBuildContext,
) {
    @PublishedApi
    internal val types = mutableListOf<ConcretePresentation>()

    inline fun <reified C : T> type(
        label: String,
        block: PresentationBuilder<C>.() -> Unit,
    ) {
        require(label.isNotBlank()) { "Concrete type labels must not be blank." }
        types += ConcretePresentation(C::class, label, PresentationBuilder(C::class, context).apply(block).column())
    }

    internal fun build(): List<ConcretePresentation> = types.toList()
}

@DslMarker
annotation class PresentationDsl

internal data class FieldReference(
    val serializedName: String,
)

@PublishedApi
internal data class ConcretePresentation(
    val type: KClass<*>,
    val label: String,
    val root: AuthoredPresentationNode,
)

internal sealed interface AuthoredPresentationNode {
    data class Column(
        val children: List<AuthoredPresentationNode>,
    ) : AuthoredPresentationNode

    data class Section(
        val key: String,
        val title: String?,
        val initiallyExpanded: Boolean?,
        val child: AuthoredPresentationNode,
    ) : AuthoredPresentationNode

    data class TextInput(
        val field: FieldReference,
        val multiline: Boolean?,
        val label: String?,
    ) : AuthoredPresentationNode

    data class NumericInput(
        val field: FieldReference,
        val label: String?,
    ) : AuthoredPresentationNode

    data class CommandButton(
        val label: String,
        val capability: RealmCommandCapabilityRef<*>,
    ) : AuthoredPresentationNode

    data class RealmSearchInput(
        val field: FieldReference,
        val capability: RealmSearchCapabilityRef<*, *>,
        val resultKey: FieldReference,
        val resultLabel: FieldReference,
        val label: String?,
    ) : AuthoredPresentationNode

    data class PolymorphicInput(
        val field: FieldReference,
        val types: List<ConcretePresentation>,
    ) : AuthoredPresentationNode

    data class Wire(
        val node: PresentationNode,
    ) : AuthoredPresentationNode
}
