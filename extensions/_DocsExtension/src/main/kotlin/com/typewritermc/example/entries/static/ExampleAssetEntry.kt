package com.typewritermc.example.entries.static

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.engine.paper.entry.AssetManager
import com.typewritermc.engine.paper.entry.entries.AssetEntry
import com.typewritermc.engine.paper.entry.entries.hasData
import com.typewritermc.engine.paper.entry.entries.stringData
import com.typewritermc.engine.paper.entry.entries.binaryData
import org.koin.java.KoinJavaComponent

//<code-block:asset_entry>
@Entry("example_asset", "An example asset entry.", Colors.BLUE, "material-symbols:home-storage-rounded")
class ExampleAssetEntry(
    override val id: String = "",
    override val name: String = "",
    override val path: String = "",
) : AssetEntry
//</code-block:asset_entry>

//<code-block:asset_access>
suspend fun accessAssetData(ref: Ref<out AssetEntry>) {
    val assetManager = KoinJavaComponent.get<AssetManager>(AssetManager::class.java)
    val entry = ref.get() ?: return
    val stringContent: String? = assetManager.fetchStringAsset(entry)
    // Do something with the string content
}
//</code-block:asset_access>

//<code-block:asset_binary_access>
suspend fun accessBinaryAssetData(ref: Ref<out AssetEntry>) {
    val assetManager = KoinJavaComponent.get<AssetManager>(AssetManager::class.java)
    val entry = ref.get() ?: return
    val binaryContent: ByteArray? = assetManager.fetchBinaryAsset(entry)
    // Do something with the binary content
}
//</code-block:asset_binary_access>

//<code-block:asset_helper_methods>
suspend fun accessAssetDataUsingHelpers(ref: Ref<out AssetEntry>) {
    val entry = ref.get() ?: return

    // Check if asset has data
    if (entry.hasData()) {
        // Access string data using helper method
        val stringContent: String? = entry.stringData()

        // Access binary data using helper method
        val binaryContent: ByteArray? = entry.binaryData()
    }
}
//</code-block:asset_helper_methods>
