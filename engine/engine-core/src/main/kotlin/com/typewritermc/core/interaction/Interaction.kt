package com.typewritermc.core.interaction

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Entry
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.entries.ref
import com.typewritermc.core.extension.annotations.AlgebraicTypeInfo
import java.time.Duration
import kotlin.reflect.KClass
import kotlin.reflect.safeCast

interface Interaction {
    val priority: Int
    val context: InteractionContext
    suspend fun initialize(): Result<Unit>
    suspend fun tick(deltaTime: Duration)
    suspend fun teardown(force: Boolean = false)
}

typealias ContextBuilder = InteractionContextBuilder.() -> Unit

fun context(builder: ContextBuilder = {}): InteractionContext {
    return InteractionContextBuilder().apply(builder).build()
}

class InteractionContext(
    private val data: Map<InteractionContextKey<*>, Any>
) {
    operator fun <T : Any> get(key: InteractionContextKey<T>): T? {
        return key.klass.safeCast(data[key])
    }

    operator fun <T : Any> get(ref: Ref<out Entry>, key: EntryContextKey): T? {
        return get(EntryInteractionContextKey(ref, key))
    }

    operator fun <T : Any> get(entry: Entry, key: EntryContextKey): T? = get(entry.ref(), key)

    fun combine(context: InteractionContext): InteractionContext {
        return InteractionContext(data + context.data)
    }

    fun expand(builder: ContextBuilder): InteractionContext {
        return combine(context(builder))
    }
}

sealed interface InteractionContextKey<T : Any> {
    val klass: KClass<T>

    companion object {
        val Empty = EntryInteractionContextKey<Any>()
    }
}

@AlgebraicTypeInfo("entry", Colors.BLUE, "mingcute:unlink-fill")
data class EntryInteractionContextKey<T : Any>(
    val ref: Ref<out Entry> = emptyRef(),
    val key: EntryContextKey = EntryContextKey.Empty,
) : InteractionContextKey<T> {
    override val klass: KClass<T> get() = key.klass as KClass<T>
}

interface EntryContextKey {
    val klass: KClass<*>

    object Empty : EntryContextKey {
        override val klass: KClass<*> = Unit::class
    }
}

@AlgebraicTypeInfo("global", Colors.RED, "mdi:application-variable")
open class GlobalContextKey<T : Any>(override val klass: KClass<T>) : InteractionContextKey<T>

class InteractionContextBuilder {
    private val data = mutableMapOf<InteractionContextKey<*>, Any>()

    fun <T : Any> put(key: InteractionContextKey<T>, value: T) {
        data[key] = value
    }

    infix fun <T : Any> InteractionContextKey<T>.withValue(value: T) {
        put(this, value)
    }

    operator fun <T : Any> Ref<out Entry>.set(key: EntryContextKey, value: T) {
        put(EntryInteractionContextKey<T>(this, key), value)
    }

    operator fun <T : Any> Entry.set(key: EntryContextKey, value: T) = ref().set(key, value)

    fun build(): InteractionContext {
        return InteractionContext(data)
    }
}

typealias EntryContextBuilder<E> = EntryInteractionContextBuilder<E>.() -> Unit

@JvmName("withContextRefs")
inline fun <reified E : Entry> List<Ref<E>>.withContext(builder: EntryContextBuilder<E>): InteractionContext {
    return map { it.withContext(builder) }.fold(context()) { a, b ->
        a.combine(b)
    }
}

@JvmName("withContextEntries")
inline fun <reified E : Entry> List<E>.withContext(builder: EntryContextBuilder<E>): InteractionContext {
    return map { it.withContext(builder) }.fold(context()) { a, b ->
        a.combine(b)
    }
}

inline fun <reified E : Entry> Ref<E>.withContext(builder: EntryContextBuilder<E>): InteractionContext {
    val entry = get() ?: return context()
    return EntryInteractionContextBuilder(this, entry).apply(builder).build()
}

inline fun <reified E : Entry> E.withContext(builder: EntryContextBuilder<E>): InteractionContext {
    return EntryInteractionContextBuilder(ref(), this).apply(builder).build()
}

class EntryInteractionContextBuilder<E : Entry>(val ref: Ref<E>, val entry: E) {
    private val data = mutableMapOf<EntryContextKey, Any>()

    fun <T : Any> put(key: EntryContextKey, value: T) {
        data[key] = value
    }

    infix fun <T : Any> EntryContextKey.withValue(value: T) {
        put(this, value)
    }

    operator fun <T : Any> EntryContextKey.plusAssign(value: T) {
        put(this, value)
    }

    fun build(): InteractionContext {
        return InteractionContext(data.mapKeys { (key, _) -> EntryInteractionContextKey<Any>(ref, key) })
    }
}

open class ContextModifier(
    private val initialContext: InteractionContext,
) {
    private val additionContext: MutableMap<InteractionContextKey<*>, Any> = mutableMapOf()
    var context: InteractionContext = initialContext
        private set

    operator fun <T : Any> set(key: InteractionContextKey<T>, value: T) {
        additionContext[key] = value
        context = initialContext.combine(InteractionContext(additionContext))
    }

    operator fun <T : Any> set(ref: Ref<out Entry>, key: EntryContextKey, value: T) {
        this[EntryInteractionContextKey<T>(ref, key)] = value
    }

    operator fun <T : Any> set(entry: Entry, key: EntryContextKey, value: T) = set(entry.ref(), key, value)

    operator fun <T : Any> InteractionContext.set(key: InteractionContextKey<T>, value: T) {
        additionContext[key] = value
        context = initialContext.combine(InteractionContext(additionContext))
    }

    operator fun <T : Any> InteractionContext.set(ref: Ref<out Entry>, key: EntryContextKey, value: T) {
        this[EntryInteractionContextKey<T>(ref, key)] = value
    }

    operator fun <T : Any> InteractionContext.set(entry: Entry, key: EntryContextKey, value: T) =
        set(entry.ref(), key, value)
}