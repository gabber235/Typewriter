package com.typewritermc.imprint.gradle

import com.typewritermc.imprint.TypewriterEngineLayerReference
import com.typewritermc.imprint.TypewriterProjectDeclaration
import com.typewritermc.imprint.TypewriterProjectKind
import com.typewritermc.imprint.TypewriterRuntimeTarget
import com.typewritermc.imprint.TypewriterRuntimeTargetKind
import io.github.z4kn4fein.semver.toVersionOrNull
import org.gradle.api.Action
import org.gradle.api.GradleException
import org.gradle.api.Plugin
import org.gradle.api.Project
import org.gradle.api.tasks.Copy
import org.gradle.jvm.tasks.Jar

class ImprintPlugin : Plugin<Project> {
    override fun apply(project: Project) {
        project.pluginManager.apply("com.google.devtools.ksp")
        val typewriter =
            project.extensions.create("typewriter", TypewriterProjectExtension::class.java, project)

        project.tasks.register("typewriterInfo") { task ->
            task.group = "typewriter"
            task.description = "Prints the configured Typewriter project declaration."
            task.doLast {
                val declaration = typewriter.declaration()
                task.logger.lifecycle(
                    "Typewriter ${declaration.kind.displayName} ${declaration.id} ${declaration.version}",
                )
                declaration.layers.forEach { layer ->
                    task.logger.lifecycle("Typewriter engine layer ${layer.id} ${layer.version}")
                }
                declaration.targets.forEach { target ->
                    task.logger.lifecycle("Typewriter target ${target.kind.name.lowercase()} ${target.id} ${target.version}")
                }
            }
        }

        project.afterEvaluate {
            val declaration = typewriter.declaration()
            project.pluginManager.withPlugin("java") {
                project.registerDevelopmentArtifact(declaration)
            }
        }
    }
}

private fun Project.registerDevelopmentArtifact(declaration: TypewriterProjectDeclaration) {
    val artifactType =
        when (declaration.kind) {
            TypewriterProjectKind.ENGINE -> if (declaration.id == "panel") "panel_engine" else "execution_engine"
            TypewriterProjectKind.ENGINE_LAYER -> "engine_layer"
            TypewriterProjectKind.EXTENSION -> "extension"
        }
    val publishedName = "${declaration.id}__${declaration.version}__$artifactType.jar"
    val jar = tasks.named("jar", Jar::class.java)
    tasks.register("publishDevArtifact", Copy::class.java) { task ->
        task.group = "development"
        task.description = "Publishes this Typewriter artifact for local development."
        task.from(jar.flatMap(Jar::getArchiveFile)) { copy -> copy.rename { publishedName } }
        task.into(rootProject.layout.projectDirectory.dir("../build/development/artifacts"))
    }
}

open class TypewriterProjectExtension(
    private val project: Project,
) {
    private val declarations = mutableListOf<ProjectDeclaration>()

    fun engine(action: Action<EngineDeclaration>) {
        add(EngineDeclaration(), action)
    }

    fun engineLayer(action: Action<EngineLayerDeclaration>) {
        add(EngineLayerDeclaration(), action)
    }

    fun extension(action: Action<ExtensionDeclaration>) {
        val declaration = ExtensionDeclaration()
        add(declaration, action)
        project.configureExtensionProject(declaration.toModel())
    }

    internal fun declaration(): TypewriterProjectDeclaration {
        if (declarations.size != 1) {
            throw GradleException(
                "A project using Imprint must declare exactly one engine, engine layer, or extension.",
            )
        }

        return declarations.single().toModel()
    }

    private fun <T : ProjectDeclaration> add(
        declaration: T,
        action: Action<T>,
    ) {
        action.execute(declaration)
        declarations += declaration
    }
}

sealed class ProjectDeclaration(
    private val kind: TypewriterProjectKind,
) {
    var id: String = ""
    var version: String = ""
    private val layers = mutableListOf<TypewriterEngineLayerReference>()

    protected fun configureLayers(action: Action<EngineLayers>) {
        val configuredLayers = EngineLayers()
        action.execute(configuredLayers)
        layers += configuredLayers.references
    }

    internal fun toModel(): TypewriterProjectDeclaration {
        if (id.isBlank()) {
            throw GradleException("The Typewriter project id must not be blank.")
        }
        validateVersion(version, "Typewriter project")

        return TypewriterProjectDeclaration(kind, id, version, layers.toList(), targets())
    }

    protected open fun targets(): List<TypewriterRuntimeTarget> = emptyList()
}

open class EngineDeclaration : ProjectDeclaration(TypewriterProjectKind.ENGINE) {
    fun implements(action: Action<EngineLayers>) {
        configureLayers(action)
    }
}

open class EngineLayerDeclaration : ProjectDeclaration(TypewriterProjectKind.ENGINE_LAYER) {
    fun requires(action: Action<EngineLayers>) {
        configureLayers(action)
    }
}

open class ExtensionDeclaration : ProjectDeclaration(TypewriterProjectKind.EXTENSION) {
    private val configuredTargets = mutableListOf<TypewriterRuntimeTarget>()

    fun targets(action: Action<ExtensionTargets>) {
        val targets = ExtensionTargets()
        action.execute(targets)
        configuredTargets += targets.targets
    }

    override fun targets(): List<TypewriterRuntimeTarget> = configuredTargets.toList()
}

open class ExtensionTargets {
    internal val targets = mutableListOf<TypewriterRuntimeTarget>()

    fun realm(version: String) {
        add(TypewriterRuntimeTargetKind.REALM, "realm", version)
    }

    fun panel(version: String) {
        add(TypewriterRuntimeTargetKind.PANEL, "panel", version)
    }

    fun engine(
        id: String,
        version: String,
    ) {
        add(TypewriterRuntimeTargetKind.ENGINE, id, version)
    }

    private fun add(
        kind: TypewriterRuntimeTargetKind,
        id: String,
        version: String,
    ) {
        if (id.isBlank()) {
            throw GradleException("The runtime target id must not be blank.")
        }
        validateVersion(version, "Runtime target $id")
        if (targets.any { it.kind == kind && it.id == id }) {
            throw GradleException("Runtime target $id is declared more than once.")
        }
        targets += TypewriterRuntimeTarget(kind, id, version)
    }
}

open class EngineLayers {
    internal val references = mutableListOf<TypewriterEngineLayerReference>()

    fun layer(
        id: String,
        version: String,
    ) {
        if (id.isBlank()) {
            throw GradleException("The engine layer id must not be blank.")
        }
        validateVersion(version, "Engine layer $id")
        references += TypewriterEngineLayerReference(id, version)
    }
}

private fun validateVersion(
    version: String,
    subject: String,
) {
    if (version.toVersionOrNull(strict = true) == null) {
        throw GradleException("$subject version must use valid semantic version syntax.")
    }
}
