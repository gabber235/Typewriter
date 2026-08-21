plugins {
    id("com.typewritermc.basic-conventions")
    id("com.typewritermc.imprint")
    `java-library`
}

dependencies {
    api(project(":engine-types"))
}

typewriter {
    engineCapability {
        id = "typewritermc:minecraft"
        version = "1.0.0"
    }
}
