plugins {
    id("com.typewritermc.basic-conventions")
    id("com.typewritermc.imprint")
}

dependencies {
    implementation(project(":engine-core"))
    implementation(project(":engine-conformance-composite"))
    testImplementation(libs.kotlin.coroutines.test)
}

typewriter {
    engine {
        id = "typewritermc:conformance"
        version = "1.0.0"
        implements {
            capability(project(":engine-conformance-composite"), version = "1.0.0")
        }
    }
}
