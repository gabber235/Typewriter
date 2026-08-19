plugins {
    id("xyz.jpenilla.run-paper") version "3.0.2"
}

tasks.runServer {
    minecraftVersion("1.21.11")
    runDirectory.set(layout.buildDirectory.dir("server"))
    pluginJars.from(layout.projectDirectory.file("../loader/build/libs/typewriter-loader-1000.0.0.jar"))
}
