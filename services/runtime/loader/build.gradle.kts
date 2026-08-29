import java.util.zip.ZipFile

plugins {
    id("com.typewritermc.basic-conventions")
    id("com.gradleup.shadow") version "9.4.1"
}

version = "1000.0.0"

dependencies {
    implementation(project(":loader-standalone"))
    implementation(project(":loader-paper"))
}

tasks.shadowJar {
    archiveFileName.set("typewriter-loader-${project.version}.jar")
    manifest {
        attributes["Main-Class"] = "com.typewritermc.loader.standalone.StandaloneLoader"
    }
}

tasks.assemble {
    dependsOn(tasks.shadowJar)
}

configurations.named("runtimeElements") {
    outgoing.artifacts.clear()
    outgoing.artifact(tasks.shadowJar)
}

val verifyDistribution =
    tasks.register("verifyDistribution") {
        group = "verification"
        description = "Verifies that the loader distribution contains both entrypoints."
        dependsOn(tasks.shadowJar)
        doLast {
            ZipFile(
                tasks.shadowJar
                    .get()
                    .archiveFile
                    .get()
                    .asFile,
            ).use { archive ->
                val entries =
                    archive
                        .entries()
                        .asSequence()
                        .map { it.name }
                        .toSet()
                check("com/typewritermc/loader/standalone/StandaloneLoader.class" in entries)
                check("com/typewritermc/loader/paper/TypewriterLoaderPlugin.class" in entries)
                check("plugin.yml" in entries)
                val manifest = archive.getInputStream(archive.getEntry("META-INF/MANIFEST.MF")).bufferedReader().readText()
                check("Main-Class: com.typewritermc.loader.standalone.StandaloneLoader" in manifest)
            }
        }
    }

tasks.check {
    dependsOn(verifyDistribution)
}

subprojects {
    version = "1000.0.0"
}
