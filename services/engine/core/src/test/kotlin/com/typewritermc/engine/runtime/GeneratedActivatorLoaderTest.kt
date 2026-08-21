package com.typewritermc.engine.runtime

import com.typewritermc.extensions.ExtensionActivation
import com.typewritermc.extensions.ExtensionActivationContext
import com.typewritermc.extensions.ExtensionActivator
import com.typewritermc.imprint.TypewriterActivatorReference
import com.typewritermc.imprint.TypewriterExtensionManifest
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainExactly
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.cbor.Cbor
import kotlinx.serialization.encodeToByteArray
import java.net.URLClassLoader
import java.nio.file.Files

@OptIn(ExperimentalSerializationApi::class)
val GeneratedActivatorLoaderTest by testSuite {
    test("loads deterministic generated activator indexes") {
        runTest {
            val root = Files.createTempDirectory("generated-activators")
            val manifest = Files.createDirectories(root.resolve("META-INF/typewriter")).resolve("extension.cbor")
            Files.write(
                manifest,
                Cbor.Default.encodeToByteArray(
                    TypewriterExtensionManifest(
                        id = "typewritermc:test",
                        version = "1.0.0",
                        targets = listOf("common"),
                        layers = emptyList(),
                        activators =
                            listOf(
                                TypewriterActivatorReference(
                                    sourceSet = "common",
                                    id = "test",
                                    className = requireNotNull(IndexedTestActivator::class.qualifiedName),
                                ),
                            ),
                    ),
                ),
            )
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
