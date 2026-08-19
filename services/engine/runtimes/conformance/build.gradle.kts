plugins {
    id("com.typewritermc.basic-conventions")
    id("com.typewritermc.imprint")
}

dependencies {
    implementation(project(":engine-core"))
    implementation(project(":engine-conformance-composite"))
    testImplementation("com.typewritermc:conformance-extension")
    testImplementation(libs.kotlin.coroutines.test)
}

typewriter {
    engine {
        id = "conformance"
        version = "1.0.0"
        implements {
            layer("typewritermc:conformance-composite", version = "1.0.0")
        }
    }
}
