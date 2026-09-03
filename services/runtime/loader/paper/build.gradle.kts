plugins {
    id("com.typewritermc.basic-conventions")
    id("xyz.jpenilla.resource-factory-paper-convention") version "1.3.1"
}

paperPluginYaml {
    name = "Typewriter"
    description = "Next Generation Story Telling Plugin"
    authors = listOf("gabber235", "Marten-Mrfc", "steveb05")
    website = "https://docs.typewritermc.com"
    version = project.version.toString()

    main = "com.typewritermc.loader.paper.TypewriterLoaderPlugin"
    apiVersion = "1.21.3"

    foliaSupported = false

//    Possibly in the future this will be used. For now its not used yet.
//    dependencies {
//        server("packetevents", load = PaperPluginYaml.Load.BEFORE, required = true, joinClasspath = true)
//        server("PlaceholderAPI", load = PaperPluginYaml.Load.BEFORE, required = false, joinClasspath = true)
//        server("floodgate", load = PaperPluginYaml.Load.BEFORE, required = false, joinClasspath = true)
//    }
//
//    loader = "com.typewritermc.engine.paper.TypewriterPaperLoader"
}

repositories {
    maven("https://repo.papermc.io/repository/maven-public/")
}

dependencies {
    implementation(project(":loader-core"))
    compileOnly(libs.paper.api)
    testImplementation(libs.paper.api)
}
