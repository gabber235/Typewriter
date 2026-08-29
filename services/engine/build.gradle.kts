subprojects {
    pluginManager.withPlugin("com.typewritermc.imprint") {
        dependencies.add("imprintProcessors", "com.typewritermc:element-codegen")
        dependencies.add("imprintProcessors", "com.typewritermc:presentation-codegen")
        dependencies.add("imprintProcessors", "com.typewritermc:page-codegen")
        dependencies.add("imprintProcessors", "com.typewritermc:realm-capability-codegen")
        dependencies.add("imprintProcessors", "com.typewritermc:discovery-codegen")
    }
}
