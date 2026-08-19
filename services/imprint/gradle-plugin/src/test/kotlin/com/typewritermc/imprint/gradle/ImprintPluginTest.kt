package com.typewritermc.imprint.gradle

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.string.shouldContain
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

        result shouldContain "version must use canonical major.minor.patch syntax"
    }
}

private fun runBuild(
    buildFile: String,
    expectFailure: Boolean = false,
): String {
    val projectDirectory = Files.createTempDirectory("imprint-functional-test").toFile()
    projectDirectory.resolve("settings.gradle.kts").writeText("rootProject.name = \"fixture\"")
    projectDirectory.resolve("build.gradle.kts").writeText(buildFile)

    val runner =
        GradleRunner
            .create()
            .withProjectDir(projectDirectory)
            .withArguments("typewriterInfo", "--stacktrace")
            .withPluginClasspath()

    return if (expectFailure) runner.buildAndFail().output else runner.build().output
}
