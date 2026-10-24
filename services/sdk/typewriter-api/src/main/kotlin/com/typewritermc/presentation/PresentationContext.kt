package com.typewritermc.presentation

import com.typewritermc.expression.Expr
import com.typewritermc.expression.ExpressionBindingId
import com.typewritermc.expression.MayBeMissing
import com.typewritermc.types.IntegerWidth
import com.typewritermc.types.ResourceId
import com.typewritermc.types.ResourceIdDefinition
import com.typewritermc.types.ScalarKind
import com.typewritermc.types.TypeUse
import skirout.editor.v1.presentation.HostContextInput
import skirout.editor.v1.presentation.PresentationContextSource
import kotlin.reflect.KClass

/**
 * A typed value a presentation reads from its surroundings. Canonical resource facts are queried separately.
 *
 * Expressions read the value through [binding]; [source] tells the editor who supplies it, so a host fills its
 * declared [HostContextInput]s without sharing binding names with Kotlin.
 */
class PresentationContextKey<Value : Any>
    @PublishedApi
    internal constructor(
        val binding: ExpressionBindingId,
        val source: PresentationContextSource,
        val valueType: PresentationContextValueType<Value>,
    )

/** How a context key finds its declared value type. */
sealed interface PresentationContextValueType<Value : Any> {
    /** A closed type registered for [valueClass] in the catalog, such as a resource identity. */
    class Registered<Value : Any>(
        val valueClass: KClass<Value>,
    ) : PresentationContextValueType<Value>

    /** A type the host contract fixes, such as the integer selection count. */
    class Fixed<Value : Any>(
        val use: TypeUse,
    ) : PresentationContextValueType<Value>
}

/** A value the caller of a presentation supplies under [id]; its type must be registered in the catalog. */
inline fun <reified Value : Any> presentationContextKey(id: String): PresentationContextKey<Value> {
    require(id.isNotBlank()) { "Caller input identity must not be blank." }
    return PresentationContextKey(
        ExpressionBindingId("context:$id"),
        PresentationContextSource.CALLER,
        PresentationContextValueType.Registered(Value::class),
    )
}

/** Context values every editor host supplies, whatever surface shows the presentation. */
object EditorContext {
    /** The resource routed in the workspace, missing when nothing is routed. */
    val activeResource: PresentationContextKey<ResourceId> =
        hostContext(HostContextInput.ACTIVE_RESOURCE, ResourceIdDefinition.use)

    /** Number of resources in the current selection, missing outside a selection surface. */
    val selectionCount: PresentationContextKey<Int> =
        hostContext(HostContextInput.SELECTION_COUNT, TypeUse.Scalar(ScalarKind.Integer(IntegerWidth.SIGNED_32)))
}

/**
 * The key for one declared host input. The binding name stays private to Kotlin: the material declares it beside
 * the host input, and the editor reads that declaration.
 */
private fun <Value : Any> hostContext(
    input: HostContextInput,
    type: TypeUse,
): PresentationContextKey<Value> =
    PresentationContextKey(
        ExpressionBindingId("context:host.${input.kind.name.removeSuffix("_CONST").lowercase()}"),
        PresentationContextSource.HostWrapper(input),
        PresentationContextValueType.Fixed(type),
    )

internal class RuntimePresentationContext(
    private val state: PresentationBuildState,
) : PresentationContextExpressions {
    override fun <Value : Any> read(key: PresentationContextKey<Value>): Expr<Value, MayBeMissing> = state.readContext(key)
}
