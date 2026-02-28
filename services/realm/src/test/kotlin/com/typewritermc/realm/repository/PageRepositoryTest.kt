package com.typewritermc.realm.repository

import com.surrealdb.Surreal
import com.typewritermc.realm.schema.SchemaMigrator
import com.typewritermc.services.libs.telemetry.testing.MockTelemetry
import com.typewritermc.services.libs.utils.asDeferredProvider
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
    val tracer = MockTelemetry.createMockTracer()

    beforeEach {
        db = Surreal()
        db.connect("memory")
        db.useNs("test").useDb("test")
        SchemaMigrator(db, tracer).migrate()
        repository = SurrealPageRepository(db.asDeferredProvider())
    }

    afterEach {
        db.close()
    }

    context("listPages") {

        test("returns all pages for a book") {
            db.query(
                """
                CREATE book:book1 SET title = 'book_1', icon = 'book', color = 4278190335;
                CREATE page:p1 SET name = 'page_1', book_id = book:book1, type = 'sequence', chapter = 'intro', priority = 1;
                CREATE page:p2 SET name = 'page_2', book_id = book:book1, type = 'scene', chapter = 'intro', priority = 2;
                CREATE page:p3 SET name = 'page_3', book_id = book:book1, type = 'static', chapter = 'outro', priority = 1;
            """.trimIndent()
            )

            val pages = repository.listPages("book1")

            pages shouldHaveSize 3
            pages.map { it.name } shouldContainExactlyInAnyOrder listOf("page_1", "page_2", "page_3")
        }

        test("returns empty when book has no pages") {
            db.query(
                """
                CREATE book:empty_book SET title = 'empty_book', icon = 'book', color = 4278190335;
            """.trimIndent()
            )

            val pages = repository.listPages("empty_book")

            pages.shouldBeEmpty()
        }

        test("returns only pages for specified book") {
            db.query(
                """
                CREATE book:book_a SET title = 'book_a', icon = 'book', color = 4278190335;
                CREATE book:book_b SET title = 'book_b', icon = 'book', color = 4278190335;
                CREATE page:pa1 SET name = 'page_a1', book_id = book:book_a, type = 'sequence', chapter = '', priority = 0;
                CREATE page:pa2 SET name = 'page_a2', book_id = book:book_a, type = 'sequence', chapter = '', priority = 0;
                CREATE page:pb1 SET name = 'page_b1', book_id = book:book_b, type = 'sequence', chapter = '', priority = 0;
            """.trimIndent()
            )

            val pagesA = repository.listPages("book_a")
            val pagesB = repository.listPages("book_b")

            pagesA shouldHaveSize 2
            pagesA.map { it.name } shouldContainExactlyInAnyOrder listOf("page_a1", "page_a2")
            pagesB shouldHaveSize 1
            pagesB.first().name shouldBe "page_b1"
        }

        test("returns pages ordered by priority") {
            db.query(
                """
                CREATE book:ordered SET title = 'ordered', icon = 'book', color = 4278190335;
                CREATE page:low SET name = 'low_priority', book_id = book:ordered, type = 'sequence', chapter = '', priority = 10;
                CREATE page:high SET name = 'high_priority', book_id = book:ordered, type = 'sequence', chapter = '', priority = 1;
                CREATE page:mid SET name = 'mid_priority', book_id = book:ordered, type = 'sequence', chapter = '', priority = 5;
            """.trimIndent()
            )

            val pages = repository.listPages("ordered")

            pages shouldHaveSize 3
            pages.map { it.name } shouldContainExactly listOf("high_priority", "mid_priority", "low_priority")
        }
    }

    context("searchPages") {

        test("finds pages by exact name") {
            db.query(
                """
                CREATE book:search SET title = 'search_book', icon = 'book', color = 4278190335;
                CREATE page:exact SET name = 'exact_match', book_id = book:search, type = 'sequence', chapter = '', priority = 0;
                CREATE page:other SET name = 'other_page', book_id = book:search, type = 'sequence', chapter = '', priority = 0;
            """.trimIndent()
            )

            val pages = repository.searchPages("search", "exact_match")

            pages shouldHaveSize 1
            pages.first().name shouldBe "exact_match"
        }

        test("finds pages by name substring") {
            db.query(
                """
                CREATE book:sub SET title = 'substring_book', icon = 'book', color = 4278190335;
                CREATE page:intro SET name = 'introduction_chapter', book_id = book:sub, type = 'sequence', chapter = '', priority = 0;
                CREATE page:outro SET name = 'outro_section', book_id = book:sub, type = 'sequence', chapter = '', priority = 0;
                CREATE page:middle SET name = 'middle_part', book_id = book:sub, type = 'sequence', chapter = '', priority = 0;
            """.trimIndent()
            )

            val pages = repository.searchPages("sub", "intro")

            pages shouldHaveSize 1
            pages.first().name shouldBe "introduction_chapter"
        }

        test("is case-insensitive") {
            db.query(
                """
                CREATE book:case SET title = 'case_book', icon = 'book', color = 4278190335;
                CREATE page:mixed SET name = 'mixed_case', book_id = book:case, type = 'sequence', chapter = '', priority = 0;
            """.trimIndent()
            )

            val lowerResult = repository.searchPages("case", "mixed_case")
            val upperResult = repository.searchPages("case", "MIXED_CASE")

            lowerResult shouldHaveSize 1
            upperResult shouldHaveSize 1
        }

        test("returns empty for no matches") {
            db.query(
                """
                CREATE book:nomatch SET title = 'no_match_book', icon = 'book', color = 4278190335;
                CREATE page:exists SET name = 'existing_page', book_id = book:nomatch, type = 'sequence', chapter = '', priority = 0;
            """.trimIndent()
            )

            val pages = repository.searchPages("nomatch", "nonexistent")

            pages.shouldBeEmpty()
        }

        test("only searches within specified book") {
            db.query(
                """
                CREATE book:b1 SET title = 'book_1', icon = 'book', color = 4278190335;
                CREATE book:b2 SET title = 'book_2', icon = 'book', color = 4278190335;
                CREATE page:target SET name = 'target_page', book_id = book:b1, type = 'sequence', chapter = '', priority = 0;
                CREATE page:same_name SET name = 'target_page', book_id = book:b2, type = 'sequence', chapter = '', priority = 0;
            """.trimIndent()
            )

            val pages = repository.searchPages("b1", "target")

            pages shouldHaveSize 1
            pages.first().bookId shouldBe "b1"
        }
    }

    context("getPage") {

        test("returns page with all fields populated") {
            db.query(
                """
                CREATE book:gettest SET title = 'get_test', icon = 'book', color = 4278190335;
                CREATE page:full SET 
                    name = 'full_page', 
                    book_id = book:gettest, 
                    type = 'scene', 
                    chapter = 'chapter.sub', 
                    priority = 42;
            """.trimIndent()
            )

            val page = repository.getPage("full")

            page.shouldNotBeNull()
            page.pageId shouldBe "full"
            page.name shouldBe "full_page"
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
            db.query("CREATE book:create_test SET title = 'create_test', icon = 'book', color = 4278190335;")

            val page = repository.createPage(
                bookId = "create_test",
                name = "new_page",
                type = PageType.MANIFEST,
                chapter = "main.intro",
                priority = 5
            )

            page.shouldNotBeNull()
            page.name shouldBe "new_page"
            page.bookId shouldBe "create_test"
            page.type shouldBe PageType.MANIFEST
            page.chapter shouldBe "main.intro"
            page.priority shouldBe 5
        }

        test("creates page linked to correct book") {
            db.query(
                """
                CREATE book:link_test SET title = 'link_test', icon = 'book', color = 4278190335;
            """.trimIndent()
            )

            val page = repository.createPage(
                bookId = "link_test",
                name = "linked_page",
                type = PageType.SEQUENCE,
                chapter = "",
                priority = 0
            )

            page.bookId shouldBe "link_test"

            val dbPages = repository.listPages("link_test")
            dbPages shouldHaveSize 1
            dbPages.first().pageId shouldBe page.pageId
        }

        test("generates unique ID") {
            db.query("CREATE book:id_test SET title = 'id_test', icon = 'book', color = 4278190335;")

            val page1 = repository.createPage("id_test", "page_1", PageType.SEQUENCE, "", 0)
            val page2 = repository.createPage("id_test", "page_2", PageType.SEQUENCE, "", 0)

            page1.pageId shouldNotBe page2.pageId
            page1.pageId.shouldNotBeNull()
            page2.pageId.shouldNotBeNull()
        }

        test("stores correct type string") {
            db.query("CREATE book:type_test SET title = 'type_test', icon = 'book', color = 4278190335;")

            val sequence = repository.createPage("type_test", "seq_page", PageType.SEQUENCE, "", 0)
            val static = repository.createPage("type_test", "static_page", PageType.STATIC, "", 0)
            val scene = repository.createPage("type_test", "scene_page", PageType.SCENE, "", 0)
            val manifest = repository.createPage("type_test", "manifest_page", PageType.MANIFEST, "", 0)

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
                CREATE book:update SET title = 'update_test', icon = 'book', color = 4278190335;
                CREATE page:to_update SET name = 'original', book_id = book:update, type = 'sequence', chapter = 'old', priority = 1;
            """.trimIndent()
            )

            val updated = repository.updatePage(Page {
                pageId = "to_update"
                bookId = "update"
                name = "updated_name"
                type = PageType.SCENE
                chapter = "new.chapter"
                priority = 99
            })

            updated.name shouldBe "updated_name"
            updated.type shouldBe PageType.SCENE
            updated.chapter shouldBe "new.chapter"
            updated.priority shouldBe 99
        }

        test("preserves book_id (immutable)") {
            db.query(
                """
                CREATE book:immutable SET title = 'immutable', icon = 'book', color = 4278190335;
                CREATE book:other SET title = 'other', icon = 'book', color = 4278190335;
                CREATE page:immut SET name = 'immutable_page', book_id = book:immutable, type = 'sequence', chapter = '', priority = 0;
            """.trimIndent()
            )

            val updated = repository.updatePage(Page {
                pageId = "immut"
                bookId = "other"
                name = "try_change_book"
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
                CREATE book:delete SET title = 'delete_test', icon = 'book', color = 4278190335;
                CREATE page:to_delete SET name = 'delete_me', book_id = book:delete, type = 'sequence', chapter = '', priority = 0;
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
                CREATE book:chapter SET title = 'chapter_test', icon = 'book', color = 4278190335;
                CREATE page:ch SET name = 'chapter_page', book_id = book:chapter, type = 'sequence', chapter = 'old.chapter', priority = 0;
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

        test("sets chapter to empty string") {
            db.query(
                """
                CREATE book:empty_ch SET title = 'empty_ch', icon = 'book', color = 4278190335;
                CREATE page:empty_ch SET name = 'empty_chapter_page', book_id = book:empty_ch, type = 'sequence', chapter = 'some.chapter', priority = 0;
            """.trimIndent()
            )

            val result = repository.changePageChapter("empty_ch", "")

            result shouldBe true

            val page = repository.getPage("empty_ch").shouldNotBeNull()
            page.chapter shouldBe ""
        }
    }

    context("changePagePriority") {

        test("updates priority for existing page") {
            db.query(
                """
                CREATE book:priority SET title = 'priority_test', icon = 'book', color = 4278190335;
                CREATE page:prio SET name = 'priority_page', book_id = book:priority, type = 'sequence', chapter = '', priority = 1;
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
                CREATE book:rename SET title = 'rename_test', icon = 'book', color = 4278190335;
                CREATE page:rn SET name = 'old_name', book_id = book:rename, type = 'sequence', chapter = '', priority = 0;
            """.trimIndent()
            )

            val result = repository.renamePage("rn", "new_name")

            result shouldBe true

            val page = repository.getPage("rn").shouldNotBeNull()
            page.name shouldBe "new_name"
        }

        test("returns false for non-existent page") {
            val result = repository.renamePage("missing", "Any Name")

            result shouldBe false
        }
    }

    context("changePagesChapters") {

        test("moves exact chapter match") {
            db.query(
                """
                CREATE book:prefix SET title = 'prefix_test', icon = 'book', color = 4278190335;
                CREATE page:exact SET name = 'exact_page', book_id = book:prefix, type = 'sequence', chapter = 'a.b', priority = 0;
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
                CREATE book:nested SET title = 'nested_test', icon = 'book', color = 4278190335;
                CREATE page:nested1 SET name = 'nested_1', book_id = book:nested, type = 'sequence', chapter = 'a.b.c', priority = 0;
                CREATE page:nested2 SET name = 'nested_2', book_id = book:nested, type = 'sequence', chapter = 'a.b.c.d', priority = 0;
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
                CREATE book:parent SET title = 'parent_test', icon = 'book', color = 4278190335;
                CREATE page:parent SET name = 'parent_page', book_id = book:parent, type = 'sequence', chapter = 'a', priority = 0;
                CREATE page:child SET name = 'child_page', book_id = book:parent, type = 'sequence', chapter = 'a.b', priority = 0;
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
                CREATE book:similar SET title = 'similar_test', icon = 'book', color = 4278190335;
                CREATE page:target SET name = 'target_page', book_id = book:similar, type = 'sequence', chapter = 'a.b', priority = 0;
                CREATE page:similar SET name = 'similar_page', book_id = book:similar, type = 'sequence', chapter = 'a.bb', priority = 0;
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
                CREATE book:count SET title = 'count_test', icon = 'book', color = 4278190335;
                CREATE page:c1 SET name = 'count_1', book_id = book:count, type = 'sequence', chapter = 'test.hey', priority = 0;
                CREATE page:c2 SET name = 'count_2', book_id = book:count, type = 'sequence', chapter = 'test.hey.sub', priority = 0;
                CREATE page:c3 SET name = 'count_3', book_id = book:count, type = 'sequence', chapter = 'test.hey.sub.deep', priority = 0;
                CREATE page:c4 SET name = 'count_4', book_id = book:count, type = 'sequence', chapter = 'other', priority = 0;
            """.trimIndent()
            )

            val count = repository.changePagesChapters("count", "test.hey", "hallo.hey")
            count shouldBe 3
        }

        test("only affects pages in specified book") {
            db.query(
                """
                CREATE book:iso1 SET title = 'iso_1', icon = 'book', color = 4278190335;
                CREATE book:iso2 SET title = 'iso_2', icon = 'book', color = 4278190335;
                CREATE page:iso1 SET name = 'iso1', book_id = book:iso1, type = 'sequence', chapter = 'a.b', priority = 0;
                CREATE page:iso2 SET name = 'iso2', book_id = book:iso2, type = 'sequence', chapter = 'a.b', priority = 0;
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
                CREATE book:empty SET title = 'empty', icon = 'book', color = 4278190335;
                CREATE page:nomatch SET name = 'no_match', book_id = book:empty, type = 'sequence', chapter = 'other', priority = 0;
            """.trimIndent()
            )

            val count = repository.changePagesChapters("empty", "nonexistent", "new")

            count shouldBe 0
        }

        test("moves pages from empty chapter to new chapter") {
            db.query(
                """
                CREATE book:from_empty SET title = 'from_empty', icon = 'book', color = 4278190335;
                CREATE page:fe1 SET name = 'empty', book_id = book:from_empty, type = 'sequence', chapter = '', priority = 0;
                CREATE page:fe2 SET name = 'already_in_chapter', book_id = book:from_empty, type = 'sequence', chapter = 'new_chapter', priority = 1;
                CREATE page:fe3 SET name = 'stays_in_different_chapter', book_id = book:from_empty, type = 'sequence', chapter = 'other', priority = 0;
            """.trimIndent()
            )

            val count = repository.changePagesChapters("from_empty", "", "new_chapter")

            count shouldBe 1

            val page1 = repository.getPage("fe1").shouldNotBeNull()
            page1.chapter shouldBe "new_chapter"

            val page2 = repository.getPage("fe2").shouldNotBeNull()
            page2.chapter shouldBe "new_chapter"

            val page3 = repository.getPage("fe3").shouldNotBeNull()
            page3.chapter shouldBe "other"
        }

        test("moves pages to empty chapter (strips prefix)") {
            db.query(
                """
                CREATE book:to_empty SET title = 'to_empty', icon = 'book', color = 4278190335;
                CREATE page:te1 SET name = 'to_empty_one', book_id = book:to_empty, type = 'sequence', chapter = 'old', priority = 0;
                CREATE page:te2 SET name = 'stays_empty', book_id = book:to_empty, type = 'sequence', chapter = '', priority = 0;
                CREATE page:te3 SET name = 'stays_in_chapter', book_id = book:to_empty, type = 'sequence', chapter = 'keep', priority = 0;
                CREATE page:te4 SET name = 'sub_chapters_stay', book_id = book:to_empty, type = 'sequence', chapter = 'old.sub.nested', priority = 0;
            """.trimIndent()
            )


            val count = repository.changePagesChapters("to_empty", "old", "")

            count shouldBe 2

            val page1 = repository.getPage("te1").shouldNotBeNull()
            page1.chapter shouldBe ""

            val page2 = repository.getPage("te2").shouldNotBeNull()
            page2.chapter shouldBe ""

            val page3 = repository.getPage("te3").shouldNotBeNull()
            page3.chapter shouldBe "keep"

            val page4 = repository.getPage("te4").shouldNotBeNull()
            page4.chapter shouldBe "sub.nested"
        }

        test("with both empty old and new is a no-op") {
            db.query(
                """
                CREATE book:both_empty SET title = 'both_empty', icon = 'book', color = 4278190335;
                CREATE page:be1 SET name = 'both_empty_one', book_id = book:both_empty, type = 'sequence', chapter = '', priority = 0;
                CREATE page:be2 SET name = 'both_empty_two', book_id = book:both_empty, type = 'sequence', chapter = 'existing', priority = 0;
            """.trimIndent()
            )

            val count = repository.changePagesChapters("both_empty", "", "")
            count shouldBe 0

            val page1 = repository.getPage("be1").shouldNotBeNull()
            val page2 = repository.getPage("be2").shouldNotBeNull()
            page1.chapter shouldBe ""
            page2.chapter shouldBe "existing"
        }
    }

    context("name validation") {

        test("accepts valid lowercase name") {
            db.query(
                """
                CREATE book:valid SET title = 'valid', icon = 'book', color = 4278190335;
                CREATE page:valid SET name = 'valid_page_1', book_id = book:valid, type = 'sequence', chapter = '', priority = 0;
            """.trimIndent()
            )

            val page = repository.getPage("valid")
            page.shouldNotBeNull()
            page.name shouldBe "valid_page_1"
        }

        test("rejects name with uppercase letters") {
            db.query("CREATE book:nupper SET title = 'nupper', icon = 'book', color = 4278190335;")
            io.kotest.assertions.throwables.shouldThrow<com.surrealdb.SurrealException> {
                db.query("CREATE page:upper SET name = 'Invalid', book_id = book:nupper, type = 'sequence', chapter = '', priority = 0;")
                    .take(0)
            }
        }

        test("rejects name with spaces") {
            db.query("CREATE book:nspaces SET title = 'nspaces', icon = 'book', color = 4278190335;")
            io.kotest.assertions.throwables.shouldThrow<com.surrealdb.SurrealException> {
                db.query("CREATE page:spaces SET name = 'has space', book_id = book:nspaces, type = 'sequence', chapter = '', priority = 0;")
                    .take(0)
            }
        }

        test("rejects name shorter than 3 characters") {
            db.query("CREATE book:nshort SET title = 'nshort', icon = 'book', color = 4278190335;")
            io.kotest.assertions.throwables.shouldThrow<com.surrealdb.SurrealException> {
                db.query("CREATE page:short SET name = 'ab', book_id = book:nshort, type = 'sequence', chapter = '', priority = 0;")
                    .take(0)
            }
        }

        test("rejects name starting with underscore") {
            db.query("CREATE book:nstart SET title = 'nstart', icon = 'book', color = 4278190335;")
            io.kotest.assertions.throwables.shouldThrow<com.surrealdb.SurrealException> {
                db.query("CREATE page:startus SET name = '_invalid', book_id = book:nstart, type = 'sequence', chapter = '', priority = 0;")
                    .take(0)
            }
        }

        test("rejects name ending with underscore") {
            db.query("CREATE book:nend SET title = 'nend', icon = 'book', color = 4278190335;")
            io.kotest.assertions.throwables.shouldThrow<com.surrealdb.SurrealException> {
                db.query("CREATE page:endus SET name = 'invalid_', book_id = book:nend, type = 'sequence', chapter = '', priority = 0;")
                    .take(0)
            }
        }
    }

    context("chapter validation") {

        test("accepts valid chapter with dots") {
            db.query(
                """
                CREATE book:chvalid SET title = 'chvalid', icon = 'book', color = 4278190335;
                CREATE page:chvalid SET name = 'chapter_valid', book_id = book:chvalid, type = 'sequence', chapter = 'main.intro', priority = 0;
            """.trimIndent()
            )

            val page = repository.getPage("chvalid")
            page.shouldNotBeNull()
            page.chapter shouldBe "main.intro"
        }

        test("accepts empty chapter") {
            db.query(
                """
                CREATE book:chempty SET title = 'chempty', icon = 'book', color = 4278190335;
                CREATE page:chempty SET name = 'chapter_empty', book_id = book:chempty, type = 'sequence', chapter = '', priority = 0;
            """.trimIndent()
            )

            val page = repository.getPage("chempty")
            page.shouldNotBeNull()
            page.chapter shouldBe ""
        }

        test("accepts single character chapter") {
            db.query(
                """
                CREATE book:chsingle SET title = 'chsingle', icon = 'book', color = 4278190335;
                CREATE page:chsingle SET name = 'chapter_single', book_id = book:chsingle, type = 'sequence', chapter = 'a', priority = 0;
            """.trimIndent()
            )

            val page = repository.getPage("chsingle")
            page.shouldNotBeNull()
            page.chapter shouldBe "a"
        }

        test("accepts two character chapter") {
            db.query(
                """
                CREATE book:chtwo SET title = 'chtwo', icon = 'book', color = 4278190335;
                CREATE page:chtwo SET name = 'chapter_two', book_id = book:chtwo, type = 'sequence', chapter = 'ab', priority = 0;
            """.trimIndent()
            )

            val page = repository.getPage("chtwo")
            page.shouldNotBeNull()
            page.chapter shouldBe "ab"
        }

        test("rejects chapter with uppercase letters") {
            db.query("CREATE book:chupper SET title = 'chupper', icon = 'book', color = 4278190335;")
            io.kotest.assertions.throwables.shouldThrow<com.surrealdb.SurrealException> {
                db.query("CREATE page:chupper SET name = 'chapter_upper', book_id = book:chupper, type = 'sequence', chapter = 'Invalid', priority = 0;")
                    .take(0)
            }
        }

        test("rejects chapter starting with dot") {
            db.query("CREATE book:chdot SET title = 'chdot', icon = 'book', color = 4278190335;")
            io.kotest.assertions.throwables.shouldThrow<com.surrealdb.SurrealException> {
                db.query("CREATE page:chdot SET name = 'chapter_dot', book_id = book:chdot, type = 'sequence', chapter = '.invalid', priority = 0;")
                    .take(0)
            }
        }

        test("rejects chapter ending with dot") {
            db.query("CREATE book:chdote SET title = 'chdote', icon = 'book', color = 4278190335;")
            io.kotest.assertions.throwables.shouldThrow<com.surrealdb.SurrealException> {
                db.query("CREATE page:chdote SET name = 'chapter_dote', book_id = book:chdote, type = 'sequence', chapter = 'invalid.', priority = 0;")
                    .take(0)
            }
        }

        test("rejects chapter starting with underscore") {
            db.query("CREATE book:chus SET title = 'chus', icon = 'book', color = 4278190335;")
            io.kotest.assertions.throwables.shouldThrow<com.surrealdb.SurrealException> {
                db.query("CREATE page:chus SET name = 'chapter_us', book_id = book:chus, type = 'sequence', chapter = '_invalid', priority = 0;")
                    .take(0)
            }
        }

        test("rejects chapter ending with underscore") {
            db.query("CREATE book:chuse SET title = 'chuse', icon = 'book', color = 4278190335;")
            io.kotest.assertions.throwables.shouldThrow<com.surrealdb.SurrealException> {
                db.query("CREATE page:chuse SET name = 'chapter_use', book_id = book:chuse, type = 'sequence', chapter = 'invalid_', priority = 0;")
                    .take(0)
            }
        }
    }
})
