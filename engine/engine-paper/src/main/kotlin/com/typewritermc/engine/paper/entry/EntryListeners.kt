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


    private fun onEvent(event: Event, info: EntryListenerInfo, generators: List<ParameterGenerator>, method: Method) {
        val parameters = generators.map { it.generate(event, info) }
        try {
            method.invoke(null, *parameters.toTypedArray())
        } catch (e: Exception) {
            logger.severe("Failed to invoke entry listener ${method.name} for event ${event::class.simpleName}")
            e.printStackTrace()
        }
    }

    /**
     * Registers all the entry listeners.
     */
    override suspend fun load() {
        val entryListeners = extensionLoader.extensions.flatMap { it.entryListeners }

        val activeEventEntries = Query.find<EventEntry>().map { it::class }.distinct()

        val activeEntryListeners = entryListeners.filter {
            activeEventEntries.any { activeEventEntry -> it.entryClassName == activeEventEntry.qualifiedName }
        }
        activeEntryListeners.forEach {
            val method = it.method
            val eventClass =
                findEventFromMethod(method).logErrorIfNull("Could not find bukkit event class for ${method.name}")
                    ?: return@forEach

            listener.listen(plugin, eventClass, it.priority.toBukkitPriority(), it.ignoreCancelled) { event ->
                onEvent(event, it, ParameterGenerator.getGenerators(method.parameters), method)
            }
        }

        logger.info("Loaded ${activeEntryListeners.size} entry listeners")
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

        override fun generate(event: Event, entryListenerInfo: EntryListenerInfo): Any {
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
