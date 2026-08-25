plugins {
    id("com.typewritermc.basic-conventions")
    id("com.typewritermc.imprint")
    alias(libs.plugins.kotlin.serialize)
    `java-library`
}

dependencies {
    api(project(":engine-types"))
    compileOnlyApi("com.typewritermc:loader-api")
    api("com.typewritermc:discovery-runtime")
    api("com.typewritermc:element-types")
    api("com.typewritermc:library-types")
    api("com.typewritermc:page-types")
    api(libs.kotlin.coroutines.core)
    testImplementation("com.typewritermc:loader-api")
    testImplementation(libs.kotlin.coroutines.test)
}

typewriter {
    engineCore()
}
