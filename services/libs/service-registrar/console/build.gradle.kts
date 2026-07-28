plugins { id("com.typewritermc.basic-conventions") }

dependencies {
    api(project(":service-registrar-core"))
    implementation(libs.mordant)
    implementation(libs.kotlin.coroutines.core)
    testImplementation(libs.kotlin.coroutines.test)
}
