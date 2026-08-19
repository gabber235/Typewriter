plugins {
    id("com.typewritermc.basic-conventions")
    id("com.typewritermc.imprint")
}

dependencies {
    implementation(project(":engine-core"))
}

typewriter {
    engine {
        id = "panel"
        version = "1.0.0"
    }
}
