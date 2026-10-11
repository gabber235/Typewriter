package com.typewritermc.expression

import com.typewritermc.discovery.checkedGeneratedScope
import kotlin.reflect.KClass

/** Constructs a compiler checked expression receiver around one portable value expression. */
interface ExpressionFactory<Scope : Any> {
    val scope: KClass<Scope>

    fun create(value: Expr<*, out MissingPolicy>): Scope
}

/** Stores generated expression declarations for one presentation runtime. */
internal class ExpressionFactories {
    private val factories = mutableMapOf<KClass<*>, ExpressionFactory<*>>()

    fun register(factory: ExpressionFactory<*>) {
        synchronized(factories) {
            val previous = factories[factory.scope]
            require(previous == null || previous === factory) {
                "One expression scope cannot have conflicting factory declarations in one presentation runtime."
            }
            factories[factory.scope] = factory
        }
    }

    fun <Scope : Any> create(
        scope: KClass<Scope>,
        value: Expr<*, out MissingPolicy>,
    ): Scope {
        val factory =
            synchronized(factories) {
                requireNotNull(factories[scope]) { "No generated expression factory is registered for ${scope.qualifiedName}." }
            }
        return checkedGeneratedScope(scope, factory.create(value))
    }
}
