package com.typewritermc.imprint.gradle

import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ArtifactKind
import com.typewritermc.imprint.ArtifactVersion
import com.typewritermc.imprint.CapabilityManifest
import com.typewritermc.imprint.EngineManifest
import com.typewritermc.imprint.ExtensionManifest
import com.typewritermc.imprint.IMPRINT_CONTRIBUTIONS_PATH
import com.typewritermc.imprint.IMPRINT_MANIFEST_PATH
import com.typewritermc.imprint.ImprintManifest
import com.typewritermc.imprint.ImprintManifestCodec
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldContain
import io.kotest.matchers.string.shouldNotContain
import org.gradle.testkit.runner.GradleRunner
import java.io.File
import java.nio.file.Files
import java.util.zip.ZipEntry
import java.util.zip.ZipFile
import java.util.zip.ZipOutputStream

val ImprintPluginTest by testSuite {
    test("projects declare exactly one artifact with an exact version") {
        val fixture = fixture()
        fixture
            .build(
                """
                plugins { id("com.typewritermc.imprint") }
                typewriter {
                    engine {
                        id = "paper"
                        version = "1.2.3"
                    }
                }
                """.trimIndent(),
            ).output shouldContain "Typewriter engine paper 1.2.3"

        fixture
            .build(
                """
                plugins { id("com.typewritermc.imprint") }
                typewriter {
                    engine {
                        id = "paper"
                        version = "1"
                    }
                }
                """.trimIndent(),
                expectFailure = true,
            ).output shouldContain "Artifact version must use complete semantic version syntax"
    }

    test("extensions create arbitrary isolated source parts") {
        val fixture = fixture("capability")
        fixture.writeBuild(
            "capability",
            capabilityBuild("typewritermc:items"),
        )
        fixture.writeBuild(
            """
            plugins {
                kotlin("jvm") version "2.4.10"
                id("com.typewritermc.imprint")
            }
            typewriter {
                extension {
                    id = "typewritermc:quests"
                    version = "1.0.0"
                    sourceSet("items") {
                        capabilities {
                            capability(project(":capability"), version = "^1")
                        }
                    }
                }
            }
            """.trimIndent(),
        )

        val output = fixture.run("typewriterSourceSets").output

        output shouldContain "Typewriter source set common"
        output shouldContain "Typewriter source set items"
        output shouldNotContain "realm"
        output shouldNotContain "panel"
    }

    test("extension common receives engine core and extension API") {
        val fixture = fixture("engineCore", "extensionApi")
        fixture.writeBuild("engineCore", javaLibraryBuild())
        fixture.writeBuild("extensionApi", javaLibraryBuild())
        fixture.write("engineCore/src/main/java/fixture/core/CoreType.java", javaType("fixture.core", "CoreType"))
        fixture.write("extensionApi/src/main/java/fixture/api/ApiType.java", javaType("fixture.api", "ApiType"))
        fixture.writeBuild(
            """
            plugins {
                kotlin("jvm") version "2.4.10"
                id("com.typewritermc.imprint")
            }
            dependencies {
                imprintEngineCore(project(":engineCore"))
                imprintExtensionApi(project(":extensionApi"))
            }
            typewriter {
                extension {
                    id = "typewritermc:quests"
                    version = "1.0.0"
                }
            }
            """.trimIndent(),
        )
        fixture.write(
            "src/common/kotlin/fixture/Common.kt",
            "package fixture\nclass Common(val core: fixture.core.CoreType, val api: fixture.api.ApiType)",
        )

        fixture.run("compileCommonKotlin").output shouldNotContain "Unresolved reference"
    }

    test("capability JAR is thin and contains one canonical manifest") {
        val fixture = fixture("core", "capability")
        fixture.writeBuild("core", javaLibraryBuild())
        fixture.write("core/src/main/java/fixture/core/CoreType.java", javaType("fixture.core", "CoreType"))
        fixture.writeBuild(
            "capability",
            capabilityBuild(
                "typewritermc:items",
                dependencies = "dependencies { imprintEngineCore(project(\":core\")) }",
            ),
        )
        fixture.write(
            "capability/src/main/java/fixture/CapabilityCode.java",
            "package fixture; public class CapabilityCode { fixture.core.CoreType core; }",
        )
        fixture.write(
            "capability/build/generated/ksp/main/resources/$IMPRINT_CONTRIBUTIONS_PATH/fixture/entries.cbor",
            "opaque payload",
        )

        fixture.run(":capability:jar")
        val jar = fixture.singleJar("capability/build/libs")
        val manifest = jar.readManifest() as CapabilityManifest

        manifest.id.value shouldBe "typewritermc:items"
        manifest.contributions
            .single()
            .payload
            .decodeToString() shouldBe "opaque payload"
        jar.entries().count { it == IMPRINT_MANIFEST_PATH } shouldBe 1
        jar.entries().any { it.startsWith(IMPRINT_CONTRIBUTIONS_PATH) } shouldBe false
        jar.entries().contains("fixture/core/CoreType.class") shouldBe false
    }

    test("engine Shadow JAR bundles core capabilities and one merged manifest") {
        val fixture = fixture("engineCore", "base", "capability", "engine")
        fixture.writeBuild("engineCore", javaLibraryBuild())
        fixture.write("engineCore/src/main/java/fixture/core/CoreType.java", javaType("fixture.core", "CoreType"))
        fixture.writeBuild("base", capabilityBuild("typewritermc:base"))
        fixture.write("base/src/main/java/fixture/base/BaseType.java", javaType("fixture.base", "BaseType"))
        fixture.writeBuild(
            "capability",
            capabilityBuild(
                "typewritermc:items",
                requires = "capability(project(\":base\"), version = \"~1\")",
            ),
        )
        fixture.write("capability/src/main/java/fixture/items/ItemType.java", javaType("fixture.items", "ItemType"))
        fixture.write(
            "capability/build/generated/ksp/main/resources/$IMPRINT_CONTRIBUTIONS_PATH/fixture/items.cbor",
            "items",
        )
        fixture.writeBuild(
            "engine",
            """
            plugins { id("com.typewritermc.imprint") }
            dependencies { imprintEngineCore(project(":engineCore")) }
            typewriter {
                engine {
                    id = "paper"
                    version = "1.0.0"
                    implements {
                        capability(project(":capability"), version = "^1")
                    }
                }
            }
            """.trimIndent(),
        )
        fixture.write("engine/src/main/java/fixture/paper/PaperEngine.java", javaType("fixture.paper", "PaperEngine"))

        fixture.run(":engine:shadowJar")
        val jar = fixture.singleJar("engine/build/libs")
        val manifest = jar.readManifest() as EngineManifest

        jar.entries().contains("fixture/core/CoreType.class") shouldBe true
        jar.entries().contains("fixture/base/BaseType.class") shouldBe true
        jar.entries().contains("fixture/items/ItemType.class") shouldBe true
        jar.entries().contains("fixture/paper/PaperEngine.class") shouldBe true
        jar.entries().count { it == IMPRINT_MANIFEST_PATH } shouldBe 1
        manifest.resolvedCapabilities.map { it.id.value } shouldContainExactly
            listOf("typewritermc:base", "typewritermc:items")
        manifest.contributions
            .single()
            .payload
            .decodeToString() shouldBe "items"
    }

    test("extension JAR records targets and resolved provenance without bundling them") {
        val fixture = fixture("capability", "extension")
        fixture.writeBuild("capability", capabilityBuild("typewritermc:items"))
        fixture.write("capability/src/main/java/fixture/items/ItemType.java", javaType("fixture.items", "ItemType"))
        fixture.writeBuild(
            "extension",
            """
            plugins {
                kotlin("jvm") version "2.4.10"
                id("com.typewritermc.imprint")
            }
            typewriter {
                extension {
                    id = "typewritermc:quests"
                    version = "2.0.0"
                    sourceSet("items") {
                        capabilities {
                            capability(project(":capability"), version = "^1")
                        }
                    }
                }
            }
            """.trimIndent(),
        )
        fixture.write(
            "extension/src/items/kotlin/fixture/ItemsExtension.kt",
            "package fixture\nclass ItemsExtension(val item: fixture.items.ItemType)",
        )

        fixture.run(":extension:jar")
        val jar = fixture.singleJar("extension/build/libs")
        val manifest = jar.readManifest() as ExtensionManifest

        manifest.sourceParts.map { it.name } shouldContainExactly listOf("common", "items")
        manifest.buildProvenance.single().kind shouldBe ArtifactKind.CAPABILITY
        jar.entries().contains("fixture/ItemsExtension.class") shouldBe true
        jar.entries().contains("fixture/items/ItemType.class") shouldBe false
    }

    test("external Maven artifacts use the same descriptor and constraint path") {
        val fixture = fixture()
        fixture.publishCapability("com.example", "items", "1.4.0", "typewritermc:items")
        fixture.writeBuild(
            """
            plugins { id("com.typewritermc.imprint") }
            repositories { maven { url = uri(rootProject.file("repository")) } }
            typewriter {
                extension {
                    id = "typewritermc:quests"
                    version = "1.0.0"
                    sourceSet("items") {
                        capabilities {
                            capability("com.example:items", version = "^1.3")
                        }
                    }
                }
            }
            """.trimIndent(),
        )

        fixture.run("jar")
        val manifest = fixture.singleJar("build/libs").readManifest() as ExtensionManifest

        manifest.buildProvenance.single().version shouldBe ArtifactVersion("1.4.0")
    }

    test("target relationships reject missing and incorrect manifests") {
        val missing = fixture("plain", "extension")
        missing.writeBuild("plain", javaLibraryBuild())
        missing.write("plain/src/main/java/fixture/Plain.java", javaType("fixture", "Plain"))
        missing.writeBuild("extension", extensionWithCapability("project(\":plain\")"))

        missing.run(":extension:jar", expectFailure = true).output shouldContain
            "does not contain $IMPRINT_MANIFEST_PATH"

        val incorrect = fixture("engine", "extension")
        incorrect.writeBuild(
            "engine",
            """
            plugins { id("com.typewritermc.imprint") }
            typewriter {
                engine {
                    id = "paper"
                    version = "1.0.0"
                }
            }
            """.trimIndent(),
        )
        incorrect.writeBuild("extension", extensionWithCapability("project(\":engine\")"))

        incorrect.run(":extension:jar", expectFailure = true).output shouldContain
            "requires CAPABILITY but paper is ENGINE"
    }

    test("extension source parts reject invalid target combinations") {
        val empty = fixture()
        empty.writeBuild(
            """
            plugins { id("com.typewritermc.imprint") }
            typewriter {
                extension {
                    id = "typewritermc:quests"
                    version = "1.0.0"
                    sourceSet("paper") {}
                }
            }
            """.trimIndent(),
        )
        empty.run("typewriterInfo", expectFailure = true).output shouldContain
            "must target one engine or at least one capability"

        val reserved = fixture()
        reserved.writeBuild(
            """
            plugins { id("com.typewritermc.imprint") }
            typewriter {
                extension {
                    id = "typewritermc:quests"
                    version = "1.0.0"
                    sourceSet("common") {
                        engine("com.example:paper", version = "^1")
                    }
                }
            }
            """.trimIndent(),
        )
        reserved.run("typewriterInfo", expectFailure = true).output shouldContain "common is reserved"
    }

    test("sibling source parts cannot access each other targets") {
        val fixture = fixture("items", "events", "extension")
        fixture.writeBuild("items", capabilityBuild("typewritermc:items"))
        fixture.writeBuild("events", capabilityBuild("typewritermc:events"))
        fixture.write("items/src/main/java/fixture/items/ItemType.java", javaType("fixture.items", "ItemType"))
        fixture.write("events/src/main/java/fixture/events/EventType.java", javaType("fixture.events", "EventType"))
        fixture.writeBuild(
            "extension",
            """
            plugins {
                kotlin("jvm") version "2.4.10"
                id("com.typewritermc.imprint")
            }
            typewriter {
                extension {
                    id = "typewritermc:quests"
                    version = "1.0.0"
                    sourceSet("items") {
                        capabilities { capability(project(":items"), version = "^1") }
                    }
                    sourceSet("events") {
                        capabilities { capability(project(":events"), version = "^1") }
                    }
                }
            }
            """.trimIndent(),
        )
        fixture.write(
            "extension/src/items/kotlin/fixture/Items.kt",
            "package fixture\nclass Items(val event: fixture.events.EventType)",
        )

        fixture.run(":extension:compileItemsKotlin", expectFailure = true).output shouldContain "Unresolved reference"
    }

    test("engine source parts may include capability source parts guaranteed by the engine") {
        val fixture = fixture("minecraft", "paper", "extension")
        fixture.writeBuild("minecraft", capabilityBuild("typewritermc:minecraft"))
        fixture.writeBuild(
            "paper",
            """
            plugins { id("com.typewritermc.imprint") }
            typewriter {
                engine {
                    id = "paper"
                    version = "1.0.0"
                    implements {
                        capability(project(":minecraft"), version = "^1")
                    }
                }
            }
            """.trimIndent(),
        )
        fixture.writeBuild(
            "extension",
            """
            plugins {
                kotlin("jvm") version "2.4.10"
                id("com.typewritermc.imprint")
            }
            typewriter {
                extension {
                    id = "typewritermc:quests"
                    version = "1.0.0"
                    sourceSet("minecraft") {
                        capabilities {
                            capability(project(":minecraft"), version = "^1")
                        }
                    }
                    sourceSet("paper") {
                        engine(project(":paper"), version = "^1")
                        includes("minecraft")
                    }
                }
            }
            """.trimIndent(),
        )
        fixture.write(
            "extension/src/minecraft/kotlin/fixture/MinecraftSupport.kt",
            "package fixture\nclass MinecraftSupport",
        )
        fixture.write(
            "extension/src/paper/kotlin/fixture/PaperSupport.kt",
            "package fixture\nclass PaperSupport(val minecraft: MinecraftSupport)",
        )

        fixture.run(":extension:jar")
        val manifest = fixture.singleJar("extension/build/libs").readManifest() as ExtensionManifest

        manifest.sourceParts.single { it.name == "paper" }.includes shouldContainExactly listOf("minecraft")
    }

    test("included capability source parts require a guaranteed capability superset") {
        val fixture = fixture("minecraft", "events", "extension")
        fixture.writeBuild("minecraft", capabilityBuild("typewritermc:minecraft"))
        fixture.writeBuild("events", capabilityBuild("typewritermc:events"))
        fixture.writeBuild(
            "extension",
            """
            plugins { id("com.typewritermc.imprint") }
            typewriter {
                extension {
                    id = "typewritermc:quests"
                    version = "1.0.0"
                    sourceSet("minecraft") {
                        capabilities {
                            capability(project(":minecraft"), version = "^1")
                        }
                    }
                    sourceSet("events") {
                        capabilities {
                            capability(project(":events"), version = "^1")
                        }
                        includes("minecraft")
                    }
                }
            }
            """.trimIndent(),
        )

        fixture.run(":extension:jar", expectFailure = true).output shouldContain
            "does not guarantee capabilities typewritermc:minecraft"
    }

    test("source part inclusion rejects unknown names and cycles") {
        val unknown = fixture()
        unknown.writeBuild(
            """
            plugins { id("com.typewritermc.imprint") }
            typewriter {
                extension {
                    id = "typewritermc:quests"
                    version = "1.0.0"
                    sourceSet("paper") {
                        engine("com.example:paper", version = "^1")
                        includes("missing")
                    }
                }
            }
            """.trimIndent(),
        )
        unknown.run("typewriterInfo", expectFailure = true).output shouldContain
            "includes unknown source set missing"

        val cyclic = fixture()
        cyclic.writeBuild(
            """
            plugins { id("com.typewritermc.imprint") }
            typewriter {
                extension {
                    id = "typewritermc:quests"
                    version = "1.0.0"
                    sourceSet("first") {
                        engine("com.example:paper", version = "^1")
                        includes("second")
                    }
                    sourceSet("second") {
                        engine("com.example:paper", version = "^1")
                        includes("first")
                    }
                }
            }
            """.trimIndent(),
        )
        cyclic.run("typewriterInfo", expectFailure = true).output shouldContain
            "Cyclic extension source set inclusion: first > second > first"
    }

    test("manifest generation is incremental and path independent") {
        val fixture = fixture()
        fixture.writeBuild(capabilityBuild("typewritermc:items"))

        fixture.run("jar")
        val second = fixture.run("jar").output

        second shouldContain ":generateImprintManifest UP-TO-DATE"
    }

    test("DSL version rejects a conflicting project version") {
        val fixture = fixture()
        fixture.writeBuild(
            """
            plugins { id("com.typewritermc.imprint") }
            version = "9.0.0"
            typewriter {
                engine {
                    id = "paper"
                    version = "1.0.0"
                }
            }
            """.trimIndent(),
        )

        fixture.run("typewriterInfo", expectFailure = true).output shouldContain
            "Project version 9.0.0 conflicts with Imprint artifact version 1.0.0"
    }
}

private fun fixture(vararg projects: String): FunctionalFixture {
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

private class FunctionalFixture(
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

private fun capabilityBuild(
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

private fun javaLibraryBuild(): String = "plugins { `java-library` }"

private fun extensionWithCapability(dependency: String): String =
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

private fun javaType(
    packageName: String,
    name: String,
): String = "package $packageName; public class $name {}"

private fun File.readManifest(): ImprintManifest =
    ZipFile(this).use { archive ->
        ImprintManifestCodec.decode(archive.getInputStream(archive.getEntry(IMPRINT_MANIFEST_PATH)).readBytes())
    }

private fun File.entries(): List<String> =
    ZipFile(this).use { archive ->
        archive
            .entries()
            .asSequence()
            .map { it.name }
            .toList()
    }
