plugins {
    id("com.typewritermc.basic-conventions")
    id("com.typewritermc.imprint")
}

dependencies {
    implementation(project(":engine-core"))
    implementation(project(":engine-minecraft"))
    testImplementation(libs.kotlin.coroutines.test)
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
