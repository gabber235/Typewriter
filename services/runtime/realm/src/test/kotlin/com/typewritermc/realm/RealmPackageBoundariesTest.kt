package com.typewritermc.realm

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContain
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import java.io.File

/**
 * Each Realm package may reference only the packages listed here, and this test checks that the map is acyclic,
 * so the Realm has no package cycles. References are read from imports and from fully qualified names in code
 * (comments and the package line are ignored), and wildcard imports are rejected, so reading them is exact.
 */
private val ALLOWED: Map<String, Set<String>> =
    mapOf(
        "storage" to setOf(),
        "catalog" to setOf(),
        "authoring" to setOf("catalog"),
        "search" to setOf("authoring", "catalog", "storage"),
        "checking" to setOf("authoring", "catalog"),
        "edit" to setOf("authoring", "catalog", "search", "storage"),
        "operation" to setOf("edit", "checking", "authoring", "catalog"),
        "publication" to setOf("checking", "authoring", "catalog", "storage"),
        "routes" to setOf("operation", "publication", "edit", "checking", "search", "authoring", "catalog"),
        ROOT to setOf("routes", "operation", "publication", "edit", "checking", "search", "authoring", "catalog", "storage"),
    )

private const val ROOT = "(root)"
private val PACKAGE_LINE = Regex("""^package com\.typewritermc\.realm(?:\.(\w+))?""", RegexOption.MULTILINE)
private val IMPORT_LINE = Regex("""^import com\.typewritermc\.realm\.(\w+)""", RegexOption.MULTILINE)
private val HEADER_LINE = Regex("""^(?:package|import) .*$""", RegexOption.MULTILINE)
private val QUALIFIED_REFERENCE = Regex("""(?<![\w.])com\.typewritermc\.realm\.(\w+)""")

/** Strings are matched only so that comment markers inside them are not mistaken for comments. */
private val COMMENT_OR_STRING = Regex("\"\"\"[\\s\\S]*?\"\"\"|\"(?:\\\\.|[^\"\\\\\\n])*\"|//[^\\n]*|/\\*[\\s\\S]*?\\*/")

private class RealmSource(
    val file: File,
    val pkg: String,
    val references: Set<String>,
)

/** A first segment naming a declared package refers to that package; any other names a root declaration. */
private fun realmPackageOf(segment: String): String = if (segment in ALLOWED.keys) segment else ROOT

/** Realm packages that [text] references through imports or fully qualified names in code. */
private fun realmReferences(text: String): Set<String> {
    val code =
        COMMENT_OR_STRING
            .replace(text) { if (it.value.startsWith("/")) it.value.replace(Regex("[^\\n]"), " ") else it.value }
    val imports = IMPORT_LINE.findAll(code).map { it.groupValues[1] }
    val qualified = QUALIFIED_REFERENCE.findAll(HEADER_LINE.replace(code, "")).map { it.groupValues[1] }
    return (imports + qualified).map(::realmPackageOf).toSet()
}

private fun realmSources(): List<RealmSource> =
    File("src/main/kotlin/com/typewritermc/realm")
        .walkTopDown()
        .filter { it.extension == "kt" }
        .map { file ->
            val text = file.readText()
            val pkg = PACKAGE_LINE.find(text)!!.groupValues[1].ifEmpty { ROOT }
            RealmSource(file, pkg, realmReferences(text))
        }.toList()

/** One cycle in [graph] as the path that closes it, or null when [graph] is acyclic. */
private fun cycleIn(graph: Map<String, Set<String>>): List<String>? {
    val finished = mutableSetOf<String>()
    val path = mutableListOf<String>()

    fun visit(node: String): List<String>? {
        if (node in finished) return null
        val start = path.indexOf(node)
        if (start >= 0) return path.subList(start, path.size) + node
        path += node
        for (next in graph[node].orEmpty().sorted()) {
            visit(next)?.let { return it }
        }
        path.removeLast()
        finished += node
        return null
    }

    return graph.keys.sorted().firstNotNullOfOrNull(::visit)
}

val RealmPackageBoundariesTest by testSuite {
    test("every Realm package is declared") {
        realmSources().map { it.pkg }.toSet() shouldBe ALLOWED.keys
    }

    test("allowed Realm package references name only declared packages") {
        (ALLOWED.values.flatten().toSet() - ALLOWED.keys) shouldBe emptySet()
    }

    test("allowed Realm package references are acyclic") {
        cycleIn(ALLOWED) shouldBe null
    }

    test("cycle detection finds a cycle") {
        cycleIn(mapOf("a" to setOf("b"), "b" to setOf("c"), "c" to setOf("a"))) shouldBe listOf("a", "b", "c", "a")
        cycleIn(mapOf("a" to setOf("a"))) shouldNotBe null
        cycleIn(mapOf("a" to setOf("b"), "b" to setOf())) shouldBe null
    }

    test("Realm packages reference only the packages below them") {
        val violations =
            realmSources().flatMap { source ->
                (source.references - source.pkg - ALLOWED.getValue(source.pkg)).map {
                    "${source.file.path}: ${source.pkg} references $it"
                }
            }
        violations shouldBe emptyList()
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
