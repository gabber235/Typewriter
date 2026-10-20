package com.typewritermc.authoring

import com.typewritermc.discovery.GeneratedContract
import com.typewritermc.dsl.TypewriterDsl
import com.typewritermc.expression.Expr
import com.typewritermc.expression.ExpressionBindingId
import com.typewritermc.expression.Handled
import com.typewritermc.expression.MayBeMissing
import com.typewritermc.expression.color
import com.typewritermc.expression.display
import com.typewritermc.expression.icon
import com.typewritermc.expression.inputExpression
import com.typewritermc.expression.name
import com.typewritermc.presentation.configuration
import com.typewritermc.presentation.declaration
import com.typewritermc.types.Color
import com.typewritermc.types.Icon
import com.typewritermc.types.Resource
import com.typewritermc.types.catalog.PublishedType

/**
 * Name, accent and icon of every resource. Every formula defaults to the subject's type display, so an empty object
 * is a complete declaration and authors override only what differs.
 *
 * Codegen emits the same members per resource type as `XDisplay`, whose scope also reads the subject's fields:
 *
 * ```kotlin
 * object BookNaming : BookDisplay {
 *     override fun BookDisplayScope.label() = title.orIfBlank(type.display.name)
 * }
 * ```
 *
 * Editors evaluate the most specific declared display of a resource's type; [DefaultDisplay] applies to every
 * resource that declares nothing more specific. Formulas read only the subject: catalog assembly rejects a formula
 * that reads a host context input (`display_reads_context`) and two displays for one target
 * (`duplicate_resource_display`).
 */
@GeneratedContract(kind = GeneratedContract.Kind.Display, target = Resource::class)
interface ResourceDisplay {
    fun ResourceDisplayScope.label(): Expr<String, Handled> = defaultLabel()

    fun ResourceDisplayScope.accent(): Expr<Color, Handled> = defaultAccent()

    fun ResourceDisplayScope.icon(): Expr<Icon, Handled> = defaultIcon()
}

/** Applies to every resource that declares nothing more specific. */
object DefaultDisplay : ResourceDisplay

/** What every display formula reads: the subject's published type. Generated scopes add the subject's fields. */
@TypewriterDsl
interface ResourceDisplayScope {
    /** The published type of the subject, whose display holds the defaults of every formula. */
    val type: Expr<PublishedType, Handled>
}

/** The name of the subject's type display, the default label of every resource. */
fun ResourceDisplayScope.defaultLabel(): Expr<String, Handled> = type.display.name

/** The color of the subject's type display, the default accent of every resource. */
fun ResourceDisplayScope.defaultAccent(): Expr<Color, Handled> = type.display.color

/** The icon of the subject's type display, the default icon of every resource. */
fun ResourceDisplayScope.defaultIcon(): Expr<Icon, Handled> = type.display.icon

/**
 * The evaluated display of one resource: what its most specific [ResourceDisplay] formulas produce. Generated resource
 * presentation scopes expose it as `appearance`, so a presentation reuses the declared name, accent and icon instead
 * of repeating the formulas:
 *
 * ```kotlin
 * object BookItemPresentation : BookPresentation {
 *     override fun BookPresentationScope.present() {
 *         text(appearance.label)
 *     }
 * }
 * ```
 *
 * It is a canonical read model, never stored: editors evaluate the display and bind the result under
 * [PresentedResourceAppearance.binding] whenever they present a resource.
 */
data class ResourceAppearance(
    val label: String,
    val accent: Color,
    val icon: Icon,
)

/** The binding through which a resource presentation reads its subject's [ResourceAppearance]. */
@GeneratedSdkApi
object PresentedResourceAppearance {
    val binding: ExpressionBindingId = ExpressionBindingId("presentation.subject.appearance")
}

/** The formulas one display declaration produced, before catalog assembly checks and compiles them. */
class DisplayFormulas(
    val label: Expr<String, Handled>,
    val accent: Expr<Color, Handled>,
    val icon: Expr<Icon, Handled>,
)

/**
 * The subject every display formula reads. It is the configured value binding, which editors bind to the resource
 * being named; its type is the catalog declaration of that resource's configuration, always present for a resource
 * that exists.
 */
@GeneratedSdkApi
object ResourceDisplaySubject : ResourceDisplayScope {
    /** The binding display formulas read the subject through; any other input binding is a context read. */
    val binding: ExpressionBindingId = ExpressionBindingId("configured_value")

    val value: Expr<Any?, MayBeMissing> = inputExpression(binding)

    @Suppress("UNCHECKED_CAST")
    override val type: Expr<PublishedType, Handled> = value.configuration().declaration() as Expr<PublishedType, Handled>
}
