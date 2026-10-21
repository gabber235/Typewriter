package com.typewritermc.realm.routes

import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.realm.catalog.RealmCatalogStore
import skirout.editor.v1.catalog.CatalogFetchRequest
import skirout.editor.v1.catalog.CatalogFetchResult
import skirout.editor.v1.catalog.CatalogInvalidated
import skirout.editor.v1.catalog.WatchEditorCatalogRequest
import skirout.editor.v1.type_catalog.CatalogGeneration as WireCatalogGeneration

interface RealmEditorCatalogSource {
    suspend fun fetch(request: CatalogFetchRequest): CatalogFetchResult

    suspend fun initialGeneration(request: WatchEditorCatalogRequest): CatalogInvalidated
}

/**
 * Answers catalog fetches from the retained editor catalog of the catalog owner.
 *
 * A requested generation mismatch returns the actual generation without encoding a catalog. The complete catalog
 * is one response; the transport splits it into frames when it is large.
 */
class RetainedRealmEditorCatalogSource(
    private val catalogs: RealmCatalogStore,
) : RealmEditorCatalogSource {
    override suspend fun fetch(request: CatalogFetchRequest): CatalogFetchResult =
        catalogs.captureCurrent().use { catalog ->
            val expected = request.expectedGeneration?.value?.let(::CatalogGeneration)
            if (expected != null && expected != catalog.generation) {
                CatalogFetchResult.GenerationChangedErrorWrapper(WireCatalogGeneration(value = catalog.generation.value))
            } else {
                CatalogFetchResult.CatalogWrapper(catalog.editorCatalog)
            }
        }

    override suspend fun initialGeneration(request: WatchEditorCatalogRequest): CatalogInvalidated =
        catalogs.captureCurrent().use { catalog ->
            CatalogInvalidated(generation = WireCatalogGeneration(value = catalog.generation.value))
        }
}
