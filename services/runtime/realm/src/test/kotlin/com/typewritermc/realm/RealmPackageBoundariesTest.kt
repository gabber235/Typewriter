package com.typewritermc.realm

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import java.io.File

/**
 * Each Realm package may import only the packages listed here; the map is acyclic, so the Realm has no package
 * cycles. Kotlin needs an import for every reference to another package (no wildcard or qualified uses exist,
 * and this test rejects wildcards), so reading imports is exact.
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
private val REALM_IMPORT = Regex("""^import com\.typewritermc\.realm\.(\w+)""", RegexOption.MULTILINE)
private val ROOT_IMPORT = Regex("""^import com\.typewritermc\.realm\.[A-Z_]""", RegexOption.MULTILINE)

private class RealmSource(
    val file: File,
    val pkg: String,
    val imports: Set<String>,
)

private fun realmSources(): List<RealmSource> =
    File("src/main/kotlin/com/typewritermc/realm")
        .walkTopDown()
        .filter { it.extension == "kt" }
        .map { file ->
            val text = file.readText()
            val pkg =
                Regex(
                    """^package com\.typewritermc\.realm(?:\.(\w+))?""",
                    RegexOption.MULTILINE,
                ).find(text)!!.groupValues[1].ifEmpty { ROOT }
            val imports =
                REALM_IMPORT
                    .findAll(text)
                    .map { it.groupValues[1] }
                    .filter { it.first().isLowerCase() }
                    .toSet() +
                    (if (ROOT_IMPORT.containsMatchIn(text)) setOf(ROOT) else emptySet())
            RealmSource(file, pkg, imports)
        }.toList()

val RealmPackageBoundariesTest by testSuite {
    test("every Realm package is declared") {
        realmSources().map { it.pkg }.toSet() shouldBe ALLOWED.keys
    }

    test("Realm packages import only the packages below them") {
        val violations =
            realmSources().flatMap { source ->
                (source.imports - source.pkg - ALLOWED.getValue(source.pkg)).map { "${source.file.path}: ${source.pkg} imports $it" }
            }
        violations shouldBe emptyList()
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
