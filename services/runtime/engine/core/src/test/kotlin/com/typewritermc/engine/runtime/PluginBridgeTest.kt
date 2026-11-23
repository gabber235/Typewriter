package com.typewritermc.engine.runtime

import com.typewritermc.engine.runtime.testing.PluginApiStandIn
import com.typewritermc.engine.runtime.testing.pluginClassLoader
import com.typewritermc.engine.runtime.testing.pluginDeploymentContext
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe

val PluginBridgeTest by testSuite {
    val pluginClass = PluginApiStandIn::class.java.name
    val engine = ClassLoader.getPlatformClassLoader()

    test("extension code reaches a plugin's classes through that plugin's class loader when a loaded part uses it") {
        val vault = pluginClassLoader()
        val context = pluginDeploymentContext(loadedParts = setOf("paper", "vault"), enabled = mapOf("Vault" to vault))

        context.extensionClassLoader(engine).loadClass(pluginClass).classLoader shouldBe vault
    }

    test("extension code does not reach a plugin no loaded part uses, even when the host enabled it") {
        val context = pluginDeploymentContext(loadedParts = setOf("paper"), enabled = mapOf("Vault" to pluginClassLoader()))

        shouldThrow<ClassNotFoundException> { context.extensionClassLoader(engine).loadClass(pluginClass) }
    }

    test("a class the engine has resolves from the engine before any plugin") {
        val context = pluginDeploymentContext(loadedParts = setOf("vault"), enabled = mapOf("Vault" to pluginClassLoader()))
        val testClasses = requireNotNull(PluginApiStandIn::class.java.classLoader)

        context.extensionClassLoader(testClasses).loadClass(pluginClass).classLoader shouldBe testClasses
    }

    test("an engine refuses to load a part whose plugin the host no longer enables") {
        val context = pluginDeploymentContext(loadedParts = setOf("vault"), enabled = emptyMap())

        shouldThrow<IllegalStateException> { context.extensionClassLoader(engine) }.message shouldBe
            "Source part vault of fixture:integrations needs the Vault plugin, which this host has not enabled."
    }
}
