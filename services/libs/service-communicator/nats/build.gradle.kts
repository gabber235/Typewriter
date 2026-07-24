plugins { id("com.typewritermc.basic-conventions") }
dependencies {
    implementation("com.typewritermc:service-utils")
    api(project(":service-communicator-core"))
    api(libs.kotlin.coroutines.core)
    implementation(libs.nats.core)
    testImplementation(libs.kotlin.coroutines.test)
}
