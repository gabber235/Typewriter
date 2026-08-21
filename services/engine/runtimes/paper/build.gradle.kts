plugins {
    id("com.typewritermc.basic-conventions")
    id("com.typewritermc.imprint")
    id("xyz.jpenilla.run-paper") version "3.0.2"
}

val loaderPlugin = configurations.create("loaderPlugin")

dependencies {
    implementation(project(":engine-core"))
    implementation(project(":engine-minecraft"))
    loaderPlugin("com.typewritermc:loader:development")
    testImplementation(libs.kotlin.coroutines.test)
}

tasks.runServer {
    minecraftVersion("26.2")
    runDirectory.set(rootProject.layout.projectDirectory.dir("../build/development/paper"))
    pluginJars.from(loaderPlugin)
}

typewriter {
    engine {
        id = "paper"
        version = "1.0.0"
        implements {
            capability("typewritermc:minecraft", version = "1.0.0")
        }
    }
}
