package com.typewritermc.realm.repository

import com.typewritermc.realm.repository.records.BookCreateOutputRecord
import com.typewritermc.realm.repository.records.BookUpdateOutputRecord
import com.typewritermc.realm.repository.records.TagCreateOutputRecord
import com.typewritermc.realm.repository.records.TagDeleteOutputRecord
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.string.shouldContain

val MutationOutputRecordTest by testSuite {
    test("unknown mutation tags fail at the database boundary") {
        shouldThrow<IllegalStateException> { BookCreateOutputRecord(kind = "unexpected").toResult() }
            .message shouldContain "unknown create outcome"
    }

    test("tagged mutation payloads are mandatory") {
        shouldThrow<IllegalStateException> { BookUpdateOutputRecord(kind = "conflict").toResult() }
            .message shouldContain "requires a book"
        shouldThrow<IllegalStateException> { TagCreateOutputRecord(kind = "parents_not_found").toResult() }
            .message shouldContain "requires parent ids"
        shouldThrow<IllegalStateException> { TagDeleteOutputRecord(kind = "success").toResult() }
            .message shouldContain "requires deletion details"
    }
}
