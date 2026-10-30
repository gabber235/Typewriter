package com.typewritermc.testkit

import com.typewritermc.discovery.GENERATED_PROVIDER_INDEX_PATH
import com.typewritermc.discovery.GeneratedProviderIndex
import com.typewritermc.discovery.GeneratedProviderIndexEntry
import com.typewritermc.discovery.GeneratedProviderKind
import com.typewritermc.discovery.GeneratedTypeProvider
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.TypeDefinition
import java.util.Collections

/** Every distinct entry of the generated provider indexes on the test class path. */
fun generatedProviderEntries(): List<GeneratedProviderIndexEntry> =
    Collections
        .list(requireNotNull(Thread.currentThread().contextClassLoader).getResources(GENERATED_PROVIDER_INDEX_PATH))
        .flatMap { resource -> resource.openStream().bufferedReader().use { GeneratedProviderIndex.parse(it.readText()) } }
        .distinct()

/** The provider [entry] names: the object itself, or a new instance of the class. */
fun generatedProvider(entry: GeneratedProviderIndexEntry): Any {
    val type = Class.forName(entry.providerClass)
    return type.fields.singleOrNull { it.name == "INSTANCE" }?.get(null) ?: type.getConstructor().newInstance()
}

/** One instance of each generated provider of [kind] the generated provider indexes on the test class path list. */
inline fun <reified P : Any> generatedProviders(kind: GeneratedProviderKind): List<P> =
    generatedProviderEntries().filter { it.kind == kind }.map { generatedProvider(it) as P }

/** A catalog [generation] of the standard types and every type a generated provider on the test class path declares. */
fun generatedTypeCatalog(generation: String): DefaultCheckedCatalog =
    DefaultCheckedCatalog(
        CatalogGeneration(value = generation),
        StandardTypes.definitions +
            generatedProviders<GeneratedTypeProvider>(GeneratedProviderKind.Type)
                .map(GeneratedTypeProvider::definition)
                .distinctBy(TypeDefinition::id),
    )
