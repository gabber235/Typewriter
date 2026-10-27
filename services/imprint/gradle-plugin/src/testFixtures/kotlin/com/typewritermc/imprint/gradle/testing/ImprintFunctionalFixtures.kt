package com.typewritermc.imprint.gradle.testing

import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ArtifactVersion
import com.typewritermc.imprint.CapabilityManifest
import com.typewritermc.imprint.HostedRuntimeEntrypointMetadata
import com.typewritermc.imprint.HostedRuntimeEntrypointMetadataCodec
import com.typewritermc.imprint.IMPRINT_MANIFEST_PATH
import com.typewritermc.imprint.IMPRINT_RUNTIME_ENTRYPOINTS_PATH
import com.typewritermc.imprint.ImprintManifest
import com.typewritermc.imprint.ImprintManifestCodec
import org.gradle.testkit.runner.GradleRunner
import java.io.File
import java.nio.file.Files
import java.util.zip.ZipEntry
import java.util.zip.ZipFile
import java.util.zip.ZipOutputStream

fun fixture(vararg projects: String): FunctionalFixture {
    val directory = Files.createTempDirectory("imprint-functional-test").toFile()
    val includes = projects.joinToString("\n") { "include(\":$it\")" }
    directory.resolve("settings.gradle.kts").writeText(
        """
        pluginManagement { repositories { gradlePluginPortal(); mavenCentral() } }
        dependencyResolutionManagement { repositories { mavenCentral() } }
        rootProject.name = "fixture"
        $includes
        """.trimIndent(),
    )
    projects.forEach { directory.resolve(it).mkdirs() }
    return FunctionalFixture(directory)
}

class FunctionalFixture(
    private val directory: File,
) {
    fun writeBuild(content: String) = write("build.gradle.kts", content)

    fun writeBuild(
        project: String,
        content: String,
    ) = write("$project/build.gradle.kts", content)

    fun write(
        path: String,
        content: String,
    ) {
        directory.resolve(path).apply {
            parentFile.mkdirs()
            writeText(content)
        }
    }

    fun writeRuntimeEntrypoints(
        project: String,
        vararg classes: String,
    ) {
        writeBytes(
            "$project/build/generated/ksp/main/resources/$IMPRINT_RUNTIME_ENTRYPOINTS_PATH",
            HostedRuntimeEntrypointMetadataCodec.encode(HostedRuntimeEntrypointMetadata(classes.toList())),
        )
    }

    fun writeBytes(
        path: String,
        content: ByteArray,
    ) {
        directory.resolve(path).apply {
            parentFile.mkdirs()
            writeBytes(content)
        }
    }

    fun build(
        content: String,
        expectFailure: Boolean = false,
    ): org.gradle.testkit.runner.BuildResult {
        writeBuild(content)
        return run("typewriterInfo", expectFailure)
    }

    fun run(
        task: String,
        expectFailure: Boolean = false,
    ): org.gradle.testkit.runner.BuildResult {
        val runner =
            GradleRunner
                .create()
                .withProjectDir(directory)
                .withArguments(task, "--stacktrace", "--no-build-cache")
                .withPluginClasspath()
        return if (expectFailure) runner.buildAndFail() else runner.build()
    }

    fun manifestBytes(project: String = ""): ByteArray =
        directory
            .resolve(if (project.isBlank()) "build" else "$project/build")
            .resolve("generated/imprint/artifact.cbor")
            .readBytes()

    fun singleJar(path: String): File =
        directory.resolve(path).listFiles { file -> file.extension == "jar" }?.single()
            ?: error("Expected one JAR in $path")

    fun publishCapability(
        group: String,
        module: String,
        version: String,
        artifactId: String,
    ) {
        val moduleDirectory = directory.resolve("repository/${group.replace('.', '/')}/$module/$version")
        moduleDirectory.mkdirs()
        val manifest =
            CapabilityManifest(
                id = ArtifactId(artifactId),
                version = ArtifactVersion(version),
                directRequirements = emptyList(),
                resolvedCapabilities = emptyList(),
                contributions = emptyList(),
            )
        ZipOutputStream(moduleDirectory.resolve("$module-$version.jar").outputStream()).use { archive ->
            archive.putNextEntry(ZipEntry(IMPRINT_MANIFEST_PATH))
            archive.write(ImprintManifestCodec.encode(manifest))
            archive.closeEntry()
        }
        moduleDirectory.resolve("$module-$version.pom").writeText(
            """
            <project>
                <modelVersion>4.0.0</modelVersion>
                <groupId>$group</groupId>
                <artifactId>$module</artifactId>
                <version>$version</version>
            </project>
            """.trimIndent(),
        )
        val metadataDirectory = moduleDirectory.parentFile
        metadataDirectory.resolve("maven-metadata.xml").writeText(
            """
            <metadata>
                <groupId>$group</groupId>
                <artifactId>$module</artifactId>
                <versioning>
                    <latest>$version</latest>
                    <release>$version</release>
                    <versions><version>$version</version></versions>
                </versioning>
            </metadata>
            """.trimIndent(),
        )
    }
}

fun capabilityBuild(
    id: String,
    dependencies: String = "",
    requires: String = "",
): String =
    """
    plugins { id("com.typewritermc.imprint") }
    $dependencies
    typewriter {
        engineCapability {
            id = "$id"
            version = "1.0.0"
            ${if (requires.isBlank()) "" else "requires { $requires }"}
        }
    }
    """.trimIndent()

fun javaLibraryBuild(): String = "plugins { `java-library` }"

fun extensionWithCapability(dependency: String): String =
    """
    plugins { id("com.typewritermc.imprint") }
    typewriter {
        extension {
            id = "typewritermc:quests"
            version = "1.0.0"
            sourceSet("target") {
                capabilities { capability($dependency, version = "^1") }
            }
        }
    }
    """.trimIndent()

fun javaType(
    packageName: String,
    name: String,
): String = "package $packageName; public class $name {}"

fun File.readManifest(): ImprintManifest =
    ZipFile(this).use { archive ->
        ImprintManifestCodec.decode(archive.getInputStream(archive.getEntry(IMPRINT_MANIFEST_PATH)).readBytes())
    }

fun File.entries(): List<String> =
    ZipFile(this).use { archive ->
        archive
            .entries()
            .asSequence()
            .map { it.name }
            .toList()
    }
