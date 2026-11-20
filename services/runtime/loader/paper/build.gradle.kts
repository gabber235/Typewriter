plugins {
    id("com.typewritermc.basic-conventions")
    id("xyz.jpenilla.resource-factory-paper-convention") version "1.4.0"
    `java-test-fixtures`
}

paperPluginYaml {
    name = "Typewriter"
    description = "Next Generation Story Telling Plugin"
    authors = listOf("gabber235", "Marten-Mrfc", "steveb05")
    website = "https://docs.typewritermc.com"
    version = project.version.toString()

    main = "com.typewritermc.loader.paper.TypewriterLoaderPlugin"
    apiVersion = "26.3"

    foliaSupported = false

//    Possibly in the future this will be used. For now its not used yet.
//    dependencies {
//        server("packetevents", load = PaperPluginYaml.Load.BEFORE, required = true, joinClasspath = true)
//        server("PlaceholderAPI", load = PaperPluginYaml.Load.BEFORE, required = false, joinClasspath = true)
//        server("floodgate", load = PaperPluginYaml.Load.BEFORE, required = false, joinClasspath = true)
//    }
//
//    loader = "com.typewritermc.engine.paper.TypewriterPaperLoader"
}

// The module targets Java 21 and runs on Paper's Java 25. Paper publishes its API for Java 25 only, so these classpaths
// ask for libraries that run on Java 25; every other library on them runs on 21 and so on 25 as well. The tests load
// Paper's classes, so they run on Java 25 like the server.
listOf("compileClasspath", "testCompileClasspath", "testRuntimeClasspath").forEach { name ->
    configurations.named(name) { attributes.attribute(TargetJvmVersion.TARGET_JVM_VERSION_ATTRIBUTE, 25) }
}
tasks.test {
    javaLauncher.set(javaToolchains.launcherFor { languageVersion.set(JavaLanguageVersion.of(25)) })
}

repositories {
    maven("https://repo.papermc.io/repository/maven-public/")
}

dependencies {
    implementation(project(":loader-core"))
    compileOnly(libs.paper.api)
    testImplementation(libs.paper.api)
}
