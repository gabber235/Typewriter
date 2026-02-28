package com.typewritermc.realm.repository

import com.surrealdb.Surreal
import com.typewritermc.realm.schema.SchemaMigrator
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.collections.*
import io.kotest.matchers.nulls.shouldBeNull
import io.kotest.matchers.nulls.shouldNotBeNull
import io.kotest.matchers.shouldBe
import protokt.v1.typewriter.models.v1.Color
import protokt.v1.typewriter.models.v1.Placement
import protokt.v1.typewriter.models.v1.Tag

class TagRepositoryTest : FunSpec({

    lateinit var db: Surreal
    lateinit var repository: SurrealTagRepository

    beforeEach {
        db = Surreal()
        db.connect("memory")
        db.useNs("test").useDb("test")
        SchemaMigrator(db).migrate()
        repository = SurrealTagRepository(db)
    }

    afterEach {
        db.close()
    }

    context("listTags") {

        test("returns all tags from database") {
            db.query(
                """
                CREATE tag:a SET name = 'Tag A', color = 4278190335, placement = { x: 0, y: 0, width: 2, height: 1 };
                CREATE tag:b SET name = 'Tag B', color = 16711935, placement = { x: 5, y: 5, width: 3, height: 2 };
                CREATE tag:c SET name = 'Tag C', color = 65535, placement = { x: 10, y: 10, width: 1, height: 1 };
            """.trimIndent()
            )

            val tags = repository.listTags()

            tags shouldHaveSize 3
            tags.map { it.name } shouldContainExactlyInAnyOrder listOf("Tag A", "Tag B", "Tag C")
        }

        test("returns tags with parent relationships resolved") {
            db.query(
                """
                CREATE tag:parent SET name = 'Parent', color = 4278190335, placement = { x: 0, y: 0, width: 2, height: 1 };
                CREATE tag:child SET name = 'Child', color = 16711935, placement = { x: 5, y: 5, width: 3, height: 2 };
                RELATE tag:child->inherits->tag:parent;
            """.trimIndent()
            )

            val tags = repository.listTags()

            tags shouldHaveSize 2
            val child = tags.find { it.name == "Child" }
            child.shouldNotBeNull()
            child.parents shouldHaveSize 1
            child.parents.first().name shouldBe "Parent"
        }

        test("returns empty list when no tags exist") {
            val tags = repository.listTags()

            tags.shouldBeEmpty()
        }
    }

    context("getTag") {

        test("returns existing tag by ID") {
            db.query(
                """
                CREATE tag:abc123 SET name = 'Test Tag', color = 2864434397, placement = { x: 1, y: 2, width: 3, height: 4 };
            """.trimIndent()
            )

            val tag = repository.getTag("abc123").shouldNotBeNull()

            tag.id shouldBe "abc123"
            tag.name shouldBe "Test Tag"
            tag.color!!.value shouldBe 0xAABBCCDD.toUInt()
            tag.placement!!.x shouldBe 1
            tag.placement!!.y shouldBe 2
            tag.placement!!.width shouldBe 3
            tag.placement!!.height shouldBe 4
        }

        test("returns null for non-existent ID") {
            val tag = repository.getTag("nonexistent")

            tag.shouldBeNull()
        }
    }

    context("createTag") {

        test("creates tag and returns it with generated ID") {
            val placement = Placement { x = 5; y = 10; width = 2; height = 1 }

            val tag = repository.createTag("New Tag", 0xFF0000FF.toInt(), emptyList(), placement)

            tag.shouldNotBeNull()
            tag.id.shouldNotBeNull()
            tag.name shouldBe "New Tag"
            tag.color!!.value shouldBe 0xFF0000FF.toUInt()
            tag.placement!!.x shouldBe 5
            tag.placement!!.y shouldBe 10
            tag.placement!!.width shouldBe 2
            tag.placement!!.height shouldBe 1

            val dbResult = db.query("SELECT VALUE name FROM tag WHERE name = 'New Tag'")
            val storedTag = dbResult.take(0)
            storedTag.array.map { it.string } shouldHaveSingleElement "New Tag"
        }

        test("creates tag with parent relationships") {
            db.query(
                """
                CREATE tag:parent SET name = 'Parent', color = 4278190335, placement = { x: 0, y: 0, width: 2, height: 1 };
            """.trimIndent()
            )
            val placement = Placement { x = 0; y = 0; width = 1; height = 1 }

            val tag = repository.createTag("Child", 0x00FF00FF, listOf("parent"), placement)

            tag.shouldNotBeNull()
            tag.parents shouldHaveSize 1
            tag.parents.first().id shouldBe "parent"

            val inheritResult =
                db.queryBind(
                    $$"SELECT VALUE ->inherits->tag FROM ONLY type::thing('tag', $id)",
                    mapOf("id" to tag.id)
                )
            val inheritValue = inheritResult.take(0)
            inheritValue.array.map { it.thing.id.string } shouldContainExactlyInAnyOrder listOf("parent")
        }
    }

    context("updateTag") {

        test("updates all tag fields") {
            db.query(
                """
                CREATE tag:update_test SET name = 'Old Name', color = 286331153, placement = { x: 0, y: 0, width: 1, height: 1 };
            """.trimIndent()
            )

            val updatedTag = Tag {
                id = "update_test"
                name = "New Name"
                color = Color { value = 0x22222222.toUInt() }
                placement = Placement { x = 10; y = 20; width = 5; height = 3 }
            }

            val result = repository.updateTag(updatedTag)

            result.name shouldBe "New Name"
            result.color!!.value shouldBe 0x22222222.toUInt()
            result.placement!!.x shouldBe 10
            result.placement!!.y shouldBe 20
            result.placement!!.width shouldBe 5
            result.placement!!.height shouldBe 3

            val dbResult = db.query("SELECT VALUE name FROM tag:update_test")
            val stored = dbResult.take(0)
            stored.array.map { it.string } shouldHaveSingleElement "New Name"
        }

        test("updates parent relationships") {
            db.query(
                """
                CREATE tag:parent_a SET name = 'Parent A', color = 4278190335, placement = { x: 0, y: 0, width: 1, height: 1 };
                CREATE tag:parent_b SET name = 'Parent B', color = 16711935, placement = { x: 0, y: 0, width: 1, height: 1 };
                CREATE tag:child SET name = 'Child', color = 65535, placement = { x: 0, y: 0, width: 1, height: 1 };
                RELATE tag:child->inherits->tag:parent_a;
            """.trimIndent()
            )

            val parentB = Tag { id = "parent_b"; name = "Parent B"; color = Color { value = 0x00FF00FF.toUInt() } }
            val updatedTag = Tag {
                id = "child"
                name = "Child"
                color = Color { value = 0x0000FFFF.toUInt() }
                placement = Placement { x = 0; y = 0; width = 1; height = 1 }
                parents = listOf(parentB)
            }

            val result = repository.updateTag(updatedTag)

            result.parents shouldHaveSize 1
            result.parents.first().id shouldBe "parent_b"

            val inheritResult = db.query("SELECT VALUE ->inherits->tag FROM ONLY tag:child")
            val inheritValue = inheritResult.take(0)
            val ids = inheritValue.array.map { it.thing.id.string }
            ids shouldContainExactlyInAnyOrder listOf("parent_b")
            ids shouldNotContain "parent_a"
        }
    }

    context("deleteTag") {

        test("removes tag from database") {
            db.query(
                """
                CREATE tag:to_delete SET name = 'Delete Me', color = 4278190335, placement = { x: 0, y: 0, width: 1, height: 1 };
            """.trimIndent()
            )

            val result = repository.deleteTag("to_delete")

            result shouldBe true

            val dbResult = db.query("record::exists(tag:to_delete)")
            dbResult.take(0).boolean shouldBe false
        }

        test("returns false for non-existent ID") {
            val result = repository.deleteTag("nonexistent")

            result shouldBe false
        }

        test("removes orphaned inherits relationships") {
            db.query(
                """
                CREATE tag:parent SET name = 'Parent', color = 4278190335, placement = { x: 0, y: 0, width: 1, height: 1 };
                CREATE tag:child SET name = 'Child', color = 16711935, placement = { x: 0, y: 0, width: 1, height: 1 };
                RELATE tag:child->inherits->tag:parent;
            """.trimIndent()
            )

            repository.deleteTag("parent")

            val inheritResult = db.query("SELECT VALUE id FROM inherits WHERE out = tag:parent")
            val inheritValue = inheritResult.take(0)
            inheritValue.array.shouldBeEmpty()
        }
    }

    context("moveTag") {

        test("updates x and y coordinates") {
            db.query(
                """
                CREATE tag:move_test SET name = 'Move Me', color = 4278190335, placement = { x: 0, y: 0, width: 5, height: 3 };
            """.trimIndent()
            )

            val result = repository.moveTag("move_test", 10, 20)

            result shouldBe true

            val tag = repository.getTag("move_test")
            tag.shouldNotBeNull()
            tag.placement!!.x shouldBe 10
            tag.placement!!.y shouldBe 20
            tag.placement!!.width shouldBe 5
            tag.placement!!.height shouldBe 3
        }
    }

    context("resizeTag") {

        test("updates width and height") {
            db.query(
                """
                CREATE tag:resize_test SET name = 'Resize Me', color = 4278190335, placement = { x: 5, y: 10, width: 1, height: 1 };
            """.trimIndent()
            )

            val result = repository.resizeTag("resize_test", 8, 4)

            result shouldBe true

            val tag = repository.getTag("resize_test")
            tag.shouldNotBeNull()
            tag.placement!!.x shouldBe 5
            tag.placement!!.y shouldBe 10
            tag.placement!!.width shouldBe 8
            tag.placement!!.height shouldBe 4
        }
    }
})
