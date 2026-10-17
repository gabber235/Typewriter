package com.typewritermc.realm.catalog

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe

val RealmCatalogStoreTest by testSuite {
    test("initial catalog stays available through a retained lease after store close") {
        val store = RealmCatalogStore()
        store.installTestCatalog("first")
        val retained = store.captureCurrent()
        store.close()

        retained.generation.value shouldBe "first"
        retained.close()
    }
}
