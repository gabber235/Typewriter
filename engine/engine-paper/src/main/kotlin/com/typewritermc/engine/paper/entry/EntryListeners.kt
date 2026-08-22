package com.typewritermc.engine.paper.entry

import com.typewritermc.core.entries.Entry
import com.typewritermc.core.entries.Query
import com.typewritermc.core.utils.Reloadable
import com.typewritermc.engine.paper.entry.entries.EventEntry
import com.typewritermc.engine.paper.logger
import com.typewritermc.engine.paper.plugin
import com.typewritermc.engine.paper.utils.logErrorIfNull
import com.typewritermc.loader.EntryListenerInfo
import com.typewritermc.loader.ExtensionLoader
import com.typewritermc.loader.ListenerPriority
import lirand.api.extensions.events.listen
import lirand.api.extensions.events.unregister
import org.bukkit.event.Event
import org.bukkit.event.EventPriority
import org.bukkit.event.Listener
import org.koin.core.component.KoinComponent
import org.koin.core.component.inject
import org.koin.java.KoinJavaComponent.get
import java.lang.invoke.MethodHandle
import java.lang.invoke.MethodHandles
import java.lang.reflect.Method
import java.lang.reflect.Parameter
import kotlin.reflect.KClass
import kotlin.reflect.full.isSubclassOf

/**
 * Manages all the active entry listeners.
 */
class EntryListeners : KoinComponent, Reloadable {
    private val extensionLoader: ExtensionLoader by inject()
    private val listener = object : Listener {}


    /**
     * A listener declaration resolved into something directly callable.
     *
     * Holds everything that does not vary per event, so dispatch only supplies the event and
     * invokes. Isolates its own failures: a listener that throws must not stop the event reaching
     * the others, nor break dispatch for subsequent events.
     */
    private class BoundListener(
        val method: Method,
        private val handle: MethodHandle?,
        private val arguments: List<ArgumentSupplier>,
    ) {
        fun invoke(event: Event) {
            val values = arrayOfNulls<Any>(arguments.size)
            for (index in arguments.indices) values[index] = arguments[index].supply(event)

            try {
                if (handle != null) handle.invokeWithArguments(*values) else method.invoke(null, *values)
            } catch (e: Throwable) {
                logger.severe("Failed to invoke entry listener ${method.name} for event ${event::class.simpleName}")
                e.printStackTrace()
            }
        }
    }

    /** Produces one argument of a bound listener, capturing everything constant up front. */
    private fun interface ArgumentSupplier {
        fun supply(event: Event): Any
    }

    /**
     * Registers all the entry listeners.
     */
    override suspend fun load() {
        val entryListeners = extensionLoader.loadedExtensions.flatMap { it.entryListeners }

        val activeEventEntries = Query.find<EventEntry>().mapTo(mutableSetOf()) { it::class.java.name }

        val activeEntryListeners = entryListeners.filter { it.entryClassName in activeEventEntries }

        val registeredEntryListeners = activeEntryListeners.count { info ->
            val method = info.method
            val eventClass =
                findEventFromMethod(method).logErrorIfNull("Could not find bukkit event class for ${method.name}")
                    ?: return@count false

            val bound = bind(info, method) ?: return@count false

            listener.listen(plugin, eventClass, info.priority.toBukkitPriority(), info.ignoreCancelled) { event ->
                bound.invoke(event)
            }
            true
        }

        logger.info("Loaded $registeredEntryListeners entry listeners")
    }

    /**
     * Resolves a listener declaration into something callable, or null when it cannot be resolved.
     *
     * Reporting an unresolvable listener here, at load, is deliberate: an unsupported parameter or
     * an unloadable entry class is a packaging mistake, and it should surface once at startup with
     * the offending method named instead of throwing on every event for the life of the server.
     */
    private fun bind(info: EntryListenerInfo, method: Method): BoundListener? {
        val arguments = bindArguments(info, method) ?: return null

        return BoundListener(method, methodHandleOf(method), arguments)
    }

    private fun bindArguments(info: EntryListenerInfo, method: Method): List<ArgumentSupplier>? {
        val generators =
            try {
                ParameterGenerator.getGenerators(method.parameters)
            } catch (e: IllegalArgumentException) {
                logger.severe("Could not bind entry listener ${method.name}: ${e.message}")
                return null
            }

        return generators.map { generator ->
            when (generator) {
                ParameterGenerator.EventParameterGenerator -> ArgumentSupplier { event -> event }
                ParameterGenerator.QueryParameterGenerator -> {
                    val query =
                        try {
                            ParameterGenerator.QueryParameterGenerator.query(info)
                        } catch (e: Exception) {
                            logger.severe(
                                "Could not resolve the query of entry listener ${method.name}: ${e.message}",
                            )
                            return null
                        }
                    ArgumentSupplier { query }
                }
            }
        }
    }

    /**
     * A handle bound to [method], or null when the extension class loader will not expose it.
     *
     * `unreflect` checks access against this class rather than against the eventual caller, and
     * entry listeners live in extension jars with their own class loader, where the declaring class
     * is often not public to the engine and `@EntryListener` never required the method to be
     * public. Suppressing the check is therefore what lets a handle exist at all — the same
     * suppression `Method.invoke` performs internally on every call, done once here instead, on a
     * `Method` the engine obtained itself and keeps for the lifetime of the binding.
     *
     * A null result is not an error: dispatch falls back to `Method.invoke`, which only costs the
     * per-call checks the handle avoids.
     */
    private fun methodHandleOf(method: Method): MethodHandle? =
        try {
            method.isAccessible = true
            MethodHandles.lookup().unreflect(method)
        } catch (e: Throwable) {
            logger.warning("MethodHandle unavailable for entry listener ${method.name}; falling back to reflection")
            null
        }

    private fun findEventFromMethod(method: Method): KClass<out Event>? {
        @Suppress("UNCHECKED_CAST")
        return method.parameters.firstNotNullOfOrNull { it.type.kotlin.takeIf { type -> type.isSubclassOf(Event::class) } } as? KClass<out Event>
    }

    private val EntryListenerInfo.method: Method
        get() {
            val clazz = extensionLoader.loadClass(className)
            val arguments = arguments.map { extensionLoader.loadClass(it) }.toTypedArray()
            return clazz.getDeclaredMethod(methodName, *arguments)
        }

    private fun ListenerPriority.toBukkitPriority(): EventPriority {
        return when (this) {
            ListenerPriority.HIGHEST -> EventPriority.HIGHEST
            ListenerPriority.HIGH -> EventPriority.HIGH
            ListenerPriority.NORMAL -> EventPriority.NORMAL
            ListenerPriority.LOW -> EventPriority.LOW
            ListenerPriority.LOWEST -> EventPriority.LOWEST
            ListenerPriority.MONITOR -> EventPriority.MONITOR
        }
    }

    /**
     * Unregisters all the entry listeners.
     */
    override suspend fun unload() {
        listener.unregister()
    }
}

sealed interface ParameterGenerator {
    fun isApplicable(parameter: Parameter): Boolean
    fun generate(event: Event, entryListenerInfo: EntryListenerInfo): Any

    data object EventParameterGenerator : ParameterGenerator {
        override fun isApplicable(parameter: Parameter): Boolean {
            // It and all superclasses must be Event
            return Event::class.java.isAssignableFrom(parameter.type)
        }

        override fun generate(event: Event, entryListenerInfo: EntryListenerInfo): Any = event
    }

    data object QueryParameterGenerator : ParameterGenerator {
        override fun isApplicable(parameter: Parameter): Boolean {
            // It can only be Query
            return parameter.type.isAssignableFrom(Query::class.java)
        }

        override fun generate(event: Event, entryListenerInfo: EntryListenerInfo): Any = query(entryListenerInfo)

        /**
         * The query a listener receives, determined solely by [entryListenerInfo] and never by the
         * event, so a caller may resolve it once and reuse it for every dispatch.
         *
         * @throws IllegalArgumentException when the declared entry class is not an [Entry].
         */
        fun query(entryListenerInfo: EntryListenerInfo): Query<out Entry> {
            val extensionLoader = get<ExtensionLoader>(ExtensionLoader::class.java)
            val entryClass = extensionLoader.loadClass(entryListenerInfo.entryClassName)
            if (!Entry::class.java.isAssignableFrom(entryClass)) {
                throw IllegalArgumentException("The entry class ${entryClass.name} is not a valid Entry")
            }
            @Suppress("UNCHECKED_CAST")
            val klass = entryClass.kotlin as KClass<out Entry>
            return Query(klass)
        }
    }

    companion object {
        private val generators = listOf(EventParameterGenerator, QueryParameterGenerator)

        private fun getGenerator(parameter: Parameter): ParameterGenerator? {
            return generators.firstOrNull { it.isApplicable(parameter) }
        }

        /**
         * Creates a list of ParameterGenerators for the given method.
         * @throws IllegalArgumentException if the parameter is not applicable to any generator
         */
        @Throws(IllegalArgumentException::class)
        fun getGenerators(parameters: Array<Parameter>): List<ParameterGenerator> {
            return parameters.map { parameter ->
                getGenerator(parameter)
                    ?: throw IllegalArgumentException("There is no way to create a parameter for ${parameter.name} (${parameter.type}) in ${parameter.declaringExecutable}")
            }
        }
    }
}
