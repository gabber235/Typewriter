package com.typewritermc.testkit

import com.typewritermc.discovery.GENERATED_PROVIDER_INDEX_PATH
import com.typewritermc.discovery.GeneratedProviderIndex
import com.typewritermc.discovery.GeneratedProviderKind
import com.typewritermc.discovery.GeneratedTypeProvider
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.TypeDefinition
import java.util.Collections

/**
 * One instance of every generated provider of [kind] that the generated provider indexes on the test class path list:
 * the object itself, or a new instance of the class.
 */
inline fun <reified P : Any> generatedProviders(kind: GeneratedProviderKind): List<P> =
    generatedProviderClasses(kind).map { name ->
        val type = Class.forName(name)
        (type.fields.singleOrNull { it.name == "INSTANCE" }?.get(null) ?: type.getConstructor().newInstance()) as P
    }

/** The class names of the generated providers of [kind] that the generated provider indexes on the test class path list. */
fun generatedProviderClasses(kind: GeneratedProviderKind): List<String> =
    Collections
        .list(requireNotNull(Thread.currentThread().contextClassLoader).getResources(GENERATED_PROVIDER_INDEX_PATH))
        .flatMap { resource -> resource.openStream().bufferedReader().use { GeneratedProviderIndex.parse(it.readText()) } }
        .distinct()
        .filter { it.kind == kind }
        .map { it.providerClass }

/** A catalog [generation] of the standard types and every type a generated provider on the test class path declares. */
fun generatedTypeCatalog(generation: String): DefaultCheckedCatalog =
    DefaultCheckedCatalog(
        CatalogGeneration(value = generation),
        StandardTypes.definitions +
            generatedProviders<GeneratedTypeProvider>(GeneratedProviderKind.Type)
                .map(GeneratedTypeProvider::definition)
                .distinctBy(TypeDefinition::id),
    )
