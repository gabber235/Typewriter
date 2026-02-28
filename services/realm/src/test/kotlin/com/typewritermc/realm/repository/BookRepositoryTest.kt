package com.typewritermc.realm.repository

import com.surrealdb.RecordId
import com.surrealdb.Surreal
import com.typewritermc.realm.repository.utils.BookRecord
import com.typewritermc.realm.schema.SchemaMigrator
import com.typewritermc.services.libs.telemetry.testing.MockTelemetry
import com.typewritermc.services.libs.utils.asDeferredProvider
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.collections.shouldBeEmpty
import io.kotest.matchers.collections.shouldContainExactlyInAnyOrder
import io.kotest.matchers.collections.shouldHaveSingleElement
import io.kotest.matchers.collections.shouldHaveSize
import io.kotest.matchers.nulls.shouldBeNull
import io.kotest.matchers.nulls.shouldNotBeNull
import io.kotest.matchers.shouldBe
import protokt.v1.typewriter.models.v1.Book
import protokt.v1.typewriter.models.v1.Color

class BookRepositoryTest : FunSpec({

    lateinit var db: Surreal
    lateinit var repository: SurrealBookRepository
    val tracer = MockTelemetry.createMockTracer()

    beforeEach {
        db = Surreal()
        db.connect("memory")
        db.useNs("test").useDb("test")
        SchemaMigrator(db, tracer).migrate()
        repository = SurrealBookRepository(db.asDeferredProvider())
    }

    afterEach {
        db.close()
    }

    context("listBooks") {

        test("returns all books from database") {
            db.query(
                """
                CREATE book:a SET title = 'book_a', icon = 'book';
                CREATE book:b SET title = 'book_b', icon = 'star';
                CREATE book:c SET title = 'book_c', icon = 'flag';
            """.trimIndent()
            )

            val books = repository.listBooks()

            books shouldHaveSize 3
            books.map { it.title } shouldContainExactlyInAnyOrder listOf("book_a", "book_b", "book_c")
        }

        test("returns empty list when no books exist") {
            val books = repository.listBooks()

            books.shouldBeEmpty()
        }

        test("returns books with tags resolved via bears relationship") {
            db.query(
                """
                CREATE tag:red SET name = 'red_tag';
                CREATE tag:blue SET name = 'blue_tag';
                CREATE book:with_tags SET title = 'tagged_book', icon = 'tag';
                RELATE book:with_tags->bears->tag:red;
                RELATE book:with_tags->bears->tag:blue;
            """.trimIndent()
            )

            val books = repository.listBooks()

            books shouldHaveSize 1
            val book = books.first()
            book.tagIds shouldHaveSize 2
            book.tagIds shouldContainExactlyInAnyOrder listOf("red", "blue")
        }
    }

    context("getBook") {

        test("returns existing book by ID") {
            db.query(
                """
                CREATE book:abc123 SET title = 'test_book', icon = 'diamond', color = 2864434397;
            """.trimIndent()
            )

            val book = repository.getBook("abc123")

            book.shouldNotBeNull()
            book.bookId shouldBe "abc123"
            book.title shouldBe "test_book"
            book.icon shouldBe "diamond"
            book.color!!.value shouldBe 0xAABBCCDD.toUInt()
        }

        test("returns null for non-existent ID") {
            val book = repository.getBook("nonexistent")

            book.shouldBeNull()
        }

        test("returns book with all tag ids") {
            db.query(
                """
                CREATE tag:parent SET name = 'parent';
                CREATE tag:child SET name = 'child';
                RELATE tag:child->inherits->tag:parent;
                CREATE book:tagged SET title = 'tagged_book', icon = 'book';
                RELATE book:tagged->bears->tag:child;
            """.trimIndent()
            )

            val book = repository.getBook("tagged")

            book.shouldNotBeNull()
            book.tagIds shouldHaveSize 1
            book.tagIds shouldHaveSingleElement "child"
        }
    }

    context("createBook") {

        test("creates book and returns it with generated ID") {
            val book = repository.createBook("new_book", "scroll", 0xFF0000FF.toInt())

            book.shouldNotBeNull()
            book.bookId.shouldNotBeNull()
            book.title shouldBe "new_book"
            book.icon shouldBe "scroll"
            book.color!!.value shouldBe 0xFF0000FF.toUInt()

            val dbResult = db.query("SELECT * FROM book WHERE title = 'new_book'")
            val storedBooks = BookRecord.parseList(dbResult.take(0))
            storedBooks shouldHaveSingleElement BookRecord(
                id = RecordId("book", book.bookId),
                title = "new_book",
                icon = "scroll",
                color = 0xFF0000FF
            )
        }

        test("creates book with tags and establishes bears relationships") {
            db.query(
                """
                CREATE tag:red SET name = 'red';
                CREATE tag:blue SET name = 'blue';
                """.trimIndent()
            )

            val book = repository.createBook(
                "tagged_book",
                "book",
                0xFF0000,
                listOf("red", "blue")
            )

            book.shouldNotBeNull()
            book.title shouldBe "tagged_book"
            book.tagIds shouldHaveSize 2
            book.tagIds shouldContainExactlyInAnyOrder listOf("red", "blue")

            val bearsResult = db.queryBind(
                $$"SELECT VALUE ->bears->tag FROM ONLY type::thing('book', $id)",
                mapOf("id" to book.bookId)
            )
            val bearsValue = bearsResult.take(0)
            bearsValue.isArray shouldBe true
            bearsValue.array.map { it.thing.id.string } shouldContainExactlyInAnyOrder listOf("red", "blue")
        }

        test("creates book without tags when tagIds is empty") {
            val book = repository.createBook("simple_book", "book", 0xFFFFFF, emptyList())

            book.shouldNotBeNull()
            book.tagIds.shouldBeEmpty()

            val bearsResult = db.queryBind(
                "SELECT VALUE ->bears->tag FROM ONLY type::thing('book', \$id)",
                mapOf("id" to book.bookId)
            )
            bearsResult.take(0).array.shouldBeEmpty()
        }

        test("creates book with non-existent tagIds") {
            val book = repository.createBook("orphan_book", "book", 0xFFFFFF, listOf("nonexistent"))

            book.shouldNotBeNull()
            book.tagIds.shouldBeEmpty()
        }
    }

    context("updateBook") {

        test("updates all book fields") {
            db.query(
                """
                CREATE book:update_test SET title = 'old_title', icon = 'old_icon';
            """.trimIndent()
            )

            val updatedBook = Book {
                bookId = "update_test"
                title = "new_title"
                icon = "new_icon"
                color = Color { value = 0x22222222.toUInt() }
            }

            val result = repository.updateBook(updatedBook)

            result.title shouldBe "new_title"
            result.icon shouldBe "new_icon"
            result.color!!.value shouldBe 0x22222222.toUInt()

            val dbResult = db.query("SELECT * FROM ONLY book:update_test")
            val storedBooks = BookRecord.parse(dbResult.take(0))
            storedBooks.title shouldBe "new_title"
            storedBooks.icon shouldBe "new_icon"
            storedBooks.color shouldBe 0x22222222L
        }

        test("updates tag relationships via tags field") {
            db.query(
                """
                CREATE tag:tag_a SET name = 'tag_a';
                CREATE tag:tag_b SET name = 'tag_b';
                CREATE tag:tag_c SET name = 'tag_c';
                CREATE book:book_tags SET title = 'book_1', icon = 'book', color = 4278255360;
                RELATE book:book_tags->bears->tag:tag_a;
                RELATE book:book_tags->bears->tag:tag_b;
            """.trimIndent()
            )

            val updatedBook = Book {
                bookId = "book_tags"
                title = "book_1"
                icon = "book"
                color = Color { value = 0xFF00FF00.toUInt() }
                tagIds = listOf("tag_b", "tag_c")
            }

            val result = repository.updateBook(updatedBook)

            result.tagIds shouldContainExactlyInAnyOrder listOf("tag_b", "tag_c")

            val tagsResult = db.query("SELECT VALUE ->bears->tag FROM ONLY book:book_tags")
            val tagsValue = tagsResult.take(0)
            tagsValue.isArray shouldBe true
            val tagsArray = tagsValue.array
            tagsArray.map { it.thing.id.string } shouldContainExactlyInAnyOrder listOf(
                "tag_b",
                "tag_c"
            )
        }
    }

    context("deleteBook") {

        test("removes book from database") {
            db.query(
                """
                CREATE book:to_delete SET title = 'delete_me', icon = 'trash';
            """.trimIndent()
            )

            repository.deleteBook("to_delete") shouldBe true

            val dbResult = db.query("record::exists(book:to_delete)")
            dbResult.take(0).boolean shouldBe false
        }

        test("returns false for non-existent ID") {
            repository.deleteBook("nonexistent") shouldBe false
        }

        test("removes orphaned bears relationships") {
            db.query(
                """
                CREATE tag:orphan_test SET name = 'tag_1';
                CREATE book:cascade SET title = 'cascade_book', icon = 'book';
                RELATE book:cascade->bears->tag:orphan_test;
            """.trimIndent()
            )

            repository.deleteBook("cascade") shouldBe true

            val bearsResult = db.query("SELECT VALUE ->bears->tag FROM book:cascade")
            val bearsValue = bearsResult.take(0)
            bearsValue.isArray shouldBe true
            bearsValue.array.map { it.thing.id.string }.shouldBeEmpty()
        }
    }

    context("addTagToBook") {

        test("creates bears relationship between book and tag") {
            db.query(
                """
                CREATE book:add_tag SET title = 'book_2', icon = 'book';
                CREATE tag:to_add SET name = 'tag_2';
            """.trimIndent()
            )

            val originalBook = repository.getBook("add_tag")
            originalBook.shouldNotBeNull()
            originalBook.tagIds.shouldBeEmpty()

            repository.addTagToBook("add_tag", "to_add") shouldBe true

            val book = repository.getBook("add_tag")
            book.shouldNotBeNull()
            book.tagIds shouldHaveSize 1
            book.tagIds shouldHaveSingleElement "to_add"
        }

        test("returns false when book does not exist") {
            db.query(
                """
                CREATE tag:orphan SET name = 'orphan';
            """.trimIndent()
            )

            repository.addTagToBook("nonexistent", "orphan") shouldBe false
        }

        test("returns false when tag does not exist") {
            db.query(
                """
                CREATE book:no_tag SET title = 'book_3', icon = 'book', color = 4278255360;
            """.trimIndent()
            )

            repository.addTagToBook("no_tag", "nonexistent") shouldBe false
        }
    }

    context("removeTagFromBook") {

        test("removes bears relationship between book and tag") {
            db.query(
                """
                CREATE book:remove_tag SET title = 'book_4', icon = 'book';
                CREATE tag:removable SET name = 'removable';
                RELATE book:remove_tag->bears->tag:removable;
            """.trimIndent()
            )

            val originalBook = repository.getBook("remove_tag")
            originalBook.shouldNotBeNull()
            originalBook.tagIds shouldHaveSize 1

            repository.removeTagFromBook("remove_tag", "removable") shouldBe true

            val book = repository.getBook("remove_tag")
            book.shouldNotBeNull()
            book.tagIds.shouldBeEmpty()
        }

        test("returns false when relationship does not exist") {
            db.query(
                """
                CREATE book:no_rel SET title = 'book_5', icon = 'book';
                CREATE tag:not_related SET name = 'not_related';
            """.trimIndent()
            )

            repository.removeTagFromBook("no_rel", "not_related") shouldBe false
        }
    }

    context("title validation") {

        test("accepts valid lowercase title") {
            db.query("CREATE book:valid SET title = 'valid_book_123', icon = 'book';")

            val book = repository.getBook("valid")
            book.shouldNotBeNull()
            book.title shouldBe "valid_book_123"
        }

        test("accepts empty title") {
            db.query("CREATE book:empty SET title = '', icon = 'book';")

            val book = repository.getBook("empty")
            book.shouldNotBeNull()
            book.title shouldBe ""
        }

        test("rejects title with uppercase letters") {
            io.kotest.assertions.throwables.shouldThrow<com.surrealdb.SurrealException> {
                db.query("CREATE book:upper SET title = 'Invalid', icon = 'book';")
                    .take(0)
            }
        }

        test("rejects title with spaces") {
            io.kotest.assertions.throwables.shouldThrow<com.surrealdb.SurrealException> {
                db.query("CREATE book:spaces SET title = 'has space', icon = 'book';")
                    .take(0)
            }
        }

        test("rejects title with special characters") {
            io.kotest.assertions.throwables.shouldThrow<com.surrealdb.SurrealException> {
                db.query("CREATE book:special SET title = 'book-name', icon = 'book';")
                    .take(0)
            }
        }
    }
})
