import xyz.jpenilla.resourcefactory.bukkit.BukkitPluginYaml

plugins {
    id("com.typewritermc.basic-conventions")
    id("xyz.jpenilla.resource-factory-bukkit-convention") version "1.3.1"
}

bukkitPluginYaml {
    name = "TypewriterLoader"
    version = project.version.toString()
    main = "com.typewritermc.loader.paper.TypewriterLoaderPlugin"
    apiVersion = "1.21"
    load = BukkitPluginYaml.PluginLoadOrder.STARTUP
}

repositories {
    maven("https://repo.papermc.io/repository/maven-public/")
}

dependencies {
    implementation(project(":loader-core"))
    compileOnly(libs.paper.api)
    testImplementation(libs.paper.api)
}
