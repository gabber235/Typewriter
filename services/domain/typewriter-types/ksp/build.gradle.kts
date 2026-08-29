plugins {
    id("com.typewritermc.basic-conventions")
    `java-library`
}

dependencies {
    api(project(":typewriter-types-core"))
    api(libs.ksp.api)
    testImplementation(libs.mockk)
}
