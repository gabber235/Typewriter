plugins { id("com.typewritermc.basic-conventions") }
dependencies {
    api(project(":service-communicator-core"))
    api(libs.kotlin.coroutines.core)
}
