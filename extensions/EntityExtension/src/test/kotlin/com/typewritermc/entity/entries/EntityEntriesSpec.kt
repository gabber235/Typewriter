package com.typewritermc.entity.entries

import com.github.retrooper.packetevents.protocol.entity.type.EntityType
import com.github.retrooper.packetevents.protocol.entity.type.EntityTypes
import com.google.gson.JsonObject
import com.google.gson.JsonParser
import com.typewritermc.entity.entries.entity.custom.state
import io.kotest.assertions.withClue
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.collections.shouldBeEmpty
import java.io.File

/**
 * Problems that were in the extension before these checks existed. Each is listed under "Known issues" in the
 * extension's AGENTS.md. Fixing one fails the check that lists it, as a reminder to take it off its list.
 */
private val knownDuplicateIds = setOf("marker_data", "small_data")

private val reservedTags = setOf("mob_data")

private val placeholderTags = setOf(
    "allay_data", "block_display_data", "breeze_data", "camel_data", "cave_spider_data", "chested_horse_data",
    "chicken_data", "cow_data", "creeper_data", "donkey_data", "elder_guardian_data", "goat_data",
    "interaction_data", "piglin_dancing_data", "polar_bear_data", "skeleton_data", "sniffer_data", "spider_data",
    "turtle_data",
)

private val unreachableData = setOf("chested_horse_chest_meta", "puff_state_data")

/** Tags that entries of other extensions carry, such as the `lines` of BasicExtension's lines entries. */
private val tagsCarriedByOtherExtensions = setOf("lines")

/** Written by KSP while the main sources compile, and copied next to the classes the tests run against. */
private const val MANIFEST = "build/resources/main/extension.json"

private const val ENTITY_SOURCES = "src/main/kotlin/com/typewritermc/entity/entries/entity"

private val entityTypeReference = Regex("""EntityTypes\.([A-Z0-9_]+)""")

/** An entry of the compiled extension manifest, reduced to what these checks read. */
private class CompiledEntry(
    val id: String,
    val tags: List<String>,
    val offeredTags: Set<String>?,
    val definitionTag: String?,
) {
    val isDefinition: Boolean get() = "entity_definition" in tags
    val isInstance: Boolean get() = "entity_instance" in tags && !isDefinition
    val isEntity: Boolean get() = "entity_definition" in tags || "entity_instance" in tags
    val isData: Boolean get() = "entity_data" in tags
}

private fun JsonObject.objectAt(name: String): JsonObject? = get(name)?.takeIf { it.isJsonObject }?.asJsonObject

private fun JsonObject.modifier(name: String): String? =
    get("modifiers")?.takeIf { it.isJsonArray }?.asJsonArray
        ?.map { it.asJsonObject }
        ?.firstOrNull { it.get("name").asString == name }
        ?.get("data")?.takeUnless { it.isJsonNull }?.asString

private fun JsonObject.toCompiledEntry(): CompiledEntry {
    val tags = getAsJsonArray("tags").map { it.asString }
    val fields = objectAt("dataBlueprint")?.objectAt("fields")
    val isEntity = "entity_definition" in tags || "entity_instance" in tags
    return CompiledEntry(
        id = get("id").asString,
        tags = tags,
        offeredTags = fields?.objectAt("data")?.objectAt("type")?.modifier("only_tags")
            ?.split(",")?.toSet()?.takeIf { isEntity },
        definitionTag = fields?.objectAt("definition")?.modifier("entry"),
    )
}

private fun loadCompiledEntries(): List<CompiledEntry> {
    val manifest = File(MANIFEST)
    check(manifest.isFile) { "${manifest.absolutePath} is missing. Compiling the main sources writes it." }
    return JsonParser.parseString(manifest.readText()).asJsonObject
        .getAsJsonArray("entries")
        .map { it.asJsonObject.toCompiledEntry() }
}

private fun entityTypesInUse(): Set<String> {
    val sources = File(ENTITY_SOURCES)
    check(sources.isDirectory) { "${sources.absolutePath} is missing. Run the tests through Gradle." }
    val types = sources.walk()
        .filter { it.extension == "kt" && it.name != "EntityTypeProperty.kt" }
        .flatMap { file -> entityTypeReference.findAll(file.readText()).map { it.groupValues[1] } }
        .toSet()
    check(types.isNotEmpty()) { "No EntityTypes references were found under ${sources.absolutePath}." }
    return types
}

/**
 * Fails on a problem that is not in [known], and on a [known] one that is gone, so the list shrinks as the
 * extension gets fixed instead of hiding new problems behind old ones.
 */
private fun Set<String>.shouldMatchKnown(known: Set<String>, listName: String, describe: (String) -> String) {
    withClue("New problems:") {
        (this - known).sorted().map(describe).shouldBeEmpty()
    }
    withClue("No longer a problem, so take these out of $listName in EntityEntriesSpec and AGENTS.md:") {
        (known - this).sorted().shouldBeEmpty()
    }
}

class EntityEntriesSpec : FunSpec({
    val entries by lazy { loadCompiledEntries() }
    val entities by lazy { entries.filter { it.isEntity && it.offeredTags != null } }

    test("every entry id is unique") {
        val duplicates = entries.groupingBy { it.id }.eachCount().filterValues { it > 1 }.keys
        duplicates.shouldMatchKnown(knownDuplicateIds, "knownDuplicateIds") { id ->
            "More than one entry is named `$id`, and the loader only ever finds the first. Give each its own id."
        }
    }

    test("an instance offers the same data as its definition") {
        val definitions = entries.filter { it.isDefinition }.groupBy { it.tags.first() }
        val mismatches = entities.filter { it.isInstance }.mapNotNull { instance ->
            val definition = instance.definitionTag?.let(definitions::get)?.singleOrNull()
                ?: return@mapNotNull null
            if (definition.offeredTags == instance.offeredTags) return@mapNotNull null
            "`${instance.id}` offers ${instance.offeredTags.orEmpty().sorted()} but `${definition.id}` offers " +
                "${definition.offeredTags.orEmpty().sorted()}. Give both @OnlyTags lists the same tags."
        }
        mismatches.shouldBeEmpty()
    }

    test("every tag an entity offers is carried by some data") {
        val carriedTags = entries.flatMap { it.tags }.toSet()
        val offeredBy = entities
            .flatMap { entity -> entity.offeredTags.orEmpty().map { tag -> tag to entity.id } }
            .filter { (tag, _) -> tag !in carriedTags && tag !in tagsCarriedByOtherExtensions }
            .groupBy({ it.first }, { it.second })
        offeredBy.keys.shouldMatchKnown(reservedTags + placeholderTags, "reservedTags or placeholderTags") { tag ->
            "${offeredBy.getValue(tag).sorted()} offer `$tag`, but no data entry carries it. " +
                "Tag the data meant for it, or take the tag out of both @OnlyTags lists."
        }
    }

    test("every data entry is offered to some entity") {
        val offeredTags = entities.flatMap { it.offeredTags.orEmpty() }.toSet()
        val unreachable = entries.filter { it.isData && it.tags.none(offeredTags::contains) }.map { it.id }.toSet()
        unreachable.shouldMatchKnown(unreachableData, "unreachableData") { id ->
            "`$id` carries no tag that any entity offers, so it can never be picked. " +
                "Add one of its tags to the @OnlyTags lists of the entities it is meant for."
        }
    }

    test("every entity type in use has a size row") {
        loadEntityTypes()
        val missing = entityTypesInUse().filter { name ->
            val type = EntityTypes::class.java.getField(name).get(null) as EntityType
            runCatching { type.state(emptyMap()) }.isFailure
        }
        withClue("Add a row for each to manualEntityData in entity/custom/EntityTypeProperty.kt:") {
            missing.sorted().shouldBeEmpty()
        }
    }
})
