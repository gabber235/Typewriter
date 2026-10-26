package com.typewritermc.realm.catalog

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe

val RealmCatalogStoreTest by testSuite {
    test("a retained catalog stays usable after the store closes and is released with its lease") {
        val store = RealmCatalogStore()
        val incarnation = testCatalogIncarnation("first")
        store.replace(incarnation)
        val retained = store.captureCurrent()
        store.close()

        retained.generation.value shouldBe "first"
        incarnation.shouldBeOpen()
        retained.close()
        incarnation.shouldBeClosed()
    }

    test("a retired catalog stays open until its last lease is released") {
        val store = RealmCatalogStore()
        val incarnation = testCatalogIncarnation("first")
        store.replace(incarnation)
        val first = store.captureCurrent()
        val second = first.retain()
        store.close()

        first.close()
        incarnation.shouldBeOpen()
        second.close()
        incarnation.shouldBeClosed()
    }

    test("replacing the catalog of an active store is refused and keeps the installed catalog") {
        RealmCatalogStore().use { store ->
            store.installTestCatalog("first")

            val second = testCatalogIncarnation("second")
            second.deployment.use {
                shouldThrow<IllegalStateException> { store.replace(second) }.message shouldBe
                    "Initial Realm catalog replacement cannot be used for an active store."
            }
            store.captureCurrent().use { it.generation.value } shouldBe "first"
        }
    }
}

/** The incarnation's deployment still lends out its providers. */
private fun RealmCatalogIncarnation.shouldBeOpen() = deployment.retain().close()

/** The incarnation's deployment refuses to lend out its providers any more. */
private fun RealmCatalogIncarnation.shouldBeClosed() {
    shouldThrow<IllegalStateException> { deployment.retain() }.message shouldBe "Generated provider deployment is closed."
}
