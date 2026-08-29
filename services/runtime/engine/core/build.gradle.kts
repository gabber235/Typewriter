plugins {
    id("com.typewritermc.basic-conventions")
    id("com.typewritermc.imprint")
    alias(libs.plugins.kotlin.serialize)
    `java-library`
}

dependencies {
    api(project(":engine-api"))
    compileOnlyApi(project(":loader-api"))
    api(project(":typewriter-api"))
    api(libs.kotlin.coroutines.core)
    implementation(project(":messaging"))
    implementation(libs.kotlin.serialize.json)
    testImplementation(project(":loader-api"))
    testImplementation(libs.kotlin.coroutines.test)
}

typewriter {
    engineCore()
}
