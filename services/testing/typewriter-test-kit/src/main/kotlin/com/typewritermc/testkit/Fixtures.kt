package com.typewritermc.testkit

import java.nio.file.Files
import java.nio.file.Path

/**
 * The first directory named [path] on the way up from the working directory, such as `skir-src/editor/v1/fixtures`.
 * Fixtures shared with other stacks live under the repository root, so tests find them from any module.
 */
fun repositoryFixture(path: String): Path =
    generateSequence(Path.of("").toAbsolutePath()) { it.parent }
        .map { it.resolve(path) }
        .first(Files::isDirectory)
