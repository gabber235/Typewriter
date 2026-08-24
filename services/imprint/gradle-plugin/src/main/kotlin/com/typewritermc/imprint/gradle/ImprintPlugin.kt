package com.typewritermc.imprint.gradle

import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ArtifactKind
import com.typewritermc.imprint.ArtifactVersion
import com.typewritermc.imprint.COMMON_SOURCE_PART
import com.typewritermc.imprint.VersionConstraint
import org.gradle.api.Action
import org.gradle.api.GradleException
import org.gradle.api.Plugin
import org.gradle.api.Project

const val ENGINE_CORE_CONFIGURATION = "imprintEngineCore"
const val EXTENSION_API_CONFIGURATION = "imprintExtensionApi"
const val HOST_API_CONFIGURATION = "imprintHostApi"
const val PROCESSORS_CONFIGURATION = "imprintProcessors"

/** Configures one canonical engine, capability, or extension artifact. */
class ImprintPlugin : Plugin<Project> {
    override fun apply(project: Project) {
        project.pluginManager.apply("java-library")
        project.pluginManager.apply("com.google.devtools.ksp")
        project.createDependencyBuckets()

        val typewriter =
            project.extensions.create("typewriter", TypewriterProjectExtension::class.java, project)
        project.tasks.register("typewriterInfo") { task ->
            task.group = "typewriter"
            task.description = "Prints the configured Typewriter artifact declaration."
            task.doLast {
                val declaration = typewriter.declaration()
                task.logger.lifecycle(
                    "Typewriter ${declaration.kind.name.lowercase()} ${declaration.id} ${declaration.version}",
                )
            }
        }
    }
}

private fun Project.createDependencyBuckets() {
    listOf(
        ENGINE_CORE_CONFIGURATION,
        EXTENSION_API_CONFIGURATION,
        HOST_API_CONFIGURATION,
        PROCESSORS_CONFIGURATION,
    ).forEach { name ->
        configurations.maybeCreate(name).apply {
            isCanBeConsumed = false
            isCanBeResolved = false
            description = "Dependencies supplied to Imprint through $name."
        }
    }
}

/** Entry point for declaring the single artifact produced by one Gradle project. */
open class TypewriterProjectExtension(
    private val project: Project,
) {
    private val declarations = mutableListOf<ArtifactDeclaration>()

    fun engine(action: Action<EngineDeclaration>) {
        val declaration = EngineDeclaration()
        add(declaration, action)
        project.configureEngineProject(declaration.toModel())
    }

    fun realm(action: Action<RealmDeclaration>) {
        val declaration = RealmDeclaration()
        add(declaration, action)
        project.configureRealmProject(declaration.toModel())
    }

    fun engineCapability(action: Action<EngineCapabilityDeclaration>) {
        val declaration = EngineCapabilityDeclaration()
        add(declaration, action)
        project.configureCapabilityProject(declaration.toModel())
    }

    fun extension(action: Action<ExtensionDeclaration>) {
        val declaration = ExtensionDeclaration()
        add(declaration, action)
        project.configureExtensionProject(declaration.toModel())
    }

    internal fun declaration(): DeclaredArtifact {
        if (declarations.size != 1) {
            throw GradleException(
                "A project using Imprint must declare exactly one Realm, engine, engine capability, or extension.",
            )
        }
        return declarations.single().toModel()
    }

    private fun <T : ArtifactDeclaration> add(
        declaration: T,
        action: Action<T>,
    ) {
        action.execute(declaration)
        if (declarations.isNotEmpty()) {
            throw GradleException(
                "A project using Imprint must declare exactly one Realm, engine, engine capability, or extension.",
            )
        }
        declarations += declaration
    }
}

sealed class ArtifactDeclaration(
    private val kind: ArtifactKind,
) {
    var id: String = ""
    var version: String = ""

    internal open fun relationships(): List<DeclaredRelationship> = emptyList()

    internal open fun sourceParts(): List<DeclaredSourcePart> = emptyList()

    internal open fun hostApi(): VersionConstraint? = null

    internal fun toModel(): DeclaredArtifact {
        val artifactId = validated("Typewriter artifact id") { ArtifactId(id) }
        val artifactVersion = validated("Typewriter artifact version") { ArtifactVersion(version) }
        return DeclaredArtifact(kind, artifactId, artifactVersion, hostApi(), relationships(), sourceParts())
    }
}

open class RealmDeclaration : HostedArtifactDeclaration(ArtifactKind.REALM)

sealed class HostedArtifactDeclaration(
    kind: ArtifactKind,
) : ArtifactDeclaration(kind) {
    var hostApi: String = ""

    internal override fun hostApi(): VersionConstraint = validatedConstraint(hostApi, "Host API")
}

open class EngineDeclaration : HostedArtifactDeclaration(ArtifactKind.ENGINE) {
    private val capabilities = mutableListOf<DeclaredRelationship>()

    fun implements(action: Action<EngineCapabilities>) {
        capabilities += EngineCapabilities.configured(action).relationships
    }

    internal override fun relationships(): List<DeclaredRelationship> = capabilities.toList()
}

open class EngineCapabilityDeclaration : ArtifactDeclaration(ArtifactKind.CAPABILITY) {
    private val capabilities = mutableListOf<DeclaredRelationship>()

    fun requires(action: Action<EngineCapabilities>) {
        capabilities += EngineCapabilities.configured(action).relationships
    }

    internal override fun relationships(): List<DeclaredRelationship> = capabilities.toList()
}

open class ExtensionDeclaration : ArtifactDeclaration(ArtifactKind.EXTENSION) {
    private val configuredSourceParts = mutableListOf<DeclaredSourcePart>()

    fun sourceSet(
        name: String,
        action: Action<ExtensionSourceSetDeclaration>,
    ) {
        validateSourcePartName(name)
        if (configuredSourceParts.any { it.name == name }) {
            throw GradleException("Extension source set $name is declared more than once.")
        }
        val declaration = ExtensionSourceSetDeclaration(name)
        action.execute(declaration)
        configuredSourceParts += declaration.toModel()
    }

    internal override fun sourceParts(): List<DeclaredSourcePart> = configuredSourceParts.toList().also(::validateDeclaredIncludes)
}

open class ExtensionSourceSetDeclaration internal constructor(
    private val name: String,
) {
    private var engine: DeclaredRelationship? = null
    private val capabilities = mutableListOf<DeclaredRelationship>()
    private val includedSourceParts = mutableListOf<String>()

    /** Makes code from the named source parts available when this source part is selected. */
    fun includes(vararg sourceSets: String) {
        sourceSets.forEach { sourceSet ->
            validateSourcePartName(sourceSet)
            if (sourceSet == name) throw GradleException("Extension source set $name cannot include itself.")
            if (sourceSet in includedSourceParts) {
                throw GradleException("Extension source set $name includes $sourceSet more than once.")
            }
            includedSourceParts += sourceSet
        }
    }

    fun engine(
        dependency: Any,
        version: String,
    ) {
        if (engine != null) throw GradleException("Extension source set $name may target only one engine.")
        if (capabilities.isNotEmpty()) {
            throw GradleException("Extension source set $name cannot target an engine and capabilities.")
        }
        engine = DeclaredRelationship(dependency, validatedConstraint(version, "Engine target"))
    }

    fun capabilities(action: Action<EngineCapabilities>) {
        if (engine != null) {
            throw GradleException("Extension source set $name cannot target an engine and capabilities.")
        }
        capabilities += EngineCapabilities.configured(action).relationships
    }

    internal fun toModel(): DeclaredSourcePart {
        val selectedEngine = engine
        if (selectedEngine != null) return DeclaredEngineSourcePart(name, selectedEngine, includedSourceParts.toList())
        if (capabilities.isNotEmpty()) {
            return DeclaredCapabilitySourcePart(name, capabilities.toList(), includedSourceParts.toList())
        }
        throw GradleException("Extension source set $name must target one engine or at least one capability.")
    }
}

open class EngineCapabilities {
    internal val relationships = mutableListOf<DeclaredRelationship>()

    fun capability(
        dependency: Any,
        version: String,
    ) {
        relationships += DeclaredRelationship(dependency, validatedConstraint(version, "Capability requirement"))
    }

    internal companion object {
        fun configured(action: Action<EngineCapabilities>): EngineCapabilities = EngineCapabilities().also(action::execute)
    }
}

internal data class DeclaredArtifact(
    val kind: ArtifactKind,
    val id: ArtifactId,
    val version: ArtifactVersion,
    val hostApi: VersionConstraint?,
    val relationships: List<DeclaredRelationship>,
    val sourceParts: List<DeclaredSourcePart>,
)

internal data class DeclaredRelationship(
    val dependency: Any,
    val version: VersionConstraint,
)

internal sealed interface DeclaredSourcePart {
    val name: String
    val relationships: List<DeclaredRelationship>
    val includes: List<String>
}

internal data class DeclaredEngineSourcePart(
    override val name: String,
    val engine: DeclaredRelationship,
    override val includes: List<String>,
) : DeclaredSourcePart {
    override val relationships: List<DeclaredRelationship> = listOf(engine)
}

internal data class DeclaredCapabilitySourcePart(
    override val name: String,
    override val relationships: List<DeclaredRelationship>,
    override val includes: List<String>,
) : DeclaredSourcePart

private fun validateSourcePartName(name: String) {
    if (name == COMMON_SOURCE_PART) throw GradleException("Extension source set common is reserved by Imprint.")
    if (!name.matches(Regex("[A-Za-z][A-Za-z0-9_]*"))) {
        throw GradleException("Extension source set $name must be a valid Gradle source set name.")
    }
}

private fun validateDeclaredIncludes(sourceParts: List<DeclaredSourcePart>) {
    val partsByName = sourceParts.associateBy(DeclaredSourcePart::name)
    sourceParts.forEach { sourcePart ->
        sourcePart.includes.forEach { includedName ->
            if (includedName !in partsByName) {
                throw GradleException("Extension source set ${sourcePart.name} includes unknown source set $includedName.")
            }
        }
    }

    val visiting = mutableListOf<String>()
    val visited = mutableSetOf<String>()

    fun visit(name: String) {
        if (name in visiting) {
            throw GradleException("Cyclic extension source set inclusion: ${(visiting + name).joinToString(" > ")}.")
        }
        if (!visited.add(name)) return

        visiting += name
        partsByName.getValue(name).includes.forEach(::visit)
        visiting.removeLast()
    }
    sourceParts.forEach { visit(it.name) }
}

private fun validatedConstraint(
    value: String,
    subject: String,
): VersionConstraint = validated("$subject version") { VersionConstraint(value) }

private fun <T> validated(
    subject: String,
    create: () -> T,
): T =
    try {
        create()
    } catch (exception: IllegalArgumentException) {
        throw GradleException("$subject is invalid: ${exception.message}", exception)
    }
