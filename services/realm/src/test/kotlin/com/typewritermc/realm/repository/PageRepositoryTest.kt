package com.typewritermc.realm.repository

import com.surrealdb.Surreal
import com.typewritermc.realm.schema.SchemaMigrator
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.collections.shouldBeEmpty
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.collections.shouldContainExactlyInAnyOrder
import io.kotest.matchers.collections.shouldHaveSize
import io.kotest.matchers.nulls.shouldBeNull
import io.kotest.matchers.nulls.shouldNotBeNull
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import protokt.v1.typewriter.models.v1.Page
import protokt.v1.typewriter.models.v1.PageType

class PageRepositoryTest : FunSpec({

    lateinit var db: Surreal
    lateinit var repository: SurrealPageRepository

    beforeEach {
        db = Surreal()
        db.connect("memory")
        db.useNs("test").useDb("test")
        SchemaMigrator(db).migrate()
        repository = SurrealPageRepository(db)
    }

    afterEach {
        db.close()
    }

    context("listPages") {

        test("returns all pages for a book") {
            db.query(
                """
                CREATE book:book1 SET title = 'Book 1', icon = 'book', color = 4278190335;
                CREATE page:p1 SET name = 'Page 1', book_id = book:book1, type = 'sequence', chapter = 'intro', priority = 1;
                CREATE page:p2 SET name = 'Page 2', book_id = book:book1, type = 'scene', chapter = 'intro', priority = 2;
                CREATE page:p3 SET name = 'Page 3', book_id = book:book1, type = 'static', chapter = 'outro', priority = 1;
            """.trimIndent()
            )

            val pages = repository.listPages("book1")

            pages shouldHaveSize 3
            pages.map { it.name } shouldContainExactlyInAnyOrder listOf("Page 1", "Page 2", "Page 3")
        }

        test("returns empty when book has no pages") {
            db.query(
                """
                CREATE book:empty_book SET title = 'Empty Book', icon = 'book', color = 4278190335;
            """.trimIndent()
            )

            val pages = repository.listPages("empty_book")

            pages.shouldBeEmpty()
        }

        test("returns only pages for specified book") {
            db.query(
                """
                CREATE book:book_a SET title = 'Book A', icon = 'book', color = 4278190335;
                CREATE book:book_b SET title = 'Book B', icon = 'book', color = 4278190335;
                CREATE page:pa1 SET name = 'Page A1', book_id = book:book_a, type = 'sequence', chapter = '', priority = 0;
                CREATE page:pa2 SET name = 'Page A2', book_id = book:book_a, type = 'sequence', chapter = '', priority = 0;
                CREATE page:pb1 SET name = 'Page B1', book_id = book:book_b, type = 'sequence', chapter = '', priority = 0;
            """.trimIndent()
            )

            val pagesA = repository.listPages("book_a")
            val pagesB = repository.listPages("book_b")

            pagesA shouldHaveSize 2
            pagesA.map { it.name } shouldContainExactlyInAnyOrder listOf("Page A1", "Page A2")
            pagesB shouldHaveSize 1
            pagesB.first().name shouldBe "Page B1"
        }

        test("returns pages ordered by priority") {
            db.query(
                """
                CREATE book:ordered SET title = 'Ordered', icon = 'book', color = 4278190335;
                CREATE page:low SET name = 'Low Priority', book_id = book:ordered, type = 'sequence', chapter = '', priority = 10;
                CREATE page:high SET name = 'High Priority', book_id = book:ordered, type = 'sequence', chapter = '', priority = 1;
                CREATE page:mid SET name = 'Mid Priority', book_id = book:ordered, type = 'sequence', chapter = '', priority = 5;
            """.trimIndent()
            )

            val pages = repository.listPages("ordered")

            pages shouldHaveSize 3
            pages.map { it.name } shouldContainExactly listOf("High Priority", "Mid Priority", "Low Priority")
        }
    }

    context("searchPages") {

        test("finds pages by exact name") {
            db.query(
                """
                CREATE book:search SET title = 'Search Book', icon = 'book', color = 4278190335;
                CREATE page:exact SET name = 'Exact Match', book_id = book:search, type = 'sequence', chapter = '', priority = 0;
                CREATE page:other SET name = 'Other Page', book_id = book:search, type = 'sequence', chapter = '', priority = 0;
            """.trimIndent()
            )

            val pages = repository.searchPages("search", "Exact Match")

            pages shouldHaveSize 1
            pages.first().name shouldBe "Exact Match"
        }

        test("finds pages by name substring") {
            db.query(
                """
                CREATE book:sub SET title = 'Substring Book', icon = 'book', color = 4278190335;
                CREATE page:intro SET name = 'Introduction Chapter', book_id = book:sub, type = 'sequence', chapter = '', priority = 0;
                CREATE page:outro SET name = 'Outro Section', book_id = book:sub, type = 'sequence', chapter = '', priority = 0;
                CREATE page:middle SET name = 'Middle Part', book_id = book:sub, type = 'sequence', chapter = '', priority = 0;
            """.trimIndent()
            )

            val pages = repository.searchPages("sub", "Intro")

            pages shouldHaveSize 1
            pages.first().name shouldBe "Introduction Chapter"
        }

        test("is case-insensitive") {
            db.query(
                """
                CREATE book:case SET title = 'Case Book', icon = 'book', color = 4278190335;
                CREATE page:mixed SET name = 'MiXeD CaSe', book_id = book:case, type = 'sequence', chapter = '', priority = 0;
            """.trimIndent()
            )

            val lowerResult = repository.searchPages("case", "mixed case")
            val upperResult = repository.searchPages("case", "MIXED CASE")

            lowerResult shouldHaveSize 1
            upperResult shouldHaveSize 1
        }

        test("returns empty for no matches") {
            db.query(
                """
                CREATE book:nomatch SET title = 'No Match Book', icon = 'book', color = 4278190335;
                CREATE page:exists SET name = 'Existing Page', book_id = book:nomatch, type = 'sequence', chapter = '', priority = 0;
            """.trimIndent()
            )

            val pages = repository.searchPages("nomatch", "nonexistent")

            pages.shouldBeEmpty()
        }

        test("only searches within specified book") {
            db.query(
                """
                CREATE book:b1 SET title = 'Book 1', icon = 'book', color = 4278190335;
                CREATE book:b2 SET title = 'Book 2', icon = 'book', color = 4278190335;
                CREATE page:target SET name = 'Target Page', book_id = book:b1, type = 'sequence', chapter = '', priority = 0;
                CREATE page:same_name SET name = 'Target Page', book_id = book:b2, type = 'sequence', chapter = '', priority = 0;
            """.trimIndent()
            )

            val pages = repository.searchPages("b1", "Target")

            pages shouldHaveSize 1
            pages.first().bookId shouldBe "b1"
        }
    }

    context("getPage") {

        test("returns page with all fields populated") {
            db.query(
                """
                CREATE book:gettest SET title = 'Get Test', icon = 'book', color = 4278190335;
                CREATE page:full SET 
                    name = 'Full Page', 
                    book_id = book:gettest, 
                    type = 'scene', 
                    chapter = 'chapter.sub', 
                    priority = 42;
            """.trimIndent()
            )

            val page = repository.getPage("full")

            page.shouldNotBeNull()
            page.id shouldBe "full"
            page.name shouldBe "Full Page"
            page.bookId shouldBe "gettest"
            page.type shouldBe PageType.SCENE
            page.chapter shouldBe "chapter.sub"
            page.priority shouldBe 42
        }

        test("returns null for non-existent ID") {
            val page = repository.getPage("nonexistent")

            page.shouldBeNull()
        }
    }

    context("createPage") {

        test("creates page with all fields correctly") {
            db.query("CREATE book:create_test SET title = 'Create Test', icon = 'book', color = 4278190335;")

            val page = repository.createPage(
                bookId = "create_test",
                name = "New Page",
                type = PageType.MANIFEST,
                chapter = "main.intro",
                priority = 5
            )

            page.shouldNotBeNull()
            page.name shouldBe "New Page"
            page.bookId shouldBe "create_test"
            page.type shouldBe PageType.MANIFEST
            page.chapter shouldBe "main.intro"
            page.priority shouldBe 5
        }

        test("creates page linked to correct book") {
            db.query(
                """
                CREATE book:link_test SET title = 'Link Test', icon = 'book', color = 4278190335;
            """.trimIndent()
            )

            val page = repository.createPage(
                bookId = "link_test",
                name = "Linked Page",
                type = PageType.SEQUENCE,
                chapter = "",
                priority = 0
            )

            page.bookId shouldBe "link_test"

            val dbPages = repository.listPages("link_test")
            dbPages shouldHaveSize 1
            dbPages.first().id shouldBe page.id
        }

        test("generates unique ID") {
            db.query("CREATE book:id_test SET title = 'ID Test', icon = 'book', color = 4278190335;")

            val page1 = repository.createPage("id_test", "Page 1", PageType.SEQUENCE, "", 0)
            val page2 = repository.createPage("id_test", "Page 2", PageType.SEQUENCE, "", 0)

            page1.id shouldNotBe page2.id
            page1.id.shouldNotBeNull()
            page2.id.shouldNotBeNull()
        }

        test("stores correct type string") {
            db.query("CREATE book:type_test SET title = 'Type Test', icon = 'book', color = 4278190335;")

            val sequence = repository.createPage("type_test", "Seq", PageType.SEQUENCE, "", 0)
            val static = repository.createPage("type_test", "Static", PageType.STATIC, "", 0)
            val scene = repository.createPage("type_test", "Scene", PageType.SCENE, "", 0)
            val manifest = repository.createPage("type_test", "Manifest", PageType.MANIFEST, "", 0)

            sequence.type shouldBe PageType.SEQUENCE
            static.type shouldBe PageType.STATIC
            scene.type shouldBe PageType.SCENE
            manifest.type shouldBe PageType.MANIFEST
        }
    }

    context("updatePage") {

        test("modifies all editable fields") {
            db.query(
                """
                CREATE book:update SET title = 'Update Test', icon = 'book', color = 4278190335;
                CREATE page:to_update SET name = 'Original', book_id = book:update, type = 'sequence', chapter = 'old', priority = 1;
            """.trimIndent()
            )

            val updated = repository.updatePage(Page {
                id = "to_update"
                bookId = "update"
                name = "Updated Name"
                type = PageType.SCENE
                chapter = "new.chapter"
                priority = 99
            })

            updated.name shouldBe "Updated Name"
            updated.type shouldBe PageType.SCENE
            updated.chapter shouldBe "new.chapter"
            updated.priority shouldBe 99
        }

        test("preserves book_id (immutable)") {
            db.query(
                """
                CREATE book:immutable SET title = 'Immutable', icon = 'book', color = 4278190335;
                CREATE book:other SET title = 'Other', icon = 'book', color = 4278190335;
                CREATE page:immut SET name = 'Immutable Page', book_id = book:immutable, type = 'sequence', chapter = '', priority = 0;
            """.trimIndent()
            )

            val updated = repository.updatePage(Page {
                id = "immut"
                bookId = "other"
                name = "Try to change book"
                type = PageType.SEQUENCE
                chapter = ""
                priority = 0
            })

            updated.bookId shouldBe "immutable"
        }
    }

    context("deletePage") {

        test("removes existing page") {
            db.query(
                """
                CREATE book:delete SET title = 'Delete Test', icon = 'book', color = 4278190335;
                CREATE page:to_delete SET name = 'Delete Me', book_id = book:delete, type = 'sequence', chapter = '', priority = 0;
            """.trimIndent()
            )

            val result = repository.deletePage("to_delete")

            result shouldBe true

            val page = repository.getPage("to_delete")
            page.shouldBeNull()
        }

        test("returns false for non-existent") {
            val result = repository.deletePage("nonexistent")

            result shouldBe false
        }
    }

    context("changePageChapter") {

        test("updates chapter for existing page") {
            db.query(
                """
                CREATE book:chapter SET title = 'Chapter Test', icon = 'book', color = 4278190335;
                CREATE page:ch SET name = 'Chapter Page', book_id = book:chapter, type = 'sequence', chapter = 'old.chapter', priority = 0;
            """.trimIndent()
            )

            val result = repository.changePageChapter("ch", "new.chapter")

            result shouldBe true

            val page = repository.getPage("ch").shouldNotBeNull()
            page.chapter shouldBe "new.chapter"
        }

        test("returns false for non-existent page") {
            val result = repository.changePageChapter("missing", "any")

            result shouldBe false
        }
    }

    context("changePagePriority") {

        test("updates priority for existing page") {
            db.query(
                """
                CREATE book:priority SET title = 'Priority Test', icon = 'book', color = 4278190335;
                CREATE page:prio SET name = 'Priority Page', book_id = book:priority, type = 'sequence', chapter = '', priority = 1;
            """.trimIndent()
            )

            val result = repository.changePagePriority("prio", 999)

            result shouldBe true

            val page = repository.getPage("prio").shouldNotBeNull()
            page.priority shouldBe 999
        }

        test("returns false for non-existent page") {
            val result = repository.changePagePriority("missing", 1)

            result shouldBe false
        }
    }

    context("renamePage") {

        test("updates name for existing page") {
            db.query(
                """
                CREATE book:rename SET title = 'Rename Test', icon = 'book', color = 4278190335;
                CREATE page:rn SET name = 'Old Name', book_id = book:rename, type = 'sequence', chapter = '', priority = 0;
            """.trimIndent()
            )

            val result = repository.renamePage("rn", "New Name")

            result shouldBe true

            val page = repository.getPage("rn").shouldNotBeNull()
            page.name shouldBe "New Name"
        }

        test("returns false for non-existent page") {
            val result = repository.renamePage("missing", "Any Name")

            result shouldBe false
        }
    }

    context("changePagesChapters (prefix matching)") {

        test("moves exact chapter match") {
            db.query(
                """
                CREATE book:prefix SET title = 'Prefix Test', icon = 'book', color = 4278190335;
                CREATE page:exact SET name = 'Exact', book_id = book:prefix, type = 'sequence', chapter = 'a.b', priority = 0;
            """.trimIndent()
            )

            val count = repository.changePagesChapters("prefix", "a.b", "x.y")

            count shouldBe 1

            val page = repository.getPage("exact").shouldNotBeNull()
            page.chapter shouldBe "x.y"
        }

        test("moves nested chapters (prefix match)") {
            db.query(
                """
                CREATE book:nested SET title = 'Nested Test', icon = 'book', color = 4278190335;
                CREATE page:nested1 SET name = 'Nested 1', book_id = book:nested, type = 'sequence', chapter = 'a.b.c', priority = 0;
                CREATE page:nested2 SET name = 'Nested 2', book_id = book:nested, type = 'sequence', chapter = 'a.b.c.d', priority = 0;
            """.trimIndent()
            )

            val count = repository.changePagesChapters("nested", "a.b", "x.y")

            count shouldBe 2

            val page1 = repository.getPage("nested1").shouldNotBeNull()
            val page2 = repository.getPage("nested2").shouldNotBeNull()
            page1.chapter shouldBe "x.y.c"
            page2.chapter shouldBe "x.y.c.d"
        }

        test("does not move parent chapters") {
            db.query(
                """
                CREATE book:parent SET title = 'Parent Test', icon = 'book', color = 4278190335;
                CREATE page:parent SET name = 'Parent', book_id = book:parent, type = 'sequence', chapter = 'a', priority = 0;
                CREATE page:child SET name = 'Child', book_id = book:parent, type = 'sequence', chapter = 'a.b', priority = 0;
            """.trimIndent()
            )

            val count = repository.changePagesChapters("parent", "a.b", "x.y")

            count shouldBe 1

            val parent = repository.getPage("parent").shouldNotBeNull()
            val child = repository.getPage("child").shouldNotBeNull()
            parent.chapter shouldBe "a"
            child.chapter shouldBe "x.y"
        }

        test("does not move similar but non-matching chapters") {
            db.query(
                """
                CREATE book:similar SET title = 'Similar Test', icon = 'book', color = 4278190335;
                CREATE page:target SET name = 'Target', book_id = book:similar, type = 'sequence', chapter = 'a.b', priority = 0;
                CREATE page:similar SET name = 'Similar', book_id = book:similar, type = 'sequence', chapter = 'a.bb', priority = 0;
            """.trimIndent()
            )

            val count = repository.changePagesChapters("similar", "a.b", "x.y")

            count shouldBe 1

            val target = repository.getPage("target").shouldNotBeNull()
            val similar = repository.getPage("similar").shouldNotBeNull()
            target.chapter shouldBe "x.y"
            similar.chapter shouldBe "a.bb"
        }

        test("returns count of updated pages") {
            db.query(
                """
                CREATE book:count SET title = 'Count Test', icon = 'book', color = 4278190335;
                CREATE page:c1 SET name = 'C1', book_id = book:count, type = 'sequence', chapter = 'test.hey', priority = 0;
                CREATE page:c2 SET name = 'C2', book_id = book:count, type = 'sequence', chapter = 'test.hey.sub', priority = 0;
                CREATE page:c3 SET name = 'C3', book_id = book:count, type = 'sequence', chapter = 'test.hey.sub.deep', priority = 0;
                CREATE page:c4 SET name = 'C4', book_id = book:count, type = 'sequence', chapter = 'other', priority = 0;
            """.trimIndent()
            )

            val count = repository.changePagesChapters("count", "test.hey", "hallo.hey")

            count shouldBe 3
        }

        test("only affects pages in specified book") {
            db.query(
                """
                CREATE book:iso1 SET title = 'Iso 1', icon = 'book', color = 4278190335;
                CREATE book:iso2 SET title = 'Iso 2', icon = 'book', color = 4278190335;
                CREATE page:iso1 SET name = 'Iso1', book_id = book:iso1, type = 'sequence', chapter = 'a.b', priority = 0;
                CREATE page:iso2 SET name = 'Iso2', book_id = book:iso2, type = 'sequence', chapter = 'a.b', priority = 0;
            """.trimIndent()
            )

            val count = repository.changePagesChapters("iso1", "a.b", "x.y")

            count shouldBe 1

            val iso1 = repository.getPage("iso1").shouldNotBeNull()
            val iso2 = repository.getPage("iso2").shouldNotBeNull()
            iso1.chapter shouldBe "x.y"
            iso2.chapter shouldBe "a.b"
        }

        test("handles empty result (no matches)") {
            db.query(
                """
                CREATE book:empty SET title = 'Empty', icon = 'book', color = 4278190335;
                CREATE page:nomatch SET name = 'No Match', book_id = book:empty, type = 'sequence', chapter = 'other', priority = 0;
            """.trimIndent()
            )

            val count = repository.changePagesChapters("empty", "nonexistent", "new")

            count shouldBe 0
        }
    }
})
