package com.typewritermc.realm.routes

import com.typewritermc.realm.catalog.RealmCatalogStore
import com.typewritermc.realm.catalog.installTestCatalog
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import kotlinx.coroutines.test.runTest
import skirout.editor.v1.catalog.CatalogFetchRequest
import skirout.editor.v1.catalog.CatalogFetchResult
import skirout.editor.v1.catalog.WatchEditorCatalogRequest
import skirout.editor.v1.type_catalog.CatalogGeneration

val RetainedRealmEditorCatalogSourceTest by testSuite {
    test("fetch returns one coherent full catalog") {
        runTest {
            val catalogs = RealmCatalogStore()
            catalogs.installTestCatalog("catalog_a")
            try {
                val catalog =
                    RetainedRealmEditorCatalogSource(catalogs)
                        .fetch(CatalogFetchRequest(expectedGeneration = null))
                        .shouldBeInstanceOf<CatalogFetchResult.CatalogWrapper>()
                        .value

                catalog.generation.value shouldBe "catalog_a"
                catalog.types.isNotEmpty() shouldBe true
            } finally {
                catalogs.close()
            }
        }
    }

    test("fetch rejects a stale expected generation without encoding a catalog") {
        runTest {
            val catalogs = RealmCatalogStore()
            catalogs.installTestCatalog("catalog_b")
            try {
                val result =
                    RetainedRealmEditorCatalogSource(catalogs).fetch(
                        CatalogFetchRequest(expectedGeneration = CatalogGeneration(value = "catalog_a")),
                    )

                result.shouldBeInstanceOf<CatalogFetchResult.GenerationChangedErrorWrapper>().value.value shouldBe "catalog_b"
            } finally {
                catalogs.close()
            }
        }
    }

    test("catalog watch begins at the captured current generation") {
        runTest {
            val catalogs = RealmCatalogStore()
            catalogs.installTestCatalog("catalog_watch")
            try {
                val result =
                    RetainedRealmEditorCatalogSource(catalogs)
                        .initialGeneration(WatchEditorCatalogRequest())

                result.generation.value shouldBe "catalog_watch"
            } finally {
                catalogs.close()
            }
        }
    }
}
