plugins {
    id("com.typewritermc.basic-conventions")
    id("com.typewritermc.imprint")
    id("xyz.jpenilla.run-paper") version "3.0.2"
}

val loaderPlugin = configurations.create("loaderPlugin")

dependencies {
    imprintEngineCore(project(":engine-core"))
    imprintHostApi(project(":loader-api"))
    loaderPlugin(project(":loader-distribution"))
    testImplementation(libs.kotlin.coroutines.test)
}

tasks.runServer {
    minecraftVersion("26.2")
    runDirectory.set(rootProject.layout.projectDirectory.dir("../build/development/paper"))
    pluginJars.from(loaderPlugin)
}

typewriter {
    engine {
        id = "typewritermc:paper"
        version = "1.0.0"
        hostApi = "^1"
        implements {
            capability(project(":engine-minecraft"), version = "1.0.0")
        }
    }
}
