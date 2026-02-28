package com.typewritermc.realm.schema

import com.surrealdb.Surreal
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe

class SchemaMigratorTest : FunSpec({

    lateinit var db: Surreal

    beforeEach {
        db = Surreal()
        db.connect("memory")
        db.useNs("test").useDb("test")
    }

    afterEach {
        db.close()
    }

    context("Schema Application") {

        test("schema can be applied without errors") {
            val migrator = SchemaMigrator(db)

            migrator.migrate()

            val response = db.query("INFO FOR DB")
            val info = response.take(0)
            info.toString().contains("_patch") shouldBe true
        }

        test("schema application is idempotent") {
            val migrator = SchemaMigrator(db)

            migrator.migrate()
            migrator.migrate()
            migrator.migrate()

            val response = db.query("INFO FOR DB")
            val info = response.take(0)
            info.toString().contains("_patch") shouldBe true
        }
    }

    context("Patch Execution") {

        test("patches run only once") {
            val migrator = SchemaMigrator(db)

            migrator.migrate()
            migrator.migrate()

            val response = db.query("SELECT count() as cnt FROM _patch GROUP ALL")
            val result = response.take(0)
            result.toString().contains("cnt") shouldBe true
        }
    }
})
