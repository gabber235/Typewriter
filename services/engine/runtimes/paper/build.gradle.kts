plugins {
    id("com.typewritermc.basic-conventions")
    id("com.typewritermc.imprint")
}

dependencies {
    implementation(project(":engine-core"))
    implementation(project(":engine-minecraft"))
}

typewriter {
    engine {
        id = "paper"
        version = "1.0.0"
        implements {
            layer("typewritermc:minecraft", version = "1.0.0")
        }
    }
}
