package com.typewritermc.realm.repository

import com.surrealdb.Surreal
import com.typewritermc.realm.repository.utils.TransactionException
import com.typewritermc.realm.schema.SchemaMigrator
import com.typewritermc.services.libs.telemetry.testing.MockTelemetry
import com.typewritermc.services.libs.utils.asDeferredProvider
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
    val tracer = MockTelemetry.createMockTracer()

    beforeEach {
        db = Surreal()
        db.connect("memory")
        db.useNs("test").useDb("test")
        SchemaMigrator(db, tracer).migrate()
        repository = SurrealTagRepository(db.asDeferredProvider())
    }

    afterEach {
        db.close()
    }

    context("listTags") {

        test("returns all tags from database") {
            db.query(
                """
                CREATE tag:a SET name = 'tag_a', color = 4278190335, placement = { x: 0, y: 0, width: 2, height: 1 };
                CREATE tag:b SET name = 'tag_b', color = 16711935, placement = { x: 5, y: 5, width: 3, height: 2 };
                CREATE tag:c SET name = 'tag_c', color = 65535, placement = { x: 10, y: 10, width: 1, height: 1 };
            """.trimIndent()
            )

            val tags = repository.listTags()

            tags shouldHaveSize 3
            tags.map { it.name } shouldContainExactlyInAnyOrder listOf("tag_a", "tag_b", "tag_c")
        }

        test("returns tags with parent relationships resolved") {
            db.query(
                """
                CREATE tag:parent SET name = 'parent', color = 4278190335, placement = { x: 0, y: 0, width: 2, height: 1 };
                CREATE tag:child SET name = 'child', color = 16711935, placement = { x: 5, y: 5, width: 3, height: 2 };
                RELATE tag:child->inherits->tag:parent;
            """.trimIndent()
            )

            val tags = repository.listTags()

            tags shouldHaveSize 2
            val child = tags.find { it.name == "child" }
            child.shouldNotBeNull()
            child.parentIds shouldHaveSize 1
            child.parentIds.first() shouldBe "parent"
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
                CREATE tag:abc123 SET name = 'test_tag', color = 2864434397, placement = { x: 1, y: 2, width: 3, height: 4 };
            """.trimIndent()
            )

            val tag = repository.getTag("abc123").shouldNotBeNull()

            tag.tagId shouldBe "abc123"
            tag.name shouldBe "test_tag"
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

            val tag = repository.createTag("new_tag", 0xFF0000FF.toInt(), emptyList(), placement)

            tag.shouldNotBeNull()
            tag.tagId.shouldNotBeNull()
            tag.name shouldBe "new_tag"
            tag.color!!.value shouldBe 0xFF0000FF.toUInt()
            tag.placement!!.x shouldBe 5
            tag.placement!!.y shouldBe 10
            tag.placement!!.width shouldBe 2
            tag.placement!!.height shouldBe 1

            val dbResult = db.query("SELECT VALUE name FROM tag WHERE name = 'new_tag'")
            val storedTag = dbResult.take(0)
            storedTag.array.map { it.string } shouldHaveSingleElement "new_tag"
        }

        test("creates tag with default placement values when zeros are provided") {
            val placement = Placement { x = 0; y = 0; width = 3; height = 1 }

            val tag = repository.createTag("defaults_tag", 0xFF0000FF.toInt(), emptyList(), placement)

            tag.shouldNotBeNull()
            tag.placement!!.x shouldBe 0
            tag.placement!!.y shouldBe 0
            tag.placement!!.width shouldBe 3
            tag.placement!!.height shouldBe 1
        }

        test("creates tag with parent relationships") {
            db.query(
                """
                CREATE tag:parent SET name = 'parent', color = 4278190335, placement = { x: 0, y: 0, width: 2, height: 1 };
            """.trimIndent()
            )
            val placement = Placement { x = 0; y = 0; width = 1; height = 1 }

            val tag = repository.createTag("child", 0x00FF00FF, listOf("parent"), placement)

            tag.shouldNotBeNull()
            tag.parentIds shouldHaveSize 1
            tag.parentIds.first() shouldBe "parent"

            val inheritResult =
                db.queryBind(
                    $$"SELECT VALUE ->inherits->tag FROM ONLY type::thing('tag', $id)",
                    mapOf("id" to tag.tagId)
                )
            val inheritValue = inheritResult.take(0)
            inheritValue.array.map { it.thing.id.string } shouldContainExactlyInAnyOrder listOf("parent")
        }

        test("uses default placement values when fields are null") {
            val placement = Placement {}

            val tag = repository.createTag("defaults_tag", 0xFF0000FF.toInt(), emptyList(), placement)

            tag.shouldNotBeNull()
            tag.placement.shouldNotBeNull()
            tag.placement!!.x shouldBe 0
            tag.placement!!.y shouldBe 0
            tag.placement!!.width shouldBe 3
            tag.placement!!.height shouldBe 1
        }
    }

    context("updateTag") {

        test("updates all tag fields") {
            db.query(
                """
                CREATE tag:update_test SET name = 'old_name', color = 286331153, placement = { x: 0, y: 0, width: 1, height: 1 };
            """.trimIndent()
            )

            val updatedTag = Tag {
                tagId = "update_test"
                name = "new_name"
                color = Color { value = 0x22222222.toUInt() }
                placement = Placement { x = 10; y = 20; width = 5; height = 3 }
            }

            val result = repository.updateTag(updatedTag)

            result.name shouldBe "new_name"
            result.color!!.value shouldBe 0x22222222.toUInt()
            result.placement!!.x shouldBe 10
            result.placement!!.y shouldBe 20
            result.placement!!.width shouldBe 5
            result.placement!!.height shouldBe 3

            val dbResult = db.query("SELECT VALUE name FROM tag:update_test")
            val stored = dbResult.take(0)
            stored.array.map { it.string } shouldHaveSingleElement "new_name"
        }

        test("keeps values even when update has default values") {
            db.query(
                """
                CREATE tag:update_test SET name = 'old_name', color = 286331153, placement = { x: 10, y: 10, width: 1, height: 1 };
            """.trimIndent()
            )

            val updatedTag = Tag {
                tagId = "update_test"
                name = ""
                color = Color { value = 0.toUInt() }
                placement = Placement { x = 0; y = 0; width = 1; height = 1 }
            }

            val result = repository.updateTag(updatedTag)

            result.name shouldBe ""
            result.color!!.value shouldBe 0.toUInt()
            result.placement!!.x shouldBe 0
            result.placement!!.y shouldBe 0
            result.placement!!.width shouldBe 1
            result.placement!!.height shouldBe 1

            val dbResult = db.query("SELECT VALUE name FROM tag:update_test")
            val stored = dbResult.take(0)
            stored.array.filter { it.isString }.map { it.string } shouldHaveSingleElement ""
        }

        test("throws an error when tag does not exist") {
            val updatedTag = Tag {
                tagId = "nonexistent"
                name = "nonexistent_tag"
                color = Color { value = 0xFF0000FF.toUInt() }
                placement = Placement { x = 0; y = 0; width = 1; height = 1 }
            }

            val exception = io.kotest.assertions.throwables.shouldThrow<TransactionException> {
                repository.updateTag(updatedTag)
            }

            exception.shouldNotBeNull()
        }

        test("updates parent relationships") {
            db.query(
                """
                CREATE tag:parent_a SET name = 'parent_a', color = 4278190335, placement = { x: 0, y: 0, width: 1, height: 1 };
                CREATE tag:parent_b SET name = 'parent_b', color = 16711935, placement = { x: 0, y: 0, width: 1, height: 1 };
                CREATE tag:child SET name = 'child', color = 65535, placement = { x: 0, y: 0, width: 1, height: 1 };
                RELATE tag:child->inherits->tag:parent_a;
            """.trimIndent()
            )

            val updatedTag = Tag {
                tagId = "child"
                name = "child"
                color = Color { value = 0x0000FFFF.toUInt() }
                placement = Placement { x = 0; y = 0; width = 1; height = 1 }
                parentIds = listOf("parent_b")
            }

            val result = repository.updateTag(updatedTag)

            result.parentIds shouldHaveSize 1
            result.parentIds.first() shouldBe "parent_b"

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
                CREATE tag:to_delete SET name = 'delete_me', color = 4278190335, placement = { x: 0, y: 0, width: 1, height: 1 };
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
                CREATE tag:parent SET name = 'parent', color = 4278190335, placement = { x: 0, y: 0, width: 1, height: 1 };
                CREATE tag:child SET name = 'child', color = 16711935, placement = { x: 0, y: 0, width: 1, height: 1 };
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
                CREATE tag:move_test SET name = 'move_me', color = 4278190335, placement = { x: 0, y: 0, width: 5, height: 3 };
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

        test("updates only x when y is null") {
            db.query(
                """
                CREATE tag:move_x SET name = 'move_x', color = 4278190335, placement = { x: 5, y: 10, width: 3, height: 2 };
            """.trimIndent()
            )

            val result = repository.moveTag("move_x", 99, null)

            result shouldBe true

            val tag = repository.getTag("move_x").shouldNotBeNull()
            tag.placement!!.x shouldBe 99
            tag.placement!!.y shouldBe 10
        }

        test("updates only y when x is null") {
            db.query(
                """
                CREATE tag:move_y SET name = 'move_y', color = 4278190335, placement = { x: 5, y: 10, width: 3, height: 2 };
            """.trimIndent()
            )

            val result = repository.moveTag("move_y", null, 42)

            result shouldBe true

            val tag = repository.getTag("move_y").shouldNotBeNull()
            tag.placement!!.x shouldBe 5
            tag.placement!!.y shouldBe 42
        }

        test("keeps both coordinates when both are null") {
            db.query(
                """
                CREATE tag:move_none SET name = 'move_none', color = 4278190335, placement = { x: 7, y: 13, width: 3, height: 2 };
            """.trimIndent()
            )

            val result = repository.moveTag("move_none", null, null)

            result shouldBe true

            val tag = repository.getTag("move_none").shouldNotBeNull()
            tag.placement!!.x shouldBe 7
            tag.placement!!.y shouldBe 13
        }
    }

    context("resizeTag") {

        test("updates width and height") {
            db.query(
                """
                CREATE tag:resize_test SET name = 'resize_me', color = 4278190335, placement = { x: 5, y: 10, width: 1, height: 1 };
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

        test("updates only width when height is null") {
            db.query(
                """
                CREATE tag:resize_w SET name = 'resize_w', color = 4278190335, placement = { x: 0, y: 0, width: 2, height: 5 };
            """.trimIndent()
            )

            val result = repository.resizeTag("resize_w", 10, null)

            result shouldBe true

            val tag = repository.getTag("resize_w").shouldNotBeNull()
            tag.placement!!.width shouldBe 10
            tag.placement!!.height shouldBe 5
        }

        test("updates only height when width is null") {
            db.query(
                """
                CREATE tag:resize_h SET name = 'resize_h', color = 4278190335, placement = { x: 0, y: 0, width: 3, height: 2 };
            """.trimIndent()
            )

            val result = repository.resizeTag("resize_h", null, 8)

            result shouldBe true

            val tag = repository.getTag("resize_h").shouldNotBeNull()
            tag.placement!!.width shouldBe 3
            tag.placement!!.height shouldBe 8
        }
    }

    context("name validation") {

        test("accepts valid lowercase name") {
            db.query("CREATE tag:valid SET name = 'valid_tag_123', color = 4278190335, placement = { x: 0, y: 0, width: 1, height: 1 };")

            val tag = repository.getTag("valid")
            tag.shouldNotBeNull()
            tag.name shouldBe "valid_tag_123"
        }

        test("accepts empty name") {
            db.query("CREATE tag:empty SET name = '', color = 4278190335, placement = { x: 0, y: 0, width: 1, height: 1 };")

            val tag = repository.getTag("empty")
            tag.shouldNotBeNull()
            tag.name shouldBe ""
        }

        test("rejects name with uppercase letters") {
            io.kotest.assertions.throwables.shouldThrow<com.surrealdb.SurrealException> {
                db.query("CREATE tag:upper SET name = 'Invalid', color = 4278190335, placement = { x: 0, y: 0, width: 1, height: 1 };")
                    .take(0)
            }
        }

        test("rejects name with spaces") {
            io.kotest.assertions.throwables.shouldThrow<com.surrealdb.SurrealException> {
                db.query("CREATE tag:spaces SET name = 'has space', color = 4278190335, placement = { x: 0, y: 0, width: 1, height: 1 };")
                    .take(0)
            }
        }

        test("rejects name with special characters") {
            io.kotest.assertions.throwables.shouldThrow<com.surrealdb.SurrealException> {
                db.query("CREATE tag:special SET name = 'tag-name', color = 4278190335, placement = { x: 0, y: 0, width: 1, height: 1 };")
                    .take(0)
            }
        }
    }

    context("placement validation") {

        test("rejects zero width") {
            io.kotest.assertions.throwables.shouldThrow<com.surrealdb.SurrealException> {
                db.query("CREATE tag:zw SET name = 'zero_width', color = 4278190335, placement = { x: 0, y: 0, width: 0, height: 1 };")
                    .take(0)
            }
        }

        test("rejects zero height") {
            io.kotest.assertions.throwables.shouldThrow<com.surrealdb.SurrealException> {
                db.query("CREATE tag:zh SET name = 'zero_height', color = 4278190335, placement = { x: 0, y: 0, width: 1, height: 0 };")
                    .take(0)
            }
        }

        test("rejects negative width") {
            io.kotest.assertions.throwables.shouldThrow<com.surrealdb.SurrealException> {
                db.query("CREATE tag:nw SET name = 'neg_width', color = 4278190335, placement = { x: 0, y: 0, width: -1, height: 1 };")
                    .take(0)
            }
        }

        test("rejects negative height") {
            io.kotest.assertions.throwables.shouldThrow<com.surrealdb.SurrealException> {
                db.query("CREATE tag:nh SET name = 'neg_height', color = 4278190335, placement = { x: 0, y: 0, width: 1, height: -1 };")
                    .take(0)
            }
        }

        test("accepts positive width and height") {
            db.query("CREATE tag:pos SET name = 'positive', color = 4278190335, placement = { x: 0, y: 0, width: 5, height: 3 };")

            val tag = repository.getTag("pos")
            tag.shouldNotBeNull()
            tag.placement!!.width shouldBe 5
            tag.placement!!.height shouldBe 3
        }
    }
})
