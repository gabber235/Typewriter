package com.typewritermc.presentation

import com.typewritermc.expression.Expr
import com.typewritermc.expression.Handled
import com.typewritermc.types.CollectionKind
import com.typewritermc.types.PresentationRole
import com.typewritermc.types.TypeTemplate
import com.typewritermc.types.TypeUse
import com.typewritermc.types.catalog.CheckedType
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.catalog.ResolvedRepresentation
import com.typewritermc.types.catalog.apply
import com.typewritermc.types.catalog.resolve

class PresentationBuildBinding(
    val type: CheckedPresentationTemplate,
    val role: PresentationRole,
    internal val resourceTypes: Map<kotlin.reflect.KClass<*>, TypeTemplate.Named> = emptyMap(),
)

class CheckedPresentationTemplate internal constructor(
    val type: TypeTemplate,
    private val fieldResolver: (TypeTemplate, String) -> TypeTemplate?,
    private val nestedResolver: (TypeTemplate, NestedPresentationSlot) -> PresentationNestedTemplate?,
    private val descriptorSelector: (TypeTemplate, List<PresentationDescriptor>) -> PresentationDescriptor?,
) {
    internal fun field(name: String): CheckedPresentationTemplate =
        CheckedPresentationTemplate(
            type = requireNotNull(fieldResolver(type, name)) { "Field $name is not present in $type." },
            fieldResolver = fieldResolver,
            nestedResolver = nestedResolver,
            descriptorSelector = descriptorSelector,
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
                ),
            collectionKind = nested.collectionKind,
        )
    }

    internal fun rebind(type: TypeTemplate): CheckedPresentationTemplate =
        CheckedPresentationTemplate(type, fieldResolver, nestedResolver, descriptorSelector)

    internal fun select(descriptors: List<PresentationDescriptor>): PresentationDescriptor? = descriptorSelector(type, descriptors)
}

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
        type = use.template(),
        fieldResolver = { parent, name ->
            resolve(parent)
                .schema.fields
                .singleOrNull { it.key == name }
                ?.type
                ?.template()
        },
        nestedResolver = { parent, slot ->
            val checked = resolve(parent)
            when (slot) {
                NestedPresentationSlot.Payload, NestedPresentationSlot.Fields -> {
                    PresentationNestedTemplate(parent)
                }

                NestedPresentationSlot.Items -> {
                    val representation = checked.schema.representation as? ResolvedRepresentation.Sequence
                    representation?.let { PresentationNestedTemplate(it.item.template(), it.kind) }
                }

                NestedPresentationSlot.Keys -> {
                    val representation = checked.schema.representation as? ResolvedRepresentation.Mapping
                    representation?.let { PresentationNestedTemplate(it.key.template()) }
                }

                NestedPresentationSlot.Values -> {
                    when (val representation = checked.schema.representation) {
                        is ResolvedRepresentation.Mapping -> PresentationNestedTemplate(representation.value.template())
                        else -> (checked.use as? TypeUse.Nullable)?.let { PresentationNestedTemplate(it.value.template()) }
                    }
                }
            }
        },
        descriptorSelector = { template, descriptors ->
            val actual = resolve(template)
            selectMostSpecificDescriptors(
                descriptors.filter { descriptor -> descriptor.target.matches(actual) },
                actual,
            )
        },
    )
}

internal fun TypeUse.template(): TypeTemplate =
    when (this) {
        is TypeUse.Named -> TypeTemplate.Named(definition, arguments.map(TypeUse::template))
        is TypeUse.Nullable -> TypeTemplate.Nullable(value.template())
        is TypeUse.Scalar -> TypeTemplate.Scalar(kind)
    }

interface Layout :
    PresentationContent,
    PresentationData,
    PresentationInteractions {
    val role: PresentationRole

    val subject: PresentationSubjectExpressions

    val context: PresentationContextExpressions

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

    fun stack(body: Layout.() -> Unit)

    fun section(
        border: PresentationBorder? = null,
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

    fun divider()

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

interface RemainingFields {
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

data class PresentationBorder(
    val width: Double,
    val color: PresentationColor,
)

data class ContainerStyle(
    val background: PresentationColor? = null,
    val foreground: PresentationColor? = null,
    val border: PresentationBorder? = null,
    val radius: PresentationRadius = PresentationRadius.None,
    val transitionMilliseconds: Int = 0,
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
    val identifier: Expr<String, com.typewritermc.expression.MayBeMissing>,
)

/** Read only observations from the surface hosting this presentation. */
class PresentationContextExpressions(
    val selectionCount: Expr<Int, com.typewritermc.expression.MayBeMissing>,
)
