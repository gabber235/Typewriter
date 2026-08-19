package com.typewritermc.engine.runtime

import com.typewritermc.extensions.ExtensionActivation
import com.typewritermc.extensions.ExtensionActivationContext
import com.typewritermc.extensions.ExtensionActivator
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainExactly
import kotlinx.coroutines.test.runTest
import java.net.URLClassLoader
import java.nio.file.Files

val GeneratedActivatorLoaderTest by testSuite {
    test("loads deterministic generated activator indexes") {
        runTest {
            val root = Files.createTempDirectory("generated-activators")
            val index = Files.createDirectories(root.resolve("META-INF/typewriter/activators")).resolve("common.index")
            Files.writeString(index, "${IndexedTestActivator::class.qualifiedName}\n")
            val classLoader = URLClassLoader(arrayOf(root.toUri().toURL()), IndexedTestActivator::class.java.classLoader)

            val activators = GeneratedActivatorLoader().load(classLoader, listOf("common"))

            activators.map { it::class } shouldContainExactly listOf(IndexedTestActivator::class)
            classLoader.close()
        }
    }
}

class IndexedTestActivator : ExtensionActivator {
    override fun activate(context: ExtensionActivationContext): ExtensionActivation = ExtensionActivation {}
}
