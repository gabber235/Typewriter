// The bridge between Typewriter's in flight work and the framework's tick holding: a Paper plugin, on
// game Papers of Typewriter's own suite only, that counts each item of the loader's InFlightWork as
// PlayerWork for the Minecraft players it is for. It is Java so it brings no Kotlin of its own: Paper
// gives it the loader's classes from the Typewriter plugin and the framework's from the Playtest plugin.
plugins {
    id("com.typewritermc.basic-conventions")
}

// The Playtest plugin and the patched server's jars are Java 25.
kotlin {
    jvmToolchain(25)
}

repositories {
    maven("https://repo.papermc.io/repository/maven-public/")
}

dependencies {
    compileOnly(libs.paper.api)
    compileOnly(project(":loader-api"))
    compileOnly(project(":playtest-plugin"))
    testImplementation(project(":loader-api"))
}

configurations.consumable("playtestTypewriterPlugin") {
    outgoing.artifact(tasks.jar)
}
