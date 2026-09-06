plugins {
    id("com.typewritermc.basic-conventions")
    id("com.typewritermc.imprint")
    `java-library`
}

dependencies {
    api(project(":engine-api"))
    implementation(project(":typewriter-api"))
}

typewriter {
    engineCapability {
        id = "typewritermc:conformance-base"
        version = "1.0.0"
    }
}
