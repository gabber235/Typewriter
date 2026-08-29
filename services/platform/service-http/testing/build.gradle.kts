plugins { id("com.typewritermc.basic-conventions") }
dependencies {
    api(project(":service-http-core"))
    implementation(libs.kotlin.coroutines.core)
}
