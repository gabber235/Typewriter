package com.typewritermc.imprint.gradle

import com.typewritermc.imprint.TypewriterEngineCapabilityReference
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

/**
 * Adds the `typewriter` DSL, target derived source sets, deterministic manifests, and development publication tasks.
 *
 * Each project must declare exactly one engine, engine capability, or extension. Configuration fails early when versions,
 * transitive capabilities, or source relationships are invalid.
 */
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
                declaration.capabilities.forEach { capability ->
                    task.logger.lifecycle("Typewriter engine capability ${capability.id} ${capability.version}")
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
            TypewriterProjectKind.ENGINE_CAPABILITY -> "engine_capability"
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

/** Entry point for declaring the single Typewriter artifact produced by a Gradle project. */
open class TypewriterProjectExtension(
    private val project: Project,
) {
    private val declarations = mutableListOf<ProjectDeclaration>()

    /** Declares an execution engine and every capability it completely implements. */
    fun engine(action: Action<EngineDeclaration>) {
        add(EngineDeclaration(), action)
    }

    /** Declares a composable engine capability and its transitive requirements. */
    fun engineCapability(action: Action<EngineCapabilityDeclaration>) {
        add(EngineCapabilityDeclaration(), action)
    }

    /** Declares one extension release and the runtime targets it compiles against. */
    fun extension(action: Action<ExtensionDeclaration>) {
        val declaration = ExtensionDeclaration()
        add(declaration, action)
        project.configureExtensionProject(declaration.toModel())
    }

    internal fun declaration(): TypewriterProjectDeclaration {
        if (declarations.size != 1) {
            throw GradleException(
                "A project using Imprint must declare exactly one engine, engine capability, or extension.",
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

/** Shared identifier and Semantic Versioning contract for Imprint declarations. */
sealed class ProjectDeclaration(
    private val kind: TypewriterProjectKind,
) {
    var id: String = ""
    var version: String = ""
    private val capabilities = mutableListOf<TypewriterEngineCapabilityReference>()

    protected fun configureCapabilities(action: Action<EngineCapabilities>) {
        val configuredCapabilities = EngineCapabilities()
        action.execute(configuredCapabilities)
        capabilities += configuredCapabilities.references
    }

    internal fun toModel(): TypewriterProjectDeclaration {
        if (id.isBlank()) {
            throw GradleException("The Typewriter project id must not be blank.")
        }
        validateVersion(version, "Typewriter project")

        return TypewriterProjectDeclaration(kind, id, version, capabilities.toList(), targets())
    }

    protected open fun targets(): List<TypewriterRuntimeTarget> = emptyList()
}

/** Configures an execution engine artifact and its complete capability set. */
open class EngineDeclaration : ProjectDeclaration(TypewriterProjectKind.ENGINE) {
    /** Selects capabilities implemented by this engine. Requirements resolve transitively. */
    fun implements(action: Action<EngineCapabilities>) {
        configureCapabilities(action)
    }
}

/** Configures one independently versioned engine capability artifact. */
open class EngineCapabilityDeclaration : ProjectDeclaration(TypewriterProjectKind.ENGINE_CAPABILITY) {
    /** Selects capabilities required for this capability contract to function. */
    fun requires(action: Action<EngineCapabilities>) {
        configureCapabilities(action)
    }
}

/** Configures one extension JAR that may contribute code to several runtime targets. */
open class ExtensionDeclaration : ProjectDeclaration(TypewriterProjectKind.EXTENSION) {
    private val configuredTargets = mutableListOf<TypewriterRuntimeTarget>()

    /** Selects actual runtime targets. Capability source sets are derived automatically from engine targets. */
    fun targets(action: Action<ExtensionTargets>) {
        val targets = ExtensionTargets()
        action.execute(targets)
        configuredTargets += targets.targets
    }

    override fun targets(): List<TypewriterRuntimeTarget> = configuredTargets.toList()
}

/** Collects the Realm, panel, and explicit engine contracts supported by an extension. */
open class ExtensionTargets {
    internal val targets = mutableListOf<TypewriterRuntimeTarget>()

    /** Adds Realm owned code compatible from [version] until the next major Realm API version. */
    fun realm(version: String) {
        add(TypewriterRuntimeTargetKind.REALM, "realm", version)
    }

    /** Adds panel engine code compatible from [version] until the next major panel API version. */
    fun panel(version: String) {
        add(TypewriterRuntimeTargetKind.PANEL, "panel", version)
    }

    /** Adds code for one explicit execution engine and derives all of that engine's transitive capabilities. */
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

/** Collects complete engine capability requirements for an engine or another capability. */
open class EngineCapabilities {
    internal val references = mutableListOf<TypewriterEngineCapabilityReference>()

    /** Requires one capability at this minimum compatible version within the same major version. */
    fun capability(
        id: String,
        version: String,
    ) {
        if (id.isBlank()) {
            throw GradleException("The engine capability id must not be blank.")
        }
        validateVersion(version, "Engine capability $id")
        references += TypewriterEngineCapabilityReference(id, version)
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
