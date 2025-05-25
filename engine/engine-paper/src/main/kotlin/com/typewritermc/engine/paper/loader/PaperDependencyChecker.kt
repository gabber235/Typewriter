package com.typewritermc.engine.paper.loader

import com.typewritermc.loader.DependencyChecker
import com.typewritermc.engine.paper.utils.server

class PaperDependencyChecker : DependencyChecker {
    override fun hasDependency(dependency: String): Boolean = server.pluginManager.isPluginEnabled(dependency)
}