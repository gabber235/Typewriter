package com.typewritermc.presentation

import com.typewritermc.capability.RealmCommandCapabilityRef
import com.typewritermc.capability.RealmSearchCapabilityRef
import com.typewritermc.types.Color
import com.typewritermc.types.FloatWidth
import com.typewritermc.types.Icon
import com.typewritermc.types.IntegerWidth
import com.typewritermc.types.PresentationRole
import com.typewritermc.types.TypeExpression
import com.typewritermc.types.TypePrototypeRegistry
import skirout.editor.v1.presentation.PresentationNode
import kotlin.reflect.KClass
import kotlin.reflect.KProperty1

/**
 * Registers a top level presentation declaration for generated discovery.
 *
 * [default] participates in the target type default selection. Higher priorities are considered first; tied
 * priorities produce diagnostics and selection proceeds to a lower unique priority.
 */
@Target(AnnotationTarget.FUNCTION)
@Retention(AnnotationRetention.BINARY)
annotation class TypewriterPresentation(
    val default: Boolean = false,
    val priority: Int = 0,
    val roles: Array<PresentationRole> = [],
)

/**
 * Resolves authored Kotlin property references against deployment serialization metadata.
 *
 * A property must have a serialized name in its prototype. This prevents UI bindings from silently using Kotlin
 * names that differ from the stored value.
 */
class PresentationBuildContext(
    private val prototypes: TypePrototypeRegistry,
) {
    internal fun type(owner: KClass<*>): TypeExpression =
        when (owner) {
            String::class -> TypeExpression.StringType()
            Boolean::class -> TypeExpression.Boolean
            Byte::class -> TypeExpression.Integer(IntegerWidth.SIGNED_8)
            Short::class -> TypeExpression.Integer(IntegerWidth.SIGNED_16)
            Int::class -> TypeExpression.Integer(IntegerWidth.SIGNED_32)
            Long::class -> TypeExpression.Integer(IntegerWidth.SIGNED_64)
            Float::class -> TypeExpression.Float(FloatWidth.FLOAT_32)
            Double::class -> TypeExpression.Float(FloatWidth.FLOAT_64)
            Unit::class -> TypeExpression.Unit
            else -> TypeExpression.Named(prototypes.require(owner).type)
        }

    @PublishedApi
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

/**
 * Retains an authored presentation tree and target class until deployment catalog compilation.
 *
 * The name must be nonblank and combines with the provider namespace to form the presentation identity.
 * Compilation resolves field paths, type references, and capability dependencies.
 */
class PresentationSpec<T : Any> internal constructor(
    val name: String,
    val target: KClass<T>,
    val inputs: List<PresentationInputRef<*>>,
    internal val root: AuthoredPresentationNode,
) {
    init {
        require(name.isNotBlank()) { "Presentation names must not be blank." }
    }

    /** Looks up a declared input and verifies its requested Kotlin type. */
    inline fun <reified V : Any> input(name: String): PresentationInputRef<V> {
        val input = inputs.single { it.name == name }
        require(input.type == V::class) { "Presentation input type does not match $name." }
        @Suppress("UNCHECKED_CAST")
        return input as PresentationInputRef<V>
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

/**
 * Builds a role presentation with explicit inputs and no implicit value binding.
 *
 * Use this when a semantic surface needs multiple context values. The declaration target still associates roles
 * with [T], while every runtime input is declared by [block].
 */
context(context: PresentationBuildContext)
inline fun <reified T : Any> rolePresentation(
    name: String,
    block: PresentationBuilder<T>.() -> Unit,
): PresentationSpec<T> =
    PresentationBuilder(T::class, context, implicitPrimaryInput = false)
        .apply(block)
        .build(name)

/**
 * Builds an ordered presentation for one Kotlin target type.
 *
 * Property based controls resolve serialized names immediately through the build context. The resulting tree is
 * compiled later into the canonical panel protocol, where duplicate node identities and missing capabilities are
 * diagnosed.
 */
@PresentationDsl
class PresentationBuilder<T : Any>
    @PublishedApi
    internal constructor(
        @PublishedApi internal val target: KClass<T>,
        @PublishedApi internal val context: PresentationBuildContext,
        @PublishedApi internal val inputs: MutableList<PresentationInputRef<*>> = mutableListOf(),
        private val implicitPrimaryInput: Boolean = true,
    ) {
        init {
            if (implicitPrimaryInput && target != Unit::class && inputs.isEmpty()) {
                inputs += PresentationInputRef("value", target, false, 0, context)
            }
        }

        private val children = mutableListOf<AuthoredPresentationNode>()

        /** Appends one node supplied by a focused SDK extension in this module. */
        internal fun append(node: AuthoredPresentationNode) {
            children += node
        }

        /** Declares a read only value supplied to this presentation. */
        inline fun <reified V : Any> input(name: String): PresentationInputRef<V> = declareInput(name, V::class, false)

        /** Declares a value that the panel may edit; persistence remains the caller's responsibility. */
        inline fun <reified V : Any> editableInput(name: String): PresentationInputRef<V> = declareInput(name, V::class, true)

        @PublishedApi
        internal fun <V : Any> declareInput(
            name: String,
            type: KClass<V>,
            editable: Boolean,
        ): PresentationInputRef<V> {
            require(name.isNotBlank() && inputs.none { it.name == name }) { "Presentation input names must be unique and nonblank." }
            return PresentationInputRef(name, type, editable, inputs.size.toLong(), context).also(inputs::add)
        }

        /**
         * Adds an editable text control whose changes are reported through the bound input.
         *
         * [multiline] and [label] are presentation metadata. Persistence remains owned by the caller of the
         * presentation, not by the builder.
         */
        fun textInput(
            value: PresentationValue<String>,
            multiline: Boolean? = null,
            label: String? = null,
        ) {
            children += AuthoredPresentationNode.TextInput(value.reference(), multiline, label)
        }

        /**
         * Adds an editable numeric control whose changes are reported through the bound input.
         *
         * The numeric type is retained by [value]. Persistence and range policy remain outside the presentation
         * builder.
         */
        fun <V : Number> numericInput(
            value: PresentationValue<V>,
            label: String? = null,
        ) {
            children += AuthoredPresentationNode.NumericInput(value.reference(), label)
        }

        /** Adds an editable color control for a typed color value. */
        fun colorInput(
            value: PresentationValue<Color>,
            includeAlpha: Boolean = false,
            label: String? = null,
        ) {
            children += AuthoredPresentationNode.ColorInput(value.reference(), includeAlpha, label)
        }

        /** Places transaction controls for an editable input without owning its persistence policy. */
        fun commitControls(value: PresentationValue<*>) {
            require(value.input.editable) { "Commit controls require an editable presentation input." }
            children += AuthoredPresentationNode.CommitControls(value)
        }

        /** Adds a button whose action sends [payload] through [capability]. */
        fun <V : Any> commandButton(
            label: String,
            capability: RealmCommandCapabilityRef<V>,
            payload: PresentationValue<V>,
        ) {
            require(label.isNotBlank()) { "Command button labels must not be blank." }
            children += AuthoredPresentationNode.CommandButton(label, capability, payload)
        }

        /**
         * Adds non editable text rendered from [value].
         *
         * The node observes the input during rendering and cannot produce an edit or persistence request.
         */
        fun text(value: PresentationValue<String>) {
            children += AuthoredPresentationNode.Text(value)
        }

        /** Adds non editable text computed from a typed authored expression. */
        fun text(value: PresentationExpression<String>) {
            children += AuthoredPresentationNode.ExpressionText(value)
        }

        /** Adds flat styled text runs with shared paragraph behavior. */
        fun richText(
            vararg runs: PresentationTextRun,
            maxLines: Int? = null,
            ellipsis: Boolean = false,
            softWrap: Boolean = true,
            selectable: Boolean = false,
            secondary: Boolean = false,
        ) {
            require(runs.isNotEmpty()) { "Rich text requires at least one run." }
            require(maxLines == null || maxLines > 0) { "Rich text maximum lines must be positive." }
            children +=
                AuthoredPresentationNode.RichText(
                    runs = runs.toList(),
                    maxLines = maxLines,
                    ellipsis = ellipsis,
                    softWrap = softWrap,
                    selectable = selectable,
                    secondary = secondary,
                )
        }

        /** Adds a display only icon whose value remains a typed expression. */
        fun icon(value: PresentationValue<Icon>) {
            children += AuthoredPresentationNode.Icon(value)
        }

        /**
         * Offers typed literal choices. Use [wire] for custom protocol expressions.
         *
         * Initialization is eligible only when the current value equals its type initializer and is absent from
         * the options. An available [defaultValue] wins; otherwise the sole distinct option is selected, if any.
         * Initialization writes through the normal editable input callback and follows its commit policy.
         * Existing selections are preserved. Each mounted control initializes at most once; later default changes
         * do not replace edits. Disabled controls wait until editable, and removal cancels pending initialization.
         */
        fun <V : Any> selectInput(
            value: PresentationValue<V>,
            options: List<PresentationOption<V>>,
            defaultValue: PresentationValue<V>? = null,
            label: String? = null,
        ) {
            children += AuthoredPresentationNode.SelectInput(value, options, defaultValue, label)
        }

        /** Delegates rendering of [value] to its selected catalog presentation. */
        fun <V : Any> defaultEditor(value: PresentationValue<V>) {
            children += AuthoredPresentationNode.DefaultEditor(value)
        }

        /** Adds a selector and editor for the concrete alternatives declared in [block]. */
        fun <V : Any> polymorphicInput(
            value: PresentationValue<V>,
            block: PolymorphicPresentationBuilder<V>.() -> Unit,
        ) {
            val types = PolymorphicPresentationBuilder<V>(context).apply(block).build()
            require(types.isNotEmpty()) { "Polymorphic inputs require at least one concrete type." }
            children += AuthoredPresentationNode.PolymorphicInput(value.reference(), types)
        }

        /** Embeds another presentation and maps its inputs from [arguments]. */
        fun include(
            id: com.typewritermc.types.PresentationId,
            vararg arguments: PresentationArgumentRef,
        ) {
            children += AuthoredPresentationNode.Invocation(id, arguments.toList())
        }

        /** Groups authored controls under a stable collapsible section identity. */
        fun section(
            key: String,
            title: String? = null,
            initiallyExpanded: Boolean? = null,
            block: PresentationBuilder<T>.() -> Unit,
        ) {
            require(key.isNotBlank()) { "Section keys must not be blank." }
            val content = PresentationBuilder(target, context, inputs).apply(block).column()
            children += AuthoredPresentationNode.Section(key, title, initiallyExpanded, content)
        }

        /** Adds a text control bound to a serialized property of the primary input. */
        fun textInput(
            property: KProperty1<T, String>,
            multiline: Boolean? = null,
            label: String? = null,
        ) {
            children += AuthoredPresentationNode.TextInput(context.field(target, property.name), multiline, label)
        }

        /** Adds a numeric control bound to a serialized property of the primary input. */
        fun numericInput(
            property: KProperty1<T, Number>,
            label: String? = null,
        ) {
            children += AuthoredPresentationNode.NumericInput(context.field(target, property.name), label)
        }

        /** Adds a button whose request is the primary input and whose action uses [capability]. */
        fun commandButton(
            label: String,
            capability: RealmCommandCapabilityRef<T>,
        ) {
            require(label.isNotBlank()) { "Command button labels must not be blank." }
            children += AuthoredPresentationNode.CommandButton(label, capability)
        }

        /**
         * Adds a search control whose selected result is written to [value] through the presentation binding.
         *
         * The Realm capability supplies results asynchronously. [resultKey] identifies each option and [resultLabel]
         * supplies its display text; the caller still owns persistence of the edited value.
         */
        fun <Context : Any, Result : Any> realmSearchInput(
            value: PresentationValue<Result>,
            capability: RealmSearchCapabilityRef<Context, Result>,
            payload: PresentationValue<Context>,
            resultKey: KProperty1<Result, String>,
            resultLabel: KProperty1<Result, String> = resultKey,
            label: String? = null,
        ) {
            children +=
                AuthoredPresentationNode.RealmSearchInput(
                    field = value.reference(),
                    capability = capability,
                    resultKey = context.field(capability.resultType, resultKey.name),
                    resultLabel = context.field(capability.resultType, resultLabel.name),
                    label = label,
                    payload = payload,
                )
        }

        /** Declares a typed search control; the panel executes its compiled provider tree. */
        fun <Value : Any, Result : Any> searchInput(
            value: PresentationValue<Value>,
            resultType: KClass<Result>,
            placeholder: String? = null,
            label: String? = null,
            maximumExtent: Int = 320,
            block: SearchInputBuilder<Value, Result>.() -> Unit,
        ) {
            require(inputs.any { it === value.input }) { "Search input belongs to another presentation." }
            children +=
                AuthoredPresentationNode.SearchInput(
                    SearchInputBuilder(context, resultType, value.type)
                        .apply(block)
                        .build(value, placeholder, label, maximumExtent),
                )
        }

        /** Adds a realm backed search control bound to a property of the primary input. */
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

        /** Adds a polymorphic selector bound to a property of the primary input. */
        fun <V : Any> polymorphicInput(
            property: KProperty1<T, V>,
            block: PolymorphicPresentationBuilder<V>.() -> Unit,
        ) {
            val types = PolymorphicPresentationBuilder<V>(context).apply(block).build()
            require(types.isNotEmpty()) { "Polymorphic inputs require at least one concrete type." }
            children += AuthoredPresentationNode.PolymorphicInput(context.field(target, property.name), types)
        }

        /**
         * Embeds a canonical protocol node when the typed DSL does not expose the required control.
         *
         * The node must have an explicit nonblank id. It is retained verbatim rather than rebased to the
         * surrounding field path, so the author owns its bindings and ids; full tree uniqueness is checked during
         * compilation.
         */
        fun wire(node: PresentationNode) {
            require(node.nodeId.isNotBlank()) { "Embedded presentation nodes require an explicit node id." }
            children += AuthoredPresentationNode.Wire(node)
        }

        /** Adds a row whose parent owns fixed and flexible child allocation. */
        fun row(
            spacing: Double = 0.0,
            block: PresentationAxisBuilder<T>.() -> Unit,
        ) {
            require(spacing.isFinite() && spacing >= 0.0) { "Row spacing must be finite and nonnegative." }
            children +=
                AuthoredPresentationNode.Axis(
                    row = true,
                    spacing = spacing,
                    children = PresentationAxisBuilder(target, context, inputs).apply(block).build(),
                )
        }

        /** Adds a column whose parent owns fixed and flexible child allocation. */
        fun column(
            spacing: Double = 0.0,
            block: PresentationAxisBuilder<T>.() -> Unit,
        ) {
            require(spacing.isFinite() && spacing >= 0.0) { "Column spacing must be finite and nonnegative." }
            children +=
                AuthoredPresentationNode.Axis(
                    row = false,
                    spacing = spacing,
                    children = PresentationAxisBuilder(target, context, inputs).apply(block).build(),
                )
        }

        /** Builds a measured leading layout whose optional slots collapse when bounded space is insufficient. */
        fun adaptiveLeading(
            leading: PresentationBuilder<T>.() -> Unit,
            center: (PresentationBuilder<T>.() -> Unit)? = null,
            suffix: (PresentationBuilder<T>.() -> Unit)? = null,
        ) {
            children +=
                AuthoredPresentationNode.AdaptiveLeading(
                    leading = PresentationBuilder(target, context, inputs).apply(leading).column(),
                    center = center?.let { PresentationBuilder(target, context, inputs).apply(it).column() },
                    suffix = suffix?.let { PresentationBuilder(target, context, inputs).apply(it).column() },
                )
        }

        @PublishedApi
        internal fun build(name: String): PresentationSpec<T> = PresentationSpec(name, target, inputs.toList(), column())

        @PublishedApi
        internal fun column(): AuthoredPresentationNode = AuthoredPresentationNode.Column(children.toList())
    }

/** Controls how an axis parent allocates remaining space to one child. */
enum class PresentationFlexFit { TIGHT, LOOSE }

/** Builds atomic axis children from the same typed presentation primitives. */
@PresentationDsl
class PresentationAxisBuilder<T : Any> internal constructor(
    private val target: KClass<T>,
    private val context: PresentationBuildContext,
    private val inputs: MutableList<PresentationInputRef<*>>,
) {
    private val children = mutableListOf<AuthoredPresentationAxisChild>()

    /** Adds a fixed child built from ordinary presentation primitives. */
    fun fixed(block: PresentationBuilder<T>.() -> Unit) {
        children += AuthoredPresentationAxisChild.Fixed(PresentationBuilder(target, context, inputs).apply(block).column())
    }

    /** Adds a flexible child while keeping allocation metadata with its node. */
    fun flexible(
        flex: Int = 1,
        fit: PresentationFlexFit = PresentationFlexFit.LOOSE,
        block: PresentationBuilder<T>.() -> Unit,
    ) {
        require(flex > 0) { "Axis child flex must be positive." }
        children +=
            AuthoredPresentationAxisChild.Flexible(
                child = PresentationBuilder(target, context, inputs).apply(block).column(),
                flex = flex,
                fit = fit,
            )
    }

    internal fun build(): List<AuthoredPresentationAxisChild> = children.toList()
}

/**
 * Collects explicitly offered concrete alternatives for a polymorphic field.
 *
 * Each alternative has its own typed builder and nonblank label. Runtime catalog compilation requires prototypes
 * for these concrete classes.
 */
@PresentationDsl
class PolymorphicPresentationBuilder<T : Any> internal constructor(
    @PublishedApi internal val context: PresentationBuildContext,
) {
    @PublishedApi
    internal val types = mutableListOf<ConcretePresentation>()

    /** Adds one concrete alternative and builds its nested editor in the alternative's scope. */
    inline fun <reified C : T> type(
        label: String,
        block: PresentationBuilder<C>.() -> Unit,
    ) {
        require(label.isNotBlank()) { "Concrete type labels must not be blank." }
        types += ConcretePresentation(C::class, label, PresentationBuilder(C::class, context).apply(block).column())
    }

    internal fun build(): List<ConcretePresentation> = types.toList()
}

/** Prevents presentation builder scopes from being mixed accidentally. */
@DslMarker
annotation class PresentationDsl

@PublishedApi
internal data class FieldReference(
    val serializedName: String,
    val input: PresentationInputRef<*>? = null,
    val prefix: List<String> = emptyList(),
)

@PublishedApi
internal data class ConcretePresentation(
    val type: KClass<*>,
    val label: String,
    val root: AuthoredPresentationNode,
)

internal sealed interface AuthoredPresentationNode {
    data class CommitControls(
        val value: PresentationValue<*>,
    ) : AuthoredPresentationNode

    data class SelectInput<V : Any>(
        val value: PresentationValue<V>,
        val options: List<PresentationOption<V>>,
        val defaultValue: PresentationValue<V>?,
        val label: String?,
    ) : AuthoredPresentationNode

    data class DefaultEditor(
        val value: PresentationValue<*>,
    ) : AuthoredPresentationNode

    data class Text(
        val value: PresentationValue<String>,
    ) : AuthoredPresentationNode

    data class ExpressionText(
        val value: PresentationExpression<String>,
    ) : AuthoredPresentationNode

    data class RichText(
        val runs: List<PresentationTextRun>,
        val maxLines: Int?,
        val ellipsis: Boolean,
        val softWrap: Boolean,
        val selectable: Boolean,
        val secondary: Boolean,
    ) : AuthoredPresentationNode

    data class Icon(
        val value: PresentationValue<com.typewritermc.types.Icon>,
    ) : AuthoredPresentationNode

    data class Invocation(
        val id: com.typewritermc.types.PresentationId,
        val arguments: List<PresentationArgumentRef>,
    ) : AuthoredPresentationNode

    data class Column(
        val children: List<AuthoredPresentationNode>,
    ) : AuthoredPresentationNode

    data class Axis(
        val row: Boolean,
        val spacing: Double,
        val children: List<AuthoredPresentationAxisChild>,
    ) : AuthoredPresentationNode

    data class AdaptiveLeading(
        val leading: AuthoredPresentationNode,
        val center: AuthoredPresentationNode?,
        val suffix: AuthoredPresentationNode?,
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

    data class ColorInput(
        val field: FieldReference,
        val includeAlpha: Boolean,
        val label: String?,
    ) : AuthoredPresentationNode

    data class CommandButton(
        val label: String,
        val capability: RealmCommandCapabilityRef<*>,
        val payload: PresentationValue<*>? = null,
    ) : AuthoredPresentationNode

    data class RealmSearchInput(
        val field: FieldReference,
        val capability: RealmSearchCapabilityRef<*, *>,
        val resultKey: FieldReference,
        val resultLabel: FieldReference,
        val label: String?,
        val payload: PresentationValue<*>? = null,
    ) : AuthoredPresentationNode

    data class SearchInput(
        val specification: AuthoredSearchInput<*, *>,
    ) : AuthoredPresentationNode

    data class PolymorphicInput(
        val field: FieldReference,
        val types: List<ConcretePresentation>,
    ) : AuthoredPresentationNode

    data class Wire(
        val node: PresentationNode,
    ) : AuthoredPresentationNode
}

/** One flat rich text run. Style values override the shared inherited text style. */
data class PresentationTextRun(
    val text: PresentationExpression<String>,
    val fontWeight: Double? = null,
    val fontItalic: Double? = null,
) {
    init {
        require(fontWeight == null || (fontWeight.isFinite() && fontWeight in 1.0..1000.0)) {
            "Text run weight must be finite and between 1 and 1000."
        }
        require(fontItalic == null || (fontItalic.isFinite() && fontItalic in 0.0..1.0)) {
            "Text run italic value must be finite and between 0 and 1."
        }
    }
}

internal sealed interface AuthoredPresentationAxisChild {
    val child: AuthoredPresentationNode

    data class Fixed(
        override val child: AuthoredPresentationNode,
    ) : AuthoredPresentationAxisChild

    data class Flexible(
        override val child: AuthoredPresentationNode,
        val flex: Int,
        val fit: PresentationFlexFit,
    ) : AuthoredPresentationAxisChild
}
