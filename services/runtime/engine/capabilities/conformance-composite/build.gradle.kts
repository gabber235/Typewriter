plugins {
    id("com.typewritermc.basic-conventions")
    id("com.typewritermc.imprint")
    `java-library`
}

dependencies {
    api(project(":engine-conformance-base"))
}

typewriter {
    engineCapability {
        id = "typewritermc:conformance-composite"
        version = "1.0.0"
        requires {
            capability(project(":engine-conformance-base"), version = "1.0.0")
        }
    }
}
