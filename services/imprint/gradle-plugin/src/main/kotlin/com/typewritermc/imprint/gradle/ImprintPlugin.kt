package com.typewritermc.imprint.gradle

import com.typewritermc.imprint.TypewriterProjectDeclaration
import com.typewritermc.imprint.TypewriterProjectKind
import org.gradle.api.Action
import org.gradle.api.GradleException
import org.gradle.api.Plugin
import org.gradle.api.Project

class ImprintPlugin : Plugin<Project> {
    override fun apply(project: Project) {
        val typewriter = project.extensions.create("typewriter", TypewriterProjectExtension::class.java)

        project.tasks.register("typewriterInfo") { task ->
            task.group = "typewriter"
            task.description = "Prints the configured Typewriter project declaration."
            task.doLast {
                val declaration = typewriter.declaration()
                task.logger.lifecycle(
                    "Typewriter ${declaration.kind.displayName} ${declaration.id} ${declaration.version}",
                )
            }
        }

        project.afterEvaluate {
            typewriter.declaration()
        }
    }
}

open class TypewriterProjectExtension {
    private val declarations = mutableListOf<ProjectDeclaration>()

    fun engine(action: Action<EngineDeclaration>) {
        add(EngineDeclaration(), action)
    }

    fun engineLayer(action: Action<EngineLayerDeclaration>) {
        add(EngineLayerDeclaration(), action)
    }

    fun extension(action: Action<ExtensionDeclaration>) {
        add(ExtensionDeclaration(), action)
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

    internal fun toModel(): TypewriterProjectDeclaration {
        if (id.isBlank()) {
            throw GradleException("The Typewriter project id must not be blank.")
        }
        if (version.isBlank()) {
            throw GradleException("The Typewriter project version must not be blank.")
        }

        return TypewriterProjectDeclaration(kind, id, version)
    }
}

open class EngineDeclaration : ProjectDeclaration(TypewriterProjectKind.ENGINE)

open class EngineLayerDeclaration : ProjectDeclaration(TypewriterProjectKind.ENGINE_LAYER)

open class ExtensionDeclaration : ProjectDeclaration(TypewriterProjectKind.EXTENSION)
