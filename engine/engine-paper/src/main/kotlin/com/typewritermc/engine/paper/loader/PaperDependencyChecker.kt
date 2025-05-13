package com.typewritermc.engine.paper.loader

import com.typewritermc.loader.DependencyChecker
import com.typewritermc.core.utils.server

class PaperDependencyChecker : DependencyChecker {
    override fun hasDependency(dependency: String): Boolean = server.pluginManager.isPluginEnabled(dependency)
}