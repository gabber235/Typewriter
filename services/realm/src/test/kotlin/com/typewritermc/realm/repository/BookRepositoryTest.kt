package com.typewritermc.realm.repository

import com.surrealdb.RecordId
import com.surrealdb.Surreal
import com.typewritermc.realm.repository.utils.BookRecord
import com.typewritermc.realm.schema.SchemaMigrator
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

    beforeEach {
        db = Surreal()
        db.connect("memory")
        db.useNs("test").useDb("test")
        SchemaMigrator(db).migrate()
        repository = SurrealBookRepository(db)
    }

    afterEach {
        db.close()
    }

    context("listBooks") {

        test("returns all books from database") {
            db.query(
                """
                CREATE book:a SET title = 'Book A', icon = 'book';
                CREATE book:b SET title = 'Book B', icon = 'star';
                CREATE book:c SET title = 'Book C', icon = 'flag';
            """.trimIndent()
            )

            val books = repository.listBooks()

            books shouldHaveSize 3
            books.map { it.title } shouldContainExactlyInAnyOrder listOf("Book A", "Book B", "Book C")
        }

        test("returns empty list when no books exist") {
            val books = repository.listBooks()

            books.shouldBeEmpty()
        }

        test("returns books with tags resolved via bears relationship") {
            db.query(
                """
                CREATE tag:red SET name = 'Red Tag';
                CREATE tag:blue SET name = 'Blue Tag';
                CREATE book:with_tags SET title = 'Tagged Book', icon = 'tag';
                RELATE book:with_tags->bears->tag:red;
                RELATE book:with_tags->bears->tag:blue;
            """.trimIndent()
            )

            val books = repository.listBooks()

            books shouldHaveSize 1
            val book = books.first()
            book.tags shouldHaveSize 2
            book.tags.map { it.name } shouldContainExactlyInAnyOrder listOf("Red Tag", "Blue Tag")
        }

        test("return books with all inherited tags resolved") {
            db.query(
                """
                CREATE tag:city SET name = 'City Tag';
                CREATE tag:country SET name = 'Country Tag';
                CREATE tag:continent SET name = 'Continent Tag';
                CREATE book:with_inherited_tags SET title = 'Tagged Book', icon = 'tag';
                RELATE tag:city->inherits->tag:country;
                RELATE tag:country->inherits->tag:continent;
                RELATE book:with_inherited_tags->bears->tag:city;
            """.trimIndent()
            )

            val books = repository.listBooks()

            books shouldHaveSize 1
            val book = books.first()
            book.tags.map { it.name } shouldHaveSingleElement "City Tag"
            book.tags.first().parents.map { it.name } shouldHaveSingleElement "Country Tag"
            book.tags.first().parents.first().parents.map { it.name } shouldHaveSingleElement "Continent Tag"
        }
    }

    context("getBook") {

        test("returns existing book by ID") {
            db.query(
                """
                CREATE book:abc123 SET title = 'Test Book', icon = 'diamond', color = 2864434397;
            """.trimIndent()
            )

            val book = repository.getBook("abc123")

            book.shouldNotBeNull()
            book.id shouldBe "abc123"
            book.title shouldBe "Test Book"
            book.icon shouldBe "diamond"
            book.color!!.value shouldBe 0xAABBCCDD.toUInt()
        }

        test("returns null for non-existent ID") {
            val book = repository.getBook("nonexistent")

            book.shouldBeNull()
        }

        test("returns book with all tags resolved") {
            db.query(
                """
                CREATE tag:parent SET name = 'Parent';
                CREATE tag:child SET name = 'Child';
                RELATE tag:child->inherits->tag:parent;
                CREATE book:tagged SET title = 'Tagged Book', icon = 'book';
                RELATE book:tagged->bears->tag:child;
            """.trimIndent()
            )

            val book = repository.getBook("tagged")

            book.shouldNotBeNull()
            book.tags shouldHaveSize 1
            val tag = book.tags.first()
            tag.name shouldBe "Child"
            tag.parents shouldHaveSize 1
            tag.parents.first().name shouldBe "Parent"
        }

        test("returns book with all inherited tags resolved") {
            db.query(
                """
                CREATE tag:city SET name = 'City Tag';
                CREATE tag:country SET name = 'Country Tag';
                CREATE tag:continent SET name = 'Continent Tag';
                CREATE book:with_inherited_tags SET title = 'Tagged Book', icon = 'tag';
                RELATE tag:city->inherits->tag:country;
                RELATE tag:country->inherits->tag:continent;
                RELATE book:with_inherited_tags->bears->tag:city;
            """.trimIndent()
            )

            val book = repository.getBook("with_inherited_tags")

            book.shouldNotBeNull()
            book.tags.map { it.name } shouldHaveSingleElement "City Tag"
            book.tags.first().parents.map { it.name } shouldHaveSingleElement "Country Tag"
            book.tags.first().parents.first().parents.map { it.name } shouldHaveSingleElement "Continent Tag"
        }
    }

    context("createBook") {

        test("creates book and returns it with generated ID") {
            val book = repository.createBook("New Book", "scroll", 0xFF0000FF.toInt())

            book.shouldNotBeNull()
            book.id.shouldNotBeNull()
            book.title shouldBe "New Book"
            book.icon shouldBe "scroll"
            book.color!!.value shouldBe 0xFF0000FF.toUInt()

            val dbResult = db.query("SELECT * FROM book WHERE title = 'New Book'")
            val storedBooks = BookRecord.parseList(dbResult.take(0))
            storedBooks shouldHaveSingleElement BookRecord(
                id = RecordId("book", book.id),
                title = "New Book",
                icon = "scroll",
                color = 0xFF0000FF
            )
        }
    }

    context("updateBook") {

        test("updates all book fields") {
            db.query(
                """
                CREATE book:update_test SET title = 'Old Title', icon = 'old_icon';
            """.trimIndent()
            )

            val updatedBook = Book {
                id = "update_test"
                title = "New Title"
                icon = "new_icon"
                color = Color { value = 0x22222222.toUInt() }
            }

            val result = repository.updateBook(updatedBook)

            result.title shouldBe "New Title"
            result.icon shouldBe "new_icon"
            result.color!!.value shouldBe 0x22222222.toUInt()

            val dbResult = db.query("SELECT * FROM ONLY book:update_test")
            val storedBooks = BookRecord.parse(dbResult.take(0))
            storedBooks.title shouldBe "New Title"
            storedBooks.icon shouldBe "new_icon"
            storedBooks.color shouldBe 0x22222222L
        }

        test("updates tag relationships via tags field") {
            db.query(
                """
                CREATE tag:tag_a SET name = 'Tag A';
                CREATE tag:tag_b SET name = 'Tag B';
                CREATE tag:tag_c SET name = 'Tag C';
                CREATE book:book_tags SET title = 'Book', icon = 'book', color = 4278255360;
                RELATE book:book_tags->bears->tag:tag_a;
                RELATE book:book_tags->bears->tag:tag_b;
            """.trimIndent()
            )

            val tagB = protokt.v1.typewriter.models.v1.Tag { id = "tag_b"; name = "Tag B" }
            val tagC = protokt.v1.typewriter.models.v1.Tag { id = "tag_c"; name = "Tag C" }
            val updatedBook = Book {
                id = "book_tags"
                title = "Book"
                icon = "book"
                color = Color { value = 0xFF00FF00.toUInt() }
                tags = listOf(tagB, tagC)
            }

            val result = repository.updateBook(updatedBook)

            result.tags.map { it.name } shouldContainExactlyInAnyOrder listOf("Tag B", "Tag C")

            val tagsResult = db.query("SELECT VALUE ->bears->tag FROM ONLY book:book_tags")
            val tagsValue = tagsResult.take(0)
            println(tagsValue)
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
                CREATE book:to_delete SET title = 'Delete Me', icon = 'trash';
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
                CREATE tag:orphan_test SET name = 'Tag';
                CREATE book:cascade SET title = 'Cascade Book', icon = 'book';
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
                CREATE book:add_tag SET title = 'Book', icon = 'book';
                CREATE tag:to_add SET name = 'Tag';
            """.trimIndent()
            )

            val originalBook = repository.getBook("add_tag")
            originalBook.shouldNotBeNull()
            originalBook.tags.shouldBeEmpty()

            repository.addTagToBook("add_tag", "to_add") shouldBe true

            val book = repository.getBook("add_tag")
            book.shouldNotBeNull()
            book.tags shouldHaveSize 1
            book.tags.first().id shouldBe "to_add"
        }

        test("returns false when book does not exist") {
            db.query(
                """
                CREATE tag:orphan SET name = 'Orphan';
            """.trimIndent()
            )

            repository.addTagToBook("nonexistent", "orphan") shouldBe false
        }

        test("returns false when tag does not exist") {
            db.query(
                """
                CREATE book:no_tag SET title = 'Book', icon = 'book', color = 4278255360;
            """.trimIndent()
            )

            repository.addTagToBook("no_tag", "nonexistent") shouldBe false
        }
    }

    context("removeTagFromBook") {

        test("removes bears relationship between book and tag") {
            db.query(
                """
                CREATE book:remove_tag SET title = 'Book', icon = 'book';
                CREATE tag:removable SET name = 'Removable';
                RELATE book:remove_tag->bears->tag:removable;
            """.trimIndent()
            )

            val originalBook = repository.getBook("remove_tag")
            originalBook.shouldNotBeNull()
            originalBook.tags shouldHaveSize 1

            repository.removeTagFromBook("remove_tag", "removable") shouldBe true

            val book = repository.getBook("remove_tag")
            book.shouldNotBeNull()
            book.tags.shouldBeEmpty()
        }

        test("returns false when relationship does not exist") {
            db.query(
                """
                CREATE book:no_rel SET title = 'Book', icon = 'book';
                CREATE tag:not_related SET name = 'Not Related';
            """.trimIndent()
            )

            repository.removeTagFromBook("no_rel", "not_related") shouldBe false
        }
    }
})
