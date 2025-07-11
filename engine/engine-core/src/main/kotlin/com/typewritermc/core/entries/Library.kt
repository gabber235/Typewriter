package com.typewritermc.core.entries

import com.typewritermc.core.books.pages.PageType
import com.typewritermc.core.utils.Reloadable
import com.typewritermc.loader.ExtensionLoader
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.int
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.serializer
import org.koin.core.component.KoinComponent
import org.koin.core.component.inject
import org.koin.core.qualifier.named
import java.io.File
import java.util.logging.Logger
import kotlin.reflect.full.findAnnotations
import kotlin.reflect.full.hasAnnotation

class Library : KoinComponent, Reloadable {
    internal var pages: List<Page> = emptyList()
        private set
    internal var entries: List<Entry> = emptyList()
        private set

    internal var entriesById: Map<String, Entry> = emptyMap()
        private set

    internal var entryPriority = emptyMap<Ref<out Entry>, Int>()
        private set

    private val logger: Logger by inject()
    private val extensionLoader by inject<ExtensionLoader>()
    private val directory by inject<File>(named("baseDir"))
    private val jsonFormat by inject<Json>(named("dataSerializer"))

    override suspend fun load() {
        pages = directory.resolve("pages").listFiles().orEmpty()
            .filter { it.isFile && it.canRead() && it.name.endsWith(".json") }
            .map {
                val json = jsonFormat.parseToJsonElement(it.readText())
                if (json !is JsonObject) throw IllegalArgumentException("Page ${it.name} does not contain a valid json object")
                JsonObject(json.toMutableMap().apply {
                    put("id", JsonPrimitive(it.name.removeSuffix(".json")))
                })
            }
            .map { parsePage(it) }

        entries = pages.flatMap { it.entries }
        entriesById = entries.associateBy { it.id }
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
        entryPriority = emptyMap()
    }

    private fun parsePage(obj: JsonObject): Page {
        val id = obj["id"]?.jsonPrimitive?.toString()
            ?: throw IllegalArgumentException("Page does not have an id")
        val name = obj["name"]?.jsonPrimitive?.toString()
            ?: throw IllegalArgumentException("Page $id does not have a name")
        val type = obj["type"]?.jsonPrimitive?.toString()
            ?: throw IllegalArgumentException("Page $name ($id) does not have a type ")
        val pageType =
            PageType.fromId(type) ?: throw IllegalArgumentException("Page $name ($id) has an invalid type $type")
        val priority = obj["priority"]?.jsonPrimitive?.int ?: 0

        val entries = obj["entries"]!!.jsonArray.mapNotNull { parseEntry(it.jsonObject, name) }

        return Page(id, name, entries, pageType, priority)
    }

    private fun parseEntry(obj: JsonObject, pageName: String): Entry? {
        val id = obj["id"]?.jsonPrimitive?.toString().logErrorIfNull("Entry does not have an id") ?: return null
        // TODO: Remove type as valid field
        val blueprintId = obj["blueprintId"]?.jsonPrimitive?.toString()
            ?: obj["type"]?.jsonPrimitive?.toString().logErrorIfNull("Entry '$id' does not have a blueprintId or type")
            ?: return null
        val clazz = extensionLoader.entryClass(blueprintId)
            .logErrorIfNull("Could not find entry class for '$id' on page '${pageName}' with type '$blueprintId' in any extension.") ?: return null
        // require(clazz.kotlin.hasAnnotation<Serializable>()) { "Entry class '${clazz.name}' is not annotated with @Serializable." }
        try {
            // Might work.
            val serial = jsonFormat.serializersModule.serializer(clazz)
            val entry = jsonFormat.decodeFromJsonElement(serial, obj) as Entry
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

val Entry.priority: Int get() = ref().priority
val Ref<out Entry>.priority: Int
    get() = org.koin.java.KoinJavaComponent.get<Library>(Library::class.java).entryPriority[this] ?: 0