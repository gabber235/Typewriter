package com.typewritermc.realm.checking

import com.typewritermc.imprint.ExtensionManifest
import com.typewritermc.loader.api.EngineCoverage
import com.typewritermc.loader.api.SourcePartDisposition
import com.typewritermc.loader.api.SourcePartKey
import com.typewritermc.realm.authoring.AuthoringViewStore
import com.typewritermc.realm.authoring.EntryCoverage
import kotlinx.coroutines.flow.Flow

/** Which source parts run each entry type's behaviour, as the deployed extension manifests declare. */
class EntryHandlers(
    manifests: Collection<ExtensionManifest>,
) {
    private val handlers: Map<String, List<SourcePartKey>> =
        manifests
            .flatMap { manifest ->
                manifest.sourceParts.flatMap { part ->
                    part.handledEntries.map { entry -> entry.canonicalText to SourcePartKey(manifest.id, part.name) }
                }
            }.groupBy({ it.first }, { it.second })

    /**
     * The entry types [engines] run on no engine: each type whose handling parts all run nowhere. A part [engines] does
     * not know leaves its types out, since nothing is known about them yet.
     */
    fun coverage(engines: EngineCoverage): EntryCoverage =
        EntryCoverage(
            handlers
                .mapNotNull { (type, parts) ->
                    val dispositions = parts.map { part -> engines.parts[part] ?: return@mapNotNull null }
                    val nowhere = dispositions.filterIsInstance<SourcePartDisposition.Ineligible>()
                    if (nowhere.size < dispositions.size) return@mapNotNull null
                    type to nowhere.flatMap(SourcePartDisposition.Ineligible::reasons).distinct()
                }.toMap(),
        )
}

/** Keeps this store's entry coverage current with each coverage [engines] report, until the caller is cancelled. */
suspend fun AuthoringViewStore.follow(
    engines: Flow<EngineCoverage>,
    handlers: EntryHandlers,
) = engines.collect { cover(handlers.coverage(it)) }
