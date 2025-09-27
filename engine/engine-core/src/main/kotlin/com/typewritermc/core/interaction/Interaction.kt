package com.typewritermc.core.interaction

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Entry
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.entries.ref
import com.typewritermc.core.extension.annotations.AlgebraicTypeInfo
import java.time.Duration
import kotlin.random.Random
import kotlin.reflect.KClass
import kotlin.reflect.safeCast

interface Interaction {
    val priority: Int
    val context: InteractionContext
    suspend fun initialize(): Result<Unit>
    suspend fun tick(deltaTime: Duration)
    suspend fun teardown()
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

/**
 * A key for storing a random seed in the interaction context.
 *
 * This random seed can be used when random values need to be generated consistently across an interaction.
 */
object RandomSeedContextKey : GlobalContextKey<Long>(Long::class) {
    override fun toString(): String = "RandomSeedContextKey"
}

fun InteractionContext?.randomSeed(): Long {
    if (this == null) return Random.nextLong()
    return this[RandomSeedContextKey] ?: Random.nextLong()
}

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
        // Always add a random seed to the context
        data.putIfAbsent(RandomSeedContextKey, Random.nextLong())
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
    private val entryContextKeys = mutableMapOf<EntryContextKey, Any>()
    private val contextKeys = mutableMapOf<InteractionContextKey<*>, Any>()

    fun <T : Any> put(key: EntryContextKey, value: T) {
        entryContextKeys[key] = value
    }

    fun <T : Any> put(key: InteractionContextKey<T>, value: T) {
        contextKeys[key] = value
    }

    infix fun <T : Any> EntryContextKey.withValue(value: T) {
        put(this, value)
    }

    infix fun <T : Any> InteractionContextKey<T>.withValue(value: T) {
        put(this, value)
    }

    operator fun <T : Any> EntryContextKey.plusAssign(value: T) {
        put(this, value)
    }

    operator fun <T : Any> InteractionContextKey<T>.plusAssign(value: T) {
        put(this, value)
    }

    fun build(): InteractionContext {
        return InteractionContext(entryContextKeys.mapKeys { (key, _) -> EntryInteractionContextKey<Any>(ref, key) })
    }
}

open class ContextModifier(
    private val initialContext: InteractionContext,
) {
    private val _additionContext: MutableMap<InteractionContextKey<*>, Any> = mutableMapOf()
    var context: InteractionContext = initialContext
        private set

    val additionContext: InteractionContext get() = InteractionContext(_additionContext)

    private fun invalidateContextCache() {
        context = initialContext.combine(InteractionContext(_additionContext))
    }

    operator fun <T : Any> set(key: InteractionContextKey<T>, value: T) {
        _additionContext[key] = value
        invalidateContextCache()
    }

    operator fun <T : Any> set(ref: Ref<out Entry>, key: EntryContextKey, value: T) {
        this[EntryInteractionContextKey<T>(ref, key)] = value
    }

    operator fun <T : Any> set(entry: Entry, key: EntryContextKey, value: T) = set(entry.ref(), key, value)

    operator fun <T : Any> InteractionContext.set(key: InteractionContextKey<T>, value: T) {
        _additionContext[key] = value
        invalidateContextCache()
    }

    operator fun <T : Any> InteractionContext.set(ref: Ref<out Entry>, key: EntryContextKey, value: T) {
        this[EntryInteractionContextKey<T>(ref, key)] = value
    }

    operator fun <T : Any> InteractionContext.set(entry: Entry, key: EntryContextKey, value: T) =
        set(entry.ref(), key, value)

    fun clear() {
        _additionContext.clear()
        invalidateContextCache()
    }

    fun <T : Any> clear(key: InteractionContextKey<T>) {
        _additionContext.remove(key)
        invalidateContextCache()
    }

    fun <T : Any> clear(ref: Ref<out Entry>, key: EntryContextKey) = this.clear(EntryInteractionContextKey<T>(ref, key))

    fun <T : Any> clear(entry: Entry, key: EntryContextKey) = clear<T>(entry.ref(), key)

    fun <T : Any> InteractionContext.clear(key: InteractionContextKey<T>) = this@ContextModifier.clear<T>(key)

    fun <T : Any> InteractionContext.clear(ref: Ref<out Entry>, key: EntryContextKey) =
        this@ContextModifier.clear<T>(ref, key)

    fun <T : Any> InteractionContext.clear(entry: Entry, key: EntryContextKey) =
        this@ContextModifier.clear<T>(entry, key)
}