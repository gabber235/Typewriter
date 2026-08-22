package com.typewritermc.core.entries

import com.google.gson.Gson
import com.google.gson.JsonObject
import com.google.gson.JsonParser
import com.typewritermc.core.books.pages.PageType
import com.typewritermc.core.utils.Reloadable
import com.typewritermc.loader.ExtensionLoader
import org.koin.core.component.KoinComponent
import org.koin.core.component.inject
import org.koin.core.qualifier.named
import java.io.File
import java.util.logging.Logger
import kotlin.reflect.KClass
import kotlin.reflect.full.allSuperclasses
import kotlin.reflect.full.findAnnotations

class Library : KoinComponent, Reloadable {
    internal var pages: List<Page> = emptyList()
        private set
    internal var entries: List<Entry> = emptyList()
        private set

    internal var entriesById: Map<String, Entry> = emptyMap()
        private set

    /**
     * Entries grouped by every type they are assignable to, their own class included.
     *
     * Derived from [entries] and owned by this library: rebuilt on every load, never mutated
     * afterwards, and published by a single volatile write so a reader sees either the whole
     * previous catalogue or the whole new one. Values keep catalogue order. An absent key means no
     * loaded entry answers to that type.
     */
    @Volatile
    internal var entriesByType: Map<KClass<*>, List<Entry>> = emptyMap()
        private set

    internal var entryPriority = emptyMap<Ref<out Entry>, Int>()
        private set

    private val logger: Logger by inject()
    private val extensionLoader by inject<ExtensionLoader>()
    private val directory by inject<File>(named("baseDir"))
    private val gson by inject<Gson>(named("dataSerializer"))

    override suspend fun load() {
        pages = directory.resolve("pages").listFiles().orEmpty()
            .filter { it.isFile && it.canRead() && it.name.endsWith(".json") }
            .map {
                val json = JsonParser.parseString(it.readText())
                if (!json.isJsonObject) throw IllegalArgumentException("Page ${it.name} does not contain a valid json object")
                val obj = json.asJsonObject
                obj.addProperty("id", it.name.removeSuffix(".json"))
                obj
            }
            .map { parsePage(it) }

        entries = pages.flatMap { it.entries }
        entriesById = entries.associateBy { it.id }
        entriesByType = entries.groupByType()
        entryPriority = pages.flatMap { page ->
            page.entries.map { entry ->
                if (entry !is PriorityEntry) return@map entry.ref() to page.priority
                entry.ref() to entry.priorityOverride.orElse(page.priority)
            }
        }.toMap()

        logger.info("Loaded ${entries.size} entries from ${pages.size} pages.")
    }

    override suspend fun unload() {
        pages = emptyList()
        entries = emptyList()
        entriesById = emptyMap()
        entriesByType = emptyMap()
        entryPriority = emptyMap()
    }

    private fun parsePage(obj: JsonObject): Page {
        val id = obj.getAsJsonPrimitive("id")?.asString ?: throw IllegalArgumentException("Page does not have an id")
        val name =
            obj.getAsJsonPrimitive("name")?.asString ?: throw IllegalArgumentException("Page $id does not have a name")
        val type = obj.getAsJsonPrimitive("type")?.asString
            ?: throw IllegalArgumentException("Page $name ($id) does not have a type ")
        val pageType =
            PageType.fromId(type) ?: throw IllegalArgumentException("Page $name ($id) has an invalid type $type")
        val priority = obj.getAsJsonPrimitive("priority")?.asInt ?: 0

        val entries = obj.getAsJsonArray("entries").mapNotNull { parseEntry(it.asJsonObject, name) }

        return Page(id, name, entries, pageType, priority)
    }

    private fun parseEntry(obj: JsonObject, pageName: String): Entry? {
        val id = obj.getAsJsonPrimitive("id")?.asString.logErrorIfNull("Entry does not have an id") ?: return null
        // TODO: Remove type as valid field
        val blueprintId = obj.getAsJsonPrimitive("blueprintId")?.asString ?:
            obj.getAsJsonPrimitive("type")?.asString.logErrorIfNull("Entry '$id' does not have a blueprintId or type") ?: return null
        val clazz = extensionLoader.entryClass(blueprintId)
            .logErrorIfNull("Could not find entry class for '$id' on page '${pageName}' with type '$blueprintId' in any extension.") ?: return null
        try {
            val entry = gson.fromJson<Entry>(obj, clazz)
            entryValidation(entry, pageName, blueprintId)
            return entry
        } catch (e: Exception) {
            logger.warning("Failed to parse entry '$id' with blueprintId '$blueprintId' on page '${pageName}': ${e.message}")
            return null
        }
    }

    private fun entryValidation(entry: Entry, pageName: String, blueprintId: String) {
        deprecatedEntryValidation(entry, pageName, blueprintId)
    }

    private fun deprecatedEntryValidation(entry: Entry, pageName: String, blueprintId: String) {
        // If the entry has the @Deprecated annotation, we want to warn the user about it.
        val deprecated = entry::class.findAnnotations<Deprecated>().firstOrNull() ?: return
        logger.warning("Entry '${entry.id}' on page '${pageName}' with blueprintId '$blueprintId' is deprecated and will be removed in the future. Reason: ${deprecated.message}")
    }

    private fun <T : Any> T?.logErrorIfNull(message: String): T? {
        if (this == null) {
            logger.severe(message)
        }
        return this
    }
}

/**
 * Groups the entries under every type each one is assignable to, keeping their order.
 *
 * Indexing supertypes and interfaces, and not only the concrete class, is what makes a query for an
 * interface or for [Entry] itself return the entries implementing it.
 */
internal fun List<Entry>.groupByType(): Map<KClass<*>, List<Entry>> {
    val assignableTypes = distinctBy { it::class }.associate { it::class to it::class.assignableTypes }

    return flatMap { entry -> assignableTypes.getValue(entry::class).map { type -> type to entry } }
        .groupBy({ (type, _) -> type }, { (_, entry) -> entry })
}

private val KClass<*>.assignableTypes: List<KClass<*>> get() = allSuperclasses + this

val Entry.priority: Int get() = ref().priority
val Ref<out Entry>.priority: Int
    get() = org.koin.java.KoinJavaComponent.get<Library>(Library::class.java).entryPriority[this] ?: 0
