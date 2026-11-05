package com.typewritermc.realm

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContain
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import java.io.File

val RealmPackageBoundariesTest by testSuite {
    test("every Realm package is declared") {
        realmSources().map { it.pkg }.toSet() shouldBe ALLOWED.keys
    }

    test("allowed Realm package references are acyclic") {
        cycleIn(ALLOWED) shouldBe null
    }

    test("cycle detection finds a cycle") {
        cycleIn(mapOf("a" to setOf("b"), "b" to setOf("c"), "c" to setOf("a"))) shouldBe listOf("a", "b", "c", "a")
        cycleIn(mapOf("a" to setOf("a"))) shouldNotBe null
        cycleIn(mapOf("a" to setOf("b"), "b" to setOf())) shouldBe null
    }

    test("Realm packages reference only the declared packages below them") {
        val undeclared =
            ALLOWED.flatMap { (pkg, allowed) ->
                (allowed - ALLOWED.keys).map { "$pkg allows undeclared package $it" }
            }
        val violations =
            realmSources().flatMap { source ->
                (source.references - source.pkg - ALLOWED.getValue(source.pkg)).map {
                    "${source.file.path}: ${source.pkg} references $it"
                }
            }
        undeclared + violations shouldBe emptyList()
    }

    test("reference detection reads imports and qualified names in code only") {
        val text =
            """
            package com.typewritermc.realm.storage

            import com.typewritermc.realm.catalog.Catalog

            // com.typewritermc.realm.edit.Edit
            /* com.typewritermc.realm.search.Search */
            val url = "surrealkv://database" + com.typewritermc.realm.SURREALDB_SERVER_VERSION
            val plan = com.typewritermc.realm.checking.CheckPlan()
            """.trimIndent()

        realmReferences(text) shouldBe setOf("catalog", ROOT, "checking")
        realmReferences("val x = com.typewritermc.realm.databaseConfiguration()") shouldContain ROOT
    }

    test("Realm sources use no wildcard imports of Realm packages") {
        realmSources()
            .filter {
                it.file.readText().contains(
                    Regex("""import com\.typewritermc\.realm.*\.\*"""),
                )
            }.map { it.file.path } shouldBe
            emptyList()
    }
}
