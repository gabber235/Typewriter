plugins {
    id("com.typewritermc.basic-conventions")
}

dependencies {
    implementation(project(":extension-types"))
    implementation(libs.ksp.api)
}
