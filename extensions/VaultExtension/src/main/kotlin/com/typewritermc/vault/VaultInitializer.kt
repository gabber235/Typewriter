package com.typewritermc.vault

import com.typewritermc.core.extension.Initializable
import com.typewritermc.core.extension.annotations.Singleton
import net.milkbowl.vault.chat.Chat
import net.milkbowl.vault.economy.Economy
import net.milkbowl.vault.permission.Permission
import org.bukkit.Bukkit.getServer

@Singleton
class VaultInitializer : Initializable {
    var economy: Economy? = null
        private set

    var permissions: Permission? = null
        private set

    var chat: Chat? = null
        private set


    override suspend fun initialize() {
        loadVault()
    }

    override suspend fun shutdown() {
        economy = null
        permissions = null
        chat = null
    }

    private fun loadVault() {
        setupEconomy()
        setupPermissions()
        setupChat()
    }

    private fun setupEconomy(): Boolean {
        if (getServer().pluginManager.getPlugin("Vault") == null) {
            return false
        }
        val rsp = getServer().servicesManager.getRegistration(
            Economy::class.java
        ) ?: return false
        economy = rsp.provider
        return true
    }

    private fun setupPermissions(): Boolean {
        val rsp = getServer().servicesManager.getRegistration(
            Permission::class.java
        ) ?: return false
        permissions = rsp.provider
        return true
    }

    private fun setupChat(): Boolean {
        val rsp = getServer().servicesManager.getRegistration(
            Chat::class.java
        ) ?: return false
        chat = rsp.provider
        return true
    }
}