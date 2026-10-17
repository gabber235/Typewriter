package com.typewritermc.presentation

import com.typewritermc.authoring.TypeSelection
import com.typewritermc.expression.CanonicalQueryOperation
import com.typewritermc.expression.CanonicalReadModels
import com.typewritermc.expression.Expr
import com.typewritermc.expression.Handled
import com.typewritermc.expression.MayBeMissing
import com.typewritermc.expression.MissingPolicy
import com.typewritermc.expression.OperationId
import com.typewritermc.expression.isNull
import com.typewritermc.expression.literal
import com.typewritermc.expression.not
import com.typewritermc.expression.orElse
import com.typewritermc.types.DataValue
import com.typewritermc.types.Ref
import com.typewritermc.types.RelationshipEndpoint
import com.typewritermc.types.Resource
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeTemplate
import com.typewritermc.types.TypeUse
import com.typewritermc.types.catalog.PublishedType
import kotlin.reflect.KClass

internal sealed interface ResourceReadSource {
    data class Identity(
        val expression: ExpressionNode,
        val expected: TypeUse.Named,
    ) : ResourceReadSource

    data class Reference(
        val expression: ExpressionNode,
    ) : ResourceReadSource
}

/** A portable read of one resource in the host supplied immutable authoring observation. */
class ResourceExpr<T : Resource> internal constructor(
    internal val source: ResourceReadSource,
) {
    val exists: Expr<Boolean, Handled> get() = configuration.isNull().not().orElse(literal(false))
    val id: Expr<ResourceId, MayBeMissing> get() = query(CanonicalQueryOperation.ResourceIdentity)
    val value: Expr<T, MayBeMissing> get() = query(CanonicalQueryOperation.ResourceValue)
    val configuration: Expr<TypeSelection, MayBeMissing> get() = query(CanonicalQueryOperation.ResourceConfiguration)
    val type: Expr<PublishedType, MayBeMissing> get() = configuration.declaration()

    private fun <V> query(operation: CanonicalQueryOperation): Expr<V, MayBeMissing> {
        val arguments =
            when (val selected = source) {
                is ResourceReadSource.Identity -> {
                    listOf(
                        selected.expression,
                        ExpressionNode.Literal(CanonicalReadModels.typeUse.encode(selected.expected)),
                    )
                }

                is ResourceReadSource.Reference -> {
                    listOf(selected.expression)
                }
            }
        return Expr(ExpressionNode.Call(OperationId(operation.id), arguments))
    }
}

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
    get() = ResourceExpr(ResourceReadSource.Reference(node))

internal class RuntimePresentationQueries(
    private val nativeTypes: Map<KClass<*>, TypeTemplate.Named>,
) : PresentationQueries {
    override fun <T : Resource> resource(
        id: Expr<ResourceId, MissingPolicy>,
        resourceClass: KClass<T>,
    ): ResourceExpr<T> {
        val template =
            requireNotNull(nativeTypes[resourceClass]) { "No unambiguous resource type is registered for ${resourceClass.qualifiedName}." }
        require(template.arguments.isEmpty()) { "Explicit class queries require a closed resource type." }
        return ResourceExpr(ResourceReadSource.Identity(id.node, TypeUse.Named(template.definition)))
    }
}

fun literal(value: TypeSelection): Expr<TypeSelection, Handled> =
    Expr(ExpressionNode.Literal(CanonicalReadModels.typeSelection.encode(value)))

fun <M : MissingPolicy> Expr<TypeSelection, M>.declaration(): Expr<PublishedType, MayBeMissing> =
    Expr(ExpressionNode.Call(OperationId(CanonicalQueryOperation.CatalogDeclaration.id), listOf(node)))

fun <M : MissingPolicy> Expr<*, M>.configuration(): Expr<TypeSelection, MayBeMissing> =
    Expr(ExpressionNode.Call(OperationId(CanonicalQueryOperation.ValueConfiguration.id), listOf(node)))
