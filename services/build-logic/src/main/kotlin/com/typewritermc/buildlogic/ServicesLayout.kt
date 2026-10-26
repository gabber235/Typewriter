package com.typewritermc.buildlogic

import org.gradle.api.Project
import java.io.File

/**
 * The `services/` directory, found from the root of the services build or of the imprint build it includes.
 */
val Project.servicesDirectory: File
    get() =
        generateSequence(rootProject.projectDir) { it.parentFile }
            .first { File(it, "build-logic").isDirectory && File(it, "libs.versions.toml").isFile }

/** The repository root that contains `services/`. */
val Project.repositoryRoot: File
    get() = servicesDirectory.parentFile

/** Where `cargo xtask` reads the results it reports; Git ignores it. */
val Project.xtaskResults: File
    get() = repositoryRoot.resolve(".xtask/results")
