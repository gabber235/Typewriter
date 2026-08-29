plugins {
    id("com.typewritermc.basic-conventions")
    id("com.typewritermc.imprint")
    `java-library`
}

dependencies {
    api(project(":engine-types"))
    implementation("com.typewritermc:discovery-runtime")
    implementation("com.typewritermc:element-types")
    implementation("com.typewritermc:page-types")
}

typewriter {
    engineCapability {
        id = "typewritermc:conformance-base"
        version = "1.0.0"
    }
}
