plugins {
    id("com.typewritermc.basic-conventions")
    id("com.typewritermc.imprint")
    `java-library`
}

dependencies {
    api(project(":engine-api"))
}

typewriter {
    engineCapability {
        id = "typewritermc:minecraft"
        version = "1.0.0"
    }
}
