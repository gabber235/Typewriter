package com.typewritermc.fixtures

import com.typewritermc.expression.renderCanonicalReadSchema
import com.typewritermc.expression.renderExpressionCorpus
import com.typewritermc.library.frameworkControlFixtures
import com.typewritermc.presentation.presentationControlFixtures
import java.nio.file.Path
import kotlin.io.path.createDirectories
import kotlin.io.path.writeBytes
import kotlin.io.path.writeText

/**
 * Writes the fixtures other hosts read from the SDK; tests only read and assert them. The `writeSdkFixtures` Gradle
 * task runs it with three paths:
 *
 * 1. the committed canonical read schema, which the panel compares with its own derivation,
 * 2. the directory for the compiled control fixtures, which the panel's fixture tool embeds,
 * 3. the expression differential corpus, build output in the operation fixture format.
 */
fun main(args: Array<String>) {
    require(args.size == 3) { "Expected the read schema file, the control fixture directory and the corpus file." }
    val (readSchema, controls, corpus) = args.map(Path::of)
    readSchema.writeText(renderCanonicalReadSchema())
    controls.createDirectories()
    (frameworkControlFixtures() + presentationControlFixtures()).forEach { (name, bytes) -> controls.resolve(name).writeBytes(bytes) }
    corpus.parent.createDirectories()
    corpus.writeText(renderExpressionCorpus())
}
