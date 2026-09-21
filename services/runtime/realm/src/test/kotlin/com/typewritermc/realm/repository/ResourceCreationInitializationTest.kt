package com.typewritermc.realm.repository

import com.typewritermc.library.Book
import com.typewritermc.types.DataValue
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe

val ResourceCreationInitializationTest by testSuite {
    test("materializes Kotlin defaults into a complete book draft") {
        val prototypes = loadTestPrototypes()
        val root = prototypes.require(Book::class).type

        val initialized = prototypes.initialize(root, DataValue.Record(emptyMap()))
        val book = prototypes.decodeAs<Book>(initialized)

        book.title shouldBe ""
        book.tags shouldBe emptySet()
        book.pages.toSet() shouldBe emptySet()
        (initialized.rootValue as DataValue.Record).fields.keys shouldBe
            setOf("title", "icon", "color", "tags", "pages")
    }
}
