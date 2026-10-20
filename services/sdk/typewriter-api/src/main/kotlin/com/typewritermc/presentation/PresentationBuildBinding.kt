package com.typewritermc.presentation

import com.typewritermc.expression.Expr
import com.typewritermc.expression.Handled
import com.typewritermc.expression.children
import com.typewritermc.types.CollectionKind
import com.typewritermc.types.PresentationRole
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeTemplate
import com.typewritermc.types.TypeUse
import com.typewritermc.types.catalog.CheckedType
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.catalog.ResolvedRepresentation
import com.typewritermc.types.catalog.apply
import com.typewritermc.types.catalog.isNominalSubtype
import com.typewritermc.types.catalog.resolve
import com.typewritermc.types.toTemplate
import skirout.editor.v1.expression.ExpressionNode

/**
 * What one presentation build is for: the subject [type], the requested [role], the native classes of published
 * types, and the owner side endpoints of ownership relations, which create actions may link new resources into.
 */
class PresentationBuildBinding(
    val type: CheckedPresentationTemplate,
    val role: PresentationRole,
    internal val nativeTypes: Map<kotlin.reflect.KClass<*>, TypeTemplate.Named> = emptyMap(),
    internal val ownershipEndpoints: Set<com.typewritermc.types.EndpointId> = emptySet(),
)

class CheckedPresentationTemplate internal constructor(
    val type: TypeTemplate,
    private val fieldResolver: (TypeTemplate, String) -> TypeTemplate?,
    private val nestedResolver: (TypeTemplate, NestedPresentationSlot) -> PresentationNestedTemplate?,
    private val descriptorSelector: (TypeTemplate, List<PresentationDescriptor>) -> PresentationDescriptor?,
    private val expressionChecker: (
        ExpressionNode,
        Map<com.typewritermc.expression.ExpressionBindingId, TypeTemplate>,
        TypeTemplate,
        Set<com.typewritermc.expression.ExpressionBindingId>,
        Boolean,
    ) -> List<String>,
    private val payloadResolver: (TypeTemplate) -> TypeTemplate,
    private val linkResolver: (TypeTemplate) -> PresentationLinkTemplate?,
    private val subtypeChecker: (TypeDefinitionId, TypeDefinitionId) -> Boolean,
) {
    internal fun field(name: String): CheckedPresentationTemplate =
        CheckedPresentationTemplate(
            type = requireNotNull(fieldResolver(type, name)) { "Field $name is not present in $type." },
            fieldResolver = fieldResolver,
            nestedResolver = nestedResolver,
            descriptorSelector = descriptorSelector,
            expressionChecker = expressionChecker,
            payloadResolver = payloadResolver,
            linkResolver = linkResolver,
            subtypeChecker = subtypeChecker,
        )

    internal fun nested(slot: NestedPresentationSlot): CheckedPresentationNested {
        val nested = requireNotNull(nestedResolver(type, slot)) { "Presentation slot $slot is not available for $type." }
        return CheckedPresentationNested(
            type =
                CheckedPresentationTemplate(
                    type = nested.type,
                    fieldResolver = fieldResolver,
                    nestedResolver = nestedResolver,
                    descriptorSelector = descriptorSelector,
                    expressionChecker = expressionChecker,
                    payloadResolver = payloadResolver,
                    linkResolver = linkResolver,
                    subtypeChecker = subtypeChecker,
                ),
            collectionKind = nested.collectionKind,
        )
    }

    internal fun rebind(type: TypeTemplate): CheckedPresentationTemplate =
        CheckedPresentationTemplate(
            type,
            fieldResolver,
            nestedResolver,
            descriptorSelector,
            expressionChecker,
            payloadResolver,
            linkResolver,
            subtypeChecker,
        )

    /** The field at [name], or null when this type has no such field. */
    internal fun fieldOrNull(name: String): CheckedPresentationTemplate? = if (fieldResolver(type, name) == null) null else field(name)

    /** The item type of this collection type, or null when it is not a collection. */
    internal fun itemsOrNull(): CheckedPresentationTemplate? = nestedResolver(type, NestedPresentationSlot.Items)?.let { rebind(it.type) }

    /** The endpoint and target of this type when it is a link, otherwise null. */
    internal fun link(): PresentationLinkTemplate? = linkResolver(type)

    internal fun isSubtype(
        actual: TypeDefinitionId,
        expected: TypeDefinitionId,
    ): Boolean = actual == expected || subtypeChecker(actual, expected)

    internal fun select(descriptors: List<PresentationDescriptor>): PresentationDescriptor? = descriptorSelector(type, descriptors)

    internal fun payloadType(): TypeTemplate = payloadResolver(type)

    internal fun checkExpression(
        body: ExpressionNode,
        bindings: Map<com.typewritermc.expression.ExpressionBindingId, TypeTemplate>,
        expected: TypeTemplate,
        present: Set<com.typewritermc.expression.ExpressionBindingId> = emptySet(),
        mayBeMissing: Boolean = false,
    ): List<String> = expressionChecker(body, bindings, expected, present, mayBeMissing)
}

/** A link type: the endpoint of its relation on the side of the resource holding it, and its target type. */
internal data class PresentationLinkTemplate(
    val endpoint: com.typewritermc.types.EndpointId,
    val target: TypeTemplate,
)

internal data class PresentationNestedTemplate(
    val type: TypeTemplate,
    val collectionKind: CollectionKind? = null,
)

internal data class CheckedPresentationNested(
    val type: CheckedPresentationTemplate,
    val collectionKind: CollectionKind? = null,
)

fun CheckedType.presentationTemplate(): CheckedPresentationTemplate {
    fun resolve(template: TypeTemplate): CheckedType {
        val use =
            when (val applied = template.apply(emptyMap())) {
                is Resolution.Ready -> applied.value
                is Resolution.Invalid -> error("A concrete presentation binding cannot contain free type parameters.")
            }
        return when (val resolved = resolve(use)) {
            is Resolution.Ready -> resolved.value
            is Resolution.Invalid -> error("Presentation type $use is unavailable.")
        }
    }

    return CheckedPresentationTemplate(
        type = use.toTemplate(),
        fieldResolver = { parent, name ->
            resolve(parent)
                .schema.fields
                .singleOrNull { it.key == name }
                ?.type
                ?.toTemplate()
        },
        nestedResolver = { parent, slot ->
            val checked = resolve(parent)
            when (slot) {
                NestedPresentationSlot.Payload, NestedPresentationSlot.Fields -> {
                    PresentationNestedTemplate(parent)
                }

                NestedPresentationSlot.Items -> {
                    val representation = checked.schema.representation as? ResolvedRepresentation.Sequence
                    representation?.let { PresentationNestedTemplate(it.item.toTemplate(), it.kind) }
                }

                NestedPresentationSlot.Keys -> {
                    val representation = checked.schema.representation as? ResolvedRepresentation.Mapping
                    representation?.let { PresentationNestedTemplate(it.key.toTemplate()) }
                }

                NestedPresentationSlot.Values -> {
                    when (val representation = checked.schema.representation) {
                        is ResolvedRepresentation.Mapping -> PresentationNestedTemplate(representation.value.toTemplate())
                        else -> (checked.use as? TypeUse.Nullable)?.let { PresentationNestedTemplate(it.value.toTemplate()) }
                    }
                }
            }
        },
        expressionChecker = {
            body,
            bindings,
            expected,
            present,
            mayBeMissing,
            ->
            checkPresentationExpression(body, bindings, expected, present, this::resolve, mayBeMissing)
        },
        payloadResolver = { parent ->
            val checked = resolve(parent)
            (checked.schema.representation as? ResolvedRepresentation.Scalar)?.let { TypeTemplate.Scalar(it.kind) } ?: parent
        },
        linkResolver = { parent ->
            (resolve(parent).schema.representation as? ResolvedRepresentation.Link)?.let { link ->
                PresentationLinkTemplate(link.endpoint, link.target.toTemplate())
            }
        },
        subtypeChecker = { actual, expected -> isNominalSubtype(actual, expected) },
        descriptorSelector = { template, descriptors ->
            val actual = resolve(template)
            selectMostSpecificDescriptors(
                descriptors.filter { descriptor -> descriptor.target.matches(actual) },
                actual,
            )
        },
    )
}

interface Layout :
    PresentationContent,
    PresentationData,
    PresentationInteractions,
    PresentationQueries,
    InputAppearanceLayout {
    val role: PresentationRole

    val subject: PresentationSubjectExpressions

    val context: PresentationContextExpressions

    fun clippedRow(
        spacing: Double = 0.0,
        body: Layout.() -> Unit,
    )

    fun row(
        spacing: Double = 0.0,
        main: MainAxisAlignment = MainAxisAlignment.Start,
        cross: CrossAxisAlignment = CrossAxisAlignment.Center,
        body: AxisLayout.() -> Unit,
    )

    fun column(
        spacing: Double = 0.0,
        main: MainAxisAlignment = MainAxisAlignment.Start,
        cross: CrossAxisAlignment = CrossAxisAlignment.Center,
        body: AxisLayout.() -> Unit,
    )

    fun wrap(
        spacing: Double = 0.0,
        runSpacing: Double = 0.0,
        body: Layout.() -> Unit,
    )

    fun grid(
        columns: Int,
        horizontalSpacing: Double = 0.0,
        verticalSpacing: Double = 0.0,
        body: Layout.() -> Unit,
    )

    /**
     * Paints children over each other. Children declared directly flow: they size the stack and sit at [alignment],
     * top start by default. [StackLayout.positioned] children are placed by insets relative to the stack.
     */
    fun stack(
        alignment: PresentationAlignment? = null,
        body: StackLayout.() -> Unit,
    )

    fun section(
        border: PresentationBorder? = null,
        header: HeaderScope.() -> Unit = {},
        body: Layout.() -> Unit,
    )

    fun container(
        style: ContainerStyle,
        body: Layout.() -> Unit,
    )

    fun align(
        alignment: PresentationAlignment,
        body: Layout.() -> Unit,
    )

    /**
     * Constrains [body] in logical pixels. An exact [width] or [height] overrides the matching bounds; an absent
     * bound leaves the incoming constraint.
     */
    fun size(
        width: Double? = null,
        height: Double? = null,
        minimumWidth: Double? = null,
        maximumWidth: Double? = null,
        minimumHeight: Double? = null,
        maximumHeight: Double? = null,
        body: Layout.() -> Unit,
    )

    /** Paints [body] transformed by [style]; layout and hit testing keep its untransformed bounds. */
    fun transform(
        style: TransformStyle,
        body: Layout.() -> Unit,
    )

    fun padding(
        insets: PresentationInsets,
        body: Layout.() -> Unit,
    )

    fun tabs(
        initial: String? = null,
        body: TabsScope.() -> Unit,
    )

    fun adaptiveLeading(configure: AdaptiveLeadingScope.() -> Unit)

    fun slot(id: String)

    fun part(
        key: PresentationPartKey<*>,
        body: (Layout.() -> Unit)? = null,
    )

    fun divider(configure: DividerAppearanceScope.() -> Unit = {})

    fun spacer(
        width: Expr<Double, Handled>? = null,
        height: Expr<Double, Handled>? = null,
    )

    fun anchors(
        configure: AnchorScope.() -> Unit,
        body: Layout.() -> Unit,
    )

    fun connectionLayer(
        configure: ConnectionsScope.() -> Unit,
        body: Layout.() -> Unit,
    )

    fun node(
        id: String,
        properties: PresentationProperties = PresentationProperties(),
        header: HeaderScope.() -> Unit = {},
        body: Layout.() -> Unit,
    )

    fun remainingFields(configure: RemainingFields.() -> Unit = {})
}

interface AxisLayout : Layout {
    fun fixed(body: Layout.() -> Unit)

    fun flexible(
        flex: Int = 1,
        fit: FlexFit = FlexFit.Loose,
        body: Layout.() -> Unit,
    )
}

/** The children of a [Layout.stack]. Children declared directly flow; these are placed by insets. */
interface StackLayout : Layout {
    /**
     * Places [body] by insets and sizes in logical pixels relative to the stack. At most two of [start], [end] and
     * [width] apply horizontally, and at most two of [top], [bottom] and [height] vertically. [transition] animates
     * changes of the insets and sizes.
     */
    fun positioned(
        top: PresentationNumber? = null,
        start: PresentationNumber? = null,
        end: PresentationNumber? = null,
        bottom: PresentationNumber? = null,
        width: PresentationNumber? = null,
        height: PresentationNumber? = null,
        transition: PresentationTransitionPolicy? = null,
        body: Layout.() -> Unit,
    )

    /** Fills the whole stack with [body]. */
    fun fill(body: Layout.() -> Unit) =
        positioned(top = number(0.0), start = number(0.0), end = number(0.0), bottom = number(0.0), body = body)
}

interface RemainingFields {
    fun exclude(part: PresentationPartKey<*>)

    fun exclude(field: PresentedField<*, *>)
}

enum class MainAxisAlignment { Start, Center, End, SpaceBetween, SpaceAround, SpaceEvenly }

enum class CrossAxisAlignment { Start, Center, End, Stretch }

enum class FlexFit { Tight, Loose }

data class PresentationInsets(
    val start: Double,
    val top: Double,
    val end: Double,
    val bottom: Double,
)

sealed interface PresentationBorder {
    data class All(
        val width: Double,
        val color: PresentationColor,
    ) : PresentationBorder {
        init {
            require(width.isFinite() && width >= 0) { "Border width must be finite and nonnegative." }
        }
    }

    data class Sides(
        val top: Side? = null,
        val start: Side? = null,
        val end: Side? = null,
        val bottom: Side? = null,
    ) : PresentationBorder

    data class Side(
        val width: Double,
        val color: PresentationColor,
    ) {
        init {
            require(width.isFinite() && width >= 0) { "Border width must be finite and nonnegative." }
        }
    }
}

data class ContainerStyle(
    val background: PresentationColor? = null,
    val foreground: PresentationColor? = null,
    val border: PresentationBorder? = null,
    val radius: PresentationRadius = PresentationRadius.None,
    /** Animates changes of the colors, border and shadows; they apply at once when null. */
    val transition: PresentationTransitionPolicy? = null,
    /** Painted below the container in declaration order. */
    val shadows: List<PresentationShadow> = emptyList(),
)

sealed interface PresentationRadius {
    data object None : PresentationRadius

    data object Small : PresentationRadius

    data object Medium : PresentationRadius

    data object Large : PresentationRadius

    data class Custom(
        val value: Expr<Double, Handled>,
    ) : PresentationRadius
}

data class PresentationProperties(
    val enabledIf: Expr<Boolean, Handled>? = null,
    val readOnly: Boolean = false,
)

interface AdaptiveLeadingScope {
    fun leading(body: Layout.() -> Unit)

    fun center(body: Layout.() -> Unit)

    fun suffix(body: Layout.() -> Unit)

    fun padding(value: PresentationInsets)

    fun compactPadding(value: PresentationInsets)

    fun gap(value: Double)

    fun minimumCenterWidth(value: Double)
}

enum class PresentationAlignment { TopStart, TopCenter, TopEnd, CenterStart, Center, CenterEnd, BottomStart, BottomCenter, BottomEnd }

data class PresentationOffset(
    val x: Expr<Double, Handled>,
    val y: Expr<Double, Handled>,
)

interface AnchorPointScope {
    fun groups(vararg ids: String)

    fun alignment(value: PresentationAlignment)

    fun offset(value: PresentationOffset)

    fun visibleIf(condition: Expr<Boolean, Handled>)

    fun exportToParent(value: Boolean = true)
}

sealed interface AnchorSelector {
    data class Local(
        val id: String,
    ) : AnchorSelector

    data class ExportedGroup(
        val id: String,
    ) : AnchorSelector
}

sealed interface ConnectorPath {
    data object Straight : ConnectorPath

    data class Orthogonal(
        val bendPosition: Expr<Double, Handled>,
    ) : ConnectorPath

    data class Curved(
        val sourceControlOffset: PresentationOffset,
        val targetControlOffset: PresentationOffset,
    ) : ConnectorPath
}

enum class ConnectionAxis { Horizontal, Vertical }

sealed interface ConnectorBundlePath {
    data class Orthogonal(
        val axis: ConnectionAxis,
        val bendPosition: Expr<Double, Handled>,
    ) : ConnectorBundlePath

    data object Fan : ConnectorBundlePath
}

sealed interface ConnectorEndpointMarker {
    data class Arrow(
        val size: Expr<Double, Handled>,
    ) : ConnectorEndpointMarker

    data class Circle(
        val diameter: Expr<Double, Handled>,
    ) : ConnectorEndpointMarker
}

data class ConnectorStyle(
    val color: PresentationColor,
    val width: Expr<Double, Handled>,
    val cornerRadius: Expr<Double, Handled>,
    val startMarker: ConnectorEndpointMarker? = null,
    val endMarker: ConnectorEndpointMarker? = null,
)

enum class ConnectionExpressionScope { Layer, Source, Target }

data class ConnectorMarker(
    val node: Layout.() -> Unit,
    val position: Expr<Double, Handled>,
    val alignToPath: Expr<Boolean, Handled>,
    val scope: ConnectionExpressionScope = ConnectionExpressionScope.Layer,
)

interface ConnectionScope {
    fun source(value: AnchorSelector)

    fun target(value: AnchorSelector)

    fun path(value: ConnectorPath)

    fun style(value: ConnectorStyle)

    fun marker(value: ConnectorMarker)

    fun visibleIf(condition: Expr<Boolean, Handled>)
}

interface ConnectionBundleScope {
    fun source(value: AnchorSelector)

    fun targets(value: AnchorSelector)

    fun path(value: ConnectorBundlePath)

    fun trunkStyle(value: ConnectorStyle)

    fun branchStyle(value: ConnectorStyle)

    fun trunkMarker(value: ConnectorMarker)

    fun branchMarker(value: ConnectorMarker)

    fun visibleIf(condition: Expr<Boolean, Handled>)
}

/** Resource identity observed outside editable fields, absent for plain values. */
class PresentationSubjectExpressions(
    val identifier: Expr<com.typewritermc.types.ResourceId, com.typewritermc.expression.MayBeMissing>,
)

/** Read only observations from the surface hosting this presentation. */
interface PresentationContextExpressions {
    val selectionCount: Expr<Int, com.typewritermc.expression.MayBeMissing>

    fun <Value : Any> read(key: PresentationContextKey<Value>): Expr<Value, com.typewritermc.expression.MayBeMissing>
}

internal fun checkPresentationExpression(
    body: ExpressionNode,
    bindings: Map<com.typewritermc.expression.ExpressionBindingId, TypeTemplate>,
    expected: TypeTemplate,
    present: Set<com.typewritermc.expression.ExpressionBindingId>,
    resolve: (TypeUse) -> Resolution<CheckedType>,
    mayBeMissing: Boolean = false,
): List<String> {
    val checker = com.typewritermc.configuration.PortableExpressionChecker(resolve)
    val structural = checker.checkExpressionStructure(body, bindings.keys)
    if (structural.isNotEmpty()) return structural
    // Free type parameters receive exact checking when material is applied to concrete arguments.
    val result = expected.apply(emptyMap()) as? Resolution.Ready ?: return structural
    val referenced = body.referencedBindingIds()
    val applied =
        bindings.filterKeys { it in referenced }.mapValues { (_, template) ->
            (template.apply(emptyMap()) as? Resolution.Ready)?.value
        }
    if (applied.values.any { it == null }) return structural
    return checker.checkExpressionCodes(
        body,
        applied.mapValues { (id, use) -> com.typewritermc.expression.nominalExpressionType(requireNotNull(use), id !in present) },
        com.typewritermc.expression.nominalExpressionType(result.value, mayBeMissing),
    )
}

private fun ExpressionNode.referencedBindingIds(): Set<com.typewritermc.expression.ExpressionBindingId> =
    buildSet {
        fun visit(node: ExpressionNode) {
            if (node is ExpressionNode.InputWrapper) add(com.typewritermc.expression.ExpressionBindingId(node.value.binding.value))
            node.children().forEach { visit(it.node) }
        }
        visit(this@referencedBindingIds)
    }
