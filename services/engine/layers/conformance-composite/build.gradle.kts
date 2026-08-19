plugins {
    id("com.typewritermc.basic-conventions")
    id("com.typewritermc.imprint")
    `java-library`
}

dependencies {
    api(project(":engine-conformance-base"))
}

typewriter {
    engineLayer {
        id = "typewritermc:conformance-composite"
        version = "1.0.0"
        requires {
            layer("typewritermc:conformance-base", version = "1.0.0")
        }
    }
}
