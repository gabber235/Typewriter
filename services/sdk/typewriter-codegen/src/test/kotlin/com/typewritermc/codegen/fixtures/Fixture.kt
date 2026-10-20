package com.typewritermc.codegen.fixtures

import java.nio.file.Path
import kotlin.io.path.isDirectory
import kotlin.io.path.listDirectoryEntries
import kotlin.io.path.name
import kotlin.io.path.nameWithoutExtension
import kotlin.io.path.readLines

/**
 * One fixture compilation: a single file or a directory of files under `src/test/fixtures/<group>`.
 *
 * Rejected fixtures mark each expected error with `// error: <message>` at the end of the line it must be reported
 * on; several markers may share a line. Accepted fixtures may define `fixture.main(args)`, which runs after compilation.
 */
class Fixture(
    val name: String,
    val files: List<Path>,
) {
    val expectedErrors: List<ExpectedError> =
        files.flatMap { file ->
            file.readLines().flatMapIndexed { index, line ->
                MARKER.findAll(line).map { ExpectedError(file.name, index + 1, it.groupValues[1].trim()) }.toList()
            }
        }

    override fun toString(): String = name

    companion object {
        private val MARKER = Regex("""// error: (.+?)(?= // error: |$)""")

        fun all(group: String): List<Fixture> =
            Path.of("src/test/fixtures", group).listDirectoryEntries().sorted().map { entry ->
                Fixture(entry.nameWithoutExtension, if (entry.isDirectory()) entry.listDirectoryEntries("*.kt").sorted() else listOf(entry))
            }
    }
}

/** An error expected at a fixture position. Messages match by containment, so compiler errors can name their key part. */
data class ExpectedError(
    val file: String,
    val line: Int,
    val message: String,
) {
    override fun toString(): String = "$file:$line   $message"
}

/** An error the compilation reported. Errors without a location have an empty [file] and line zero. */
data class ReportedError(
    val file: String,
    val line: Int,
    val message: String,
) {
    fun matches(expected: ExpectedError): Boolean = file == expected.file && line == expected.line && expected.message in message

    override fun toString(): String = "$file:$line   $message"
}
