package com.typewritermc.engine.paper.utils

import com.typewritermc.engine.paper.events.TypewriterUnloadEvent
import com.typewritermc.engine.paper.plugin
import lirand.api.extensions.events.listen
import kotlin.properties.ReadOnlyProperty
import kotlin.reflect.KProperty

// TODO: After v1.0 this won't work anymore because the engine will also be loaded in and out.
fun <T> reloadable(loader: () -> T) = Reloadable(loader)
class Reloadable<T>(private val loader: () -> T) : ReadOnlyProperty<Any?, T> {
    private var value: T? = null

    init {
        plugin.listen<TypewriterUnloadEvent> { reload() }
    }

    fun get(): T {
        val value = this.value
        if (value == null) {
            val createdValue = loader()
            this.value = createdValue
            return createdValue
        }
        return value
    }

    private fun reload() {
        value = null
    }

    override fun getValue(thisRef: Any?, property: KProperty<*>): T {
        return get()
    }
}