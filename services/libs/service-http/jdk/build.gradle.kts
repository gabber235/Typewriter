plugins { id("com.typewritermc.basic-conventions") }
dependencies {
    api(project(":service-http-core"))
    implementation("com.typewritermc:service-utils")
    implementation(libs.kotlin.coroutines.core)
}
