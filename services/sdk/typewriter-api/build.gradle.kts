plugins {
    id("com.typewritermc.basic-conventions")
    alias(libs.plugins.ksp)
    alias(libs.plugins.kotlin.serialize)
    `java-library`
}

dependencies {
    api(project(":typewriter-contracts"))
    api(platform(libs.koin.bom))
    api(libs.koin.core)
    api(libs.kotlin.coroutines.core)
    ksp(project(":typewriter-codegen"))
    testImplementation(libs.bundles.basic.test)
    testImplementation(libs.kotlin.serialize.json)
}

ksp {
    arg("typewriter.artifactId", "typewritermc:core")
    arg("typewriter.sourcePart", "main")
}
