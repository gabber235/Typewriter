package com.typewritermc.presentation

import com.typewritermc.expression.CanonicalReadModels
import com.typewritermc.expression.Expr
import com.typewritermc.expression.Handled
import com.typewritermc.expression.MayBeMissing
import com.typewritermc.expression.MissingPolicy
import com.typewritermc.expression.configuration
import com.typewritermc.expression.declaration
import com.typewritermc.expression.identity
import com.typewritermc.expression.isNull
import com.typewritermc.expression.literal
import com.typewritermc.expression.not
import com.typewritermc.expression.orElse
import com.typewritermc.expression.resourceValue
import com.typewritermc.expression.value
import com.typewritermc.types.Ref
import com.typewritermc.types.RelationshipEndpoint
import com.typewritermc.types.Resource
import com.typewritermc.types.ResourceId
import com.typewritermc.types.namedUse
import com.typewritermc.types.use
import skirout.editor.v1.catalog.PublishedType
import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.type_catalog.NamedTypeTemplate
import skirout.editor.v1.type_catalog.NamedTypeUse
import skirout.editor.v1.type_catalog.TypeSelection
import kotlin.reflect.KClass

internal sealed interface ResourceReadSource {
    data class Identity(
        val expression: Expr<*, *>,
        val expected: NamedTypeUse,
    ) : ResourceReadSource

    data class Reference(
        val expression: Expr<*, *>,
    ) : ResourceReadSource
}

/** A portable read of one resource in the host supplied immutable authoring observation. */
class ResourceExpr<T : Resource> internal constructor(
    internal val source: ResourceReadSource,
) {
    val exists: Expr<Boolean, Handled> get() = configuration.isNull().not().orElse(literal(false))

    /** The identity of the resource: the identity a read by identity names, or the target of a live link. */
    val id: Expr<ResourceId, MayBeMissing>
        get() =
            when (val selected = source) {
                is ResourceReadSource.Identity -> selected.identityExpression()
                is ResourceReadSource.Reference -> selected.linkExpression<T>().identity()
            }

    val value: Expr<T, MayBeMissing>
        get() =
            when (val selected = source) {
                is ResourceReadSource.Identity -> selected.identityExpression().resourceValue(selected.expected.use)
                is ResourceReadSource.Reference -> selected.linkExpression<T>().value()
            }

    val configuration: Expr<TypeSelection, MayBeMissing>
        get() =
            when (val selected = source) {
                is ResourceReadSource.Identity -> selected.identityExpression().configuration()
                is ResourceReadSource.Reference -> selected.linkExpression<T>().identity().configuration()
            }

    val type: Expr<PublishedType, MayBeMissing> get() = configuration.declaration()
}

@Suppress("UNCHECKED_CAST")
private fun ResourceReadSource.Identity.identityExpression(): Expr<ResourceId, MayBeMissing> = expression as Expr<ResourceId, MayBeMissing>

@Suppress("UNCHECKED_CAST")
private fun <T : Resource> ResourceReadSource.Reference.linkExpression(): Expr<Ref<*, T>, MayBeMissing> =
    expression as Expr<Ref<*, T>, MayBeMissing>

/** Constructs reads with a checked expected resource contract. It performs no author process query. */
interface PresentationQueries {
    fun <T : Resource> resource(
        id: Expr<ResourceId, MissingPolicy>,
        resourceClass: KClass<T>,
    ): ResourceExpr<T>
}

inline fun <reified T : Resource> PresentationQueries.resource(id: Expr<ResourceId, MissingPolicy>): ResourceExpr<T> =
    resource(id, T::class)

context(queries: PresentationQueries)
fun <T : Resource> PresentationSubjectExpressions.resource(resourceClass: KClass<T>): ResourceExpr<T> =
    queries.resource(identifier, resourceClass)

context(queries: PresentationQueries)
inline fun <reified T : Resource> PresentationSubjectExpressions.resource(): ResourceExpr<T> = resource(T::class)

val <E : RelationshipEndpoint<*, *>, T : Resource, M : MissingPolicy> Expr<Ref<E, T>, M>.resource: ResourceExpr<T>
    get() = ResourceExpr(ResourceReadSource.Reference(this))

internal class RuntimePresentationQueries(
    private val nativeTypes: Map<KClass<*>, NamedTypeTemplate>,
) : PresentationQueries {
    override fun <T : Resource> resource(
        id: Expr<ResourceId, MissingPolicy>,
        resourceClass: KClass<T>,
    ): ResourceExpr<T> {
        val template =
            requireNotNull(nativeTypes[resourceClass]) { "No unambiguous resource type is registered for ${resourceClass.qualifiedName}." }
        require(template.arguments.isEmpty()) { "Explicit class queries require a closed resource type." }
        return ResourceExpr(ResourceReadSource.Identity(id, template.definition.namedUse()))
    }
}

fun literal(value: TypeSelection): Expr<TypeSelection, Handled> {
    val encoded = CanonicalReadModels.typeSelection.encode(value)
    return Expr { ExpressionNode.LiteralWrapper(encoded) }
}
