plugins {
    id("com.typewritermc.basic-conventions")
}

dependencies {
    implementation(project(":service-file-transfer-core"))
    implementation(libs.kotlin.coroutines.core)
}
