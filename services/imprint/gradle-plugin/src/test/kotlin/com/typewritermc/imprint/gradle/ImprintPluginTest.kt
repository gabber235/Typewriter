package com.typewritermc.imprint.gradle

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.string.shouldContain
import io.kotest.matchers.string.shouldNotContain
import org.gradle.testkit.runner.GradleRunner
import java.nio.file.Files

val ImprintPluginTest by testSuite {
    test("engine projects expose their declaration") {
        val result =
            runBuild(
                """
                plugins {
                    id("com.typewritermc.imprint")
                }

                typewriter {
                    engine {
                        id = "paper"
                        version = "1.0.0"
                    }
                }
                """.trimIndent(),
            )

        result shouldContain "Typewriter engine paper 1.0.0"
    }

    test("extension projects expose their declaration") {
        val result =
            runBuild(
                """
                plugins {
                    id("com.typewritermc.imprint")
                }

                typewriter {
                    extension {
                        id = "typewritermc:conformance"
                        version = "1.0.0"
                    }
                }
                """.trimIndent(),
            )

        result shouldContain "Typewriter extension typewritermc:conformance 1.0.0"
    }

    test("projects must declare exactly one Typewriter project kind") {
        val result =
            runBuild(
                """
                plugins {
                    id("com.typewritermc.imprint")
                }

                typewriter {
                    engine {
                        id = "paper"
                        version = "1.0.0"
                    }
                    extension {
                        id = "typewritermc:conformance"
                        version = "1.0.0"
                    }
                }
                """.trimIndent(),
                expectFailure = true,
            )

        result shouldContain "must declare exactly one engine, engine layer, or extension"
    }

    test("engine projects expose implemented layers") {
        val result =
            runBuild(
                """
                plugins {
                    id("com.typewritermc.imprint")
                }

                typewriter {
                    engine {
                        id = "paper"
                        version = "1.0.0"
                        implements {
                            layer("typewritermc:minecraft", version = "1.2.0")
                        }
                    }
                }
                """.trimIndent(),
            )

        result shouldContain "Typewriter engine layer typewritermc:minecraft 1.2.0"
    }

    test("versions must use canonical semantic version syntax") {
        val result =
            runBuild(
                """
                plugins {
                    id("com.typewritermc.imprint")
                }

                typewriter {
                    engineLayer {
                        id = "typewritermc:minecraft"
                        version = "1"
                    }
                }
                """.trimIndent(),
                expectFailure = true,
            )

        result shouldContain "version must use valid semantic version syntax"
    }

    test("versions support prerelease and build metadata") {
        val result =
            runBuild(
                """
                plugins {
                    id("com.typewritermc.imprint")
                }

                typewriter {
                    engineLayer {
                        id = "typewritermc:minecraft"
                        version = "1.2.3-rc.1+local.4"
                    }
                }
                """.trimIndent(),
            )

        result shouldContain "Typewriter engine layer typewritermc:minecraft 1.2.3-rc.1+local.4"
    }

    test("extension engine targets derive their transitive layer source sets") {
        val result =
            runBuild(
                extensionBuild(
                    """
                    engine("paper", version = "1.0.0")
                    engine("conformance", version = "1.0.0")
                    """.trimIndent(),
                ),
                task = "typewriterSourceSets",
            )

        result shouldContain "Typewriter source set enginePaper"
        result shouldContain "Typewriter source set engineConformance"
        result shouldContain "Typewriter source set layerMinecraft"
        result shouldContain "Typewriter source set layerConformanceBase"
        result shouldContain "Typewriter source set layerConformanceComposite"
    }

    test("engine source sets may use common sources") {
        val result =
            runBuild(
                extensionBuild("engine(\"paper\", version = \"1.0.0\")"),
                task = "compileEnginePaperKotlin",
                files =
                    mapOf(
                        "src/common/kotlin/fixture/Common.kt" to "package fixture\nclass Common",
                        "src/enginePaper/kotlin/fixture/Paper.kt" to "package fixture\nclass Paper(val common: Common)",
                    ),
            )

        result shouldNotContain "Unresolved reference"
    }

    test("common sources cannot use engine sources") {
        val result =
            runBuild(
                extensionBuild("engine(\"paper\", version = \"1.0.0\")"),
                task = "compileCommonKotlin",
                files =
                    mapOf(
                        "src/common/kotlin/fixture/Common.kt" to "package fixture\nclass Common(val paper: Paper)",
                        "src/enginePaper/kotlin/fixture/Paper.kt" to "package fixture\nclass Paper",
                    ),
                expectFailure = true,
            )

        result shouldContain "Unresolved reference"
    }

    test("extension targets reject incompatible engine majors") {
        val result =
            runBuild(
                extensionBuild("engine(\"paper\", version = \"2.0.0\")"),
                task = "typewriterSourceSets",
                expectFailure = true,
            )

        result shouldContain "engine paper 1.0.0 does not satisfy version 2.0.0"
    }
}

private fun extensionBuild(targets: String): String =
    """
    plugins {
        id("com.typewritermc.imprint")
    }
    apply(plugin = "org.jetbrains.kotlin.jvm")

    repositories {
        mavenCentral()
    }

    typewriter {
        extension {
            id = "typewritermc:fixture"
            version = "1.0.0"
            targets {
                $targets
            }
        }
    }
    """.trimIndent()

private fun runBuild(
    buildFile: String,
    task: String = "typewriterInfo",
    files: Map<String, String> = emptyMap(),
    expectFailure: Boolean = false,
): String {
    val projectDirectory = Files.createTempDirectory("imprint-functional-test").toFile()
    projectDirectory.resolve("settings.gradle.kts").writeText("rootProject.name = \"fixture\"")
    projectDirectory.resolve("build.gradle.kts").writeText(buildFile)
    files.forEach { (path, content) ->
        projectDirectory.resolve(path).apply {
            parentFile.mkdirs()
            writeText(content)
        }
    }

    val runner =
        GradleRunner
            .create()
            .withProjectDir(projectDirectory)
            .withArguments(task, "--stacktrace")
            .withPluginClasspath()

    return if (expectFailure) runner.buildAndFail().output else runner.build().output
}
