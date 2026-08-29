plugins { id("com.typewritermc.basic-conventions") }
dependencies {
    api(project(":service-communicator-core"))
    api(libs.skir.client)
    api(libs.okio)
}
