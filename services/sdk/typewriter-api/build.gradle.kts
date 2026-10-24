plugins {
    id("com.typewritermc.basic-conventions")
    alias(libs.plugins.ksp)
    alias(libs.plugins.kotlin.serialize)
    `java-library`
}

kotlin {
    sourceSets.named("main") {
        kotlin.srcDir("src/main/skirout")
    }
}

dependencies {
    api(project(":typewriter-contracts"))
    api(platform(libs.koin.bom))
    api(libs.koin.core)
    api(libs.kotlin.coroutines.core)
    implementation(libs.kotlin.reflect)
    ksp(project(":typewriter-codegen"))
    testImplementation(libs.kotlin.serialize.json)
}

ksp {
    arg("typewriter.artifactId", "typewritermc:core")
    arg("typewriter.sourcePart", "main")
    arg("typewriter.claimDependencyClosure", "true")
}
