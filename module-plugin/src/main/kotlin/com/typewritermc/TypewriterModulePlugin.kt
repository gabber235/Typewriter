package com.typewritermc

import com.google.devtools.ksp.gradle.KspExtension
import com.typewritermc.moduleplugin.TypewriterModuleConfiguration
import com.typewritermc.moduleplugin.validate
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import org.gradle.api.GradleException
import org.gradle.api.Plugin
import org.gradle.api.Project
import java.util.*

class TypewriterModulePlugin : Plugin<Project> {
    override fun apply(project: Project) {
        project.pluginManager.apply("com.google.devtools.ksp")

        val extension = project.extensions.create("typewriter", TypewriterModuleConfiguration::class.java)

        project.registerKsp(extension)
        project.afterEvaluate {
            project.checkModuleConfiguration(extension)

            project.registerRepositories(extension)
        }
    }

    /**
     * Checks if the extension is valid.
     */
    private fun Project.checkModuleConfiguration(module: TypewriterModuleConfiguration) {
        if (module.namespace.isBlank() && module.flags.isEmpty() && module.engine == null && module.extension == null) {
            logger.warn("No extension configuration found in module $name. The typewriter plugin will not work.")
            return
        }
        try {
            module.validate()
        } catch (e: Exception) {
            throw GradleException("Invalid module configuration for $name", e)
        }
    }

    /**
     * Registers repositories that are required for typewriter to work.
     */
    private fun Project.registerRepositories(extension: TypewriterModuleConfiguration) {
        // Add Maven Central repository
        repositories.mavenCentral()

        // Add PacketEvents repository
        repositories.maven {
            it.setUrl("https://repo.codemc.io/repository/maven-releases/")
        }
        // Add EntityLib repository
        repositories.maven {
            it.setUrl("https://maven.evokegames.gg/snapshots")
        }

        // Configure dependencies for extensions
        extension.extension?.let { extension ->
            // Add Typewriter repository
            extension.channel.url?.let { url ->
                repositories.maven {
                    it.setUrl(url)
                }
            }
            val engineVersion = extension.engineVersion.substringBefore("-beta")
            // Add Typewriter core dependency
            dependencies.add("compileOnly", "com.typewritermc:engine-core:${engineVersion}")

            extension.paper?.let { paper ->
                // Add Typewriter Paper dependency
                dependencies.add("compileOnly", "com.typewritermc:engine-paper:${engineVersion}")
                // Add Paper repository
                repositories.maven {
                    it.setUrl("https://repo.papermc.io/repository/maven-public/")
                }
                // Add Geyser repository
                repositories.maven {
                    it.setUrl("https://repo.opencollab.dev/main/")
                }
            }
        }
    }

    private fun Project.registerKsp(configuration: TypewriterModuleConfiguration) {
        val pluginVersion = getModulePluginVersion()
        dependencies.add("ksp", "com.typewritermc.module-plugin:extension-processor:$pluginVersion")

        afterEvaluate {
            extensions.configure(KspExtension::class.java) {
                it.arg(
                    "configuration",
                    Base64.getEncoder().encodeToString(Json.encodeToString(configuration).toByteArray())
                )
                it.arg("pluginVersion", pluginVersion)
                it.arg("version", version.toString())
                it.arg("buildDir", buildDir.absolutePath)
            }
        }
    }

    private fun getModulePluginVersion(): String {
        val props = Properties().apply {
            this@TypewriterModulePlugin::class.java.classLoader.getResourceAsStream("typewriter-module-plugin.properties")
                ?.use { stream ->
                    load(stream)
                } ?: throw IllegalStateException("Could not load properties")
        }
        val version = props.getProperty("version")
        return version ?: "0.0.0"
    }
}