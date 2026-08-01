package com.typewritermc.engine.paper.entry.entity

import com.typewritermc.core.entries.Ref
import com.typewritermc.engine.paper.entry.entries.EntityActivityEntry
import com.typewritermc.engine.paper.entry.entries.EntityProperty

/**
 * Owns the child activities an activity switches between, one per [Key].
 *
 * Each child is built once by [create] and kept for the lifetime of the holder, so it resumes where
 * it left off. Switching deactivates the outgoing child and activates the incoming one at the
 * position it is handed. Disposing tears down every child that was ever built, not only the one
 * showing.
 *
 * [create] returns null when the child cannot be built yet, for instance because the entry it comes
 * from is not loaded. The entity then stands still and the next activation tries again, so a child
 * that becomes available later still runs.
 *
 * Use [entryActivityHolder] when the children come from entry references. Use this directly when
 * the owner already knows its children, with an enum for the key.
 */
class ChildActivityHolder<Key : Any, Context : ActivityContext>(
    startPosition: PositionProperty,
    private val create: (key: Key, context: Context, position: PositionProperty) -> EntityActivity<in Context>?,
) {
    private val children = mutableMapOf<Key, EntityActivity<in Context>>()
    private var active: EntityActivity<in Context> = IdleActivity(startPosition)
    private var activeKey: Key? = null

    val currentKey: Key?
        get() = activeKey

    val currentPosition: PositionProperty
        get() = active.currentPosition

    val currentProperties: List<EntityProperty>
        get() = active.currentProperties

    /**
     * Activate the child for [key] at [position], even when it is already the active one.
     *
     * Use this when the owner itself is being activated, so a child that was never paused still
     * adopts the position the owner was handed.
     */
    fun activate(key: Key, context: Context, position: PositionProperty) {
        if (activeKey != null && activeKey != key) active.deactivate(context)

        val child: EntityActivity<in Context> = children[key]
            ?: create(key, context, position)?.also { children[key] = it }
            ?: IdleActivity(position)

        activeKey = key
        active = child
        active.activate(context, position)
    }

    /** Activate the child for [key] only when it is not already the active one. */
    fun switchTo(key: Key, context: Context, position: PositionProperty) {
        if (activeKey == key) return
        activate(key, context, position)
    }

    fun tick(context: Context): TickResult = active.tick(context)

    fun deactivate(context: Context) {
        if (activeKey == null) return
        active.deactivate(context)
        activeKey = null
    }

    fun dispose() {
        children.values.forEach { it.dispose() }
        children.clear()
        activeKey = null
    }
}

typealias EntryActivityHolder<Context> = ChildActivityHolder<Ref<out EntityActivityEntry>, Context>

/**
 * A [ChildActivityHolder] whose children come from entry references.
 *
 * A reference that is unset, or that does not resolve, leaves the entity standing still until it
 * does.
 */
fun <Context : ActivityContext> entryActivityHolder(
    startPosition: PositionProperty,
): EntryActivityHolder<Context> = ChildActivityHolder(startPosition) { ref, context, position ->
    ref.get()?.create(context, position)
}
